import { Controller, Get, Put, Patch, Param, Body } from '@nestjs/common';
import { AdminService } from './admin.service';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  getStats() { return this.adminService.getStats(); }

  @Get('users')
  getUsers() { return this.adminService.getAllUsers(); }

  @Put('users/:id/role')
  updateRole(@Param('id') id: string, @Body() body: { role: string }) {
    return this.adminService.updateUserRole(id, body.role);
  }

  @Get('verifications')
  getVerifications() {
    return this.adminService.getPendingVerifications();
  }

  @Patch('verifications/:id/status')
  updateVerificationStatus(@Param('id') id: string, @Body() body: { status: string; reason?: string }) {
    return this.adminService.updateVerificationStatus(id, body.status, body.reason);
  }

  @Patch('tickets/:id/verify')
  verifyTicket(@Param('id') id: string) {
    return this.adminService.verifyTicket(id);
  }


  @Get('settings')
  getSettings() {
    return this.adminService.getSettings();
  }

  @Patch('settings')
  updateSettings(@Body() body: any) {
    return this.adminService.updateSettings(body);
  }
}
