
import axios from 'axios';
import * as cheerio from 'cheerio';

async function debug() {
  const headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'en-US,en;q=0.9',
    'Referer': 'https://google.com/',
    'Upgrade-Insecure-Requests': '1',
  };

  try {
    console.log('Fetching homepage...');
    const listUrl = 'https://manhuatop.org/';
    const listResp = await axios.get(listUrl, { headers });
    const $list = cheerio.load(listResp.data);
    
    console.log('Homepage HTML structure check:');
    // Check for manga items
    const items = $list('.page-item-detail, .c-tabs-item__content, .item-summary');
    console.log(`Found ${items.length} items.`);
    
    if (items.length > 0) {
      const first = items.first();
      console.log('First item title:', first.find('.post-title a, h3 a').text().trim());
    } else {
      console.log('No items found. Dumping body start (might be Cloudflare):');
      console.log($list('body').html()?.substring(0, 500));
    }

  } catch (e) {
    console.error('Error:', e.message);
    if (e.response) {
      console.log('Status:', e.response.status);
      console.log('Data:', e.response.data?.substring(0, 200));
    }
  }
}

debug();
