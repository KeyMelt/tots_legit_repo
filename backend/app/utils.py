from __future__ import annotations

import re
from datetime import datetime, timezone


def slugify(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")


def sanitize_label(value: str) -> str:
    sanitized = value.replace("/", " ").replace("\\", " ").strip()
    sanitized = re.sub(r"\s+", " ", sanitized)
    if not sanitized:
        raise ValueError("Each enrolled member must have a non-empty label.")
    return sanitized


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
