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

export class ManhuaTopSource extends HttpSource {
  id = 'manhuatop';
  name = 'ManhuaTop';
  baseUrl = 'https://manhuatop.org';
  lang = 'en';
  versionId = 1;
  iconUrl = '/images/manhuatop.jpeg';

  constructor(private puppeteerService: PuppeteerService) {
    super();
  }

  // Override to handle errors
  async getPopularManga(page: number): Promise<MangasPage> {
    try {
      const url = `${this.baseUrl}/manga/?m_orderby=views&page=${page}`;
      // Use Puppeteer to bypass Cloudflare
      const html = await this.puppeteerService.fetchPageContent(
        url,
        '.page-item-detail',
      );

      // Create a mock AxiosResponse for parsing logic reuse
      const response: AxiosResponse = {
        data: html,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      return this.popularMangaParse(response);
    } catch (error) {
      console.error(`ManhuaTop popularManga error: ${error}`);
      return { mangas: [], hasNextPage: false };
    }
  }

  async getLatestUpdates(page: number): Promise<MangasPage> {
    try {
      const url = `${this.baseUrl}/manga/?m_orderby=latest&page=${page}`;
      const html = await this.puppeteerService.fetchPageContent(
        url,
        '.page-item-detail',
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
      console.error(`ManhuaTop latestUpdates error: ${error}`);
      return { mangas: [], hasNextPage: false };
    }
  }

  async searchManga(
    page: number,
    query: string,
    filters: any,
  ): Promise<MangasPage> {
    try {
      const url = `${this.baseUrl}/page/${page}/?s=${encodeURIComponent(query)}&post_type=wp-manga`;
      const html = await this.puppeteerService.fetchPageContent(
        url,
        '.c-tabs-item__content',
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
      console.error(`ManhuaTop searchManga error: ${error}`);
      return { mangas: [], hasNextPage: false };
    }
  }

  async getMangaDetails(mangaId: string): Promise<Manga> {
    const normalizedId = this.normalizeMangaId(mangaId);
    const url = `${this.baseUrl}/manhua/${encodeURIComponent(normalizedId)}/`;
    const html = await this.puppeteerService.fetchPageContent(
      url,
      '.post-title',
    );

    const response: AxiosResponse = {
      data: html,
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {} as any,
    };

    const manga = this.mangaDetailsParse(response, normalizedId);
    if (!manga.title || !manga.thumbnailUrl) {
      throw new Error(`ManhuaTop returned incomplete details for ${normalizedId}`);
    }
    return manga;
  }

  async getChapterList(mangaId: string): Promise<Chapter[]> {
    // 1. Try fetching from the main manga page first
    const normalizedId = this.normalizeMangaId(mangaId);
    const url = `${this.baseUrl}/manhua/${encodeURIComponent(normalizedId)}/`;
    let html: string | undefined;

    try {
      // We set a shorter timeout for the selector because if it's not there, it's likely hidden behind AJAX
      html = await this.puppeteerService.fetchPageContent(
        url,
        '.wp-manga-chapter',
      );

      const response: AxiosResponse = {
        data: html,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      const chapters = this.chapterListParse(response);

      // If we found chapters, return them
      if (chapters.length > 0) {
        return chapters;
      }
    } catch (e) {
      console.warn(
        `ManhuaTop: Failed to fetch chapters from main page for ${mangaId}, trying AJAX fallback.`,
      );
    }

    // 2. Fallback: Try Madara AJAX endpoint
    // Madara themes often load chapters via POST /wp-admin/admin-ajax.php
    return this.fetchChaptersViaAjax(normalizedId, html);
  }

  private async fetchChaptersViaAjax(
    mangaId: string,
    mainPageHtml?: string,
  ): Promise<Chapter[]> {
    try {
      const ajaxUrl = `${this.baseUrl}/wp-admin/admin-ajax.php`;

      // We need the numeric ID of the manga for the AJAX call.
      // Often this is embedded in the page as "manga_id" or similar, but let's try to scrape it or guess it.
      // Actually, Madara AJAX usually expects 'action': 'manga_get_chapters' and 'manga': numeric_id.
      // Getting the numeric ID might require parsing the main page source again if we don't have it.

      // Alternative: Some Madara versions allow passing the slug or have a specific endpoint.
      // Let's try to fetch the main page again (lightweight) to find the numeric ID if we can.
      // But Puppeteer is heavy.

      // Let's try a direct POST with axios first (faster) if we can find the ID.
      // If we can't easily get the numeric ID, we might need to rely on Puppeteer to click "Show More" or similar.

      // Strategy B: Puppeteer Click
      // Since we are using Puppeteer, we can instruct it to click the "ajax" button if it exists.
      // But 'fetchPageContent' returns a string. We might need a new method in PuppeteerService to "interact".

      // Let's stick to the Plan: "POST request to /wp-admin/admin-ajax.php".
      // To do this, we need the internal WP ID.
      // Let's parse the main page HTML (which we might have cached or just fetched) to find <input type="hidden" name="manga-id" value="123">

      const html =
        mainPageHtml ??
        (await this.puppeteerService.fetchPageContent(
          `${this.baseUrl}/manhua/${encodeURIComponent(mangaId)}/`,
        ));
      const $ = cheerio.load(html);

      // Common selector for Madara internal ID
      let internalId =
        $('input[name="wp-manga-id"]').val() ||
        $('#manga-chapters-holder').attr('data-id');

      // Sometimes it's in a script tag "var manga_id = 123;"
      if (!internalId) {
        const match = html.match(/manga_id\s*=\s*(\d+)/);
        if (match) internalId = match[1];
      }

      if (!internalId) {
        console.error(
          `ManhuaTop: Could not find internal manga ID for ${mangaId}`,
        );
        return [];
      }

      // Now perform the AJAX request using Axios (since it's an API call, Puppeteer might be overkill, but Cloudflare might block Axios)
      // If Cloudflare is active, we MUST use Puppeteer to fetch this too, or use the cookies from Puppeteer.
      // For simplicity in this codebase, let's try Axios first. If it fails, we might need to enhance PuppeteerService to support POST.
      // Actually, PuppeteerService only does GET. Let's try Axios with standard headers.

      const formData = new URLSearchParams();
      formData.append('action', 'manga_get_chapters');
      formData.append('manga', internalId.toString());

      const response = await this.client.post(ajaxUrl, formData, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'X-Requested-With': 'XMLHttpRequest',
          Referer: `${this.baseUrl}/manhua/${encodeURIComponent(mangaId)}/`,
        },
      });

      return this.chapterListParse(response);
    } catch (error) {
      console.error(`ManhuaTop: AJAX chapter fetch failed: ${error}`);
      return [];
    }
  }

  async getPageList(chapterId: string): Promise<Page[]> {
    // chapterId might be full path relative or absolute
    let url = chapterId.startsWith('http')
      ? chapterId
      : `${this.baseUrl}/${chapterId}/`;

    // Force single page mode if possible (Madara standard)
    if (!url.includes('?style=list')) {
      url += '?style=list';
    }

    // Try a broader selector, sometimes .reading-content img is too specific or nested
    // .reading-content is the main container
    // Wait for images specifically to ensure lazy loading is triggered or at least DOM is ready
    const html = await this.puppeteerService.fetchPageContent(
      url,
      '.reading-content img',
      5000,
    );

    const response: AxiosResponse = {
      data: html,
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {} as any,
    };

    return this.pageListParse(response);
  }

  popularMangaRequest(page: number): AxiosRequestConfig {
    return {
      url: `${this.baseUrl}/manga/`,
      method: 'GET',
      params: {
        m_orderby: 'views',
        page: page,
      },
    };
  }

  popularMangaParse(response: AxiosResponse): MangasPage {
    const $ = cheerio.load(response.data);
    const mangas: Manga[] = [];

    $('.page-item-detail').each((_, element) => {
      try {
        const url = this.makeAbsoluteUrl(
          $(element).find('.post-title a').attr('href') || '',
        );
        const id = this.urlToId(url);

        if (!id) return;

        mangas.push({
          id,
          url,
          title: $(element).find('.post-title a').text().trim(),
          thumbnailUrl: this.makeAbsoluteUrl(
            $(element).find('img').attr('data-src') ||
              $(element).find('img').attr('src') ||
              '',
          ),
          sourceId: this.id,
        });
      } catch (e) {
        console.warn(`Failed to parse manga item in ManhuaTop: ${e}`);
      }
    });

    return {
      mangas,
      hasNextPage: $('.nav-previous, .next').length > 0,
    };
  }

  latestUpdatesRequest(page: number): AxiosRequestConfig {
    return {
      url: `${this.baseUrl}/manga/`,
      method: 'GET',
      params: {
        m_orderby: 'latest',
        page: page,
      },
    };
  }

  latestUpdatesParse(response: AxiosResponse): MangasPage {
    return this.popularMangaParse(response);
  }

  searchMangaRequest(
    page: number,
    query: string,
    filters: any,
  ): AxiosRequestConfig {
    return {
      url: `${this.baseUrl}/page/${page}/`,
      method: 'GET',
      params: {
        s: query,
        post_type: 'wp-manga',
      },
    };
  }

  searchMangaParse(response: AxiosResponse): MangasPage {
    const $ = cheerio.load(response.data);
    const mangas: Manga[] = [];

    $('.c-tabs-item__content').each((_, element) => {
      try {
        const url = this.makeAbsoluteUrl(
          $(element).find('.post-title a').attr('href') || '',
        );
        const id = this.urlToId(url);

        if (!id) return;

        mangas.push({
          id,
          url,
          title: $(element).find('.post-title a').text().trim(),
          thumbnailUrl: this.makeAbsoluteUrl(
            $(element).find('img').attr('data-src') ||
              $(element).find('img').attr('src') ||
              '',
          ),
          sourceId: this.id,
        });
      } catch (e) {
        console.warn(`Failed to parse search item in ManhuaTop: ${e}`);
      }
    });

    return {
      mangas,
      hasNextPage: $('.nav-previous, .next').length > 0,
    };
  }

  mangaDetailsRequest(mangaId: string): AxiosRequestConfig {
    return {
      url: `${this.baseUrl}/manhua/${encodeURIComponent(this.normalizeMangaId(mangaId))}/`,
      method: 'GET',
    };
  }

  mangaDetailsParse(response: AxiosResponse, mangaId: string): Manga {
    const $ = cheerio.load(response.data);
    const descriptionParagraphs = $('.summary__content p')
      .map((_, element) => $(element).text().trim())
      .get()
      .filter((text) => text && !/^read manhwa\b/i.test(text));

    return {
      id: mangaId,
      url: `${this.baseUrl}/manhua/${encodeURIComponent(mangaId)}/`,
      title: $('.post-title h1').first().text().trim(),
      thumbnailUrl:
        this.makeAbsoluteUrl(
          $('.summary_image img').attr('data-src') ||
            $('.summary_image img').attr('src') ||
            '',
        ),
      description:
        descriptionParagraphs.join('\n\n') ||
        $('.summary__content').text().trim(),
      author: $('.author-content').text().trim(),
      artist: $('.artist-content').text().trim(),
      status: $('.post-status .summary-content').text().trim(),
      genres: $('.genres-content a')
        .map((_, el) => $(el).text().trim())
        .get(),
      sourceId: this.id,
    };
  }

  chapterListRequest(mangaId: string): AxiosRequestConfig {
    return {
      url: `${this.baseUrl}/manhua/${encodeURIComponent(this.normalizeMangaId(mangaId))}/`,
      method: 'GET',
    };
  }

  chapterListParse(response: AxiosResponse): Chapter[] {
    const $ = cheerio.load(response.data);
    const chapters: Chapter[] = [];

    $('li.wp-manga-chapter').each((_, element) => {
      const url = this.makeAbsoluteUrl($(element).find('a').attr('href') || '');
      const id = this.chapterUrlToId(url);
      const dateStr = $(element).find('.chapter-release-date i').text().trim();

      if (!id) return;

      chapters.push({
        id,
        url,
        name: $(element).find('a').text().trim(),
        chapterNumber: this.parseChapterNumber($(element).find('a').text()),
        dateUpload: this.parseDate(dateStr),
      });
    });

    return chapters;
  }

  pageListRequest(chapterId: string): AxiosRequestConfig {
    return {
      url: `${this.baseUrl}/${chapterId}/`,
      method: 'GET',
    };
  }

  pageListParse(response: AxiosResponse): Page[] {
    const $ = cheerio.load(response.data);
    const pages: Page[] = [];

    // Selectors for Madara themes (ManhuaTop uses Madara)
    // 1. .page-break img (standard)
    // 2. .wp-manga-chapter-img (sometimes used)
    // 3. .reading-content img (fallback)
    const selectors = [
      '.page-break img',
      '.wp-manga-chapter-img',
      '.reading-content img',
      '.blocks-gallery-item img',
      'div.entry-content img', // Sometimes images are just dumped here
    ];

    let imagesFound = false;

    for (const selector of selectors) {
      const elements = $(selector);
      if (elements.length > 0) {
        elements.each((index, element) => {
          // Check common lazy loading attributes
          // Some sites use data-src, data-lazy-src, data-original
          const url =
            $(element).attr('data-src') ||
            $(element).attr('data-lazy-src') ||
            $(element).attr('data-original') ||
            $(element).attr('src');

          // Avoid base64 placeholders, logos, and very small images
          if (url && !url.includes('data:image')) {
            // Basic filter for likely garbage images
            if (
              url.includes('logo') ||
              url.includes('banner') ||
              url.includes('ads')
            )
              return;

            pages.push({
              index,
                imageUrl: this.makeAbsoluteUrl(url.trim()),
              url: '',
            });
          }
        });

        // If we found pages with this selector, stop trying others to avoid duplicates
        // unless the count is suspiciously low (e.g. < 3 for a chapter), but usually one selector is enough.
        if (pages.length > 0) {
          imagesFound = true;
          break;
        }
      }
    }

    // De-duplicate just in case
    const uniquePages = Array.from(
      new Map(pages.map((p) => [p.imageUrl, p])).values(),
    );

    return uniquePages.map((p, i) => ({ ...p, index: i }));
  }

  private urlToId(url: string): string {
    // Remove trailing slash and split
    const cleanUrl = url.replace(/\/$/, '');
    const parts = cleanUrl.split('/').filter(Boolean);
    return parts[parts.length - 1] || '';
  }

  private normalizeMangaId(rawId: string): string {
    const raw = rawId.trim();
    try {
      const parsed = new URL(raw, this.baseUrl);
      const segments = parsed.pathname.split('/').filter(Boolean);
      const manhuaIndex = segments.indexOf('manhua');
      return (manhuaIndex >= 0
        ? segments[manhuaIndex + 1]
        : segments[segments.length - 1] || raw
      ).trim();
    } catch {
      return raw.replace(/^\/+|\/+$/g, '').replace(/^manhua\//, '');
    }
  }

  private makeAbsoluteUrl(value: string): string {
    const trimmed = value.trim();
    if (!trimmed || trimmed.startsWith('data:')) return '';
    try {
      return new URL(trimmed, this.baseUrl).toString();
    } catch {
      return '';
    }
  }

  private chapterUrlToId(url: string): string {
    // Extract everything after baseUrl, remove leading/trailing slashes
    let id = url.replace(this.baseUrl, '');
    id = id.replace(/^\/+|\/+$/g, '');
    return id;
  }

  private parseChapterNumber(name: string): number {
    // Matches "Chapter 10", "Ch.10", "10", "10.5"
    // Also handles volume prefixes if needed, but usually chapter number is the primary sort key
    const match =
      name.match(/(?:Chapter|Ch\.?|No\.)\s*(\d+(\.\d+)?)/i) ||
      name.match(/^(\d+(\.\d+)?)/);
    return match ? parseFloat(match[1]) : 0;
  }

  private parseDate(dateStr: string): number {
    // 1. Handle relative dates like "2 days ago", "1 hour ago"
    if (dateStr.includes('ago')) {
      const now = Date.now();
      const num = parseInt(dateStr.match(/\d+/)?.[0] || '0', 10);

      if (dateStr.includes('second')) return now - num * 1000;
      if (dateStr.includes('minute')) return now - num * 60 * 1000;
      if (dateStr.includes('hour')) return now - num * 60 * 60 * 1000;
      if (dateStr.includes('day')) return now - num * 24 * 60 * 60 * 1000;
      if (dateStr.includes('week')) return now - num * 7 * 24 * 60 * 60 * 1000;
      if (dateStr.includes('month'))
        return now - num * 30 * 24 * 60 * 60 * 1000;
      if (dateStr.includes('year'))
        return now - num * 365 * 24 * 60 * 60 * 1000;
      return now;
    }

    // 2. Handle "Yesterday", "Today"
    if (dateStr.toLowerCase().includes('yesterday')) {
      return Date.now() - 24 * 60 * 60 * 1000;
    }
    if (dateStr.toLowerCase().includes('today')) {
      return Date.now();
    }

    // 3. Handle standard formats
    // Remove ordinal suffixes like 'st', 'nd', 'rd', 'th' (e.g., "January 1st, 2023")
    const cleanDate = dateStr.replace(/(\d+)(st|nd|rd|th)/, '$1');
    const parsed = Date.parse(cleanDate);

    return isNaN(parsed) ? 0 : parsed;
  }
}
