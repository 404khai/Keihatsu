import { IsEmail, IsNotEmpty, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @IsEmail()
  @ApiProperty({ example: 'reader@example.com', format: 'email' })
  email: string;

  @IsNotEmpty()
  @MinLength(6)
  @ApiProperty({ format: 'password', writeOnly: true, minLength: 6 })
  password: string;
}
