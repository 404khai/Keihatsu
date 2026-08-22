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
import { CategoriesService } from './categories.service';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('user/categories')
@UseGuards(JwtAuthGuard)
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Post()
  create(@Req() req: any, @Body() createDto: CreateCategoryDto) {
    return this.categoriesService.create(req.user.id, createDto);
  }

  @Get()
  findAll(@Req() req: any, @Query('include_count') includeCount: string) {
    return this.categoriesService.findAll(req.user.id, includeCount === 'true');
  }

  @Put(':id')
  update(
    @Req() req: any,
    @Param('id') id: string,
    @Body() updateDto: UpdateCategoryDto,
  ) {
    return this.categoriesService.update(id, req.user.id, updateDto);
  }

  @Delete(':id')
  remove(@Req() req: any, @Param('id') id: string) {
    return this.categoriesService.remove(id, req.user.id);
  }
}

// Separate controller for manga assignment or just add endpoint here?
// Requirement: POST /api/manga/{manga_id}/category/{category_id}
// Since this is specific to manga and categories, let's put it here but mapped to root.
// Or actually, NestJS controllers are prefix-based.
// Let's make a new Controller class for the Manga path if needed, or just handle it here with a global route.
// However, standard Nest practice is to keep it under the controller's path.
// The user explicitly asked for `POST /api/manga/{manga_id}/category/{category_id}`.
// I'll create a separate controller method or a new controller file for this specific route to match the requirement exactly,
// OR I can use a global prefix.
// Let's add it to a new controller `MangaCategoryController` in the same module to handle that specific path.
