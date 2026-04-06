"use client";

import { useEffect, useMemo, useState } from "react";

import { InlineMessage, MetricCard, Panel, PrimaryButton, StatusBadge } from "@/components/common";
import { listMemberProfiles, saveApprovedGuests } from "@/lib/api";
import type { AttendeeDetail } from "@/lib/types";

export default function SettingsPage() {
  const [profiles, setProfiles] = useState<AttendeeDetail[]>([]);
  const [approvedIds, setApprovedIds] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function loadProfiles() {
    setLoading(true);
    setError(null);
    try {
      const nextProfiles = await listMemberProfiles();
      setProfiles(nextProfiles);
      setApprovedIds(
        new Set(
          nextProfiles.filter((profile) => profile.status === "accepted").map((profile) => profile.id),
        ),
      );
    } catch (settingsError) {
      setError(settingsError instanceof Error ? settingsError.message : "Unable to load the approval registry.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadProfiles();
  }, []);

  const hasChanges = useMemo(
    () =>
      profiles.some((profile) => approvedIds.has(profile.id) !== (profile.status === "accepted")),
    [approvedIds, profiles],
  );

  async function handleSave() {
    setSaving(true);
    setError(null);
    setMessage(null);
    try {
      const approvedNames = profiles
        .filter((profile) => approvedIds.has(profile.id))
        .map((profile) => profile.name)
        .sort((left, right) => left.localeCompare(right));
      await saveApprovedGuests(approvedNames);
      setMessage(`Saved approvals for ${approvedNames.length} people.`);
      await loadProfiles();
    } catch (settingsError) {
      setError(settingsError instanceof Error ? settingsError.message : "Unable to save approvals.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="screen-grid">
      <Panel
        action={
          <button className="button button--secondary" onClick={() => void loadProfiles()} type="button">
            Refresh
          </button>
        }
        subtitle="Approved people scan as accepted. Saved people who are not approved scan as rejected."
        title="Approval Registry"
      >
        <div className="settings-metrics">
          <MetricCard label="Saved people" value={String(profiles.length)} />
          <MetricCard accent="var(--accepted)" label="Approved" value={String(approvedIds.size)} />
          <MetricCard
            accent="var(--rejected)"
            label="Not approved"
            value={String(Math.max(profiles.length - approvedIds.size, 0))}
          />
        </div>
        {loading ? <InlineMessage>Loading approval registry…</InlineMessage> : null}
        {message ? <InlineMessage tone="success">{message}</InlineMessage> : null}
        {error ? <InlineMessage tone="error">{error}</InlineMessage> : null}
        {!loading && profiles.length === 0 ? (
          <InlineMessage>No saved people yet. Enroll someone first, then manage approval here.</InlineMessage>
        ) : null}
        <div className="profile-list">
          {profiles.map((profile) => {
            const approved = approvedIds.has(profile.id);
            return (
              <div className="profile-card" key={profile.id}>
                <div className="profile-card__summary">
                  <div>
                    <div className="profile-card__title-row">
                      <strong>{profile.name}</strong>
                      <StatusBadge status={approved ? "accepted" : "rejected"} />
                    </div>
                    <p>
                      {profile.role} · {profile.organization}
                    </p>
                  </div>
                  <label className="toggle">
                    <input
                      checked={approved}
                      onChange={(event) => {
                        setApprovedIds((current) => {
                          const next = new Set(current);
                          if (event.target.checked) {
                            next.add(profile.id);
                          } else {
                            next.delete(profile.id);
                          }
                          return next;
                        });
                      }}
                      type="checkbox"
                    />
                    <span>{approved ? "Approved guest" : "Rejected / watchlist"}</span>
                  </label>
                </div>
                <p className="profile-card__note">{profile.note}</p>
              </div>
            );
          })}
        </div>
        <PrimaryButton disabled={!hasChanges || saving || loading} onClick={() => void handleSave()}>
          {saving ? "Saving..." : "Save Approvals"}
        </PrimaryButton>
      </Panel>
    </div>
  );
}
