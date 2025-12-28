import Foundation

#if canImport(KeyboardShortcuts)
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
  static let openRecorder = Self("hotkeyOpenRecorder")
  static let clearRecorder = Self("hotkeyClearRecorder")
  static let legacyOpenRecorder = Self(TockSettingsKeys.openHotkey)
  static let legacyClearRecorder = Self(TockSettingsKeys.clearHotkey)
}
#endif
