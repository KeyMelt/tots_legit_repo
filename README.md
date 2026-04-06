# MSA_Hackathon

## Backend structure

The backend now uses a small app package that is shared by the notebook bridge,
the local FastAPI server, and the Vercel entrypoint:

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

## Local backend

```bash
.venv/bin/python -m uvicorn main:app --reload
```

## Vercel backend

Vercel's current FastAPI docs support zero-config entrypoints such as root
`index.py`, so the deployment entrypoint is:

```text
index.py -> backend.app.api:app
```
