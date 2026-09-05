"use client";

import React from "react"

import { motion } from "framer-motion";
import {
  Code2,
  Users,
  BookOpen,
  Palette,
  WifiOff,
  Cloud,
} from "lucide-react";
import { cn } from "@/lib/utils";

const features = [
  {
    icon: Code2,
    title: "Open Source",
    description: "Built in the open. Contribute, fork, or simply learn from the codebase.",
    className: "md:col-span-2",
  },
  {
    icon: Users,
    title: "Vibrant Community",
    description: "Join thousands of readers and creators shaping the future of manwha.",
    className: "md:col-span-1",
  },
  {
    icon: BookOpen,
    title: "Immersive Reader",
    description: "A reading experience designed to disappear, letting the story take center stage.",
    className: "md:col-span-1",
  },
  {
    icon: Palette,
    title: "Custom UI & Themes",
    description: "Make it yours. Adjust colors, typography, and layout to match your preferences.",
    className: "md:col-span-2",
  },
  {
    icon: WifiOff,
    title: "Offline Reading",
    description: "Download chapters and read anywhere, no connection required.",
    className: "md:col-span-2",
  },
  {
    icon: Cloud,
    title: "Cloud Sync",
    description: "Your progress, bookmarks, and settings follow you across all devices.",
    className: "md:col-span-1",
  },
];

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.6,
      ease: [0.22, 1, 0.36, 1],
    },
  },
};

export function BentoFeatures() {
  return (
    <section id="features" className="relative py-28">
      <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-foreground/10 to-transparent" />
      <div className="site-shell">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
          className="mb-16 text-center"
        >
          <p className="mb-4 text-sm font-medium uppercase tracking-[0.25em] text-muted-foreground">
            Features
          </p>
          <h2 className="text-balance font-serif-display text-5xl font-semibold leading-[0.95] tracking-[-0.035em] text-foreground md:text-6xl lg:text-7xl">
            Everything you need,
            <br />
            <span className="text-foreground/45">nothing you don&apos;t.</span>
          </h2>
        </motion.div>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-100px" }}
          className="grid grid-cols-1 gap-4 md:grid-cols-3"
        >
          {features.map((feature) => (
            <FeatureCard key={feature.title} {...feature} />
          ))}
        </motion.div>
      </div>
    </section>
  );
}

function FeatureCard({
  icon: Icon,
  title,
  description,
  className,
}: {
  icon: React.ElementType;
  title: string;
  description: string;
  className?: string;
}) {
  return (
    <motion.div
      variants={itemVariants as any}
      className={cn(
        "group relative overflow-hidden rounded-[2rem] border border-foreground/10 bg-white/68 p-8",
        "shadow-[0_20px_70px_rgb(52_46_55/0.08)] backdrop-blur transition-all duration-500 ease-out",
        "hover:-translate-y-1 hover:bg-white hover:shadow-[0_28px_90px_rgb(52_46_55/0.14)]",
        className
      )}
    >
      <div className="flex flex-col h-full relative z-10">
        <div className="mb-10 w-fit rounded-2xl border border-foreground/10 bg-accent/20 p-3 transition-colors duration-500 group-hover:bg-accent">
          <Icon className="h-5 w-5 text-foreground transition-colors duration-500" />
        </div>

        <h3 className="mb-3 font-serif-display text-3xl font-semibold leading-none tracking-tight text-foreground transition-transform duration-500 group-hover:translate-x-0.5">
          {title}
        </h3>
        <p className="text-sm leading-6 text-muted-foreground transition-transform duration-500 group-hover:translate-x-0.5">
          {description}
        </p>
      </div>

      <div className="pointer-events-none absolute -bottom-8 -right-8">
        <Icon 
          className="h-36 w-36 text-accent/20 transition-all duration-500 group-hover:scale-110 group-hover:text-accent/35" 
          strokeWidth={1}
        />
      </div>

      
    </motion.div>
  );
}
