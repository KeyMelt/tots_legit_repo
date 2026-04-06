"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState, type ReactNode } from "react";

import { getDemoSession } from "@/lib/session";

export function SessionGuard({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const session = getDemoSession();
    if (!session) {
      router.replace("/login");
      return;
    }
    setReady(true);
  }, [router]);

  if (!ready) {
    return (
      <main className="centered-state">
        <div className="loading-dot" />
        <p>Checking operator access…</p>
      </main>
    );
  }

  return <>{children}</>;
}
