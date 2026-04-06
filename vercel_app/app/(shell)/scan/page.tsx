"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, useRef, useState } from "react";

import { CameraPanel } from "@/components/camera-panel";
import { InlineMessage, MetricCard, Panel } from "@/components/common";
import { healthCheck, submitScan } from "@/lib/api";
import { encodeResultPayload } from "@/lib/result-payload";
import type { HealthResponse } from "@/lib/types";

export default function ScanPage() {
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const router = useRouter();
  const searchParams = useSearchParams();
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [busy, setBusy] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    void healthCheck()
      .then(setHealth)
      .catch((scanError: Error) => setError(scanError.message));
  }, []);

  useEffect(() => {
    if (searchParams.get("enrolled") === "1") {
      setStatusMessage("Enrollment complete. The backend registry is ready for another scan.");
    }
  }, [searchParams]);

  async function handleScan(file: File, source: "camera" | "gallery") {
    setBusy(true);
    setError(null);
    setStatusMessage(source === "camera" ? "Submitting captured camera frame…" : "Submitting gallery image…");

    try {
      const result = await submitScan(file, source);
      const payload = encodeResultPayload(result);
      const target = new URL(`/result/${result.detail.id}`, window.location.origin);
      target.searchParams.set("payload", payload);
      target.searchParams.set("status", result.status);
      target.searchParams.set("confidence", String(result.confidence));
      target.searchParams.set("source", result.source);
      target.searchParams.set("scannedAt", result.scannedAt);
      router.push(`${target.pathname}${target.search}`);
    } catch (scanError) {
      setError(scanError instanceof Error ? scanError.message : "Unable to process this scan right now.");
      setStatusMessage(null);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="screen-grid">
      <Panel
        subtitle="Use browser capture or upload a saved photo. The backend contract remains unchanged."
        title="Scan Console"
      >
        <div className="scan-grid">
          <CameraPanel busy={busy} onCapture={(file) => handleScan(file, "camera")} />
          <div className="scan-grid__sidebar">
            <Panel
              subtitle="The current Vercel-safe web flow replaces Flutter live polling with explicit capture actions."
              title="Upload A Photo"
            >
              <button
                className="button button--primary button--full"
                disabled={busy}
                onClick={() => fileInputRef.current?.click()}
                type="button"
              >
                {busy ? "Processing..." : "Upload From Device"}
              </button>
              <input
                accept="image/*"
                className="sr-only"
                onChange={(event) => {
                  const file = event.target.files?.[0];
                  if (file) {
                    void handleScan(file, "gallery");
                  }
                  event.target.value = "";
                }}
                ref={fileInputRef}
                type="file"
              />
              <div className="stack">
                <MetricCard label="Entry point" value={health?.entrypoint ?? "Checking"} />
                <MetricCard
                  accent="var(--primary)"
                  label="Known attendees"
                  value={health ? String(health.knownAttendees) : "—"}
                />
              </div>
            </Panel>
            <Panel title="Operator Guidance">
              <ul className="bullet-list">
                <li>Capture one person at a time for the clearest result detail screen.</li>
                <li>Unknown results can be enrolled later with multiple frames per person.</li>
                <li>History and approval settings continue to come from the existing FastAPI API.</li>
              </ul>
            </Panel>
          </div>
        </div>
      </Panel>
      {statusMessage ? <InlineMessage tone="success">{statusMessage}</InlineMessage> : null}
      {error ? <InlineMessage tone="error">{error}</InlineMessage> : null}
    </div>
  );
}
