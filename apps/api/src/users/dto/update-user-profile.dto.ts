import { IsIn, IsOptional, IsString, Length, Matches } from 'class-validator';

const avatarExpressions = [
  'idle',
  'happy',
  'sad',
  'mad',
  'surprised',
  'wink',
  'sleepy',
  'smug',
  'unsure',
  'scared',
  'love',
  'shy',
  'sick',
  'thinking',
] as const;

export class UpdateUserProfileDto {
  @IsOptional()
  @IsString()
  @Length(3, 30)
  username?: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  bio?: string;

  @IsOptional()
  @IsString()
  @Matches(/^(auto|\d+(?:\.\d+)?)$/)
  avatarHue?: string;

  @IsOptional()
  @IsString()
  @Matches(/^(auto|(?:0(?:\.\d+)?|1(?:\.0+)?))$/)
  avatarShape?: string;

  @IsOptional()
  @IsIn(avatarExpressions)
  avatarExpression?: (typeof avatarExpressions)[number];

  @IsOptional()
  @IsIn(['true', 'false'])
  avatarAnimated?: 'true' | 'false';
}
