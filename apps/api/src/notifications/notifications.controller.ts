import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { IsBoolean, IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { PushPlatform } from '@prisma/client';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NotificationsService } from './notifications.service';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';

class RegisterDeviceDto {
  @IsString() @MaxLength(200) installationId: string;
  @IsEnum(PushPlatform) platform: PushPlatform;
  @IsString() @MaxLength(4096) token: string;
  @IsString() @MaxLength(80) appVersion: string;
}

class PreferenceDto {
  @IsOptional() @IsBoolean() libraryUpdates?: boolean;
  @IsOptional() @IsBoolean() commentReplies?: boolean;
  @IsOptional() @IsBoolean() commentMentions?: boolean;
  @IsOptional() @IsBoolean() commentLikes?: boolean;
  @IsOptional() @IsBoolean() moderation?: boolean;
  @IsOptional() @IsBoolean() sourceStatus?: boolean;
  @IsOptional() @IsBoolean() productAnnouncements?: boolean;
}

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private notifications: NotificationsService) {}
  @Post('devices')
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { ttl: 60000, limit: 10 } })
  register(@Req() req: any, @Body() body: RegisterDeviceDto) {
    return this.notifications.registerDevice(req.user.id, body.installationId, body.platform, body.token, body.appVersion);
  }
  @Delete('devices/:installationId')
  unregister(@Req() req: any, @Param('installationId') id: string) {
    return this.notifications.unregisterDevice(req.user.id, id);
  }
  @Get('unread-count')
  unread(@Req() req: any) { return this.notifications.unreadCount(req.user.id); }
  @Get('preferences')
  preferences(@Req() req: any) { return this.notifications.preferences(req.user.id); }
  @Patch('preferences')
  updatePreferences(@Req() req: any, @Body() body: PreferenceDto) {
    return this.notifications.updatePreferences(req.user.id, { ...body });
  }
  @Post('read-all')
  readAll(@Req() req: any) { return this.notifications.readAll(req.user.id); }
  @Get()
  list(@Req() req: any, @Query() query: { cursor?: string; limit?: string; type?: string; category?: string; unread?: string }) {
    return this.notifications.list(req.user.id, query);
  }
  @Patch(':id/read')
  read(@Req() req: any, @Param('id') id: string) { return this.notifications.markRead(req.user.id, id); }
  @Delete(':id')
  remove(@Req() req: any, @Param('id') id: string) { return this.notifications.remove(req.user.id, id); }
}
