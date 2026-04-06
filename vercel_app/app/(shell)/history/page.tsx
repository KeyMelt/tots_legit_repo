"use client";

import { useEffect, useState } from "react";

import { HistoryDetailModal } from "@/components/history-detail-modal";
import { InlineMessage, Panel, StatusBadge } from "@/components/common";
import { getAttendeeDetail, listAttendees } from "@/lib/api";
import type { AttendeeDetail, AttendeeSummary, HistoryFilter } from "@/lib/types";
import { formatClock, formatConfidence, historyFilterLabels, historyFilters } from "@/lib/utils";

export default function HistoryPage() {
  const [filter, setFilter] = useState<HistoryFilter>("all");
  const [records, setRecords] = useState<AttendeeSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [selectedDetail, setSelectedDetail] = useState<AttendeeDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);
    void listAttendees(filter)
      .then((nextRecords) => {
        setRecords(nextRecords);
      })
      .catch((historyError: Error) => {
        setError(historyError.message);
        setRecords([]);
      })
      .finally(() => setLoading(false));
  }, [filter]);

  useEffect(() => {
    if (!selectedId) {
      return;
    }
    setDetailLoading(true);
    setDetailError(null);
    void getAttendeeDetail(selectedId)
      .then(setSelectedDetail)
      .catch((historyError: Error) => setDetailError(historyError.message))
      .finally(() => setDetailLoading(false));
  }, [selectedId]);

  return (
    <div className="screen-grid">
      <Panel
        subtitle="Review backend-backed scan events and open each attendee detail on demand."
        title="Scan History"
      >
        <div className="filter-row" role="tablist">
          {historyFilters.map((entry) => (
            <button
              className={`filter-chip ${entry === filter ? "filter-chip--active" : ""}`}
              key={entry}
              onClick={() => setFilter(entry)}
              type="button"
            >
              {historyFilterLabels[entry]}
            </button>
          ))}
        </div>
        {loading ? <InlineMessage>Loading scan history…</InlineMessage> : null}
        {error ? <InlineMessage tone="error">{error}</InlineMessage> : null}
        {!loading && !error && records.length === 0 ? (
          <InlineMessage>No scan history is available for this filter.</InlineMessage>
        ) : null}
        <div className="history-list">
          {records.map((record) => (
            <button
              className="history-item"
              key={`${record.id}-${record.scannedAt}`}
              onClick={() => {
                setSelectedId(record.id);
                setSelectedDetail(null);
              }}
              type="button"
            >
              <div className="history-item__left">
                {record.imageUrl ? (
                  <img alt={record.name} className="history-item__avatar" src={record.imageUrl} />
                ) : (
                  <div className="history-item__avatar history-item__avatar--fallback">
                    {record.name[0]}
                  </div>
                )}
                <div>
                  <strong>{record.name}</strong>
                  <p>
                    {record.role} · {record.location}
                  </p>
                </div>
              </div>
              <div className="history-item__right">
                <StatusBadge status={record.status} />
                <span>{formatClock(record.scannedAt)}</span>
                <span>{formatConfidence(record.confidence)}</span>
              </div>
            </button>
          ))}
        </div>
      </Panel>
      <HistoryDetailModal
        detail={selectedDetail}
        error={detailError}
        loading={detailLoading}
        onClose={() => {
          setSelectedId(null);
          setSelectedDetail(null);
          setDetailError(null);
        }}
        open={Boolean(selectedId)}
      />
    </div>
  );
}
