import { PuppeteerService } from './src/sources/core/puppeteer.service';
import { ManhuaTopSource } from './src/sources/extensions/manhuatop.source';

async function testManhuaTop() {
    console.log('Initializing PuppeteerService...');
    const puppeteerService = new PuppeteerService();
    await puppeteerService.onModuleInit();

    try {
        const source = new ManhuaTopSource(puppeteerService);
        
        console.log('\n1. Fetching Popular Manga...');
        const popular = await source.getPopularManga(1);
        
        if (popular.mangas.length === 0) {
            console.error('FAILED: No popular mangas found');
            return;
        }

        const manga = popular.mangas[0];
        console.log(`Selected Manga: ${manga.title} (${manga.id})`);

        console.log('\n2. Fetching Chapter List...');
        const chapters = await source.getChapterList(manga.id);
        
        if (chapters.length === 0) {
            console.error('FAILED: No chapters found');
            return;
        }

        const chapter = chapters[0];
        console.log(`Selected Chapter: ${chapter.name} (${chapter.id})`);
        console.log(`Chapter URL: ${chapter.url}`);

        console.log('\n3. Fetching Page List...');
        const pages = await source.getPageList(chapter.id);
        
        console.log(`Found ${pages.length} pages`);
        if (pages.length > 0) {
            console.log('First Page URL:', pages[0].imageUrl);
            console.log('SUCCESS: Pages fetched successfully');
        } else {
            console.error('FAILED: No pages found');
        }

    } catch (error) {
        console.error('Test Failed:', error);
    } finally {
        await puppeteerService.onModuleDestroy();
    }
}

testManhuaTop();
