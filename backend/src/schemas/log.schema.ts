import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

// ─── Scan Log ────────────────────────────────────────────────────────────────
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
ScanLogSchema.index({ scannerId: 1, createdAt: -1 });
ScanLogSchema.index({ status: 1 });

// ─── Transfer Log ─────────────────────────────────────────────────────────────
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

  @Prop({ type: Object })
  metadata: {
    quantity: number;
    batchTransfer: boolean;
    otpVerified: boolean;
  };
}
export const TransferLogSchema = SchemaFactory.createForClass(TransferLog);
TransferLogSchema.index({ fromUserId: 1, createdAt: -1 });
TransferLogSchema.index({ toUserId: 1, createdAt: -1 });
TransferLogSchema.index({ ticketId: 1 });

// ─── Admin Log ────────────────────────────────────────────────────────────────
// Records every admin action: create/update/delete events, zones, verify users, change roles, etc.
@Schema({ timestamps: true, collection: 'admin_logs' })
export class AdminLog {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  adminId: Types.ObjectId;

  @Prop({ required: true })
  // Examples: 'create_event', 'update_event', 'delete_event',
  //           'create_zone', 'update_zone',
  //           'update_user_role', 'update_verification', 'verify_ticket',
  //           'update_settings'
  action: string;

  @Prop({ type: Types.ObjectId })
  targetId: Types.ObjectId; // ID of the affected resource

  @Prop()
  targetType: string; // 'event' | 'zone' | 'user' | 'ticket' | 'settings' | 'sponsor'

  @Prop()
  targetName: string; // Human-readable name of the affected resource

  @Prop({ type: Object })
  changes: any; // { before: {...}, after: {...} } snapshot

  @Prop({ type: Object })
  metadata: any; // Any extra context
}
export const AdminLogSchema = SchemaFactory.createForClass(AdminLog);
AdminLogSchema.index({ adminId: 1, createdAt: -1 });
AdminLogSchema.index({ action: 1, createdAt: -1 });
AdminLogSchema.index({ targetType: 1, targetId: 1 });

// ─── Auth Log ─────────────────────────────────────────────────────────────────
// Records login, logout, OTP requests, OTP failures for all users (user, scanner, admin)
@Schema({ timestamps: true, collection: 'auth_logs' })
export class AuthLog {
  @Prop({ type: Types.ObjectId, ref: 'User' })
  userId: Types.ObjectId;

  @Prop()
  phoneNumber: string; // Always store phone even if userId is null (e.g., failed OTP)

  @Prop({
    required: true,
    enum: ['otp_requested', 'otp_failed', 'login_success', 'logout', 'profile_updated'],
  })
  event: string;

  @Prop()
  role: string; // 'user' | 'admin' | 'scanner' | 'zone_manager' | null

  @Prop()
  deviceId: string;

  @Prop()
  ipAddress: string;

  @Prop({ type: Object })
  metadata: any; // e.g., { reason: 'invalid_otp' }
}
export const AuthLogSchema = SchemaFactory.createForClass(AuthLog);
AuthLogSchema.index({ userId: 1, createdAt: -1 });
AuthLogSchema.index({ phoneNumber: 1, createdAt: -1 });
AuthLogSchema.index({ event: 1, createdAt: -1 });
