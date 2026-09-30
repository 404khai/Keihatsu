import { Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { ApnsPushProvider, FcmPushProvider, NoopPushProvider, PushService } from './push.service';
import { SourcesModule } from '../sources/sources.module';
import { ChapterUpdateService } from './chapter-update.service';
import { AnnouncementService } from './announcement.service';
import { AnnouncementsController } from './announcements.controller';

@Module({
  imports: [SourcesModule],
  controllers: [NotificationsController, AnnouncementsController],
  providers: [NotificationsService, PushService, ApnsPushProvider, FcmPushProvider, NoopPushProvider, ChapterUpdateService, AnnouncementService],
  exports: [NotificationsService, ChapterUpdateService],
})
export class NotificationsModule {}
