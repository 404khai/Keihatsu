import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios';
import { CatalogueSource } from '../interfaces/catalogue-source.interface';
import {
  Manga,
  Chapter,
  Page,
  MangasPage,
} from '../interfaces/manga.interface';

export abstract class HttpSource implements CatalogueSource {
  abstract id: string;
  abstract name: string;
  abstract baseUrl: string;
  abstract lang: string;
  abstract versionId: number;
  iconUrl?: string;

  protected client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      timeout: 15000,
      headers: this.headers(),
    });
  }

  protected headers(): Record<string, string> {
    return {
      'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
    };
  }

  // Popular Manga
  abstract popularMangaRequest(page: number): AxiosRequestConfig;
  abstract popularMangaParse(response: AxiosResponse): MangasPage;

  async getPopularManga(page: number): Promise<MangasPage> {
    const config = this.popularMangaRequest(page);
    const response = await this.client.request(config);
    return this.popularMangaParse(response);
  }

  // Latest Updates
  abstract latestUpdatesRequest(page: number): AxiosRequestConfig;
  abstract latestUpdatesParse(response: AxiosResponse): MangasPage;

  async getLatestUpdates(page: number): Promise<MangasPage> {
    const config = this.latestUpdatesRequest(page);
    const response = await this.client.request(config);
    return this.latestUpdatesParse(response);
  }

  // Search
  abstract searchMangaRequest(
    page: number,
    query: string,
    filters: any,
  ): AxiosRequestConfig;
  abstract searchMangaParse(response: AxiosResponse): MangasPage;

  async searchManga(
    page: number,
    query: string,
    filters: any,
  ): Promise<MangasPage> {
    const config = this.searchMangaRequest(page, query, filters);
    const response = await this.client.request(config);
    return this.searchMangaParse(response);
  }

  // Manga Details
  abstract mangaDetailsRequest(mangaId: string): AxiosRequestConfig;
  abstract mangaDetailsParse(response: AxiosResponse, mangaId: string): Manga;

  async getMangaDetails(mangaId: string): Promise<Manga> {
    const config = this.mangaDetailsRequest(mangaId);
    const response = await this.client.request(config);
    return this.mangaDetailsParse(response, mangaId);
  }

  // Chapters
  abstract chapterListRequest(mangaId: string): AxiosRequestConfig;
  abstract chapterListParse(response: AxiosResponse): Chapter[];

  async getChapterList(mangaId: string): Promise<Chapter[]> {
    const config = this.chapterListRequest(mangaId);
    const response = await this.client.request(config);
    return this.chapterListParse(response);
  }

  // Pages
  abstract pageListRequest(chapterId: string): AxiosRequestConfig;
  abstract pageListParse(response: AxiosResponse): Page[];

  async getPageList(chapterId: string): Promise<Page[]> {
    const config = this.pageListRequest(chapterId);
    const response = await this.client.request(config);
    return this.pageListParse(response);
  }
}
