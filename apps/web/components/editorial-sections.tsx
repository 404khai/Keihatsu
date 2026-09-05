"use client";

import { useRef } from "react";
import Image from "next/image";
import {
  motion,
  useScroll,
  useTransform,
  type MotionValue,
} from "framer-motion";

const sections = [
  {
    label: "Multi-Extension Search",
    title: "Search across all your in-built extensions",
    description:
      "No more looking for repo links to find your favorite series. Keihatsu lets you search across all your in-built extensions, so you can find what you're looking for in seconds.",
    image: "/mockups/homeScreen.png",
  },
  {
    label: "Read Anywhere",
    title: "Download and read offline",
    description:
      "Keihatsu lets you download your favorite series, so you can read them whenever you want, wherever you are.",
    image: "/mockups/readerScreen.png",
  },
  {
    label: "Join the community",
    title: "Chat with other readers",
    description:
      "Join our discord community to chat with other readers and engage with comments under each chapter of your favorite series.",
    image: "/mockups/homeScreen.png",
  },
];

export function EditorialSections() {
  const sectionRef = useRef<HTMLElement>(null);
  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start start", "end end"],
  });

  return (
    <section ref={sectionRef} className="relative h-[320vh]">
      <div className="sticky top-0 flex h-screen items-center overflow-hidden">
        <div className="site-shell grid items-center gap-12 md:grid-cols-[0.9fr_1.1fr] md:gap-20">
          <div className="relative min-h-[380px] md:min-h-[460px]">
            {sections.map((section, index) => (
              <FeatureText
                key={section.title}
                index={index}
                progress={scrollYProgress}
                {...section}
              />
            ))}
          </div>

          <div className="relative min-h-[520px] md:min-h-[680px]">
            <div className="absolute inset-10 rounded-full bg-accent/30 blur-3xl" />
            {sections.map((section, index) => (
              <FeatureImage
                key={section.image + section.title}
                index={index}
                progress={scrollYProgress}
                image={section.image}
                title={section.title}
              />
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

function FeatureText({
  label,
  title,
  description,
  index,
  progress,
}: {
  label: string;
  title: string;
  description: string;
  index: number;
  progress: MotionValue<number>;
}) {
  const opacity = useStepOpacity(progress, index);
  const y = useStepY(progress, index);
  const scale = useStepScale(progress, index);

  return (
    <motion.article
      style={{ opacity, y, scale }}
      className="absolute inset-0 flex items-center"
    >
      <div className="grid grid-cols-[2rem_1fr] gap-6">
        <ProgressBars progress={progress} />
        <div className="space-y-6">
          <p className="text-sm font-medium uppercase tracking-[0.25em] text-muted-foreground">
            {label}
          </p>
          <h3 className="max-w-xl text-balance font-serif-display text-5xl font-semibold leading-[0.95] tracking-[-0.035em] text-foreground md:text-6xl">
            {title}
          </h3>
          <p className="max-w-lg text-pretty text-lg leading-8 text-muted-foreground">
            {description}
          </p>
        </div>
      </div>
    </motion.article>
  );
}

function FeatureImage({
  image,
  title,
  index,
  progress,
}: {
  image: string;
  title: string;
  index: number;
  progress: MotionValue<number>;
}) {
  const opacity = useStepOpacity(progress, index);
  const y = useStepImageY(progress, index);
  const scale = useStepScale(progress, index);

  return (
    <motion.div
      style={{ opacity, y, scale }}
      className="absolute inset-0 flex items-center justify-center"
    >
      <div className="relative mx-auto flex aspect-[4/5] w-full max-w-sm items-start justify-center overflow-hidden rounded-[2.5rem] border border-foreground/10 bg-white/45 p-4 shadow-[0_30px_90px_rgb(52_46_55/0.14)] backdrop-blur-xl md:max-w-md">
        <Image
          src={image}
          className="h-auto w-full rounded-[2rem] shadow-[0_24px_80px_rgb(52_46_55/0.18)]"
          alt={title}
          width={440}
          height={900}
        />
      </div>
    </motion.div>
  );
}

function ProgressBars({ progress }: { progress: MotionValue<number> }) {
  return (
    <div className="flex h-48 flex-col gap-3 pt-1">
      <ProgressBar progress={progress} index={0} />
      <ProgressBar progress={progress} index={1} />
      <ProgressBar progress={progress} index={2} />
    </div>
  );
}

function ProgressBar({
  progress,
  index,
}: {
  progress: MotionValue<number>;
  index: number;
}) {
  const start = index / sections.length;
  const end = (index + 1) / sections.length;
  const opacity = useTransform(progress, [start, end], [0.35, 1]);
  const scaleY = useTransform(progress, [start, end], [0.12, 1]);

  return (
    <div className="relative h-14 w-1 overflow-hidden rounded-full bg-foreground/12">
      <motion.div
        style={{ scaleY, opacity, transformOrigin: "top" }}
        className="absolute inset-0 rounded-full bg-foreground"
      />
    </div>
  );
}

function useStepOpacity(progress: MotionValue<number>, index: number) {
  const range = getStepRange(index);
  return useTransform(progress, range, [0, 1, 1, 0]);
}

function useStepY(progress: MotionValue<number>, index: number) {
  const range = getStepRange(index);
  return useTransform(progress, range, [44, 0, 0, -44]);
}

function useStepImageY(progress: MotionValue<number>, index: number) {
  const range = getStepRange(index);
  return useTransform(progress, range, [90, 0, 0, -90]);
}

function useStepScale(progress: MotionValue<number>, index: number) {
  const range = getStepRange(index);
  return useTransform(progress, range, [0.96, 1, 1, 0.98]);
}

function getStepRange(index: number) {
  const count = sections.length;
  const start = Math.max(0, index / count - 0.08);
  const holdStart = index / count + 0.04;
  const holdEnd = (index + 1) / count - 0.08;
  const end = Math.min(1, (index + 1) / count + 0.04);

  return [start, holdStart, holdEnd, end] as [number, number, number, number];
}
