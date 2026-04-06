import type { AttendeeStatus, HistoryFilter, ScanSource } from "@/lib/types";

export const statusMeta: Record<
  AttendeeStatus,
  {
    badgeLabel: string;
    label: string;
    color: string;
    resultTitle: string;
    resultDescription: string;
    membershipText: string;
  }
> = {
  accepted: {
    badgeLabel: "ACCEPTED",
    label: "Accepted",
    color: "var(--accepted)",
    resultTitle: "Accepted Attendee",
    resultDescription:
      "This attendee is on the accepted guest list and can be cleared for entry.",
    membershipText: "On the accepted attendee list.",
  },
  rejected: {
    badgeLabel: "REJECTED",
    label: "Rejected",
    color: "var(--rejected)",
    resultTitle: "Rejected Match",
    resultDescription:
      "A record was found, but this person is not on the accepted attendee list.",
    membershipText: "Not on the accepted attendee list.",
  },
  unknown: {
    badgeLabel: "UNKNOWN",
    label: "Unknown",
    color: "var(--unknown)",
    resultTitle: "Unknown Guest",
    resultDescription:
      "No verified attendee match was found. Manual review is required.",
    membershipText: "Unknown / not on the accepted attendee list.",
  },
};

export const historyFilters: HistoryFilter[] = [
  "all",
  "accepted",
  "rejected",
  "unknown",
];

export const historyFilterLabels: Record<HistoryFilter, string> = {
  all: "All",
  accepted: "Accepted",
  rejected: "Rejected",
  unknown: "Unknown",
};

export const sourceLabels: Record<ScanSource, string> = {
  camera: "Live camera",
  gallery: "Camera roll",
};

export function formatClock(value: string): string {
  const date = new Date(value);
  return date.toLocaleTimeString([], {
    hour: "numeric",
    minute: "2-digit",
  });
}

export function formatConfidence(value: number): string {
  return `${(value * 100).toFixed(2)}%`;
}

export function resolvedAttendeeStatusText(status: AttendeeStatus, note?: string | null): string {
  const membershipText = statusMeta[status].membershipText;
  if (!note) {
    return membershipText;
  }

  const normalizedNote = note.trim();
  if (!normalizedNote) {
    return membershipText;
  }

  return membershipText;
}

export function resolvedProfileNote(status: AttendeeStatus, note?: string | null): string | null {
  if (!note) {
    return null;
  }

  const normalizedNote = note.trim();
  if (!normalizedNote) {
    return null;
  }

  if (normalizedNote === statusMeta[status].membershipText) {
    return null;
  }

  const normalizedLower = normalizedNote.toLowerCase();
  const systemStatusPhrases = [
    "accepted attendee list",
    "not on the accepted attendee list",
    "manual review is required",
    "a record exists, but this person is not on the accepted attendee list",
    "this attendee is on the accepted guest list",
    "no verified attendee match was found",
  ];

  if (systemStatusPhrases.some((phrase) => normalizedLower.includes(phrase))) {
    return null;
  }

  return normalizedNote;
}

export function buildOperatorName(email: string): string {
  const localPart = email.split("@")[0] ?? "operator";
  return localPart
    .split(/[._-]/g)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

export function encodeBytesToBase64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

export function decodeBase64Url(value: string): Uint8Array {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padding = "=".repeat((4 - (normalized.length % 4 || 4)) % 4);
  const binary = atob(normalized + padding);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes;
}
