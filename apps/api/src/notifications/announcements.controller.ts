import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiForbiddenResponse,
  ApiBody,
} from '@nestjs/swagger';
import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { AnnouncementService } from './announcement.service';
import type { AnnouncementInput } from './announcement.service';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';

@ApiTags('Admin announcements')
@Controller('admin/announcements')
@ApiBearerAuth()
@ApiForbiddenResponse({ description: 'Requires an ADMIN account.' })
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AnnouncementsController {
  constructor(private announcements: AnnouncementService) {}
  @Post()
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { ttl: 60000, limit: 3 } })
  @ApiOperation({
    summary: 'Create and schedule a system announcement (ADMIN only)',
  })
  @ApiBody({
    schema: {
      type: 'object',
      required: ['title', 'body', 'severity', 'pushEnabled', 'publishAt'],
      properties: {
        title: { type: 'string', maxLength: 160, example: 'Service notice' },
        body: {
          type: 'string',
          maxLength: 500,
          example: 'Open your Inbox for details.',
        },
        platform: {
          type: 'string',
          enum: ['IOS', 'ANDROID'],
          description: 'Omit to target all platforms.',
        },
        minAppVersion: { type: 'string', example: '1.0.0' },
        maxAppVersion: { type: 'string', example: '2.0.0' },
        deepLink: { type: 'string', example: 'keihatsu://inbox' },
        severity: { type: 'string', enum: ['INFO', 'IMPORTANT', 'CRITICAL'] },
        pushEnabled: { type: 'boolean', example: false },
        publishAt: {
          type: 'string',
          format: 'date-time',
          description: 'Publish immediately when this time is in the past.',
        },
        expiresAt: { type: 'string', format: 'date-time' },
      },
    },
  })
  create(@Body() body: AnnouncementInput) {
    return this.announcements.create(body);
  }
}
