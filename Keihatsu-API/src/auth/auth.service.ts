import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client } from 'google-auth-library';
import { UsersService } from '../users/users.service';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private googleClient: OAuth2Client;

  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {
    const webClientId = this.configService.get<string>('GOOGLE_CLIENT_ID_WEB');
    const androidClientId = this.configService.get<string>(
      'GOOGLE_CLIENT_ID_ANDROID',
    );
    const clientId = webClientId || androidClientId;
    this.googleClient = new OAuth2Client(clientId);
  }

  async login(loginDto: LoginDto) {
    const user = await this.usersService.findByEmail(loginDto.email);

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.password) {
      throw new UnauthorizedException(
        'Account does not have a password set. Please use Google Login.',
      );
    }

    const isPasswordValid = await bcrypt.compare(
      loginDto.password,
      user.password,
    );

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Update last login
    await this.usersService.updateUser({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    return this.generateTokens(user);
  }

  async verifyGoogleToken(token: string) {
    try {
      const webClientId = this.configService.get<string>(
        'GOOGLE_CLIENT_ID_WEB',
      );
      const androidClientId = this.configService.get<string>(
        'GOOGLE_CLIENT_ID_ANDROID',
      );
      const audiences: string[] = [];

      if (webClientId) {
        audiences.push(webClientId);
      }
      if (androidClientId) {
        audiences.push(androidClientId);
      }

      let audience: string | string[] | undefined;
      if (audiences.length === 1) {
        audience = audiences[0];
      } else if (audiences.length > 1) {
        audience = audiences;
      }

      const ticket = await this.googleClient.verifyIdToken({
        idToken: token,
        audience,
      });
      return ticket.getPayload();
    } catch (error) {
      this.logger.warn(
        `Google token verification failed: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
      throw new UnauthorizedException('Invalid Google token');
    }
  }

  async loginWithGoogle(token: string) {
    const payload = await this.verifyGoogleToken(token);

    if (!payload) {
      throw new UnauthorizedException('Invalid Google token payload');
    }

    const { sub: googleId, email, name, picture } = payload;

    if (!email) {
      throw new UnauthorizedException('Email not found in Google token');
    }

    let user = await this.usersService.findByGoogleId(googleId);

    if (!user) {
      // Check if user exists with same email (maybe signed up differently if we had other methods, but good practice)
      const userByEmail = await this.usersService.findByEmail(email);

      if (userByEmail) {
        // Link account logic could go here, for now, we just update or throw.
        // Since we only have Google auth, this case shouldn't happen unless we manually inserted data.
        // Or if we decide to support multiple providers later.
        // Let's assume we just return that user or update googleId.
        user = await this.usersService.updateUser({
          where: { id: userByEmail.id },
          data: { googleId, avatarUrl: picture || userByEmail.avatarUrl },
        });
      } else {
        user = await this.usersService.createGoogleUser({
          googleId,
          email,
          displayName: name || email.split('@')[0],
          avatarUrl: picture,
        });
      }
    }

    // Update last login
    await this.usersService.updateUser({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    return this.generateTokens(user);
  }

  async generateTokens(user: any) {
    const payload = { sub: user.id, email: user.email };
    return {
      accessToken: this.jwtService.sign(payload),
      user,
    };
  }

  async validateUser(payload: any) {
    return this.usersService.findOne({ id: payload.sub });
  }
}
