import { Navbar } from '@/components/navbar';
import { DocsNavigation } from '@/components/docs/docs-navigation';
import './docs.css';

export default function DocsLayout({children}: {children: React.ReactNode}) {
  return <div className="docs-shell"><Navbar /><div className="docs-layout"><DocsNavigation />{children}</div></div>;
}
