import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import axios from 'axios';
import { SourcesService } from './sources.service';
import { PuppeteerService } from './core/puppeteer.service';
import { CatalogueSource } from './interfaces/catalogue-source.interface';

const live = process.env.RUN_LIVE_SOURCE_CONFORMANCE === '1';
const sourceIDs = ['atsumaru', 'mangafire', 'weebcentral'] as const;

describe('source failure contract', () => {
  const service = new SourcesService({} as PuppeteerService);
  const rateLimit = Object.assign(new Error('Upstream rate limited'), { status: 429 });
  const source = {
    id: 'failing',
    getPopularManga: jest.fn().mockRejectedValue(rateLimit),
    getLatestUpdates: jest.fn().mockRejectedValue(rateLimit),
    searchManga: jest.fn().mockRejectedValue(rateLimit),
  } as unknown as CatalogueSource;
  service.registerSource(source);

  it.each(['popular', 'latest', 'search'] as const)('preserves %s upstream failures', async (type) => {
    await expect(service.getMangaList('failing', type, 1, 'query')).rejects.toBe(rateLimit);
  });
});

/** Run with RUN_LIVE_SOURCE_CONFORMANCE=1; this is the gate before client rollout. */
(live ? describe : describe.skip)('live source conformance', () => {
  let browser: PuppeteerService;
  let service: SourcesService;
  beforeAll(async () => {
    browser = new PuppeteerService();
    await browser.onModuleInit();
    service = new SourcesService(browser);
    service.onModuleInit();
  }, 90_000);
  afterAll(async () => browser?.onModuleDestroy(), 30_000);

  for (const sourceID of sourceIDs) {
    it(`${sourceID}: listings, search, metadata, reader, image transfer and CBZ`, async () => {
      const source = service.getSource(sourceID);
      const popular = await source.getPopularManga(1);
      const latest = await source.getLatestUpdates(1);
      expect(popular.mangas.length).toBeGreaterThan(0);
      expect(latest.mangas.length).toBeGreaterThan(0);
      expect(popular.mangas.every((manga) => manga.sourceId === sourceID && manga.id && manga.title)).toBe(true);
      const first = popular.mangas[0];
      const search = await source.searchManga(1, first.title.split(/\s+/)[0], {});
      expect(search.mangas.length).toBeGreaterThan(0);
      expect(typeof search.hasNextPage).toBe('boolean');
      if (popular.hasNextPage) {
        const next = await source.getPopularManga(2);
        expect(next.mangas.length).toBeGreaterThan(0);
        expect(next.mangas[0].id).not.toBe(first.id);
      }
      const readerManga = sourceID === 'mangafire'
        ? (await source.searchManga(1, 'All-Class Awakening', {})).mangas[0]
        : first;
      expect(readerManga).toBeDefined();
      const detail = await source.getMangaDetails(readerManga.id);
      expect(detail.title).toBeTruthy();
      expect(detail.sourceId).toBe(sourceID);
      const chapters = await source.getChapterList(readerManga.id);
      expect(chapters.length).toBeGreaterThan(0);
      if (sourceID === 'mangafire') expect(chapters.length).toBeGreaterThan(20);
      expect(chapters.every((chapter) => chapter.id && chapter.name && Number.isFinite(chapter.chapterNumber))).toBe(true);
      expect(chapters[0].chapterNumber).toBeGreaterThanOrEqual(chapters[chapters.length - 1].chapterNumber);
      const pages = await source.getPageList(chapters[0].id);
      expect(pages.length).toBeGreaterThan(0);
      expect(pages.every((page, index) => page.index === index && new URL(page.imageUrl).protocol === 'https:' && page.url)).toBe(true);

      // A reader and both download engines consume these exact page URLs and referers.
      const directory = await mkdtemp(join(tmpdir(), `keihatsu-${sourceID}-`));
      try {
        const files: string[] = [];
        for (const page of pages.slice(0, 2)) {
          const response = await axios.get<ArrayBuffer>(page.imageUrl, {
            responseType: 'arraybuffer',
            headers: { Referer: page.url, Accept: 'image/*' },
            timeout: 30_000,
          });
          expect(response.headers['content-type']).toMatch(/^image\//);
          const filename = `${String(page.index + 1).padStart(4, '0')}.img`;
          await writeFile(join(directory, filename), Buffer.from(response.data));
          expect((await readFile(join(directory, filename))).length).toBeGreaterThan(0);
          files.push(filename);
        }
        execFileSync('zip', ['-q', 'chapter.cbz', ...files], { cwd: directory });
        execFileSync('unzip', ['-tq', 'chapter.cbz'], { cwd: directory });
      } finally {
        await rm(directory, { recursive: true, force: true });
      }
    }, 180_000);
  }
});
