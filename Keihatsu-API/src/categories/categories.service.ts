import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';

@Injectable()
export class CategoriesService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, createDto: CreateCategoryDto) {
    // Check uniqueness
    const existing = await this.prisma.category.findUnique({
      where: {
        userId_name: {
          userId,
          name: createDto.name,
        },
      },
    });

    if (existing) {
      throw new ConflictException('Category with this name already exists');
    }

    return this.prisma.category.create({
      data: {
        ...createDto,
        userId,
      },
    });
  }

  async findAll(userId: string, includeCount: boolean = false) {
    const categories = await this.prisma.category.findMany({
      where: { userId },
      include: {
        _count: includeCount ? { select: { entries: true } } : false,
      },
      orderBy: { name: 'asc' },
    });

    // If includeCount is requested, we might want to flatten the structure slightly or just return as is
    // Prisma returns _count: { entries: 5 }.
    return categories;
  }

  async update(id: string, userId: string, updateDto: UpdateCategoryDto) {
    const category = await this.prisma.category.findUnique({
      where: { id },
    });

    if (!category || category.userId !== userId) {
      throw new NotFoundException('Category not found');
    }

    return this.prisma.category.update({
      where: { id },
      data: updateDto,
    });
  }

  async remove(id: string, userId: string) {
    const category = await this.prisma.category.findUnique({
      where: { id },
    });

    if (!category || category.userId !== userId) {
      throw new NotFoundException('Category not found');
    }

    return this.prisma.category.delete({
      where: { id },
    });
  }

  async addMangaToCategory(
    userId: string,
    mangaId: string,
    categoryId: string,
  ) {
    // 1. Verify Category ownership
    const category = await this.prisma.category.findUnique({
      where: { id: categoryId },
    });
    if (!category || category.userId !== userId) {
      throw new NotFoundException('Category not found');
    }

    // 2. Find Library Entry (Manga must be in library first)
    // We assume mangaId is the external ID. We need the internal LibraryEntry ID.
    const entry = await this.prisma.libraryEntry.findUnique({
      where: {
        userId_mangaId: {
          userId,
          mangaId,
        },
      },
    });

    if (!entry) {
      throw new NotFoundException('Manga not in library');
    }

    // 3. Connect (Replace existing categories)
    return this.prisma.libraryEntry.update({
      where: { id: entry.id },
      data: {
        categories: {
          set: [{ id: categoryId }],
        },
      },
    });
  }
}
