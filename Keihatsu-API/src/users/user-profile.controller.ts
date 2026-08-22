import {
  Controller,
  Patch,
  Get,
  Body,
  UseGuards,
  Req,
  UseInterceptors,
  UploadedFiles,
  Param,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { UpdateUserProfileDto } from './dto/update-user-profile.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { UpdateProfileVisibilityDto } from './dto/update-profile-visibility.dto';
import { Request } from 'express';

type AuthenticatedRequest = Request & {
  user: {
    id: string;
  };
};

@Controller('user/profile')
export class UserProfileController {
  constructor(private readonly usersService: UsersService) {}

  @Get('stats')
  @UseGuards(JwtAuthGuard)
  async getStats(@Req() req: AuthenticatedRequest) {
    return this.usersService.getUserStats(req.user.id);
  }

  @Get('public/:userId')
  getPublicProfile(@Param('userId') userId: string) {
    return this.usersService.getPublicProfile(userId);
  }

  @Patch()
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(
    FileFieldsInterceptor(
      [
        { name: 'avatar', maxCount: 1 },
        { name: 'banner', maxCount: 1 },
      ],
      {
        storage: memoryStorage(), // Use memory storage for Cloudinary
      },
    ),
  )
  updateProfile(
    @Req() req: AuthenticatedRequest,
    @Body() updateDto: UpdateUserProfileDto,
    @UploadedFiles()
    files: { avatar?: Express.Multer.File[]; banner?: Express.Multer.File[] },
  ) {
    return this.usersService.updateProfile(req.user.id, updateDto, files || {});
  }

  @Patch('visibility')
  @UseGuards(JwtAuthGuard)
  updateProfileVisibility(
    @Req() req: AuthenticatedRequest,
    @Body() updateDto: UpdateProfileVisibilityDto,
  ) {
    return this.usersService.updateProfileVisibility(
      req.user.id,
      updateDto.isProfilePublic,
    );
  }
}
