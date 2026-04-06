from __future__ import annotations

from datetime import datetime, timezone
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import cv2
import face_recognition
import numpy as np

from .config import (
    DEFAULT_DETECTION_MODEL,
    DEFAULT_FRAME_SCALE,
    DEFAULT_TOLERANCE,
    UNKNOWN_CAPTURE_DIR,
)
from .face_database import detect_faces_and_encodings_in_frame, match_face_embedding
from .schemas import EnrollmentMemberManifest
from .service import RecognitionService


@dataclass
class UnknownCluster:
    cluster_id: int
    encodings: list[np.ndarray] = field(default_factory=list)
    crops: list[np.ndarray] = field(default_factory=list)
    saved_paths: list[Path] = field(default_factory=list)
    capture_dir: Path | None = None
    last_capture_frame: int = -999


def _match_unknown_cluster(
    query_encoding: np.ndarray,
    clusters: list[UnknownCluster],
    *,
    threshold: float = 0.42,
) -> UnknownCluster | None:
    if not clusters:
        return None

    centroids = [
        np.mean(np.stack(cluster.encodings), axis=0).astype(np.float32)
        for cluster in clusters
    ]
    distances = face_recognition.face_distance(centroids, query_encoding)
    best_index = int(np.argmin(distances))
    if float(distances[best_index]) <= threshold:
        return clusters[best_index]
    return None


def collect_unknown_face_clusters(
    *,
    camera_id: int = 0,
    max_unknown_people: int | None = None,
    samples_per_person: int = 5,
    sample_interval_frames: int = 12,
    tolerance: float = DEFAULT_TOLERANCE,
    frame_scale: float = DEFAULT_FRAME_SCALE,
    detection_model: str = DEFAULT_DETECTION_MODEL,
) -> list[UnknownCluster]:
    service = RecognitionService()
    capture = cv2.VideoCapture(camera_id)
    if not capture.isOpened():
        raise RuntimeError(f"Cannot open camera {camera_id}.")

    frame_index = 0
    clusters: list[UnknownCluster] = []
    session_dir = UNKNOWN_CAPTURE_DIR / (
        "session_" + datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    )
    session_dir.mkdir(parents=True, exist_ok=True)

    print("Unknown enrollment capture started.")
    print("Press 'q' or Esc to stop once enough samples are collected.")
    print(f"Captured crops will be saved to: {session_dir}")

    try:
        while True:
            ok, frame = capture.read()
            if not ok:
                print("Failed to read a frame from the camera.")
                break

            display_frame = frame.copy()
            detections = detect_faces_and_encodings_in_frame(
                frame,
                frame_scale=frame_scale,
                detection_model=detection_model,
            )

            for detection in detections:
                encoding = detection["encoding"]
                x, y, w, h = detection["box"]
                match = match_face_embedding(
                    encoding,
                    service.known_names,
                    service.known_embeddings,
                    tolerance=tolerance,
                )

                if match["name"] != "Unknown":
                    cv2.rectangle(display_frame, (x, y), (x + w, y + h), (0, 180, 0), 2)
                    cv2.putText(
                        display_frame,
                        str(match["name"]),
                        (x, max(y - 8, 12)),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.55,
                        (0, 255, 0),
                        2,
                    )
                    continue

                cluster = _match_unknown_cluster(encoding, clusters)
                if cluster is None:
                    if max_unknown_people is not None and len(clusters) >= max_unknown_people:
                        continue
                    cluster = UnknownCluster(
                        cluster_id=len(clusters) + 1,
                        capture_dir=session_dir / f"unknown_{len(clusters) + 1:02d}",
                    )
                    cluster.capture_dir.mkdir(parents=True, exist_ok=True)
                    clusters.append(cluster)

                cluster.encodings.append(encoding)
                if (
                    frame_index - cluster.last_capture_frame >= sample_interval_frames
                    and len(cluster.crops) < samples_per_person
                ):
                    y1 = max(y, 0)
                    x1 = max(x, 0)
                    y2 = min(y + h, frame.shape[0])
                    x2 = min(x + w, frame.shape[1])
                    crop = frame[y1:y2, x1:x2].copy()
                    if crop.size != 0:
                        cluster.crops.append(crop)
                        file_path = (cluster.capture_dir or session_dir) / (
                            f"frame_{len(cluster.saved_paths) + 1:03d}.jpg"
                        )
                        if cv2.imwrite(str(file_path), crop):
                            cluster.saved_paths.append(file_path)
                        cluster.last_capture_frame = frame_index

                label = f"Unknown {cluster.cluster_id} [{len(cluster.crops)}/{samples_per_person}]"
                cv2.rectangle(display_frame, (x, y), (x + w, y + h), (0, 70, 255), 2)
                cv2.putText(
                    display_frame,
                    label,
                    (x, max(y - 8, 12)),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.55,
                    (0, 140, 255),
                    2,
                )

            progress_text = f"Tracked unknown people: {len(clusters)}"
            cv2.putText(
                display_frame,
                progress_text,
                (20, 30),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.7,
                (255, 255, 255),
                2,
            )
            cv2.imshow("Unknown Enrollment Capture", display_frame)

            everyone_complete = bool(clusters) and all(
                len(cluster.crops) >= samples_per_person for cluster in clusters
            )
            if everyone_complete and (
                max_unknown_people is None or len(clusters) >= max_unknown_people
            ):
                print("Enough samples were collected for every tracked unknown person.")
                break

            key = cv2.waitKey(1) & 0xFF
            if key in (ord("q"), 27):
                break

            frame_index += 1
    finally:
        capture.release()
        cv2.destroyAllWindows()

    return [cluster for cluster in clusters if cluster.crops]


