import { AxiosRequestConfig } from 'axios';
import * as cheerio from 'cheerio';
import { HttpSource } from '../core/http-source.abstract';
import {
  Chapter,
  Manga,
  MangasPage,
  Page,
} from '../interfaces/manga.interface';
import { PuppeteerService } from '../core/puppeteer.service';

type BatCaveSeriesJsonLd = {
  name?: string;
  image?: string;
  description?: string;
  genre?: string[] | string;
  author?: Array<{ name?: string }> | { name?: string };
  illustrator?: Array<{ name?: string }> | { name?: string };
  publisher?: { name?: string };
  hasPart?: {
    itemListElement?: Array<{
      position?: number;
      item?: {
        url?: string;
        name?: string;
        issueNumber?: string | number;
      };
    }>;
  };
};

type JsonLdGraphResponse = {
  '@graph'?: Array<Record<string, unknown>>;
};

export class BatCaveSource extends HttpSource {
  id = 'batcave';
  name = 'BatCave';
  baseUrl = 'https://batcave.biz';
  lang = 'en';
  versionId = 1;
  iconUrl = '/images/batcave.png';

  constructor(private puppeteerService: PuppeteerService) {
    super();
  }

  async getPopularManga(page: number): Promise<MangasPage> {
    const url = this.buildCatalogueUrl(page);
    const html = await this.puppeteerService.fetchPageContent(
      url,
      '.readed',
      2000,
    );
    return this.parseMangaCards(html, page);
  }

  async getLatestUpdates(page: number): Promise<MangasPage> {
    // BatCave's public catalogue is ordered by newest additions, so we reuse it for latest.
    const url = this.buildCatalogueUrl(page);
    const html = await this.puppeteerService.fetchPageContent(
      url,
      '.readed',
      2000,
    );
    return this.parseMangaCards(html, page);
  }

  async searchManga(
    page: number,
    query: string,
    filters: any,
  ): Promise<MangasPage> {
    void filters;
    const url = this.buildSearchUrl(query, page);
    const html = await this.puppeteerService.fetchPageContent(
      url,
      '.readed',
      2000,
    );
    return this.parseMangaCards(html, page);
  }

  async getMangaDetails(mangaId: string): Promise<Manga> {
    const url = `${this.baseUrl}/${mangaId}`;
    const html = await this.puppeteerService.fetchPageContent(
      url,
      'body',
      2000,
    );
    const $ = cheerio.load(html);

    const seriesData = this.extractSeriesJsonLd(html);
    const title =
      seriesData?.name?.trim() ||
      $('meta[property="og:title"]').attr('content') ||
      '';
    const thumbnail =
      this.makeAbsoluteUrl(
        seriesData?.image ||
          $('link[rel="preload"][as="image"]').attr('href') ||
          $('meta[property="og:image"]').attr('content') ||
          '',
      ) || '';
    const description =
      seriesData?.description?.trim() ||
      $('meta[property="og:description"]').attr('content') ||
      '';
    const genres = this.toStringArray(seriesData?.genre);
    const author = this.extractPersonNames(seriesData?.author).join(', ');
    const artist = this.extractPersonNames(seriesData?.illustrator).join(', ');
    const status = this.inferStatus(title, $('title').text());

    return {
      id: mangaId,
      url,
      title,
      thumbnailUrl: thumbnail,
      description,
      author,
      artist,
      status,
      genres,
      sourceId: this.id,
    };
  }

  async getChapterList(mangaId: string): Promise<Chapter[]> {
    const url = `${this.baseUrl}/${mangaId}`;
    const html = await this.puppeteerService.fetchPageContent(
      url,
      'body',
      2000,
    );

    const seriesData = this.extractSeriesJsonLd(html);
    const chapterElements = seriesData?.hasPart?.itemListElement ?? [];

    const chapters = chapterElements
      .map((entry, index) => {
        const chapterUrl = entry.item?.url ?? '';
        const chapterId = chapterUrl.replace(`${this.baseUrl}/reader/`, '');
        const name =
          entry.item?.name?.trim() ||
          `Issue ${entry.item?.issueNumber ?? index + 1}`;
        const issueNumber = this.parseChapterNumber(
          String(entry.item?.issueNumber ?? name),
        );

        if (!chapterId) {
          return null;
        }

        return {
          id: chapterId,
          url: chapterUrl,
          name,
          chapterNumber: issueNumber,
          dateUpload: 0,
        } as Chapter;
      })
      .filter((chapter): chapter is Chapter => chapter !== null);

    return chapters;
  }

