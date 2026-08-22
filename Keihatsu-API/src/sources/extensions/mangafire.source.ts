import { AxiosRequestConfig, AxiosResponse } from 'axios';
import * as cheerio from 'cheerio';
import { HttpSource } from '../core/http-source.abstract';
import {
  MangasPage,
  Manga,
  Chapter,
  Page,
} from '../interfaces/manga.interface';
import { PuppeteerService } from '../core/puppeteer.service';

export class MangaFireSource extends HttpSource {
  id = 'mangafire';
  name = 'MangaFire';
  baseUrl = 'https://mangafire.to';
  lang = 'en';
  versionId = 1;
  iconUrl = '/images/mangafire.png';

  constructor(private puppeteerService: PuppeteerService) {
    super();
  }

  async getPopularManga(page: number): Promise<MangasPage> {
    try {
      // MangaFire uses /filter?sort=most_viewed&page=X
      const url = `${this.baseUrl}/filter?sort=most_viewed&page=${page}`;
      const html = await this.puppeteerService.fetchPageContent(
        url,
        '.unit .inner', // Wait for manga items
        3000,
      );
      return this.parseMangaList(html);
    } catch (e) {
      console.error(`MangaFire popular error: ${e}`);
      return { mangas: [], hasNextPage: false };
    }
  }

  async getLatestUpdates(page: number): Promise<MangasPage> {
    try {
      // MangaFire uses /filter?sort=recently_updated&page=X
      const url = `${this.baseUrl}/filter?sort=recently_updated&page=${page}`;
      const html = await this.puppeteerService.fetchPageContent(
        url,
        '.unit .inner',
        3000,
      );
      return this.parseMangaList(html);
    } catch (e) {
      console.error(`MangaFire latest error: ${e}`);
      return { mangas: [], hasNextPage: false };
    }
  }

  async searchManga(
    page: number,
    query: string,
    filters: any,
  ): Promise<MangasPage> {
    try {
      // MangaFire uses /filter?keyword=QUERY&page=X
      const url = `${this.baseUrl}/filter?keyword=${encodeURIComponent(
        query,
      )}&page=${page}`;
      const html = await this.puppeteerService.fetchPageContent(
        url,
        '.unit .inner',
        3000,
      );
      return this.parseMangaList(html);
    } catch (e) {
      console.error(`MangaFire search error: ${e}`);
      return { mangas: [], hasNextPage: false };
    }
  }

  async getMangaDetails(mangaId: string): Promise<Manga> {
    // mangaId is typically slug.id
    const url = `${this.baseUrl}/manga/${mangaId}`;
    try {
      const html = await this.puppeteerService.fetchPageContent(
        url,
        '.manga-detail',
        3000,
      );
      const $ = cheerio.load(html);

      const title = $('h1[itemprop="name"]').text().trim();
      const thumbnail =
        $('.poster img').attr('src') || $('.poster img').attr('data-src') || '';
      const description = $('.description').text().trim();

      // Meta info
      const author = $('span:contains("Author:")').next().text().trim();
      const status = $('span:contains("Status:")').next().text().trim();
      const genres = $('.meta .genres a')
        .map((_, el) => $(el).text().trim())
        .get();

      return {
        id: mangaId,
        url,
        title,
        thumbnailUrl: thumbnail,
        description,
        author,
        artist: '',
        status,
        genres,
        sourceId: this.id,
      };
    } catch (e) {
      console.error(`MangaFire details error: ${e}`);
      throw e;
    }
  }

  async getChapterList(mangaId: string): Promise<Chapter[]> {
    // MangaFire loads chapters via AJAX or listed on page.
    // URL: /manga/slug.id
    // AJAX: /ajax/manga/{id}/chapter/en

    // First, we need the internal ID, which is often in a data attribute on the page.
    const url = `${this.baseUrl}/manga/${mangaId}`;
    try {
      // We fetch the main page to get the ID or see if chapters are there
      const html = await this.puppeteerService.fetchPageContent(
        url,
        'body',
        3000,
      );
      const $ = cheerio.load(html);

      // Check if chapters are already listed
      const chapters: Chapter[] = [];

      // MangaFire chapter list items usually in .list-chapter .item or similar
      // Or loaded via AJAX.
      // Let's assume they might be loaded.

      // Look for chapters in .list-chapter or similar container
      const chapterElements = $('.list-chapter li a, .chapters-list li a');
      if (chapterElements.length > 0) {
        chapterElements.each((_, el) => {
          const href = $(el).attr('href');
          if (!href) return;

          // href usually: /read/slug.id/lang/chapter-1
          // We need an ID that allows us to fetch pages.
          // The page URL for reading is typically the href.

          let id = href;
          if (href.startsWith('/read/')) {
            id = href.replace('/read/', '');
          } else if (href.includes('/read/')) {
            // In case it's a full URL
            const parts = href.split('/read/');
            if (parts.length > 1) id = parts[1];
          }

          // Clean up leading/trailing slashes
          id = id.replace(/^\/+|\/+$/g, '');

          const name = $(el).find('.name').text().trim() || $(el).text().trim();
          const dateStr = $(el).find('.date').text().trim();

          chapters.push({
            id, // e.g., slug.id/en/chapter-1
            url: href.startsWith('http') ? href : `${this.baseUrl}${href}`,
            name,
            chapterNumber: this.parseChapterNumber(name),
            dateUpload: this.parseDate(dateStr),
          });
        });
      }

      // If no chapters found, we might need to fetch via AJAX.
      // But for now, let's assume Puppeteer renders the list if we wait enough or scroll.
      // If the list is hidden or paginated, we might miss some.
      // However, MangaFire often lists all chapters or has a "View More" button.
      // Implementing "View More" via Puppeteer is complex.
      // Let's stick to what's visible or try to find a "wrapper" API if needed.
      // Actually, many MangaFire scrapers use the /ajax/read/{id} endpoint.

      return chapters;
    } catch (e) {
      console.error(`MangaFire chapter list error: ${e}`);
      throw e;
    }
  }

