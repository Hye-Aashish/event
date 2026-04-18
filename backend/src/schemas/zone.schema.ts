import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ZoneDocument = Zone & Document;

@Schema({ timestamps: true })
export class Zone {
  @Prop({ required: true })
  name: string;

  @Prop({ type: Types.ObjectId, ref: 'Event', required: true })
  eventId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  ownerId: Types.ObjectId; // Zone Manager

  @Prop({ default: 0 })
  capacity: number;

  @Prop({ default: 0 })
  currentCount: number;

  @Prop({ default: 0 })
  availableSeats: number;

  @Prop({ default: 0 })
  price: number;

  @Prop()
  type: string; // daily/season

  @Prop()
  color: string;

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ default: false })
  autoVerifySeasonPass: boolean;

  @Prop({ type: [String], default: [] })
  allowedTicketCategories: string[]; // ['VIP', 'General', 'Premium']
}

export const ZoneSchema = SchemaFactory.createForClass(Zone);
ZoneSchema.index({ eventId: 1 });
ZoneSchema.index({ ownerId: 1 });
