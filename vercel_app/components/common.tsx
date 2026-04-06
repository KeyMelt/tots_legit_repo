"use client";

import Link from "next/link";
import { useEffect, useState, type CSSProperties, type ReactNode } from "react";

import type { AttendeeStatus } from "@/lib/types";
import { statusMeta } from "@/lib/utils";

export function AppMark() {
  return (
    <div className="app-mark">
      <span className="app-mark__eye" aria-hidden="true">
        ◉
      </span>
      <div>
        <p className="eyebrow">Biometric Authority v2.0</p>
        <h1 className="app-mark__title">Synthetic Eye</h1>
      </div>
    </div>
  );
}

interface ButtonProps {
  children: ReactNode;
  href?: string;
  onClick?: () => void;
  disabled?: boolean;
  type?: "button" | "submit";
}

export function PrimaryButton({
  children,
  href,
  onClick,
  disabled,
  type = "button",
}: ButtonProps) {
  if (href) {
    return (
      <Link className="button button--primary" href={href}>
        {children}
      </Link>
    );
  }

  return (
    <button className="button button--primary" disabled={disabled} onClick={onClick} type={type}>
      {children}
    </button>
  );
}

export function SecondaryButton({
  children,
  href,
  onClick,
  disabled,
  type = "button",
}: ButtonProps) {
  if (href) {
    return (
      <Link className="button button--secondary" href={href}>
        {children}
      </Link>
    );
  }

  return (
    <button className="button button--secondary" disabled={disabled} onClick={onClick} type={type}>
      {children}
    </button>
  );
}

export function StatusBadge({ status }: { status: AttendeeStatus }) {
  const meta = statusMeta[status];

  return (
    <span
      className="status-badge"
      style={{
        borderColor: meta.color,
        color: meta.color,
      }}
    >
      {meta.badgeLabel}
    </span>
  );
}

export function MetricCard({
  label,
  value,
  accent,
}: {
  label: string;
  value: string;
  accent?: string;
}) {
  return (
    <div className="metric-card">
      <span className="eyebrow">{label}</span>
      <strong style={accent ? { color: accent } : undefined}>{value}</strong>
    </div>
  );
}

export function InlineMessage({
  tone = "neutral",
  children,
}: {
  tone?: "neutral" | "error" | "success";
  children: ReactNode;
}) {
  return <div className={`inline-message inline-message--${tone}`}>{children}</div>;
}

export function Panel({
  title,
  subtitle,
  children,
  action,
}: {
  title?: string;
  subtitle?: string;
  children: ReactNode;
  action?: ReactNode;
}) {
  return (
    <section className="panel">
      {(title || subtitle || action) && (
        <header className="panel__header">
          <div>
            {title ? <h2 className="panel__title">{title}</h2> : null}
            {subtitle ? <p className="panel__subtitle">{subtitle}</p> : null}
          </div>
          {action}
        </header>
      )}
      {children}
    </section>
  );
}

export function FilePreviewStrip({
  files,
  onRemove,
}: {
  files: File[];
  onRemove: (index: number) => void;
}) {
  const [urls, setUrls] = useState<string[]>([]);

  useEffect(() => {
    const nextUrls = files.map((file) => URL.createObjectURL(file));
    setUrls(nextUrls);
    return () => {
      nextUrls.forEach((url) => URL.revokeObjectURL(url));
    };
  }, [files]);

  if (files.length === 0) {
    return <InlineMessage>No frames captured yet.</InlineMessage>;
  }

  return (
    <div className="preview-strip">
      {urls.map((url, index) => (
        <div className="preview-strip__item" key={`${files[index]?.name}-${index}`}>
          <img
            alt={`Captured frame ${index + 1}`}
            className="preview-strip__image"
            src={url}
          />
          <button
            aria-label={`Remove frame ${index + 1}`}
            className="preview-strip__remove"
            onClick={() => onRemove(index)}
            type="button"
          >
            ×
          </button>
        </div>
      ))}
    </div>
  );
}
