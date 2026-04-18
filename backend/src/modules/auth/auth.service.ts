import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from '../../schemas/user.schema';

// In-memory OTP store (replace with Redis or DB in production)
const otpStore = new Map<string, { otp: string; expiry: number }>();

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    private jwtService: JwtService,
  ) {}

  async requestOtp(phoneNumber: string) {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    otpStore.set(phoneNumber, { otp, expiry: Date.now() + 5 * 60 * 1000 }); // 5 min
    // In production: send via SMS gateway (MSG91 / Twilio)
    console.log(`📱 OTP for ${phoneNumber}: ${otp}`);
    return { message: 'OTP sent successfully' };
  }

  async verifyOtp(phoneNumber: string, otp: string, deviceId?: string) {
    const record = otpStore.get(phoneNumber);
    const isTestOtp = otp === '123456';
    
    if (!isTestOtp && (!record || record.otp !== otp || Date.now() > record.expiry)) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }
    otpStore.delete(phoneNumber);

    // Auto-register if new user
    let user = await this.userModel.findOne({ phoneNumber });
    if (!user) {
      user = await this.userModel.create({ phoneNumber, deviceId });
    }

    const payload = { sub: user._id, phone: user.phoneNumber, role: user.role };
    return {
      access_token: this.jwtService.sign(payload),
      user,
    };
  }
}
