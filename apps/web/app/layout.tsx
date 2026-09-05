import React from "react"
import type { Metadata } from 'next'
import { Cormorant_Garamond, Henny_Penny, Inter } from 'next/font/google'
import { Analytics } from '@vercel/analytics/next'
import './globals.css'

const inter = Inter({ 
  subsets: ["latin"],
  variable: '--font-inter'
});

const hennyPenny = Henny_Penny({ 
  weight: "400",
  subsets: ["latin"],
  variable: '--font-henny-penny'
});

const cormorant = Cormorant_Garamond({
  subsets: ["latin"],
  variable: "--font-cormorant",
  weight: ["400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: 'Keihatsu - The social manhwa reader app',
  description: 'Keihatsu is a cross-platform social manhwa reader shaped for focus, fast search, offline chapters, soft customization, and a community layer that knows when to stay out of the way.',
  generator: 'v0.app',
  icons: {
    icon: [
      {
        url: '/icon-light-32x32.png',
        media: '(prefers-color-scheme: light)',
      },
      {
        url: '/icon-dark-32x32.png',
        media: '(prefers-color-scheme: dark)',
      },
      {
        url: '/icon.svg',
        type: 'image/svg+xml',
      },
    ],
    apple: '/apple-icon.png',
  },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en">
      <body className={`${inter.variable} ${hennyPenny.variable} ${cormorant.variable} font-sans antialiased bg-background text-foreground`}>
        {children}
        <Analytics />
      </body>
    </html>
  )
}
