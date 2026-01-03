import AppKit
import Carbon
import Foundation

#if canImport(KeyboardShortcuts)
import KeyboardShortcuts
#endif

struct Hotkey: Codable, Equatable {
  let keyCode: UInt16
  let modifiers: UInt32

  static let didChangeNotification = Notification.Name("TockHotkeyDidChange")
  static let registrationFailedNotification = Notification.Name("TockHotkeyRegistrationFailed")
  static let registrationFailedActionKey = "action"
  static let registrationFailedStatusKey = "status"

  init(keyCode: UInt16, modifiers: UInt32) {
    self.keyCode = keyCode
    self.modifiers = modifiers
  }

  var modifierFlags: NSEvent.ModifierFlags {
    Self.modifierFlags(fromCarbon: modifiers)
  }

  var displayString: String {
    let flags = modifierFlags
    var parts: [String] = []
    if flags.contains(.command) {
      parts.append("Cmd")
    }
    if flags.contains(.option) {
      parts.append("Option")
    }
    if flags.contains(.control) {
      parts.append("Control")
    }
    if flags.contains(.shift) {
      parts.append("Shift")
    }
    if flags.contains(.function) {
      parts.append("Fn")
    }
    parts.append(Self.displayName(for: keyCode))
    return parts.joined(separator: "+")
  }

  #if canImport(KeyboardShortcuts)
  init?(keyboardShortcut: KeyboardShortcuts.Shortcut?) {
    guard let keyboardShortcut else { return nil }
    keyCode = UInt16(keyboardShortcut.carbonKeyCode)
    modifiers = UInt32(keyboardShortcut.carbonModifiers)
  }

  var keyboardShortcut: KeyboardShortcuts.Shortcut? {
    KeyboardShortcuts.Shortcut(
      carbonKeyCode: Int(keyCode),
      carbonModifiers: Int(modifiers)
    )
  }
  #endif

  static func load(for action: HotkeyAction, defaults: UserDefaults = .standard) -> Hotkey? {
    guard let data = defaults.data(forKey: action.userDefaultsKey) else { return nil }
    return (try? JSONDecoder().decode(Hotkey?.self, from: data)) ?? nil
  }

  static func save(_ hotkey: Hotkey?, for action: HotkeyAction, defaults: UserDefaults = .standard) {
    guard let data = try? JSONEncoder().encode(hotkey) else {
      defaults.removeObject(forKey: action.userDefaultsKey)
      NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
      return
    }
    defaults.set(data, forKey: action.userDefaultsKey)
    NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
  }

  static func seedDefaultsIfNeeded(defaults: UserDefaults = .standard) {
    for action in HotkeyAction.allCases where defaults.object(forKey: action.userDefaultsKey) == nil {
      save(action.defaultHotkey, for: action, defaults: defaults)
    }
  }

  #if canImport(KeyboardShortcuts)
  static func updateRecorderUI(_ hotkey: Hotkey?, name: KeyboardShortcuts.Name) {
    KeyboardShortcuts.setShortcut(hotkey?.keyboardShortcut, for: name)
    // Recorder UI only; Carbon + Hotkey(UserDefaults) are authoritative.
    KeyboardShortcuts.disable(name)
  }

  static func migrateRecorderDefaultsIfNeeded(defaults: UserDefaults = .standard) {
    migrateRecorderShortcut(
      action: .open,
      legacyName: .legacyOpenRecorder,
      newName: .openRecorder,
      defaults: defaults
    )
    migrateRecorderShortcut(
      action: .clear,
      legacyName: .legacyClearRecorder,
      newName: .clearRecorder,
      defaults: defaults
    )
  }

  private static func migrateRecorderShortcut(
    action: HotkeyAction,
    legacyName: KeyboardShortcuts.Name,
    newName: KeyboardShortcuts.Name,
    defaults: UserDefaults
  ) {
    if load(for: action, defaults: defaults) == nil,
       let legacyShortcut = KeyboardShortcuts.getShortcut(for: legacyName),
       let hotkey = Hotkey(keyboardShortcut: legacyShortcut) {
      save(hotkey, for: action, defaults: defaults)
      updateRecorderUI(hotkey, name: newName)
    }

    if KeyboardShortcuts.getShortcut(for: legacyName) != nil {
      updateRecorderUI(nil, name: legacyName)
    }
  }
  #endif

