from __future__ import annotations

from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, Query, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from .config import KNOWN_PEOPLE_DIR
from .schemas import (
    AttendeeDetailResponse,
    AttendeeSummaryResponse,
    ApprovedGuestsResponse,
    ApprovedGuestsUpdateRequest,
    EnrollmentBatchManifest,
    EnrollmentBatchResponse,
    ScanResultResponse,
)
from .service import RecognitionService, parse_member_index

service = RecognitionService()
app = FastAPI(title="Synthetic Eye API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _base_url(request: Request) -> str:
    return str(request.base_url).rstrip("/")


def _is_image_upload(file: UploadFile) -> bool:
    if file.content_type and file.content_type.startswith("image/"):
        return True
    if file.filename:
        return Path(file.filename).suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    return False


@app.get("/health")
def health_check() -> dict[str, object]:
    return {
        "status": "ok",
        "knownAttendees": service.known_attendee_count,
        "entrypoint": "backend.app.api:app",
    }


@app.get("/api/member-images/{image_path:path}")
def member_image(image_path: str) -> FileResponse:
    target = (KNOWN_PEOPLE_DIR / image_path).resolve()
    if KNOWN_PEOPLE_DIR.resolve() not in target.parents and target != KNOWN_PEOPLE_DIR.resolve():
        raise HTTPException(status_code=400, detail="Invalid image path.")
    if not target.exists() or not target.is_file():
        raise HTTPException(status_code=404, detail="Image not found.")
    return FileResponse(target)


@app.get("/api/attendees", response_model=list[AttendeeSummaryResponse])
def list_attendees(
    request: Request,
    filter: str = Query("all"),
) -> list[dict[str, object]]:
    if filter not in {"all", "accepted", "rejected", "unknown"}:
        raise HTTPException(status_code=400, detail="Invalid filter value.")
    records = service.list_attendees(filter)
    return [service.serialize_summary(record, _base_url(request)) for record in records]


@app.get("/api/attendees/{attendee_id}", response_model=AttendeeDetailResponse)
def get_attendee_detail(request: Request, attendee_id: str) -> dict[str, object]:
    try:
        detail = service.get_attendee_detail(attendee_id)
    except KeyError as error:
        raise HTTPException(status_code=404, detail="Attendee not found.") from error
    return service.serialize_detail(detail, _base_url(request))


@app.get("/api/member-profiles", response_model=list[AttendeeDetailResponse])
def list_member_profiles(request: Request) -> list[dict[str, object]]:
    return [
        service.serialize_detail(profile, _base_url(request))
        for profile in service.list_member_profiles()
    ]


@app.get("/api/approved-guests", response_model=ApprovedGuestsResponse)
def get_approved_guests() -> dict[str, object]:
    return {"names": service.list_approved_guest_names()}


@app.put("/api/approved-guests", response_model=ApprovedGuestsResponse)
def update_approved_guests(payload: ApprovedGuestsUpdateRequest) -> dict[str, object]:
    return {"names": service.update_approved_guest_names(payload.names)}


@app.post("/api/scans", response_model=ScanResultResponse)
async def submit_scan(
    request: Request,
    file: UploadFile = File(...),
    source: str = Form(...),
    preview: bool = Form(False),
) -> dict[str, object]:
    if not _is_image_upload(file):
        raise HTTPException(status_code=400, detail="Upload a valid image file.")

    try:
        image_bytes = await file.read()
        record = service.recognize_upload(
            image_bytes,
            source,
            persist_history=not preview,
        )
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="The backend could not process this image.",
        ) from error

    return service.serialize_scan_result(record, _base_url(request))


@app.post("/api/enrollments", response_model=EnrollmentBatchResponse)
async def enroll_unknown_members(
    request: Request,
    manifest: str = Form(...),
    files: list[UploadFile] = File(...),
) -> dict[str, object]:
    try:
        enrollment_manifest = EnrollmentBatchManifest.model_validate_json(manifest)
    except Exception as error:
        raise HTTPException(status_code=400, detail="Invalid enrollment manifest.") from error

    member_files: list[list[tuple[str, bytes]]] = [
        [] for _ in range(len(enrollment_manifest.members))
    ]

    try:
        for file in files:
            if not file.filename:
                raise ValueError("Each enrollment image must include a file name.")
            if not _is_image_upload(file):
                raise ValueError("Enrollment files must all be valid images.")

            member_index = parse_member_index(file.filename)
            if member_index >= len(member_files):
                raise ValueError("Enrollment file index is outside the manifest range.")

            member_files[member_index].append((file.filename, await file.read()))

        result = service.enroll_members(enrollment_manifest.members, member_files)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="The backend could not complete the enrollment request.",
        ) from error

    return service.serialize_enrollment_result(result, _base_url(request))
