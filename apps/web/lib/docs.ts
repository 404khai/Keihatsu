import fs from 'node:fs/promises';
import path from 'node:path';

import { docsPages } from './docs-index';
export { docsPages } from './docs-index';

export const headingId = (text: string) => text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
export async function readDoc(slug: string) {
  if (!docsPages.some(p => p.slug === slug)) return null;
  return fs.readFile(path.join(process.cwd(), 'content', 'docs', `${slug}.md`), 'utf8');
}
