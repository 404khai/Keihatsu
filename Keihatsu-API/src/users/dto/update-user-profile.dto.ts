import { IsOptional, IsString, Length } from 'class-validator';

export class UpdateUserProfileDto {
  @IsOptional()
  @IsString()
  @Length(3, 30)
  username?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  bio?: string;
}
