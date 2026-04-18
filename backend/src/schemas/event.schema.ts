import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type EventDocument = Event & Document;

@Schema({ timestamps: true })
export class Event {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  description: string;

  @Prop()
  bannerUrl: string;

  @Prop()
  imageUrl: string;

  @Prop({ required: true })
  venue: string;

  @Prop({ required: true, type: [String] })
  eventDates: string[]; // ['2024-10-10', '2024-10-11']

  @Prop({ default: 'draft', enum: ['draft', 'published', 'cancelled', 'completed'] })
  status: string;

  @Prop({ default: false })
  gstEnabled: boolean;

  @Prop({ default: 18 })
  gstPercentage: number;

  @Prop({ default: false })
  autoVerifySeasonPass: boolean;

  @Prop({ type: Object })
  ticketPricing: {
    regular: { [category: string]: number };
    season: { [category: string]: number };
  };

  @Prop({ default: 0 })
  maxSponsorTickets: number;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  createdBy: Types.ObjectId;
}

export const EventSchema = SchemaFactory.createForClass(Event);
EventSchema.index({ status: 1 });
EventSchema.index({ eventDates: 1 });
