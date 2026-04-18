import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from '../../schemas/user.schema';
import { Ticket } from '../../schemas/ticket.schema';

@Injectable()
export class AdminService {
  constructor(
    @InjectModel(User.name) private userModel: Model<any>,
    @InjectModel(Ticket.name) private ticketModel: Model<any>,
    @InjectModel('ScanLog') private scanLogModel: Model<any>,
    @InjectModel('Event') private eventModel: Model<any>,
  ) {}

  async getStats() {
    const totalUsers = await this.userModel.countDocuments();
    const totalTickets = await this.ticketModel.countDocuments();
    const totalEvents = await this.eventModel.countDocuments();
    const totalScans = await this.scanLogModel.countDocuments({ status: 'success' });

    // Calculate chart data (last 7 days sales)
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

  async getAllUsers() {
    return this.userModel.find().sort({ createdAt: -1 }).select('-__v').lean();
  }

  async updateUserRole(id: string, role: string) {
    return this.userModel.findByIdAndUpdate(id, { role }, { new: true });
  }
}
