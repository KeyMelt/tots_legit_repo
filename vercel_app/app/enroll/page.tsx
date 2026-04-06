"use client";

import { useRouter } from "next/navigation";
import { useMemo, useState } from "react";

import { FilePreviewStrip, InlineMessage, Panel, PrimaryButton, SecondaryButton } from "@/components/common";
import { FrameCapturePanel } from "@/components/frame-capture-panel";
import { SessionGuard } from "@/components/session-guard";
import { enrollMembers } from "@/lib/api";
import type { EnrollmentMemberDraft } from "@/lib/types";

interface DraftCard {
  id: string;
  label: string;
  status: EnrollmentMemberDraft["status"];
  files: File[];
  cameraOpen: boolean;
}

function createDraft(): DraftCard {
  return {
    id: crypto.randomUUID(),
    label: "",
    status: "accepted",
    files: [],
    cameraOpen: false,
  };
}

export default function EnrollmentPage() {
  const router = useRouter();
  const [drafts, setDrafts] = useState<DraftCard[]>([createDraft()]);
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const totalFrames = useMemo(
    () => drafts.reduce((count, draft) => count + draft.files.length, 0),
    [drafts],
  );

  async function handleSubmit() {
    setError(null);
    setMessage(null);

    for (const draft of drafts) {
      if (!draft.label.trim()) {
        setError("Enter a label for every unknown person.");
        return;
      }
      if (draft.files.length === 0) {
        setError(`Add at least one frame for ${draft.label.trim() || "each person"}.`);
        return;
      }
    }

    setSubmitting(true);
    try {
      const result = await enrollMembers(
        drafts.map((draft) => ({
          label: draft.label.trim(),
          status: draft.status,
          files: draft.files,
        })),
      );
      setMessage(
        `Enrolled ${result.enrolledCount} member(s) with ${result.totalSavedImages} saved frame(s).`,
      );
      window.setTimeout(() => {
        router.replace("/scan?enrolled=1");
      }, 900);
    } catch (enrollError) {
      setError(enrollError instanceof Error ? enrollError.message : "Unable to enroll these members right now.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <SessionGuard>
      <main className="enrollment-page">
        <div className="enrollment-page__header">
          <SecondaryButton href="/scan">Back</SecondaryButton>
          <h1>Enroll Unknown Members</h1>
        </div>

        <Panel
          subtitle="Create one card per unknown person. Capture or upload several frames, then assign whether they belong on the approved guest list."
          title="Enrollment Batch"
        >
          <div className="settings-metrics">
            <div className="metric-card">
              <span className="eyebrow">People in batch</span>
              <strong>{drafts.length}</strong>
            </div>
            <div className="metric-card">
              <span className="eyebrow">Frames collected</span>
              <strong>{totalFrames}</strong>
            </div>
          </div>
          {message ? <InlineMessage tone="success">{message}</InlineMessage> : null}
          {error ? <InlineMessage tone="error">{error}</InlineMessage> : null}
          <div className="enrollment-list">
            {drafts.map((draft, index) => (
              <article className="enrollment-card" key={draft.id}>
                <div className="enrollment-card__header">
                  <div>
                    <p className="eyebrow">Unknown person {index + 1}</p>
                    <h2>Enrollment Card</h2>
                  </div>
                  {drafts.length > 1 ? (
                    <button
                      className="button button--secondary"
                      disabled={submitting}
                      onClick={() => {
                        setDrafts((current) => current.filter((entry) => entry.id !== draft.id));
                      }}
                      type="button"
                    >
                      Remove
                    </button>
                  ) : null}
                </div>
                <label>
                  Member label
                  <input
                    disabled={submitting}
                    onChange={(event) => {
                      setDrafts((current) =>
                        current.map((entry) =>
                          entry.id === draft.id ? { ...entry, label: event.target.value } : entry,
                        ),
                      );
                    }}
                    placeholder="Enter the member label"
                    type="text"
                    value={draft.label}
                  />
                </label>
                <div className="choice-row">
                  <label className={`choice-pill ${draft.status === "accepted" ? "choice-pill--active" : ""}`}>
                    <input
                      checked={draft.status === "accepted"}
                      disabled={submitting}
                      name={`status-${draft.id}`}
                      onChange={() => {
                        setDrafts((current) =>
                          current.map((entry) =>
                            entry.id === draft.id ? { ...entry, status: "accepted" } : entry,
                          ),
                        );
                      }}
                      type="radio"
                    />
                    Approved Guest
                  </label>
                  <label className={`choice-pill ${draft.status === "rejected" ? "choice-pill--active" : ""}`}>
                    <input
                      checked={draft.status === "rejected"}
                      disabled={submitting}
                      name={`status-${draft.id}`}
                      onChange={() => {
                        setDrafts((current) =>
                          current.map((entry) =>
                            entry.id === draft.id ? { ...entry, status: "rejected" } : entry,
                          ),
                        );
                      }}
                      type="radio"
                    />
                    Rejected / Watchlist
                  </label>
                </div>
                <FilePreviewStrip
                  files={draft.files}
                  onRemove={(fileIndex) => {
                    setDrafts((current) =>
                      current.map((entry) =>
                        entry.id === draft.id
                          ? {
                              ...entry,
                              files: entry.files.filter((_, indexToKeep) => indexToKeep !== fileIndex),
                            }
                          : entry,
                      ),
                    );
                  }}
                />
                <div className="enrollment-card__actions">
                  <label className="button button--secondary button--file">
                    Upload Frames
                    <input
                      accept="image/*"
                      className="sr-only"
                      disabled={submitting}
                      multiple
                      onChange={(event) => {
                        const files = Array.from(event.target.files ?? []);
                        if (files.length > 0) {
                          setDrafts((current) =>
                            current.map((entry) =>
                              entry.id === draft.id
                                ? { ...entry, files: [...entry.files, ...files] }
                                : entry,
                            ),
                          );
                        }
                        event.target.value = "";
                      }}
                      type="file"
                    />
                  </label>
                  <button
                    className="button button--secondary"
                    disabled={submitting}
                    onClick={() => {
                      setDrafts((current) =>
                        current.map((entry) =>
                          entry.id === draft.id
                            ? { ...entry, cameraOpen: !entry.cameraOpen }
                            : { ...entry, cameraOpen: false },
                        ),
                      );
                    }}
                    type="button"
                  >
                    {draft.cameraOpen ? "Hide Camera" : "Capture Frames"}
                  </button>
                </div>
                {draft.cameraOpen ? (
                  <FrameCapturePanel
                    disabled={submitting}
                    onAddFrame={(file) => {
                      setDrafts((current) =>
                        current.map((entry) =>
                          entry.id === draft.id ? { ...entry, files: [...entry.files, file] } : entry,
                        ),
                      );
                    }}
                  />
                ) : null}
              </article>
            ))}
          </div>
          <div className="enrollment-page__footer">
            <SecondaryButton
              onClick={() => {
                setDrafts((current) => [...current, createDraft()]);
              }}
            >
              Add Another Person
            </SecondaryButton>
            <PrimaryButton disabled={submitting} onClick={() => void handleSubmit()}>
              {submitting ? "Enrolling..." : "Save Enrollments"}
            </PrimaryButton>
          </div>
        </Panel>
      </main>
    </SessionGuard>
  );
}
