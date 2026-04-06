from __future__ import annotations

import json
from io import BytesIO
from pathlib import Path
from typing import Any

import cv2
import face_recognition
import numpy as np
from PIL import Image, ImageOps

from .config import (
    DATABASE_PATH,
    DEFAULT_DETECTION_MODEL,
    DEFAULT_FRAME_SCALE,
    DEFAULT_TOLERANCE,
    KNOWN_PEOPLE_DIR,
    SUPPORTED_IMAGE_EXTENSIONS,
    ensure_backend_directories,
)

ensure_backend_directories()


def list_image_files(folder: Path) -> list[Path]:
    return sorted(
        path
        for path in folder.iterdir()
        if path.is_file() and path.suffix.lower() in SUPPORTED_IMAGE_EXTENSIONS
    )


def load_face_database(database_path: Path = DATABASE_PATH) -> list[dict[str, Any]]:
    if not database_path.exists():
        return []

    raw_text = database_path.read_text(encoding="utf-8").strip()
    if not raw_text:
        return []

    payload = json.loads(raw_text)
    if isinstance(payload, dict) and "people" in payload:
        return payload["people"]
    if isinstance(payload, list):
        return payload
    raise ValueError("Database must be a list of people or a {'people': [...]} object.")


def save_face_database(
    database: list[dict[str, Any]],
    database_path: Path = DATABASE_PATH,
) -> None:
    database_path.parent.mkdir(parents=True, exist_ok=True)
    database_path.write_text(
        json.dumps(database, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )


def load_normalized_image(source: str | Path | bytes | BytesIO) -> np.ndarray:
    if isinstance(source, (bytes, bytearray)):
        source = BytesIO(source)

    with Image.open(source) as image:
        normalized = ImageOps.exif_transpose(image).convert("RGB")
        return np.asarray(normalized)


def _candidate_image_orientations(image: np.ndarray) -> list[np.ndarray]:
    return [
        image,
        np.rot90(image, 1).copy(),
        np.rot90(image, -1).copy(),
        np.rot90(image, 2).copy(),
    ]


def extract_single_face_encoding(
    image: np.ndarray,
    detection_model: str = DEFAULT_DETECTION_MODEL,
) -> tuple[np.ndarray | None, str | None]:
    errors: list[str] = []

    for candidate in _candidate_image_orientations(image):
        locations = face_recognition.face_locations(candidate, model=detection_model)

        if len(locations) == 0:
            errors.append("no_face")
            continue
        if len(locations) > 1:
            errors.append("multiple_faces")
            continue

        encodings = face_recognition.face_encodings(
            candidate,
            known_face_locations=locations,
        )
        if len(encodings) != 1:
            errors.append("encoding_failed")
            continue

        return encodings[0].astype(np.float32), None

    if "multiple_faces" in errors:
        return None, "multiple_faces"
    if "encoding_failed" in errors:
        return None, "encoding_failed"
    return None, "no_face"


def detect_faces_and_encodings_in_rgb_image(
    rgb_image: np.ndarray,
    detection_model: str = DEFAULT_DETECTION_MODEL,
) -> list[dict[str, Any]]:
    locations = face_recognition.face_locations(rgb_image, model=detection_model)
    encodings = face_recognition.face_encodings(rgb_image, known_face_locations=locations)

    results: list[dict[str, Any]] = []
    for (top, right, bottom, left), encoding in zip(locations, encodings):
        results.append(
            {
                "box": (
                    int(left),
                    int(top),
                    int(right - left),
                    int(bottom - top),
                ),
                "encoding": np.asarray(encoding, dtype=np.float32),
            }
        )
    return results


def build_face_database(
    known_people_dir: Path = KNOWN_PEOPLE_DIR,
    database_path: Path = DATABASE_PATH,
    detection_model: str = DEFAULT_DETECTION_MODEL,
) -> tuple[list[dict[str, Any]], list[dict[str, int | str]]]:
    database: list[dict[str, Any]] = []
    report: list[dict[str, int | str]] = []

    if not known_people_dir.exists():
        raise FileNotFoundError(f"Known people directory does not exist: {known_people_dir}")

    for person_dir in sorted(path for path in known_people_dir.iterdir() if path.is_dir()):
        person_name = person_dir.name
        embeddings: list[list[float]] = []
        stats = {
            "person": person_name,
            "accepted": 0,
            "skipped_no_face": 0,
            "skipped_multiple_faces": 0,
            "skipped_encoding_failed": 0,
        }

        for image_path in list_image_files(person_dir):
            image = load_normalized_image(image_path)
            encoding, error = extract_single_face_encoding(
                image,
                detection_model=detection_model,
            )

            if error == "no_face":
                stats["skipped_no_face"] += 1
                continue
            if error == "multiple_faces":
                stats["skipped_multiple_faces"] += 1
                continue
            if error is not None:
                stats["skipped_encoding_failed"] += 1
                continue

            embeddings.append(encoding.tolist())
            stats["accepted"] += 1

        if embeddings:
            database.append({"name": person_name, "embeddings": embeddings})
        report.append(stats)

    save_face_database(database, database_path=database_path)
    return database, report


def build_person_record(
    person_dir: Path,
    *,
    detection_model: str = DEFAULT_DETECTION_MODEL,
) -> tuple[dict[str, Any] | None, dict[str, int | str]]:
    person_name = person_dir.name
    embeddings: list[list[float]] = []
    stats = {
        "person": person_name,
        "accepted": 0,
        "skipped_no_face": 0,
        "skipped_multiple_faces": 0,
        "skipped_encoding_failed": 0,
    }

    for image_path in list_image_files(person_dir):
        image = load_normalized_image(image_path)
        encoding, error = extract_single_face_encoding(
            image,
            detection_model=detection_model,
        )

        if error == "no_face":
            stats["skipped_no_face"] += 1
            continue
        if error == "multiple_faces":
            stats["skipped_multiple_faces"] += 1
            continue
        if error is not None:
            stats["skipped_encoding_failed"] += 1
            continue

        embeddings.append(encoding.tolist())
        stats["accepted"] += 1

    if not embeddings:
        return None, stats
    return {"name": person_name, "embeddings": embeddings}, stats


def upsert_people_in_database(
    labels: list[str] | set[str] | tuple[str, ...],
    *,
    known_people_dir: Path = KNOWN_PEOPLE_DIR,
    database_path: Path = DATABASE_PATH,
    detection_model: str = DEFAULT_DETECTION_MODEL,
) -> tuple[list[dict[str, Any]], list[dict[str, int | str]]]:
    updated_labels = {str(label).strip() for label in labels if str(label).strip()}
    existing_by_name = {
        person["name"]: person
        for person in load_face_database(database_path)
        if person["name"] not in updated_labels
    }
    report: list[dict[str, int | str]] = []

    for label in sorted(updated_labels):
        person_dir = known_people_dir / label
        if not person_dir.exists() or not person_dir.is_dir():
            continue
        person_record, stats = build_person_record(
            person_dir,
            detection_model=detection_model,
        )
        report.append(stats)
        if person_record is not None:
            existing_by_name[label] = person_record

    merged_database = [existing_by_name[name] for name in sorted(existing_by_name)]
    save_face_database(merged_database, database_path=database_path)
    return merged_database, report


def summarize_database(database: list[dict[str, Any]]) -> None:
    total_people = len(database)
    total_embeddings = sum(len(person.get("embeddings", [])) for person in database)
    print(f"People enrolled: {total_people}")
    print(f"Total embeddings: {total_embeddings}")
    for person in database:
        print(f"- {person['name']}: {len(person.get('embeddings', []))} embeddings")


def print_enrollment_report(report: list[dict[str, int | str]]) -> None:
    for item in report:
        print(
            f"{item['person']}: accepted={item['accepted']}, "
            f"skipped_no_face={item['skipped_no_face']}, "
            f"skipped_multiple_faces={item['skipped_multiple_faces']}, "
            f"skipped_encoding_failed={item['skipped_encoding_failed']}"
        )


def flatten_database(database: list[dict[str, Any]]) -> tuple[list[str], list[np.ndarray]]:
    known_names: list[str] = []
    known_embeddings: list[np.ndarray] = []

    for person in database:
        name = person["name"]
        for embedding in person.get("embeddings", []):
            known_names.append(name)
            known_embeddings.append(np.asarray(embedding, dtype=np.float32))

    return known_names, known_embeddings


def match_face_embedding(
    query_embedding: np.ndarray,
    known_names: list[str],
    known_embeddings: list[np.ndarray],
    tolerance: float = DEFAULT_TOLERANCE,
) -> dict[str, Any]:
    if not known_embeddings:
        return {
            "name": "Unknown",
            "distance": None,
            "confidence": 0.0,
        }

    distances = face_recognition.face_distance(known_embeddings, query_embedding)
    best_index = int(np.argmin(distances))
    best_distance = float(distances[best_index])

    if best_distance < tolerance:
        return {
            "name": known_names[best_index],
            "distance": best_distance,
            "confidence": max(0.0, 1.0 - best_distance),
        }

    return {
        "name": "Unknown",
        "distance": best_distance,
        "confidence": max(0.0, 1.0 - best_distance),
    }


def recognize_single_face_in_image_bytes(
    image_bytes: bytes,
    known_names: list[str],
    known_embeddings: list[np.ndarray],
    tolerance: float = DEFAULT_TOLERANCE,
    detection_model: str = DEFAULT_DETECTION_MODEL,
) -> dict[str, Any]:
    image = load_normalized_image(image_bytes)
    encoding, error = extract_single_face_encoding(
        image,
        detection_model=detection_model,
    )

    if error is not None:
        return {
            "name": "Unknown",
            "distance": None,
            "confidence": 0.0,
            "error": error,
        }

    match = match_face_embedding(
        encoding,
        known_names,
        known_embeddings,
        tolerance=tolerance,
    )
    match["error"] = None
    return match


def recognize_faces_in_image_bytes(
    image_bytes: bytes,
    known_names: list[str],
    known_embeddings: list[np.ndarray],
    tolerance: float = DEFAULT_TOLERANCE,
    detection_model: str = DEFAULT_DETECTION_MODEL,
) -> list[dict[str, Any]]:
    image = load_normalized_image(image_bytes)
    detections: list[dict[str, Any]] = []

    for candidate in _candidate_image_orientations(image):
        detections = detect_faces_and_encodings_in_rgb_image(
            candidate,
            detection_model=detection_model,
        )
        if detections:
            break

    results: list[dict[str, Any]] = []
    for detection in detections:
        match = match_face_embedding(
            detection["encoding"],
            known_names,
            known_embeddings,
            tolerance=tolerance,
        )
        results.append(
            {
                "name": match["name"],
                "distance": match["distance"],
                "confidence": match["confidence"],
                "box": detection["box"],
            }
        )
    return results


def detect_faces_and_encodings_in_frame(
    frame: np.ndarray,
    frame_scale: float = DEFAULT_FRAME_SCALE,
    detection_model: str = DEFAULT_DETECTION_MODEL,
) -> list[dict[str, Any]]:
    if frame_scale <= 0 or frame_scale > 1:
        raise ValueError("frame_scale must be in the range (0, 1].")

    working_frame = frame
    scale_back = 1.0
    if frame_scale != 1.0:
        working_frame = cv2.resize(frame, (0, 0), fx=frame_scale, fy=frame_scale)
        scale_back = 1.0 / frame_scale

    rgb_frame = cv2.cvtColor(working_frame, cv2.COLOR_BGR2RGB)
    detections = detect_faces_and_encodings_in_rgb_image(
        rgb_frame,
        detection_model=detection_model,
    )

    results: list[dict[str, Any]] = []
    for detection in detections:
        left, top, width, height = detection["box"]
        results.append(
            {
                "box": (
                    int(left * scale_back),
                    int(top * scale_back),
                    int(width * scale_back),
                    int(height * scale_back),
                ),
                "encoding": detection["encoding"],
            }
        )
    return results


def recognize_faces_in_frame(
    frame: np.ndarray,
    known_names: list[str],
    known_embeddings: list[np.ndarray],
    tolerance: float = DEFAULT_TOLERANCE,
    frame_scale: float = DEFAULT_FRAME_SCALE,
    detection_model: str = DEFAULT_DETECTION_MODEL,
) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    for detection in detect_faces_and_encodings_in_frame(
        frame,
        frame_scale=frame_scale,
        detection_model=detection_model,
    ):
        match = match_face_embedding(
            detection["encoding"],
            known_names,
            known_embeddings,
            tolerance=tolerance,
        )
        results.append(
            {
                "name": match["name"],
                "distance": match["distance"],
                "confidence": match["confidence"],
                "box": detection["box"],
            }
        )
    return results


def draw_recognition_results(frame: np.ndarray, results: list[dict[str, Any]]) -> np.ndarray:
    for result in results:
        x, y, w, h = result["box"]
        name = result["name"]
        confidence = result["confidence"]

        color = (0, 255, 0) if name != "Unknown" else (0, 0, 255)
        label = name if name == "Unknown" else f"{name} ({confidence:.0%})"

        cv2.rectangle(frame, (x, y), (x + w, y + h), color, 2)

        (text_w, text_h), baseline = cv2.getTextSize(
            label,
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            2,
        )
        label_top = max(y - text_h - baseline - 8, 0)
        label_bottom = label_top + text_h + baseline + 8
        cv2.rectangle(frame, (x, label_top), (x + text_w + 10, label_bottom), color, -1)
        cv2.putText(
            frame,
            label,
            (x + 5, label_bottom - baseline - 4),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (255, 255, 255),
            2,
        )

    return frame


def run_live_recognition(
    database_path: Path = DATABASE_PATH,
    camera_id: int = 0,
    tolerance: float = DEFAULT_TOLERANCE,
    frame_scale: float = DEFAULT_FRAME_SCALE,
    detection_model: str = DEFAULT_DETECTION_MODEL,
    process_every_n_frames: int = 1,
) -> None:
    database = load_face_database(database_path)
    known_names, known_embeddings = flatten_database(database)

    if not known_embeddings:
        print("Database is empty. Build the database first or every face will show as Unknown.")

    capture = cv2.VideoCapture(camera_id)
    if not capture.isOpened():
        raise RuntimeError(f"Cannot open camera {camera_id}.")

    frame_index = 0
    cached_results: list[dict[str, Any]] = []
    process_every_n_frames = max(1, process_every_n_frames)

    print("Live recognition started. Press 'q' or Esc to quit.")

    try:
        while True:
            ok, frame = capture.read()
            if not ok:
                print("Failed to read a frame from the camera.")
                break

            if frame_index % process_every_n_frames == 0:
                cached_results = recognize_faces_in_frame(
                    frame,
                    known_names,
                    known_embeddings,
                    tolerance=tolerance,
                    frame_scale=frame_scale,
                    detection_model=detection_model,
                )

            draw_recognition_results(frame, cached_results)
            cv2.imshow("Face Recognition", frame)

            key = cv2.waitKey(1) & 0xFF
            if key in (ord("q"), 27):
                break

            frame_index += 1
    finally:
        capture.release()
        cv2.destroyAllWindows()
