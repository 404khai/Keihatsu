import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { Controller, Post, Param, UseGuards, Req } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Categories')
@Controller('manga')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
export class MangaCategoryController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Post(':mangaId/category/:categoryId')
  @ApiOperation({ summary: 'Assign a library manga to a category' })
  addMangaToCategory(
    @Req() req: any,
    @Param('mangaId') mangaId: string,
    @Param('categoryId') categoryId: string,
  ) {
    return this.categoriesService.addMangaToCategory(
      req.user.id,
      mangaId,
      categoryId,
    );
  }
}
