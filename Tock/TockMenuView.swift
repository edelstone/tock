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

      HStack(spacing: 2) {
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
        .buttonStyle(HoverPillButtonStyle())

        Spacer()
        if model.canRepeat {
          Button {
            if model.repeatLastInput() {
              dismiss()
            }
          } label: {
            Image("repeat")
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(width: buttonSize.iconPointSize, height: buttonSize.iconPointSize)
              .frame(width: buttonSize.buttonPointSize, height: buttonSize.buttonPointSize)
              .foregroundStyle(style.color)
              .opacity(style.opacity)
              .shadow(color: style.shadowColor, radius: style.shadowRadius)
          }
          .buttonStyle(HoverPillButtonStyle())
        }
        Button {
          if model.isRunning {
            if model.isPaused {
              if model.isFinished {
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
        .buttonStyle(HoverPillButtonStyle())
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
        .buttonStyle(HoverPillButtonStyle())
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

private struct HoverPillButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    HoverPillButton(configuration: configuration)
  }

  private struct HoverPillButton: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    let configuration: ButtonStyle.Configuration
    @State private var isHovering = false

    var body: some View {
      configuration.label
        .padding(3)
        .background(
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(.regularMaterial)
            .opacity(backgroundOpacity)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.white.opacity(overlayOpacity))
        )
        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .scaleEffect(configuration.isPressed ? 0.965 : 1)
        .onHover { hovering in
          isHovering = hovering
        }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var backgroundOpacity: Double {
      guard isEnabled else { return 0 }
      let targetOpacity: Double = colorScheme == .dark ? 0.95 : 0.55
      return (isHovering || configuration.isPressed) ? targetOpacity : 0
    }

    private var overlayOpacity: Double {
      guard isEnabled, colorScheme == .dark, (isHovering || configuration.isPressed) else { return 0 }
      return 0.04
    }

  }
}

#Preview {
  TockMenuView()
    .environmentObject(TockModel())
}
