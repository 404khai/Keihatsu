import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { DownloadsService } from './downloads.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { IsString, IsNotEmpty } from 'class-validator';

export class DownloadChapterDto {
  @IsString()
  @IsNotEmpty()
  sourceId: string;

  @IsString()
  @IsNotEmpty()
  mangaId: string;

  @IsString()
  @IsNotEmpty()
  chapterId: string;
}

@Controller('downloads')
export class DownloadsController {
  constructor(private readonly downloadsService: DownloadsService) {}

  @Post('process')
  @UseGuards(JwtAuthGuard)
  async downloadChapter(@Body() body: DownloadChapterDto) {
    return this.downloadsService.downloadChapter(
      body.sourceId,
      body.mangaId,
      body.chapterId,
    );
  }
}
