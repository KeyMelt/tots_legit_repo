from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from threading import Lock
from typing import Any
from urllib.parse import quote

from .config import KNOWN_PEOPLE_DIR, SCAN_HISTORY_PATH, ensure_backend_directories
from .face_database import (
    extract_single_face_encoding,
    flatten_database,
    load_face_database,
    load_normalized_image,
    recognize_faces_in_image_bytes,
    upsert_people_in_database,
)
from .profile_store import (
    default_profile_for_name,
    load_approved_guest_names,
    load_member_profiles,
    save_approved_guest_names,
    sync_member_profiles_with_database,
    upsert_member_profile,
)
from .schemas import EnrollmentMemberManifest
from .utils import sanitize_label, slugify, utc_timestamp

UNKNOWN_NOTES = {
    "no_face": "No face was detected in the uploaded image. Try a clearer photo.",
    "multiple_faces": "Multiple faces were detected. Live preview can summarize groups, but individual review works best with one face at a time.",
    "encoding_failed": "The detected face could not be encoded. Try a front-facing image with better lighting.",
    "no_match": "No verified attendee match was found. Manual review is required.",
}


class RecognitionService:
    def __init__(self) -> None:
        ensure_backend_directories()
        self._state_lock = Lock()
        self._history_lock = Lock()
        self._database: list[dict[str, Any]] = []
        self._profiles: list[dict[str, Any]] = []
        self._known_names: list[str] = []
        self._known_embeddings: list[Any] = []
        self.reload_state()

    @property
    def known_names(self) -> list[str]:
        return list(self._known_names)

    @property
    def known_embeddings(self) -> list[Any]:
        return list(self._known_embeddings)

    @property
    def known_attendee_count(self) -> int:
        return len(self._profiles)

    def reload_state(self) -> None:
        with self._state_lock:
            self._database = load_face_database()
            self._known_names, self._known_embeddings = flatten_database(self._database)
            self._profiles = sync_member_profiles_with_database(self._database)

    def list_attendees(self, filter_value: str) -> list[dict[str, Any]]:
        history = self._read_history()
        if filter_value != "all":
            history = [record for record in history if record.get("status") == filter_value]
        return history

    def list_member_profiles(self) -> list[dict[str, Any]]:
        return [dict(profile) for profile in self._profiles]

    def list_approved_guest_names(self) -> list[str]:
        return load_approved_guest_names()

    def update_approved_guest_names(self, names: list[str]) -> list[str]:
        approved_names = save_approved_guest_names(names)
        self.reload_state()
        return approved_names

    def get_attendee_detail(self, attendee_id: str) -> dict[str, Any]:
        history = self._read_history()
        for record in history:
            detail = record.get("detail", {})
            if detail.get("id") == attendee_id:
                return detail

        profile = self._find_profile_by_id(attendee_id)
        if profile is None:
            raise KeyError(attendee_id)
        return profile

    def recognize_upload(
        self,
        image_bytes: bytes,
        source: str,
        *,
        persist_history: bool = True,
    ) -> dict[str, Any]:
        if source not in {"camera", "gallery"}:
            raise ValueError("source must be either 'camera' or 'gallery'.")
        if not image_bytes:
            raise ValueError("The uploaded image is empty.")

        detections = recognize_faces_in_image_bytes(
            image_bytes,
            self._known_names,
            self._known_embeddings,
        )
        summary = self._build_scan_summary(detections)

        if not detections:
            detail = self._build_unknown_detail("no_face")
            confidence = 0.0
        elif len(detections) == 1:
            match = detections[0]
            if match["name"] == "Unknown":
                detail = self._build_unknown_detail("no_match")
            else:
                detail = self._build_known_detail(str(match["name"]))
            confidence = float(match["confidence"])
        else:
            detail = self._build_group_detail(summary)
            confidence = max(
                (
                    float(match.get("confidence") or 0.0)
                    for match in summary.get("matches", [])
                ),
                default=0.0,
            )

        record = {
            "status": detail["status"],
            "detail": detail,
            "confidence": round(confidence, 4),
            "source": source,
            "scannedAt": datetime.now(timezone.utc).isoformat(),
            "summary": summary,
        }

        if persist_history:
            history = self._read_history()
            history.insert(0, record)
            self._write_history(history)
        return record

    def enroll_members(
        self,
        members: list[EnrollmentMemberManifest],
        member_files: list[list[tuple[str, bytes]]],
    ) -> dict[str, Any]:
        if not members:
            raise ValueError("Add at least one unknown member before enrolling.")
        if len(members) != len(member_files):
            raise ValueError("Enrollment manifest does not match the uploaded files.")

        enrollment_summary: list[dict[str, Any]] = []
        total_saved_images = 0
        saved_counts_by_label: dict[str, int] = {}

        for manifest, files in zip(members, member_files):
            label = self._canonicalize_label(manifest.label)
            if not files:
                raise ValueError(f"Add at least one image for {label}.")

            saved_images = self._save_member_images(label, files)
            if saved_images == 0:
                raise ValueError(
                    f"No usable single-face images were found for {label}. "
                    "Capture a few clear front-facing frames and try again.",
                )

            upsert_member_profile(
                label,
                status=manifest.status,
                role=manifest.role,
                location=manifest.location,
                organization=manifest.organization,
                note=manifest.note,
            )
            total_saved_images += saved_images
            saved_counts_by_label[label] = saved_images

        upsert_people_in_database(list(saved_counts_by_label))
        self.reload_state()

        for manifest in members:
            label = self._canonicalize_label(manifest.label)
            profile = self._build_known_detail(label)
            enrollment_summary.append(
                {
                    "attendee": profile,
                    "savedImages": saved_counts_by_label[label],
                }
            )

        return {
            "enrolledCount": len(enrollment_summary),
            "totalSavedImages": total_saved_images,
            "members": enrollment_summary,
        }

    def serialize_summary(self, record: dict[str, Any], base_url: str) -> dict[str, Any]:
        detail = dict(record["detail"])
        return {
            "id": str(detail["id"]),
            "name": str(detail["name"]),
            "role": str(detail["role"]),
            "location": str(detail["location"]),
            "scannedAt": datetime.fromisoformat(str(record["scannedAt"])),
            "status": str(record["status"]),
            "imageUrl": self._build_image_url(detail.get("imagePath"), base_url),
            "confidence": float(record["confidence"]),
            "source": str(record["source"]),
        }

    def serialize_detail(self, detail: dict[str, Any], base_url: str) -> dict[str, Any]:
        return {
            "id": str(detail["id"]),
            "name": str(detail["name"]),
            "role": str(detail["role"]),
            "location": str(detail["location"]),
            "status": str(detail["status"]),
            "imageUrl": self._build_image_url(detail.get("imagePath"), base_url),
            "email": str(detail["email"]),
            "organization": str(detail["organization"]),
            "note": str(detail["note"]),
        }

    def serialize_scan_result(self, record: dict[str, Any], base_url: str) -> dict[str, Any]:
        detail = dict(record["detail"])
        summary = record.get("summary")
        return {
            "status": str(record["status"]),
            "detail": self.serialize_detail(detail, base_url),
            "confidence": float(record["confidence"]),
            "source": str(record["source"]),
            "scannedAt": datetime.fromisoformat(str(record["scannedAt"])),
            "summary": summary,
        }

    def serialize_enrollment_result(
        self,
        payload: dict[str, Any],
        base_url: str,
    ) -> dict[str, Any]:
        return {
            "enrolledCount": int(payload["enrolledCount"]),
            "totalSavedImages": int(payload["totalSavedImages"]),
            "members": [
                {
                    "attendee": self.serialize_detail(member["attendee"], base_url),
                    "savedImages": int(member["savedImages"]),
                }
                for member in payload["members"]
            ],
        }

    def _save_member_images(self, label: str, files: list[tuple[str, bytes]]) -> int:
        person_dir = KNOWN_PEOPLE_DIR / label
        person_dir.mkdir(parents=True, exist_ok=True)
        existing_count = len([path for path in person_dir.iterdir() if path.is_file()])
        saved_images = 0

        for index, (filename, image_bytes) in enumerate(files, start=1):
            if not image_bytes:
                continue

            image = load_normalized_image(image_bytes)
            _, error = extract_single_face_encoding(image)
            if error is not None:
                continue

            file_extension = Path(filename).suffix.lower() or ".jpg"
            file_name = (
                f"{slugify(label)}_{utc_timestamp()}_{existing_count + index:03d}{file_extension}"
            )
            (person_dir / file_name).write_bytes(image_bytes)
            saved_images += 1

        return saved_images

    def _find_profile_by_id(self, attendee_id: str) -> dict[str, Any] | None:
        for profile in self._profiles:
            if profile["id"] == attendee_id:
                return profile
        return None

    def _find_profile_by_name(self, name: str) -> dict[str, Any] | None:
        normalized = sanitize_label(name)
        for profile in self._profiles:
            if sanitize_label(str(profile.get("name", ""))) == normalized:
                return profile
        return None

    def _canonicalize_label(self, label: str) -> str:
        clean_label = sanitize_label(label)
        attendee_id = slugify(clean_label)
        for profile in load_member_profiles():
            if profile["id"] == attendee_id:
                return profile["name"]
        return clean_label

    def _build_known_detail(self, name: str) -> dict[str, Any]:
        attendee_id = slugify(name)
        profile = self._find_profile_by_id(attendee_id)
        if profile is not None:
            return profile
        return default_profile_for_name(
            name,
            approved_names=load_approved_guest_names(),
        )

    def _build_unknown_detail(self, reason: str) -> dict[str, Any]:
        return {
            "id": f"unknown-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S%f')}",
            "name": "Unknown Guest",
            "role": "Identity not recognized",
            "location": "Manual Review Required",
            "status": "unknown",
            "imagePath": None,
            "email": "Unavailable",
            "organization": "Unknown",
            "note": UNKNOWN_NOTES.get(reason, UNKNOWN_NOTES["no_match"]),
        }

    def _build_group_detail(self, summary: dict[str, Any]) -> dict[str, Any]:
        accepted_names = [
            match["name"]
            for match in summary["matches"]
            if match["status"] == "accepted" and match["name"] != "Unknown"
        ]
        rejected_names = [
            match["name"]
            for match in summary["matches"]
            if match["status"] == "rejected" and match["name"] != "Unknown"
        ]
        note_parts = [f"Detected {summary['faceCount']} faces in the frame."]
        if accepted_names:
            note_parts.append(f"Approved: {', '.join(accepted_names[:3])}.")
        if rejected_names:
            note_parts.append(f"Not approved: {', '.join(rejected_names[:3])}.")
        if summary["unknownCount"]:
            note_parts.append(
                f"Unknown: {summary['unknownCount']}. Capture or enroll those people separately."
            )

        return {
            "id": f"group-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S%f')}",
            "name": "Group Scan",
            "role": "Multiple faces detected",
            "location": "Live Group Summary",
            "status": summary["status"],
            "imagePath": None,
            "email": "Unavailable",
            "organization": "Synthetic Eye Registry",
            "note": " ".join(note_parts),
        }

    def _build_scan_summary(self, detections: list[dict[str, Any]]) -> dict[str, Any]:
        matches: list[dict[str, Any]] = []
        accepted_count = 0
        rejected_count = 0
        unknown_count = 0

        for detection in detections:
            name = str(detection["name"])
            confidence = float(detection.get("confidence") or 0.0)
            if name == "Unknown":
                status = "unknown"
                unknown_count += 1
            else:
                profile = self._find_profile_by_name(name) or default_profile_for_name(
                    name,
                    approved_names=load_approved_guest_names(),
                )
                status = str(profile["status"])
                if status == "accepted":
                    accepted_count += 1
                else:
                    rejected_count += 1

            matches.append(
                {
                    "name": name,
                    "status": status,
                    "confidence": round(confidence, 4),
                }
            )

        overall_status = "unknown"
        if matches:
            if unknown_count > 0:
                overall_status = "unknown"
            elif rejected_count > 0:
                overall_status = "rejected"
            else:
                overall_status = "accepted"

        return {
            "faceCount": len(matches),
            "acceptedCount": accepted_count,
            "rejectedCount": rejected_count,
            "unknownCount": unknown_count,
            "status": overall_status,
            "matches": matches,
        }

    def _build_image_url(self, image_path: Any, base_url: str) -> str | None:
        if not image_path:
            return None
        encoded_path = "/".join(quote(part) for part in Path(str(image_path)).parts)
        return f"{base_url.rstrip('/')}/api/member-images/{encoded_path}"

    def _read_history(self) -> list[dict[str, Any]]:
        with self._history_lock:
            raw_text = SCAN_HISTORY_PATH.read_text(encoding="utf-8").strip()
            if not raw_text:
                return []
            payload = json.loads(raw_text)
            if not isinstance(payload, list):
                raise ValueError("History payload must be a list.")
            return payload

    def _write_history(self, history: list[dict[str, Any]]) -> None:
        with self._history_lock:
            SCAN_HISTORY_PATH.write_text(
                json.dumps(history, indent=2, ensure_ascii=False),
                encoding="utf-8",
            )


def parse_member_index(filename: str) -> int:
    match = re.match(r"^member_(\d+)__", filename)
    if match is None:
        raise ValueError(
            "Enrollment file names must include the member index, for example "
            "'member_0__frame_0.jpg'."
        )
    return int(match.group(1))
