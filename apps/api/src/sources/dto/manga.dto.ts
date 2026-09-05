import {
  IsString,
  IsNumber,
  IsBoolean,
  IsArray,
  IsOptional,
} from 'class-validator';
import {
  Manga,
  Chapter,
  Page,
  MangasPage,
} from '../interfaces/manga.interface';

export class MangaDTO implements Manga {
  @IsString()
  id: string;

  @IsString()
  url: string;

  @IsString()
  title: string;

  @IsString()
  thumbnailUrl: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  author?: string;

  @IsString()
  @IsOptional()
  artist?: string;

  @IsString()
  @IsOptional()
  status?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  genres?: string[];

  @IsString()
  sourceId: string;
}

export class ChapterDTO implements Chapter {
  @IsString()
  id: string;

  @IsString()
  url: string;

  @IsString()
  name: string;

  @IsNumber()
  dateUpload: number;

  @IsNumber()
  chapterNumber: number;

  @IsString()
  @IsOptional()
  scanlator?: string;
}

export class PageDTO implements Page {
  @IsNumber()
  index: number;

  @IsString()
  imageUrl: string;

  @IsString()
  url: string;
}

export class MangasPageDTO implements MangasPage {
  @IsArray()
  mangas: MangaDTO[];

  @IsBoolean()
  hasNextPage: boolean;
}
