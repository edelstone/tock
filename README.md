# Tock

<img src="Tock/AppIcon.png" alt="Tock app icon" width="128">

Super-minimal menubar timer with quick parsing, stopwatch mode, and configurable repeating tones.

## Features

- Menubar timer with countdown + stopwatch, plus quick natural-language input.
- Configurable notification tone, repeat count, and alert volume.
- Context menu and popover controls for start/pause/clear and settings.

## Usage

- Enter a duration like `10`, `5m`, `1.5h`, or `45 sec`, then press Enter.
- Click the play button to start a stopwatch without a countdown.
- Clear stops the timer and silences the alarm.

## Shortcuts

- Open popover: ⌃⌥⌘T
- Clear timer: ⌃⌥⌘X

## Build and run

1. Open `Tock.xcodeproj` in Xcode.
1. Select the `Tock` scheme.
1. Build and run.

## Archive and export

1. `Product > Archive`
1. Organizer > `Distribute App` > `Custom` > `Copy App`
1. Open the export folder and move the inner `Tock.app` to `/Applications`.

## Login item

- Add via `System Settings > General > Login Items`.
