"use client";

import { useParams, useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";

import { InlineMessage } from "@/components/common";
import { ResultView } from "@/components/result-view";
import { SessionGuard } from "@/components/session-guard";
import { getAttendeeDetail } from "@/lib/api";
import { decodeResultPayload } from "@/lib/result-payload";
import type { ScanResult } from "@/lib/types";

export default function ResultPage() {
  const params = useParams<{ resultId: string }>();
  const searchParams = useSearchParams();
  const [result, setResult] = useState<ScanResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const payload = searchParams.get("payload");
    if (payload) {
      const decoded = decodeResultPayload(payload);
      if (decoded) {
        setResult(decoded);
        return;
      }
    }

    void getAttendeeDetail(params.resultId)
      .then((detail) => {
        setResult({
          detail,
          confidence: Number(searchParams.get("confidence") ?? "0"),
          scannedAt: searchParams.get("scannedAt") ?? new Date().toISOString(),
          source: (searchParams.get("source") as ScanResult["source"]) ?? "gallery",
          status: (searchParams.get("status") as ScanResult["status"]) ?? detail.status,
          summary: null,
        });
      })
      .catch((resultError: Error) => setError(resultError.message));
  }, [params.resultId, searchParams]);

  return (
    <SessionGuard>
      {error ? (
        <main className="result-page">
          <InlineMessage tone="error">{error}</InlineMessage>
        </main>
      ) : null}
      {!error && !result ? (
        <main className="result-page">
          <InlineMessage>Loading scan result…</InlineMessage>
        </main>
      ) : null}
      {result ? <ResultView result={result} /> : null}
    </SessionGuard>
  );
}
