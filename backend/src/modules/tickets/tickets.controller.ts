import { Controller, Post, Get, Body, Param, Query } from '@nestjs/common';
import { TicketsService } from './tickets.service';

@Controller('tickets')
export class TicketsController {
  constructor(private readonly ticketsService: TicketsService) {}

  @Post('order')
  createOrder(@Body() body: any) {
    return this.ticketsService.createOrder(body.userId, body);
  }

  @Post('verify-payment')
  verifyPayment(@Body() body: any) {
    return this.ticketsService.verifyAndCreate(body.userId, body);
  }

  @Get('all')
  getAllTickets(@Query() query: any) {
    return this.ticketsService.getAllTickets(query);
  }

  @Get('my/:userId')
  getMyTickets(@Param('userId') userId: string) {
    return this.ticketsService.getMyTickets(userId);
  }

  @Post(':id/transfer')
  transfer(@Param('id') id: string, @Body() body: any) {
    return this.ticketsService.transferTicket(id, body.fromUserId, body.toPhone);
  }

  @Post(':id/submit-verification')
  submitVerification(@Param('id') id: string, @Body() body: any) {
    return this.ticketsService.submitVerification(id, body);
  }

  @Get(':id/qr/:userId')
  getQr(@Param('id') id: string, @Param('userId') userId: string) {
    return this.ticketsService.getQrData(id, userId);
  }

  @Post('sponsor/issue')
  issueSponsored(@Body() body: any) {
    return this.ticketsService.issueSponsorTicket(body.sponsorId, body, body.adminId);
  }
}
