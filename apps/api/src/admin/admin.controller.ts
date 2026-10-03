import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiForbiddenResponse,
} from '@nestjs/swagger';
import { Controller, Get, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { AdminService } from './admin.service';
import { AdminStatsDto } from './dto/admin-stats.dto';

@ApiTags('Admin')
@Controller('admin')
@ApiBearerAuth()
@ApiForbiddenResponse({ description: 'Requires an ADMIN account.' })
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminController {
  constructor(private adminService: AdminService) {}

  @Get('analytics')
  @ApiOperation({ summary: 'Get live admin analytics and source health' })
  getAnalytics() {
    return this.adminService.getAnalytics();
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get administrator dashboard statistics' })
  async getStats(): Promise<AdminStatsDto> {
    return this.adminService.getDashboardStats();
  }
}
