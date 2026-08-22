import { Controller, Post, Param, UseGuards, Req } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('manga')
@UseGuards(JwtAuthGuard)
export class MangaCategoryController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Post(':mangaId/category/:categoryId')
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
