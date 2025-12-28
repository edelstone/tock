import AppKit
import SwiftUI

final class SettingsWindowController: NSObject, NSWindowDelegate {
  static let shared = SettingsWindowController()
  static let settingsWillCloseNotification = Notification.Name("TockSettingsWillClose")
  static let settingsDidResignKeyNotification = Notification.Name("TockSettingsDidResignKey")

  private var window: NSWindow?

  func show() {
    let window = ensureWindow()
    centerWindow(window)
    if window.isMiniaturized {
      window.deminiaturize(nil)
    }
    NSApp.unhide(nil)
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
    window.orderFrontRegardless()
    DispatchQueue.main.async {
      window.makeFirstResponder(nil)
    }
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
    centerWindow(window)
    window.isReleasedWhenClosed = false
    window.initialFirstResponder = nil
    window.delegate = self
    self.window = window
    return window
  }

  private func centerWindow(_ window: NSWindow) {
    let screenFrame = NSScreen.main?.visibleFrame ?? window.screen?.visibleFrame
    guard let screenFrame else { return }
    let size = window.frame.size
    let origin = NSPoint(
      x: screenFrame.midX - (size.width / 2),
      y: screenFrame.midY - (size.height / 2)
    )
    window.setFrameOrigin(origin)
  }

  func windowWillClose(_ notification: Notification) {
    NotificationCenter.default.post(name: Self.settingsWillCloseNotification, object: nil)
  }

  func windowDidResignKey(_ notification: Notification) {
    NotificationCenter.default.post(name: Self.settingsDidResignKeyNotification, object: nil)
  }

}
