import { Controller, Post, Get, Patch, Body, UseGuards, Request } from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('send-otp')
  async sendOtp(@Body('phone') phone: string, @Request() req) {
    const ip = req.headers['x-forwarded-for'] || req.socket?.remoteAddress || '';
    return this.authService.requestOtp(phone, ip);
  }

  @Post('verify-otp')
  async verifyOtp(@Body() body: { phone: string; otp: string; deviceId?: string }, @Request() req) {
    const ip = req.headers['x-forwarded-for'] || req.socket?.remoteAddress || '';
    return this.authService.verifyOtp(body.phone, body.otp, body.deviceId, ip);
  }

  @UseGuards(JwtAuthGuard)
  @Post('logout')
  async logout(@Request() req) {
    return this.authService.logout(req.user.sub, req.user.phone, req.user.role);
  }

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  async getProfile(@Request() req) {
    return this.authService.getProfile(req.user.sub);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  async updateProfile(@Request() req, @Body() body: UpdateProfileDto) {
    return this.authService.updateProfile(req.user.sub, body);
  }

  @UseGuards(JwtAuthGuard)
  @Post('verify/submit')
  async submitVerification(@Request() req, @Body() body: { selfieUrl: string; idCardUrl: string }) {
    return this.authService.submitVerification(req.user.sub, body.selfieUrl, body.idCardUrl);
  }
}
