import XCTest
@testable import Tock

final class PomodoroPreferencesTests: XCTestCase {
  override func tearDown() {
    let defaults = UserDefaults.standard
    [
      TockSettingsKeys.pomodoroWorkMinutes,
      TockSettingsKeys.pomodoroShortBreakMinutes,
      TockSettingsKeys.pomodoroLongBreakMinutes,
      TockSettingsKeys.pomodoroCyclesPerSet,
      TockSettingsKeys.pomodoroShouldLoop,
    ].forEach { defaults.removeObject(forKey: $0) }
    super.tearDown()
  }

  func testDefaults() {
    let preferences = PomodoroPreferences()

    XCTAssertEqual(preferences.workMinutes, PomodoroDefaults.workMinutes)
    XCTAssertEqual(preferences.shortBreakMinutes, PomodoroDefaults.shortBreakMinutes)
    XCTAssertEqual(preferences.longBreakMinutes, PomodoroDefaults.longBreakMinutes)
    XCTAssertEqual(preferences.cyclesPerSet, PomodoroDefaults.cyclesPerSet)
    XCTAssertFalse(preferences.shouldLoop)
  }

  func testDurationValuesClampToEightHours() {
    let defaults = UserDefaults.standard
    defaults.set(PomodoroDefaults.maximumDurationMinutes + 1, forKey: TockSettingsKeys.pomodoroWorkMinutes)
    defaults.set(PomodoroDefaults.maximumDurationMinutes + 1, forKey: TockSettingsKeys.pomodoroShortBreakMinutes)
    defaults.set(PomodoroDefaults.maximumDurationMinutes + 1, forKey: TockSettingsKeys.pomodoroLongBreakMinutes)

    let preferences = PomodoroPreferences()

    XCTAssertEqual(preferences.workMinutes, PomodoroDefaults.maximumDurationMinutes)
    XCTAssertEqual(preferences.shortBreakMinutes, PomodoroDefaults.maximumDurationMinutes)
    XCTAssertEqual(preferences.longBreakMinutes, PomodoroDefaults.maximumDurationMinutes)
  }

  func testCycleCountClampsToMaximum() {
    UserDefaults.standard.set(
      PomodoroDefaults.maximumCyclesPerSet + 1,
      forKey: TockSettingsKeys.pomodoroCyclesPerSet
    )

    XCTAssertEqual(PomodoroPreferences().cyclesPerSet, PomodoroDefaults.maximumCyclesPerSet)
  }

  func testValuesClampToMinimumOne() {
    let defaults = UserDefaults.standard
    defaults.set(0, forKey: TockSettingsKeys.pomodoroWorkMinutes)
    defaults.set(-1, forKey: TockSettingsKeys.pomodoroShortBreakMinutes)
    defaults.set(0, forKey: TockSettingsKeys.pomodoroLongBreakMinutes)
    defaults.set(0, forKey: TockSettingsKeys.pomodoroCyclesPerSet)

    let preferences = PomodoroPreferences()

    XCTAssertEqual(preferences.workMinutes, 1)
    XCTAssertEqual(preferences.shortBreakMinutes, 1)
    XCTAssertEqual(preferences.longBreakMinutes, 1)
    XCTAssertEqual(preferences.cyclesPerSet, 1)
  }
}
