import { IsBoolean } from 'class-validator';

export class UpdateProfileVisibilityDto {
  @IsBoolean()
  isProfilePublic!: boolean;
}
