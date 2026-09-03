import {
  Controller,
  Get,
  Param,
  Query,
  BadRequestException,
  BadGatewayException,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import axios from 'axios';
import type { Request, Response } from 'express';
import { SourcesService } from './sources.service';
import { PuppeteerService } from './core/puppeteer.service';
import { UsersService } from '../users/users.service';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { MangasPageDTO, MangaDTO, ChapterDTO, PageDTO } from './dto/manga.dto';

@Controller('sources')
export class SourcesController {
  constructor(
    private readonly sourcesService: SourcesService,
    private readonly usersService: UsersService,
    private readonly puppeteerService: PuppeteerService,
  ) {}

  @Get('proxy/image')
  async proxyImage(
    @Query('url') url: string,
    @Query('referer') referer: string | undefined,
    @Res() res: Response,
  ): Promise<void> {
    if (!url) {
      throw new BadRequestException('Missing image url');
    }

    let parsedUrl: URL;
    try {
      parsedUrl = new URL(url);
    } catch {
      throw new BadRequestException('Invalid image url');
    }

    const isBatCave =
      parsedUrl.hostname === 'batcave.biz' ||
      parsedUrl.hostname.endsWith('.batcave.biz');
    const isManhuaTop =
      parsedUrl.hostname === 'manhuatop.org' ||
      parsedUrl.hostname.endsWith('.manhuatop.org');

    if (parsedUrl.protocol !== 'https:' || (!isBatCave && !isManhuaTop)) {
      throw new BadRequestException(
        'Only BatCave and ManhuaTop assets can be proxied',
      );
    }

    if (isManhuaTop) {
      const safeReferer =
        referer &&
        (() => {
          try {
            const parsedReferer = new URL(referer);
            return (
              parsedReferer.protocol === 'https:' &&
              (parsedReferer.hostname === 'manhuatop.org' ||
                parsedReferer.hostname.endsWith('.manhuatop.org'))
            );
          } catch {
            return false;
          }
        })()
          ? referer
          : 'https://manhuatop.org/';

      try {
        const image = await this.puppeteerService.fetchBinary(url, safeReferer);
        res.setHeader('Content-Type', image.contentType);
        res.setHeader('Content-Length', image.data.length.toString());
        res.setHeader('Cache-Control', 'public, max-age=86400');
        res.end(image.data);
        return;
      } catch {
        throw new BadGatewayException('Failed to proxy ManhuaTop image');
      }
    }

    const safeReferer =
      referer && referer.startsWith('https://batcave.biz/')
        ? referer
        : 'https://batcave.biz/';

    try {
      const upstream = await axios.get(url, {
        responseType: 'stream',
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
          Referer: safeReferer,
          Origin: 'https://batcave.biz',
          Accept: 'image/webp,image/apng,image/*,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
        },
        timeout: 30000,
      });

      const contentType = upstream.headers['content-type'];
      const cacheControl = upstream.headers['cache-control'];
      const contentLength = upstream.headers['content-length'];

      if (contentType) {
        res.setHeader('Content-Type', contentType);
      }
      if (cacheControl) {
        res.setHeader('Cache-Control', cacheControl);
      }
      if (contentLength) {
        res.setHeader('Content-Length', contentLength);
      }

      await new Promise<void>((resolve, reject) => {
        upstream.data.on('end', () => resolve());
        upstream.data.on('error', (error: Error) => reject(error));
        upstream.data.pipe(res);
      });
    } catch (error) {
      if (axios.isAxiosError(error) && error.response?.status) {
        throw new BadGatewayException(
          `Upstream image request failed with status ${error.response.status}`,
        );
      }

      throw new BadGatewayException('Failed to proxy BatCave image');
    }
  }

  @Get()
  @UseGuards(OptionalJwtAuthGuard)
  async getSources(@Req() req: Request & { user?: any }) {
    let sources = this.sourcesService.getSources();
    const baseUrl = `${req.protocol}://${req.get('host')}`;

    if (req.user && req.user.id) {
      const preferences = (await this.usersService.getPreferences(
        req.user.id,
      )) as any;
      const sourcePrefs = preferences.source_preferences || {};

      // Filter out disabled sources
      sources = sources.filter((s) => {
        const pref = sourcePrefs[s.id];
        // If pref exists and enabled is explicitly false, filter out
        return !(pref && pref.enabled === false);
      });

      // Sort: pinned first
      sources.sort((a, b) => {
        const prefA = sourcePrefs[a.id];
        const prefB = sourcePrefs[b.id];
        const pinnedA = prefA?.pinned || false;
        const pinnedB = prefB?.pinned || false;

        if (pinnedA === pinnedB) return 0;
        return pinnedA ? -1 : 1;
      });
    }

    return sources.map((source) => ({
      ...source,
      iconUrl:
        source.iconUrl && source.iconUrl.startsWith('/')
          ? `${baseUrl}${source.iconUrl}`
          : source.iconUrl,
    }));
  }

  @Get(':sourceId/manga')
  async getMangaList(
    @Param('sourceId') sourceId: string,
    @Query('type') type: string,
    @Query('page') page: number = 1,
    @Query('q') query?: string,
    @Query('filters') filters?: any,
  ): Promise<MangasPageDTO> {
    if (!['popular', 'latest', 'search'].includes(type)) {
      throw new BadRequestException(
        'Invalid type. Must be popular, latest, or search',
      );
    }

    return this.sourcesService.getMangaList(
      sourceId,
      type as 'popular' | 'latest' | 'search',
      Number(page),
      query,
      filters,
    );
  }

  @Get(':sourceId/manga/:mangaId')
  async getMangaDetails(
    @Param('sourceId') sourceId: string,
    @Param('mangaId') mangaId: string,
  ): Promise<MangaDTO> {
    return this.sourcesService.getMangaDetails(sourceId, mangaId);
  }

  @Get(':sourceId/manga/:mangaId/chapters')
  async getChapterList(
    @Param('sourceId') sourceId: string,
    @Param('mangaId') mangaId: string,
  ): Promise<ChapterDTO[]> {
    return this.sourcesService.getChapterList(sourceId, mangaId);
  }

  @Get(':sourceId/chapters/:chapterId/pages')
  async getPageList(
    @Param('sourceId') sourceId: string,
    @Param('chapterId') chapterId: string,
  ): Promise<PageDTO[]> {
    return this.sourcesService.getPageList(sourceId, chapterId);
  }
}
