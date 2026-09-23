import { Injectable } from '@nestjs/common';
import { HttpSource } from '../core/http-source.abstract';
import { Manga, Chapter, Page, MangasPage } from '../interfaces/manga.interface';

interface SearchDocument {
  id: string;
  title: string;
  poster?: string;
  posterMedium?: string;
  synopsis?: string;
  authors?: string[];
  status?: string;
}

interface ChapterRecord {
  id: string;
  title: string;
  number: number;
  createdAt: number;
}

/** Atsumaru's public catalogue and reader endpoints return JSON. */
@Injectable()
export class AtsumaruSource extends HttpSource {
  id = 'atsumaru';
  name = 'Atsumaru';
  baseUrl = 'https://atsu.moe';
  lang = 'en';
  versionId = 2;
  iconUrl = '/images/atsumaru.png';

  private imageUrl(path?: string): string {
    return path ? new URL(path, 'https://cdn.atsu.moe').toString() : '';
  }

  private async listing(page: number, query: string, sort: string): Promise<MangasPage> {
    const params = new URLSearchParams({
      q: query || '*',
      query_by: 'title,otherNames',
      per_page: '24',
      page: String(page),
      filter_by: 'hidden:!=true',
      sort_by: sort,
    });
    const { data } = await this.client.get(`${this.baseUrl}/collections/manga/documents/search?${params}`);
    const mangas: Manga[] = (data.hits ?? []).map(({ document }: { document: SearchDocument }) => ({
      id: document.id,
      url: `${this.baseUrl}/manga/${document.id}`,
      title: document.title,
      thumbnailUrl: this.imageUrl(document.posterMedium || document.poster),
      sourceId: this.id,
    }));
    return { mangas, hasNextPage: page * 24 < data.found };
  }

  getPopularManga(page: number): Promise<MangasPage> {
    return this.listing(page, '*', 'views:desc');
  }

  getLatestUpdates(page: number): Promise<MangasPage> {
    return this.latestUpdates(page);
  }

  private async latestUpdates(page: number): Promise<MangasPage> {
    const params = new URLSearchParams({
      offset: String((page - 1) * 24), limit: '24',
      types: 'Manga,Manwha,Manhua,OEL,Other',
      mediums: 'Comic,Novel', contentRatings: 'Safe,Suggestive,Erotica',
    });
    const { data } = await this.client.get(`${this.baseUrl}/api/home2/hotUpdates?${params}`);
    const mangas: Manga[] = (data.items ?? []).map((item: {
      id: string; title: string; mediumImage?: string; image?: string;
    }) => ({
      id: item.id, url: `${this.baseUrl}/manga/${item.id}`,
      title: item.title, thumbnailUrl: this.imageUrl(`/static/${item.mediumImage || item.image}`),
      sourceId: this.id,
    }));
    return { mangas, hasNextPage: mangas.length === 24 };
  }

  searchManga(page: number, query: string): Promise<MangasPage> {
    return this.listing(page, query, '_text_match:desc');
  }

  private async mangaPage(mangaId: string): Promise<any> {
    const { data } = await this.client.get(`${this.baseUrl}/api/manga/page`, { params: { id: mangaId } });
    if (!data.mangaPage?.id) throw new Error(`Atsumaru returned no manga for ${mangaId}`);
    return data.mangaPage;
  }

  async getMangaDetails(mangaId: string): Promise<Manga> {
    const manga = await this.mangaPage(mangaId);
    return {
      id: manga.id,
      url: `${this.baseUrl}/manga/${manga.id}`,
      title: manga.title,
      thumbnailUrl: this.imageUrl(manga.poster?.mediumImage || manga.poster?.image),
      description: manga.synopsis,
      author: manga.authors?.map((value: { name: string }) => value.name).join(', '),
      status: manga.status,
      genres: manga.genres?.map((value: { name: string }) => value.name) ?? [],
      sourceId: this.id,
    };
  }

  async getChapterList(mangaId: string): Promise<Chapter[]> {
    const manga = await this.mangaPage(mangaId);
    return (manga.chapters ?? []).map((chapter: ChapterRecord) => ({
      id: `${mangaId}/${chapter.id}`,
      url: `${this.baseUrl}/read/${mangaId}/${chapter.id}`,
      name: chapter.title,
      chapterNumber: chapter.number,
      dateUpload: chapter.createdAt,
    }));
  }

  async getPageList(chapterId: string): Promise<Page[]> {
    const [mangaId, id] = chapterId.split('/');
    if (!mangaId || !id) throw new Error('Invalid Atsumaru chapter ID');
    const url = `${this.baseUrl}/read/${mangaId}/${id}`;
    const { data } = await this.client.get(`${this.baseUrl}/api/read/chapter`, { params: { mangaId, chapterId: id } });
    if (!data.readChapter?.pages) throw new Error(`Atsumaru returned no pages for ${chapterId}`);
    return data.readChapter.pages.map((page: { image: string }, index: number) => ({
      index,
      imageUrl: this.imageUrl(page.image),
      url,
    }));
  }

  // HttpSource's request/parse hooks are unused because this source uses JSON endpoints.
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
