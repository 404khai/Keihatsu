import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
  Query,
  Delete,
  Param,
} from '@nestjs/common';
import { HistoryService } from './history.service';
import { SyncHistoryDto } from './dto/sync-history.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('history')
@UseGuards(JwtAuthGuard)
export class HistoryController {
  constructor(private readonly historyService: HistoryService) {}

  @Post('sync')
  async sync(@Request() req, @Body() body: SyncHistoryDto) {
    return this.historyService.syncHistory(req.user.id, body);
  }

  @Get()
  async getHistory(
    @Request() req,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '50',
  ) {
    return this.historyService.getHistory(req.user.id, +page, +limit);
  }

  @Delete(':mangaId')
  async deleteHistory(@Request() req, @Param('mangaId') mangaId: string) {
    return this.historyService.deleteHistoryEntry(req.user.id, mangaId);
  }
}
