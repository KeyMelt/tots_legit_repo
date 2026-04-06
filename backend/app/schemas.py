from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class AttendeeDetailResponse(BaseModel):
    id: str
    name: str
    role: str
    location: str
    status: str
    imageUrl: str | None
    email: str
    organization: str
    note: str


class AttendeeSummaryResponse(BaseModel):
    id: str
    name: str
    role: str
    location: str
    scannedAt: datetime
    status: str
    imageUrl: str | None
    confidence: float
    source: str


class DetectedFaceResponse(BaseModel):
    name: str
    status: str
    confidence: float


class ScanSummaryResponse(BaseModel):
    faceCount: int
    acceptedCount: int
    rejectedCount: int
    unknownCount: int
    status: str
    matches: list[DetectedFaceResponse]


class ScanResultResponse(BaseModel):
    status: str
    detail: AttendeeDetailResponse
    confidence: float
    source: str
    scannedAt: datetime
    summary: ScanSummaryResponse | None = None


class EnrollmentMemberManifest(BaseModel):
    label: str
    status: str = "accepted"
    role: str | None = None
    location: str | None = None
    organization: str | None = None
    note: str | None = None


class EnrollmentBatchManifest(BaseModel):
    members: list[EnrollmentMemberManifest] = Field(default_factory=list)


class EnrollmentMemberResponse(BaseModel):
    attendee: AttendeeDetailResponse
    savedImages: int


class EnrollmentBatchResponse(BaseModel):
    enrolledCount: int
    totalSavedImages: int
    members: list[EnrollmentMemberResponse]


class ApprovedGuestsResponse(BaseModel):
    names: list[str] = Field(default_factory=list)


class ApprovedGuestsUpdateRequest(BaseModel):
    names: list[str] = Field(default_factory=list)
