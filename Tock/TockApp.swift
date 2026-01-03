import SwiftUI

@main
struct TockApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate: AppDelegate

  var body: some Scene {
    Settings {
      EmptyView()
    }
    .commands {
      CommandGroup(replacing: .appSettings) {
        Button("Settings…") {
          appDelegate.openSettingsFromCommand()
        }
        .keyboardShortcut(",", modifiers: .command)
      }
    }
  }
}
