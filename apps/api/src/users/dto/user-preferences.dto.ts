import {
  IsBoolean,
  IsNumber,
  IsOptional,
  IsString,
  IsObject,
  IsIn,
} from 'class-validator';

export class UpdateUserPreferencesDto {
  @IsOptional()
  @IsString()
  library_display_style?: string;

  @IsOptional()
  @IsNumber()
  library_items_per_row?: number;

  @IsOptional()
  @IsBoolean()
  overlay_show_downloaded?: boolean;

  @IsOptional()
  @IsBoolean()
  overlay_show_unread?: boolean;

  @IsOptional()
  @IsBoolean()
  overlay_show_language?: boolean;

  @IsOptional()
  @IsBoolean()
  tabs_show_categories?: boolean;

  @IsOptional()
  @IsBoolean()
  tabs_show_item_count?: boolean;

  @IsOptional()
  @IsIn(['compact grid', 'cover grid', 'comfortable grid', 'list'])
  categories_display_mode?: string;

  @IsOptional()
  @IsObject()
  source_preferences?: Record<string, { enabled: boolean; pinned: boolean }>;
}
