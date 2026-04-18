import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class User extends Document {
  @Prop({ required: true, unique: true })
  phoneNumber: string;

  @Prop()
  name: string;

  @Prop({ default: 'user', enum: ['user', 'admin', 'scanner', 'zone_manager'] })
  role: string;

  @Prop({ default: false })
  isVerified: boolean;

  @Prop()
  lastLogin: Date;

  @Prop()
  deviceId: string;
}

export const UserSchema = SchemaFactory.createForClass(User);
