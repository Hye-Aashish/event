import { Controller, Get, Post, Put, Delete, Body, Param, UseInterceptors, UploadedFile, BadRequestException, UseGuards, Request } from '@nestjs/common';
import { EventsService } from './events.service';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import * as fs from 'fs';
import * as path from 'path';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('events')
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin', 'user', 'scanner', 'zone_manager')
  @Post('upload')
  @UseInterceptors(FileInterceptor('image', {
    storage: diskStorage({
      destination: './uploads',
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, `${uniqueSuffix}${extname(file.originalname)}`);
      },
    }),
    fileFilter: (req, file, cb) => {
      if (!file.mimetype.match(/\/(jpg|jpeg|png|webp)$/)) {
        return cb(new BadRequestException('Only image files are allowed!'), false);
      }
      cb(null, true);
    }
  }))
  uploadFile(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('File upload failed or file missing');
    }
    return { url: `/uploads/${file.filename}` };
  }

  @Get('debug-uploads')
  debugUploads() {
    try {
      const cwd = process.cwd();
      const uploadPath = path.join(cwd, 'uploads');
      const exists = fs.existsSync(uploadPath);
      let files = [];
      if (exists) {
        files = fs.readdirSync(uploadPath);
      }
      return {
        cwd,
        __dirname,
        uploadPath,
        exists,
        files
      };
    } catch (e: any) {
      return {
        error: e.message,
        stack: e.stack
      };
    }
  }

  // ── Events ──────────────────────────────────────────────────────────────
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @Post()
  create(@Body() dto: any, @Request() req) {
    return this.eventsService.createEvent(dto, req.user.sub);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @Get('all-admin')
  findAllAdmin() {
    return this.eventsService.getAllEventsForAdmin();
  }

  @Get()
  findAll() {
    return this.eventsService.getAllEvents();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.eventsService.getEventById(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: any, @Request() req) {
    return this.eventsService.updateEvent(id, dto, req.user.sub);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @Delete(':id')
  remove(@Param('id') id: string, @Request() req) {
    return this.eventsService.deleteEvent(id, req.user.sub);
  }

  // ── Zones ────────────────────────────────────────────────────────────────
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @Post('zones')
  createZone(@Body() dto: any, @Request() req) {
    return this.eventsService.createZone(dto, req.user.sub);
  }

  @Get(':id/zones')
  getZones(@Param('id') id: string) {
    return this.eventsService.getZonesByEvent(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @Put('zones/:id')
  updateZone(@Param('id') id: string, @Body() dto: any, @Request() req) {
    return this.eventsService.updateZone(id, dto, req.user.sub);
  }
}
