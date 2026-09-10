import {
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
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

export class SetLibraryCategoriesDto {
  @IsArray()
  @ArrayUnique()
  @IsUUID('4', { each: true })
  categoryIds: string[];
}
