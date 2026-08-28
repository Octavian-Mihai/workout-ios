# Workout (iOS)

Native iPhone workout tracker built with **SwiftUI** and **SwiftData**. Log strength sessions with a custom keypad and RIR tracking, build your own programs, analyze training stress, sync runs from Apple Health, and customize the app accent.

Requires **iOS 17+**.

---

## Screenshots

| Home | Live workout |
|:---:|:---:|
| ![Home screen](docs/screenshots/home.png) | ![Live workout session](docs/screenshots/live-workout.png) |

| Workout (Learn) | Info (Analytics) |
|:---:|:---:|
| ![Workout tab](docs/screenshots/workout.png) | ![Info analytics](docs/screenshots/info.png) |

| Running | Settings |
|:---:|:---:|
| ![Running tab](docs/screenshots/running.png) | ![Settings](docs/screenshots/settings.png) |

---

## Features

### Home
- Year activity grid with **Weights**, **Running**, and **Both** day markers
- Next workout from your active program rotation
- Start an empty workout anytime
- **Today's stress** estimate from recent lifting + running load

### Workout logging
- Custom **4×4 number pad** (no system keyboard) with rest timer
- **RIR** input on the reps keypad (color-coded 0–5+)
- **Plate calculator** for barbell and functional-trainer exercises
- Per-set history: last session performance + 4-column set grid
- Swipe left to delete a logged set
- Minimize an in-progress session and resume from a floating pill
- Exercise history & **1RM estimate** per movement

### Programs
- Create multi-day programs with exercise rotation
- Optional save of a changed day template after a programmed session

### Info
- Personal stress dashboard (today + 7-day trend)
- Strength analytics: volume, 1RM charts, muscle engagement, intensity map, central/total stress (0–100)

### Running
- Reads runs from **Apple Health** (read-only)
- Filters, pace/HR charts, route map when GPS data exists
- Runs older than 2 weeks grouped in a collapsible section

### Settings
- Accent color: 5 presets + custom color picker (spectrum / sliders)
- Light, dark, or system appearance
- kg/lb and km/mi units
- Body weight log synced with HealthKit
- Export / import workout data (JSON backup)
- Delete local data, privacy info, HealthKit permissions

---

## Tech stack

| Layer | Choice |
|---|---|
| UI | SwiftUI |
| Persistence | SwiftData |
| Charts | Swift Charts |
| Maps | MapKit |
| Health | HealthKit (running read, body mass read/write) |
| Project | [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`) |

---

## Getting started

### Requirements
- macOS with **Xcode 15+** (iOS 17 SDK)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

### Open the project

```bash
git clone https://github.com/Octavian-Mihai/workout-ios.git
cd workout-ios
xcodegen generate
open WorkoutApp.xcodeproj
```

Select an **iPhone** simulator or a physical device, set your **Team** under Signing & Capabilities, then **Run**.

### HealthKit on device
Running analytics and body-weight sync need Apple Health permission on a **physical iPhone**. The simulator has limited Health data unless you add samples manually.

---

## Project structure

```
workout_ios/
├── WorkoutApp/
│   ├── App/              Root tab view, app entry
│   ├── Features/         Home, Workout, Session, Program, Running, Info, Settings
│   ├── Models/           SwiftData models + exercise catalog
│   ├── Services/         Stress, 1RM, HealthKit, backup
│   ├── Shared/           Activity grid, RIR, formatters
│   └── Theme/            Accent, cards, units
├── WorkoutAppUITests/    UI tests (includes screenshot capture)
├── docs/screenshots/     README screenshots
├── project.yml
└── Info.plist
```

---

## Regenerate README screenshots

```bash
xcodegen generate
xcodebuild test \
  -project WorkoutApp.xcodeproj \
  -scheme WorkoutApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:WorkoutAppUITests/ScreenshotTests/testCaptureScreenshots \
  CODE_SIGNING_ALLOWED=NO
```

PNG files are written to `docs/screenshots/`.

---

## App Store notes

Before submitting:
- Replace `com.local.WorkoutApp` with your production bundle ID
- Add App Icon marketing assets
- Configure HealthKit capability with your Apple Developer team
- Privacy strings for HealthKit are in `Info.plist`
- `ITSAppUsesNonExemptEncryption` is set to `false`

---

## License

Private project — all rights reserved unless a license file is added.
