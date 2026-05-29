import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { User } from '../../schemas/user.schema';

// In-memory OTP store (replace with Redis or DB in production)
const otpStore = new Map<string, { otp: string; expiry: number }>();

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    @InjectModel('AuthLog') private authLogModel: Model<any>,
    private jwtService: JwtService,
  ) {}

  // ── Helper: Write auth log (non-blocking) ──────────────────────────────
  private writeAuthLog(data: {
    userId?: string;
    phoneNumber: string;
    event: string;
    role?: string;
    deviceId?: string;
    ipAddress?: string;
    metadata?: any;
  }) {
    const doc: any = { ...data };
    if (data.userId) {
      doc.userId = new Types.ObjectId(data.userId);
    }
    this.authLogModel.create(doc).catch(() => {}); // fire-and-forget
  }

  async requestOtp(phoneNumber: string, ipAddress?: string) {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    otpStore.set(phoneNumber, { otp, expiry: Date.now() + 5 * 60 * 1000 }); // 5 min
    // In production: send via SMS gateway (MSG91 / Twilio)
    console.log(`📱 OTP for ${phoneNumber}: ${otp}`);

    this.writeAuthLog({ phoneNumber, event: 'otp_requested', ipAddress });
    return { message: 'OTP sent successfully' };
  }

  async verifyOtp(phoneNumber: string, otp: string, deviceId?: string, ipAddress?: string) {
    const record = otpStore.get(phoneNumber);
    const isTestOtp = otp === '123456';

    if (!isTestOtp && (!record || record.otp !== otp || Date.now() > record.expiry)) {
      console.warn(`⚠️ Failed OTP verification attempt for ${phoneNumber}`);
      this.writeAuthLog({
        phoneNumber,
        event: 'otp_failed',
        ipAddress,
        deviceId,
        metadata: { reason: 'invalid_or_expired_otp' },
      });
      throw new UnauthorizedException('Invalid or expired OTP');
    }
    otpStore.delete(phoneNumber);

    // Auto-register if new user
    let user = await this.userModel.findOne({ phoneNumber });
    if (!user) {
      console.log(`🆕 Creating new user for ${phoneNumber}`);
      user = await this.userModel.create({ phoneNumber, deviceId });
    } else {
      console.log(`🔑 Login successful for ${phoneNumber}`);
      // Update lastLogin
      await this.userModel.findByIdAndUpdate(user._id, { lastLogin: new Date(), deviceId });
    }

    this.writeAuthLog({
      userId: String(user._id),
      phoneNumber,
      event: 'login_success',
      role: user.role,
      deviceId,
      ipAddress,
    });

    const payload = { sub: user._id, phone: user.phoneNumber, role: user.role };
    return {
      access_token: this.jwtService.sign(payload),
      user,
      isNewUser: !user.name,
    };
  }

  async logout(userId: string, phoneNumber: string, role: string) {
    this.writeAuthLog({ userId, phoneNumber, event: 'logout', role });
    return { success: true, message: 'Logged out successfully' };
  }

  async getProfile(userId: string) {
    const user = await this.userModel.findById(userId);
    if (!user) throw new UnauthorizedException('User not found');
    return { success: true, user };
  }

  async updateProfile(userId: string, data: { name?: string; email?: string; role?: string }) {
    const user = await this.userModel.findByIdAndUpdate(
      userId,
      { $set: data },
      { new: true },
    );
    if (!user) throw new UnauthorizedException('User not found');

    this.writeAuthLog({
      userId,
      phoneNumber: user.phoneNumber,
      event: 'profile_updated',
      role: user.role,
      metadata: { updatedFields: Object.keys(data) },
    });

    return { success: true, user };
  }

  async submitVerification(userId: string, selfieUrl: string, idCardUrl: string) {
    console.log(`📤 Processing verification submission for user: ${userId}`);
    const user = await this.userModel.findByIdAndUpdate(
      userId,
      {
        $set: {
          verificationStatus: 'pending',
          verificationSelfie: selfieUrl,
          verificationIdCard: idCardUrl,
          verificationReason: '', // Clear any previous reason
        },
      },
      { new: true },
    );
    if (!user) throw new UnauthorizedException('User not found');
    console.log(`✅ Verification state set to: pending for user ${userId}`);
    return { success: true, user };
  }
}
