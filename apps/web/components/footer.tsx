"use client";

import Image from "next/image";
import { motion } from "framer-motion";

const footerGroups = [
  {
    title: "Menu",
    links: [
      { label: "Home", href: "#reader" },
      { label: "Features", href: "#features" },
      { label: "Community", href: "#community" },
      { label: "Download", href: "https://github.com/grvt8/Keihatsu/releases/download/v1.0.0/keihatsu-v1.0.0.apk" },
    ],
  },
  {
    title: "Project",
    links: [
      { label: "GitHub", href: "https://github.com/grvt8/Keihatsu" },
      { label: "Discord", href: "https://discord.gg/8cu84svT" },
      { label: "Privacy", href: "#" },
      { label: "Terms", href: "#" },
    ],
  },
  {
    title: "Reader",
    links: [
      { label: "Offline library", href: "#features" },
      { label: "Extensions", href: "#features" },
      { label: "Open source", href: "#opensource" },
      { label: "Reader themes", href: "#features" },
    ],
  },
];

export function Footer() {
  return (
    <motion.footer
      initial={{ opacity: 0 }}
      whileInView={{ opacity: 1 }}
      viewport={{ once: true }}
      transition={{ duration: 0.6 }}
      className="relative mt-20 min-h-[640px] w-full overflow-hidden rounded-t-[2rem] text-foreground md:min-h-[720px] md:rounded-t-[2.5rem]"
    >
      <Image
        src="/footerBg.jpg"
        alt=""
        fill
        sizes="100vw"
        className="object-cover object-center"
      />
      <div className="absolute inset-0 bg-[linear-gradient(180deg,rgb(250_255_253/0.92)_0%,rgb(250_255_253/0.58)_30%,rgb(52_46_55/0.08)_62%,rgb(52_46_55/0.22)_100%)]" />
      <div className="absolute inset-x-0 top-0 h-48 bg-gradient-to-b from-background to-transparent" />

      <div className="relative z-10 grid gap-12 px-[8vw] pb-16 pt-16 md:grid-cols-[1.35fr_1fr_1fr_1fr] md:gap-16 md:pt-20">
        <div className="max-w-sm space-y-5">
          <div className="flex items-center">
            <Image
              src="/logo.png"
              alt="Keihatsu logo"
              width={100}
              height={100}
              className="h-20 w-20 object-contain"
            />
            <span className="text-xl font-serif font-medium tracking-[-0.03em]">
              Keihatsu
            </span>
          </div>

          <div className="space-y-3">
            <h2 className="font-serif-display text-3xl font-semibold leading-none tracking-[-0.04em] md:text-4xl">
              Your quiet second shelf.
            </h2>
            <p className="text-sm leading-6 text-foreground/90">
              Search, save, and read manhwa in a polished app built to keep the story in front.
            </p>
          </div>

          <a
            href="https://github.com/grvt8/Keihatsu/releases/download/v1.0.0/keihatsu-v1.0.0.apk"
            className="inline-flex rounded-xl bg-foreground px-4 py-3 text-sm font-semibold text-background shadow-[0_14px_34px_rgb(52_46_55/0.18)] transition-transform duration-300 hover:-translate-y-0.5"
            download
          >
            Download for Android
          </a>

          <p className="text-xs md:text-white text-foreground">
            © {new Date().getFullYear()} Keihatsu. Open source under MIT.
          </p>
        </div>

        {footerGroups.map((group) => (
          <nav key={group.title} className="space-y-5">
            <h3 className="text-sm font-semibold md:font-bold tracking-[-0.03em] md:text-foreground text-background">
              {group.title}
            </h3>
            <div className="space-y-3">
              {group.links.map((link) => (
                  <a
                    key={link.label}
                    href={link.href}
                    className="block text-sm text-white/85 hover:text-white md:text-foreground/70 md:hover:text-foreground transition-colors duration-300 "
                  >
                    {link.label}
                  </a>
              ))}
            </div>
          </nav>
        ))}
      </div>

      <div className="pointer-events-none absolute inset-x-0 bottom-[-1.2vw] z-10 overflow-hidden px-[7vw]">
        <p className="select-none font-serif-display text-[22vw] font-bold leading-[0.68] tracking-[-0.04em] text-background/82 drop-shadow-[0_8px_40px_rgb(52_46_55/0.12)] md:text-[17vw]">
          Keihatsu
        </p>
      </div>
    </motion.footer>
  );
}
