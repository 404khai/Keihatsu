import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  UseGuards,
  UseInterceptors,
  UploadedFiles,
  Req,
} from '@nestjs/common';
import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { FilesInterceptor } from '@nestjs/platform-express';
import { Request } from 'express';

@Controller('comments')
export class CommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  @UseGuards(JwtAuthGuard)
  @Post(':mangaId/:chapterId')
  @UseInterceptors(FilesInterceptor('images', 5)) // Allow up to 5 images per comment
  async create(
    @Param('mangaId') mangaId: string,
    @Param('chapterId') chapterId: string,
    @Body() createCommentDto: CreateCommentDto,
    @UploadedFiles() files: Array<Express.Multer.File>,
    @Req() req: any,
  ) {
    return this.commentsService.create(
      req.user.id,
      mangaId,
      chapterId,
      createCommentDto,
      files,
    );
  }

  @UseGuards(OptionalJwtAuthGuard)
  @Get(':mangaId/:chapterId')
  findAll(
    @Param('mangaId') mangaId: string,
    @Param('chapterId') chapterId: string,
    @Req() req: any,
  ) {
    return this.commentsService.findAll(mangaId, chapterId, req.user?.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/like')
  async like(@Param('id') id: string, @Req() req: any) {
    return this.commentsService.like(req.user.id, id);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  remove(@Param('id') id: string, @Req() req: any) {
    return this.commentsService.remove(id, req.user.id);
  }
}
