import SwiftUI

struct TockMenuView: View {
  @EnvironmentObject private var model: TockModel
  @Environment(\.menuDismiss) private var dismiss
  @State private var placeholder = Self.randomSuggestion()
  @FocusState private var isInputFocused: Bool

  private static let suggestions = [
    "10s", "30 sec", "45 secs",
    "1 min", "5 mins", "12 minutes",
    "20m", "25 min", "45 minutes",
    "1h", "1 hr", "1.5 hrs", "2 hours",
    "3h", "4 hours", "17m 45s", "1h 30m",
    "25:00", "10pm", "6:15a", "noon",
  ]

  private static func randomSuggestion() -> String {
    suggestions.randomElement() ?? "10s"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ZStack(alignment: .leading) {
        if model.inputDuration.isEmpty {
          Text(placeholder)
            .foregroundColor(.secondary.opacity(0.35))
        }
        TextField("", text: $model.inputDuration)
          .focused($isInputFocused)
          .textFieldStyle(.plain)
          .onSubmit {
            if model.startFromInputs() {
              dismiss()
            }
          }
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 8)
      .background(
        RoundedRectangle(cornerRadius: 6, style: .continuous)
          .fill(.regularMaterial)
      )

      .font(.system(size: 26, weight: .regular))
      .frame(maxWidth: .infinity, alignment: .leading)
      .onAppear {
        placeholder = Self.randomSuggestion()
        DispatchQueue.main.async {
          isInputFocused = true
        }
      }
      .onReceive(
        NotificationCenter.default.publisher(for: Notification.Name("TockPopoverWillShow"))
      ) { _ in
        placeholder = Self.randomSuggestion()
        DispatchQueue.main.async {
          isInputFocused = true
        }
      }

      let pauseDisabled = model.isRunning && !model.isPaused && model.isTimeOfDayCountdown

      HStack(spacing: 6) {
        Button {
          SettingsWindowController.shared.show()
          dismiss()
        } label: {
          Image("settings")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.borderless)

        Spacer()
        Button {
          if model.isRunning {
            if model.isPaused {
              if model.isCountdownFinished {
                model.startStopwatch()
              } else {
                model.resume()
              }
            } else {
              model.pause()
            }
          } else {
            model.startStopwatch()
          }
        } label: {
          Image((model.isRunning && !model.isPaused) ? "pause" : "play")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.borderless)
        .disabled(pauseDisabled)
        .opacity(pauseDisabled ? 0.5 : 1)

        Button {
          model.stop()
          dismiss()
        } label: {
          Image("close")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.borderless)
        .disabled(!model.isRunning)
        .opacity(model.isRunning ? 1 : 0.5)
      }
    }
    .padding(16)
    .frame(width: 210)
  }
}

#Preview {
  TockMenuView()
    .environmentObject(TockModel())
}
