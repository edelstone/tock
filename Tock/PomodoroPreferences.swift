import Foundation

struct PomodoroPreferences {
  let workMinutes: Int
  let shortBreakMinutes: Int
  let longBreakMinutes: Int
  let cyclesPerSet: Int
  let shouldLoop: Bool

  init() {
    let defaults = UserDefaults.standard
    self.workMinutes = min(
      PomodoroDefaults.maximumDurationMinutes,
      max(
        1,
      defaults.object(forKey: TockSettingsKeys.pomodoroWorkMinutes) == nil
        ? PomodoroDefaults.workMinutes
        : defaults.integer(forKey: TockSettingsKeys.pomodoroWorkMinutes)
      )
    )
    self.shortBreakMinutes = min(
      PomodoroDefaults.maximumDurationMinutes,
      max(
        1,
      defaults.object(forKey: TockSettingsKeys.pomodoroShortBreakMinutes) == nil
        ? PomodoroDefaults.shortBreakMinutes
        : defaults.integer(forKey: TockSettingsKeys.pomodoroShortBreakMinutes)
      )
    )
    self.longBreakMinutes = min(
      PomodoroDefaults.maximumDurationMinutes,
      max(
        1,
      defaults.object(forKey: TockSettingsKeys.pomodoroLongBreakMinutes) == nil
        ? PomodoroDefaults.longBreakMinutes
        : defaults.integer(forKey: TockSettingsKeys.pomodoroLongBreakMinutes)
      )
    )
    self.cyclesPerSet = min(
      PomodoroDefaults.maximumCyclesPerSet,
      max(
        1,
      defaults.object(forKey: TockSettingsKeys.pomodoroCyclesPerSet) == nil
        ? PomodoroDefaults.cyclesPerSet
        : defaults.integer(forKey: TockSettingsKeys.pomodoroCyclesPerSet)
      )
    )
    self.shouldLoop = defaults.bool(forKey: TockSettingsKeys.pomodoroShouldLoop)
  }
}
