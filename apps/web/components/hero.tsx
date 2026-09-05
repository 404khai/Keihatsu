"use client";

import { useRef } from "react";
import Image from "next/image";
import Link from "next/link";
import { motion, useScroll, useTransform } from "framer-motion";
import { BookOpen, Download, MessageCircle, Search } from "lucide-react";
import { Button } from "@/components/ui/button";

const storyTabs = [
  {
    number: "01",
    title: "Search before the urge fades",
    copy: "Keihatsu pulls from your in-built extensions so the next chapter is never buried behind repo hunting.",
    icon: Search,
  },
  {
    number: "02",
    title: "Read in a quieter room",
    copy: "A focused reader, offline downloads, and tuned layouts keep the panel flow feeling calm and deliberate.",
    icon: BookOpen,
  },
  {
    number: "03",
    title: "Stay close to the fandom",
    copy: "Comments and Discord keep the social layer nearby without turning reading into another noisy feed.",
    icon: MessageCircle,
  },
];

export function Hero() {
  const mockupRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: mockupRef,
    offset: ["start end", "end start"],
  });
  const mockupY = useTransform(scrollYProgress, [0, 0.55, 1], [120, 0, -40]);
  const mockupScale = useTransform(scrollYProgress, [0, 0.55, 1], [0.9, 1, 0.98]);
  const mockupOpacity = useTransform(scrollYProgress, [0, 0.25], [0, 1]);

  return (
    <section id="reader" className="relative overflow-hidden pb-24 pt-32 md:pt-40">
      <div className="absolute inset-x-0 top-0 h-[610px] overflow-hidden md:h-[720px]">
        <Image
          src="/heroBg.jpg"
          alt="Hero background"
          fill
          priority
          className="object-cover object-center opacity-95 mix-blend-darken saturate-130"
        />
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_90%_70%_at_50%_18%,transparent_0%,rgb(250_255_253/0.12)_42%,rgb(250_255_253/0.38)_100%)]" />
        <div className="absolute inset-x-0 bottom-0 h-40 bg-gradient-to-b from-transparent to-background" />
      </div>
      <div className="soft-grid absolute inset-x-0 top-10 h-[620px] opacity-70" />
      <div className="absolute left-1/2 top-40 h-72 w-72 -translate-x-1/2 rounded-full bg-accent/35 blur-3xl" />

      <div className="site-shell relative z-10 text-center">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
        >
          <p className="mx-auto mb-6 flex w-fit items-center gap-2 rounded-full border border-foreground/10 bg-white/70 px-4 py-2 text-xs font-medium uppercase tracking-[0.22em] text-foreground/70 shadow-sm backdrop-blur">
            <span className="h-2 w-2 rounded-full bg-accent shadow-[0_0_18px_rgb(159_211_86/0.9)]" />
            The cross-platform manhwa reader app
          </p>
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1], delay: 0.1 }}
          className="mx-auto max-w-5xl text-balance font-serif-display text-6xl font-semibold leading-[0.92] tracking-[-0.045em] text-black/70 sm:text-7xl md:text-8xl lg:text-9xl"
        >
          Manhwa reading,
          <span className="block text-foreground/65">with a little hush.</span>
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1], delay: 0.2 }}
          className="mx-auto mt-8 max-w-2xl text-pretty text-lg leading-8 text-foreground/85 md:text-xl"
        >
          Keihatsu is a cross-platform social manhwa reader shaped for focus, fast search, offline chapters, soft customization, and a community layer that knows when to stay out of the way.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1], delay: 0.3 }}
          className="mt-12 flex flex-col items-center justify-center gap-4 sm:flex-row"
        >
          <Button
            asChild
            size="lg"
            className="h-14 rounded-full bg-foreground px-8 text-background shadow-[0_18px_44px_rgb(52_46_55/0.24)] transition-all duration-300 hover:-translate-y-0.5 hover:bg-foreground/90 active:scale-[0.98]"
          >
            <a href="https://github.com/grvt8/Keihatsu/releases/download/v1.0.0/keihatsu-v1.0.0.apk" download>
              <Download className="w-4 h-4 mr-2" />
              Download App
            </a>
          </Button>

          <Link href="https://github.com/grvt8/Keihatsu">
            <Button
              variant="outline"
              size="lg"
              className="h-14 cursor-pointer rounded-full border-foreground/10 bg-white/60 px-8 text-foreground shadow-sm backdrop-blur transition-all duration-300 hover:-translate-y-0.5 hover:bg-white active:scale-[0.98]"
            >
              View on GitHub  
            </Button>
          </Link>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1], delay: 0.45 }}
          className="sticky top-28 z-20 mx-auto mt-16 grid max-w-4xl gap-3 rounded-[2rem] border border-foreground/10 bg-white/70 p-2 text-left shadow-[0_28px_80px_rgb(52_46_55/0.14)] backdrop-blur-2xl md:grid-cols-3"
        >
          {storyTabs.map((tab, index) => (
            <motion.article
              key={tab.title}
              initial={{ opacity: 0, y: 18 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.55, delay: index * 0.08, ease: [0.22, 1, 0.36, 1] }}
              className="group rounded-[1.5rem] p-5 transition-all duration-500 hover:bg-white hover:shadow-[0_16px_50px_rgb(52_46_55/0.1)]"
            >
              <div className="mb-7 flex items-center justify-between">
                <span className="font-serif-display text-4xl font-semibold leading-none text-foreground/35">
                  {tab.number}
                </span>
                <tab.icon className="h-5 w-5 text-foreground/35 transition-colors duration-500 group-hover:text-accent-foreground" />
              </div>
              <h2 className="font-serif-display text-2xl font-semibold leading-none tracking-tight text-foreground">
                {tab.title}
              </h2>
              <p className="mt-3 text-sm leading-6 text-muted-foreground">
                {tab.copy}
              </p>
            </motion.article>
          ))}
        </motion.div>

        <motion.div
          ref={mockupRef}
          style={{ y: mockupY, scale: mockupScale, opacity: mockupOpacity }}
          className="mockup-mask relative mx-auto mt-24 max-w-[980px] pb-10 pt-4"
        >
          <div className="absolute inset-x-10 top-24 h-64 rounded-full bg-accent/40 blur-3xl" />
          <div className="glass-panel relative mx-auto w-fit rounded-[3rem] p-3">
            <div className="overflow-hidden rounded-[2.35rem]">
              <Image
                src="/mockups/homeScreen.png"
                alt="Keihatsu app home screen"
                width={420}
                height={900}
                priority
                className="h-auto w-[min(78vw,420px)]"
              />
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
