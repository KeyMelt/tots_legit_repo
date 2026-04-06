from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Iterable

from .config import (
    APPROVED_GUESTS_PATH,
    KNOWN_PEOPLE_DIR,
    MEMBER_PROFILES_PATH,
    SUPPORTED_IMAGE_EXTENSIONS,
)
from .utils import sanitize_label, slugify

DEFAULT_ACCEPTED_OVERRIDES = {
    "Angelina Jolie": {
        "role": "Keynote Speaker",
        "location": "Main Entry Checkpoint",
        "organization": "Synthetic Eye Summit",
    },
    "Sandra Bullock": {
        "role": "VIP Guest",
        "location": "South Lobby Reception",
        "organization": "Synthetic Eye Summit",
    },
    "Scarlett Johansson": {
        "role": "Panel Speaker",
        "location": "Speaker Entrance",
        "organization": "Synthetic Eye Summit",
    },
    "Tom Hanks": {
        "role": "Executive Guest",
        "location": "North Atrium Checkpoint",
        "organization": "Synthetic Eye Summit",
    },
}


def _normalize_guest_names(names: Iterable[str]) -> list[str]:
    normalized = {
        sanitize_label(name)
        for name in names
        if isinstance(name, str) and sanitize_label(name)
    }
    return sorted(normalized)


def _seed_approved_guest_names(
    approved_names_path: Path = APPROVED_GUESTS_PATH,
    profiles_path: Path = MEMBER_PROFILES_PATH,
) -> None:
    if approved_names_path.exists():
        raw_text = approved_names_path.read_text(encoding="utf-8").strip()
        if raw_text:
            try:
                payload = json.loads(raw_text)
            except json.JSONDecodeError:
                payload = None
            if isinstance(payload, list) and _normalize_guest_names(payload):
                return

    seeded_names = set(DEFAULT_ACCEPTED_OVERRIDES)
    for profile in load_member_profiles(profiles_path):
        if str(profile.get("status")) == "accepted":
            name = sanitize_label(str(profile.get("name", "")))
            if name:
                seeded_names.add(name)

    save_approved_guest_names(sorted(seeded_names), approved_names_path=approved_names_path)


def load_approved_guest_names(
    approved_names_path: Path = APPROVED_GUESTS_PATH,
    profiles_path: Path = MEMBER_PROFILES_PATH,
) -> list[str]:
    _seed_approved_guest_names(
        approved_names_path=approved_names_path,
        profiles_path=profiles_path,
    )

    raw_text = approved_names_path.read_text(encoding="utf-8").strip()
    if not raw_text:
        return []

    payload = json.loads(raw_text)
    if isinstance(payload, list):
        return _normalize_guest_names(name for name in payload if isinstance(name, str))
    raise ValueError("Approved guest names must be stored as a list.")


