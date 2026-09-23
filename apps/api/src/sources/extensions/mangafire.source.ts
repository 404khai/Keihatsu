import * as cheerio from 'cheerio';
import { HttpSource } from '../core/http-source.abstract';
import { PuppeteerService } from '../core/puppeteer.service';
import { Manga, Chapter, Page, MangasPage } from '../interfaces/manga.interface';

/** MangaFire renders its catalogue in the browser and signs its JSON requests. */
export class MangaFireSource extends HttpSource {
  id = 'mangafire';
  name = 'MangaFire';
  baseUrl = 'https://mangafire.to';
  lang = 'en';
  versionId = 2;
  iconUrl = '/images/mangafire.png';

  constructor(private readonly browser: PuppeteerService) { super(); }

  private async listing(page: number, sort: string, query?: string): Promise<MangasPage> {
    const params = new URLSearchParams({ sort, page: String(page) });
    if (query) params.set('keyword', query);
    const html = await this.browser.fetchPageContent(`${this.baseUrl}/browse?${params}`, '.title-row-card');
    const $ = cheerio.load(html);
    const mangas: Manga[] = [];
    $('a[href^="/title/"]').each((_, element) => {
      const href = $(element).attr('href') ?? '';
      if (href.includes('/chapter/')) return;
      const id = href.split('/')[2];
      const card = $(element).find('.title-row-card');
      const title = card.find('.title-row-card__title').text().trim();
      const thumbnailUrl = card.find('img').attr('src') ?? '';
      if (id && title && thumbnailUrl && !mangas.some((item) => item.id === id)) {
        mangas.push({ id, url: `${this.baseUrl}${href}`, title, thumbnailUrl, sourceId: this.id });
      }
    });
    if (!mangas.length) throw new Error('MangaFire returned no catalogue cards');
    return { mangas, hasNextPage: mangas.length >= 30 };
  }

  getPopularManga(page: number): Promise<MangasPage> {
    return this.listing(page, 'views_total:desc');
  }

  getLatestUpdates(page: number): Promise<MangasPage> {
    return this.listing(page, 'chapter_updated_at:desc');
  }

  searchManga(page: number, query: string): Promise<MangasPage> {
    return this.listing(page, 'relevance:desc', query);
  }

  private async detailHTML(mangaId: string): Promise<string> {
    return this.browser.fetchPageContent(`${this.baseUrl}/title/${mangaId}`, '.title-detail__title');
  }

  async getMangaDetails(mangaId: string): Promise<Manga> {
    const $ = cheerio.load(await this.detailHTML(mangaId));
    const title = $('.title-detail__title').first().text().trim();
    if (!title) throw new Error(`MangaFire returned no manga for ${mangaId}`);
    return {
      id: mangaId,
      url: `${this.baseUrl}/title/${mangaId}`,
      title,
      thumbnailUrl: $('.title-detail__poster img').first().attr('src') ?? '',
      description: $('.title-detail__synopsis').first().text().trim(),
      sourceId: this.id,
    };
  }

  async getChapterList(mangaId: string): Promise<Chapter[]> {
    const titleID = mangaId.split('-')[0];
    const pages = await this.browser.fetchPaginatedJSONResponses<{
      items: { id: number; number: number; name: string; createdAt: number }[];
      meta: { page: number; hasNext: boolean };
    }>(
      `${this.baseUrl}/title/${mangaId}`,
      `/api/titles/${titleID}/chapters`,
      '.npager__nav[aria-label="Next page"]',
    );
    const chapters: Chapter[] = pages.flatMap((page) => page.items.map((item) => {
      const id = `${mangaId}/chapter/${item.id}`;
      return {
        id, url: `${this.baseUrl}/title/${id}`,
        name: `Chapter ${item.number}${item.name ? `: ${item.name}` : ''}`,
        chapterNumber: item.number,
        dateUpload: item.createdAt * 1_000,
      };
    }));
    if (!chapters.length) throw new Error(`MangaFire returned no chapters for ${mangaId}`);
    return chapters;
  }

  async getPageList(chapterId: string): Promise<Page[]> {
    const match = chapterId.match(/^([^/]+)\/chapter\/(\d+)$/);
    if (!match) throw new Error('Invalid MangaFire chapter ID');
    const url = `${this.baseUrl}/title/${chapterId}`;
    const response = await this.browser.fetchJSONResponse<{ data?: { pages?: { url: string }[] } }>(
      url, `/api/chapters/${match[2]}`,
    );
    const pages = response.data?.pages;
    if (!pages?.length) throw new Error(`MangaFire returned no pages for ${chapterId}`);
    return pages.map((page, index) => ({ index, imageUrl: page.url, url }));
  }

  // HttpSource's request/parse hooks are unused by the browser-backed source.
  popularMangaRequest(): never { throw new Error('Use getPopularManga'); }
  popularMangaParse(): never { throw new Error('Use getPopularManga'); }
  latestUpdatesRequest(): never { throw new Error('Use getLatestUpdates'); }
  latestUpdatesParse(): never { throw new Error('Use getLatestUpdates'); }
  searchMangaRequest(): never { throw new Error('Use searchManga'); }
  searchMangaParse(): never { throw new Error('Use searchManga'); }
  mangaDetailsRequest(): never { throw new Error('Use getMangaDetails'); }
  mangaDetailsParse(): never { throw new Error('Use getMangaDetails'); }
  chapterListRequest(): never { throw new Error('Use getChapterList'); }
  chapterListParse(): never { throw new Error('Use getChapterList'); }
  pageListRequest(): never { throw new Error('Use getPageList'); }
  pageListParse(): never { throw new Error('Use getPageList'); }
}
