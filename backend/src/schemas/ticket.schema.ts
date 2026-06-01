import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type TicketDocument = Ticket & Document;

@Schema({ timestamps: true })
export class Ticket {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Event', required: true })
  eventId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Zone', required: true })
  zoneId: Types.ObjectId;

  @Prop({ required: true, enum: ['regular', 'season'] })
  type: string;

  @Prop()
  date: string; // YYYY-MM-DD for regular passes

  @Prop({ required: true })
  category: string; // 'VIP', 'General', 'Premium'

  @Prop({ required: true, unique: true })
  qrHash: string;

  // Regular Pass
  @Prop({ default: false })
  isScanned: boolean;

  // Season Pass Daily
  @Prop({ default: false })
  isScannedToday: boolean;

  @Prop({ default: 0 })
  totalScans: number;

  @Prop()
  lastScannedAt: Date;

  // Season Pass Identity Verification
  @Prop({ default: false })
  isVerified: boolean;

  @Prop({ default: 'pending', enum: ['pending', 'approved', 'rejected'] })
  verificationStatus: string;

  @Prop({ type: Object })
  verificationData: {
    selfieUrl: string;
    idProofUrl: string;
    submittedAt: Date;
    reviewedBy: string;
    reviewNote: string;
  };

  // Transfer
  @Prop({ default: false })
  transferable: boolean;

  @Prop({ type: [Types.ObjectId], ref: 'User', default: [] })
  transferChain: Types.ObjectId[];

  @Prop({ type: Types.ObjectId, ref: 'User' })
  currentOwner: Types.ObjectId;

  // Payment
  @Prop()
  razorpayOrderId: string;

  @Prop()
  razorpayPaymentId: string;

  @Prop({ default: 0 })
  basePrice: number;

  @Prop({ default: 0 })
  gstAmount: number;

  @Prop({ default: 0 })
  totalAmount: number;

  // Source
  @Prop({ default: 'purchase', enum: ['purchase', 'sponsor', 'complimentary'] })
  source: string;

  @Prop({ type: Types.ObjectId, ref: 'Sponsor' })
  sponsorId: Types.ObjectId;

  // Status
  @Prop({ default: 'active', enum: ['active', 'used', 'expired', 'transferred', 'cancelled'] })
  status: string;

  @Prop({ default: 1 })
  quantity: number;
}

export const TicketSchema = SchemaFactory.createForClass(Ticket);
TicketSchema.index({ qrHash: 1 }, { unique: true });
TicketSchema.index({ userId: 1, eventId: 1 });
TicketSchema.index({ status: 1 });
TicketSchema.index({ eventId: 1, zoneId: 1 });
