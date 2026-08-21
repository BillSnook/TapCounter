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
  - **Double tap** → decrements the count.
  - **Triple tap** → zeroes the count out; triple-tap again to restore the
    value it had before it was zeroed (alternates each time).
- **Apple Watch app** — shows the same buttons with the same gestures, kept
  in sync with the iPhone app over WatchConnectivity.
- **Watch complication** — a small (circular) and medium (rectangular)
  complication that shows the app icon and launches the Watch app. Static for
  now (no live count).

## Project layout

```
TapCounter/
  README.md                You are here
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
  TapCounterWatchWidget/    watchOS WidgetKit extension — the complication
    TapCounterWidgetBundle.swift
    TapCounterComplication.swift   circular + rectangular families, static content
    Assets.xcassets/          ComplicationIcon.imageset (copy of the app icon)
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
3. Open `TapCounter.xcodeproj` in Xcode. Signing is already configured
   (development team `JXXDAFT8NW`, automatic signing) — bundle IDs are
   `com.billsnook.TapCounter` and friends; change the `bundleIdPrefix` in
   `project.yml` and re-run `xcodegen generate` if you'd rather use your own.
4. Run the **TapCounter** scheme on an iPhone (simulator or device). To try
   the Watch app, run the **TapCounterWatch** scheme on a paired Watch
   simulator, or just install the iOS app on a device with a paired Watch —
   Xcode will offer to install the Watch app alongside it.

Re-run `xcodegen generate` any time you add/remove/rename files — XcodeGen
picks up folder contents automatically, so you generally don't need to touch
`project.yml` for day-to-day file changes.

**Heads up:** `xcodegen generate` rebuilds `TapCounter.xcodeproj` from
`project.yml` every time, so anything you changed only in Xcode's UI and not
in `project.yml` gets reset. The development team (`JXXDAFT8NW`) is checked
into `project.yml` now (`DEVELOPMENT_TEAM` / `CODE_SIGN_STYLE: Automatic` in
the base settings), so regenerating won't wipe signing anymore — but any
other Xcode-only tweak (capabilities, custom build settings, etc.) still
will, unless it's also reflected in `project.yml`.

### Adding the complication to a watch face

After building and installing the Watch app, the complication ("TapCounter")
is available from the watch face editor under both a small/circular slot and
a medium/rectangular slot, same as any other complication — long-press the
watch face, tap Edit, and assign it to an open slot.

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
- **Gesture tuning**: tap/double-tap/triple-tap are implemented with
  SwiftUI's built-in `onTapGesture(count:)` disambiguation.
- **Complication families**: WidgetKit complications don't literally use the
  words "small"/"medium" — the closest mapping is `.accessoryCircular` (small,
  round) and `.accessoryRectangular` (medium, wide). There are two more
  families worth knowing about if you want fuller watch-face coverage later:
  `.accessoryCorner` and `.accessoryInline`. Add them to `supportedFamilies`
  in `TapCounterComplication.swift` and handle them in
  `TapCounterComplicationView`.
- **Complication data**: `TapCounterComplication.swift` uses a static
  `Timeline` with a single entry and `policy: .never` — it just shows the
  icon and opens the app, no live count. To show real counts later, the
  complication target will need to read `CounterStore` (it can add the
  `Shared` group to its `sources` in `project.yml`) and use a timeline
  `policy` that reloads, e.g. `.after(date:)` or `WidgetCenter.shared.reloadTimelines`
  triggered from the app/store whenever a count changes.
