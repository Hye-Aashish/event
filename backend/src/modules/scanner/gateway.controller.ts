import { Controller, Post, Get, Body, Param } from '@nestjs/common';
import { ScannerService } from './scanner.service';

@Controller('gate')
export class ScanGatewayController {
  constructor(private readonly scannerService: ScannerService) {}

  @Post('scan')
  handleScan(@Body() payload: any) {
    const { sys, scannerId } = payload;
    // Route to private system if sys = 'p'
    if (sys === 'p') {
      return { success: false, message: 'Private system routing (separate service)' };
    }
    return this.scannerService.validateScan(payload, scannerId);
  }

  @Post('verify')
  handleVerify(@Body() payload: any) {
    return this.scannerService.validateScan(payload, undefined, true);
  }

  @Get('logs/:eventId')
  getLogs(@Param('eventId') eventId: string) {
    return this.scannerService.getScanLogs(eventId);
  }
}