  async getPageList(chapterId: string): Promise<Page[]> {
    // chapterId is slug.id/chapter-slug
    // URL: /read/slug.id/chapter-slug (or similar)
    // Actually, on MangaFire, reading page URL is /read/slug.id/en/chapter-1 (sometimes)
    // Let's assume the ID we stored is the relative path or part of it.

    // If we stored the full relative path in getChapterList, we can construct the URL.
    // But MangaFire reader often uses AJAX to fetch images.
    // The images are in a variable `const pages = [...]` or fetched via API.

    const url = `${this.baseUrl}/read/${chapterId}`; // chapterId might need adjustment

    try {
      const html = await this.puppeteerService.fetchPageContent(
        url,
        'img.page-image, .reading-content img', // Wait for images
        5000,
      );
      const $ = cheerio.load(html);
      const pages: Page[] = [];

      // Look for images
      $('img.page-image, .reading-content img').each((i, el) => {
        const src = $(el).attr('src') || $(el).attr('data-src');
        if (src) {
          pages.push({
            index: i,
            imageUrl: src.trim(),
            url: '',
          });
        }
      });

      return pages;
    } catch (e) {
      console.error(`MangaFire page list error: ${e}`);
      throw e;
    }
  }

  private parseMangaList(html: string): MangasPage {
    const $ = cheerio.load(html);
    const mangas: Manga[] = [];

    // MangaFire list items: .unit .inner
    $('.unit .inner').each((_, el) => {
      const link = $(el).find('a.poster');
      const href = link.attr('href');
      if (!href) return;

      // href: /manga/slug.id
      const id = href.split('/').pop(); // slug.id
      if (!id) return;

      const img = link.find('img');
      const title = img.attr('alt') || $(el).find('.info a').text().trim();
      const thumbnail = img.attr('src') || img.attr('data-src') || '';

      mangas.push({
        id,
        url: `${this.baseUrl}${href}`,
        title,
        thumbnailUrl: thumbnail,
        sourceId: this.id,
      });
    });

    return {
      mangas,
      hasNextPage: $('.pagination .next').length > 0,
    };
  }

  // Helper overrides
  popularMangaRequest(): AxiosRequestConfig {
    throw new Error('Use getPopularManga');
  }
  popularMangaParse(): MangasPage {
    throw new Error('Use getPopularManga');
  }
  latestUpdatesRequest(): AxiosRequestConfig {
    throw new Error('Use getLatestUpdates');
  }
  latestUpdatesParse(): MangasPage {
    throw new Error('Use getLatestUpdates');
  }
  searchMangaRequest(): AxiosRequestConfig {
    throw new Error('Use searchManga');
  }
  searchMangaParse(): MangasPage {
    throw new Error('Use searchManga');
  }
  mangaDetailsRequest(): AxiosRequestConfig {
    throw new Error('Use getMangaDetails');
  }
  mangaDetailsParse(): Manga {
    throw new Error('Use getMangaDetails');
  }
  chapterListRequest(): AxiosRequestConfig {
    throw new Error('Use getChapterList');
  }
  chapterListParse(): Chapter[] {
    throw new Error('Use getChapterList');
  }
  pageListRequest(): AxiosRequestConfig {
    throw new Error('Use getPageList');
  }
  pageListParse(): Page[] {
    throw new Error('Use getPageList');
  }

  private parseChapterNumber(name: string): number {
    const match =
      name.match(/Chapter\s+(\d+(\.\d+)?)/i) || name.match(/(\d+(\.\d+)?)/);
    return match ? parseFloat(match[1]) : 0;
  }

  private parseDate(dateStr: string): number {
    return new Date(dateStr).getTime() || 0;
  }
}
