"use client";

import type { ReactNode } from "react";

import { AppShell } from "@/components/app-shell";
import { SessionGuard } from "@/components/session-guard";

export default function ShellLayout({
  children,
}: {
  children: ReactNode;
}) {
  return (
    <SessionGuard>
      <AppShell>{children}</AppShell>
    </SessionGuard>
  );
}
