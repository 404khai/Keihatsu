import { IsString, IsNumber, IsOptional, IsBoolean } from 'class-validator';

export class SyncHistoryDto {
  @IsString()
  mangaId: string;

  @IsString()
  sourceId: string;

  @IsString()
  chapterId: string;

  @IsNumber()
  @IsOptional()
  pageNumber?: number;

  @IsString()
  @IsOptional()
  lastReadAt?: string; // ISO Date string

  @IsString()
  @IsOptional()
  title?: string;

  @IsString()
  @IsOptional()
  thumbnailUrl?: string;

  @IsString()
  @IsOptional()
  author?: string;

  @IsString()
  @IsOptional()
  chapterName?: string;

  @IsNumber()
  @IsOptional()
  chapterNumber?: number;

  @IsNumber()
  @IsOptional()
  readingTimeMs?: number;

  @IsBoolean()
  @IsOptional()
  isBookmarked?: boolean;

  @IsBoolean()
  @IsOptional()
  isRead?: boolean;
}
