import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { Source } from './interfaces/source.interface';
import { CatalogueSource } from './interfaces/catalogue-source.interface';
import { MangasPage, Manga, Chapter, Page } from './interfaces/manga.interface';
import { ManhuaTopSource } from './extensions/manhuatop.source';
import { WeebCentralSource } from './extensions/weebcentral.source';
import { AtsumaruSource } from './extensions/atsumaru.source';
import { MangaFireSource } from './extensions/mangafire.source';
import { BatCaveSource } from './extensions/batcave.source';
import { PuppeteerService } from './core/puppeteer.service';

@Injectable()
export class SourcesService implements OnModuleInit {
  private sources: Map<string, CatalogueSource> = new Map();

  constructor(private puppeteerService: PuppeteerService) {
    // We will register sources here or via a module setup
  }

  onModuleInit() {
    this.registerSource(new ManhuaTopSource(this.puppeteerService));
    this.registerSource(new WeebCentralSource(this.puppeteerService));
    this.registerSource(new AtsumaruSource(this.puppeteerService));
    this.registerSource(new MangaFireSource(this.puppeteerService));
    this.registerSource(new BatCaveSource(this.puppeteerService));
  }

  registerSource(source: CatalogueSource) {
    this.sources.set(source.id, source);
  }

  getSources(): Source[] {
    return Array.from(this.sources.values()).map((s) => ({
      id: s.id,
      name: s.name,
      lang: s.lang,
      baseUrl: s.baseUrl,
      iconUrl: s.iconUrl,
      versionId: s.versionId,
    }));
  }

  getSource(id: string): CatalogueSource {
    const source = this.sources.get(id);
    if (!source) {
      throw new NotFoundException(`Source with ID ${id} not found`);
    }
    return source;
  }

  async getMangaList(
    sourceId: string,
    type: 'popular' | 'latest' | 'search',
    page: number,
    query?: string,
    filters?: any,
  ): Promise<MangasPage> {
    const source = this.getSource(sourceId);
    try {
      switch (type) {
        case 'popular':
          return source.getPopularManga(page);
        case 'latest':
          return source.getLatestUpdates(page);
        case 'search':
          return source.searchManga(page, query || '', filters);
        default:
          throw new Error('Invalid list type');
      }
    } catch (error) {
      const fallbackSourceId = 'mock_source';
      if (sourceId === fallbackSourceId) {
        throw error;
      }

      const fallbackSource = this.getSource(fallbackSourceId);
      switch (type) {
        case 'popular':
          return fallbackSource.getPopularManga(page);
        case 'latest':
          return fallbackSource.getLatestUpdates(page);
        case 'search':
          return fallbackSource.searchManga(page, query || '', filters);
        default:
          throw error;
      }
    }
  }

  async getMangaDetails(sourceId: string, mangaId: string): Promise<Manga> {
    const source = this.getSource(sourceId);
    return source.getMangaDetails(mangaId);
  }

  async getChapterList(sourceId: string, mangaId: string): Promise<Chapter[]> {
    const source = this.getSource(sourceId);
    return source.getChapterList(mangaId);
  }

  async getPageList(sourceId: string, chapterId: string): Promise<Page[]> {
    const source = this.getSource(sourceId);
    return source.getPageList(chapterId);
  }
}
