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

export class WeebCentralSource extends HttpSource {
  id = 'weebcentral';
  name = 'WeebCentral';
  baseUrl = 'https://weebcentral.com';
  lang = 'en';
  versionId = 1;
  iconUrl = '/images/weebcentral.png';

  constructor(private puppeteerService: PuppeteerService) {
    super();
  }

  // WeebCentral uses query params for sorting: /search/data?sort=Pop&page=1

  async getPopularManga(page: number): Promise<MangasPage> {
    try {
      const url = `${this.baseUrl}/search/data?sort=Popularity&author=&text=&series_type=All&series_status=All&year_from=&year_to=&tags=&no_tags=&order=Ascending&page=${page}`;

      // WeebCentral SPA: wait for main content container
      // If we wait for a specific link and it's empty, it times out.
      // Wait for 'main' or 'body' and then check content.
      const html = await this.puppeteerService.fetchPageContent(
        url,
        'section',
        5000,
      );

      if (
        html.includes('challenge-platform') ||
        html.includes('Verify you are human')
      ) {
        console.warn('WeebCentral: Cloudflare Challenge Detected');
        return { mangas: [], hasNextPage: false };
      }

      const response: AxiosResponse = {
        data: html,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      return this.popularMangaParse(response);
    } catch (error) {
      console.error(`WeebCentral popularManga error: ${error}`);
      return { mangas: [], hasNextPage: false };
    }
  }

  async getLatestUpdates(page: number): Promise<MangasPage> {
    try {
      const url = `${this.baseUrl}/search/data?sort=Latest Update&author=&text=&series_type=All&series_status=All&year_from=&year_to=&tags=&no_tags=&order=Ascending&page=${page}`;
      const html = await this.puppeteerService.fetchPageContent(
        url,
        'a[href*="/series/"]',
        2000,
      );

      const response: AxiosResponse = {
        data: html,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      return this.latestUpdatesParse(response);
    } catch (error) {
      console.error(`WeebCentral latestUpdates error: ${error}`);
      return { mangas: [], hasNextPage: false };
    }
  }

  async searchManga(
    page: number,
    query: string,
    filters: any,
  ): Promise<MangasPage> {
    try {
      const url = `${this.baseUrl}/search/data?text=${encodeURIComponent(query)}&sort=Best Match&author=&series_type=All&series_status=All&year_from=&year_to=&tags=&no_tags=&order=Ascending&page=${page}`;
      const html = await this.puppeteerService.fetchPageContent(
        url,
        'a[href*="/series/"]',
        2000,
      );

      const response: AxiosResponse = {
        data: html,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      return this.searchMangaParse(response);
    } catch (error) {
      console.error(`WeebCentral searchManga error: ${error}`);
      return { mangas: [], hasNextPage: false };
    }
  }

  async getMangaDetails(mangaId: string): Promise<Manga> {
    try {
      const url = `${this.baseUrl}/series/${mangaId}/`;
      const html = await this.puppeteerService.fetchPageContent(
        url,
        'h1',
        2000,
      );

      const response: AxiosResponse = {
        data: html,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      return this.mangaDetailsParse(response, mangaId);
    } catch (error) {
      console.error(`WeebCentral getMangaDetails error: ${error}`);
      throw error;
    }
  }

  async getChapterList(mangaId: string): Promise<Chapter[]> {
    try {
      const url = `${this.baseUrl}/series/${mangaId}/full-chapter-list`;
      const html = await this.puppeteerService.fetchPageContent(
        url,
        'a[href*="/chapters/"]',
        2000,
      );

      const response: AxiosResponse = {
        data: html,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      return this.chapterListParse(response);
    } catch (error) {
      console.error(`WeebCentral getChapterList error: ${error}`);
      throw error;
    }
  }

  async getPageList(chapterId: string): Promise<Page[]> {
    try {
      const url = `${this.baseUrl}/chapters/${chapterId}/images?is_prev=False&current_page=1&reading_style=long_strip`;
      // WeebCentral loads images dynamically. Wait for images to appear.
      const html = await this.puppeteerService.fetchPageContent(
        url,
        'img[src*="weebcentral.com"]',
        3000,
      );

      const response: AxiosResponse = {
        data: html,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      return this.pageListParse(response);
    } catch (error) {
      console.error(`WeebCentral getPageList error: ${error}`);
      throw error;
    }
  }

  popularMangaRequest(page: number): AxiosRequestConfig {
    throw new Error('Not implemented. Use getPopularManga');
  }

  popularMangaParse(response: AxiosResponse): MangasPage {
    const $ = cheerio.load(response.data);
    const mangas: Manga[] = [];

    // WeebCentral uses article tags or divs.
    // Usually a link to /series/ID is the best anchor.
    $('a[href*="/series/"]').each((_, element) => {
      const href = $(element).attr('href');
      // Skip if random link or no href
      if (!href || href.includes('/series/random')) return;

      const id = href.split('/').filter(Boolean).pop(); // Handle trailing slash
      if (!id) return;

      // Avoid duplicates
      if (mangas.some((m) => m.id === id)) return;

      // Find parent container to scope searches
      // Usually the link wraps the image or is next to it.
      // Strategy: Go up to finding a container that likely holds the whole card
      // OR look inside the element if the link wraps everything.

      let title = '';
      let thumbnail = '';

      // Check if link wraps image
      const img = $(element).find('img');
      if (img.length > 0) {
        thumbnail = img.attr('src') || img.attr('data-src') || '';
        // Title might be in alt or sibling
        title = img.attr('alt') || '';
      }

      // If title/thumb not found, try looking at siblings or parents
      if (!title || !thumbnail) {
        // Look for title in sibling elements if the link is just the image
        // Or if the link is the title itself
        const text = $(element).text().trim();
        if (text && text.length > 2 && !text.includes('Official')) {
          title = text;
        }
      }

      // Fallback: If we still don't have good data, try to be more specific with selectors based on observation
      // WeebCentral cards:
      // <article>
      //    <a href="/series/ID"> <img src="..." alt="Title" /> </a>
      //    <a href="/series/ID" class="...">Title</a>
      // </article>
      if (!thumbnail) {
        // Maybe this link is the text link, find the image link in the same container?
        // This is hard with generic scraping.
        // Let's rely on the image-containing link first.
        return;
      }

      // Clean title
      title = title.replace(/Official/gi, '').trim();

      if (title.length < 1 || !thumbnail) return;

      mangas.push({
        id,
        url: href,
        title: title || 'Unknown Title',
        thumbnailUrl: thumbnail,
        sourceId: this.id,
      });
    });

    return {
      mangas,
      hasNextPage:
        $('a:contains("Next")').length > 0 || $('a[rel="next"]').length > 0,
    };
  }

  latestUpdatesRequest(page: number): AxiosRequestConfig {
    throw new Error('Not implemented');
  }

  latestUpdatesParse(response: AxiosResponse): MangasPage {
    return this.popularMangaParse(response);
  }

  searchMangaRequest(
    page: number,
    query: string,
    filters: any,
  ): AxiosRequestConfig {
    throw new Error('Not implemented');
  }

  searchMangaParse(response: AxiosResponse): MangasPage {
    return this.popularMangaParse(response);
  }

  mangaDetailsRequest(mangaId: string): AxiosRequestConfig {
    throw new Error('Not implemented');
  }

  mangaDetailsParse(response: AxiosResponse, mangaId: string): Manga {
    const $ = cheerio.load(response.data);

    // Update selectors based on typical WeebCentral detail page
    // Often <h1 class="hidden md:block ...">Title</h1>
    // or just <h1>

    // WeebCentral puts info in a specific section
    const infoSection = $('section').first();

    const title = $('h1').first().text().trim();
    const thumbnail =
      $('img[alt="' + title + '"]').attr('src') ||
      $('img').first().attr('src') ||
      '';
    const description = $('p')
      .filter((i, el) => $(el).text().length > 50)
      .first()
      .text()
      .trim();

    // Author/Artist often in specific divs
    // Look for "Author" label
    const author = $('strong:contains("Author")')
      .parent()
      .text()
      .replace('Author', '')
      .trim();
    const status = $('strong:contains("Status")')
      .parent()
      .text()
      .replace('Status', '')
      .trim();

    const genres: string[] = [];
    $('a[href*="/search/data?tags="]').each((_, el) => {
      genres.push($(el).text().trim());
    });

    return {
      id: mangaId,
      url: `${this.baseUrl}/series/${mangaId}/`,
      title,
      thumbnailUrl: thumbnail,
      description,
      author,
      artist: '',
      status,
      genres,
      sourceId: this.id,
    };
  }

  chapterListRequest(mangaId: string): AxiosRequestConfig {
    throw new Error('Not implemented');
  }

  chapterListParse(response: AxiosResponse): Chapter[] {
    const $ = cheerio.load(response.data);
    const chapters: Chapter[] = [];

    // WeebCentral full chapter list usually has links to /chapters/ID
    $('a[href*="/chapters/"]').each((_, element) => {
      const url = $(element).attr('href');
      if (!url) return;

      const id = url.split('/').filter(Boolean).pop(); // Extract chapter ID

      // The text inside the link usually contains "Chapter X" or similar
      const name =
        $(element).find('span.grow').text().trim() || $(element).text().trim();

      // Date often in a sibling span or inside
      const dateStr = $(element).find('time').text().trim() || '';

      chapters.push({
        id: id || '',
        url,
        name: name,
        chapterNumber: this.parseChapterNumber(name),
        dateUpload: this.parseDate(dateStr),
      });
    });

    return chapters;
  }

  pageListRequest(chapterId: string): AxiosRequestConfig {
    throw new Error('Not implemented');
  }

  pageListParse(response: AxiosResponse): Page[] {
    const $ = cheerio.load(response.data);
    const pages: Page[] = [];

    $('img[src*="weebcentral.com"]').each((index, element) => {
      const url = $(element).attr('src');
      if (url && !url.includes('logo')) {
        pages.push({
          index,
          imageUrl: url,
          url: '',
        });
      }
    });

    return pages;
  }

  private parseChapterNumber(name: string): number {
    const match =
      name.match(/Chapter\s+(\d+(\.\d+)?)/i) || name.match(/(\d+(\.\d+)?)/);
    return match ? parseFloat(match[1]) : 0;
  }

  private parseDate(dateStr: string): number {
    return new Date(dateStr).getTime() || Date.now();
  }
}
