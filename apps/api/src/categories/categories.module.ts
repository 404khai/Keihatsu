import { Module } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { CategoriesController } from './categories.controller';
import { MangaCategoryController } from './manga-category.controller';

@Module({
  controllers: [CategoriesController, MangaCategoryController],
  providers: [CategoriesService],
})
export class CategoriesModule {}
