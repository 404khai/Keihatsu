import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
  ApiExtraModels,
  getSchemaPath,
} from '@nestjs/swagger';
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

@ApiTags('Comments')
@Controller('comments')
export class CommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('source/:sourceId/:mangaId/:chapterId')
  @UseInterceptors(FilesInterceptor('images', 5))
  @ApiOperation({ summary: 'Create a comment or reply for a source chapter' })
  @ApiConsumes('multipart/form-data', 'application/json')
  @ApiExtraModels(CreateCommentDto)
  @ApiBody({
    schema: {
      allOf: [
        { $ref: getSchemaPath(CreateCommentDto) },
        {
          type: 'object',
          properties: {
            images: {
              type: 'array',
              maxItems: 5,
              description:
                'Optional image uploads when using multipart/form-data.',
              items: { type: 'string', format: 'binary' },
            },
          },
        },
      ],
    },
  })
  createForSource(
    @Param('sourceId') sourceId: string,
    @Param('mangaId') mangaId: string,
    @Param('chapterId') chapterId: string,
    @Body() createCommentDto: CreateCommentDto,
    @UploadedFiles() files: Array<Express.Multer.File>,
    @Req() req: any,
  ) {
    return this.commentsService.create(
      req.user.id,
      sourceId,
      mangaId,
      chapterId,
      createCommentDto,
      files,
    );
  }

  @UseGuards(OptionalJwtAuthGuard)
  @Get('source/:sourceId/:mangaId/:chapterId')
  @ApiOperation({
    summary: 'List a source chapter’s comment threads',
    security: [{}, { bearer: [] }],
  })
  findAllForSource(
    @Param('sourceId') sourceId: string,
    @Param('mangaId') mangaId: string,
    @Param('chapterId') chapterId: string,
    @Req() req: any,
  ) {
    return this.commentsService.findAll(
      sourceId,
      mangaId,
      chapterId,
      req.user?.id,
    );
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post(['like/:id', ':id/like'])
  @ApiOperation({ summary: 'Toggle a comment like' })
  async like(@Param('id') id: string, @Req() req: any) {
    return this.commentsService.like(req.user.id, id);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post(':mangaId/:chapterId')
  @UseInterceptors(FilesInterceptor('images', 5)) // Allow up to 5 images per comment
  @ApiOperation({
    summary: 'Create a ManhuaTop comment or reply (legacy route)',
  })
  @ApiConsumes('multipart/form-data', 'application/json')
  @ApiExtraModels(CreateCommentDto)
  @ApiBody({
    schema: {
      allOf: [
        { $ref: getSchemaPath(CreateCommentDto) },
        {
          type: 'object',
          properties: {
            images: {
              type: 'array',
              maxItems: 5,
              description:
                'Optional image uploads when using multipart/form-data.',
              items: { type: 'string', format: 'binary' },
            },
          },
        },
      ],
    },
  })
  async create(
    @Param('mangaId') mangaId: string,
    @Param('chapterId') chapterId: string,
    @Body() createCommentDto: CreateCommentDto,
    @UploadedFiles() files: Array<Express.Multer.File>,
    @Req() req: any,
  ) {
    return this.commentsService.create(
      req.user.id,
      'manhuatop',
      mangaId,
      chapterId,
      createCommentDto,
      files,
    );
  }

  @UseGuards(OptionalJwtAuthGuard)
  @Get(':mangaId/:chapterId')
  @ApiOperation({
    summary: 'List ManhuaTop comment threads (legacy route)',
    security: [{}, { bearer: [] }],
  })
  findAll(
    @Param('mangaId') mangaId: string,
    @Param('chapterId') chapterId: string,
    @Req() req: any,
  ) {
    return this.commentsService.findAll(
      'manhuatop',
      mangaId,
      chapterId,
      req.user?.id,
    );
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  @ApiOperation({ summary: 'Delete an owned comment' })
  remove(@Param('id') id: string, @Req() req: any) {
    return this.commentsService.remove(id, req.user.id);
  }
}
