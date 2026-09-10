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
    const iosClientId = this.configService.get<string>('GOOGLE_CLIENT_ID_IOS');
    const clientId = webClientId || androidClientId || iosClientId;
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
      const iosClientId = this.configService.get<string>(
        'GOOGLE_CLIENT_ID_IOS',
      );
      const audiences: string[] = [];

      if (webClientId) {
        audiences.push(webClientId);
      }
      if (androidClientId) {
        audiences.push(androidClientId);
      }
      if (iosClientId) {
        audiences.push(iosClientId);
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

    const {
      sub: googleId,
      email,
      email_verified: emailVerified,
      name,
    } = payload;

    if (!email) {
      throw new UnauthorizedException('Email not found in Google token');
    }
    if (!emailVerified) {
      throw new UnauthorizedException('Google email is not verified');
    }

    const normalizedEmail = email.trim().toLowerCase();

    let user = await this.usersService.findByGoogleId(googleId);

    if (!user) {
      // The OAuth subject can differ when platform clients were configured in
      // separate Google projects. A verified email is the cross-platform
      // account key, so Android and iOS still resolve to one backend user.
      const userByEmail = await this.usersService.findByEmail(normalizedEmail);

      if (userByEmail) {
        user = await this.usersService.updateUser({
          where: { id: userByEmail.id },
          data: { googleId, avatarUrl: null },
        });
      } else {
        user = await this.usersService.createGoogleUser({
          googleId,
          email: normalizedEmail,
          displayName: name || normalizedEmail.split('@')[0],
        });
      }
    }

    // Never retain an identifying Google profile photo. Existing accounts are
    // migrated to their deterministic Blobatar the next time they sign in.
    if (user.avatarUrl) {
      user = await this.usersService.updateUser({
        where: { id: user.id },
        data: { avatarUrl: null },
      });
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
