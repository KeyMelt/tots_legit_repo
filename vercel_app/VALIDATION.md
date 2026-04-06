# Validation Matrix

## Flutter-to-Next flow mapping

| Flutter flow | Next.js route | Backend calls |
| --- | --- | --- |
| Splash + onboarding | `/` | none |
| Login | `/login` | none |
| Sign up | `/signup` | none |
| Scan via upload | `/scan` | `POST /api/scans` |
| Scan via browser camera capture | `/scan` | `POST /api/scans` |
| Result detail | `/result/[resultId]` | none by default, fallback `GET /api/attendees/{id}` |
| History list | `/history` | `GET /api/attendees?filter=...` |
| History attendee detail | `/history` modal | `GET /api/attendees/{id}` |
| Settings approval registry | `/settings` | `GET /api/member-profiles`, `PUT /api/approved-guests` |
| Unknown enrollment | `/enroll` | `POST /api/enrollments` |

## Manual validation scenarios

- Load onboarding, navigate to login and sign up, and validate client-only auth behavior.
- Submit a scan from an uploaded image and verify the result page matches backend status, note, and confidence.
- Enable the browser camera, capture a frame, and verify the same scan flow works without Flutter.
- Open history, switch all filter tabs, and verify the list changes with backend data.
- Open a history row and verify attendee details load correctly.
- Open settings, toggle approvals, save, and verify the save round-trip refreshes the registry.
- Open enrollment, add multiple frames for one or more people, save, and verify success messaging plus backend persistence.
- Refresh deep links such as `/history`, `/settings`, and `/result/[id]` and verify the app still renders.

## Command checks

```bash
cd vercel_app
npm run lint
npm run typecheck
npm run build
```

```bash
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/api/attendees
curl http://127.0.0.1:8000/api/member-profiles
```
