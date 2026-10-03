"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutGrid,
  Users,
  BookOpen,
  Puzzle,
  MessageCircle,
  Flag,
  Shield,
  Settings,
} from "lucide-react";
export const sections = [
  "readers",
  "catalogue",
  "extensions",
  "community",
  "reports",
  "team",
  "settings",
];
const items = [
  ["", "Overview", LayoutGrid],
  ["readers", "Readers", Users],
  ["catalogue", "Catalogue", BookOpen],
  ["extensions", "Extensions", Puzzle],
  ["community", "Community", MessageCircle],
  ["reports", "Reports", Flag],
  ["team", "Team & access", Shield],
  ["settings", "Settings", Settings],
] as const;
export function AdminNav() {
  const path = usePathname();
  return (
    <nav aria-label="Admin navigation">
      <span className="admin-eyebrow">WORKSPACE</span>
      {items.map(([slug, label, Icon]) => (
        <Link
          key={slug}
          href={`/admin${slug ? `/${slug}` : ""}`}
          aria-current={
            path === `/admin${slug ? `/${slug}` : ""}` ? "page" : undefined
          }
        >
          <Icon size={18} />
          {label}
        </Link>
      ))}
    </nav>
  );
}
