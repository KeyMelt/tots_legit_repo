from __future__ import annotations

from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[2]
BACKEND_DIR = ROOT_DIR / "backend"
DATA_DIR = BACKEND_DIR / "data"
KNOWN_PEOPLE_DIR = BACKEND_DIR / "known_people"
UNKNOWN_CAPTURE_DIR = BACKEND_DIR / "unknown_captures"

DATABASE_PATH = DATA_DIR / "known_faces.json"
SCAN_HISTORY_PATH = DATA_DIR / "scan_history.json"
MEMBER_PROFILES_PATH = DATA_DIR / "member_profiles.json"
APPROVED_GUESTS_PATH = DATA_DIR / "approved_guests.json"

SUPPORTED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
DEFAULT_TOLERANCE = 0.50
DEFAULT_DETECTION_MODEL = "hog"
DEFAULT_FRAME_SCALE = 0.50


def ensure_backend_directories() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    KNOWN_PEOPLE_DIR.mkdir(parents=True, exist_ok=True)
    UNKNOWN_CAPTURE_DIR.mkdir(parents=True, exist_ok=True)

    if not DATABASE_PATH.exists():
        DATABASE_PATH.write_text("[]\n", encoding="utf-8")
    if not SCAN_HISTORY_PATH.exists():
        SCAN_HISTORY_PATH.write_text("[]\n", encoding="utf-8")
    if not MEMBER_PROFILES_PATH.exists():
        MEMBER_PROFILES_PATH.write_text("[]\n", encoding="utf-8")
    if not APPROVED_GUESTS_PATH.exists():
        APPROVED_GUESTS_PATH.write_text("[]\n", encoding="utf-8")
