# AVA Demo Script

**Time:** ~5 minutes | **Audience:** Clinical staff / hospital admin

---

## Setup (before demo)

- [ ] App installed on device, Firebase + Calendar configured
- [ ] At least 3–5 calls in Firestore (`calls` collection)  
      — include 1 `failed`, 1 `transferred`, 2 `booked`
- [ ] Google Calendar has 2–3 upcoming appointments
- [ ] If live testing: Vapi webhook pointed at deployed Cloud Function

---

## Walk-through

### 1 · Dashboard (30 sec)

> *"This is AVA's command center. Everything your receptionist handled today, at a glance."*

- Point to **Calls Today**, **Appointments Booked**, **Failed / Missed**
- Note the **LIVE** badge — data updates in real time via Firestore
- Scroll down: **Recent Calls** shows the last 5 calls with outcome dots
- Pull down to refresh

---

### 2 · Calls Tab (90 sec)

> *"Every call AVA handled is logged here — who called, what happened, for how long."*

- Show the call list — outcome badges (green Booked, red Failed, amber Transferred)
- Tap a filter chip: **Failed** → list narrows instantly (client-side, no new fetch)
- Tap a call to open the **Detail screen**:
  - Metadata card: patient number, time, duration
  - **AI Summary** — one-sentence recap
  - **Recording player** — hit play, scrub the timeline
  - **Transcript** — speaker-colored (AVA in purple, Patient in blue)
  - Tap copy icon → transcript on clipboard

---

### 3 · Appointments Tab (60 sec)

> *"All appointments AVA booked, pulled live from your Google Calendar."*

- Show **Today** section highlighted in purple
- Show **Tomorrow / future days** grouped below
- Each card: time strip on left, title + duration + location on right
- Pull down to refresh

---

### 4 · Alerts Tab (60 sec)

> *"When something goes wrong, AVA flags it here immediately."*

- Show **red count badge** in the tab bar (number of active alerts)
- **Failed Calls** section: red strip, error icon
- **Transferred** section: amber strip, swap icon
- Tap **"View call details"** → jumps straight to transcript
- Mention: a **push notification** fires the moment a new failure comes in,  
  even if the app is in the background

---

### 5 · Live Demo (if available, 60 sec)

1. Place a test call to the Vapi number
2. Let it run for 20–30 seconds, then hang up
3. Within seconds: Dashboard call count increments
4. If Vapi marks it failed/transferred: Alerts badge lights up + push arrives

---

## Key Talking Points

| Feature | Benefit |
|---------|---------|
| Real-time Firestore sync | Staff see call outcomes the instant they happen |
| Full transcript + audio | Review any call, resolve patient disputes |
| Google Calendar integration | Appointments visible alongside call context |
| Zero-auth companion app | No login friction — open and go |
| Local push notifications | Never miss a failed call, even phone is locked |

---

## Config Checklist (for handoff)

| Item | File | Status |
|------|------|--------|
| Firebase Project ID | `backend/.firebaserc` | ⬜ |
| Cloud Function deployed | `backend/BACKEND_SETUP.md` | ⬜ |
| Vapi webhook URL set | Vapi dashboard → Server URL | ⬜ |
| `google-services.json` | `android/app/` | ⬜ |
| `firebase_options.dart` | `lib/firebase_options.dart` | ⬜ |
| Google Calendar API key | `lib/config/app_config.dart` | ⬜ |
| Calendar ID | `lib/config/app_config.dart` | ⬜ |
| App icon generated | `flutter pub run flutter_launcher_icons` | ⬜ |
