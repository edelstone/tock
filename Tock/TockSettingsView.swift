import SwiftUI
import AVFoundation

struct TockSettingsView: View {
  @FocusState private var focusedField: FocusField?
  @AppStorage(TockSettingsKeys.tone) private var selectedTone = NotificationTone.default.rawValue
  @AppStorage(TockSettingsKeys.repeatCount) private var repeatCount = NotificationRepeatOption.default.rawValue
  @AppStorage(TockSettingsKeys.volume) private var selectedVolume = NotificationVolume.default.rawValue
  @AppStorage(TockSettingsKeys.defaultUnit) private var defaultUnit = DefaultTimeUnit.default.rawValue
  @State private var previewPlayer: AVAudioPlayer?
  @State private var previewPlayers: [String: AVAudioPlayer] = [:]
  @State private var skipTonePreview = false

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
        }
        .onAppear {
          DispatchQueue.main.async {
            focusedField = .tone
          }
          preloadPreviewTones()
          if NotificationTone(rawValue: selectedTone) == nil {
            skipTonePreview = true
            selectedTone = NotificationTone.default.rawValue
          }
        }
        .frame(maxWidth: 280)
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
