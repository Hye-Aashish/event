import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Ticket, TicketDocument } from '../../schemas/ticket.schema';
import { Event, EventDocument } from '../../schemas/event.schema';
import { Zone, ZoneDocument } from '../../schemas/zone.schema';
import { TransferLog } from '../../schemas/log.schema';
import * as crypto from 'crypto';
import Razorpay from 'razorpay';

@Injectable()
export class TicketsService {
  private razorpay: Razorpay;

  constructor(
    @InjectModel(Ticket.name) private ticketModel: Model<TicketDocument>,
    @InjectModel(Event.name) private eventModel: Model<EventDocument>,
    @InjectModel(Zone.name) private zoneModel: Model<ZoneDocument>,
    @InjectModel('TransferLog') private transferLogModel: Model<any>,
  ) {
    this.razorpay = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder',
      key_secret: process.env.RAZORPAY_KEY_SECRET || 'placeholder',
    });
  }

  // ── Create Razorpay Order ─────────────────────────────────────────────────
  async createOrder(userId: string, body: { eventId: string; zoneId: string; type: string; category: string; quantity: number }) {
    const event = await this.eventModel.findById(body.eventId);
    if (!event) throw new NotFoundException('Event not found');
    if (event.status !== 'published') throw new BadRequestException('Event not available');

    const basePrice = event.ticketPricing?.[body.type]?.[body.category] || 0;
    const gstAmount = event.gstEnabled ? Math.round(basePrice * (event.gstPercentage / 100)) : 0;
    const totalPerTicket = basePrice + gstAmount;
    const totalAmount = totalPerTicket * body.quantity;

    const order = await this.razorpay.orders.create({
      amount: totalAmount * 100, // paise
      currency: 'INR',
      receipt: `rcpt_${Date.now()}`,
      notes: { userId, eventId: body.eventId, type: body.type, category: body.category, quantity: String(body.quantity) },
    });

    return { order, basePrice, gstAmount, totalAmount };
  }

  // ── Verify Payment & Create Tickets ──────────────────────────────────────
  async verifyAndCreate(userId: string, body: any) {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, eventId, zoneId, type, category, quantity } = body;

    const expectedSig = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || 'placeholder')
      .update(`${razorpay_order_id}|${razorpay_payment_id}`)
      .digest('hex');

    if (expectedSig !== razorpay_signature) {
      throw new BadRequestException('Payment verification failed');
    }

    const event = await this.eventModel.findById(eventId);
    const basePrice = event.ticketPricing?.[type]?.[category] || 0;
    const gstAmount = event.gstEnabled ? Math.round(basePrice * (event.gstPercentage / 100)) : 0;

    const tickets = [];
    for (let i = 0; i < quantity; i++) {
      const ticketId = new Types.ObjectId().toString();
      const qrHash = this.generateQrHash(ticketId, eventId);

      const ticket = await this.ticketModel.create({
        userId, eventId, zoneId, type, category,
        qrHash,
        razorpayOrderId: razorpay_order_id,
        razorpayPaymentId: razorpay_payment_id,
        basePrice, gstAmount,
        totalAmount: basePrice + gstAmount,
        transferable: type === 'regular',
        currentOwner: userId,
        source: 'purchase',
        status: 'active',
      });
      tickets.push(ticket);
    }

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
    if (query.type)    filter.type    = query.type;
    if (query.status)  filter.status  = query.status;
    return this.ticketModel
      .find(filter)
      .populate('userId',  'phoneNumber name')
      .populate('eventId', 'name')
      .populate('zoneId',  'name')
      .sort({ createdAt: -1 })
      .limit(200)
      .lean();
  }

  // ── My Tickets ────────────────────────────────────────────────────────────
  async getMyTickets(userId: string) {
    return this.ticketModel
      .find({ currentOwner: userId, status: { $ne: 'transferred' } })
      .populate('eventId', 'name venue eventDates bannerUrl')
      .populate('zoneId', 'name')
      .sort({ createdAt: -1 });
  }


  // ── Transfer Ticket ───────────────────────────────────────────────────────
  async transferTicket(ticketId: string, fromUserId: string, toPhone: string) {
    const ticket = await this.ticketModel.findById(ticketId);
    if (!ticket) throw new NotFoundException('Ticket not found');
    if (!ticket.transferable) throw new BadRequestException('Ticket not transferable');
    if (ticket.type !== 'regular') throw new BadRequestException('Only regular passes can be transferred');
    if (ticket.status !== 'active') throw new BadRequestException('Ticket is not active');
    if (ticket.currentOwner.toString() !== fromUserId) throw new BadRequestException('Not your ticket');

    // Find recipient — in production, query User by phone
    const toUserId = new Types.ObjectId(); // Placeholder — replace with real user lookup

    await this.ticketModel.updateOne(
      { _id: ticketId },
      {
        $set: { currentOwner: toUserId, status: 'active' },
        $push: { transferChain: toUserId },
      }
    );

    await this.transferLogModel.create({
      ticketId, fromUserId, toUserId, toPhone, status: 'completed',
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
          selfieUrl:   body.selfieUrl   || '',
          idProofUrl:  body.idProofUrl  || '',
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
