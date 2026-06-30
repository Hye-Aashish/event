import * as dns from 'dns';
dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);

import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { ServeStaticModule } from '@nestjs/serve-static';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { join } from 'path';

// Schemas
import { User, UserSchema } from './schemas/user.schema';
import { Event, EventSchema } from './schemas/event.schema';
import { Zone, ZoneSchema } from './schemas/zone.schema';
import { Ticket, TicketSchema } from './schemas/ticket.schema';
import { Sponsor, SponsorSchema } from './schemas/sponsor.schema';
import { Settings, SettingsSchema } from './schemas/settings.schema';
import { ScanLog, ScanLogSchema, TransferLog, TransferLogSchema, AdminLog, AdminLogSchema, AuthLog, AuthLogSchema } from './schemas/log.schema';

// Auth
import { AuthService } from './modules/auth/auth.service';
import { AuthController } from './modules/auth/auth.controller';

// Events & Zones
import { EventsService } from './modules/events/events.service';
import { EventsController } from './modules/events/events.controller';

// Tickets
import { TicketsService } from './modules/tickets/tickets.service';
import { TicketsController } from './modules/tickets/tickets.controller';

// Scanner
import { ScannerService } from './modules/scanner/scanner.service';
import { ScanGatewayController } from './modules/scanner/gateway.controller';

// Sponsors
import { SponsorService } from './modules/sponsor/sponsor.service';
import { SponsorController } from './modules/sponsor/sponsor.controller';

// Admin
import { AdminService } from './modules/admin/admin.service';
import { AdminController } from './modules/admin/admin.controller';

// Zones standalone route
import { ZonesController } from './modules/zones/zones.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),

    // Serve User App at http://localhost:3000/app
    ServeStaticModule.forRoot(
      {
        rootPath: join(__dirname, '..', '..', 'app'),
        serveRoot: '/app',
        exclude: ['/api/(.*)'],
      },
      // Serve Admin Panel at http://localhost:3000/admin
      {
        rootPath: join(__dirname, '..', '..', 'admin-panel'),
        serveRoot: '/admin',
        exclude: ['/api/(.*)'],
      },
    ),

    MongooseModule.forRoot(
      process.env.MONGODB_URI,
      { serverSelectionTimeoutMS: 10000, socketTimeoutMS: 45000 }
    ),
    MongooseModule.forFeature([
      { name: User.name,        schema: UserSchema },
      { name: Event.name,       schema: EventSchema },
      { name: Zone.name,        schema: ZoneSchema },
      { name: Ticket.name,      schema: TicketSchema },
      { name: Sponsor.name,     schema: SponsorSchema },
      { name: Settings.name,    schema: SettingsSchema },
      { name: ScanLog.name,     schema: ScanLogSchema },
      { name: TransferLog.name, schema: TransferLogSchema },
      { name: AdminLog.name,    schema: AdminLogSchema },
      { name: AuthLog.name,     schema: AuthLogSchema },
    ]),
    JwtModule.register({
      secret: process.env.JWT_SECRET,
      signOptions: { expiresIn: '1d' },
    }),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 10 }]),
  ],
  controllers: [
    AuthController,
    EventsController,
    TicketsController,
    ScanGatewayController,
    SponsorController,
    AdminController,
    ZonesController,
  ],
  providers: [
    AuthService,
    EventsService,
    TicketsService,
    ScannerService,
    SponsorService,
    AdminService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
