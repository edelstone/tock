import Foundation

enum TockSettingsKeys {
  static let tone = "notificationTone"
  static let repeatCount = "notificationRepeatCount"
  static let volume = "notificationVolume"
  static let defaultUnit = "defaultTimeUnit"
}

enum NotificationTone: String, CaseIterable, Identifiable {
  case gentleRoll = "gentle-roll"
  case correctAnswer = "correct-answer"
  case electroMarimba = "electro-marimba"
  case happyBells = "happy-bells"
  case shireFlute = "shire-flute"

  static let `default` = NotificationTone.gentleRoll

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .gentleRoll:
      return "Gentle Roll"
    case .correctAnswer:
      return "Correct Answer"
    case .electroMarimba:
      return "Electro Marimba"
    case .happyBells:
      return "Happy Bells"
    case .shireFlute:
      return "Shire Flute"
    }
  }
}

enum NotificationRepeatOption: Int, CaseIterable, Identifiable {
  case none = 0
  case five = 5
  case ten = 10
  case infinite = -1

  static let `default` = NotificationRepeatOption.ten

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
      return "Infinitely"
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
  case low
  case medium
  case high

  static let `default` = NotificationVolume.medium

  var id: String { rawValue }

  var displayName: String {
    switch self {
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
