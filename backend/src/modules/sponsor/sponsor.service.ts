import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Sponsor, SponsorDocument } from '../../schemas/sponsor.schema';
import { Event, EventDocument } from '../../schemas/event.schema';

@Injectable()
export class SponsorService {
  constructor(
    @InjectModel(Sponsor.name) private sponsorModel: Model<SponsorDocument>,
    @InjectModel(Event.name) private eventModel: Model<EventDocument>,
  ) {}

  async createSponsor(dto: any, adminId: string) {
    return this.sponsorModel.create({ ...dto, createdBy: adminId });
  }

  async getAllSponsors() {
    return this.sponsorModel.find().populate('eventId', 'name').sort({ createdAt: -1 }).lean();
  }

  async getSponsorsByEvent(eventId: string) {
    return this.sponsorModel.find({ eventId }).sort({ createdAt: -1 });
  }

  async getSponsorById(id: string) {
    const s = await this.sponsorModel.findById(id);
    if (!s) throw new NotFoundException('Sponsor not found');
    return s;
  }

  async updateSponsor(id: string, dto: any) {
    return this.sponsorModel.findByIdAndUpdate(id, dto, { new: true });
  }

  async checkAndDeductQuota(sponsorId: string, amount: number, price: number) {
    const sponsor = await this.getSponsorById(sponsorId);
    if (sponsor.status !== 'active') throw new BadRequestException('Sponsor account not active');

    if (sponsor.limitType === 'quantity' || sponsor.limitType === 'combined') {
      if (sponsor.ticketsUsed + amount > sponsor.ticketQuota) {
        throw new BadRequestException('Sponsor ticket quota exceeded');
      }
    }
    if (sponsor.limitType === 'credit' || sponsor.limitType === 'combined') {
      if (sponsor.creditUsed + (price * amount) > sponsor.creditLimit) {
        throw new BadRequestException('Sponsor credit limit exceeded');
      }
    }

    await this.sponsorModel.updateOne(
      { _id: sponsorId },
      { $inc: { ticketsUsed: amount, creditUsed: price * amount } }
    );
    return true;
  }
}
