import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { User } from '../../schemas/user.schema';
import { Ticket } from '../../schemas/ticket.schema';
import { Settings } from '../../schemas/settings.schema';

@Injectable()
export class AdminService {
  constructor(
    @InjectModel(User.name) private userModel: Model<any>,
    @InjectModel(Ticket.name) private ticketModel: Model<any>,
    @InjectModel(Settings.name) private settingsModel: Model<any>,
    @InjectModel('ScanLog') private scanLogModel: Model<any>,
    @InjectModel('TransferLog') private transferLogModel: Model<any>,
    @InjectModel('AdminLog') private adminLogModel: Model<any>,
    @InjectModel('AuthLog') private authLogModel: Model<any>,
    @InjectModel('Event') private eventModel: Model<any>,
  ) {}

  // ── Helper: Write admin log (non-blocking) ──────────────────────────────
  private writeAdminLog(data: {
    adminId: string;
    action: string;
    targetId?: string;
    targetType?: string;
    targetName?: string;
    changes?: any;
    metadata?: any;
  }) {
    this.adminLogModel.create({
      ...data,
      adminId: new Types.ObjectId(data.adminId),
      targetId: data.targetId ? new Types.ObjectId(data.targetId) : undefined,
    }).catch(() => {});
  }

  // ── Dashboard Stats ──────────────────────────────────────────────────────
  async getStats() {
    const totalUsers = await this.userModel.countDocuments();
    const totalTickets = await this.ticketModel.countDocuments();
    const totalEvents = await this.eventModel.countDocuments();
    const totalScans = await this.scanLogModel.countDocuments({ status: 'success' });

    const labels = [];
    const values = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const start = new Date(date).setHours(0, 0, 0, 0);
      const end = new Date(date).setHours(23, 59, 59, 999);
      const count = await this.ticketModel.countDocuments({
        createdAt: { $gte: new Date(start), $lte: new Date(end) }
      });
      labels.push(new Date(start).toLocaleDateString('en-US', { weekday: 'short' }));
      values.push(count);
    }

