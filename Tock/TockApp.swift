import SwiftUI

@main
struct TockApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup {
      EmptyView()
    }
    .handlesExternalEvents(matching: [])
  }
}
