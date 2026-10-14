"use client";

import Image from "next/image";
import { useState } from "react";

const downloadUrl =
  "https://github.com/grvt8/Keihatsu/releases/download/v1.0.0/keihatsu-v1.0.0.apk";

const navLinks = [
  { label: "Docs", href: "/docs" },
  { label: "Reader", href: "/#reader" },
  { label: "Features", href: "/#features" },
  { label: "Open source", href: "/#opensource" },
  { label: "Community", href: "/#community" },
];

export function Navbar() {
  const [open, setOpen] = useState(false);

  return (
    <header className="paper-navbar">
      <nav className="paper-navbar__inner" aria-label="Main navigation">
        <a
          className="brand-lockup font-comic tracking-tight"
          href="/#reader"
          aria-label="Keihatsu home"
        >
          <Image src="/logo.png" alt="" width={44} height={44} priority />
          <span>KEIHATSU</span>
        </a>

        <div className="paper-navbar__links">
          {navLinks.map((link) => (
            <a key={link.href} href={link.href}>
              {link.label}
            </a>
          ))}
        </div>

        <div className="paper-navbar__actions">
          <a href="https://github.com/grvt8/Keihatsu">GitHub ↗</a>
          <a className="pill-button pill-button--small" href={downloadUrl} download>
            Download app
          </a>
        </div>

        <button
          className="paper-navbar__menu"
          type="button"
          aria-expanded={open}
          aria-controls="mobile-navigation"
          aria-label="Toggle navigation"
          onClick={() => setOpen((value) => !value)}
        >
          <span />
          <span />
        </button>

        <div
          id="mobile-navigation"
          className="paper-navbar__mobile"
          data-open={open}
        >
          {navLinks.map((link) => (
            <a key={link.href} href={link.href} onClick={() => setOpen(false)}>
              {link.label}
            </a>
          ))}
          <a href="https://github.com/grvt8/Keihatsu">GitHub ↗</a>
          <a href={downloadUrl} download>
            Download app
          </a>
        </div>
      </nav>
    </header>
  );
}
