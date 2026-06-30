import { Controller, Post, Get, Patch, Delete, Body, UseGuards, Request } from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { Throttle, SkipThrottle } from '@nestjs/throttler';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // ── Rate limited: max 3 OTP requests per minute per IP (prevents SMS bombing) ──
  @Throttle({ default: { ttl: 60000, limit: 3 } })
  @Post('send-otp')
  async sendOtp(@Body('phone') phone: string, @Request() req) {
    const ip = req.headers['x-forwarded-for'] || req.socket?.remoteAddress || '';
    return this.authService.requestOtp(phone, ip);
  }

  // ── Rate limited: max 5 verify attempts per minute (prevents OTP brute force) ──
  @Throttle({ default: { ttl: 60000, limit: 5 } })
  @Post('verify-otp')
  async verifyOtp(@Body() body: { phone: string; otp: string; deviceId?: string }, @Request() req) {
    const ip = req.headers['x-forwarded-for'] || req.socket?.remoteAddress || '';
    return this.authService.verifyOtp(body.phone, body.otp, body.deviceId, ip);
  }

  @SkipThrottle()
  @UseGuards(JwtAuthGuard)
  @Post('logout')
  async logout(@Request() req) {
    return this.authService.logout(req.user.sub, req.user.phone, req.user.role);
  }

  @SkipThrottle()
  @UseGuards(JwtAuthGuard)
  @Get('profile')
  async getProfile(@Request() req) {
    return this.authService.getProfile(req.user.sub);
  }

  @SkipThrottle()
  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  async updateProfile(@Request() req, @Body() body: UpdateProfileDto) {
    return this.authService.updateProfile(req.user.sub, body);
  }

  @SkipThrottle()
  @UseGuards(JwtAuthGuard)
  @Post('verify/submit')
  async submitVerification(@Request() req, @Body() body: { selfieUrl: string; idCardUrl: string }) {
    return this.authService.submitVerification(req.user.sub, body.selfieUrl, body.idCardUrl);
  }

  @SkipThrottle()
  @UseGuards(JwtAuthGuard)
  @Delete('account')
  async deleteAccount(@Request() req) {
    return this.authService.deleteAccount(req.user.sub);
  }
}
