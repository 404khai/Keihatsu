import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UserPreferencesController } from './user-preferences.controller';
import { UserProfileController } from './user-profile.controller';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';

@Module({
  imports: [CloudinaryModule],
  controllers: [UserPreferencesController, UserProfileController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
