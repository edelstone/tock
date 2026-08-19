import Carbon
import Foundation

enum HotkeyAction: CaseIterable {
  case open
  case pauseResume
  case clear
  case startPomodoro

  var id: UInt32 {
    switch self {
    case .open:
      return 1
    case .pauseResume:
      return 2
    case .clear:
      return 3
    case .startPomodoro:
      return 4
    }
  }

  var userDefaultsKey: String {
    switch self {
    case .open:
      return TockSettingsKeys.openHotkey
    case .pauseResume:
      return TockSettingsKeys.pauseResumeHotkey
    case .clear:
      return TockSettingsKeys.clearHotkey
    case .startPomodoro:
      return TockSettingsKeys.startPomodoroHotkey
    }
  }

  var defaultHotkey: Hotkey {
    let modifiers = UInt32(controlKey | optionKey | cmdKey)
    switch self {
    case .open:
      return Hotkey(keyCode: UInt16(kVK_ANSI_T), modifiers: modifiers)
    case .pauseResume:
      return Hotkey(keyCode: UInt16(kVK_ANSI_P), modifiers: modifiers)
    case .clear:
      return Hotkey(keyCode: UInt16(kVK_ANSI_X), modifiers: modifiers)
    case .startPomodoro:
      return Hotkey(keyCode: UInt16(kVK_ANSI_M), modifiers: modifiers)
    }
  }

  init?(id: UInt32) {
    switch id {
    case HotkeyAction.open.id:
      self = .open
    case HotkeyAction.pauseResume.id:
      self = .pauseResume
    case HotkeyAction.clear.id:
      self = .clear
    case HotkeyAction.startPomodoro.id:
      self = .startPomodoro
    default:
      return nil
    }
  }
}
