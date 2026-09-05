"use client";

import React from "react"
import Image from "next/image";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Download } from "lucide-react";
import { cn } from "@/lib/utils";

const navLinks = [
  { label: "Home", href: "#reader" },
  { label: "Features", href: "#features" },
  { label: "GitHub", href: "https://github.com/grvt8/Keihatsu" },
  { label: "Community", href: "#community" },
];

export function Navbar() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    handleScroll();
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <motion.header
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
      className={cn(
        "fixed left-0 right-0 top-0 z-50 transition-all duration-500",
        scrolled
          ? "bg-white/45 backdrop-blur-2xl"
          : "bg-transparent"
      )}
    >
      <nav
        className={cn(
          "flex h-16 w-full items-center justify-between px-5 transition-all duration-500 md:px-40",
          scrolled && "shadow-[inset_0_-1px_0_rgb(255_255_255/0.32)]"
        )}
      >
        <a
          href="/"
          className="flex items-center transition-opacity duration-300 hover:opacity-80"
        >
          <Image
            src="/logo.png"
            alt="Keihatsu logo"
            width={100}
            height={100}
            className="h-20 w-20 object-contain"
          />
          <span
            className={cn(
              "text-2xl font-serif font-medium tracking-[-0.03em] transition-colors duration-500",
              scrolled ? "text-foreground" : "text-white"
            )}
          >
            Keihatsu
          </span>
        </a>

        <div className="hidden items-center gap-7 md:flex">
          {navLinks.map((link) => (
            <NavLink key={link.href} href={link.href} scrolled={scrolled}>
              {link.label}
            </NavLink>
          ))}
        </div>

        <a
          href="https://github.com/grvt8/Keihatsu/releases/download/v1.0.0/keihatsu-v1.0.0.apk"
          className="hidden items-center gap-2 rounded-full bg-white px-5 py-2.5 text-sm font-semibold text-foreground shadow-[0_12px_30px_rgb(52_46_55/0.16)] ring-1 ring-foreground/8 transition-all duration-300 hover:-translate-y-0.5 hover:bg-background md:inline-flex"
          download
        >
          <Download className="h-4 w-4" />
          Download
        </a>

        <MobileMenuButton />
      </nav>
    </motion.header>
  );
}

function NavLink({
  href,
  children,
  scrolled,
}: {
  href: string;
  children: React.ReactNode;
  scrolled: boolean;
}) {
  return (
    <a
      href={href}
      className={cn(
        "text-sm font-medium transition-colors duration-500",
        scrolled ? "text-foreground hover:text-foreground/80" : "text-white hover:text-white/80"
      )}
    >
      {children}
    </a>
  );
}

function MobileMenuButton() {
  const [open, setOpen] = useState(false);

  return (
    <div className="md:hidden">
      <button
        type="button"
        onClick={() => setOpen(!open)}
        className="rounded-full border border-foreground/10 bg-white/72 p-2 text-foreground shadow-sm backdrop-blur transition-colors hover:bg-white"
        aria-label="Toggle menu"
      >
        <svg
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.5"
        >
          <motion.line
            x1="4"
            y1="8"
            x2="20"
            y2="8"
            animate={{ rotate: open ? 45 : 0, y: open ? 4 : 0 }}
            style={{ transformOrigin: "center" }}
          />
          <motion.line
            x1="4"
            y1="16"
            x2="20"
            y2="16"
            animate={{ rotate: open ? -45 : 0, y: open ? -4 : 0 }}
            style={{ transformOrigin: "center" }}
          />
        </svg>
      </button>

      <motion.div
        initial={false}
        animate={{
          opacity: open ? 1 : 0,
          height: open ? "auto" : 0,
        }}
        transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
        className={cn(
          "absolute left-3 right-3 top-[calc(100%+0.5rem)] overflow-hidden rounded-3xl border border-foreground/10 bg-white/90 shadow-2xl shadow-foreground/10 backdrop-blur-xl",
          !open && "pointer-events-none"
        )}
      >
        <div className="flex flex-col gap-2 px-4 py-4">
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              onClick={() => setOpen(false)}
              className="rounded-2xl px-4 py-3 text-muted-foreground transition-colors hover:bg-surface-2 hover:text-foreground"
            >
              {link.label}
            </a>
          ))}
          <a
            href="https://github.com/grvt8/Keihatsu/releases/download/v1.0.0/keihatsu-v1.0.0.apk"
            onClick={() => setOpen(false)}
            className="rounded-2xl bg-foreground px-4 py-3 text-center text-background"
            download
          >
            Download
          </a>
        </div>
      </motion.div>
    </div>
  );
}
