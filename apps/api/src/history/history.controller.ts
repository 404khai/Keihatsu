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
    @Query('include_deleted') includeDeleted: string = 'false',
  ) {
    return this.historyService.getHistory(
      req.user.id,
      +page,
      +limit,
      includeDeleted === 'true',
    );
  }

  @Delete(':sourceId/:mangaId')
  async deleteSourceHistory(
    @Request() req,
    @Param('sourceId') sourceId: string,
    @Param('mangaId') mangaId: string,
    @Query('operation_id') operationId?: string,
    @Query('deleted_at') deletedAt?: string,
  ) {
    return this.historyService.deleteHistoryEntry(
      req.user.id,
      mangaId,
      sourceId,
      operationId,
      deletedAt,
    );
  }

  @Delete(':mangaId')
  async deleteHistory(@Request() req, @Param('mangaId') mangaId: string) {
    return this.historyService.deleteHistoryEntry(req.user.id, mangaId);
  }
}
