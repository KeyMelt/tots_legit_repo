# %% [markdown]
# # Synthetic Eye Backend Notebook Bridge
#
# This file keeps the notebook-style cell workflow while delegating all real logic
# to the reusable backend package under `backend/app/`.
#
# Use this file for:
# 1. rebuilding the face database from `known_people/<label>/`
# 2. inspecting the synchronized member profile store
# 3. running live recognition
# 4. capturing unknown people from the webcam, labeling them, and enrolling them


# %%
from __future__ import annotations

from backend.app.api import service
from backend.app.config import (
    BACKEND_DIR,
    DATABASE_PATH,
    KNOWN_PEOPLE_DIR,
    MEMBER_PROFILES_PATH,
    SCAN_HISTORY_PATH,
)
from backend.app.face_database import (
    build_face_database,
    load_face_database,
    print_enrollment_report,
    run_live_recognition,
    summarize_database,
)
from backend.app.live_enrollment import run_unknown_enrollment_session
from backend.app.profile_store import load_member_profiles

print(f"Backend directory: {BACKEND_DIR}")
print(f"Known people directory: {KNOWN_PEOPLE_DIR}")
print(f"Face database path: {DATABASE_PATH}")
print(f"Member profile path: {MEMBER_PROFILES_PATH}")
print(f"Scan history path: {SCAN_HISTORY_PATH}")


# %% [markdown]
# ## Stage A: Rebuild the face database from folders
#
# Every folder in `known_people/` is treated as one person label.
# Images with zero or multiple faces are skipped.


# %%
# Example:
# database, report = build_face_database()
# print_enrollment_report(report)
# summarize_database(database)


# %% [markdown]
# ## Stage B: Inspect the synced profile registry
#
# The profile file stores the status and detail payload used by the frontend.
# New enrollments are added here automatically.


# %%
database = load_face_database()
profiles = load_member_profiles()
summarize_database(database)
print(f"Profiles synced: {len(profiles)}")
for profile in profiles[:10]:
    print(f"- {profile['name']} [{profile['status']}]")


# %% [markdown]
# ## Stage C: Live recognition
#
# Press `q` or `Esc` to close the OpenCV window.


# %%
# run_live_recognition(
#     camera_id=0,
#     tolerance=0.50,
#     frame_scale=0.50,
#     process_every_n_frames=1,
# )


# %% [markdown]
# ## Stage D: Unknown-member enrollment from live capture
#
# This session watches the webcam, groups recurring unknown faces, captures a few
# crops for each one, then prompts you for labels in order.
#
# If six unknown people appear, the session can gather samples for all six,
# ask you to label them one by one, create folders under `known_people/<label>/`,
# save the captured images using the entered labels, and rebuild `known_faces.json`.


# %%
# result = run_unknown_enrollment_session(
#     camera_id=0,
#     max_unknown_people=6,
#     samples_per_person=5,
# )
# print(result)


# %% [markdown]
# ## Stage E: Refresh the in-memory API service
#
# Use this cell after manual edits to `known_people/` or profile files.


# %%
# service.reload_state()
