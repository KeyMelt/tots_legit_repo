import type { Metadata } from "next";
import { Manrope, Space_Grotesk } from "next/font/google";
import type { ReactNode } from "react";

import "@/app/globals.css";

const spaceGrotesk = Space_Grotesk({
  subsets: ["latin"],
  variable: "--font-display",
});

const manrope = Manrope({
  subsets: ["latin"],
  variable: "--font-body",
});

export const metadata: Metadata = {
  title: "Synthetic Eye",
  description: "Vercel-safe hackathon frontend for biometric attendee verification.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  return (
    <html className={`${spaceGrotesk.variable} ${manrope.variable}`} lang="en">
      <body>{children}</body>
    </html>
  );
}
