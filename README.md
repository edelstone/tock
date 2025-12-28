# Tock

<img src="Tock/AppIcon.png" alt="Tock app icon" width="128">

Super-minimal menubar timer with quick parsing, stopwatch mode, and configurable repeating tones.

## Features

- Menubar timer with countdown + stopwatch, plus quick natural-language input.
- Flexible notification settings with multiple tones, repeat, volume, and default unit when omitted.
- Context (right-click) menu with most app controls, plus popover UI.
- Customizable global keyboard shortcuts for common actions (Open, Clear).

## Installation

1. Download the latest macOS build:

   [![Download](https://img.shields.io/github/v/release/edelstone/tock?label=Download&logo=apple&style=for-the-badge&color=5865f2)](https://github.com/edelstone/tock/releases/latest/download/Tock.dmg)

2. Drag `Tock.app` to `/Applications`.
3. If macOS warns that the app is damaged or can’t be opened (Gatekeeper), this is usually due to the quarantine flag on apps downloaded outside the App Store. You can remove it for Tock only by running:

   ```bash
   xattr -dr com.apple.quarantine /Applications/Tock.app
   ```

4. Optional: add the app to your login items via **System Settings → General → Login Items**.

## Usage

- Enter a duration like `10`, `5m`, `1.5h`, `45 sec`, `17m 45s`, or `25:00`, then press Enter to start.
- Enter a time of day like `10pm`, `6:15a`, or `noon` to count down until the next occurrence.
- Click the play button to start a stopwatch with no countdown.
- Clear stops the timer and silences any active alarm.
- Most actions are also available via the menubar right-click menu.
- Settings allow customization of notifications and keyboard shortcuts.

## Default shortcuts

- Open popover: ⌃⌥⌘T
- Clear timer: ⌃⌥⌘X

## Releasing

See [docs/RELEASING.md](docs/RELEASING.md) for the full release and personal dev workflow.

## Credits

All sounds from [Notification Sounds](https://notificationsounds.com).

## License

MIT, use freely in commercial and personal projects.
