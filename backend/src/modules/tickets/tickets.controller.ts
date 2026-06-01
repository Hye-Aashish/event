import { Controller, Post, Get, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { TicketsService } from './tickets.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('tickets')
export class TicketsController {
  constructor(private readonly ticketsService: TicketsService) {}

  // ── Get max tickets per order setting (used by mobile app on booking sheet) ──
  @UseGuards(JwtAuthGuard)
  @Get('settings/max-qty')
  getMaxQty() {
    return this.ticketsService.getMaxTicketsPerOrder();
  }

  @UseGuards(JwtAuthGuard)
  @Post('order')
  createOrder(@Request() req, @Body() body: any) {
    return this.ticketsService.createOrder(req.user.sub, body);
  }

  @UseGuards(JwtAuthGuard)
  @Post('verify-payment')
  verifyPayment(@Request() req, @Body() body: any) {
    return this.ticketsService.verifyAndCreate(req.user.sub, body);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @Get('all')
  getAllTickets(@Query() query: any) {
    return this.ticketsService.getAllTickets(query);
  }

  @UseGuards(JwtAuthGuard)
  @Get('my')
  getMyTickets(@Request() req) {
    return this.ticketsService.getMyTickets(req.user.sub);
  }

  // ── Transfer: Step 1 — initiate and send OTP to sender's phone ───────────
  // Initiate transfer of passes
  @UseGuards(JwtAuthGuard)
  @Post('transfer/initiate')
  initiateTransfer(@Request() req, @Body() body: any) {
    return this.ticketsService.initiateTransfer(req.user.sub, {
      ticketId: body.ticketId,
      quantity: Number(body.quantity),
      toPhone: body.toPhone,
    });
  }

  // ── Transfer: Step 2 — confirm with OTP and execute transfer ─────────────
  @UseGuards(JwtAuthGuard)
  @Post('transfer/confirm')
  confirmTransfer(@Request() req, @Body() body: any) {
    return this.ticketsService.confirmTransfer(req.user.sub, {
      ticketId: body.ticketId,
      quantity: Number(body.quantity),
      toPhone: body.toPhone,
      otp: body.otp,
    });
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/submit-verification')
  submitVerification(@Param('id') id: string, @Body() body: any) {
    return this.ticketsService.submitVerification(id, body);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':id/qr')
  getQr(@Param('id') id: string, @Request() req) {
    return this.ticketsService.getQrData(id, req.user.sub);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @Post('sponsor/issue')
  issueSponsored(@Body() body: any) {
    return this.ticketsService.issueSponsorTicket(body.sponsorId, body, body.adminId);
  }
}
