import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Event, EventDocument } from '../../schemas/event.schema';
import { Zone, ZoneDocument } from '../../schemas/zone.schema';

@Injectable()
export class EventsService {
  constructor(
    @InjectModel(Event.name) private eventModel: Model<EventDocument>,
    @InjectModel(Zone.name) private zoneModel: Model<ZoneDocument>,
  ) {}

  // ── Helper ───────────────────────────────────────────────────────────
  private normalizeZone(z: any) {
    const dPrice = z.dailyPrice || (z.type === 'daily' || z.type === 'both' ? z.price : 0) || 0;
    const sPrice = z.seasonPrice || (z.type === 'season' || z.type === 'both' ? z.price : 0) || 0;
    return {
      ...z,
      id: z._id.toString(),
      _id: z._id.toString(),
      dailyPrice: dPrice,
      seasonPrice: sPrice,
      availableSeats: z.availableSeats ?? z.available ?? 0
    };
  }

  // ── Events ──────────────────────────────────────────────────────────────
  async createEvent(dto: any, adminId: string) {
    const event = await this.eventModel.create({ ...dto, createdBy: adminId });
    return event;
  }

  async getAllEvents() {
    console.log('📅 Fetching all events...');
    const events = await this.eventModel.find({ status: { $in: ['published', 'active'] } }).sort({ createdAt: -1 }).lean();
    
    return Promise.all(events.map(async (event) => {
      // Robust query: Search by both ObjectId and String to handle DB inconsistencies
      const zones = await this.zoneModel.find({ 
        $or: [
          { eventId: new Types.ObjectId(String(event._id)) },
          { eventId: String(event._id) }
        ]
      }).lean();
      
      console.log(`📍 Event ${event.name}: Populated ${zones.length} zones`);
      
      return {
        ...event,
        id: event._id.toString(),
        zones: zones.map(z => this.normalizeZone(z))
      };
    }));
  }

  async getEventById(id: string) {
    console.log(`📅 Fetching details for event: ${id}`);
    const event = await this.eventModel.findById(id).lean();
    if (!event) throw new NotFoundException('Event not found');
    
    // Also fetch zones for detail view
    const zones = await this.zoneModel.find({ 
      $or: [
        { eventId: new Types.ObjectId(String(event._id)) },
        { eventId: String(event._id) }
      ]
    }).lean();

    console.log(`📍 Event ${event.name}: Populated ${zones.length} zones`);

    return {
      ...event,
      id: event._id.toString(),
      zones: zones.map(z => this.normalizeZone(z))
    };
  }

  async updateEvent(id: string, dto: any) {
    return this.eventModel.findByIdAndUpdate(id, dto, { new: true });
  }

  async deleteEvent(id: string) {
    // Soft delete
    return this.eventModel.findByIdAndUpdate(id, { status: 'cancelled' }, { new: true });
  }

  // ── Zones ────────────────────────────────────────────────────────────────
  async createZone(dto: any, adminId?: string) {
    const eventCandidateId = dto.eventId;
    const event = await this.eventModel.findById(eventCandidateId);
    if (!event) throw new NotFoundException('Event not found');
    
    // Explicitly cast eventId to ObjectId to ensure clean data
    const zoneData = {
      ...dto,
      eventId: new Types.ObjectId(String(eventCandidateId)),
      availableSeats: dto.availableSeats ?? dto.capacity ?? 0,
      createdBy: adminId || 'platform_admin'
    };
    
    return this.zoneModel.create(zoneData);
  }

  async getZonesByEvent(eventId: string) {
    const zones = await this.zoneModel.find({ 
      $or: [
        { eventId: new Types.ObjectId(String(eventId)) },
        { eventId: String(eventId) }
      ]
    }).populate('ownerId', 'name phoneNumber').lean();
    
    return zones.map(z => this.normalizeZone(z));
  }

  async updateZone(id: string, dto: any) {
    let updateData = { ...dto };
    if (dto.eventId) {
      updateData.eventId = new Types.ObjectId(String(dto.eventId));
    }
    return this.zoneModel.findByIdAndUpdate(id, updateData, { new: true });
  }

  async incrementZoneCount(zoneId: string) {
    return this.zoneModel.findByIdAndUpdate(
      zoneId,
      { $inc: { currentCount: 1, availableSeats: -1 } },
      { new: true }
    );
  }
}
