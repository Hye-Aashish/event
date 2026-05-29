import { Controller, Post, Get, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ScannerService } from './scanner.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('gate')
export class ScanGatewayController {
  constructor(private readonly scannerService: ScannerService) {}

  @Roles('admin', 'scanner')
  @Post('scan')
  handleScan(@Body() payload: any, @Request() req) {
    const { sys } = payload;
    console.log(`📡 [Scan Request] Scanner ID: ${req.user?.sub} | Phone: ${req.user?.phone} | Payload:`, payload);
    // Route to private system if sys = 'p'
    if (sys === 'p') {
      return { success: false, message: 'Private system routing (separate service)' };
    }
    return this.scannerService.validateScan(payload, req.user.sub);
  }

  @Roles('admin', 'scanner')
  @Post('verify')
  handleVerify(@Body() payload: any, @Request() req) {
    console.log(`🔍 [Verify Request] Scanner ID: ${req.user?.sub} | Phone: ${req.user?.phone} | Payload:`, payload);
    return this.scannerService.validateScan(payload, req.user.sub, true);
  }

  @Roles('admin')
  @Get('logs/:eventId')
  getLogs(@Param('eventId') eventId: string) {
    return this.scannerService.getScanLogs(eventId);
  }
}
