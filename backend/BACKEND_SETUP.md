# Backend Setup — Phase 1

## Prerequisites

| Tool | Install |
|------|---------|
| Node.js 18+ | https://nodejs.org |
| Firebase CLI | `npm install -g firebase-tools` |
| Firebase account | https://console.firebase.google.com |

---

## Step 1 — Create Firebase Project

1. Go to https://console.firebase.google.com → **Add project**
2. Project name: e.g. `ava-hospital` (note the auto-generated Project ID)
3. **Disable** Google Analytics (not needed)
4. Once created:
   - Go to **Build → Firestore Database** → Create database
   - Choose **Native mode**, region: `us-central1` (or nearest)
5. Go to **Build → Functions** → Get started
   - Requires **Blaze (pay-as-you-go)** plan — Cloud Functions need it
   - Free tier covers ~2M invocations/month (more than enough for a clinic)

---

## Step 2 — Configure Local Files

```bash
cd backend/
```

Edit `.firebaserc`, replace `YOUR_FIREBASE_PROJECT_ID`:
```json
{ "projects": { "default": "your-actual-project-id" } }
```

Login and select project:
```bash
firebase login
firebase use your-actual-project-id
```

---

## Step 3 — Install Dependencies

```bash
cd backend/functions/
npm install
cd ..
```

---

## Step 4 — Deploy Firestore Rules + Function

```bash
# From backend/ directory:
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions
```

Expected output:
```
✔  functions[vapiWebhook(us-central1)]: Successful create operation.
Function URL (vapiWebhook(us-central1)):
https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/vapiWebhook
```

**Copy that URL** — you'll need it for Vapi.

---

## Step 5 — Configure Vapi Webhook

1. Log into https://dashboard.vapi.ai
2. Go to **Settings → Server URL** (or your Assistant → Server URL)
3. Set URL to:
   ```
   https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/vapiWebhook
   ```
4. Vapi will POST `end-of-call-report` events to this URL after every call

---

## Step 6 — Verify

Test with curl (or Postman):
```bash
curl -X POST https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/vapiWebhook \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "type": "end-of-call-report",
      "call": {
        "id": "test-call-001",
        "customer": { "number": "+15551234567" },
        "startedAt": "2024-01-15T10:00:00Z",
        "endedAt": "2024-01-15T10:03:30Z",
        "endedReason": "customer-ended-call"
      },
      "transcript": "AI: Hello, how can I help?\nPatient: I need to book an appointment.\nAI: Sure, I have booked you for Monday at 2pm.",
      "recordingUrl": null,
      "summary": "Patient booked appointment for Monday 2pm.",
      "analysis": { "successEvaluation": "true" }
    }
  }'
```

Expected response: `{"status":"ok","id":"test-call-001"}`

Check Firestore: go to Firebase Console → Firestore → `calls` collection → document `test-call-001` should appear.

---

## Firestore `calls` Collection Schema

| Field | Type | Description |
|-------|------|-------------|
| `patientNumber` | string | Caller phone (e.g. `+15551234567`) |
| `timestamp` | timestamp | Call end time (Firestore Timestamp) |
| `durationSeconds` | number | Total call duration |
| `outcome` | string | `booked` / `failed` / `transferred` / `completed` |
| `transcript` | string | Full conversation text |
| `recordingUrl` | string? | Vapi recording URL (nullable) |
| `summary` | string? | AI-generated summary (nullable) |
| `vapiCallId` | string? | Vapi's call ID (used as doc ID) |

---

## Outcome Mapping Logic

| Vapi `endedReason` | Vapi `successEvaluation` | AVA `outcome` |
|--------------------|--------------------------|---------------|
| `transfer` | any | `transferred` |
| `pipeline-error` / `error` | any | `failed` |
| any | `"true"` | `booked` |
| any | `"false"` | `failed` |
| any | `"unknown"` | `completed` |

---

## Webhook URL (fill after deploy)

```
CLOUD_FUNCTION_WEBHOOK_URL=https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/vapiWebhook
```

---

## Local Emulator (optional, for testing without deploy)

```bash
cd backend/
firebase emulators:start --only functions,firestore
```
Emulator UI: http://127.0.0.1:4000  
Webhook URL (local): `http://127.0.0.1:5001/YOUR_PROJECT_ID/us-central1/vapiWebhook`
