# DoomClock

DoomClock is a minimalist watchOS-only SwiftUI app for creating a fictional personal Doomsday countdown.

It is not a prediction tool, warning system, emergency app, or real-world alerting product. It is a symbolic retro terminal-style countdown experience built for Apple Watch.

## Features

- Guided first-run onboarding
- User-selected fictional target date and time
- Optional future editing lock
- Live countdown with days, hours, minutes, and seconds
- Expired state handling
- Threat mode color themes:
  - Calm
  - Suspicious
  - Critical
  - Armageddon
- Local persistence with `UserDefaults.standard`
- Watch haptics for key actions
- Retro terminal-inspired Apple Watch UI
- Custom app icon

## Platform

- iOS 17+ (iPhone companion)
- watchOS 11.6+ (embedded Watch app)
- SwiftUI
- No network dependency
- Local persistence only (`UserDefaults.standard` per platform)

## v1 Release Note

WidgetKit complications are intentionally disabled for the v1 release.

The complication source files are kept in the repository for a future v1.1 release, but the Watch app target does not currently build or embed the Widget Extension. This keeps the v1 install clean and avoids App Group/provisioning issues while the core watchOS app ships first.

Kept for future complication support:

- `DoomClockComplication.swift`
- `CountdownFormatter.swift`
- `SharedDefaults.swift`

## Persistence

For v1, settings are stored with `UserDefaults.standard`.

Persisted values include:

- Target date
- Countdown start date
- Doom mode
- Onboarding completion state
- Future editing preference

App Group storage is currently disabled and documented in code for future complication support.

## Project Structure

```text
DoomClock iOS/
  Services/          # UIKit haptics
  ViewModels/
  Views/
    Components/

DoomClock Watch App/
  Services/          # WatchKit haptics
  ViewModels/
  Views/
    Components/

DoomClock Complication/
  DoomClockComplication.swift

Shared/
  CountdownFormatter.swift
  DoomMode.swift
  DoomSettings.swift
  PersistenceService.swift
  SharedDefaults.swift
```

## Build

Open `DoomClock.xcodeproj` in Xcode.

- **iPhone:** run the `DoomClock iOS` scheme (embeds the Watch app for App Store distribution).
- **Watch only (development):** run the `DoomClock Watch App` scheme on a Watch simulator or device.

The complication target is present for a future v1.1 release and is not embedded in v1 products.

## Design Direction

DoomClock uses an original retro atomic terminal aesthetic:

- Dark terminal background
- Monospaced typography
- High-contrast countdown numbers
- Minimal scanline treatment
- No copyrighted game UI, names, symbols, or branding

## Disclaimer

DoomClock is fictional software for mood, reflection, and fun. It does not predict, detect, warn about, or respond to real-world events.
