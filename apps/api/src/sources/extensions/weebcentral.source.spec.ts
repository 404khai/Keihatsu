import { WeebCentralSource } from './weebcentral.source';
import { PuppeteerService } from '../core/puppeteer.service';

describe('WeebCentral metadata and chapters', () => {
  const browser = { fetchPageContent: jest.fn() };
  const source = new WeebCentralSource(browser as unknown as PuppeteerService);

  it('accepts a detail page containing Cloudflare script and extracts metadata', async () => {
    browser.fetchPageContent.mockResolvedValueOnce(`
      <html><head><title>Example | Weeb Central</title>
      <script src="/cdn-cgi/challenge-platform/scripts/jsd/main.js"></script></head>
      <body><h1>Example</h1><img alt="Example cover" src="https://covers.example/cover.jpg">
      <p>A long description of this series that contains enough text to be selected as its overview.</p>
      <li><strong>Author(s): </strong><span><a>First Author</a></span><span><a>Second Author</a></span></li>
      </body></html>`);
    const manga = await source.getMangaDetails('series-id');
    expect(manga.title).toBe('Example');
    expect(manga.author).toBe('First Author, Second Author');
    expect(manga.description).toContain('A long description');
    expect(browser.fetchPageContent).toHaveBeenCalledTimes(1);
  });

  it('removes hidden Last Read labels and uses chapter upload timestamps', async () => {
    browser.fetchPageContent.mockResolvedValueOnce(`
      <a href="/chapters/chapter-id"><span class="grow"><span>Chapter 42</span>
      <span class="hidden md:inline">Last Read</span></span>
      <time datetime="2026-09-11T04:49:26.455Z"></time></a>`);
    const chapters = await source.getChapterList('series-id');
    expect(chapters).toHaveLength(1);
    expect(chapters[0]).toMatchObject({ id: 'chapter-id', name: 'Chapter 42', chapterNumber: 42 });
    expect(chapters[0].dateUpload).toBe(Date.parse('2026-09-11T04:49:26.455Z'));
  });
});
