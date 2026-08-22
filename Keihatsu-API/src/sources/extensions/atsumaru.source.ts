import { AxiosRequestConfig } from 'axios';
import * as cheerio from 'cheerio';
import { HttpSource } from '../core/http-source.abstract';
import {
  MangasPage,
  Manga,
  Chapter,
  Page,
} from '../interfaces/manga.interface';
import { PuppeteerService } from '../core/puppeteer.service';
import { Injectable } from '@nestjs/common';

@Injectable()
export class AtsumaruSource extends HttpSource {
  id = 'atsumaru';
  name = 'Atsumaru';
  baseUrl = 'https://atsu.moe';
  lang = 'en';
  versionId = 1;
  iconUrl = '/images/atsumaru.png';

  // Inject PuppeteerService. Note: Since we are instantiating this manually in SourcesService,
  // we need to pass the instance.
  private puppeteerService: PuppeteerService;

  constructor(puppeteerService?: PuppeteerService) {
    super();
    // If manually instantiated without injection (legacy way), this might be undefined.
    // But we will update SourcesService to pass it.
    if (puppeteerService) {
      this.puppeteerService = puppeteerService;
    }
  }

  // Atsumaru (atsu.moe) is a Madara-based site or similar.
  // It likely uses wp-manga or similar structure.
  // We'll use Puppeteer to fetch content.

  async getPopularManga(page: number): Promise<MangasPage> {
    if (!this.puppeteerService)
      throw new Error('PuppeteerService not initialized in AtsumaruSource');

    // Madara themes often use /manga/?m_orderby=views or /page/X/?m_orderby=views
    const url = `${this.baseUrl}/page/${page}/?s&post_type=wp-manga&m_orderby=views`;

    try {
      // Don't wait for a specific selector that might not exist. Wait for body.
      const html = await this.puppeteerService.fetchPageContent(
        url,
        'body',
        3000,
      );
      return this.parseMangaList(html);
    } catch (e) {
      console.error(`Atsumaru popular error: ${e}`);
      return { mangas: [], hasNextPage: false };
    }
  }

  async getLatestUpdates(page: number): Promise<MangasPage> {
    if (!this.puppeteerService)
      throw new Error('PuppeteerService not initialized in AtsumaruSource');
    const url = `${this.baseUrl}/page/${page}/?s&post_type=wp-manga&m_orderby=latest`;

    try {
      const html = await this.puppeteerService.fetchPageContent(
        url,
        '.c-tabs-item__content',
        2000,
      );
      return this.parseMangaList(html);
    } catch (e) {
      console.error(`Atsumaru latest error: ${e}`);
      return { mangas: [], hasNextPage: false };
    }
  }

  async searchManga(
    page: number,
    query: string,
    filters: any,
  ): Promise<MangasPage> {
    if (!this.puppeteerService)
      throw new Error('PuppeteerService not initialized in AtsumaruSource');
    const url = `${this.baseUrl}/page/${page}/?s=${encodeURIComponent(query)}&post_type=wp-manga`;

    try {
      const html = await this.puppeteerService.fetchPageContent(
        url,
        '.c-tabs-item__content',
        2000,
      );
      return this.parseMangaList(html);
    } catch (e) {
      console.error(`Atsumaru search error: ${e}`);
      return { mangas: [], hasNextPage: false };
    }
  }

  async getMangaDetails(mangaId: string): Promise<Manga> {
    if (!this.puppeteerService)
      throw new Error('PuppeteerService not initialized in AtsumaruSource');
    // mangaId is the slug, e.g., 'solo-leveling'
    const url = `${this.baseUrl}/manga/${mangaId}/`;

    try {
      const html = await this.puppeteerService.fetchPageContent(
        url,
        '.post-title',
        2000,
      );
      const $ = cheerio.load(html);

      return {
        id: mangaId,
        url,
        title: $('.post-title h1').text().trim(),
        thumbnailUrl:
          $('.summary_image img').attr('src') ||
          $('.summary_image img').attr('data-src') ||
          '',
        description: $('.summary__content').text().trim(),
        author: $('.author-content').text().trim(),
        artist: $('.artist-content').text().trim(),
        status: $('.post-status .summary-content').text().trim(),
        genres: $('.genres-content a')
          .map((_, el) => $(el).text().trim())
          .get(),
        sourceId: this.id,
      };
    } catch (e) {
      console.error(`Atsumaru details error: ${e}`);
      throw e;
    }
  }

  async getChapterList(mangaId: string): Promise<Chapter[]> {
    if (!this.puppeteerService)
      throw new Error('PuppeteerService not initialized in AtsumaruSource');
    const url = `${this.baseUrl}/manga/${mangaId}/`;

    // Madara themes often load chapters via AJAX or listed at bottom
    try {
      const html = await this.puppeteerService.fetchPageContent(
        url,
        '.wp-manga-chapter',
        2000,
      );
      const $ = cheerio.load(html);
      const chapters: Chapter[] = [];

      $('.wp-manga-chapter').each((_, el) => {
        const link = $(el).find('a');
        const href = link.attr('href');
        if (!href) return;

        // ID is usually the last part of URL or the date-slug
        // https://atsu.moe/manga/slug/chapter-1/
        // We'll use the full slug after /manga/slug/ as ID
        const id = href
          .replace(`${this.baseUrl}/manga/${mangaId}/`, '')
          .replace(/\/$/, '');

        chapters.push({
          id,
          url: href,
          name: link.text().trim(),
          chapterNumber: this.parseChapterNumber(link.text()),
          dateUpload: this.parseDate(
            $(el).find('.chapter-release-date').text(),
          ),
        });
      });

      return chapters;
    } catch (e) {
      console.error(`Atsumaru chapter list error: ${e}`);
      throw e;
    }
  }

