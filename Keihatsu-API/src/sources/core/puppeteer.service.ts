import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Browser, Page } from 'puppeteer';
import puppeteer from 'puppeteer-extra';
import StealthPlugin from 'puppeteer-extra-plugin-stealth';

@Injectable()
export class PuppeteerService implements OnModuleInit, OnModuleDestroy {
  private browser: Browser;

  async onModuleInit() {
    puppeteer.use(StealthPlugin());
    await this.launchBrowser();
  }

  async onModuleDestroy() {
    if (this.browser) {
      await this.browser.close();
    }
  }

  private async launchBrowser() {
    this.browser = await puppeteer.launch({
      headless: true, // Use "new" if supported by installed version, otherwise boolean
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-web-security',
        '--disable-features=IsolateOrigins,site-per-process',
        '--window-size=1920,1080',
      ],
    });
  }

  async fetchPageContent(
    url: string,
    waitForSelector?: string,
    waitForTimeout: number = 0,
  ): Promise<string> {
    if (!this.browser) {
      await this.launchBrowser();
    }

    let page: Page | null = null;
    try {
      page = await this.browser.newPage();

      // Randomize Viewport
      await page.setViewport({
        width: 1920 + Math.floor(Math.random() * 100),
        height: 1080 + Math.floor(Math.random() * 100),
      });

      // Set a realistic User-Agent (although Stealth plugin handles this, explicit setting can help)
      await page.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
      );

      await page.setExtraHTTPHeaders({
        'Accept-Language': 'en-US,en;q=0.9',
        Referer: 'https://google.com',
      });

      // Block images/fonts to speed up, BUT allow stylesheets/scripts as some sites break without them
      await page.setRequestInterception(true);
      page.on('request', (req) => {
        const resourceType = req.resourceType();
        // Allow stylesheets and scripts to ensure proper rendering and anti-bot checks pass
        if (
          resourceType === 'image' ||
          resourceType === 'font' ||
          resourceType === 'media'
        ) {
          req.abort();
        } else {
          req.continue();
        }
      });

      // Navigate
      await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });

      // Handle selector waiting
      if (waitForSelector) {
        try {
          await page.waitForSelector(waitForSelector, { timeout: 15000 });
        } catch (e) {
          console.warn(
            `Timeout waiting for selector ${waitForSelector} on ${url}. Content might be incomplete.`,
          );
          // We DO NOT throw here immediately, because sometimes the selector is just missing (e.g. no search results)
          // but the page loaded fine. We let the parser handle the empty content.
          // However, if the page is a Cloudflare challenge, the content will reflect that.
        }
      }

      if (waitForTimeout > 0) {
        await new Promise((resolve) => setTimeout(resolve, waitForTimeout));
      }

      const content = await page.content();
      return content;
    } catch (error) {
      console.error(
        `Puppeteer fetch failed for ${url}: ${error instanceof Error ? error.message : String(error)}`,
      );
      throw error;
    } finally {
      if (page) {
        await page.close();
      }
    }
  }

  async close() {
    if (this.browser) await this.browser.close();
  }
}
