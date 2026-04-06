# Synthetic Eye Vercel App

This folder contains the Vercel-safe web frontend for the hackathon build.

## Why this app exists

- The original Flutter frontend remains untouched.
- The backend remains the existing FastAPI app at the repo root.
- This frontend is a separate Next.js project designed for Vercel deployment.

## Architecture

- Frontend: Next.js App Router in `vercel_app/`
- Backend: FastAPI from repo root via `index.py`
- Integration: browser HTTP calls to the existing backend API

## Local setup

### 1. Create the frontend env file

```bash
cd vercel_app
cp .env.example .env.local
```

### 2. Create the backend validation venv

```bash
cd vercel_app
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```

Workspace note:

- In this workspace, `vercel_app/.venv` is linked to the repo root `.venv` because that environment already contains the backend stack.
- Recreating the backend env from scratch may require adjusting local Python and native build tooling for the pinned face-recognition stack.

### 3. Run the backend

```bash
cd /Users/ultramarine/Desktop/UniHackathon/MSA_Hackathon
vercel_app/.venv/bin/python -m uvicorn main:app --reload
```

### 4. Run the frontend

```bash
cd /Users/ultramarine/Desktop/UniHackathon/MSA_Hackathon/vercel_app
npm install
npm run dev
```

## Vercel deployment

Recommended deploy shape:

1. Create one Vercel project for the backend from the repo root.
2. Create a second Vercel project for the frontend with root directory set to `vercel_app`.
3. Set `NEXT_PUBLIC_API_BASE_URL` in the frontend project to the deployed backend URL.

This keeps the existing backend unchanged and makes the frontend Vercel-native.