  static func carbonFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var carbon: UInt32 = 0
    if flags.contains(.command) { carbon |= UInt32(cmdKey) }
    if flags.contains(.option) { carbon |= UInt32(optionKey) }
    if flags.contains(.control) { carbon |= UInt32(controlKey) }
    if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
    if flags.contains(.function) { carbon |= UInt32(NSEvent.ModifierFlags.function.rawValue) }
    return carbon
  }

  static func modifierFlags(fromCarbon carbon: UInt32) -> NSEvent.ModifierFlags {
    var flags: NSEvent.ModifierFlags = []
    if carbon & UInt32(cmdKey) != 0 { flags.insert(.command) }
    if carbon & UInt32(optionKey) != 0 { flags.insert(.option) }
    if carbon & UInt32(controlKey) != 0 { flags.insert(.control) }
    if carbon & UInt32(shiftKey) != 0 { flags.insert(.shift) }
    if carbon & UInt32(NSEvent.ModifierFlags.function.rawValue) != 0 { flags.insert(.function) }
    return flags
  }

  static func isValid(modifierFlags: NSEvent.ModifierFlags) -> Bool {
    if modifierFlags.isEmpty { return false }
    if modifierFlags == [.shift] { return false }
    if modifierFlags == [.function] { return false }
    return true
  }

  var menuKeyEquivalent: String? {
    let name = Self.displayName(for: keyCode)
    guard name.count == 1 else { return nil }
    return name.lowercased()
  }

  static func displayName(for keyCode: UInt16) -> String {
    switch keyCode {
    case UInt16(kVK_ANSI_A):
      return "A"
    case UInt16(kVK_ANSI_B):
      return "B"
    case UInt16(kVK_ANSI_C):
      return "C"
    case UInt16(kVK_ANSI_D):
      return "D"
    case UInt16(kVK_ANSI_E):
      return "E"
    case UInt16(kVK_ANSI_F):
      return "F"
    case UInt16(kVK_ANSI_G):
      return "G"
    case UInt16(kVK_ANSI_H):
      return "H"
    case UInt16(kVK_ANSI_I):
      return "I"
    case UInt16(kVK_ANSI_J):
      return "J"
    case UInt16(kVK_ANSI_K):
      return "K"
    case UInt16(kVK_ANSI_L):
      return "L"
    case UInt16(kVK_ANSI_M):
      return "M"
    case UInt16(kVK_ANSI_N):
      return "N"
    case UInt16(kVK_ANSI_O):
      return "O"
    case UInt16(kVK_ANSI_P):
      return "P"
    case UInt16(kVK_ANSI_Q):
      return "Q"
    case UInt16(kVK_ANSI_R):
      return "R"
    case UInt16(kVK_ANSI_S):
      return "S"
    case UInt16(kVK_ANSI_T):
      return "T"
    case UInt16(kVK_ANSI_U):
      return "U"
    case UInt16(kVK_ANSI_V):
      return "V"
    case UInt16(kVK_ANSI_W):
      return "W"
    case UInt16(kVK_ANSI_X):
      return "X"
    case UInt16(kVK_ANSI_Y):
      return "Y"
    case UInt16(kVK_ANSI_Z):
      return "Z"
    case UInt16(kVK_ANSI_0):
      return "0"
    case UInt16(kVK_ANSI_1):
      return "1"
    case UInt16(kVK_ANSI_2):
      return "2"
    case UInt16(kVK_ANSI_3):
      return "3"
    case UInt16(kVK_ANSI_4):
      return "4"
    case UInt16(kVK_ANSI_5):
      return "5"
    case UInt16(kVK_ANSI_6):
      return "6"
    case UInt16(kVK_ANSI_7):
      return "7"
    case UInt16(kVK_ANSI_8):
      return "8"
    case UInt16(kVK_ANSI_9):
      return "9"
    case UInt16(kVK_Space):
      return "Space"
    case UInt16(kVK_Return):
      return "Return"
    case UInt16(kVK_Tab):
      return "Tab"
    case UInt16(kVK_Delete):
      return "Delete"
    case UInt16(kVK_Escape):
      return "Escape"
    default:
      return "Key \(keyCode)"
    }
  }
}
