import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SettingsDocument = Settings & Document;

@Schema({ timestamps: true })
export class Settings {
  @Prop({ default: 'global' })
  key: string;

  @Prop()
  razorpayKeyId: string;

  @Prop()
  razorpayKeySecret: string;

  @Prop({ default: 18 })
  defaultGstPercentage: number;

  @Prop({ default: 10 })
  maxTicketsPerOrder: number;
}

export const SettingsSchema = SchemaFactory.createForClass(Settings);
