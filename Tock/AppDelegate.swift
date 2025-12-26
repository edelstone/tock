import AppKit
import SwiftUI
import Combine
import Carbon

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private var panel: RoundedPanel?
  private var globalEventMonitor: Any?
  private var localEventMonitor: Any?
  private let model = TockModel()
  private var cancellables = Set<AnyCancellable>()
  private var hotKeyRef: EventHotKeyRef?
  private var trashHotKeyRef: EventHotKeyRef?
  private var hotKeyHandlerRef: EventHandlerRef?
  private let hotKeyId: UInt32 = 1
  private let trashHotKeyId: UInt32 = 2
  private var contextMenu: NSMenu?
  private var stopwatchItem: NSMenuItem?
  private var pauseItem: NSMenuItem?
  private var clearItem: NSMenuItem?
  private let panelCornerRadius: CGFloat = 8

  private static let statusBarImage: NSImage = {
    let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
    let image = NSImage(systemSymbolName: "hourglass", accessibilityDescription: nil)?
      .withSymbolConfiguration(config) ?? NSImage()
    image.isTemplate = true
    image.size = NSSize(width: 18, height: 18)
    return image
  }()

  private static let popoverWillShowNotification = Notification.Name("TockPopoverWillShow")

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    #if DEBUG
    terminateOtherInstances()
    #endif
    NSApp.windows.forEach { $0.orderOut(nil) }
    configurePanel()
    configureStatusItem()
    bindModel()
    updateStatusItem()
    registerHotKey()
  }

  private func terminateOtherInstances() {
    guard let bundleId = Bundle.main.bundleIdentifier else { return }
    let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
    let current = NSRunningApplication.current
    for app in runningApps where app.processIdentifier != current.processIdentifier {
      app.terminate()
    }
  }

  private func configurePanel() {
    let view = TockMenuView()
      .environmentObject(model)
      .environment(\.menuDismiss, MenuDismissAction { [weak self] in
        self?.closePanel()
      })
    let hostingView = NSHostingView(rootView: view)
    hostingView.wantsLayer = true
    hostingView.layer?.cornerRadius = panelCornerRadius
    hostingView.layer?.masksToBounds = true

    let panel = RoundedPanel(
      contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
      styleMask: [.borderless],
      backing: .buffered,
      defer: true
    )
    panel.isReleasedWhenClosed = false
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = true
    panel.level = .popUpMenu
    panel.collectionBehavior = [.transient, .moveToActiveSpace]
    panel.isMovableByWindowBackground = false
    panel.contentView = hostingView
    let fittingSize = hostingView.fittingSize
    let size = NSSize(
      width: fittingSize.width > 0 ? fittingSize.width : 210,
      height: fittingSize.height > 0 ? fittingSize.height : 160
    )
    panel.setContentSize(size)
    self.panel = panel
  }

  private func configureStatusItem() {
    guard let button = statusItem.button else { return }
    button.target = self
    button.action = #selector(statusItemClicked(_:))
    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
  }

  private func bindModel() {
    model.objectWillChange
      .sink { [weak self] _ in self?.updateStatusItem() }
      .store(in: &cancellables)
  }

  private func updateStatusItem() {
    guard let button = statusItem.button else { return }
    if model.isRunning {
      let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
      let attributes: [NSAttributedString.Key: Any] = [.font: font]
      button.attributedTitle = NSAttributedString(string: model.formattedRemaining, attributes: attributes)
      button.image = nil
    } else {
      button.title = ""
      button.attributedTitle = NSAttributedString(string: "")
      button.image = Self.statusBarImage
    }
    updateContextMenuItems()
  }

  @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
    guard let event = NSApp.currentEvent else { return }
    if event.type == .rightMouseUp || event.type == .rightMouseDown {
      showContextMenu()
    } else {
      togglePopover(sender)
    }
  }

  private func togglePopover(_ sender: NSStatusBarButton) {
    if panel?.isVisible == true {
      closePanel()
    } else {
      showPanel(sender)
    }
  }

  private func togglePopoverFromHotKey() {
    guard let button = statusItem.button else { return }
    togglePopover(button)
  }

  private func trashFromHotKey() {
    model.stop()
    closePanel()
  }

  private func showContextMenu() {
    let menu = NSMenu()
    menu.autoenablesItems = false
    menu.delegate = self
    let openItem = NSMenuItem(title: "Open", action: #selector(openTimerFromMenu), keyEquivalent: "t")
    openItem.keyEquivalentModifierMask = [.control, .option, .command]
    openItem.target = self
    menu.addItem(openItem)

    let startStopwatchItem = NSMenuItem(title: "Stopwatch", action: #selector(startStopwatchFromMenu), keyEquivalent: "")
    startStopwatchItem.target = self
    menu.addItem(startStopwatchItem)
    stopwatchItem = startStopwatchItem

    let newPauseItem = NSMenuItem(title: "Pause", action: #selector(pauseTimerFromMenu), keyEquivalent: "")
    newPauseItem.target = self
    menu.addItem(newPauseItem)
    pauseItem = newPauseItem

    let stopItem = NSMenuItem(title: "Clear", action: #selector(stopTimerFromMenu), keyEquivalent: "x")
    stopItem.keyEquivalentModifierMask = [.control, .option, .command]
    stopItem.target = self
    menu.addItem(stopItem)
    clearItem = stopItem

    menu.addItem(.separator())

    let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettingsFromMenu), keyEquivalent: ",")
    settingsItem.keyEquivalentModifierMask = [.command]
    settingsItem.target = self
    menu.addItem(settingsItem)

    let quitItem = NSMenuItem(title: "Quit Tock", action: #selector(quitApp), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)

    contextMenu = menu
    updateContextMenuItems()
    statusItem.menu = menu
    statusItem.button?.performClick(nil)
    statusItem.menu = nil
  }

  private func updateContextMenuItems() {
    guard contextMenu != nil else { return }
    stopwatchItem?.isEnabled = !model.isRunning || model.isCountdownFinished
    pauseItem?.isEnabled = model.isRunning && !model.isCountdownFinished
    clearItem?.isEnabled = model.isRunning

    if model.isPaused {
      pauseItem?.title = "Restart"
      pauseItem?.action = #selector(restartTimerFromMenu)
    } else {
      pauseItem?.title = "Pause"
      pauseItem?.action = #selector(pauseTimerFromMenu)
    }
  }

  func menuDidClose(_ menu: NSMenu) {
    if menu == contextMenu {
      contextMenu = nil
      stopwatchItem = nil
      pauseItem = nil
      clearItem = nil
    }
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }

  @objc private func openTimerFromMenu() {
    togglePopoverFromHotKey()
  }

  @objc private func startStopwatchFromMenu() {
    model.startStopwatch()
  }

  @objc private func pauseTimerFromMenu() {
    model.pause()
  }

  @objc private func restartTimerFromMenu() {
    model.resume()
  }

  @objc private func stopTimerFromMenu() {
    model.stop()
    closePanel()
  }

  @objc private func openSettingsFromMenu() {
    closePanel()
    SettingsWindowController.shared.show()
  }

  private func showPanel(_ sender: NSStatusBarButton) {
    guard let panel, let buttonWindow = sender.window else { return }
    NotificationCenter.default.post(name: Self.popoverWillShowNotification, object: nil)
    let buttonFrame = buttonWindow.convertToScreen(sender.frame)
    let panelSize = panel.frame.size
    var origin = NSPoint(
      x: buttonFrame.midX - (panelSize.width / 2),
      y: buttonFrame.minY - panelSize.height
    )
    if let screen = buttonWindow.screen {
      let visible = screen.visibleFrame
      origin.x = min(max(origin.x, visible.minX + 6), visible.maxX - panelSize.width - 6)
      origin.y = min(max(origin.y, visible.minY + 6), visible.maxY - panelSize.height - 6)
    }
    panel.setFrameOrigin(origin)
    NSApp.activate(ignoringOtherApps: true)
    panel.makeKeyAndOrderFront(nil)
    addPanelEventMonitors()
  }

  private func closePanel() {
    panel?.orderOut(nil)
    removePanelEventMonitors()
  }

  private func addPanelEventMonitors() {
    if globalEventMonitor == nil {
      globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
        self?.handleGlobalClick()
      }
    }
    if localEventMonitor == nil {
      localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
        guard let self else { return event }
        if event.type == .keyDown, event.keyCode == 53 {
          self.closePanel()
          return nil
        }
        if self.isStatusItemClick(event) {
          return event
        }
        if event.window === self.panel {
          return event
        }
        self.closePanel()
        return event
      }
    }
  }

  private func handleGlobalClick() {
    guard let panel else { return }
    let mouseLocation = NSEvent.mouseLocation
    if isStatusItemClick(at: mouseLocation) {
      return
    }
    if panel.frame.contains(mouseLocation) {
      return
    }
    closePanel()
  }

  private func isStatusItemClick(_ event: NSEvent) -> Bool {
    guard let button = statusItem.button, let window = button.window else { return false }
    guard event.window === window else { return false }
    return button.frame.contains(event.locationInWindow)
  }

  private func isStatusItemClick(at point: NSPoint) -> Bool {
    guard let button = statusItem.button, let window = button.window else { return false }
    let buttonFrame = window.convertToScreen(button.frame)
    return buttonFrame.contains(point)
  }

  private func removePanelEventMonitors() {
    if let globalEventMonitor {
      NSEvent.removeMonitor(globalEventMonitor)
      self.globalEventMonitor = nil
    }
    if let localEventMonitor {
      NSEvent.removeMonitor(localEventMonitor)
      self.localEventMonitor = nil
    }
  }

  private func registerHotKey() {
    let modifiers: UInt32 = UInt32(controlKey | optionKey | cmdKey)
    let signature = OSType(bitPattern: 0x544F434B)
    let hotKeyID = EventHotKeyID(signature: signature, id: hotKeyId)
    RegisterEventHotKey(UInt32(kVK_ANSI_T), modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
    let trashHotKeyID = EventHotKeyID(signature: signature, id: trashHotKeyId)
    RegisterEventHotKey(UInt32(kVK_ANSI_X), modifiers, trashHotKeyID, GetEventDispatcherTarget(), 0, &trashHotKeyRef)

    if hotKeyHandlerRef == nil {
      var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
      InstallEventHandler(GetEventDispatcherTarget(), { _, event, userData in
        guard let event, let userData else { return noErr }
        var hkID = EventHotKeyID()
        let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
        guard status == noErr else { return status }
        let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
        DispatchQueue.main.async {
          if hkID.id == appDelegate.hotKeyId {
            appDelegate.togglePopoverFromHotKey()
          } else if hkID.id == appDelegate.trashHotKeyId {
            appDelegate.trashFromHotKey()
          }
        }
        return noErr
      }, 1, &eventType, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &hotKeyHandlerRef)
    }
  }
}

private final class RoundedPanel: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
}
