import Foundation
import AppKit
import AVFoundation
import UserNotifications

final class TockModel: ObservableObject {
  enum TimerMode {
    case countdown
    case stopwatch
  }

  private enum NotificationContext {
    case duration(TimeInterval)
    case timeOfDay(String)
  }

  @Published var remaining: TimeInterval = 0
  @Published var elapsed: TimeInterval = 0
  @Published var mode: TimerMode = .countdown
  @Published var isRunning = false
  @Published var isPaused = false
  @Published var isFinished = false
  @Published var inputDuration = ""
  @Published private(set) var isTimeOfDayCountdown = false
  @Published private(set) var canRepeat = false

  private var timer: Timer?
  private var targetDate: Date?
  private var startDate: Date?
  private var alarmPlayer: AVAudioPlayer?
  private var alarmRepeatTimer: Timer?
  private var alarmRepeatCount = 0
  private var alarmRepeatLimit: Int?
  private let timerInterval: TimeInterval = 0.25
  private let timerTolerance: TimeInterval = 0.05
  private let alarmMinInterval: TimeInterval = 0.1
  private var lastDisplayedSecond: Int?
  private var notificationContext: NotificationContext?
  private var lastInput: String?

  var formattedRemaining: String {
    let total: Int
    switch mode {
    case .stopwatch:
      total = max(0, Int(elapsed.rounded()))
    case .countdown:
      total = max(0, Int(ceil(remaining)))
    }
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
      return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%02d:%02d", minutes, seconds)
  }

  var timeOfDayEndTooltip: String? {
    guard isRunning, mode == .countdown, isTimeOfDayCountdown, !isFinished else { return nil }
    guard let targetDate else { return nil }
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    let timeString = formatter.string(from: targetDate)
      .replacingOccurrences(of: "AM", with: "a.m.")
      .replacingOccurrences(of: "PM", with: "p.m.")
      .replacingOccurrences(of: "am", with: "a.m.")
      .replacingOccurrences(of: "pm", with: "p.m.")
    return "Ends at \(timeString)"
  }

  @discardableResult
  func startFromInputs() -> Bool {
    let rawInput = inputDuration.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmed = rawInput.lowercased()
    guard !trimmed.isEmpty else { return false }
    if trimmed == "sw" || trimmed == "stopwatch" {
      notificationContext = nil
      lastInput = nil
      startStopwatch()
      inputDuration = ""
      return true
    }
    if let interval = parsedTimeOfDayInterval(from: trimmed) {
      notificationContext = .timeOfDay(rawInput)
      start(duration: interval, isTimeOfDay: true)
      lastInput = rawInput
      inputDuration = ""
      updateRepeatAvailability()
      return true
    }
    let duration = parsedDuration(from: trimmed)
    guard duration > 0 else { return false }
    notificationContext = .duration(duration)
    start(duration: duration, isTimeOfDay: false)
    lastInput = rawInput
    inputDuration = ""
    updateRepeatAvailability()
    return true
  }

  func start(duration: TimeInterval, isTimeOfDay: Bool = false) {
    stop()
    mode = .countdown
    remaining = duration
    isRunning = true
    isPaused = false
    isFinished = false
    isTimeOfDayCountdown = isTimeOfDay
    targetDate = Date().addingTimeInterval(duration)
    if isTimeOfDay {
      if notificationContext == nil, let targetDate {
        notificationContext = .timeOfDay(formattedTimeString(for: targetDate))
      }
    } else {
      notificationContext = .duration(duration)
    }
    lastDisplayedSecond = nil
    scheduleTimer()
  }

  func startStopwatch() {
    stop()
    mode = .stopwatch
    elapsed = 0
    isRunning = true
    isPaused = false
    isFinished = false
    isTimeOfDayCountdown = false
    startDate = Date()
    lastDisplayedSecond = nil
    notificationContext = nil
    scheduleTimer()
  }

  func pause() {
    guard isRunning, !isPaused, !isTimeOfDayCountdown else { return }
    isPaused = true
    timer?.invalidate()
    timer = nil
  }

