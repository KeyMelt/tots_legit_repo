"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState, type ReactNode } from "react";

import { AppMark } from "@/components/common";
import { clearDemoSession, getDemoSession } from "@/lib/session";

const navigationItems = [
  { href: "/scan", label: "Scan" },
  { href: "/history", label: "History" },
  { href: "/settings", label: "Settings" },
];

export function AppShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [operatorName, setOperatorName] = useState("Operator");

  useEffect(() => {
    const session = getDemoSession();
    setOperatorName(session?.name || "Operator");
  }, []);

  return (
    <div className="shell">
      <header className="shell__header">
        <AppMark />
        <div className="shell__actions">
          <div className="shell__operator">
            <img
              alt="Operator avatar"
              className="shell__avatar"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuAu8LtAqsYCESoQV-UVx44frWqs5WotZi2SfNXPx2j9skrVWlXSDbFfyYh-0u7y4-gbnuMhp4bY8WByFqmy9_qaWWo1jMvNc0ts6-YrqS30yAbtDIMsgesQkWHbC42_K_nM8VFVZannG-gx__MWJo7AjF2rXn_7gor0-t500YVQ6uG1NUYSUWfVFxi0kOFP9105j-lve0Q10UrhzOVxjvNDxfS9Jwn9Nq_O8GEgT70OGxdIz9wQdi0-Z-tzEhHwIW0QIgvqTY5joqW0"
            />
            <div>
              <p className="eyebrow">Signed in</p>
              <strong>{operatorName}</strong>
            </div>
          </div>
          <button
            className="button button--secondary"
            onClick={() => {
              clearDemoSession();
              router.replace("/login");
            }}
            type="button"
          >
            Log out
          </button>
        </div>
      </header>
      <main className="shell__content">{children}</main>
      <nav className="shell__nav" aria-label="Primary">
        {navigationItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              className={`shell__nav-link ${isActive ? "shell__nav-link--active" : ""}`}
              href={item.href}
              key={item.href}
            >
              {item.label}
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
