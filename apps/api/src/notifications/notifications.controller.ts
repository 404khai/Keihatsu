import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiProperty,
  ApiPropertyOptional,
  ApiQuery,
} from '@nestjs/swagger';
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { PushPlatform, NotificationType } from '@prisma/client';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NotificationsService } from './notifications.service';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';

class RegisterDeviceDto {
  @ApiProperty({
    description: 'Stable identifier for this app installation.',
    maxLength: 200,
  })
  @IsString()
  @MaxLength(200)
  installationId: string;
  @ApiProperty({ enum: PushPlatform })
  @IsEnum(PushPlatform)
  platform: PushPlatform;
  @ApiProperty({
    description: 'APNs device token or FCM registration token.',
    maxLength: 4096,
    writeOnly: true,
  })
  @IsString()
  @MaxLength(4096)
  token: string;
  @ApiProperty({ example: '1.0.0', maxLength: 80 })
  @IsString()
  @MaxLength(80)
  appVersion: string;
}

class PreferenceDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  libraryUpdates?: boolean;
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  commentReplies?: boolean;
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  commentMentions?: boolean;
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  commentLikes?: boolean;
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  moderation?: boolean;
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  sourceStatus?: boolean;
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  productAnnouncements?: boolean;
}

@ApiTags('Notifications')
@Controller('notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private notifications: NotificationsService) {}
  @Post('devices')
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { ttl: 60000, limit: 10 } })
  @ApiOperation({ summary: 'Register or refresh a push installation' })
  register(@Req() req: any, @Body() body: RegisterDeviceDto) {
    return this.notifications.registerDevice(
      req.user.id,
      body.installationId,
      body.platform,
      body.token,
      body.appVersion,
    );
  }
  @Delete('devices/:installationId')
  @ApiOperation({ summary: 'Unregister a push installation' })
  unregister(@Req() req: any, @Param('installationId') id: string) {
    return this.notifications.unregisterDevice(req.user.id, id);
  }
  @Get('unread-count')
  @ApiOperation({ summary: 'Get the unread Inbox count' })
  unread(@Req() req: any) {
    return this.notifications.unreadCount(req.user.id);
  }
  @Get('preferences')
  @ApiOperation({ summary: 'Get notification push preferences' })
  preferences(@Req() req: any) {
    return this.notifications.preferences(req.user.id);
  }
  @Patch('preferences')
  @ApiOperation({ summary: 'Update notification push preferences' })
  updatePreferences(@Req() req: any, @Body() body: PreferenceDto) {
    return this.notifications.updatePreferences(req.user.id, { ...body });
  }
  @Post('read-all')
  @ApiOperation({ summary: 'Mark all Inbox notifications as read' })
  readAll(@Req() req: any) {
    return this.notifications.readAll(req.user.id);
  }
  @Get()
  @ApiOperation({ summary: 'List Inbox notifications' })
  @ApiQuery({
    name: 'cursor',
    required: false,
    description: 'Notification ID returned as nextCursor by the previous page.',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    schema: { type: 'integer', minimum: 1, maximum: 100, default: 30 },
  })
  @ApiQuery({ name: 'type', required: false, enum: NotificationType })
  @ApiQuery({
    name: 'category',
    required: false,
    enum: ['UPDATES', 'COMMENTS', 'SYSTEM', 'ACCOUNT'],
    description: 'Ignored when a specific type is supplied.',
  })
  @ApiQuery({ name: 'unread', required: false, enum: ['true', 'false'] })
  list(
    @Req() req: any,
    @Query()
    query: {
      cursor?: string;
      limit?: string;
      type?: string;
      category?: string;
      unread?: string;
    },
  ) {
    return this.notifications.list(req.user.id, query);
  }
  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark an Inbox notification as read' })
  read(@Req() req: any, @Param('id') id: string) {
    return this.notifications.markRead(req.user.id, id);
  }
  @Delete(':id')
  @ApiOperation({ summary: 'Delete an Inbox notification' })
  remove(@Req() req: any, @Param('id') id: string) {
    return this.notifications.remove(req.user.id, id);
  }
}
