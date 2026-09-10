# Workout

A native iPhone app for strength training, plus a desktop **Program Builder** website. Log sessions with a custom keypad and RIR, build rotating programs, follow recovery and volume, and pull runs from Apple Health. The website assembles programs from the same exercise catalog and exports JSON the app can import.

Requires **iOS 17+**.

This repo has two parts:

- **iPhone app** — SwiftUI client in `WorkoutApp/`
- **Program Builder** — static site in `program-builder/`

---

## Screenshots

| Home | Live workout |
|:---:|:---:|
| ![Home screen](docs/screenshots/home.png) | ![Live workout session](docs/screenshots/live-workout.png) |

| Workout | Info |
|:---:|:---:|
| ![Workout tab](docs/screenshots/workout.png) | ![Info tab](docs/screenshots/info.png) |

| Running | Settings |
|:---:|:---:|
| ![Running tab](docs/screenshots/running.png) | ![Settings](docs/screenshots/settings.png) |

---

## Features

### Home
- Year activity grid for **Weights**, **Running**, and **Both**
- Workout count and day-of-year on the year card
- **Today’s stress** under the year overview
- Next workout from your active program, or start an empty session

### Workout logging
- Custom number pad (no system keyboard) with rest timer
- **RIR** on the reps keypad, with an in-session explainer
- Planned vs logged sets (`X out of Y sets done`)
- Edit a logged set’s weight, reps, and RIR without adding a new set
- Plate calculator for barbell and functional-trainer lifts
- Exercise history and estimated **1RM** per movement

### Programs
- Multi-day programs with a rotating next workout
- Sets per exercise while building a day
- Overview after you tap Done: planned sets, muscle breakdown, and split notes
- Import a program JSON from the desktop builder via Workout → Programs → Import

### Learn
- Core movement categories
- Key muscle groups
- More strength patterns
- Related muscles and patterns as separate cards you can tap through

### Info
- Today’s stress and 7-day trend
- 7-day tonnage and reps (totals and per muscle)
- Volume, 1RM, engagement, and intensity charts
- Searchable exercise history
- Sections you can hide from Settings

### Running
- Reads running, walking, hiking, and cycling from **Apple Health**
- Filters, pace and heart-rate charts, route map when GPS exists

### Widgets
- **Year** — small, medium, and large year-in-pixels views
- **Today’s stress** — small and medium
- **Next workout** — small

### Settings
- Custom accent and appearance (including a custom background color)
- Light, dark, or system appearance
- kg/lb and km/mi
- Body weight log synced with Health
- Optional write of finished strength sessions to Apple Health (Traditional Strength Training)
- Export / import JSON backup
- Info-page visibility toggles

---

## Tech stack

| Layer | Choice |
|---|---|
| UI | SwiftUI |
| Persistence | SwiftData |
| Charts | Swift Charts |
| Maps | MapKit |
| Health | HealthKit (cardio read; body mass read/write; optional strength workout write) |
| Home screen | WidgetKit |

---

## App Store

- Privacy strings for HealthKit are in `Info.plist`
- `ITSAppUsesNonExemptEncryption` is `false`
- Strength sessions stay on-device unless the user turns on **Write finished workouts to Apple Health**
- Cardio workouts from Health are read-only
- Replace `com.local.WorkoutApp` with your production bundle ID and App Icon before submit

---

## Program Builder (web)

Desktop site to assemble rotating programs from the same exercise catalog (names and photos). Overview analysis covers 20 muscles, with views for **Upper / lower**, **Push / pull / legs**, and **Antagonists**. Export JSON and import it in the app via Workout → Programs → Import.

**Live site:** [Program Builder](https://YOUR-DEPLOY-URL) — paste your deployed URL here after you publish.

### Run locally

```bash
cd program-builder && python3 -m http.server
```

Then open the local URL (default `http://127.0.0.1:8000/`).

### Deploy

Static files live in `program-builder/`. On Vercel, set the project **Root Directory** to `program-builder`.

### Screenshots

| Builder | Exercise picker |
|:---:|:---:|
| ![Program Builder workspace](docs/screenshots/program-builder.png) | ![Exercise picker](docs/screenshots/program-builder-picker.png) |

| Overview | Antagonists |
|:---:|:---:|
| ![Push / pull / legs overview](docs/screenshots/program-builder-overview.png) | ![Antagonists overview](docs/screenshots/program-builder-antagonists.png) |
