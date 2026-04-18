import { Controller, Get, Post, Put, Delete, Body, Param, UseInterceptors, UploadedFile } from '@nestjs/common';
import { EventsService } from './events.service';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';

@Controller('events')
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  @Post('upload')
  @UseInterceptors(FileInterceptor('image', {
    storage: diskStorage({
      destination: './uploads',
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, `${uniqueSuffix}${extname(file.originalname)}`);
      },
    }),
  }))
  uploadFile(@UploadedFile() file: Express.Multer.File) {
    return { url: `/uploads/${file.filename}` };
  }

  // ── Events ──────────────────────────────────────────────────────────────
  @Post()
  create(@Body() dto: any) {
    return this.eventsService.createEvent(dto, dto.adminId);
  }

  @Get()
  findAll() {
    return this.eventsService.getAllEvents();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.eventsService.getEventById(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: any) {
    return this.eventsService.updateEvent(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.eventsService.deleteEvent(id);
  }

  // ── Zones ────────────────────────────────────────────────────────────────
  @Post('zones')
  createZone(@Body() dto: any) {
    return this.eventsService.createZone(dto, dto.adminId);
  }

  @Get(':id/zones')
  getZones(@Param('id') id: string) {
    return this.eventsService.getZonesByEvent(id);
  }

  @Put('zones/:id')
  updateZone(@Param('id') id: string, @Body() dto: any) {
    return this.eventsService.updateZone(id, dto);
  }
}
