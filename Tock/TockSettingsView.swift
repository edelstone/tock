import SwiftUI
import AVFoundation

struct TockSettingsView: View {
  @AppStorage(TockSettingsKeys.tone) private var selectedTone = NotificationTone.default.rawValue
  @AppStorage(TockSettingsKeys.repeatCount) private var repeatCount = NotificationRepeatOption.default.rawValue
  @AppStorage(TockSettingsKeys.volume) private var selectedVolume = NotificationVolume.default.rawValue
  @AppStorage(TockSettingsKeys.defaultUnit) private var defaultUnit = DefaultTimeUnit.default.rawValue
  @State private var previewPlayer: AVAudioPlayer?

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 12) {
        AppIconView()
          .frame(width: 48, height: 48)
        Text("Tock Settings")
          .font(.system(size: 22, weight: .semibold))
      }

      Form {
        Picker("Notification tone", selection: $selectedTone) {
          ForEach(NotificationTone.allCases) { tone in
            Text(tone.displayName)
              .tag(tone.rawValue)
          }
        }
        .pickerStyle(.menu)
        .onChange(of: selectedTone) { _, newValue in
          playPreviewTone(named: newValue)
        }

        Picker("Play tone", selection: $repeatCount) {
          ForEach(NotificationRepeatOption.allCases) { option in
            Text(option.displayName)
              .tag(option.rawValue)
          }
        }
        .pickerStyle(.menu)

      Picker("Volume", selection: $selectedVolume) {
        ForEach(NotificationVolume.allCases) { volume in
          Text(volume.displayName)
            .tag(volume.rawValue)
        }
      }
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
      .pickerStyle(.menu)
    }
    }
    .padding(20)
    .frame(width: 360)
  }

  private func playPreviewTone(named rawValue: String) {
    guard let url = Bundle.main.url(forResource: rawValue, withExtension: "wav") else { return }
    do {
      previewPlayer = try AVAudioPlayer(contentsOf: url)
      let volume = NotificationVolume(rawValue: selectedVolume) ?? .default
      previewPlayer?.volume = volume.level
      previewPlayer?.play()
    } catch {
      previewPlayer = nil
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
