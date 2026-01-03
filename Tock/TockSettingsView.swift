import SwiftUI
import AVFoundation
import ServiceManagement
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
  @AppStorage(TockSettingsKeys.menuBarIconSize) private var menuBarIconSize = MenuBarIconSize.default.rawValue
  @AppStorage(TockSettingsKeys.menuButtonSize) private var menuButtonSize = MenuButtonSize.default.rawValue
  @AppStorage(TockSettingsKeys.menuButtonBrightness) private var menuButtonBrightness = MenuButtonBrightness.default.rawValue
  @State private var previewPlayer: AVAudioPlayer?
  @State private var previewPlayers: [String: AVAudioPlayer] = [:]
  @State private var skipTonePreview = false
  @State private var openHotkey: Hotkey?
  @State private var pauseResumeHotkey: Hotkey?
  @State private var clearHotkey: Hotkey?
  @State private var hasHotkeyConflict = false
  @State private var isUpdatingRecorder = false
  @State private var hotkeyErrorMessage: String?
  @State private var launchAtLogin = false
  @State private var isUpdatingLaunchAtLogin = false
  @State private var launchAtLoginError: String?

  private enum FocusField {
    case tone
    case repeatCount
    case volume
    case defaultUnit
    case iconSize
    case buttonSize
    case buttonBrightness
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

        VStack(spacing: 6) {
          Toggle("Launch Tock at Login", isOn: $launchAtLogin)
            .toggleStyle(.checkbox)
            .onChange(of: launchAtLogin) { _, newValue in
              guard !isUpdatingLaunchAtLogin else { return }
              setLaunchAtLogin(newValue)
            }
            .frame(maxWidth: .infinity, alignment: .center)

          if let launchAtLoginError {
            Text(launchAtLoginError)
              .foregroundStyle(.red)
              .frame(maxWidth: .infinity, alignment: .leading)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .padding(.bottom, 8)

        Form {
          Picker("Notification Tone", selection: $selectedTone) {
            ForEach(NotificationTone.allCases) { tone in
              Text(tone.displayName)
                .tag(tone.rawValue)
            }
          }
          .padding(.vertical, 2)
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

          Picker("Play Tone", selection: $repeatCount) {
            ForEach(NotificationRepeatOption.allCases) { option in
              Text(option.displayName)
                .tag(option.rawValue)
            }
          }
          .padding(.vertical, 2)
          .focused($focusedField, equals: .repeatCount)
          .focusEffectDisabled()
          .pickerStyle(.menu)

          Picker("Volume", selection: $selectedVolume) {
            ForEach(NotificationVolume.allCases) { volume in
              Text(volume.displayName)
                .tag(volume.rawValue)
            }
          }
          .padding(.vertical, 2)
          .focused($focusedField, equals: .volume)
          .focusEffectDisabled()
          .pickerStyle(.menu)
          .onChange(of: selectedVolume) { _, _ in
            playPreviewTone(named: selectedTone)
          }
          .padding(.bottom, 12)

          Picker("Default Unit", selection: $defaultUnit) {
            ForEach(DefaultTimeUnit.allCases) { unit in
              Text(unit.displayName)
                .tag(unit.rawValue)
            }
          }
          .padding(.vertical, 2)
          .focused($focusedField, equals: .defaultUnit)
          .focusEffectDisabled()
          .pickerStyle(.menu)

          Picker("Icon Size", selection: $menuBarIconSize) {
            ForEach(MenuBarIconSize.allCases) { size in
              Text(size.displayName)
                .tag(size.rawValue)
            }
          }
          .padding(.vertical, 2)
          .focused($focusedField, equals: .iconSize)
          .focusEffectDisabled()
          .pickerStyle(.menu)

          Picker("Button Size", selection: $menuButtonSize) {
            ForEach(MenuButtonSize.allCases) { size in
              Text(size.displayName)
                .tag(size.rawValue)
            }
          }
          .padding(.vertical, 2)
          .focused($focusedField, equals: .buttonSize)
          .focusEffectDisabled()
          .pickerStyle(.menu)

          Picker("Button Brightness", selection: $menuButtonBrightness) {
            ForEach(MenuButtonBrightness.allCases) { brightness in
              Text(brightness.displayName)
                .tag(brightness.rawValue)
            }
          }
          .padding(.vertical, 2)
          .focused($focusedField, equals: .buttonBrightness)
          .focusEffectDisabled()
          .pickerStyle(.menu)
          .padding(.bottom, 12)

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
          .padding(.vertical, 2)

          LabeledContent {
            #if canImport(KeyboardShortcuts)
            KeyboardShortcutsRecorderRepresentable(
              name: .pauseResumeRecorder,
              onChange: { shortcut in
                handleRecorderChange(action: .pauseResume, shortcut: shortcut)
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
            Text("Pause/Resume")
              .alignmentGuide(.firstTextBaseline) { dimensions in
                dimensions[VerticalAlignment.center]
              }
          }
          .padding(.vertical, 2)

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
            Text("Clear Timer")
              .alignmentGuide(.firstTextBaseline) { dimensions in
                dimensions[VerticalAlignment.center]
              }
          }
          .padding(.vertical, 2)

          if hasHotkeyConflict {
            Text("Open, Pause/Resume, and Clear shortcuts must be different.")
              .foregroundStyle(.red)
          }
          if let hotkeyErrorMessage {
            Text(hotkeyErrorMessage)
              .foregroundStyle(.red)
              .frame(maxWidth: .infinity, alignment: .leading)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        Text(Self.appVersionText)
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(.secondary)
          .padding(.top, 6)
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
          if MenuBarIconSize(rawValue: menuBarIconSize) == nil {
            menuBarIconSize = MenuBarIconSize.default.rawValue
          }
          if MenuButtonSize(rawValue: menuButtonSize) == nil {
            menuButtonSize = MenuButtonSize.default.rawValue
          }
          if MenuButtonBrightness(rawValue: menuButtonBrightness) == nil {
            menuButtonBrightness = MenuButtonBrightness.default.rawValue
          }
          refreshLaunchAtLoginState()
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

  private static var appVersionText: String {
    let info = Bundle.main.infoDictionary
    let version = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
    return "Version \(version)"
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
    pauseResumeHotkey = Hotkey.load(for: .pauseResume)
    clearHotkey = Hotkey.load(for: .clear)
    updateHotkeyConflict()
    syncRecorderFromDefaults()
  }

  private func updateHotkeyConflict() {
    hasHotkeyConflict = hotkeysHaveConflict([openHotkey, pauseResumeHotkey, clearHotkey])
    if hasHotkeyConflict {
      hotkeyErrorMessage = nil
    }
  }

  private func syncRecorderFromDefaults() {
    #if canImport(KeyboardShortcuts)
    isUpdatingRecorder = true
    Hotkey.updateRecorderUI(openHotkey, name: .openRecorder)
    Hotkey.updateRecorderUI(pauseResumeHotkey, name: .pauseResumeRecorder)
    Hotkey.updateRecorderUI(clearHotkey, name: .clearRecorder)
    isUpdatingRecorder = false
    #endif
  }

  #if canImport(KeyboardShortcuts)
  private func handleRecorderChange(action: HotkeyAction, shortcut: KeyboardShortcuts.Shortcut?) {
    guard !isUpdatingRecorder else { return }
    let proposed = Hotkey(keyboardShortcut: shortcut)
    let recorderName: KeyboardShortcuts.Name
    switch action {
    case .open:
      recorderName = .openRecorder
    case .pauseResume:
      recorderName = .pauseResumeRecorder
    case .clear:
      recorderName = .clearRecorder
    }
    Hotkey.updateRecorderUI(proposed, name: recorderName)
    if let proposed, !Hotkey.isValid(modifierFlags: proposed.modifierFlags) {
      syncRecorderFromDefaults()
      return
    }

    var nextOpen = openHotkey
    var nextPauseResume = pauseResumeHotkey
    var nextClear = clearHotkey
    switch action {
    case .open:
      nextOpen = proposed
    case .pauseResume:
      nextPauseResume = proposed
    case .clear:
      nextClear = proposed
    }

    hasHotkeyConflict = hotkeysHaveConflict([nextOpen, nextPauseResume, nextClear])
    guard !hasHotkeyConflict else { return }
    openHotkey = nextOpen
    pauseResumeHotkey = nextPauseResume
    clearHotkey = nextClear
    Hotkey.save(openHotkey, for: .open)
    Hotkey.save(pauseResumeHotkey, for: .pauseResume)
    Hotkey.save(clearHotkey, for: .clear)
    hotkeyErrorMessage = nil
  }
  #endif

  private func refreshLaunchAtLoginState() {
    guard #available(macOS 13.0, *) else { return }
    isUpdatingLaunchAtLogin = true
    launchAtLogin = SMAppService.mainApp.status == .enabled
    isUpdatingLaunchAtLogin = false
  }

  private func setLaunchAtLogin(_ enabled: Bool) {
    guard #available(macOS 13.0, *) else { return }
    do {
      if enabled {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
      launchAtLoginError = nil
    } catch {
      launchAtLoginError = "Could not update login item."
    }
    refreshLaunchAtLoginState()
  }

  private static func formatHotkeyError(_ notification: Notification) -> String {
    guard
      let userInfo = notification.userInfo,
      let action = userInfo[Hotkey.registrationFailedActionKey] as? HotkeyAction,
      let status = userInfo[Hotkey.registrationFailedStatusKey] as? Int
    else {
      return "Hotkey registration failed."
    }

    let actionName: String
    switch action {
    case .open:
      actionName = "Open Tock"
    case .pauseResume:
      actionName = "Pause/Resume"
    case .clear:
      actionName = "Clear Timer"
    }
    return "\(actionName) shortcut failed to register (status \(status))."
  }

}

private func hotkeysHaveConflict(_ hotkeys: [Hotkey?]) -> Bool {
  var seen: [Hotkey] = []
  for hotkey in hotkeys.compactMap({ $0 }) {
    if seen.contains(hotkey) {
      return true
    }
    seen.append(hotkey)
  }
  return false
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
