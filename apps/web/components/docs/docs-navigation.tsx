'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { BounceSidebar } from '@/components/ui/bounce-sidebar';
import { docsPages } from '@/lib/docs-index';

export function DocsNavigation() {
  const pathname = usePathname();
  const [query, setQuery] = useState('');
  return <aside className="docs-nav"><p className="docs-eyebrow">READER HANDBOOK</p>
    <label className="docs-search"><span className="sr-only">Find a guide</span>
      <input placeholder="Find a guide…" value={query} onChange={e => setQuery(e.target.value)} /></label>
    <nav aria-label="Documentation">{docsPages.filter(p => `${p.title} ${p.description}`.toLowerCase().includes(query.toLowerCase())).map(p =>
      <Link key={p.slug} href={`/docs/${p.slug}`} aria-current={pathname === `/docs/${p.slug}` ? 'page' : undefined}>{p.title}</Link>)}</nav>
    <a className="docs-help" href="https://github.com/404khai/Keihatsu/issues">Something missing? ↗</a>
  </aside>;
}

export function DocsTableOfContents({headings}: {headings: {id: string; title: string}[]}) {
  const [active, setActive] = useState(0);
  useEffect(() => {
    const update = () => {
      let current = 0;
      headings.forEach((heading, index) => {
        if ((document.getElementById(heading.id)?.getBoundingClientRect().top ?? Infinity) <= 160) current = index;
      });
      setActive(current);
    };
    update(); window.addEventListener('scroll', update, {passive: true});
    return () => window.removeEventListener('scroll', update);
  }, [headings]);
  return <aside className="docs-toc" aria-label="On this page"><p>On this page</p>
    <BounceSidebar items={headings.map(h => h.title)} value={active} dotColor="var(--yellow)"
      onChange={index => {setActive(index); document.getElementById(headings[index].id)?.scrollIntoView({behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth', block: 'start'}); history.replaceState(null, '', `#${headings[index].id}`);}} />
  </aside>;
}
