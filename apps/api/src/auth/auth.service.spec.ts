import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

describe('AuthService', () => {
  let service: AuthService;
  const usersService = {
    findByGoogleId: jest.fn(),
    findByEmail: jest.fn(),
    createGoogleUser: jest.fn(),
    updateUser: jest.fn(),
  };
  const jwtService = { sign: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: usersService },
        { provide: JwtService, useValue: jwtService },
        { provide: ConfigService, useValue: { get: jest.fn() } },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('reuses the existing backend account across Google platform clients', async () => {
    const existingUser = {
      id: 'existing-user-id',
      googleId: 'ios-google-subject',
      email: 'reader@example.com',
      avatarUrl: null,
    };
    const linkedUser = {
      ...existingUser,
      googleId: 'android-google-subject',
    };
    jest.spyOn(service, 'verifyGoogleToken').mockResolvedValue({
      sub: 'android-google-subject',
      email: 'Reader@Example.com',
      email_verified: true,
      name: 'Reader',
    });
    usersService.findByGoogleId.mockResolvedValue(null);
    usersService.findByEmail.mockResolvedValue(existingUser);
    usersService.updateUser
      .mockResolvedValueOnce(linkedUser)
      .mockResolvedValueOnce(linkedUser);
    jwtService.sign.mockReturnValue('backend-access-token');

    const response = await service.loginWithGoogle('android-id-token');

    expect(usersService.findByEmail).toHaveBeenCalledWith('reader@example.com');
    expect(usersService.updateUser).toHaveBeenNthCalledWith(1, {
      where: { id: 'existing-user-id' },
      data: {
        googleId: 'android-google-subject',
        avatarUrl: null,
      },
    });
    expect(jwtService.sign).toHaveBeenCalledWith({
      sub: 'existing-user-id',
      email: 'reader@example.com',
    });
    expect(response).toEqual({
      accessToken: 'backend-access-token',
      user: linkedUser,
    });
  });
});
