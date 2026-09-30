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
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Req,
} from '@nestjs/common';
import { LibraryService } from './library.service';
import {
  CreateLibraryEntryDto,
  SetLibraryCategoriesDto,
  UpdateLibraryEntryDto,
} from './dto/library-entry.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Library')
@Controller('user/library')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
export class LibraryController {
  constructor(private readonly libraryService: LibraryService) {}

  @Post()
  @ApiOperation({ summary: 'Add a manga to the library' })
  create(@Req() req: any, @Body() createDto: CreateLibraryEntryDto) {
    return this.libraryService.create(req.user.id, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'List library entries with filters and sorting' })
  @ApiQuery({
    name: 'filter_downloaded',
    required: false,
    enum: ['true', 'false'],
  })
  @ApiQuery({ name: 'filter_unread', required: false, enum: ['true', 'false'] })
  @ApiQuery({
    name: 'filter_started',
    required: false,
    enum: ['true', 'false'],
  })
  @ApiQuery({
    name: 'filter_bookmarked',
    required: false,
    enum: ['true', 'false'],
  })
  @ApiQuery({
    name: 'filter_completed',
    required: false,
    enum: ['true', 'false'],
  })
  @ApiQuery({
    name: 'search',
    required: false,
    description: 'Search manga titles and authors.',
  })
  @ApiQuery({
    name: 'sort_by',
    required: false,
    enum: [
      'alphabetical',
      'last_read',
      'last_updated',
      'unread_count',
      'total_chapters',
      'date_added',
    ],
  })
  @ApiQuery({
    name: 'order',
    required: false,
    enum: ['asc', 'desc'],
    schema: { default: 'asc' },
  })
  findAll(@Req() req: any, @Query() query: any) {
    return this.libraryService.findAll(req.user.id, query);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update library reading flags' })
  update(
    @Req() req: any,
    @Param('id') id: string,
    @Body() updateDto: UpdateLibraryEntryDto,
  ) {
    return this.libraryService.update(id, req.user.id, updateDto);
  }

  @Put(':id/categories')
  @ApiOperation({ summary: 'Replace categories assigned to a library entry' })
  setCategories(
    @Req() req: any,
    @Param('id') id: string,
    @Body() body: SetLibraryCategoriesDto,
  ) {
    return this.libraryService.setCategories(id, req.user.id, body.categoryIds);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a manga from the library' })
  remove(@Req() req: any, @Param('id') id: string) {
    return this.libraryService.remove(id, req.user.id);
  }
}
