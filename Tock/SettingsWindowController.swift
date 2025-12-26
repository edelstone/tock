import AppKit
import SwiftUI

final class SettingsWindowController {
  static let shared = SettingsWindowController()

  private var window: NSWindow?

  func show() {
    let window = ensureWindow()
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
  }

  private func ensureWindow() -> NSWindow {
    if let window {
      return window
    }

    let hostingController = NSHostingController(rootView: TockSettingsView())
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 360, height: 320),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = ""
    window.contentViewController = hostingController
    hostingController.view.layoutSubtreeIfNeeded()
    let fittingSize = hostingController.view.fittingSize
    let contentSize = NSSize(
      width: max(360, fittingSize.width),
      height: max(260, fittingSize.height)
    )
    window.setContentSize(contentSize)
    window.center()
    window.isReleasedWhenClosed = false
    self.window = window
    return window
  }
}
