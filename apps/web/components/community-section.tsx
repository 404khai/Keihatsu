"use client";

import { motion } from "framer-motion";
import { Github, Users, GitFork, Star } from "lucide-react";
import { Badge } from "@/components/ui/badge";

const stats = [
  { icon: Star, label: "GitHub Stars", value: "2.4k" },
  { icon: GitFork, label: "Forks", value: "340" },
  { icon: Users, label: "Contributors", value: "85" },
];

export function CommunitySection() {
  return (
    <section id="community" className="relative py-28">
      <div className="absolute inset-x-0 top-24 h-80 bg-[radial-gradient(circle_at_center,rgb(159_211_86/0.24),transparent_58%)]" />
      <div className="site-shell relative">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
          className="mb-16 text-center"
        >
          <p className="mb-4 text-sm font-medium uppercase tracking-[0.25em] text-muted-foreground">
            Community
          </p>
          <h2 className="text-balance font-serif-display text-5xl font-semibold leading-[0.95] tracking-[-0.035em] text-foreground md:text-6xl lg:text-7xl">
            Built together,
            <br />
            <span className="text-foreground/45">growing together.</span>
          </h2>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1], delay: 0.1 }}
          className="grid gap-6 md:grid-cols-2"
        >
          <div
            id="opensource"
            className="glass-panel space-y-8 rounded-[2.25rem] p-8 md:p-10"
          >
            <div className="flex items-center gap-3">
              <div className="rounded-2xl border border-foreground/10 bg-accent/25 p-3">
                <Github className="w-5 h-5 text-foreground" />
              </div>
              <Badge
                variant="secondary"
                className="rounded-full border-none bg-white/70 text-muted-foreground"
              >
                MIT License
              </Badge>
            </div>

            <div className="space-y-4">
              <h3 className="font-serif-display text-4xl font-semibold leading-none tracking-tight text-foreground">
                Open Source First
              </h3>
              <p className="text-pretty leading-7 text-muted-foreground">
                Transparency is the foundation. Every
                line of code is available for review, contribution, or learning.
                We believe the best software is built in the open.
              </p>
            </div>

            <div className="flex flex-wrap gap-6">
              {stats.map((stat) => (
                <div key={stat.label} className="flex items-center gap-3">
                  <stat.icon className="w-4 h-4 text-muted-foreground" />
                  <div>
                    <p className="font-serif-display text-3xl font-semibold leading-none text-foreground">
                      {stat.value}
                    </p>
                    <p className="text-xs text-muted-foreground">{stat.label}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="glass-panel space-y-8 rounded-[2.25rem] p-8 md:p-10">
            <div className="flex items-center gap-3">
              <div className="rounded-2xl border border-foreground/10 bg-accent/25 p-3">
                <Users className="w-5 h-5 text-foreground" />
              </div>
              <Badge
                variant="secondary"
                className="rounded-full border-none bg-white/70 text-muted-foreground"
              >
                Active Discord
              </Badge>
            </div>

            <div className="space-y-4">
              <h3 className="font-serif-display text-4xl font-semibold leading-none tracking-tight text-foreground">
                Shaped by Readers
              </h3>
              <p className="text-pretty leading-7 text-muted-foreground">
                Every feature request, bug report, and suggestion shapes what
                Keihatsu becomes. Join our Discord to discuss, contribute ideas,
                and connect with fellow enthusiasts.
              </p>
            </div>

            <div className="flex flex-wrap gap-2">
              {["Feature Requests", "Bug Reports", "Translations", "Design"].map(
                (tag) => (
                  <span
                    key={tag}
                    className="rounded-full border border-foreground/10 bg-white/70 px-3 py-1.5 text-xs text-muted-foreground"
                  >
                    {tag}
                  </span>
                )
              )}
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
