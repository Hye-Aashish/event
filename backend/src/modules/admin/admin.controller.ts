import { Controller, Get, Put, Patch, Delete, Param, Body, Query, UseGuards, Request } from '@nestjs/common';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // ── Dashboard ──────────────────────────────────────────────────────────────
  @Get('stats')
  getStats() { return this.adminService.getStats(); }

  // ── Users ──────────────────────────────────────────────────────────────────
  @Get('users')
  getUsers() { return this.adminService.getAllUsers(); }

  @Get('users/:id')
  getUserById(@Param('id') id: string) {
    return this.adminService.getUserById(id);
  }

  @Put('users/:id/role')
  updateRole(@Param('id') id: string, @Body() body: { role: string }, @Request() req) {
    return this.adminService.updateUserRole(id, body.role, req.user.sub);
  }

  @Patch('users/:id/status')
  updateUserStatus(@Param('id') id: string, @Body() body: { status: string }, @Request() req) {
    return this.adminService.updateUserStatus(id, body.status, req.user.sub);
  }

  @Delete('users/:id')
  deleteUser(@Param('id') id: string, @Request() req) {
    return this.adminService.deleteUserAccount(id, req.user.sub);
  }

  // ── User Analytics ─────────────────────────────────────────────────────────
  @Get('analytics/user/:id')
  getUserAnalytics(@Param('id') id: string) {
    return this.adminService.getUserAnalytics(id);
  }

  // ── Scanners ───────────────────────────────────────────────────────────────
  @Get('scanners')
  getScanners() { return this.adminService.getAllScanners(); }

  @Get('analytics/scanner/:id')
  getScannerAnalytics(@Param('id') id: string) {
    return this.adminService.getScannerAnalytics(id);
  }

  // ── Logs (Separate tabs: scan | transfer | admin | auth) ─────────────────
  @Get('logs')
  getLogs(
    @Query('type') type?: string,
    @Query('userId') userId?: string,
    @Query('role') role?: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
    @Query('eventId') eventId?: string,
  ) {
    return this.adminService.getLogs({ type, userId, role, dateFrom, dateTo, eventId } as any);
  }

  // ── Verifications ──────────────────────────────────────────────────────────
  @Get('verifications')
  getVerifications() {
    return this.adminService.getPendingVerifications();
  }

  @Patch('verifications/:id/status')
  updateVerificationStatus(
    @Param('id') id: string,
    @Body() body: { status: string; reason?: string },
    @Request() req,
  ) {
    return this.adminService.updateVerificationStatus(id, body.status, body.reason, req.user.sub);
  }

  // ── Tickets ────────────────────────────────────────────────────────────────
  @Patch('tickets/:id/verify')
  verifyTicket(@Param('id') id: string, @Request() req) {
    return this.adminService.verifyTicket(id, req.user.sub);
  }

  // ── Settings ───────────────────────────────────────────────────────────────
  @Get('settings')
  getSettings() {
    return this.adminService.getSettings();
  }

  @Patch('settings')
  updateSettings(@Body() body: any, @Request() req) {
    return this.adminService.updateSettings(body, req.user.sub);
  }
}
