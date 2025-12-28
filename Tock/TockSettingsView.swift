import SwiftUI
import AVFoundation
#if canImport(KeyboardShortcuts)
import AppKit
import KeyboardShortcuts
#endif

struct TockSettingsView: View {
  @FocusState private var focusedField: FocusField?
  @AppStorage(TockSettingsKeys.tone) private var selectedTone = NotificationTone.default.rawValue
  @AppStorage(TockSettingsKeys.repeatCount) private var repeatCount = NotificationRepeatOption.default.rawValue
  @AppStorage(TockSettingsKeys.volume) private var selectedVolume = NotificationVolume.default.rawValue
  @AppStorage(TockSettingsKeys.defaultUnit) private var defaultUnit = DefaultTimeUnit.default.rawValue
  @State private var previewPlayer: AVAudioPlayer?
  @State private var previewPlayers: [String: AVAudioPlayer] = [:]
  @State private var skipTonePreview = false
  @State private var openHotkey: Hotkey?
  @State private var clearHotkey: Hotkey?
  @State private var hasHotkeyConflict = false
  @State private var isUpdatingRecorder = false
  @State private var hotkeyErrorMessage: String?

  private enum FocusField {
    case tone
    case repeatCount
    case volume
    case defaultUnit
  }

  var body: some View {
    ZStack {
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture {
          focusedField = nil
        }

      VStack(alignment: .center, spacing: 16) {
        HStack(spacing: 12) {
          AppIconView()
            .frame(width: 48, height: 48)
          Text("Tock Settings")
            .font(.system(size: 22, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .center)

        Form {
          Picker("Notification tone", selection: $selectedTone) {
            ForEach(NotificationTone.allCases) { tone in
              Text(tone.displayName)
                .tag(tone.rawValue)
            }
          }
          .focused($focusedField, equals: .tone)
          .focusEffectDisabled()
          .pickerStyle(.menu)
          .onChange(of: selectedTone) { _, newValue in
            if skipTonePreview {
              skipTonePreview = false
              return
            }
            playPreviewTone(named: newValue)
          }

          Picker("Play tone", selection: $repeatCount) {
            ForEach(NotificationRepeatOption.allCases) { option in
              Text(option.displayName)
                .tag(option.rawValue)
            }
          }
          .focused($focusedField, equals: .repeatCount)
          .focusEffectDisabled()
          .pickerStyle(.menu)

          Picker("Volume", selection: $selectedVolume) {
            ForEach(NotificationVolume.allCases) { volume in
              Text(volume.displayName)
                .tag(volume.rawValue)
            }
          }
          .focused($focusedField, equals: .volume)
          .focusEffectDisabled()
          .pickerStyle(.menu)
          .onChange(of: selectedVolume) { _, _ in
            playPreviewTone(named: selectedTone)
          }

          Picker("Default unit", selection: $defaultUnit) {
            ForEach(DefaultTimeUnit.allCases) { unit in
              Text(unit.displayName)
                .tag(unit.rawValue)
            }
          }
          .focused($focusedField, equals: .defaultUnit)
          .focusEffectDisabled()
          .pickerStyle(.menu)

          LabeledContent {
            #if canImport(KeyboardShortcuts)
            KeyboardShortcutsRecorderRepresentable(
              name: .openRecorder,
              onChange: { shortcut in
                handleRecorderChange(action: .open, shortcut: shortcut)
              }
            )
            .frame(width: 110)
            .padding(.leading, 12)
            .alignmentGuide(.firstTextBaseline) { dimensions in
              dimensions[VerticalAlignment.center]
            }
            #else
            Text("Add KeyboardShortcuts")
              .foregroundStyle(.secondary)
            #endif
          } label: {
            Text("Open Tock")
              .alignmentGuide(.firstTextBaseline) { dimensions in
                dimensions[VerticalAlignment.center]
              }
          }

          LabeledContent {
            #if canImport(KeyboardShortcuts)
            KeyboardShortcutsRecorderRepresentable(
              name: .clearRecorder,
              onChange: { shortcut in
                handleRecorderChange(action: .clear, shortcut: shortcut)
              }
            )
            .frame(width: 110)
            .padding(.leading, 12)
            .alignmentGuide(.firstTextBaseline) { dimensions in
              dimensions[VerticalAlignment.center]
            }
            #else
            Text("Add KeyboardShortcuts")
              .foregroundStyle(.secondary)
            #endif
          } label: {
            Text("Clear timer")
              .alignmentGuide(.firstTextBaseline) { dimensions in
                dimensions[VerticalAlignment.center]
              }
          }

          if hasHotkeyConflict {
            Text("Open and Clear shortcuts must be different.")
              .foregroundStyle(.red)
          }
          if let hotkeyErrorMessage {
            Text(hotkeyErrorMessage)
              .foregroundStyle(.red)
              .frame(maxWidth: .infinity, alignment: .leading)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .onAppear {
          DispatchQueue.main.async {
            focusedField = .tone
          }
          #if canImport(KeyboardShortcuts)
          Hotkey.migrateRecorderDefaultsIfNeeded()
          #endif
          Hotkey.seedDefaultsIfNeeded()
          loadHotkeysFromDefaults()
          preloadPreviewTones()
          if NotificationTone(rawValue: selectedTone) == nil {
            skipTonePreview = true
            selectedTone = NotificationTone.default.rawValue
          }
        }
        .onReceive(NotificationCenter.default.publisher(for: Hotkey.registrationFailedNotification)) { notification in
          hotkeyErrorMessage = Self.formatHotkeyError(notification)
        }
        .frame(width: 300)
      }
    }
    .padding(20)
    .frame(width: 360)
    .onDisappear {
      stopPreviewTone()
    }
    .onReceive(NotificationCenter.default.publisher(for: SettingsWindowController.settingsWillCloseNotification)) { _ in
      stopPreviewTone()
    }
    .onReceive(NotificationCenter.default.publisher(for: SettingsWindowController.settingsDidResignKeyNotification)) { _ in
      stopPreviewTone()
    }
  }

  private func playPreviewTone(named rawValue: String) {
    stopPreviewTone()
    if let cached = previewPlayers[rawValue] {
      previewPlayer = cached
    } else if let url = Bundle.main.url(forResource: rawValue, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) {
      previewPlayers[rawValue] = player
      previewPlayer = player
    }

    let volume = NotificationVolume(rawValue: selectedVolume) ?? .default
    previewPlayer?.volume = volume.level
    previewPlayer?.currentTime = 0
    previewPlayer?.play()
  }

  private func stopPreviewTone() {
    previewPlayer?.stop()
    previewPlayer?.currentTime = 0
    previewPlayer = nil
  }

  private func preloadPreviewTones() {
    guard previewPlayers.isEmpty else { return }
    let tones = NotificationTone.allCases.map { $0.rawValue }
    DispatchQueue.global(qos: .userInitiated).async {
      var players: [String: AVAudioPlayer] = [:]
      for tone in tones {
        guard let url = Bundle.main.url(forResource: tone, withExtension: "wav") else { continue }
        if let player = try? AVAudioPlayer(contentsOf: url) {
          player.prepareToPlay()
          players[tone] = player
        }
      }
      DispatchQueue.main.async {
        if self.previewPlayers.isEmpty {
          self.previewPlayers = players
        } else {
          self.previewPlayers.merge(players) { existing, _ in existing }
        }
      }
    }
  }

  private func loadHotkeysFromDefaults() {
    openHotkey = Hotkey.load(for: .open)
    clearHotkey = Hotkey.load(for: .clear)
    updateHotkeyConflict()
    syncRecorderFromDefaults()
  }

  private func updateHotkeyConflict() {
    hasHotkeyConflict = openHotkey != nil && openHotkey == clearHotkey
    if hasHotkeyConflict {
      hotkeyErrorMessage = nil
    }
  }

  private func syncRecorderFromDefaults() {
    #if canImport(KeyboardShortcuts)
    isUpdatingRecorder = true
    Hotkey.updateRecorderUI(openHotkey, name: .openRecorder)
    Hotkey.updateRecorderUI(clearHotkey, name: .clearRecorder)
    isUpdatingRecorder = false
    #endif
  }

  #if canImport(KeyboardShortcuts)
  private func handleRecorderChange(action: HotkeyAction, shortcut: KeyboardShortcuts.Shortcut?) {
    guard !isUpdatingRecorder else { return }
    let proposed = Hotkey(keyboardShortcut: shortcut)
    let recorderName: KeyboardShortcuts.Name = action == .open ? .openRecorder : .clearRecorder
    Hotkey.updateRecorderUI(proposed, name: recorderName)
    if let proposed, !Hotkey.isValid(modifierFlags: proposed.modifierFlags) {
      syncRecorderFromDefaults()
      return
    }

    var nextOpen = openHotkey
    var nextClear = clearHotkey
    switch action {
    case .open:
      nextOpen = proposed
    case .clear:
      nextClear = proposed
    }

    hasHotkeyConflict = nextOpen != nil && nextOpen == nextClear
    guard !hasHotkeyConflict else { return }
    openHotkey = nextOpen
    clearHotkey = nextClear
    Hotkey.save(openHotkey, for: .open)
    Hotkey.save(clearHotkey, for: .clear)
    hotkeyErrorMessage = nil
  }
  #endif

  private static func formatHotkeyError(_ notification: Notification) -> String {
    guard
      let userInfo = notification.userInfo,
      let action = userInfo[Hotkey.registrationFailedActionKey] as? HotkeyAction,
      let status = userInfo[Hotkey.registrationFailedStatusKey] as? Int
    else {
      return "Hotkey registration failed."
    }

    let actionName = action == .open ? "Open Tock" : "Clear timer"
    return "\(actionName) shortcut failed to register (status \(status))."
  }

}

private struct AppIconView: View {
  var body: some View {
    Image(nsImage: NSApp.applicationIconImage)
      .resizable()
      .scaledToFit()
  }
}

#Preview {
  TockSettingsView()
}