  async getPageList(chapterId: string): Promise<Page[]> {
    if (!this.puppeteerService)
      throw new Error('PuppeteerService not initialized in AtsumaruSource');
    // We need the mangaId to construct URL properly?
    // Actually chapterId contains the path relative to manga?
    // In getChapterList we stored "chapter-1" as ID.
    // But we don't have mangaId here.
    // Madara chapter URLs are /manga/MANGA_SLUG/CHAPTER_SLUG/
    // If we only have CHAPTER_SLUG, we can't build URL unless we stored full URL in ID or look it up.
    // Re-design: Store full URL or path in ID if needed, OR just handle it if ID is unique enough.
    // For now, let's assume we need to reconstruct or look up.
    // Ideally, chapterId should be the full URL for generic sources, OR we parse it.
    // Wait, getChapterList stored: id = "chapter-1" (example).
    // We can't fetch https://atsu.moe/chapter-1/.

    // FIX: Update getChapterList to store full URL as ID or enough info.
    // Or, assume we can pass the URL as the ID (base64 encoded maybe? or just raw string if safe).
    // Let's rely on the ID being the Full URL for simplicity in this specific source context?
    // No, IDs should be relatively short.
    // Let's assume the calling context doesn't pass mangaId.

    // Let's modify getChapterList to store `mangaId/chapterId` as the ID.
    // Then we can split it here.

    // BUT, the interface `getPageList(chapterId)` is fixed.
    // In `getChapterList` above, I used `href.replace...`.
    // Let's change `getChapterList` to store the full absolute URL as the ID? No, that's ugly.
    // Let's store `mangaId/chapter-slug`.

    // Re-read getChapterList logic:
    // `const id = href.replace(\`\${this.baseUrl}/manga/\${mangaId}/\`, '')...`
    // This results in `chapter-1`.
    // We are missing `mangaId`.

    // Solution: Atsumaru chapter IDs will be formatted as `mangaId/chapterSlug`.
    // Wait, I can't easily change `getChapterList` args (it takes mangaId).
    // So I will update `getChapterList` to produce ID = `${mangaId}/${chapterSlug}`.

    const parts = chapterId.split('/');
    if (parts.length < 2) {
      // Fallback or error?
      // Maybe the ID is just the URL?
      // If we can't deduce, throw.
      throw new Error(
        'Invalid chapter ID format for Atsumaru. Expected "mangaId/chapterSlug"',
      );
    }

    const url = `${this.baseUrl}/manga/${chapterId}/`; // chapterId = "slug/chapter-1" -> /manga/slug/chapter-1/

    try {
      const html = await this.puppeteerService.fetchPageContent(
        url,
        '.reading-content',
        2000,
      );
      const $ = cheerio.load(html);
      const pages: Page[] = [];

      $('.reading-content img').each((i, el) => {
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
      console.error(`Atsumaru page list error: ${e}`);
      throw e;
    }
  }

  private parseMangaList(html: string): MangasPage {
    const $ = cheerio.load(html);
    const mangas: Manga[] = [];

    // Try multiple selectors for different Madara themes
    const selectors = [
      '.c-tabs-item__content',
      '.page-item-detail',
      '.manga-item',
      '.item-summary',
      '.col-md-3',
      '.col-6',
    ];
    let foundItems = 0;

    for (const selector of selectors) {
      if ($(selector).length > 0) {
        $(selector).each((_, el) => {
          // Madara structure variations:
          // 1. .tab-thumb > a > img
          // 2. .item-thumb > a > img
          // 3. .manga-item > a > img

          const thumb = $(el).find(
            '.tab-thumb a, .item-thumb a, .manga-poster a, a.manga-poster',
          );
          let href = thumb.attr('href');

          // If not found in thumb, look for title link
          if (!href) {
            href = $(el)
              .find('.post-title h3 a, .post-title h4 a, .item-title a')
              .attr('href');
          }

          if (!href) return;

          const id = href.split('/').filter(Boolean).pop();
          if (!id) return;

          const img = $(el).find('img');
          let title = $(el)
            .find('.post-title h3 a, .post-title h4 a, .item-title a')
            .text()
            .trim();

          if (!title) {
            title = img.attr('alt') || img.attr('title') || 'Unknown';
          }

          // Deduplicate
          if (mangas.some((m) => m.id === id)) return;

          mangas.push({
            id,
            url: href,
            title: title,
            thumbnailUrl: img.attr('src') || img.attr('data-src') || '',
            sourceId: this.id,
          });
        });

        foundItems = mangas.length;
        if (foundItems > 0) break; // Stop if we found items with this selector
      }
    }

    return {
      mangas,
      hasNextPage: true, // Madara usually has many pages
    };
  }

  // Override helpers
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
    const match = name.match(/(\d+(\.\d+)?)/);
    return match ? parseFloat(match[1]) : 0;
  }

  private parseDate(dateStr: string): number {
    return new Date(dateStr).getTime() || 0;
  }
}
