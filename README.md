# Tock

<img src="Tock/AppIcon.png" alt="Tock app icon" width="128">

Super-minimal menubar timer with quick parsing, stopwatch mode, and configurable repeating tones.

## Features

- Menubar timer with countdown + stopwatch, plus quick natural-language input.
- Notification settings for tone (default: gentle-roll), repeat (default: 10x), volume (default: medium), and unit when omitted (default: minutes).
- Context menu and popover controls for start/pause/clear and settings.

## Usage

- Enter a duration like `10`, `5m`, `1.5h`, or `45 sec`, then press Enter.
- Click the play button to start a stopwatch without a countdown.
- Clear stops the timer and silences the alarm.

## Shortcuts

- Open popover: ⌃⌥⌘T
- Clear timer: ⌃⌥⌘X

## Download

Download the latest macOS build:

[![Download](https://img.shields.io/github/v/release/edelstone/tock?label=Download)](https://github.com/edelstone/tock/releases/latest/download/Tock.dmg)

To install:

1. Drag `Tock.app` to `/Applications`.
1. If macOS says the app is damaged, run this in Terminal: `xattr -dr com.apple.quarantine /Applications/Tock.app`
1. Add the app to your login items via `System Settings > General > Login Items`.

## Local development

For developers:

### Build and run

1. Open `Tock.xcodeproj` in Xcode.
1. Select the `Tock` scheme.
1. Build and run.

### Archive and export

1. `Product > Archive`
1. Organizer > `Distribute App` > `Custom` > `Copy App`
1. Open the export folder and move the inner `Tock.app` to `/Applications`.

## License

MIT, use freely in commercial and personal projects.
