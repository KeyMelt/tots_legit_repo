"use client";

import Link from "next/link";

import { MetricCard, Panel, PrimaryButton, SecondaryButton, StatusBadge } from "@/components/common";
import type { ScanResult } from "@/lib/types";
import {
  formatConfidence,
  resolvedAttendeeStatusText,
  resolvedProfileNote,
  sourceLabels,
  statusMeta,
} from "@/lib/utils";

export function ResultView({ result }: { result: ScanResult }) {
  const meta = statusMeta[result.status];

  return (
    <main className="result-page">
      <div className="result-page__header">
        <SecondaryButton href="/scan">Back To Scan</SecondaryButton>
        <StatusBadge status={result.status} />
      </div>

      <div className="result-hero">
        <div className="result-hero__badge" style={{ borderColor: meta.color }}>
          <span aria-hidden="true" style={{ backgroundColor: meta.color }} />
        </div>
        <p className="eyebrow" style={{ color: meta.color }}>
          Match confidence: {formatConfidence(result.confidence)}
        </p>
        <h1>{meta.resultTitle}</h1>
        <p>{meta.resultDescription}</p>
      </div>

      <Panel>
        <div className="result-profile">
          {result.detail.imageUrl ? (
            <img alt={result.detail.name} className="result-profile__image" src={result.detail.imageUrl} />
          ) : (
            <div className="result-profile__image result-profile__image--fallback">
              {result.detail.name[0]}
            </div>
          )}
          <div>
            <h2>{result.detail.name}</h2>
            <p>{result.detail.role}</p>
          </div>
        </div>
        <div className="result-metrics">
          <MetricCard label="Source" value={sourceLabels[result.source]} />
          <MetricCard label="Confidence" value={formatConfidence(result.confidence)} accent={meta.color} />
        </div>
        <div className="result-note">
          <span className="eyebrow" style={{ color: meta.color }}>
            Attendee status
          </span>
          <p>{resolvedAttendeeStatusText(result.status, result.detail.note)}</p>
        </div>
        {resolvedProfileNote(result.status, result.detail.note) ? (
          <div className="result-note">
            <span className="eyebrow">Profile note</span>
            <p>{resolvedProfileNote(result.status, result.detail.note)}</p>
          </div>
        ) : null}
        {result.summary ? (
          <div className="result-summary">
            <span className="eyebrow">Summary</span>
            <p>
              {result.summary.faceCount} face(s), {result.summary.acceptedCount} accepted,{" "}
              {result.summary.rejectedCount} rejected, {result.summary.unknownCount} unknown.
            </p>
            {result.summary.matches.length > 0 ? (
              <ul className="result-summary__matches">
                {result.summary.matches.map((match, index) => (
                  <li key={`${match.name}-${index}`}>
                    <span>{match.name}</span>
                    <span>{formatConfidence(match.confidence)}</span>
                  </li>
                ))}
              </ul>
            ) : null}
          </div>
        ) : null}
      </Panel>

      <div className="result-page__actions">
        {result.status === "unknown" ? (
          <PrimaryButton href="/enroll">Enroll Unknown Guests</PrimaryButton>
        ) : (
          <PrimaryButton href="/history">View History</PrimaryButton>
        )}
        <SecondaryButton href={result.status === "unknown" ? "/scan" : "/scan"}>
          {result.status === "unknown" ? "Scan Again" : "Back To Scan"}
        </SecondaryButton>
      </div>

      <p className="result-page__footnote">
        Need to verify the saved profile directly? Open the history view for the latest backend-backed record.
      </p>
      <Link className="result-page__history-link" href="/history">
        Open history
      </Link>
    </main>
  );
}
