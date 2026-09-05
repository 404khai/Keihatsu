import { Module } from '@nestjs/common';
import { DownloadsController } from './downloads.controller';
import { DownloadsService } from './downloads.service';
import { SourcesModule } from '../sources/sources.module';

@Module({
  imports: [SourcesModule],
  controllers: [DownloadsController],
  providers: [DownloadsService],
})
export class DownloadsModule {}
