import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Event, EventDocument } from '../../schemas/event.schema';
import { Zone, ZoneDocument } from '../../schemas/zone.schema';

@Injectable()
export class EventsService {
  constructor(
    @InjectModel(Event.name) private eventModel: Model<EventDocument>,
    @InjectModel(Zone.name) private zoneModel: Model<ZoneDocument>,
  ) {}

  // ── Events ──────────────────────────────────────────────────────────────
  async createEvent(dto: any, adminId: string) {
    const event = await this.eventModel.create({ ...dto, createdBy: adminId });
    return event;
  }

  async getAllEvents() {
    // published events fetch karein
    const events = await this.eventModel.find({ status: { $in: ['published', 'active'] } }).sort({ createdAt: -1 }).lean();
    
    // Har event ke liye zones ko dhundo
    const results = await Promise.all(events.map(async (event) => {
      const zones = await this.zoneModel.find({ eventId: event._id }).lean();
      
      return {
        ...event,
        id: event._id.toString(),
        // Map lean zones to match what frontend expects
        zones: zones.map((z: any) => ({
          ...z,
          id: z._id.toString(),
          _id: z._id.toString(),
          availableSeats: z.availableSeats ?? z.available ?? 0 // fallback
        }))
      };
    }));

    return results;
  }

  async getEventById(id: string) {
    const event = await this.eventModel.findById(id);
    if (!event) throw new NotFoundException('Event not found');
    return event;
  }

  async updateEvent(id: string, dto: any) {
    return this.eventModel.findByIdAndUpdate(id, dto, { new: true });
  }

  async deleteEvent(id: string) {
    return this.eventModel.findByIdAndUpdate(id, { status: 'cancelled' }, { new: true });
  }

  // ── Zones ────────────────────────────────────────────────────────────────
  async createZone(dto: any, adminId?: string) {
    const event = await this.eventModel.findById(dto.eventId);
    if (!event) throw new NotFoundException('Event not found');
    
    // Ensure availableSeats starts at capacity if not specified
    const zoneData = {
      ...dto,
      availableSeats: dto.availableSeats ?? dto.capacity ?? 0,
      createdBy: adminId || 'platform_admin'
    };
    
    return this.zoneModel.create(zoneData);
  }

  async getZonesByEvent(eventId: string) {
    return this.zoneModel.find({ eventId }).populate('ownerId', 'name phoneNumber');
  }

  async updateZone(id: string, dto: any) {
    return this.zoneModel.findByIdAndUpdate(id, dto, { new: true });
  }

  async incrementZoneCount(zoneId: string) {
    return this.zoneModel.findByIdAndUpdate(
      zoneId,
      { $inc: { currentCount: 1 } },
      { new: true }
    );
  }
}
