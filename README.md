# Tock

<img src="Tock/AppIcon.png" alt="Tock app icon" width="128">

Super-minimal  menu bar timer with natural-language parsing, stopwatch mode, and configurable repeating tones.

## Features

- Menu bar countdown timer and stopwatch with natural-language input.
- Flexible notifications: multiple tones, repeat behavior, volume, and default units.
- Context (right-click) menu with most app controls, plus popover UI.
- Customizable global keyboard shortcuts for common actions.

## Installation

1. Download the latest macOS build:

   [![Download](https://img.shields.io/github/v/release/edelstone/tock?label=Download&logo=apple&style=for-the-badge&color=5865f2)](https://github.com/edelstone/tock/releases/latest/download/Tock.dmg)

2. Drag `Tock.app` to `/Applications`.
3. If macOS warns that the app is damaged or can’t be opened (Gatekeeper), this is usually due to the quarantine flag applied to apps downloaded outside the App Store. You can remove the flag for Tock only by running:

   ```bash
   xattr -dr com.apple.quarantine /Applications/Tock.app
   ```

4. On first launch you'll be prompted to add Tock to your login items. You can change this later in Tock settings or **System Settings → General → Login Items & Extensions**.

## Usage

- Enter a duration like `10`, `5m`, `1.5h`, `45 sec`, `17m 45s`, or `25:00`, then press Enter to start.
- Enter a time of day like `10pm`, `6:15a`, `330 p.m.`, or `noon` to count down until the next occurrence.
- Click the play button to start a stopwatch with no countdown.
- Clear stops the timer and silences any active alarm.
- Quit the app via context (right-click) menu or open the popover and type ⌘-Q.
- Configure notifications and keyboard shortcuts in Settings.

## Default shortcuts

- Open popover: ⌃⌥⌘T
- Clear timer: ⌃⌥⌘X

## Releasing

See [docs/RELEASING.md](docs/RELEASING.md) for the full release workflow.

## Credits

- Tones from [Notification Sounds](https://notificationsounds.com).
- Icons from [Tabler Icons](https://tabler.io/icons).

## License

MIT — free for commercial and personal use.
