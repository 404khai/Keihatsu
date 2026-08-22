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
  UpdateLibraryEntryDto,
} from './dto/library-entry.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('user/library')
@UseGuards(JwtAuthGuard)
export class LibraryController {
  constructor(private readonly libraryService: LibraryService) {}

  @Post()
  create(@Req() req: any, @Body() createDto: CreateLibraryEntryDto) {
    return this.libraryService.create(req.user.id, createDto);
  }

  @Get()
  findAll(@Req() req: any, @Query() query: any) {
    return this.libraryService.findAll(req.user.id, query);
  }

  @Put(':id')
  update(
    @Req() req: any,
    @Param('id') id: string,
    @Body() updateDto: UpdateLibraryEntryDto,
  ) {
    return this.libraryService.update(id, req.user.id, updateDto);
  }

  @Delete(':id')
  remove(@Req() req: any, @Param('id') id: string) {
    return this.libraryService.remove(id, req.user.id);
  }
}
