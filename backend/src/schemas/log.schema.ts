import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true, collection: 'scan_logs' })
export class ScanLog {
  @Prop({ type: Types.ObjectId, ref: 'Ticket' })
  ticketId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Event' })
  eventId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Zone' })
  zoneId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  scannerId: Types.ObjectId;

  @Prop({ required: true, enum: ['success', 'duplicate', 'invalid_sig', 'expired', 'time_invalid', 'unverified', 'fraud'] })
  status: string;

  @Prop()
  deviceId: string;

  @Prop({ type: Object })
  rawPayload: any;

  @Prop()
  message: string;
}

export const ScanLogSchema = SchemaFactory.createForClass(ScanLog);
ScanLogSchema.index({ ticketId: 1, createdAt: -1 });
ScanLogSchema.index({ eventId: 1, createdAt: -1 });
ScanLogSchema.index({ status: 1 });

// ─── Transfer Log ───────────────────────────────────────────────────────────
@Schema({ timestamps: true, collection: 'transfer_logs' })
export class TransferLog {
  @Prop({ type: Types.ObjectId, ref: 'Ticket', required: true })
  ticketId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  fromUserId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  toUserId: Types.ObjectId;

  @Prop()
  toPhone: string;

  @Prop({ default: 'completed', enum: ['pending', 'completed', 'rejected'] })
  status: string;
}
export const TransferLogSchema = SchemaFactory.createForClass(TransferLog);

// ─── Admin Log ───────────────────────────────────────────────────────────────
@Schema({ timestamps: true, collection: 'admin_logs' })
export class AdminLog {
  @Prop({ type: Types.ObjectId, ref: 'User' })
  adminId: Types.ObjectId;

  @Prop({ required: true })
  action: string; // 'create_event', 'update_zone', 'approve_verification'

  @Prop({ type: Object })
  metadata: any;
}
export const AdminLogSchema = SchemaFactory.createForClass(AdminLog);
