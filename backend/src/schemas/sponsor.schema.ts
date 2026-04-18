import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SponsorDocument = Sponsor & Document;

@Schema({ timestamps: true })
export class Sponsor {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  contactName: string;

  @Prop({ required: true })
  phone: string;

  @Prop()
  email: string;

  @Prop({ type: Types.ObjectId, ref: 'Event', required: true })
  eventId: Types.ObjectId;

  // Limit types: quantity-based, credit-based, combined
  @Prop({ default: 'quantity', enum: ['quantity', 'credit', 'combined'] })
  limitType: string;

  @Prop({ default: 0 })
  ticketQuota: number; // Max tickets they can issue

  @Prop({ default: 0 })
  ticketsUsed: number;

  @Prop({ default: 0 })
  creditLimit: number; // Max rupee value

  @Prop({ default: 0 })
  creditUsed: number;

  @Prop({ default: 'active', enum: ['active', 'suspended', 'exhausted'] })
  status: string;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  createdBy: Types.ObjectId;
}

export const SponsorSchema = SchemaFactory.createForClass(Sponsor);
SponsorSchema.index({ eventId: 1 });
SponsorSchema.index({ phone: 1 });
