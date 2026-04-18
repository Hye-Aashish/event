import { Controller, Get, Param } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Zone } from '../../schemas/zone.schema';

@Controller('zones')
export class ZonesController {
  constructor(@InjectModel(Zone.name) private zoneModel: Model<any>) {}

  @Get()
  findAll() {
    return this.zoneModel.find().populate('eventId', 'name').sort({ createdAt: -1 }).lean();
  }
}
