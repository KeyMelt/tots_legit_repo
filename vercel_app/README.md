# Synthetic Eye Vercel App

This folder contains the lightweight Node.js frontend for the MSA_Hackathon project.

## Purpose

The repository already contains a Flutter frontend, but `vercel_app/` exists as a lighter web deployment target:

- Flutter remains the original fuller client.
- `vercel_app/` is the lightweight Next.js version built specifically for web deployment.
- Both clients consume the same FastAPI backend.

## Technical Stack

- Node.js
- Next.js App Router
- React
- TypeScript
- Vercel

## Folder Structure

```text
vercel_app/
  app/
  components/
  lib/
  package.json
  next.config.ts
  vercel.json
```

## How It Operates

1. The browser frontend collects user interaction and camera-driven workflow input.
2. The frontend sends HTTP requests to the shared FastAPI backend.
3. The backend performs recognition, enrollment, and result assembly.
4. The frontend renders scan state, result detail, and history-oriented UI flows.

This keeps the browser client thin and shifts business logic to the backend.

## Local Setup

Create the frontend env file:

```bash
cd vercel_app
cp .env.example .env.local
```

Run the frontend:

```bash
cd vercel_app
npm install
npm run dev
```

Run the backend from the repository root:

```bash
.venv/bin/python -m uvicorn main:app --reload
```

## Deployment

Recommended deploy shape:

1. Deploy the backend from the repository root.
2. Deploy `vercel_app/` as a separate Vercel project.
3. Set `NEXT_PUBLIC_API_BASE_URL` to the deployed backend URL.

## Demo Videos

See the repository-level demo assets:

- `../demos/demo-mobile.mp4`
- `../demos/demo-web.mp4`

