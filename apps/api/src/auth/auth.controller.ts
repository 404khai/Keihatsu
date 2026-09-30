import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiCreatedResponse,
} from '@nestjs/swagger';
import {
  Controller,
  Post,
  Body,
  Get,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { GoogleLoginDto } from './dto/google-login.dto';
import { LoginDto } from './dto/login.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @ApiOperation({ summary: 'Sign in with email and password' })
  @ApiCreatedResponse({
    description:
      'Authenticated session. Use accessToken in the Authorize dialog.',
    schema: {
      type: 'object',
      required: ['accessToken', 'user'],
      properties: {
        accessToken: { type: 'string' },
        user: { type: 'object', additionalProperties: true },
      },
    },
  })
  async login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  @Post('google')
  @ApiOperation({ summary: 'Sign in with a Google ID token' })
  @ApiCreatedResponse({
    description:
      'Authenticated session. Use accessToken in the Authorize dialog.',
    schema: {
      type: 'object',
      required: ['accessToken', 'user'],
      properties: {
        accessToken: { type: 'string' },
        user: { type: 'object', additionalProperties: true },
      },
    },
  })
  async googleLogin(@Body() googleLoginDto: GoogleLoginDto) {
    return this.authService.loginWithGoogle(googleLoginDto.token);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('me')
  @ApiOperation({ summary: 'Get the signed-in account' })
  getProfile(@Request() req) {
    return req.user;
  }
}
