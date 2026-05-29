import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import * as crypto from 'crypto';
import { Model, Types } from 'mongoose';
import Razorpay from 'razorpay';
import { Event, EventDocument } from '../../schemas/event.schema';
import { Settings, SettingsDocument } from '../../schemas/settings.schema';
import { Ticket, TicketDocument } from '../../schemas/ticket.schema';
import { Zone, ZoneDocument } from '../../schemas/zone.schema';

import { User } from '../../schemas/user.schema';

@Injectable()
export class TicketsService {
  private razorpay: Razorpay;

  constructor(
    @InjectModel(Ticket.name) private ticketModel: Model<TicketDocument>,
    @InjectModel(Event.name) private eventModel: Model<EventDocument>,
    @InjectModel(Zone.name) private zoneModel: Model<ZoneDocument>,
    @InjectModel(Settings.name) private settingsModel: Model<SettingsDocument>,
    @InjectModel('TransferLog') private transferLogModel: Model<any>,
    @InjectModel(User.name) private userModel: Model<any>,
  ) { }

  private async getRazorpayInstance() {
    const settings = await this.settingsModel.findOne({ key: 'global' });
    const key_id = settings?.razorpayKeyId || process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder';
    const key_secret = settings?.razorpayKeySecret || process.env.RAZORPAY_KEY_SECRET || 'placeholder';

    return new Razorpay({ key_id, key_secret });
  }

  private async getRazorpayKey() {
    const settings = await this.settingsModel.findOne({ key: 'global' });
    return settings?.razorpayKeyId || process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder';
  }

  // ── Create Razorpay Order ─────────────────────────────────────────────────
  async createOrder(userId: string, body: { eventId: string; zoneId: string; type: string; category: string; quantity: number; date?: string }) {
    const event = await this.eventModel.findById(body.eventId);
    if (!event) throw new NotFoundException('Event not found');
    if (event.status !== 'published') throw new BadRequestException('Event not available');

    const zone = await this.zoneModel.findById(body.zoneId);
    if (!zone) throw new NotFoundException('Zone not found');

    console.log(`🎟️ Creating Razorpay Order for User: ${userId} | Event: ${event.name} | Zone: ${zone.name}`);

    // Pricing Logic
    const basePrice = (body.type === 'season') ? (zone.seasonPrice || 0) : (zone.dailyPrice || 0);

    let gstAmount = 0;
    let finalBasePrice = basePrice;

    if (event.gstEnabled) {
      if (event.gstInclusive) {
        // Price includes GST: Base = Total / (1 + tax_rate)
        const total = basePrice;
        finalBasePrice = Math.round(total / (1 + (event.gstPercentage / 100)));
        gstAmount = total - finalBasePrice;
      } else {
        // Price excludes GST: Tax = Base * tax_rate
        gstAmount = Math.round(basePrice * (event.gstPercentage / 100));
      }
    }

    console.log(`💰 Pricing: Base: ${finalBasePrice}, GST: ${gstAmount}, Total: ${finalBasePrice + gstAmount}`);

    const totalPerTicket = finalBasePrice + gstAmount;
    const totalAmount = totalPerTicket * body.quantity;

    const rzp = await this.getRazorpayInstance();
    const order = await rzp.orders.create({
      amount: Math.round(totalAmount * 100), // paise
      currency: 'INR',
      receipt: `rcpt_${Date.now()}`,
      notes: {
        userId,
        eventId: body.eventId,
        zoneId: body.zoneId,
        type: body.type,
        category: body.category,
        date: body.date || '',
        quantity: String(body.quantity)
      },
    });

    return {
      order,
      basePrice: finalBasePrice,
      gstAmount,
      totalAmount,
      razorpayKey: await this.getRazorpayKey()
    };
  }

  // ── Verify Payment & Create Tickets ──────────────────────────────────────
  async verifyAndCreate(userId: string, body: any) {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, eventId, zoneId, type, category, quantity, date } = body;

