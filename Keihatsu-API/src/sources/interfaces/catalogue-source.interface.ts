import { Source } from './source.interface';
import { Manga, Chapter, Page, MangasPage } from './manga.interface';

export interface CatalogueSource extends Source {
  getPopularManga(page: number): Promise<MangasPage>;
  getLatestUpdates(page: number): Promise<MangasPage>;
  searchManga(page: number, query: string, filters: any): Promise<MangasPage>;

  getMangaDetails(mangaId: string): Promise<Manga>;
  getChapterList(mangaId: string): Promise<Chapter[]>;
  getPageList(chapterId: string): Promise<Page[]>;
}
