import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { Controller, Get, Put, Body, UseGuards, Req } from '@nestjs/common';
import { UsersService } from './users.service';
import { UpdateUserPreferencesDto } from './dto/user-preferences.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('User preferences')
@Controller('user/preferences')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
export class UserPreferencesController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @ApiOperation({ summary: 'Get reader and library preferences' })
  getPreferences(@Req() req: any) {
    return this.usersService.getPreferences(req.user.id);
  }

  @Put()
  @ApiOperation({ summary: 'Update reader and library preferences' })
  updatePreferences(
    @Req() req: any,
    @Body() updateDto: UpdateUserPreferencesDto,
  ) {
    return this.usersService.updatePreferences(req.user.id, updateDto);
  }
}
