import SwiftUI

struct TockMenuView: View {
  @EnvironmentObject private var model: TockModel
  @Environment(\.menuDismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme
  @AppStorage(TockSettingsKeys.menuButtonSize) private var menuButtonSize = MenuButtonSize.default.rawValue
  @AppStorage(TockSettingsKeys.menuButtonBrightness) private var menuButtonBrightness = MenuButtonBrightness.default.rawValue
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

  private struct IconStyle {
    let color: Color
    let opacity: Double
    let shadowColor: Color
    let shadowRadius: CGFloat
  }

  private func iconStyle(for brightness: MenuButtonBrightness, scheme: ColorScheme) -> IconStyle {
    switch brightness {
    case .dim:
      return IconStyle(
        color: .primary,
        opacity: 0.4,
        shadowColor: .clear,
        shadowRadius: 0
      )
    case .normal:
      return IconStyle(
        color: .primary,
        opacity: 0.65,
        shadowColor: .clear,
        shadowRadius: 0
      )
    case .bright:
      let color: Color = scheme == .light ? .black : .white
      let shadowColor: Color = scheme == .light ? .clear : .white.opacity(0.45)
      return IconStyle(
        color: color,
        opacity: 0.9,
        shadowColor: shadowColor,
        shadowRadius: scheme == .light ? 0 : 1.1
      )
    }
  }

  var body: some View {
    let buttonSize = MenuButtonSize(rawValue: menuButtonSize) ?? .default
    let brightnessSetting = MenuButtonBrightness(rawValue: menuButtonBrightness) ?? .default
    let style = iconStyle(for: brightnessSetting, scheme: colorScheme)
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
            .frame(width: buttonSize.iconPointSize, height: buttonSize.iconPointSize)
            .frame(width: buttonSize.buttonPointSize, height: buttonSize.buttonPointSize)
            .foregroundStyle(style.color)
            .opacity(style.opacity)
            .shadow(color: style.shadowColor, radius: style.shadowRadius)
        }
        .buttonStyle(.borderless)

        Spacer()
        Button {
          if model.isRunning {
            if model.isPaused {
              if model.isCountdownFinished {
                model.startStopwatch()
                dismiss()
              } else {
                model.resume()
              }
            } else {
              model.pause()
            }
          } else {
            model.startStopwatch()
            dismiss()
          }
        } label: {
          Image((model.isRunning && !model.isPaused) ? "pause" : "play")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: buttonSize.iconPointSize, height: buttonSize.iconPointSize)
            .frame(width: buttonSize.buttonPointSize, height: buttonSize.buttonPointSize)
            .foregroundStyle(style.color)
            .opacity(style.opacity)
            .shadow(color: style.shadowColor, radius: style.shadowRadius)
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
            .frame(width: buttonSize.iconPointSize, height: buttonSize.iconPointSize)
            .frame(width: buttonSize.buttonPointSize, height: buttonSize.buttonPointSize)
            .foregroundStyle(style.color)
            .opacity(style.opacity)
            .shadow(color: style.shadowColor, radius: style.shadowRadius)
        }
        .buttonStyle(.borderless)
        .disabled(!model.isRunning)
        .opacity(model.isRunning ? 1 : 0.5)
      }
    }
    .padding(16)
    .frame(width: 210)
    .background(
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture {
          isInputFocused = false
        }
    )
  }
}

#Preview {
  TockMenuView()
    .environmentObject(TockModel())
}