  func resume() {
    guard isRunning, isPaused else { return }
    stopAlarm()
    guard !isFinished else { return }
    switch mode {
    case .countdown:
      guard remaining > 0 else { return }
      isPaused = false
      targetDate = Date().addingTimeInterval(remaining)
      lastDisplayedSecond = nil
      scheduleTimer()
    case .stopwatch:
      isPaused = false
      startDate = Date().addingTimeInterval(-elapsed)
      lastDisplayedSecond = nil
      scheduleTimer()
    }
  }

  func stop() {
    timer?.invalidate()
    timer = nil
    targetDate = nil
    startDate = nil
    isRunning = false
    isPaused = false
    isTimeOfDayCountdown = false
    isFinished = false
    remaining = 0
    elapsed = 0
    inputDuration = ""
    lastInput = nil
    mode = .countdown
    lastDisplayedSecond = nil
    notificationContext = nil
    stopAlarm()
    updateRepeatAvailability()
  }

  private func parsedDuration(from input: String) -> TimeInterval {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !trimmed.isEmpty else { return 0 }

    if let interval = parsedColonDuration(from: trimmed) {
      return interval
    }

    if let composite = parsedCompositeDuration(from: trimmed) {
      return composite
    }

    let numberChars = "0123456789."
    let numberPart = trimmed.prefix { numberChars.contains($0) }
    let unitPart = trimmed.dropFirst(numberPart.count)
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let value = Double(numberPart) ?? 0
    guard value > 0 else { return 0 }

    let multiplier: Double
    if unitPart.isEmpty {
      multiplier = currentDefaultUnit().multiplier
    } else {
      guard let parsedUnit = unitForToken(unitPart) else { return 0 }
      multiplier = parsedUnit.multiplier
    }

    return max(0, value * multiplier)
  }

  private func parsedCompositeDuration(from input: String) -> TimeInterval? {
    let cleaned = input.replacingOccurrences(of: ",", with: "")
    let scanner = Scanner(string: cleaned)
    scanner.charactersToBeSkipped = .whitespacesAndNewlines

    var total: Double = 0
    var lastUnit: ParsedUnit?

    while !scanner.isAtEnd {
      guard let value = scanner.scanDouble(), value > 0 else { return nil }

      let unit = scanner.scanCharacters(from: .letters)?.lowercased()
      if let unit, !unit.isEmpty {
        guard let parsedUnit = unitForToken(unit) else { return nil }
        total += value * parsedUnit.multiplier
        lastUnit = parsedUnit
      } else {
        guard let currentUnit = lastUnit,
              let nextUnit = nextSmallerUnit(after: currentUnit) else {
          return nil
        }
        total += value * nextUnit.multiplier
        lastUnit = nextUnit
      }
    }

    return total > 0 ? total : nil
  }

  private func parsedColonDuration(from input: String) -> TimeInterval? {
    guard input.contains(":") else { return nil }
    let compact = input.replacingOccurrences(of: " ", with: "")
    guard !compact.contains("am"), !compact.contains("pm") else { return nil }

    let parts = compact.split(separator: ":", omittingEmptySubsequences: false)
    guard parts.count == 2 || parts.count == 3 else { return nil }
    let firstPart = String(parts[0])
    let secondPart = String(parts[1])
    let first: Int
    if firstPart.isEmpty, compact.hasPrefix(":") {
      first = 0
    } else if let parsed = Int(firstPart) {
      first = parsed
    } else {
      return nil
    }
    guard let second = Int(secondPart) else { return nil }
    guard first >= 0, second >= 0 else { return nil }

    if parts.count == 2 {
      guard second < 60 else { return nil }
      return Double(first * 60 + second)
    }

    guard let third = Int(parts[2]), third >= 0 else { return nil }
    guard second < 60, third < 60 else { return nil }
    return Double(first * 3600 + second * 60 + third)
  }

  private enum ParsedUnit {
    case hour
    case minute
    case second

    var multiplier: Double {
      switch self {
      case .hour:
        return 3600
      case .minute:
        return 60
      case .second:
        return 1
      }
    }
  }

  private func unitForToken(_ unit: String) -> ParsedUnit? {
    switch unit {
    case "m", "min", "mins", "minute", "minutes":
      return .minute
    case "s", "sec", "secs", "second", "seconds":
      return .second
    case "h", "hr", "hrs", "hour", "hours":
      return .hour
    default:
      return nil
    }
  }

