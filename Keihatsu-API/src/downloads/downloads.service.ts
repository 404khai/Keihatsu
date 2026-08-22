import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { SourcesService } from '../sources/sources.service';
import * as fs from 'fs';
import * as path from 'path';
import axios from 'axios';
import { Stream } from 'stream';
import { promisify } from 'util';

const pipeline = promisify(Stream.pipeline);

@Injectable()
export class DownloadsService {
  private readonly logger = new Logger(DownloadsService.name);
  private readonly downloadsRoot = path.join(process.cwd(), 'downloads');

  constructor(private readonly sourcesService: SourcesService) {}

  async downloadChapter(sourceId: string, mangaId: string, chapterId: string) {
    // 1. Get Source Name
    const source = this.sourcesService.getSource(sourceId);
    if (!source) throw new NotFoundException('Source not found');
    const sourceName = this.sanitize(source.name);

    // 2. Get Manga Title
    const manga = await this.sourcesService.getMangaDetails(sourceId, mangaId);
    const mangaTitle = this.sanitize(manga.title);

    // 3. Get Chapter Title
    // Need to find chapter in list to get its title/number
    const chapters = await this.sourcesService.getChapterList(
      sourceId,
      mangaId,
    );
    const chapter = chapters.find((c) => c.id === chapterId);
    if (!chapter) throw new NotFoundException('Chapter not found');

    // Construct a friendly chapter name
    // Use chapter.name if available, otherwise construct from number
    const chapterName = chapter.name || `Chapter ${chapter.chapterNumber}`;
    const safeChapterName = this.sanitize(chapterName);

    // 4. Create Directory
    const downloadDir = path.join(
      this.downloadsRoot,
      sourceName,
      mangaTitle,
      safeChapterName,
    );
    if (!fs.existsSync(downloadDir)) {
      fs.mkdirSync(downloadDir, { recursive: true });
    }

    // 5. Get Pages
    const pages = await this.sourcesService.getPageList(sourceId, chapterId);

    // 6. Download Pages
    this.logger.log(
      `Starting download for ${mangaTitle} - ${chapterName} (${pages.length} pages)`,
    );

    // Process in chunks to avoid overwhelming the server or local network
    const chunkSize = 5;
    for (let i = 0; i < pages.length; i += chunkSize) {
      const chunk = pages.slice(i, i + chunkSize);
      await Promise.all(
        chunk.map(async (page, index) => {
          const actualIndex = i + index;
          // Use imageUrl for downloading
          const targetUrl = page.imageUrl;
          const extension = path.extname(targetUrl.split('?')[0]) || '.jpg';
          // Pad page number: 001, 002, etc.
          const pageNumber = (actualIndex + 1).toString().padStart(3, '0');
          const filename = `${pageNumber}${extension}`;
          const filePath = path.join(downloadDir, filename);

          try {
            await this.downloadFile(targetUrl, filePath);
          } catch (error) {
            this.logger.error(
              `Failed to download page ${actualIndex + 1}: ${error.message}`,
            );
          }
        }),
      );
    }

    this.logger.log(`Completed download for ${mangaTitle} - ${chapterName}`);

    return {
      status: 'completed',
      path: downloadDir,
      pageCount: pages.length,
    };
  }

  private sanitize(str: string): string {
    return str.replace(/[<>:"/\\|?*]/g, '').trim();
  }

  private async downloadFile(url: string, outputPath: string) {
    const response = await axios({
      url,
      method: 'GET',
      responseType: 'stream',
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        // 'Referer': url // Some CDNs check referer, but usually base url is better. Leaving empty for now unless needed.
      },
    });

    await pipeline(response.data, fs.createWriteStream(outputPath));
  }
}
