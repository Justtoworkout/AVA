# AVA — AI Voice Receptionist Supervisor

> A Flutter app for hospital staff to monitor and manage an AI voice receptionist powered by Vapi + Twilio + Google Calendar.

---

## Overview

AVA (AI Voice Assistant) is a companion mobile app that surfaces real-time data from an already-running Vapi voice AI receptionist. Staff can review call logs, upcoming appointments, dashboard stats, and alerts — all without touching the voice AI itself.

## Architecture

```
Vapi (voice AI) ──webhook──► Firebase Cloud Function
                                    │
                                    ▼
                             Firestore `calls` collection
                                    │
                        ┌──────────┴──────────┐
                        ▼                     ▼
                  Flutter App          Google Calendar API
                  (read-only)          (read-only)
```

## Stack

| Layer | Technology |
|-------|-----------|
| Mobile app | Flutter (Android + iOS) |
| Database | Firebase Firestore |
| Backend | Firebase Cloud Functions (Node 18) |
| Calendar | Google Calendar API v3 (read-only) |
| Voice AI | Vapi + Twilio (pre-existing, not modified) |

## Project Structure

```
gamma/
├── lib/
│   ├── main.dart
│   ├── models/          # Call, Appointment, Alert data classes
│   ├── services/        # Firestore, Calendar, Notification services
│   └── screens/         # Dashboard, Appointments, Calls, Alerts
├── backend/
│   ├── functions/       # Firebase Cloud Function (webhook handler)
│   └── BACKEND_SETUP.md
├── .env.example
├── PROGRESS.md
└── README.md
```

## Phases

- [x] Phase 0 — Scaffold
- [ ] Phase 1 — Backend (Firestore + Cloud Function webhook)
- [ ] Phase 2 — App shell + Calls tab
- [ ] Phase 3 — Appointments tab (Google Calendar)
- [ ] Phase 4 — Dashboard tab
- [ ] Phase 5 — Alerts tab
- [ ] Phase 6 — Polish

## Setup

See `.env.example` for required credentials.  
See `backend/BACKEND_SETUP.md` for Cloud Function deploy steps.