  private func nextSmallerUnit(after unit: ParsedUnit) -> ParsedUnit? {
    switch unit {
    case .hour:
      return .minute
    case .minute:
      return .second
    case .second:
      return nil
    }
  }

  private func parsedTimeOfDayInterval(from input: String) -> TimeInterval? {
    var compact = input.replacingOccurrences(of: " ", with: "")
    compact = compact.replacingOccurrences(of: ".", with: "")
    if compact == "noon" {
      return intervalUntil(hour: 12, minute: 0)
    }
    if compact == "midnight" {
      return intervalUntil(hour: 0, minute: 0)
    }

    if compact.hasSuffix("a") {
      compact.removeLast()
      compact += "am"
    } else if compact.hasSuffix("p") {
      compact.removeLast()
      compact += "pm"
    }

    guard compact.contains("am") || compact.contains("pm") else {
      return nil
    }

    if !compact.contains(":") {
      let suffix = compact.suffix(2)
      let prefix = compact.dropLast(2)
      if (suffix == "am" || suffix == "pm"), prefix.count >= 3, prefix.allSatisfy({ $0.isNumber }) {
        let minutes = prefix.suffix(2)
        let hours = prefix.dropLast(2)
        compact = "\(hours):\(minutes)\(suffix)"
      }
    }

    let formats = ["h:mma", "ha", "H:mm", "HH:mm"]
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current

    for format in formats {
      formatter.dateFormat = format
      guard let parsed = formatter.date(from: compact) else { continue }
      let components = Calendar.current.dateComponents([.hour, .minute], from: parsed)
      guard let hour = components.hour, let minute = components.minute else { continue }
      if let interval = intervalUntil(hour: hour, minute: minute) {
        return interval
      }
    }

    return nil
  }