    return { totalUsers, totalTickets, totalScans, totalEvents, chartData: { labels, values } };
  }

  // ── Users ─────────────────────────────────────────────────────────────────
  async getAllUsers() {
    return this.userModel.find().sort({ createdAt: -1 }).select('-__v').lean();
  }

  async getUserById(id: string) {
    return this.userModel.findById(id).select('-__v').lean();
  }

  async updateUserRole(id: string, role: string, adminId: string) {
    const user = await this.userModel.findById(id).lean();
    const updated = await this.userModel.findByIdAndUpdate(id, { role }, { new: true });

    this.writeAdminLog({
      adminId,
      action: 'update_user_role',
      targetId: id,
      targetType: 'user',
      targetName: (user as any)?.phoneNumber || id,
      changes: { before: { role: (user as any)?.role }, after: { role } },
    });

    return updated;
  }

  // ── User Analytics ────────────────────────────────────────────────────────
  async getUserAnalytics(userId: string) {
    const uid = new Types.ObjectId(userId);

    // All tickets ever owned (initial purchase)
    const [purchased, transferred, receivedTransfers, authLogs] = await Promise.all([
      this.ticketModel.find({ userId: uid })
        .populate('eventId', 'name venue')
        .populate('zoneId', 'name')
        .sort({ createdAt: -1 })
        .lean(),

      this.transferLogModel.find({
        $or: [
          { fromUserId: uid },
          { fromUserId: userId }
        ]
      })
        .populate('ticketId', 'category type')
        .populate('toUserId', 'name phoneNumber')
        .sort({ createdAt: -1 })
        .lean(),

      this.transferLogModel.find({
        $or: [
          { toUserId: uid },
          { toUserId: userId }
        ]
      })
        .populate('ticketId', 'category type')
        .populate('fromUserId', 'name phoneNumber')
        .sort({ createdAt: -1 })
        .lean(),

      this.authLogModel.find({
        $or: [
          { userId: uid },
          { userId: userId }
        ]
      })
        .sort({ createdAt: -1 })
        .limit(50)
        .lean(),
    ]);

    // Current tickets in possession (currentOwner)
    const currentTickets = await this.ticketModel.find({
      currentOwner: uid,
      status: { $ne: 'transferred' },
    }).populate('eventId', 'name venue').populate('zoneId', 'name').sort({ createdAt: -1 }).lean();

    const totalSpent = purchased.reduce((sum: number, t: any) => sum + (t.totalAmount || 0), 0);
    const unused = currentTickets.filter((t: any) => t.status === 'active' && !t.isScanned).length;
    const used = currentTickets.filter((t: any) => t.isScanned || t.status === 'used').length;

    return {
      summary: {
        totalPurchased: purchased.length,
        totalSpent,
        totalTransferredOut: transferred.length,
        totalTransferredIn: receivedTransfers.length,
        currentlyHeld: currentTickets.length,
        unused,
        used,
      },
      purchasedTickets: purchased,
      currentTickets,
      transfersOut: transferred,
      transfersIn: receivedTransfers,
      authLogs,
    };
  }

  // ── Scanners ──────────────────────────────────────────────────────────────
  async getAllScanners() {
    return this.userModel.find({ role: { $in: ['scanner', 'zone_manager'] } })
      .sort({ createdAt: -1 }).select('-__v').lean();
  }

  async getScannerAnalytics(scannerId: string) {
    const sid = new Types.ObjectId(scannerId);

    const [scanLogs, authLogs] = await Promise.all([
      this.scanLogModel.find({
        $or: [
          { scannerId: sid },
          { scannerId: scannerId }
        ]
      })
        .populate({
          path: 'ticketId',
          select: 'category type userId',
          populate: {
            path: 'userId',
            select: 'name phoneNumber'
          }
        })
        .populate('eventId', 'name')
        .populate('zoneId', 'name')
        .sort({ createdAt: -1 })
        .limit(500)
        .lean(),

      this.authLogModel.find({
        $or: [
          { userId: sid },
          { userId: scannerId }
        ]
      })
        .sort({ createdAt: -1 })
        .limit(50)
        .lean(),
    ]);

    const counts = scanLogs.reduce((acc: any, log: any) => {
      acc[log.status] = (acc[log.status] || 0) + 1;
      return acc;
    }, {});

    return {
      summary: {
        total: scanLogs.length,
        success: counts['success'] || 0,
        duplicate: counts['duplicate'] || 0,
        fraud: counts['fraud'] || 0,
        invalid_sig: counts['invalid_sig'] || 0,
        unverified: counts['unverified'] || 0,
        time_invalid: counts['time_invalid'] || 0,
        expired: counts['expired'] || 0,
      },
      scanLogs,
      authLogs,
    };
  }

  // ── Full Logs (unified, separate by type) ─────────────────────────────────
  async getLogs(filters: {
    type?: string; // 'scan' | 'transfer' | 'admin' | 'auth'
    userId?: string;
    role?: string;
    dateFrom?: string;
    dateTo?: string;
    page?: number;
  }) {
    const limit = 200;
    const type = filters.type || 'scan';
    const dateFilter: any = {};
    if (filters.dateFrom) dateFilter.$gte = new Date(filters.dateFrom);
    if (filters.dateTo) dateFilter.$lte = new Date(filters.dateTo + 'T23:59:59Z');

    if (type === 'scan') {
      const q: any = {};
      if (filters.userId) {
        q.$or = [
          { scannerId: new Types.ObjectId(filters.userId) },
          { scannerId: filters.userId }
        ];
      }
      if (Object.keys(dateFilter).length) q.createdAt = dateFilter;
      return this.scanLogModel.find(q)
        .populate('scannerId', 'name phoneNumber role')
        .populate({
          path: 'ticketId',
          select: 'category type userId',
          populate: {
            path: 'userId',
            select: 'name phoneNumber'
          }
        })
        .populate('eventId', 'name')
        .populate('zoneId', 'name')
        .sort({ createdAt: -1 }).limit(limit).lean();
    }

    if (type === 'transfer') {
      const q: any = {};
      if (filters.userId) {
        const uid = new Types.ObjectId(filters.userId);
        q.$or = [
          { fromUserId: uid },
          { fromUserId: filters.userId },
          { toUserId: uid },
          { toUserId: filters.userId }
        ];
      }
      if (Object.keys(dateFilter).length) q.createdAt = dateFilter;
      return this.transferLogModel.find(q)
        .populate('fromUserId', 'name phoneNumber')
        .populate('toUserId', 'name phoneNumber')
        .populate('ticketId', 'category type')
        .sort({ createdAt: -1 }).limit(limit).lean();
    }

    if (type === 'admin') {
      const q: any = {};
      if (filters.userId) {
        q.$or = [
          { adminId: new Types.ObjectId(filters.userId) },
          { adminId: filters.userId }
        ];
      }
      if (Object.keys(dateFilter).length) q.createdAt = dateFilter;
      return this.adminLogModel.find(q)
        .populate('adminId', 'name phoneNumber role')
        .sort({ createdAt: -1 }).limit(limit).lean();
    }

    if (type === 'auth') {
      const q: any = {};
      if (filters.userId) {
        q.$or = [
          { userId: new Types.ObjectId(filters.userId) },
          { userId: filters.userId }
        ];
      }
      if (filters.role) q.role = filters.role;
      if (Object.keys(dateFilter).length) q.createdAt = dateFilter;
      return this.authLogModel.find(q)
        .populate('userId', 'name phoneNumber role')
        .sort({ createdAt: -1 }).limit(limit).lean();
    }

    return [];
  }

  // ── Verifications ─────────────────────────────────────────────────────────
  async getPendingVerifications() {
    return this.userModel.find({ verificationStatus: 'pending' }).sort({ updatedAt: 1 }).select('-__v').lean();
  }

  async updateVerificationStatus(id: string, status: string, reason: string = '', adminId: string) {
    const user = await this.userModel.findById(id).lean();
    const update: any = {
      verificationStatus: status,
      verificationReason: reason
    };
    if (status === 'approved') update.isVerified = true;
    else if (status === 'rejected') update.isVerified = false;

    const updated = await this.userModel.findByIdAndUpdate(id, { $set: update }, { new: true });

    this.writeAdminLog({
      adminId,
      action: 'update_verification',
      targetId: id,
      targetType: 'user',
      targetName: (user as any)?.phoneNumber || id,
      changes: { before: { verificationStatus: (user as any)?.verificationStatus }, after: { verificationStatus: status, reason } },
    });

    return updated;
  }

  async verifyTicket(ticketId: string, adminId: string) {
    const ticket = await this.ticketModel.findById(ticketId).lean();
    const updated = await this.ticketModel.findByIdAndUpdate(
      ticketId,
      { $set: { isVerified: true, verificationStatus: 'approved' } },
      { new: true }
    );

    this.writeAdminLog({
      adminId,
      action: 'verify_ticket',
      targetId: ticketId,
      targetType: 'ticket',
      targetName: `Ticket #${ticketId.slice(-6)}`,
      changes: { before: { verificationStatus: (ticket as any)?.verificationStatus }, after: { verificationStatus: 'approved' } },
    });

    return updated;
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  async getSettings() {
    return this.settingsModel.findOne({ key: 'global' }).lean();
  }

  async updateSettings(body: any, adminId: string) {
    const before = await this.settingsModel.findOne({ key: 'global' }).lean();
    const updated = await this.settingsModel.findOneAndUpdate(
      { key: 'global' },
      { $set: body },
      { upsert: true, new: true }
    );

    this.writeAdminLog({
      adminId,
      action: 'update_settings',
      targetType: 'settings',
      targetName: 'Global Settings',
      changes: { before, after: body },
    });

    return updated;
  }
}
