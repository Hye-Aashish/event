import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Ticket, TicketDocument } from '../../schemas/ticket.schema';
import { ScanLog } from '../../schemas/log.schema';
import * as crypto from 'crypto';

const memoryLock = new Map<string, NodeJS.Timeout>();

@Injectable()
export class ScannerService {
  private readonly SECRET_KEY = process.env.QR_SECRET || 'qr-hmac-secret-key';

  constructor(
    @InjectModel(Ticket.name) private ticketModel: Model<TicketDocument>,
    @InjectModel('ScanLog') private scanLogModel: Model<any>,
  ) {}

  async validateScan(payload: any, scannerId?: string) {
    const { id, d: eventDate, sig, sys } = payload;
    const logBase = { ticketId: id, scannerId, rawPayload: payload };

    // 1. HMAC Signature Verification
    const expectedSig = crypto
      .createHmac('sha256', this.SECRET_KEY)
      .update(id + eventDate)
      .digest('hex');

    if (sig !== expectedSig) {
      await this.scanLogModel.create({ ...logBase, status: 'invalid_sig', message: 'HMAC mismatch' });
      throw new BadRequestException('Invalid QR signature');
    }

    // 2. Time window check
    if (!this.isValidTimeWindow(eventDate)) {
      await this.scanLogModel.create({ ...logBase, status: 'time_invalid', message: 'Outside valid time window' });
      throw new BadRequestException('Ticket not valid for current time (6PM–6AM only)');
    }

    // 3. Atomic in-process lock
    const lockKey = `lock:${id}`;
    if (memoryLock.has(lockKey)) {
      await this.scanLogModel.create({ ...logBase, status: 'duplicate', message: 'Concurrent scan blocked' });
      throw new BadRequestException('Duplicate scan detected');
    }
    const timeout = setTimeout(() => memoryLock.delete(lockKey), 5000);
    memoryLock.set(lockKey, timeout);

    try {
      const ticket = await this.ticketModel
        .findById(id)
        .populate('eventId', 'name')
        .populate('zoneId', 'name')
        .lean();

      if (!ticket) {
        await this.scanLogModel.create({ ...logBase, status: 'invalid_sig', message: 'Ticket not found' });
        throw new NotFoundException('Ticket not found');
      }

      // 4. Status check
      if (ticket.status !== 'active') {
        await this.scanLogModel.create({ ...logBase, status: 'fraud', eventId: ticket.eventId, zoneId: ticket.zoneId, message: `Status: ${ticket.status}` });
        throw new BadRequestException(`Ticket is ${ticket.status}`);
      }

      // 5. Type-specific rules
      if (ticket.type === 'season') {
        if (!ticket.isVerified) {
          await this.scanLogModel.create({ ...logBase, status: 'unverified', eventId: ticket.eventId, message: 'Not verified' });
          throw new BadRequestException('Season pass not verified');
        }
        if (ticket.isScannedToday) {
          await this.scanLogModel.create({ ...logBase, status: 'duplicate', eventId: ticket.eventId, message: 'Already scanned today' });
          throw new BadRequestException('Already scanned today');
        }
      } else {
        if (ticket.totalScans > 0) {
          await this.scanLogModel.create({ ...logBase, status: 'duplicate', eventId: ticket.eventId, message: 'Already used' });
          throw new BadRequestException('Regular pass already used');
        }
      }

      // 6. Mark scanned
      await this.ticketModel.updateOne(
        { _id: id },
        { $set: { isScannedToday: true, isScanned: true, lastScannedAt: new Date() }, $inc: { totalScans: 1 } }
      );

      // 7. Log success (async — don't block response)
      this.scanLogModel.create({
        ...logBase,
        eventId: (ticket.eventId as any)?._id,
        zoneId: (ticket.zoneId as any)?._id,
        status: 'success',
        message: 'Access granted',
      });

      return {
        success: true,
        message: '✅ Access Granted',
        ticket: {
          type: ticket.type,
          category: ticket.category,
          event: (ticket.eventId as any)?.name,
          zone: (ticket.zoneId as any)?.name,
        },
      };

    } finally {
      clearTimeout(memoryLock.get(lockKey));
      memoryLock.delete(lockKey);
    }
  }

  async getScanLogs(eventId: string) {
    return this.scanLogModel
      .find({ eventId })
      .sort({ createdAt: -1 })
      .limit(500)
      .populate('scannerId', 'name phoneNumber')
      .lean();
  }

  private isValidTimeWindow(eventDate: string): boolean {
    const now = new Date();
    const hours = now.getHours();
    const today = now.toISOString().split('T')[0];
    if (today === eventDate && hours >= 18) return true;
    const yesterday = new Date();
    yesterday.setDate(now.getDate() - 1);
    if (yesterday.toISOString().split('T')[0] === eventDate && hours <= 6) return true;
    return false;
  }
}
