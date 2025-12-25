# Tock

<img src="Tock/AppIcon.png" alt="Tock app icon" width="128">

Super-minimal menubar timer with quick parsing, stopwatch mode, and a repeating chime.

## Features

- Menubar timer shows countdown or stopwatch time with monospaced digits.
- Single input field with natural-language inputs: `10`, `5m`, `1.5h`, `45 sec`, etc. (defaults to minutes when unit is omitted).
- Countdown stays at `00:00:00` when finished, with controls still enabled.
- Countdown alarm repeats up to 10 times or until cleared.
- Stopwatch mode when no countdown is running (or after a countdown finishes).
- Right-click menubar icon for Open, Stopwatch, Pause/Restart, Clear, and Quit.

## Shortcuts

- Open popover: ⌃⌥⌘T
- Clear timer: ⌃⌥⌘X

## Build and Run

1. Open `Tock.xcodeproj` in Xcode.
1. Select the `Tock` scheme.
1. Build and Run.

## Archive and Export

1. `Product > Archive`
1. Organizer > `Distribute App` > `Custom` > `Copy App`
1. Open the export folder and move the inner `Tock.app` to `/Applications`.

## Login Item

- Add via `System Settings > General > Login Items`.

## Assets

- App icon: `Tock/AppIcon.icns`
- Alarm sound: `Tock/Sounds/chime.mp3`

## Todo

- Settings menu
- Open on startup alert
- Editable hotkeys
- Custom chime + volume control
- Recent durations / favorites
- Notification banner on finish
- Website and dowwnloads
