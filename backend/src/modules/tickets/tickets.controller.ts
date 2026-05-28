import { Controller, Post, Get, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { TicketsService } from './tickets.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('tickets')
export class TicketsController {
  constructor(private readonly ticketsService: TicketsService) {}

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

  @Get('all')
  getAllTickets(@Query() query: any) {
    return this.ticketsService.getAllTickets(query);
  }

  @UseGuards(JwtAuthGuard)
  @Get('my')
  getMyTickets(@Request() req) {
    return this.ticketsService.getMyTickets(req.user.sub);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/transfer')
  transfer(@Param('id') id: string, @Request() req, @Body() body: any) {
    return this.ticketsService.transferTicket(id, req.user.sub, body.toPhone);
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

  @Post('sponsor/issue')
  issueSponsored(@Body() body: any) {
    return this.ticketsService.issueSponsorTicket(body.sponsorId, body, body.adminId);
  }
}