def save_approved_guest_names(
    names: Iterable[str],
    *,
    approved_names_path: Path = APPROVED_GUESTS_PATH,
) -> list[str]:
    normalized = _normalize_guest_names(names)
    approved_names_path.parent.mkdir(parents=True, exist_ok=True)
    approved_names_path.write_text(
        json.dumps(normalized, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    return normalized


def is_guest_approved(
    name: str,
    *,
    approved_names: Iterable[str] | None = None,
) -> bool:
    clean_name = sanitize_label(name)
    approved_lookup = {
        sanitize_label(approved_name)
        for approved_name in (approved_names or load_approved_guest_names())
    }
    return clean_name in approved_lookup


def resolve_member_image_path(name: str) -> str | None:
    person_dir = KNOWN_PEOPLE_DIR / name
    if not person_dir.exists():
        return None

    for image_path in sorted(
        path
        for path in person_dir.iterdir()
        if path.is_file() and path.suffix.lower() in SUPPORTED_IMAGE_EXTENSIONS
    ):
        return str(image_path.relative_to(KNOWN_PEOPLE_DIR))
    return None


def default_profile_for_name(
    name: str,
    *,
    status: str | None = None,
    role: str | None = None,
    location: str | None = None,
    organization: str | None = None,
    note: str | None = None,
    approved_names: Iterable[str] | None = None,
) -> dict[str, Any]:
    clean_name = sanitize_label(name)
    attendee_id = slugify(clean_name)
    accepted_override = DEFAULT_ACCEPTED_OVERRIDES.get(clean_name)
    approved = is_guest_approved(clean_name, approved_names=approved_names)
    effective_status = status or ("accepted" if approved else "rejected")

    if effective_status == "accepted":
        return {
            "id": attendee_id,
            "name": clean_name,
            "role": role or (accepted_override or {}).get("role") or "Approved Guest",
            "location": location
            or (accepted_override or {}).get("location")
            or "Main Entry Checkpoint",
            "status": "accepted",
            "imagePath": resolve_member_image_path(clean_name),
            "email": f"{attendee_id.replace('-', '.')}@syntheticeye.local",
            "organization": organization
            or (accepted_override or {}).get("organization")
            or "Synthetic Eye Registry",
            "note": note or "This person is on the approved guest list.",
        }

    return {
        "id": attendee_id,
        "name": clean_name,
        "role": role or "Manual Review Required",
        "location": location or "Security Review Desk",
        "status": "rejected",
        "imagePath": resolve_member_image_path(clean_name),
        "email": f"{attendee_id.replace('-', '.')}@syntheticeye.local",
        "organization": organization or "Synthetic Eye Registry",
        "note": note or "A record exists, but this person is not on the approved guest list.",
    }


def load_member_profiles(
    profiles_path: Path = MEMBER_PROFILES_PATH,
) -> list[dict[str, Any]]:
    if not profiles_path.exists():
        return []

    raw_text = profiles_path.read_text(encoding="utf-8").strip()
    if not raw_text:
        return []

    payload = json.loads(raw_text)
    if isinstance(payload, list):
        return payload
    raise ValueError("Member profiles must be stored as a list.")


def save_member_profiles(
    profiles: list[dict[str, Any]],
    profiles_path: Path = MEMBER_PROFILES_PATH,
) -> None:
    profiles_path.parent.mkdir(parents=True, exist_ok=True)
    profiles_path.write_text(
        json.dumps(profiles, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )


def sync_member_profiles_with_database(
    database: list[dict[str, Any]],
    profiles_path: Path = MEMBER_PROFILES_PATH,
    approved_names_path: Path = APPROVED_GUESTS_PATH,
) -> list[dict[str, Any]]:
    existing_profiles = {profile["id"]: profile for profile in load_member_profiles(profiles_path)}
    approved_names = load_approved_guest_names(
        approved_names_path=approved_names_path,
        profiles_path=profiles_path,
    )
    approved_lookup = set(approved_names)
    synced_profiles: list[dict[str, Any]] = []

    for person in sorted(database, key=lambda item: item["name"]):
        name = person["name"]
        attendee_id = slugify(name)
        profile = existing_profiles.get(attendee_id) or default_profile_for_name(
            name,
            approved_names=approved_lookup,
        )
        clean_name = sanitize_label(name)
        profile["id"] = attendee_id
        profile["name"] = clean_name
        profile["status"] = "accepted" if clean_name in approved_lookup else "rejected"
        profile["imagePath"] = resolve_member_image_path(clean_name)
        profile["email"] = profile.get(
            "email",
            f"{attendee_id.replace('-', '.')}@syntheticeye.local",
        )
        if profile["status"] == "accepted":
            profile["role"] = profile.get("role") or "Approved Guest"
            profile["location"] = profile.get("location") or "Main Entry Checkpoint"
            profile["organization"] = profile.get("organization") or "Synthetic Eye Registry"
            profile["note"] = profile.get("note") or "This person is on the approved guest list."
        else:
            profile["role"] = profile.get("role") or "Manual Review Required"
            profile["location"] = profile.get("location") or "Security Review Desk"
            profile["organization"] = profile.get("organization") or "Synthetic Eye Registry"
            profile["note"] = (
                profile.get("note")
                or "A record exists, but this person is not on the approved guest list."
            )
        synced_profiles.append(profile)

    save_member_profiles(synced_profiles, profiles_path)
    return synced_profiles


def upsert_member_profile(
    label: str,
    *,
    status: str = "accepted",
    role: str | None = None,
    location: str | None = None,
    organization: str | None = None,
    note: str | None = None,
    profiles_path: Path = MEMBER_PROFILES_PATH,
    approved_names_path: Path = APPROVED_GUESTS_PATH,
) -> list[dict[str, Any]]:
    clean_label = sanitize_label(label)
    attendee_id = slugify(clean_label)
    approved_names = set(
        load_approved_guest_names(
            approved_names_path=approved_names_path,
            profiles_path=profiles_path,
        )
    )
    if status == "accepted":
        approved_names.add(clean_label)
    else:
        approved_names.discard(clean_label)
    approved_names = set(
        save_approved_guest_names(
            approved_names,
            approved_names_path=approved_names_path,
        )
    )

    profiles = load_member_profiles(profiles_path)
    existing_map = {profile["id"]: profile for profile in profiles}
    effective_status = "accepted" if clean_label in approved_names else "rejected"

    updated_profile = existing_map.get(attendee_id) or default_profile_for_name(
        clean_label,
        approved_names=approved_names,
    )
    updated_profile["name"] = clean_label
    updated_profile["status"] = effective_status
    updated_profile["role"] = role or updated_profile["role"]
    updated_profile["location"] = location or updated_profile["location"]
    updated_profile["organization"] = organization or updated_profile["organization"]
    updated_profile["note"] = note or updated_profile["note"]
    updated_profile["imagePath"] = resolve_member_image_path(clean_label)
    updated_profile["email"] = updated_profile.get(
        "email",
        f"{attendee_id.replace('-', '.')}@syntheticeye.local",
    )

    existing_map[attendee_id] = updated_profile
    merged_profiles = sorted(existing_map.values(), key=lambda profile: profile["name"])
    save_member_profiles(merged_profiles, profiles_path)
    return merged_profiles