  async getPageList(chapterId: string): Promise<Page[]> {
    const url = `${this.baseUrl}/reader/${chapterId}`;
    const html = await this.puppeteerService.fetchPageContent(
      url,
      '.reader-view img.reader__item',
      8000,
    );

    const data = this.extractReaderData(html);
    const images = data?.images ?? [];

    return images.map((imageUrl, index) => ({
      index,
      imageUrl: this.makeAbsoluteUrl(imageUrl),
      url,
    }));
  }

  private buildCatalogueUrl(page: number): string {
    return page <= 1
      ? `${this.baseUrl}/comix/`
      : `${this.baseUrl}/comix/page/${page}/`;
  }

  private buildSearchUrl(query: string, page: number): string {
    const encodedQuery = encodeURIComponent(query.trim());
    return page <= 1
      ? `${this.baseUrl}/search/${encodedQuery}`
      : `${this.baseUrl}/search/${encodedQuery}/page/${page}/`;
  }

  private parseMangaCards(html: string, page: number): MangasPage {
    const $ = cheerio.load(html);
    const mangas: Manga[] = [];

    $('.readed').each((_, element) => {
      const link = $(element).find('.readed__title a').first();
      const href = link.attr('href') || '';
      const id = href.replace(`${this.baseUrl}/`, '').trim();
      const title = link.text().trim();
      const image =
        $(element).find('.readed__img img').attr('data-src') ||
        $(element).find('.readed__img img').attr('src') ||
        '';

      if (!id || !title) {
        return;
      }

      mangas.push({
        id,
        url: this.makeAbsoluteUrl(href),
        title,
        thumbnailUrl: this.makeAbsoluteUrl(image),
        sourceId: this.id,
      });
    });

    const hasNextPage =
      $(`a[href$="/page/${page + 1}/"]`).length > 0 ||
      html.includes(`/page/${page + 1}/`);

    return { mangas, hasNextPage };
  }

  private extractSeriesJsonLd(html: string): BatCaveSeriesJsonLd | null {
    const $ = cheerio.load(html);
    const scripts = $('script[type="application/ld+json"]')
      .map((_, el) => $(el).contents().text())
      .get();

    for (const rawScript of scripts) {
      try {
        const parsed = JSON.parse(rawScript) as JsonLdGraphResponse;
        const graph = Array.isArray(parsed['@graph']) ? parsed['@graph'] : [];
        const series = graph.find(
          (entry: Record<string, unknown>) => entry['@type'] === 'ComicSeries',
        );

        if (series) {
          return series as BatCaveSeriesJsonLd;
        }
      } catch {
        continue;
      }
    }

    return null;
  }

  private extractReaderData(html: string): { images?: string[] } | null {
    const match = html.match(
      /window\.__DATA__\s*=\s*(\{[\s\S]*?\});<\/script>/,
    );
    if (!match) {
      return null;
    }

    try {
      return JSON.parse(match[1]) as { images?: string[] };
    } catch {
      return null;
    }
  }

  private toStringArray(value?: string[] | string): string[] {
    if (!value) {
      return [];
    }

    return Array.isArray(value)
      ? value.map((item) => item.trim()).filter(Boolean)
      : [value.trim()].filter(Boolean);
  }

  private extractPersonNames(
    value?: Array<{ name?: string }> | { name?: string },
  ): string[] {
    if (!value) {
      return [];
    }

    const items = Array.isArray(value) ? value : [value];
    return items.map((item) => item.name?.trim() || '').filter(Boolean);
  }

  private inferStatus(title: string, pageTitle: string): string {
    const combined = `${title} ${pageTitle}`;
    if (/\(\d{4}-\)/.test(combined)) {
      return 'Ongoing';
    }
    return 'Unknown';
  }

  private parseChapterNumber(name: string): number {
    const match =
      name.match(/Issue\s*#?\s*(\d+(\.\d+)?)/i) ||
      name.match(/#\s*(\d+(\.\d+)?)/) ||
      name.match(/(\d+(\.\d+)?)/);
    return match ? parseFloat(match[1]) : 0;
  }

  private makeAbsoluteUrl(url: string): string {
    if (!url) {
      return '';
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    return url.startsWith('/')
      ? `${this.baseUrl}${url}`
      : `${this.baseUrl}/${url}`;
  }

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
}
