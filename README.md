# TapCounter

A SwiftUI iOS app for creating custom tap counters, with a watchOS companion
app that mirrors the same buttons.

## What it does

- **Button creator/editor** — add a named counter button, optionally give it
  a starting count, or edit/delete an existing one.
- **List of buttons** — every button you've created, each showing its name
  and a large, prominent count.
- **Gestures on each button:**
  - **Tap** → increments the count.
  - **Long press** → decrements the count.
  - **Double tap** → zeroes the count out; double-tap again to restore the
    value it had before it was zeroed (alternates each time).
- **Apple Watch app** — shows the same buttons with the same gestures, kept
  in sync with the iPhone app over WatchConnectivity.

## Project layout

```
TapCounter/
  project.yml              XcodeGen spec — generates the .xcodeproj
  Shared/                  Code used by both the iOS and watchOS targets
    CounterButtonItem.swift    the counter model + increment/decrement/zero logic
    CounterStore.swift         @Observable store, JSON persistence, sync hooks
  TapCounter/               iOS app target
    TapCounterApp.swift
    ContentView.swift          list of buttons
    ButtonEditorView.swift     create/edit form
    CounterButtonRow.swift     the functional button + its gestures
    PhoneConnectivityManager.swift   sends/receives state to/from the Watch
    Assets.xcassets/
  TapCounterWatch/          watchOS app target
    TapCounterWatchApp.swift
    WatchContentView.swift
    WatchCounterButtonRow.swift
    WatchConnectivityManager.swift
    Assets.xcassets/
  TapCounterTests/          Unit tests for the counting/zero-restore logic
```

## Building the project

This project's `.xcodeproj` is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen)
rather than checked in, so it never goes stale relative to `project.yml`.

1. Install XcodeGen (one-time):
   ```
   brew install xcodegen
   ```
2. From the `TapCounter` folder, generate the Xcode project:
   ```
   cd TapCounter
   xcodegen generate
   ```
3. Open `TapCounter.xcodeproj` in Xcode.
4. Select the **TapCounter** target, go to *Signing & Capabilities*, and pick
   your development team (bundle IDs are `com.billsnook.TapCounter` and
   `com.billsnook.TapCounter.watchkitapp` — change the `bundleIdPrefix` in
   `project.yml` and re-run `xcodegen generate` if you'd rather use your own).
5. Run the **TapCounter** scheme on an iPhone (simulator or device). To try
   the Watch app, run the **TapCounterWatch** scheme on a paired Watch
   simulator, or just install the iOS app on a device with a paired Watch —
   Xcode will offer to install the Watch app alongside it.

Re-run `xcodegen generate` any time you add/remove/rename files — XcodeGen
picks up folder contents automatically, so you generally don't need to touch
`project.yml` for day-to-day file changes.

## Notes

- **Deployment targets**: iOS 17 / watchOS 10, so the app can use the
  `@Observable` macro (Observation framework), `NavigationStack`,
  `ContentTransition.numericText`, and `ContentUnavailableView`.
- **Sync**: each device keeps its own local JSON file
  (`counters.json` in the app's Documents directory) and pushes the full
  button list to the paired device via `WCSession.updateApplicationContext`
  whenever it changes. This is a simple last-write-wins sync — fine for a
  personal counter list, but if two devices edit the same button offline at
  the same time, the most recent `updateApplicationContext` wins.
- **App icon**: a placeholder icon is included (`icon-1024.png` in both
  `Assets.xcassets`) so the project builds cleanly; swap it for real artwork
  before shipping.
- **Gesture tuning**: tap/long-press/double-tap are implemented with
  SwiftUI's built-in `onTapGesture(count:)` disambiguation plus
  `onLongPressGesture`. This is the standard approach, but exact timing feel
  is worth testing on a real device — adjust `minimumDuration` in
  `CounterButtonRow.swift` / `WatchCounterButtonRow.swift` if long-press
  feels too eager or too slow.

