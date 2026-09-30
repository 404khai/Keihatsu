import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class GoogleLoginDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({
    description: 'Google ID token issued for a configured app client.',
    writeOnly: true,
  })
  token: string;
}
