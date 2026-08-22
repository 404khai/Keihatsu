import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateLibraryEntryDto {
  @IsNotEmpty()
  @IsString()
  mangaId: string;

  @IsNotEmpty()
  @IsString()
  sourceId: string;

  @IsNotEmpty()
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  thumbnailUrl?: string;

  @IsOptional()
  @IsString()
  author?: string;

  @IsOptional()
  @IsString()
  language?: string;
}

export class UpdateLibraryEntryDto {
  @IsOptional()
  @IsBoolean()
  isUnread?: boolean;

  @IsOptional()
  @IsBoolean()
  isStarted?: boolean;

  @IsOptional()
  @IsBoolean()
  isBookmarked?: boolean;

  @IsOptional()
  @IsBoolean()
  isCompleted?: boolean;
}
