import { Controller, Get, Param } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Zone } from '../../schemas/zone.schema';

@Controller('zones')
export class ZonesController {
  constructor(@InjectModel(Zone.name) private zoneModel: Model<any>) {}

  @Get()
  async findAll() {
    const zones = await this.zoneModel.find().populate('eventId', 'name').sort({ createdAt: -1 }).lean();
    return zones.map((z: any) => {
      // Normalize pricing for Admin Panel display
      const dPrice = z.dailyPrice || (z.type === 'daily' || z.type === 'both' ? z.price : 0) || 0;
      const sPrice = z.seasonPrice || (z.type === 'season' || z.type === 'both' ? z.price : 0) || 0;
      return {
        ...z,
        dailyPrice: dPrice,
        seasonPrice: sPrice,
        availableSeats: z.availableSeats ?? z.available ?? 0,
        isMultipleAllowed: z.isMultipleAllowed !== false
      };
    });
  }
}
