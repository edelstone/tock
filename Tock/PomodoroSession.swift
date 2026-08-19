import Foundation

struct PomodoroSession {
  // Configuration (read once at start from preferences)
  let workDuration: TimeInterval
  let shortBreakDuration: TimeInterval
  let longBreakDuration: TimeInterval
  let cyclesPerSet: Int
  let shouldLoop: Bool

  // State
  var currentCycle: Int = 1
  var currentPhase: Phase = .work
  var isActive: Bool = false

  enum Phase: Equatable {
    case work
    case shortBreak
    case longBreak
  }

  // MARK: - Initialization
  init(from preferences: PomodoroPreferences) {
    self.workDuration = TimeInterval(preferences.workMinutes * 60)
    self.shortBreakDuration = TimeInterval(preferences.shortBreakMinutes * 60)
    self.longBreakDuration = TimeInterval(preferences.longBreakMinutes * 60)
    self.cyclesPerSet = preferences.cyclesPerSet
    self.shouldLoop = preferences.shouldLoop
    self.isActive = true
  }

  // MARK: - Phase Progression
  /// Called when current timer expires. Returns the next phase duration and updates state.
  mutating func advanceToNextPhase() -> TimeInterval {
    switch currentPhase {
    case .work:
      // Work phase ended. Determine if next is short or long break.
      if currentCycle == cyclesPerSet {
        currentPhase = .longBreak
        return longBreakDuration
      } else {
        currentPhase = .shortBreak
        return shortBreakDuration
      }

    case .shortBreak:
      // Short break ended. Next is always work.
      currentPhase = .work
      currentCycle += 1
      return workDuration

    case .longBreak:
      // Long break ended. Check if we should loop.
      if shouldLoop {
        currentCycle = 1
        currentPhase = .work
        return workDuration
      } else {
        isActive = false
        return 0
      }
    }
  }

  // MARK: - Display
  func displayLabel() -> String {
    let phasePrefix: String
    switch currentPhase {
    case .work:
      phasePrefix = "W"
    case .shortBreak:
      phasePrefix = "B"
    case .longBreak:
      phasePrefix = "B"
    }
    return "\(phasePrefix) \(currentCycle)/\(cyclesPerSet)"
  }

  func phaseDescription(includeCycle: Bool = true) -> String {
    let cycleDescription = includeCycle ? " \(currentCycle)/\(cyclesPerSet)" : ""
    switch currentPhase {
    case .work:
      return "Work cycle\(cycleDescription)"
    case .shortBreak:
      return "Short break\(cycleDescription)"
    case .longBreak:
      return "Long break\(cycleDescription)"
    }
  }

}
