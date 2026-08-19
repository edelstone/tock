import Foundation

enum TockSettingsKeys {
  static let tone = "notificationTone"
  static let repeatCount = "notificationRepeatCount"
  static let repeatCountMigrationVersion = "notificationRepeatCountMigrationVersion"
  static let volume = "notificationVolume"
  static let defaultUnit = "defaultTimeUnit"
  static let openHotkey = "hotkeyOpen"
  static let pauseResumeHotkey = "hotkeyPauseResume"
  static let clearHotkey = "hotkeyClear"
  static let startPomodoroHotkey = "hotkeyStartPomodoro"
  static let didPromptLoginItem = "didPromptLoginItem"
  static let showNotifications = "showNotifications"
  static let menuBarIconSize = "menuBarIconSize"
  static let menuButtonSize = "menuButtonSize"
  static let menuButtonBrightness = "menuButtonBrightness"
  static let pomodoroWorkMinutes = "pomodoroWorkMinutes"
  static let pomodoroShortBreakMinutes = "pomodoroShortBreakMinutes"
  static let pomodoroLongBreakMinutes = "pomodoroLongBreakMinutes"
  static let pomodoroCyclesPerSet = "pomodoroCyclesPerSet"
  static let pomodoroShouldLoop = "pomodoroShouldLoop"
}

enum PomodoroDefaults {
  static let workMinutes = 25
  static let shortBreakMinutes = 5
  static let longBreakMinutes = 15
  static let cyclesPerSet = 4
  static let shouldLoop = false
  static let maximumDurationMinutes = 480
  static let maximumCyclesPerSet = 100
}

enum NotificationTone: String, CaseIterable, Identifiable {
  case alarmFrenzy = "alarm-frenzy"
  case discreet
  case fingerlicking
  case gladToKnow = "glad-to-know"
  case goodMorning = "good-morning"
  case joyousChime = "joyous-chime"
  case lightHearted = "light-hearted"
  case openYourEyes = "open-your-eyes"
  case rush
  case wailing
  case wakeUp = "wake-up"
  case whistling

  static let `default` = NotificationTone.wakeUp

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .alarmFrenzy:
      return "Alarm frenzy"
    case .discreet:
      return "Discreet"
    case .fingerlicking:
      return "Finger licking"
    case .gladToKnow:
      return "Glad to know"
    case .goodMorning:
      return "Good morning"
    case .joyousChime:
      return "Joyous chime"
    case .lightHearted:
      return "Light-hearted"
    case .openYourEyes:
      return "Open your eyes"
    case .rush:
      return "Rush"
    case .wailing:
      return "Wailing"
    case .wakeUp:
      return "Wake up"
    case .whistling:
      return "Whistling"
    }
  }
}

enum NotificationRepeatOption: Int, CaseIterable, Identifiable {
  case none = 0
  case five = 5
  case ten = 10
  case infinite = -1

  static let `default` = NotificationRepeatOption.none

  var id: Int { rawValue }

  var displayName: String {
    switch self {
    case .none:
      return "Once"
    case .five:
      return "5 times"
    case .ten:
      return "10 times"
    case .infinite:
      return "Until cleared"
    }
  }

  var repeatLimit: Int? {
    switch self {
    case .none:
      return 1
    case .five:
      return 5
    case .ten:
      return 10
    case .infinite:
      return nil
    }
  }
}

enum NotificationVolume: String, CaseIterable, Identifiable {
  case ultraLow = "ultra-low"
  case low
  case medium
  case high

  static let `default` = NotificationVolume.medium

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .ultraLow:
      return "Very low"
    case .low:
      return "Low"
    case .medium:
      return "Medium"
    case .high:
      return "High"
    }
  }

  var level: Float {
    switch self {
    case .ultraLow:
      return 0.2
    case .low:
      return 0.35
    case .medium:
      return 0.7
    case .high:
      return 1.0
    }
  }
}

enum DefaultTimeUnit: String, CaseIterable, Identifiable {
  case seconds
  case minutes
  case hours

  static let `default` = DefaultTimeUnit.minutes

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .seconds:
      return "Seconds"
    case .minutes:
      return "Minutes"
    case .hours:
      return "Hours"
    }
  }

  var multiplier: Double {
    switch self {
    case .seconds:
      return 1
    case .minutes:
      return 60
    case .hours:
      return 3600
    }
  }
}

enum MenuBarIconSize: String, CaseIterable, Identifiable {
  case small
  case medium
  case large

  static let `default` = MenuBarIconSize.medium

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .small:
      return "Small"
    case .medium:
      return "Medium"
    case .large:
      return "Large"
    }
  }
}

enum MenuButtonSize: String, CaseIterable, Identifiable {
  case small
  case medium
  case large

  static let `default` = MenuButtonSize.medium

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .small:
      return "Small"
    case .medium:
      return "Medium"
    case .large:
      return "Large"
    }
  }

  var iconPointSize: CGFloat {
    switch self {
    case .small:
      return 16
    case .medium:
      return 20
    case .large:
      return 24
    }
  }

  var buttonPointSize: CGFloat {
    switch self {
    case .small:
      return 24
    case .medium:
      return 28
    case .large:
      return 34
    }
  }
}

enum MenuButtonBrightness: String, CaseIterable, Identifiable {
  case dim
  case normal
  case bright

  static let `default` = MenuButtonBrightness.normal

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .dim:
      return "Dim"
    case .normal:
      return "Normal"
    case .bright:
      return "Bright"
    }
  }
}
