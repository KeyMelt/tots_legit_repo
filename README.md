# MSA_Hackathon

MSA_Hackathon is a face-recognition attendance and enrollment system built around a shared FastAPI backend and two frontend clients:

- A Flutter frontend for the original mobile-first hackathon experience.
- A lightweight Next.js frontend in `vercel_app/` built specifically for web deployment.

## Technical Stack

### Backend

- Python
- FastAPI
- Shared backend package under `backend/app/`
- Vercel-compatible entrypoint through `index.py`
- Local development entrypoint through `main.py`

Backend layout:

```text
backend/
  app/
    api.py
    config.py
    face_database.py
    live_enrollment.py
    profile_store.py
    schemas.py
    service.py
    utils.py
  data/
  known_people/
  playGround.py
index.py
main.py
```

### Mobile / Native Frontend

- Flutter
- Dart
- Camera integration
- HTTP-based communication with the shared FastAPI backend

Primary Flutter app locations:

```text
lib/
ios/
macos/
web/
pubspec.yaml
```

### Web Frontend

- Node.js
- Next.js App Router
- React
- TypeScript
- Vercel deployment configuration in `vercel_app/vercel.json`

Primary web frontend locations:

```text
vercel_app/
  app/
  components/
  lib/
  package.json
  next.config.ts
  vercel.json
```

## Why There Are Two Frontends

This repository intentionally keeps two frontend implementations because they serve different deployment and product needs:

- The Flutter frontend is the fuller original client built for the hackathon workflow and native-device interaction.
- The Node.js frontend is a lightweight web-first version created in lieu of Flutter for browser deployment.
- The Next.js app exists because deploying a lightweight React/Next.js frontend to the web is operationally simpler than shipping the Flutter client for the same web use case.
- Both frontends talk to the same backend so the recognition, enrollment, and session logic stays centralized.

In practice, this means:

- Flutter remains the richer native-oriented client.
- `vercel_app/` is the lightweight web deployment target.
- The backend remains the shared source of truth for API behavior.

## Application Operations

The system operates around a single backend service and two possible clients.

### Main User Flows

1. A user opens either the Flutter app or the Next.js web frontend.
2. The client captures camera input or uploads a frame for recognition.
3. The client sends requests to the FastAPI backend.
4. The backend runs the recognition or enrollment workflow.
5. The backend returns structured results to the client for display.
6. The client renders scan history, recognition output, or enrollment status.

### Enrollment Flow

1. Capture a face image or frame.
2. Send the enrollment request to the backend.
3. Persist identity/profile data through the backend package.
4. Reuse the same backend identity store across both frontends.

### Recognition Flow

1. Capture a live frame.
2. Send the frame to the shared API.
3. Run face matching and result packaging in the backend.
4. Return a normalized payload to whichever frontend initiated the request.

## Local Development

### Backend

Run the FastAPI server locally from the repository root:

```bash
.venv/bin/python -m uvicorn main:app --reload
```

### Flutter Frontend

Use the standard Flutter workflow from the repository root:

```bash
flutter pub get
flutter run
```

### Next.js Frontend

Run the lightweight web frontend from `vercel_app/`:

```bash
cd vercel_app
cp .env.example .env.local
npm install
npm run dev
```

## Deployment Model

Recommended deployment split:

1. Deploy the backend from the repository root.
2. Deploy `vercel_app/` separately as the web frontend.
3. Point the frontend at the deployed backend using `NEXT_PUBLIC_API_BASE_URL`.

This keeps the backend unchanged while allowing a lightweight web deployment path.

## Demo Videos

The repository includes compressed demo captures under `demos/`:

- `demos/demo-mobile.mp4`
- `demos/demo-web.mp4`

They correspond to the original local recordings but were compressed to make them repository-safe.

