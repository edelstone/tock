# Tock

<img src="Tock/AppIcon.png" alt="Tock app icon" width="128">

Super-minimal menubar timer with quick parsing, stopwatch mode, and configurable repeating tones.

## Features

- Menubar timer with countdown + stopwatch, plus quick natural-language input.
- Notification settings for tone (default: light-hearted), repeat (default: 10x), volume (default: medium), and unit when omitted (default: minutes).
- Context menu and popover controls for start/pause/clear and settings.

## Usage

- Enter a duration like `10`, `5m`, `1.5h`, `45 sec`, or `17m 45s`, then press Enter.
- Enter a time like `10pm` or `6:15a` to count down until the next occurrence.
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
1. Optional: add the app to your login items via `System Settings > General > Login Items`.

## Releasing

See [docs/RELEASING.md](docs/RELEASING.md) for the full release and personal dev workflow.

## Credits

All sounds from [Notification Sounds](https://notificationsounds.com).

## License

MIT, use freely in commercial and personal projects.
