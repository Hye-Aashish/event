import { Controller, Post, Get, Put, Body, Param } from '@nestjs/common';
import { SponsorService } from './sponsor.service';

@Controller('sponsors')
export class SponsorController {
  constructor(private readonly sponsorService: SponsorService) {}

  @Post()
  create(@Body() body: any) {
    return this.sponsorService.createSponsor(body, body.adminId);
  }

  @Get('all')
  getAll() {
    return this.sponsorService.getAllSponsors();
  }

  @Get('event/:eventId')
  getByEvent(@Param('eventId') eventId: string) {
    return this.sponsorService.getSponsorsByEvent(eventId);
  }

  @Get(':id')
  getOne(@Param('id') id: string) {
    return this.sponsorService.getSponsorById(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() body: any) {
    return this.sponsorService.updateSponsor(id, body);
  }
}