  private func intervalUntil(hour: Int, minute: Int) -> TimeInterval? {
    let calendar = Calendar.current
    let now = Date()
    guard var target = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) else {
      return nil
    }
    if target <= now {
      guard let next = calendar.date(byAdding: .day, value: 1, to: target) else { return nil }
      target = next
    }
    let interval = target.timeIntervalSince(now)
    return interval > 0 ? interval : nil
  }

  private func scheduleTimer() {
    timer?.invalidate()
    let newTimer = Timer(timeInterval: timerInterval, repeats: true) { [weak self] _ in
      self?.tick()
    }
    newTimer.tolerance = timerTolerance
    RunLoop.main.add(newTimer, forMode: .common)
    timer = newTimer
  }

  private func tick() {
    switch mode {
    case .countdown:
      guard let targetDate else { return }
      let newRemaining = targetDate.timeIntervalSinceNow
      if newRemaining <= 0 {
        finish()
      } else {
        let displaySeconds = max(0, Int(ceil(newRemaining)))
        if displaySeconds != lastDisplayedSecond {
          remaining = newRemaining
          lastDisplayedSecond = displaySeconds
        }
      }
    case .stopwatch:
      guard let startDate else { return }
      let newElapsed = Date().timeIntervalSince(startDate)
      let displaySeconds = max(0, Int(newElapsed.rounded()))
      if displaySeconds != lastDisplayedSecond {
        elapsed = newElapsed
        lastDisplayedSecond = displaySeconds
      }
    }
  }

  private func finish() {
    timer?.invalidate()
    timer = nil
    remaining = 0
    isRunning = true
    isPaused = true
    isTimeOfDayCountdown = false
    isFinished = true
    targetDate = nil
    mode = .countdown
    let context = notificationContext
    notificationContext = nil
    sendFinishedNotificationIfNeeded(context: context)
    startAlarm()
    updateRepeatAvailability()
  }

  private func sendFinishedNotificationIfNeeded(context: NotificationContext?) {
    guard UserDefaults.standard.bool(forKey: TockSettingsKeys.showNotifications) else { return }
    guard let context else { return }

    let body: String
    switch context {
    case .duration(let duration):
      body = formattedDurationDescription(duration)
    case .timeOfDay(let input):
      let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
      let timeString = trimmed.isEmpty ? formattedTimeString(for: Date()) : trimmed
      body = "Reached \(timeString)"
    }

    let content = UNMutableNotificationContent()
    content.title = "Timer Finished"
    content.body = body
    content.categoryIdentifier = NotificationIdentifiers.timerFinishedCategory

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )
    UNUserNotificationCenter.current().add(request)
  }

  private func formattedDurationDescription(_ duration: TimeInterval) -> String {
    let totalSeconds = max(1, Int(ceil(duration)))
    if totalSeconds < 60 {
      return "\(formattedUnit(totalSeconds, unit: "second")) timer"
    }

    let totalMinutes = Int(ceil(duration / 60.0))
    if totalMinutes < 60 {
      return "\(formattedUnit(totalMinutes, unit: "minute")) timer"
    }

    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    let hoursPart = formattedUnit(hours, unit: "hour")
    if minutes == 0 {
      return "\(hoursPart) timer"
    }
    let minutesPart = formattedUnit(minutes, unit: "minute")
    return "\(hoursPart) \(minutesPart) timer"
  }

  private func formattedUnit(_ value: Int, unit: String) -> String {
    let label = value == 1 ? unit : "\(unit)s"
    return "\(value)-\(label)"
  }

  private func formattedTimeString(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter.string(from: date)
      .replacingOccurrences(of: "AM", with: "a.m.")
      .replacingOccurrences(of: "PM", with: "p.m.")
      .replacingOccurrences(of: "am", with: "a.m.")
      .replacingOccurrences(of: "pm", with: "p.m.")
  }

  private func startAlarm() {
    stopAlarm()
    alarmRepeatCount = 0
    alarmRepeatLimit = currentRepeatLimit()

    let tone = currentTone()
    guard let url = Bundle.main.url(forResource: tone.rawValue, withExtension: "wav") else {
      NSSound(named: "Glass")?.play()
      return
    }

    do {
      let player = try AVAudioPlayer(contentsOf: url)
      let volume = currentVolume()
      player.volume = volume.level
      alarmPlayer = player
      player.play()
      alarmRepeatCount = 1

      guard alarmRepeatLimit != 1 else {
        return
      }

      let interval = max(alarmMinInterval, player.duration)
      let repeatTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
        guard let self else { return }
        if let alarmRepeatLimit = self.alarmRepeatLimit,
           self.alarmRepeatCount >= alarmRepeatLimit {
          self.stopAlarm()
          return
        }
        self.alarmPlayer?.currentTime = 0
        self.alarmPlayer?.play()
        self.alarmRepeatCount += 1
      }
      RunLoop.main.add(repeatTimer, forMode: .common)
      alarmRepeatTimer = repeatTimer
    } catch {
      alarmPlayer = nil
      NSSound(named: "Glass")?.play()
    }
  }

  private func stopAlarm() {
    alarmRepeatTimer?.invalidate()
    alarmRepeatTimer = nil
    alarmPlayer?.stop()
    alarmPlayer = nil
    alarmRepeatCount = 0
    alarmRepeatLimit = nil
  }

  @discardableResult
  func repeatLastInput() -> Bool {
    guard let lastInput else { return false }
    inputDuration = lastInput
    return startFromInputs()
  }

  private func updateRepeatAvailability() {
    canRepeat = isFinished && lastInput != nil
  }

  private func currentTone() -> NotificationTone {
    let raw = UserDefaults.standard.string(forKey: TockSettingsKeys.tone)
    return NotificationTone(rawValue: raw ?? "") ?? .default
  }

  private func currentRepeatLimit() -> Int? {
    let defaults = UserDefaults.standard
    let storedValue = defaults.object(forKey: TockSettingsKeys.repeatCount) as? Int
    let option = NotificationRepeatOption(rawValue: storedValue ?? NotificationRepeatOption.default.rawValue)
      ?? .default
    return option.repeatLimit
  }

  private func currentVolume() -> NotificationVolume {
    let raw = UserDefaults.standard.string(forKey: TockSettingsKeys.volume)
    return NotificationVolume(rawValue: raw ?? "") ?? .default
  }

  private func currentDefaultUnit() -> DefaultTimeUnit {
    let raw = UserDefaults.standard.string(forKey: TockSettingsKeys.defaultUnit)
    return DefaultTimeUnit(rawValue: raw ?? "") ?? .default
  }
}
