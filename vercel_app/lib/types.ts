export type AttendeeStatus = "accepted" | "rejected" | "unknown";
export type HistoryFilter = "all" | "accepted" | "rejected" | "unknown";
export type ScanSource = "camera" | "gallery";

export interface AttendeeSummary {
  id: string;
  name: string;
  role: string;
  location: string;
  scannedAt: string;
  status: AttendeeStatus;
  imageUrl: string | null;
  confidence: number;
  source: ScanSource;
}

export interface AttendeeDetail {
  id: string;
  name: string;
  role: string;
  location: string;
  status: AttendeeStatus;
  imageUrl: string | null;
  email: string;
  organization: string;
  note: string;
}

export interface ScanFaceMatch {
  name: string;
  status: AttendeeStatus;
  confidence: number;
}

export interface ScanSummary {
  faceCount: number;
  acceptedCount: number;
  rejectedCount: number;
  unknownCount: number;
  status: AttendeeStatus;
  matches: ScanFaceMatch[];
}

export interface ScanResult {
  status: AttendeeStatus;
  detail: AttendeeDetail;
  confidence: number;
  source: ScanSource;
  scannedAt: string;
  summary: ScanSummary | null;
}

export interface ApprovedGuestsConfig {
  names: string[];
}

export interface EnrollmentMemberDraft {
  label: string;
  status: Exclude<AttendeeStatus, "unknown">;
  files: File[];
}

export interface EnrollmentMemberResult {
  attendee: AttendeeDetail;
  savedImages: number;
}

export interface EnrollmentBatchResult {
  enrolledCount: number;
  totalSavedImages: number;
  members: EnrollmentMemberResult[];
}

export interface HealthResponse {
  status: string;
  knownAttendees: number;
  entrypoint: string;
}
