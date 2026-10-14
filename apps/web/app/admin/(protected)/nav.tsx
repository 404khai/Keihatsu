"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutGrid,
  Users,
  Activity,
  Megaphone,
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
  "messages",
];
const items = [
  ["", "Overview", LayoutGrid],
  ["readers", "Readers", Users],
  ["catalogue", "Engagement", Activity],
  ["extensions", "Extensions", Puzzle],
  ["community", "Community", MessageCircle],
  ["reports", "Reports", Flag],
  ["team", "Team & access", Shield],
  ["messages", "System messages", Megaphone],
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
