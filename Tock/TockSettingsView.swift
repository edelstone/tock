import AVFoundation
import ServiceManagement
import SwiftUI
import UserNotifications

#if canImport(KeyboardShortcuts)
  import AppKit
  import KeyboardShortcuts
#endif

struct TockSettingsView: View {
  @FocusState private var focusedField: FocusField?
  @AppStorage(TockSettingsKeys.tone) private var selectedTone = NotificationTone.default.rawValue
  @AppStorage(TockSettingsKeys.repeatCount) private var repeatCount = NotificationRepeatOption
    .default.rawValue
  @AppStorage(TockSettingsKeys.volume) private var selectedVolume = NotificationVolume.default
    .rawValue
  @AppStorage(TockSettingsKeys.defaultUnit) private var defaultUnit = DefaultTimeUnit.default
    .rawValue
  @AppStorage(TockSettingsKeys.menuBarIconSize) private var menuBarIconSize = MenuBarIconSize
    .default.rawValue
  @AppStorage(TockSettingsKeys.menuButtonSize) private var menuButtonSize = MenuButtonSize.default
    .rawValue
  @AppStorage(TockSettingsKeys.menuButtonBrightness) private var menuButtonBrightness =
    MenuButtonBrightness.default.rawValue
  @AppStorage(TockSettingsKeys.showNotifications) private var showNotifications = false
  @AppStorage(TockSettingsKeys.pomodoroWorkMinutes) private var pomodoroWorkMinutes = PomodoroDefaults.workMinutes
  @AppStorage(TockSettingsKeys.pomodoroShortBreakMinutes) private var pomodoroShortBreakMinutes = PomodoroDefaults.shortBreakMinutes
  @AppStorage(TockSettingsKeys.pomodoroLongBreakMinutes) private var pomodoroLongBreakMinutes = PomodoroDefaults.longBreakMinutes
  @AppStorage(TockSettingsKeys.pomodoroCyclesPerSet) private var pomodoroCyclesPerSet = PomodoroDefaults.cyclesPerSet
  @AppStorage(TockSettingsKeys.pomodoroShouldLoop) private var pomodoroShouldLoop = PomodoroDefaults.shouldLoop
  @State private var previewPlayer: AVAudioPlayer?
  @State private var previewPlayers: [String: AVAudioPlayer] = [:]
  @State private var skipTonePreview = false
  @State private var openHotkey: Hotkey?
  @State private var pauseResumeHotkey: Hotkey?
  @State private var clearHotkey: Hotkey?
  @State private var startPomodoroHotkey: Hotkey?
  @State private var hasHotkeyConflict = false
  @State private var isUpdatingRecorder = false
  @State private var hotkeyErrorMessage: String?
  @State private var launchAtLogin = false
  @State private var isUpdatingLaunchAtLogin = false
  @State private var launchAtLoginError: String?
  @State private var showNotificationsError: String?

  private enum FocusField {
    case launchAtLogin
    case showNotifications
    case tone
    case repeatCount
    case volume
    case defaultUnit
    case iconSize
    case buttonSize
    case buttonBrightness
    case pomodoroWork
    case pomodoroShortBreak
    case pomodoroLongBreak
    case pomodoroCycles
  }

