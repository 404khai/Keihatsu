import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
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

@ApiTags('History')
@Controller('history')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
export class HistoryController {
  constructor(private readonly historyService: HistoryService) {}

  @Post('sync')
  @ApiOperation({ summary: 'Synchronize a reading history event' })
  async sync(@Request() req, @Body() body: SyncHistoryDto) {
    return this.historyService.syncHistory(req.user.id, body);
  }

  @Get()
  @ApiOperation({ summary: 'List reading history' })
  @ApiQuery({
    name: 'page',
    required: false,
    schema: { type: 'integer', default: 1 },
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    schema: { type: 'integer', default: 50 },
  })
  @ApiQuery({
    name: 'include_deleted',
    required: false,
    enum: ['true', 'false'],
  })
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
  @ApiOperation({ summary: 'Delete a source-specific history entry' })
  @ApiQuery({
    name: 'operation_id',
    required: false,
    description: 'Idempotency identifier for the deletion.',
  })
  @ApiQuery({
    name: 'deleted_at',
    required: false,
    schema: { type: 'string', format: 'date-time' },
  })
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
  @ApiOperation({ summary: 'Delete a ManhuaTop history entry (legacy route)' })
  async deleteHistory(@Request() req, @Param('mangaId') mangaId: string) {
    return this.historyService.deleteHistoryEntry(req.user.id, mangaId);
  }
}
