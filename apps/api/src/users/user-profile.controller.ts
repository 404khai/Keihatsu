import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
  ApiExtraModels,
  getSchemaPath,
  ApiNoContentResponse,
} from '@nestjs/swagger';
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
  Delete,
  HttpCode,
  HttpStatus,
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

@ApiTags('User profile')
@Controller('user/profile')
export class UserProfileController {
  constructor(private readonly usersService: UsersService) {}

  @Get('stats')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get account statistics' })
  async getStats(@Req() req: AuthenticatedRequest) {
    return this.usersService.getUserStats(req.user.id);
  }

  @Get('public/:userId')
  @ApiOperation({ summary: 'Get a public profile' })
  getPublicProfile(@Param('userId') userId: string) {
    return this.usersService.getPublicProfile(userId);
  }

  @Patch()
  @ApiBearerAuth()
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
  @ApiOperation({ summary: 'Update profile fields and images' })
  @ApiConsumes('multipart/form-data', 'application/json')
  @ApiExtraModels(UpdateUserProfileDto)
  @ApiBody({
    schema: {
      allOf: [
        { $ref: getSchemaPath(UpdateUserProfileDto) },
        {
          type: 'object',
          properties: {
            avatar: {
              type: 'string',
              format: 'binary',
              description: 'Optional avatar upload; multipart only.',
            },
            banner: {
              type: 'string',
              format: 'binary',
              description: 'Optional banner upload; multipart only.',
            },
          },
        },
      ],
    },
  })
  updateProfile(
    @Req() req: AuthenticatedRequest,
    @Body() updateDto: UpdateUserProfileDto,
    @UploadedFiles()
    files: { avatar?: Express.Multer.File[]; banner?: Express.Multer.File[] },
  ) {
    return this.usersService.updateProfile(req.user.id, updateDto, files || {});
  }

  @Patch('visibility')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Change public profile visibility' })
  updateProfileVisibility(
    @Req() req: AuthenticatedRequest,
    @Body() updateDto: UpdateProfileVisibilityDto,
  ) {
    return this.usersService.updateProfileVisibility(
      req.user.id,
      updateDto.isProfilePublic,
    );
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Delete the signed-in account' })
  @ApiNoContentResponse({ description: 'Account deleted.' })
  async deleteAccount(@Req() req: AuthenticatedRequest): Promise<void> {
    await this.usersService.deleteAccount(req.user.id);
  }
}
