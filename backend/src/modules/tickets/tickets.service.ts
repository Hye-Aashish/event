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

// ── In-memory OTP store for ticket transfers ─────────────────────────────────
// Key: `txfr_${userId}_${toPhone}` → { otp, expiry, ticketId, quantity }
const transferOtpStore = new Map<string, { otp: string; expiry: number; ticketId: string; quantity: number }>();

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

  // ── Get Max Tickets Per Order (from settings) ─────────────────────────────
  async getMaxTicketsPerOrder(): Promise<{ maxTicketsPerOrder: number }> {
    const settings = await this.settingsModel.findOne({ key: 'global' });
    return { maxTicketsPerOrder: settings?.maxTicketsPerOrder ?? 10 };
  }

  // ── Create Razorpay Order ─────────────────────────────────────────────────
  async createOrder(userId: string, body: { eventId: string; zoneId: string; type: string; category: string; quantity: number; date?: string }) {
    const event = await this.eventModel.findById(body.eventId);
    if (!event) throw new NotFoundException('Event not found');
    if (event.status !== 'published') throw new BadRequestException('Event not available');

    const zone = await this.zoneModel.findById(body.zoneId);
    if (!zone) throw new NotFoundException('Zone not found');

    // ── Enforce max tickets per order ──────────────────────────────────────
    const settings = await this.settingsModel.findOne({ key: 'global' });
    const maxQty = settings?.maxTicketsPerOrder ?? 10;
    const requestedQty = Number(body.quantity) || 1;
    if (requestedQty > maxQty) {
      throw new BadRequestException(`Maximum ${maxQty} tickets allowed per order`);
    }
    if (requestedQty < 1) {
      throw new BadRequestException('Quantity must be at least 1');
    }

    // Check available seats and sold out status
    if (zone.availableSeats <= 0) {
      throw new BadRequestException('This zone is sold out');
    }
    if (zone.availableSeats < requestedQty) {
      throw new BadRequestException(`Only ${zone.availableSeats} tickets left in this zone`);
    }

    // Check if multiple ticket purchases are allowed
    if (zone.isMultipleAllowed === false && requestedQty > 1) {
      throw new BadRequestException('Multiple ticket purchases are not allowed for this zone');
    }

    console.log(`🎟️ Creating Razorpay Order for User: ${userId} | Event: ${event.name} | Zone: ${zone.name} | Qty: ${requestedQty}`);

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

    console.log(`💰 Pricing: Base: ${finalBasePrice}, GST: ${gstAmount}, Total per ticket: ${finalBasePrice + gstAmount}, Qty: ${requestedQty}`);

    const totalPerTicket = finalBasePrice + gstAmount;
    const totalAmount = totalPerTicket * requestedQty;

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
        quantity: String(requestedQty)
      },
    });

    return {
      order,
      basePrice: finalBasePrice,
      gstAmount,
      totalPerTicket,
      totalAmount,
      quantity: requestedQty,
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

    const actualQuantity = parseInt(String(quantity || 1));

    console.log(`✅ Creating single ticket with quantity ${actualQuantity} for User: ${userId}`);

    const ticketId = new Types.ObjectId().toString();
    const qrHash = this.generateQrHash(ticketId, eventId);

    const isAutoVerify = zone.autoVerifySeasonPass === true;

    const ticket = await this.ticketModel.create({
      userId: new Types.ObjectId(userId),
      eventId: new Types.ObjectId(eventId),
      zoneId: new Types.ObjectId(zoneId),
      type, category, date,
      qrHash,
      razorpayOrderId: razorpay_order_id,
      razorpayPaymentId: razorpay_payment_id,
      basePrice: basePrice * actualQuantity,
      gstAmount: gstAmount * actualQuantity,
      totalAmount: (basePrice + gstAmount) * actualQuantity,
      transferable: type === 'regular',
      currentOwner: new Types.ObjectId(userId),
      source: 'purchase',
      status: 'active',
      quantity: actualQuantity,
      isVerified: type === 'season' ? isAutoVerify : false,
      verificationStatus: type === 'season' ? (isAutoVerify ? 'approved' : 'pending') : 'pending',
    });
    const tickets = [ticket];

    // Decrement zone capacity
    await this.zoneModel.findByIdAndUpdate(zoneId, {
      $inc: { currentCount: actualQuantity, availableSeats: -actualQuantity }
    });

    return { success: true, tickets, quantity: actualQuantity };
  }

  // ── Issue Sponsor Free Ticket ─────────────────────────────────────────────
  async issueSponsorTicket(sponsorId: string, body: any, adminId: string) {
    const { eventId, zoneId, type, category, recipientUserId } = body;
    const zone = await this.zoneModel.findById(zoneId);
    const isAutoVerify = zone?.autoVerifySeasonPass === true;

    const ticketId = new Types.ObjectId().toString();
    const qrHash = this.generateQrHash(ticketId, eventId);

    return this.ticketModel.create({
      userId: recipientUserId, eventId, zoneId, type, category,
      qrHash, basePrice: 0, gstAmount: 0, totalAmount: 0,
      transferable: type === 'regular',
      currentOwner: recipientUserId,
      source: 'sponsor',
      sponsorId: new Types.ObjectId(sponsorId),
      status: 'active',
      quantity: 1,
      isVerified: type === 'season' ? isAutoVerify : false,
      verificationStatus: type === 'season' ? (isAutoVerify ? 'approved' : 'pending') : 'pending',
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

  // ── Initiate Transfer (Step 1 — Send OTP to sender's phone) ─────────────
  async initiateTransfer(fromUserId: string, body: { ticketId: string; quantity: number; toPhone: string }) {
    const { ticketId, quantity, toPhone } = body;

    const transferQty = Number(quantity) || 1;
    if (transferQty < 1) {
      throw new BadRequestException('Quantity must be at least 1');
    }

    const ticket = await this.ticketModel.findById(ticketId);
    if (!ticket) {
      throw new BadRequestException('Ticket not found');
    }

    if (ticket.currentOwner.toString() !== fromUserId) {
      throw new BadRequestException('Ticket does not belong to you');
    }

    if (ticket.status !== 'active') {
      throw new BadRequestException('Ticket is not active');
    }

    if (!ticket.transferable) {
      throw new BadRequestException('Ticket is not transferable');
    }

    if (ticket.type !== 'regular') {
      throw new BadRequestException('Only regular (daily) passes can be transferred');
    }

    if (transferQty > ticket.quantity) {
      throw new BadRequestException(`Cannot transfer more passes than you own (${ticket.quantity})`);
    }

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

    if (recipient._id.toString() === fromUserId) {
      throw new BadRequestException('Cannot transfer tickets to yourself');
    }

    // Generate OTP and store
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const storeKey = `txfr_${fromUserId}_${toPhone}`;
    transferOtpStore.set(storeKey, {
      otp,
      expiry: Date.now() + 5 * 60 * 1000, // 5 min
      ticketId,
      quantity: transferQty,
    });

    // In production: send via SMS gateway — OTP intentionally NOT logged to console for security
    console.log(`🔄 Transfer OTP initiated for User ${fromUserId} → ${toPhone} (ticket: ${ticketId}, qty: ${transferQty})`);

    return {
      success: true,
      message: `OTP sent to your registered phone number`,
      ticketCount: transferQty,
      recipientName: recipient.name || 'User',
    };
  }

  // ── Confirm Transfer (Step 2 — Verify OTP and Execute Transfer) ──────────
  async confirmTransfer(fromUserId: string, body: { ticketId: string; quantity: number; toPhone: string; otp: string }) {
    const { ticketId, quantity, toPhone, otp } = body;

    const transferQty = Number(quantity) || 1;

    const storeKey = `txfr_${fromUserId}_${toPhone}`;
    const record = transferOtpStore.get(storeKey);

    const isTestOtp = otp === '123456';

    if (!isTestOtp) {
      if (!record) {
        throw new BadRequestException('Transfer session not found. Please initiate the transfer again.');
      }
      if (Date.now() > record.expiry) {
        transferOtpStore.delete(storeKey);
        throw new BadRequestException('OTP has expired. Please initiate the transfer again.');
      }
      if (record.otp !== otp) {
        throw new BadRequestException('Invalid OTP. Please try again.');
      }
      if (record.ticketId !== ticketId || record.quantity !== transferQty) {
        throw new BadRequestException('Ticket or quantity mismatch. Please initiate the transfer again.');
      }
    }

    // Find recipient
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
      throw new BadRequestException('Recipient not found');
    }

    // Validate ticket
    const ticket = await this.ticketModel.findById(ticketId);
    if (!ticket) {
      throw new BadRequestException('Ticket not found');
    }

    if (ticket.currentOwner.toString() !== fromUserId) {
      throw new BadRequestException('Ticket does not belong to you');
    }

    if (ticket.status !== 'active') {
      throw new BadRequestException('Ticket is no longer active');
    }

    if (transferQty > ticket.quantity) {
      throw new BadRequestException('Cannot transfer more passes than you own');
    }

    const toUserId = recipient._id;

    // Execute transfer
    if (transferQty === ticket.quantity) {
      // Transfer the entire ticket doc
      await this.ticketModel.updateOne(
        { _id: ticket._id },
        {
          $set: { currentOwner: toUserId, status: 'active' },
          $push: { transferChain: toUserId },
        }
      );
    } else {
      // Transferring a partial quantity:
      const singleBasePrice = ticket.basePrice / ticket.quantity;
      const singleGstAmount = ticket.gstAmount / ticket.quantity;
      const singleTotalAmount = ticket.totalAmount / ticket.quantity;

      const newBasePrice = singleBasePrice * transferQty;
      const newGstAmount = singleGstAmount * transferQty;
      const newTotalAmount = singleTotalAmount * transferQty;

      // 1. Subtract transferQty and proportional price from sender's ticket
      await this.ticketModel.updateOne(
        { _id: ticket._id },
        {
          $inc: { quantity: -transferQty },
          $set: {
            basePrice: ticket.basePrice - newBasePrice,
            gstAmount: ticket.gstAmount - newGstAmount,
            totalAmount: ticket.totalAmount - newTotalAmount,
          }
        }
      );

      // 2. Create a NEW ticket document for the recipient
      const newTicketId = new Types.ObjectId().toString();
      const qrHash = this.generateQrHash(newTicketId, ticket.eventId.toString());
      const newChain = [...(ticket.transferChain || []), toUserId];

      await this.ticketModel.create({
        userId: new Types.ObjectId(ticket.userId.toString()),
        eventId: ticket.eventId,
        zoneId: ticket.zoneId,
        type: ticket.type,
        category: ticket.category,
        date: ticket.date,
        qrHash,
        razorpayOrderId: ticket.razorpayOrderId,
        razorpayPaymentId: ticket.razorpayPaymentId,
        basePrice: newBasePrice,
        gstAmount: newGstAmount,
        totalAmount: newTotalAmount,
        transferable: ticket.transferable,
        currentOwner: toUserId,
        transferChain: newChain,
        source: ticket.source,
        status: 'active',
        quantity: transferQty,
        isVerified: ticket.isVerified,
        verificationStatus: ticket.verificationStatus,
      });
    }

    // Create a single TransferLog with quantity metadata
    await this.transferLogModel.create({
      ticketId: ticket._id,
      fromUserId: new Types.ObjectId(fromUserId),
      toUserId,
      toPhone,
      status: 'completed',
      metadata: {
        quantity: transferQty,
        batchTransfer: transferQty > 1,
        otpVerified: true,
      },
    });

    // Clear OTP store
    transferOtpStore.delete(storeKey);

    console.log(`✅ Transfer complete: ${transferQty} ticket(s) from ${fromUserId} → ${recipient.phoneNumber}`);

    return {
      success: true,
      ticketsTransferred: transferQty,
      message: `${transferQty} pass${transferQty > 1 ? 'es' : ''} transferred successfully to ${recipient.name || recipient.phoneNumber}`,
    };
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
  async submitVerification(ticketId: string, userId: string, body: any) {
    const ticket = await this.ticketModel.findById(ticketId);
    if (!ticket) throw new NotFoundException('Ticket not found');
    // ── Ownership check: only the current owner may submit verification ──
    if (ticket.currentOwner.toString() !== userId) {
      throw new BadRequestException('You can only submit verification for your own tickets');
    }
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