  var body: some View {
    ZStack {
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture {
          focusedField = nil
        }

      VStack(alignment: .leading, spacing: 24) {
        HStack(spacing: 16) {
          AppIconView()
            .frame(width: 48, height: 48)
          Text("Tock settings")
            .font(.system(size: 24, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        HStack(alignment: .top, spacing: 64) {
          VStack(alignment: .leading, spacing: 40) {
            VStack(alignment: .leading, spacing: 8) {
              settingsSectionHeading("Behavior")

              Toggle(isOn: $launchAtLogin) {
                Text("Launch Tock at login")
                  .padding(.leading, 4)
              }
              .toggleStyle(.checkbox)
              .focused($focusedField, equals: .launchAtLogin)
              .onChange(of: launchAtLogin) { _, newValue in
                guard !isUpdatingLaunchAtLogin else { return }
                setLaunchAtLogin(newValue)
              }

              Toggle(isOn: $showNotifications) {
                Text("Show notifications")
                  .padding(.leading, 4)
              }
              .toggleStyle(.checkbox)
              .focused($focusedField, equals: .showNotifications)
              .onChange(of: showNotifications) { _, newValue in
                handleShowNotificationsChange(newValue)
              }

              if let launchAtLoginError {
                settingsError(launchAtLoginError)
              }
              if let showNotificationsError {
                settingsError(showNotificationsError)
              }

              Picker(selection: $selectedTone) {
                ForEach(NotificationTone.allCases) { tone in
                  Text(tone.displayName)
                    .tag(tone.rawValue)
                }
              } label: {
                settingsLabel("Notification tone")
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

              Picker(selection: $repeatCount) {
                ForEach(NotificationRepeatOption.allCases) { option in
                  Text(option.displayName)
                    .tag(option.rawValue)
                }
              } label: {
                settingsLabel("Play tone")
              }
              .focused($focusedField, equals: .repeatCount)
              .focusEffectDisabled()
              .pickerStyle(.menu)

              Picker(selection: $selectedVolume) {
                ForEach(NotificationVolume.allCases) { volume in
                  Text(volume.displayName)
                    .tag(volume.rawValue)
                }
              } label: {
                settingsLabel("Tone volume")
              }
              .focused($focusedField, equals: .volume)
              .focusEffectDisabled()
              .pickerStyle(.menu)
              .onChange(of: selectedVolume) { _, _ in
                playPreviewTone(named: selectedTone)
              }

              Picker(selection: $defaultUnit) {
                ForEach(DefaultTimeUnit.allCases) { unit in
                  Text(unit.displayName)
                    .tag(unit.rawValue)
                }
              } label: {
                settingsLabel("Default unit")
              }
              .focused($focusedField, equals: .defaultUnit)
              .focusEffectDisabled()
              .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 8) {
              settingsSectionHeading("Appearance")
              Picker(selection: $menuBarIconSize) {
                ForEach(MenuBarIconSize.allCases) { size in
                  Text(size.displayName)
                    .tag(size.rawValue)
                }
              } label: {
                settingsLabel("Icon size")
              }
              .focused($focusedField, equals: .iconSize)
              .focusEffectDisabled()
              .pickerStyle(.menu)

              Picker(selection: $menuButtonSize) {
                ForEach(MenuButtonSize.allCases) { size in
                  Text(size.displayName)
                    .tag(size.rawValue)
                }
              } label: {
                settingsLabel("Button size")
              }
              .focused($focusedField, equals: .buttonSize)
              .focusEffectDisabled()
              .pickerStyle(.menu)

              Picker(selection: $menuButtonBrightness) {
                ForEach(MenuButtonBrightness.allCases) { brightness in
                  Text(brightness.displayName)
                    .tag(brightness.rawValue)
                }
              } label: {
                settingsLabel("Button brightness")
              }
              .focused($focusedField, equals: .buttonBrightness)
              .focusEffectDisabled()
              .pickerStyle(.menu)
            }
          }
          .focusSection()

          VStack(alignment: .leading, spacing: 40) {
            VStack(alignment: .leading, spacing: 8) {
              VStack(alignment: .leading, spacing: 0) {
                settingsSectionHeading("Pomodoro")
                Text("Durations in minutes")
                  .foregroundStyle(.secondary)
              }
              .padding(.bottom, 4)
              settingsNumberField(
                "Work interval", value: $pomodoroWorkMinutes, focus: .pomodoroWork,
                maximum: PomodoroDefaults.maximumDurationMinutes)
              settingsNumberField(
                "Short break", value: $pomodoroShortBreakMinutes, focus: .pomodoroShortBreak,
                maximum: PomodoroDefaults.maximumDurationMinutes)
              settingsNumberField(
                "Long break", value: $pomodoroLongBreakMinutes, focus: .pomodoroLongBreak,
                maximum: PomodoroDefaults.maximumDurationMinutes)
              settingsNumberField(
                "Cycles per set", value: $pomodoroCyclesPerSet, focus: .pomodoroCycles,
                maximum: PomodoroDefaults.maximumCyclesPerSet
              )
              Toggle(isOn: $pomodoroShouldLoop) {
                Text("Loop continuously")
                  .padding(.leading, 4)
              }
              .toggleStyle(.checkbox)

              Button("Restore defaults") {
                resetPomodoroSettings()
              }
              .buttonStyle(.link)
              .padding(.top, 4)
            }

            VStack(alignment: .leading, spacing: 8) {
              settingsSectionHeading("Keyboard shortcuts")
              hotkeyRow("Open Tock", name: .openRecorder, action: .open)
              hotkeyRow("Pause/resume", name: .pauseResumeRecorder, action: .pauseResume)
              hotkeyRow("Clear timer", name: .clearRecorder, action: .clear)
              hotkeyRow("Start Pomodoro", name: .startPomodoroRecorder, action: .startPomodoro)

              if hasHotkeyConflict {
                settingsError(
                  "Open, pause/resume, clear, and start Pomodoro shortcuts must be different.")
              }
              if let hotkeyErrorMessage {
                settingsError(hotkeyErrorMessage)
              }
            }
          }
          .focusSection()

        }
        .onAppear {
          DispatchQueue.main.async {
            focusedField = .launchAtLogin
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
          refreshNotificationAuthorization()
        }
        .onReceive(NotificationCenter.default.publisher(for: Hotkey.registrationFailedNotification))
        { notification in
          hotkeyErrorMessage = Self.formatHotkeyError(notification)
        }
      }
    }
    .padding(24)
    .frame(width: 680)
    .onDisappear {
      stopPreviewTone()
    }
    .onReceive(
      NotificationCenter.default.publisher(
        for: SettingsWindowController.settingsWillCloseNotification)
    ) { _ in
      stopPreviewTone()
    }
    .onReceive(
      NotificationCenter.default.publisher(
        for: SettingsWindowController.settingsDidResignKeyNotification)
    ) { _ in
      stopPreviewTone()
    }
  }

  private func settingsSectionHeading(_ title: String) -> some View {
    Text(title)
      .font(.system(size: 18, weight: .semibold))
      .padding(.bottom, 5)
  }

  private func settingsError(_ message: String) -> some View {
    Text(message)
      .foregroundStyle(.red)
      .fixedSize(horizontal: false, vertical: true)
  }

  private func settingsLabel(_ title: String) -> some View {
    Text(title)
      .frame(width: 112, alignment: .leading)
  }

  private func resetPomodoroSettings() {
    pomodoroWorkMinutes = PomodoroDefaults.workMinutes
    pomodoroShortBreakMinutes = PomodoroDefaults.shortBreakMinutes
    pomodoroLongBreakMinutes = PomodoroDefaults.longBreakMinutes
    pomodoroCyclesPerSet = PomodoroDefaults.cyclesPerSet
    pomodoroShouldLoop = PomodoroDefaults.shouldLoop
  }

  private func settingsNumberField(
    _ title: String,
    value: Binding<Int>,
    focus: FocusField,
    maximum: Int
  ) -> some View {
    LabeledContent {
      HStack(spacing: 4) {
        TextField("", value: value, format: .number)
          .textFieldStyle(.roundedBorder)
          .frame(width: 60)
          .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
              .stroke(settingsControlBorderColor, lineWidth: 1)
          )
          .focused($focusedField, equals: focus)
          .onChange(of: value.wrappedValue) { _, newValue in
            if newValue < 1 {
              value.wrappedValue = 1
            } else if newValue > maximum {
              value.wrappedValue = maximum
            }
          }
          .onKeyPress(.upArrow) {
            value.wrappedValue = min(maximum, value.wrappedValue + 1)
            return .handled
          }
          .onKeyPress(.downArrow) {
            value.wrappedValue = max(1, value.wrappedValue - 1)
            return .handled
          }

        Stepper("", value: value, in: 1...maximum)
          .labelsHidden()
          .controlSize(.small)
          .focusable(false)
      }
    } label: {
      settingsLabel(title)
    }
  }

  private var settingsControlBorderColor: Color {
    #if canImport(AppKit)
      let appearance = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
      return Color(nsColor: appearance == .darkAqua ? .tertiaryLabelColor : .separatorColor)
    #else
      return .secondary
    #endif
  }

  @ViewBuilder
  private func hotkeyRow(
    _ title: String,
    name: KeyboardShortcuts.Name,
    action: HotkeyAction
  ) -> some View {
    LabeledContent {
      #if canImport(KeyboardShortcuts)
        KeyboardShortcutsRecorderRepresentable(
          name: name,
          onChange: { shortcut in
            handleRecorderChange(action: action, shortcut: shortcut)
          }
        )
        .frame(width: 110)
        .padding(.leading, 12)
      #else
        Text("Add KeyboardShortcuts")
          .foregroundStyle(.secondary)
      #endif
    } label: {
      settingsLabel(title)
    }
    .padding(.vertical, 0)
  }

  private func playPreviewTone(named rawValue: String) {
    stopPreviewTone()
    if let cached = previewPlayers[rawValue] {
      previewPlayer = cached
    } else if let url = Bundle.main.url(forResource: rawValue, withExtension: "wav"),
      let player = try? AVAudioPlayer(contentsOf: url)
    {
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
    startPomodoroHotkey = Hotkey.load(for: .startPomodoro)
    updateHotkeyConflict()
    syncRecorderFromDefaults()
  }

  private func updateHotkeyConflict() {
    hasHotkeyConflict = hotkeysHaveConflict([
      openHotkey, pauseResumeHotkey, clearHotkey, startPomodoroHotkey,
    ])
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
      Hotkey.updateRecorderUI(startPomodoroHotkey, name: .startPomodoroRecorder)
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
      case .startPomodoro:
        recorderName = .startPomodoroRecorder
      }
      Hotkey.updateRecorderUI(proposed, name: recorderName)
      if let proposed, !Hotkey.isValid(modifierFlags: proposed.modifierFlags) {
        syncRecorderFromDefaults()
        return
      }

      var nextOpen = openHotkey
      var nextPauseResume = pauseResumeHotkey
      var nextClear = clearHotkey
      var nextStartPomodoro = startPomodoroHotkey
      switch action {
      case .open:
        nextOpen = proposed
      case .pauseResume:
        nextPauseResume = proposed
      case .clear:
        nextClear = proposed
      case .startPomodoro:
        nextStartPomodoro = proposed
      }

      hasHotkeyConflict = hotkeysHaveConflict([
        nextOpen, nextPauseResume, nextClear, nextStartPomodoro,
      ])
      guard !hasHotkeyConflict else { return }
      openHotkey = nextOpen
      pauseResumeHotkey = nextPauseResume
      clearHotkey = nextClear
      startPomodoroHotkey = nextStartPomodoro
      Hotkey.save(openHotkey, for: .open)
      Hotkey.save(pauseResumeHotkey, for: .pauseResume)
      Hotkey.save(clearHotkey, for: .clear)
      Hotkey.save(startPomodoroHotkey, for: .startPomodoro)
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

  private func refreshNotificationAuthorization() {
    guard showNotifications else { return }
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      DispatchQueue.main.async {
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
          showNotificationsError = nil
        case .notDetermined:
          break
        case .denied:
          showNotifications = false
          showNotificationsError = "Notifications are disabled in System Settings."
        @unknown default:
          showNotifications = false
          showNotificationsError = "Notifications are unavailable."
        }
      }
    }
  }

  private func handleShowNotificationsChange(_ enabled: Bool) {
    guard enabled else {
      showNotificationsError = nil
      return
    }

    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      DispatchQueue.main.async {
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
          showNotificationsError = nil
        case .notDetermined:
          center.requestAuthorization(options: [.alert]) { granted, _ in
            DispatchQueue.main.async {
              if granted {
                showNotificationsError = nil
              } else {
                showNotifications = false
                showNotificationsError = "Notifications are disabled in System Settings."
              }
            }
          }
        case .denied:
          showNotifications = false
          showNotificationsError = "Notifications are disabled in System Settings."
        @unknown default:
          showNotifications = false
          showNotificationsError = "Notifications are unavailable."
        }
      }
    }
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
      actionName = "Pause/resume"
    case .clear:
      actionName = "Clear timer"
    case .startPomodoro:
      actionName = "Start Pomodoro"
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
