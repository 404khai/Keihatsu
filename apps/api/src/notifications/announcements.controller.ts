import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { AnnouncementService } from './announcement.service';
import type { AnnouncementInput } from './announcement.service';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';

@Controller('admin/announcements')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AnnouncementsController {
  constructor(private announcements: AnnouncementService) {}
  @Post()
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { ttl: 60000, limit: 3 } })
  create(@Body() body: AnnouncementInput) { return this.announcements.create(body); }
}
