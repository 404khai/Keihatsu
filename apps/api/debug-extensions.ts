import { Test, TestingModule } from '@nestjs/testing';
import { SourcesService } from './src/sources/sources.service';
import { PuppeteerService } from './src/sources/core/puppeteer.service';
import { WeebCentralSource } from './src/sources/extensions/weebcentral.source';
import { AtsumaruSource } from './src/sources/extensions/atsumaru.source';
import { HttpModule } from '@nestjs/axios';

async function testExtensions() {
    console.log('Initializing PuppeteerService...');
    const puppeteerService = new PuppeteerService();
    await puppeteerService.onModuleInit();

    try {
        // Test WeebCentral
        console.log('\n--- Testing WeebCentral ---');
        const weebCentral = new WeebCentralSource(puppeteerService);
        
        console.log('Fetching Popular Manga...');
        const wcPopular = await weebCentral.getPopularManga(1);
        console.log(`Found ${wcPopular.mangas.length} popular mangas`);
        if (wcPopular.mangas.length > 0) {
            const firstManga = wcPopular.mangas[0];
            console.log('First Manga:', firstManga.title, `(${firstManga.id})`);
            
            console.log('Fetching Details...');
            const details = await weebCentral.getMangaDetails(firstManga.id);
            console.log('Details:', details.title, (details.description || '').substring(0, 50) + '...');

            console.log('Fetching Chapters...');
            const chapters = await weebCentral.getChapterList(firstManga.id);
            console.log(`Found ${chapters.length} chapters`);
            
            if (chapters.length > 0) {
                console.log('Fetching Pages for first chapter...');
                const pages = await weebCentral.getPageList(chapters[0].id);
                console.log(`Found ${pages.length} pages`);
            }
        } else {
            console.error('FAILED: No popular mangas found for WeebCentral');
        }

        // Test Atsumaru
        console.log('\n--- Testing Atsumaru ---');
        const atsumaru = new AtsumaruSource(puppeteerService);
        
        console.log('Fetching Popular Manga...');
        const atsuPopular = await atsumaru.getPopularManga(1);
        console.log(`Found ${atsuPopular.mangas.length} popular mangas`);
        if (atsuPopular.mangas.length > 0) {
            const firstManga = atsuPopular.mangas[0];
            console.log('First Manga:', firstManga.title, `(${firstManga.id})`);
             // Skip details/chapters/pages for now to save time, or uncomment to test full flow
        } else {
             console.error('FAILED: No popular mangas found for Atsumaru');
        }

    } catch (error) {
        console.error('Test Failed:', error);
    } finally {
        await puppeteerService.onModuleDestroy();
    }
}

testExtensions();
