import type {
  ApprovedGuestsConfig,
  AttendeeDetail,
  AttendeeSummary,
  EnrollmentBatchResult,
  EnrollmentMemberDraft,
  HealthResponse,
  HistoryFilter,
  ScanResult,
  ScanSource,
} from "@/lib/types";

const defaultApiBaseUrl =
  process.env.NEXT_PUBLIC_API_BASE_URL?.trim() || "http://127.0.0.1:8000";

function buildUrl(path: string, query?: Record<string, string>): string {
  const base = defaultApiBaseUrl.endsWith("/")
    ? defaultApiBaseUrl.slice(0, -1)
    : defaultApiBaseUrl;
  const url = new URL(`${base}${path}`);
  if (query) {
    for (const [key, value] of Object.entries(query)) {
      url.searchParams.set(key, value);
    }
  }
  return url.toString();
}

async function readJson<T>(response: Response): Promise<T> {
  const payload = (await response.json().catch(() => null)) as
    | Record<string, unknown>
    | null;

  if (!response.ok) {
    const detail =
      typeof payload?.detail === "string"
        ? payload.detail
        : `Request failed with status ${response.status}.`;
    throw new Error(detail);
  }

  return payload as T;
}

export async function healthCheck(): Promise<HealthResponse> {
  const response = await fetch(buildUrl("/health"), { cache: "no-store" });
  return readJson<HealthResponse>(response);
}

export async function listAttendees(filter: HistoryFilter): Promise<AttendeeSummary[]> {
  const response = await fetch(buildUrl("/api/attendees", { filter }), {
    cache: "no-store",
  });
  return readJson<AttendeeSummary[]>(response);
}

export async function getAttendeeDetail(attendeeId: string): Promise<AttendeeDetail> {
  const response = await fetch(buildUrl(`/api/attendees/${attendeeId}`), {
    cache: "no-store",
  });
  return readJson<AttendeeDetail>(response);
}

export async function listMemberProfiles(): Promise<AttendeeDetail[]> {
  const response = await fetch(buildUrl("/api/member-profiles"), {
    cache: "no-store",
  });
  return readJson<AttendeeDetail[]>(response);
}

export async function getApprovedGuests(): Promise<ApprovedGuestsConfig> {
  const response = await fetch(buildUrl("/api/approved-guests"), {
    cache: "no-store",
  });
  return readJson<ApprovedGuestsConfig>(response);
}

export async function saveApprovedGuests(names: string[]): Promise<ApprovedGuestsConfig> {
  const response = await fetch(buildUrl("/api/approved-guests"), {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ names }),
  });
  return readJson<ApprovedGuestsConfig>(response);
}

export async function submitScan(file: File, source: ScanSource): Promise<ScanResult> {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("source", source);
  formData.append("preview", "false");

  const response = await fetch(buildUrl("/api/scans"), {
    method: "POST",
    body: formData,
  });
  return readJson<ScanResult>(response);
}

export async function enrollMembers(
  members: EnrollmentMemberDraft[],
): Promise<EnrollmentBatchResult> {
  const formData = new FormData();
  formData.append(
    "manifest",
    JSON.stringify({
      members: members.map((member) => ({
        label: member.label,
        status: member.status,
      })),
    }),
  );

  members.forEach((member, memberIndex) => {
    member.files.forEach((file, imageIndex) => {
      const extension = file.type.includes("png") ? "png" : "jpg";
      formData.append(
        "files",
        file,
        `member_${memberIndex}__frame_${imageIndex}.${extension}`,
      );
    });
  });

  const response = await fetch(buildUrl("/api/enrollments"), {
    method: "POST",
    body: formData,
  });
  return readJson<EnrollmentBatchResult>(response);
}
