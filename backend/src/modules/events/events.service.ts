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
    @InjectModel('AdminLog') private adminLogModel: Model<any>,
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
      availableSeats: z.availableSeats ?? z.available ?? 0,
      isMultipleAllowed: z.isMultipleAllowed !== false
    };
  }

  private writeAdminLog(data: {
    adminId: string;
    action: string;
    targetId?: string;
    targetType?: string;
    targetName?: string;
    changes?: any;
    metadata?: any;
  }) {
    if (!data.adminId) return;
    this.adminLogModel.create({
      ...data,
      adminId: new Types.ObjectId(data.adminId),
      targetId: data.targetId ? new Types.ObjectId(data.targetId) : undefined,
    }).catch(() => {});
  }

  // ── Events ──────────────────────────────────────────────────────────────
  async createEvent(dto: any, adminId: string) {
    const event = await this.eventModel.create({ ...dto, createdBy: adminId });

    this.writeAdminLog({
      adminId,
      action: 'create_event',
      targetId: String(event._id),
      targetType: 'event',
      targetName: dto.name,
      metadata: { eventDates: dto.eventDates, venue: dto.venue },
    });

    return event;
  }

  async getAllEvents() {
    console.log('📅 Fetching all events...');
    const events = await this.eventModel.find({ status: { $in: ['published', 'active'] } }).sort({ createdAt: -1 }).lean();

    return Promise.all(events.map(async (event) => {
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

  async getAllEventsForAdmin() {
    console.log('📅 Fetching all events for admin...');
    const events = await this.eventModel.find({}).sort({ createdAt: -1 }).lean();

    return Promise.all(events.map(async (event) => {
      const zones = await this.zoneModel.find({
        $or: [
          { eventId: new Types.ObjectId(String(event._id)) },
          { eventId: String(event._id) }
        ]
      }).lean();

      console.log(`📍 Event ${event.name}: Populated ${zones.length} zones for admin`);

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

  async updateEvent(id: string, dto: any, adminId?: string) {
    const before = await this.eventModel.findById(id).lean();
    const updated = await this.eventModel.findByIdAndUpdate(id, dto, { new: true });

    if (adminId) {
      this.writeAdminLog({
        adminId,
        action: 'update_event',
        targetId: id,
        targetType: 'event',
        targetName: (before as any)?.name || id,
        changes: {
          before: { name: (before as any)?.name, status: (before as any)?.status, venue: (before as any)?.venue },
          after: { name: dto.name, status: dto.status, venue: dto.venue },
        },
      });
    }

    return updated;
  }

  async deleteEvent(id: string, adminId?: string) {
    const event = await this.eventModel.findById(id).lean();
    // Soft delete
    const deleted = await this.eventModel.findByIdAndUpdate(id, { status: 'cancelled' }, { new: true });

    if (adminId) {
      this.writeAdminLog({
        adminId,
        action: 'delete_event',
        targetId: id,
        targetType: 'event',
        targetName: (event as any)?.name || id,
        changes: { before: { status: (event as any)?.status }, after: { status: 'cancelled' } },
      });
    }

    return deleted;
  }

  // ── Zones ────────────────────────────────────────────────────────────────
  async createZone(dto: any, adminId?: string) {
    const eventCandidateId = dto.eventId;
    const event = await this.eventModel.findById(eventCandidateId);
    if (!event) throw new NotFoundException('Event not found');

    const zoneData = {
      ...dto,
      eventId: new Types.ObjectId(String(eventCandidateId)),
      availableSeats: dto.availableSeats ?? dto.capacity ?? 0,
      createdBy: adminId || 'platform_admin'
    };

    const zone = await this.zoneModel.create(zoneData);

    if (adminId) {
      this.writeAdminLog({
        adminId,
        action: 'create_zone',
        targetId: String(zone._id),
        targetType: 'zone',
        targetName: dto.name,
        metadata: { eventId: eventCandidateId, eventName: event.name, capacity: dto.capacity },
      });
    }

    return zone;
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

  async updateZone(id: string, dto: any, adminId?: string) {
    const before = await this.zoneModel.findById(id).lean();
    let updateData = { ...dto };
    if (dto.eventId) {
      updateData.eventId = new Types.ObjectId(String(dto.eventId));
    }
    const updated = await this.zoneModel.findByIdAndUpdate(id, updateData, { new: true });

    if (adminId) {
      this.writeAdminLog({
        adminId,
        action: 'update_zone',
        targetId: id,
        targetType: 'zone',
        targetName: (before as any)?.name || id,
        changes: {
          before: { name: (before as any)?.name, capacity: (before as any)?.capacity, dailyPrice: (before as any)?.dailyPrice },
          after: { name: dto.name, capacity: dto.capacity, dailyPrice: dto.dailyPrice },
        },
      });
    }

    return updated;
  }

  async incrementZoneCount(zoneId: string) {
    return this.zoneModel.findByIdAndUpdate(
      zoneId,
      { $inc: { currentCount: 1, availableSeats: -1 } },
      { new: true }
    );
  }
}