def run_unknown_enrollment_session(
    *,
    camera_id: int = 0,
    max_unknown_people: int | None = None,
    samples_per_person: int = 5,
) -> dict[str, Any]:
    clusters = collect_unknown_face_clusters(
        camera_id=camera_id,
        max_unknown_people=max_unknown_people,
        samples_per_person=samples_per_person,
    )
    if not clusters:
        print("No unknown people were captured for enrollment.")
        return {"enrolledCount": 0, "totalSavedImages": 0, "members": []}

    manifests: list[EnrollmentMemberManifest] = []
    image_groups: list[list[tuple[str, bytes]]] = []

    for cluster in clusters:
        if cluster.capture_dir is not None:
            print(
                f"Unknown person {cluster.cluster_id} captured {len(cluster.saved_paths)} frames in "
                f"{cluster.capture_dir}"
            )
        while True:
            label = input(
                f"Label for unknown person {cluster.cluster_id} "
                f"({len(cluster.crops)} captured frames): "
            ).strip()
            if label:
                break
            print("Please enter a non-empty label.")

        encoded_images: list[tuple[str, bytes]] = []
        if cluster.saved_paths:
            for index, path in enumerate(cluster.saved_paths, start=1):
                encoded_images.append(
                    (f"member_{cluster.cluster_id - 1}__frame_{index}.jpg", path.read_bytes())
                )
        else:
            for index, crop in enumerate(cluster.crops, start=1):
                ok, encoded = cv2.imencode(".jpg", crop)
                if ok:
                    encoded_images.append(
                        (f"member_{cluster.cluster_id - 1}__frame_{index}.jpg", encoded.tobytes())
                    )

        manifests.append(EnrollmentMemberManifest(label=label))
        image_groups.append(encoded_images)

    service = RecognitionService()
    result = service.enroll_members(manifests, image_groups)
    print(
        f"Enrolled {result['enrolledCount']} people with "
        f"{result['totalSavedImages']} saved images."
    )
    for member in result["members"]:
        print(f"- {member['attendee']['name']}: {member['savedImages']} images")
    return result
