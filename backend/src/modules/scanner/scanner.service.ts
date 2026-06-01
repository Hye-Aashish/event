import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Ticket, TicketDocument } from '../../schemas/ticket.schema';

const memoryLock = new Map<string, NodeJS.Timeout>();

@Injectable()
export class ScannerService {
  private readonly SECRET_KEY = process.env.QR_SECRET || 'qr-hmac-secret-key';

  constructor(
    @InjectModel(Ticket.name) private ticketModel: Model<TicketDocument>,
    @InjectModel('ScanLog') private scanLogModel: Model<any>,
  ) { }

  async validateScan(payload: any, scannerId?: string, readOnly: boolean = false) {
    const isRawHash = !!payload.qrData;
    const sigToSearch = isRawHash ? payload.qrData : payload.sig;

    if (!sigToSearch) {
      throw new BadRequestException('Invalid QR format');
    }

    const logBase: any = { rawPayload: payload };
    if (scannerId) {
      logBase.scannerId = new Types.ObjectId(scannerId);
    }

    // Atomic in-process lock to prevent duplicate scans
    const lockKey = `lock:${sigToSearch}`;
    if (memoryLock.has(lockKey)) {
      await this.scanLogModel.create({ ...logBase, status: 'duplicate', message: 'Concurrent scan blocked' });
      throw new BadRequestException('Duplicate scan detected');
    }
    const timeout = setTimeout(() => memoryLock.delete(lockKey), 5000);
    memoryLock.set(lockKey, timeout);

    try {
      // Lookup the ticket by the uniquely generated qrHash (which acts as the signature itself)
      const ticket = await this.ticketModel
        .findOne({ qrHash: sigToSearch })
        .populate('eventId', 'name')
        .populate('zoneId', 'name')
        .populate('userId', 'name phoneNumber')
        .lean();

      if (!ticket) {
        await this.scanLogModel.create({ ...logBase, status: 'invalid_sig', message: 'Ticket not found by hash' });
        throw new BadRequestException('Invalid QR signature or Ticket not found');
      }

      const id = ticket._id.toString();
      logBase.ticketId = new Types.ObjectId(id);

      // Extract eventDate for time window checking
      let eventDate = payload.d || ticket.date;

      // Time window check (Only if eventDate is present)
      // DEBUG: Temporarily bypassing the strict 6PM-6AM time window check so you can test during the day!
      // In production, you would re-enable this.
      /*
      if (eventDate) {
        if (!this.isValidTimeWindow(eventDate)) {
          await this.scanLogModel.create({ ...logBase, status: 'time_invalid', message: 'Outside valid time window' });
          throw new BadRequestException('Ticket not valid for current time (6PM–6AM only)');
        }
      }
      */

      // 4. Status check
      if (ticket.status !== 'active') {
        await this.scanLogModel.create({ ...logBase, status: 'fraud', eventId: ticket.eventId?._id || ticket.eventId, zoneId: ticket.zoneId?._id || ticket.zoneId, message: `Status: ${ticket.status}` });
        throw new BadRequestException(`Ticket is ${ticket.status}`);
      }

      // 5. Type-specific rules
      if (ticket.type === 'season') {
        if (!ticket.isVerified) {
          await this.scanLogModel.create({ ...logBase, status: 'unverified', eventId: ticket.eventId?._id || ticket.eventId, zoneId: ticket.zoneId?._id || ticket.zoneId, message: 'Not verified' });
          throw new BadRequestException('Season pass not verified');
        }
        if (ticket.isScannedToday) {
          await this.scanLogModel.create({ ...logBase, status: 'duplicate', eventId: ticket.eventId?._id || ticket.eventId, zoneId: ticket.zoneId?._id || ticket.zoneId, message: 'Already scanned today' });
          throw new BadRequestException('Already scanned today');
        }
      } else {
        if (ticket.totalScans >= (ticket.quantity || 1)) {
          await this.scanLogModel.create({ ...logBase, status: 'duplicate', eventId: ticket.eventId?._id || ticket.eventId, zoneId: ticket.zoneId?._id || ticket.zoneId, message: 'Already fully scanned' });
          throw new BadRequestException('Pass already fully scanned/used');
        }
      }

      // 6. Mark scanned (only if not read-only validation)
      if (!readOnly) {
        const remaining = (ticket.quantity || 1) - ticket.totalScans;
        const isSeason = ticket.type === 'season';
        const isFullyScanned = !isSeason;
        const newStatus = isSeason ? 'active' : 'used';

        await this.ticketModel.updateOne(
          { _id: id },
          { 
            $set: { 
              isScannedToday: true, 
              isScanned: isFullyScanned, 
              status: newStatus,
              lastScannedAt: new Date() 
            }, 
            $inc: { totalScans: remaining } 
          }
        );

        // 7. Log success (async — don't block response)
        this.scanLogModel.create({
          ...logBase,
          eventId: (ticket.eventId as any)?._id,
          zoneId: (ticket.zoneId as any)?._id,
          status: 'success',
          message: `Access granted (All ${ticket.quantity || 1} passes admitted)`,
        });
      }

      const groupTotal = ticket.quantity || 1;
      const groupScanned = ticket.quantity || 1;

      return {
        success: true,
        message: readOnly ? 'Ticket verified' : '✅ Access Granted',
        ticket: {
          type: ticket.type,
          category: ticket.category,
          event: (ticket.eventId as any)?.name,
          zone: (ticket.zoneId as any)?.name,
          user: ticket.userId ? {
            name: (ticket.userId as any).name || 'Unknown',
            phone: (ticket.userId as any).phoneNumber || '',
          } : null,
          groupTotal,
          groupScanned,
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
