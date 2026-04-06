"use client";

import type { AttendeeDetail } from "@/lib/types";

import { InlineMessage, StatusBadge } from "@/components/common";
import { resolvedAttendeeStatusText, resolvedProfileNote } from "@/lib/utils";

interface HistoryDetailModalProps {
  open: boolean;
  detail: AttendeeDetail | null;
  loading: boolean;
  error: string | null;
  onClose: () => void;
}

export function HistoryDetailModal({
  open,
  detail,
  loading,
  error,
  onClose,
}: HistoryDetailModalProps) {
  if (!open) {
    return null;
  }

  return (
    <div className="modal-backdrop" role="presentation">
      <div aria-modal="true" className="modal" role="dialog">
        <div className="modal__header">
          <h2>Attendee Detail</h2>
          <button className="button button--secondary" onClick={onClose} type="button">
            Close
          </button>
        </div>
        {loading ? <InlineMessage>Loading attendee detail…</InlineMessage> : null}
        {error ? <InlineMessage tone="error">{error}</InlineMessage> : null}
        {detail ? (
          <div className="detail-grid">
            <div className="detail-grid__hero">
              {detail.imageUrl ? (
                <img alt={detail.name} className="detail-grid__avatar" src={detail.imageUrl} />
              ) : (
                <div className="detail-grid__avatar detail-grid__avatar--fallback">{detail.name[0]}</div>
              )}
              <div>
                <StatusBadge status={detail.status} />
                <h3>{detail.name}</h3>
                <p>{detail.role}</p>
              </div>
            </div>
            <div className="detail-grid__rows">
              <DetailRow label="Organization" value={detail.organization} />
              <DetailRow label="Email" value={detail.email} />
              <DetailRow label="Location" value={detail.location} />
              <DetailRow
                label="Attendee status"
                value={resolvedAttendeeStatusText(detail.status, detail.note)}
              />
              {resolvedProfileNote(detail.status, detail.note) ? (
                <DetailRow
                  label="Profile note"
                  value={resolvedProfileNote(detail.status, detail.note)!}
                />
              ) : null}
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}

function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="detail-row">
      <span className="eyebrow">{label}</span>
      <strong>{value}</strong>
    </div>
  );
}