    // Validation
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature || !eventId || !zoneId) {
      throw new BadRequestException('Missing required payment verification details');
    }

    const settings = await this.settingsModel.findOne({ key: 'global' });
    const secret = settings?.razorpayKeySecret || process.env.RAZORPAY_KEY_SECRET || 'placeholder';

    const expectedSig = crypto
      .createHmac('sha256', secret)
      .update(`${razorpay_order_id}|${razorpay_payment_id}`)
      .digest('hex');

    if (expectedSig !== razorpay_signature) {
      console.error(`❌ Payment Verification Failed for User: ${userId}`);
      console.error(`Order ID: ${razorpay_order_id}`);
      console.error(`Status: Signature mismatch`);
      throw new BadRequestException('Payment verification failed');
    }

    const event = await this.eventModel.findById(eventId);
    if (!event) throw new NotFoundException('Event not found');

    const zone = await this.zoneModel.findById(zoneId);
    if (!zone) throw new NotFoundException('Zone not found');

    // Recalculate for verification
    const rawPrice = (type === 'season') ? (zone.seasonPrice || 0) : (zone.dailyPrice || 0);
    let gstAmount = 0;
    let basePrice = rawPrice;

    if (event.gstEnabled) {
      if (event.gstInclusive) {
        basePrice = Math.round(rawPrice / (1 + (event.gstPercentage / 100)));
        gstAmount = rawPrice - basePrice;
      } else {
        gstAmount = Math.round(rawPrice * (event.gstPercentage / 100));
      }
    }

    const tickets = [];
    const actualQuantity = parseInt(String(quantity || 1));

    console.log(`✅ Creating ${actualQuantity} tickets for User: ${userId}`);

    for (let i = 0; i < actualQuantity; i++) {
      const ticketId = new Types.ObjectId().toString();
      const qrHash = this.generateQrHash(ticketId, eventId);

      const ticket = await this.ticketModel.create({
        userId: new Types.ObjectId(userId), 
        eventId: new Types.ObjectId(eventId), 
        zoneId: new Types.ObjectId(zoneId), 
        type, category, date,
        qrHash,
        razorpayOrderId: razorpay_order_id,
        razorpayPaymentId: razorpay_payment_id,
        basePrice, gstAmount,
        totalAmount: basePrice + gstAmount,
        transferable: type === 'regular',
        currentOwner: new Types.ObjectId(userId),
        source: 'purchase',
        status: 'active',
      });
      tickets.push(ticket);
    }

    // Decrement zone capacity
    await this.zoneModel.findByIdAndUpdate(zoneId, {
      $inc: { currentCount: actualQuantity, availableSeats: -actualQuantity }
    });

    return { success: true, tickets };
  }

  // ── Issue Sponsor Free Ticket ─────────────────────────────────────────────
  async issueSponsorTicket(sponsorId: string, body: any, adminId: string) {
    const { eventId, zoneId, type, category, recipientUserId } = body;
    const ticketId = new Types.ObjectId().toString();
    const qrHash = this.generateQrHash(ticketId, eventId);

    return this.ticketModel.create({
      userId: recipientUserId, eventId, zoneId, type, category,
      qrHash, basePrice: 0, gstAmount: 0, totalAmount: 0,
      transferable: type === 'regular',
      currentOwner: recipientUserId,
      source: 'sponsor',
      sponsorId,
      status: 'active',
    });
  }

  // ── Admin: All Tickets with filters ─────────────────────────────────────
  async getAllTickets(query: any = {}) {
    const filter: any = {};
    if (query.eventId) filter.eventId = query.eventId;
    if (query.type) filter.type = query.type;
    if (query.status) filter.status = query.status;
    return this.ticketModel
      .find(filter)
      .populate('currentOwner', 'phoneNumber name')
      .populate('eventId', 'name')
      .populate('zoneId', 'name')
      .sort({ createdAt: -1 })
      .limit(200)
      .lean();
  }

  // ── My Tickets ────────────────────────────────────────────────────────────
  async getMyTickets(userId: string) {
    console.log(`🎫 Fetching tickets for user: ${userId}`);
    const tickets = await this.ticketModel
      .find({ currentOwner: new Types.ObjectId(userId), status: { $ne: 'transferred' } })
      .populate('eventId', 'name venue eventDates bannerUrl')
      .populate('zoneId', 'name')
      .sort({ createdAt: -1 });

    console.log(`✅ Found ${tickets.length} tickets for user ${userId}`);
    return tickets;
  }


  // ── Transfer Ticket ───────────────────────────────────────────────────────
  async transferTicket(ticketId: string, fromUserId: string, toPhone: string) {
    const ticket = await this.ticketModel.findById(ticketId);
    if (!ticket) throw new NotFoundException('Ticket not found');
    if (!ticket.transferable) throw new BadRequestException('Ticket not transferable');
    if (ticket.type !== 'regular') throw new BadRequestException('Only regular passes can be transferred');
    if (ticket.status !== 'active') throw new BadRequestException('Ticket is not active');
    if (ticket.currentOwner.toString() !== fromUserId) throw new BadRequestException('Not your ticket');

    // Find recipient — query User by phone
    const normalizedPhone = toPhone.startsWith('+') ? toPhone : `+91${toPhone}`;
    const rawPhone = toPhone.replace('+91', '');

    const recipient = await this.userModel.findOne({
      $or: [
        { phoneNumber: toPhone },
        { phoneNumber: normalizedPhone },
        { phoneNumber: rawPhone }
      ]
    });

    if (!recipient) {
      throw new BadRequestException('Recipient not found. Please ask them to register first.');
    }

    const toUserId = recipient._id;

    await this.ticketModel.updateOne(
      { _id: ticketId },
      {
        $set: { currentOwner: toUserId, status: 'active' },
        $push: { transferChain: toUserId },
      }
    );

    await this.transferLogModel.create({
      ticketId: new Types.ObjectId(ticketId),
      fromUserId: new Types.ObjectId(fromUserId),
      toUserId,
      toPhone,
      status: 'completed',
    });

    return { success: true, message: 'Ticket transferred successfully' };
  }

  // ── Get QR Data ───────────────────────────────────────────────────────────
  async getQrData(ticketId: string, userId: string) {
    const ticket = await this.ticketModel.findById(ticketId);
    if (!ticket) throw new NotFoundException('Ticket not found');
    if (ticket.currentOwner.toString() !== userId) throw new BadRequestException('Not your ticket');
    if (ticket.type === 'season' && !ticket.isVerified) {
      throw new BadRequestException('Season pass not verified. Complete identity verification first.');
    }

    const eventDate = (await this.eventModel.findById(ticket.eventId))?.eventDates?.[0];
    return {
      id: ticketId,
      d: eventDate,
      t: ticket.type,
      sys: 'm',
      sig: this.generateQrHash(ticketId, eventDate),
    };
  }

  // ── Submit Season Pass Verification ──────────────────────────────────────
  async submitVerification(ticketId: string, body: any) {
    const ticket = await this.ticketModel.findById(ticketId);
    if (!ticket) throw new NotFoundException('Ticket not found');
    if (ticket.type !== 'season') throw new BadRequestException('Only season passes need verification');

    await this.ticketModel.updateOne({ _id: ticketId }, {
      $set: {
        verificationStatus: 'pending',
        verificationData: {
          selfieUrl: body.selfieUrl || '',
          idProofUrl: body.idProofUrl || '',
          submittedAt: new Date(),
        },
      },
    });
    return { success: true, message: 'Verification submitted. Admin will review within 24 hours.' };
  }

  private generateQrHash(id: string, eventDate: string): string {
    return crypto
      .createHmac('sha256', process.env.QR_SECRET || 'qr-hmac-secret-key')
      .update(id + eventDate)
      .digest('hex');
  }
}
