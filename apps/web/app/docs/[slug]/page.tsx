import Link from 'next/link';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { notFound } from 'next/navigation';
import { docsPages, readDoc, headingId } from '@/lib/docs';
import { DocsTableOfContents } from '@/components/docs/docs-navigation';

export function generateStaticParams() { return docsPages.map(p => ({slug: p.slug})); }
export async function generateMetadata({params}: {params: Promise<{slug: string}>}) {
  const {slug} = await params; const page = docsPages.find(p => p.slug === slug);
  return {title: `${page?.title || 'Documentation'} | Keihatsu`, description: page?.description};
}
export default async function DocsPage({params}: {params: Promise<{slug: string}>}) {
  const {slug} = await params; const index = docsPages.findIndex(p => p.slug === slug);
  const content = await readDoc(slug); if (!content || index < 0) notFound();
  const page = docsPages[index];
  const headings = [...content.matchAll(/^## (.+)$/gm)].map(m => ({title: m[1], id: headingId(m[1])}));
  return <><main className="docs-article" id="docs-content">
    <div className="docs-breadcrumb"><Link href="/">Keihatsu</Link><span>/</span>Documentation</div>
    <h1>{page.title}</h1><p className="docs-description">{page.description}</p>
    <Markdown remarkPlugins={[remarkGfm]} components={{
      h2: ({children}) => <h2 id={headingId(String(children))}>{children}</h2>,
      img: ({src, alt}) => <img className="docs-image" src={typeof src === 'string' ? src : undefined} alt={alt || ''} loading="lazy" />,
      a: ({href, children}) => <a href={href} {...(href?.startsWith('http') ? {target: '_blank', rel: 'noopener noreferrer'} : {})}>{children}</a>,
    }}>{content}</Markdown>
    <footer className="docs-pagination">{index > 0 ? <Link href={`/docs/${docsPages[index - 1].slug}`}><small>Previous</small>{docsPages[index - 1].title}</Link> : <span />}
      {index < docsPages.length - 1 && <Link href={`/docs/${docsPages[index + 1].slug}`}><small>Next</small>{docsPages[index + 1].title} →</Link>}</footer>
  </main><DocsTableOfContents headings={headings} /></>;
}
