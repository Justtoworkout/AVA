# AVA — Progress Tracker

## Current Phase: 6 — Polish ✅ ALL PHASES COMPLETE

---

## Done

### Phase 0 — Scaffold ✅
### Phase 1 — Backend ✅ (Cloud Function + BACKEND_SETUP.md)
### Phase 2 — App Shell + Calls Tab ✅
### Phase 3 — Appointments Tab ✅
### Phase 4 — Dashboard Tab ✅
### Phase 5 — Alerts Tab ✅

### Phase 6 — Polish ✅
- App icon generated (deep navy + violet "A" waveform mark)
  - `assets/images/app_icon.png` — source image
  - `pubspec.yaml` — flutter_launcher_icons configured (adaptive Android + iOS)
  - Run `flutter pub run flutter_launcher_icons` to generate all platform sizes
- `DEMO_SCRIPT.md` — 5-min walk-through, setup checklist, config handoff table
- Final pubspec.yaml review — clean, no unused deps
- Flutter SDK downloaded and extracting to `~\flutter\`

## Empty / Loading / Error States (all screens ✅)
| Screen | Empty | Loading | Error |
|--------|-------|---------|-------|
| Dashboard | "No calls yet" in recent | shimmer boxes | ErrorState + retry |
| Appointments | EmptyState widget | shimmer cards | ErrorState (friendly API msgs) |
| Calls | EmptyState per filter | shimmer list | ErrorState |
| Alerts | "All clear" EmptyState | shimmer cards | ErrorState |
| Call Detail | "No transcript" text | audio player spinner | "Could not load recording" |

## Files Touched (Phase 6)
```
assets/images/app_icon.png   ← NEW (generated)
pubspec.yaml                 ← UPDATED (launcher icons)
DEMO_SCRIPT.md               ← NEW
PROGRESS.md
```

## Full Project File Tree
```
gamma/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart        ← FILL IN (flutterfire configure)
│   ├── config/app_config.dart       ← FILL IN (API key + calendar ID)
│   ├── models/
│   │   ├── call_record.dart
│   │   ├── appointment.dart
│   │   ├── alert.dart
│   │   └── dashboard_stats.dart
│   ├── services/
│   │   ├── firestore_service.dart
│   │   ├── calendar_service.dart
│   │   └── notification_service.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── appointments_screen.dart
│   │   ├── calls_screen.dart
│   │   ├── call_detail_screen.dart
│   │   └── alerts_screen.dart
│   ├── theme/app_theme.dart
│   └── widgets/
│       ├── stat_card.dart
│       ├── outcome_badge.dart
│       ├── call_list_tile.dart
│       ├── appointment_card.dart
│       ├── alert_card.dart
│       ├── empty_state.dart
│       └── error_state.dart
├── backend/
│   ├── functions/index.js           ← Vapi webhook handler
│   ├── functions/package.json
│   ├── firebase.json
│   ├── .firebaserc                  ← FILL IN project ID
│   ├── firestore.rules
│   └── BACKEND_SETUP.md
├── android/app/src/main/AndroidManifest.xml
├── assets/images/app_icon.png
├── pubspec.yaml
├── DEMO_SCRIPT.md
├── PROGRESS.md
├── README.md
├── .env.example
└── .gitignore
```

## Launch Checklist
1. `flutter pub get`
2. Fill `lib/firebase_options.dart` (flutterfire configure OR manual)
3. Copy `google-services.json` → `android/app/`
4. Fill `lib/config/app_config.dart` (API key + calendar ID)
5. `flutter pub run flutter_launcher_icons`
6. Deploy backend: see `backend/BACKEND_SETUP.md`
7. Set Vapi webhook URL → Cloud Function URL
8. `flutter run`

## Blockers
- None — all code complete
- Flutter SDK: extracted to `~\flutter\flutter\bin\flutter.bat` (add to PATH)
