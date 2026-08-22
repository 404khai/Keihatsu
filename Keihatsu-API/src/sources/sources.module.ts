import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { SourcesController } from './sources.controller';
import { SourcesService } from './sources.service';
import { PuppeteerService } from './core/puppeteer.service';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [HttpModule, UsersModule],
  controllers: [SourcesController],
  providers: [SourcesService, PuppeteerService],
  exports: [SourcesService, PuppeteerService],
})
export class SourcesModule {}
