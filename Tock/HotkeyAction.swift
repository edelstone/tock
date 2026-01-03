import Carbon
import Foundation

enum HotkeyAction: CaseIterable {
  case open
  case pauseResume
  case clear

  var id: UInt32 {
    switch self {
    case .open:
      return 1
    case .pauseResume:
      return 2
    case .clear:
      return 3
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
    default:
      return nil
    }
  }
}
