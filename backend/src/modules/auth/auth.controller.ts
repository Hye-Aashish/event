import { Controller, Post, Get, Patch, Body, UseGuards, Request } from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('send-otp')
  async sendOtp(@Body('phone') phone: string) {
    return this.authService.requestOtp(phone);
  }

  @Post('verify-otp')
  async verifyOtp(@Body() body: { phone: string; otp: string }) {
    return this.authService.verifyOtp(body.phone, body.otp);
  }

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  async getProfile(@Request() req) {
    return this.authService.getProfile(req.user.sub);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  async updateProfile(@Request() req, @Body() body: { name?: string; email?: string; role?: string }) {
    return this.authService.updateProfile(req.user.sub, body);
  }

  @UseGuards(JwtAuthGuard)
  @Post('verify/submit')
  async submitVerification(@Request() req, @Body() body: { selfieUrl: string; idCardUrl: string }) {
    return this.authService.submitVerification(req.user.sub, body.selfieUrl, body.idCardUrl);
  }
}
