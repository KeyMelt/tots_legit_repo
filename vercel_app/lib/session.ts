"use client";

const SESSION_KEY = "synthetic-eye-demo-session";

export interface DemoSession {
  name: string;
  email: string;
}

export function getDemoSession(): DemoSession | null {
  if (typeof window === "undefined") {
    return null;
  }
  const raw = window.localStorage.getItem(SESSION_KEY);
  if (!raw) {
    return null;
  }
  try {
    return JSON.parse(raw) as DemoSession;
  } catch {
    window.localStorage.removeItem(SESSION_KEY);
    return null;
  }
}

export function saveDemoSession(session: DemoSession): void {
  window.localStorage.setItem(SESSION_KEY, JSON.stringify(session));
}

export function clearDemoSession(): void {
  window.localStorage.removeItem(SESSION_KEY);
}
