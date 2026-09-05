import { Controller, Get, Put, Body, UseGuards, Req } from '@nestjs/common';
import { UsersService } from './users.service';
import { UpdateUserPreferencesDto } from './dto/user-preferences.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('user/preferences')
@UseGuards(JwtAuthGuard)
export class UserPreferencesController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  getPreferences(@Req() req: any) {
    return this.usersService.getPreferences(req.user.id);
  }

  @Put()
  updatePreferences(
    @Req() req: any,
    @Body() updateDto: UpdateUserPreferencesDto,
  ) {
    return this.usersService.updatePreferences(req.user.id, updateDto);
  }
}
