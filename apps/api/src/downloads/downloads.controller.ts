import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiProperty,
} from '@nestjs/swagger';
import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { DownloadsService } from './downloads.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { IsString, IsNotEmpty } from 'class-validator';

export class DownloadChapterDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  sourceId: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  mangaId: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  chapterId: string;
}

@ApiTags('Downloads')
@Controller('downloads')
export class DownloadsController {
  constructor(private readonly downloadsService: DownloadsService) {}

  @Post('process')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Download chapter pages on the API server' })
  async downloadChapter(@Body() body: DownloadChapterDto) {
    return this.downloadsService.downloadChapter(
      body.sourceId,
      body.mangaId,
      body.chapterId,
    );
  }
}
