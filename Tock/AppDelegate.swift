import AppKit
import SwiftUI
import Combine
import Carbon

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private let popover = NSPopover()
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
    configurePopover()
    configureStatusItem()
    bindModel()
    updateStatusItem()
    registerHotKey()
  }

  private func configurePopover() {
    let view = TockMenuView()
      .environmentObject(model)
      .environment(\.menuDismiss, MenuDismissAction { [weak self] in
        self?.popover.performClose(nil)
      })
    popover.contentViewController = NSHostingController(rootView: view)
    popover.behavior = .transient
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
    if popover.isShown {
      popover.performClose(sender)
    } else {
      NotificationCenter.default.post(name: Self.popoverWillShowNotification, object: nil)
      popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }
  }

  private func togglePopoverFromHotKey() {
    guard let button = statusItem.button else { return }
    togglePopover(button)
  }

  private func trashFromHotKey() {
    model.stop()
    popover.performClose(nil)
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
    popover.performClose(nil)
  }

  private func registerHotKey() {
    let modifiers: UInt32 = UInt32(controlKey | optionKey | cmdKey)
    let signature = OSType(bitPattern: 0x544F434B)
    var hotKeyID = EventHotKeyID(signature: signature, id: hotKeyId)
    RegisterEventHotKey(UInt32(kVK_ANSI_T), modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
    var trashHotKeyID = EventHotKeyID(signature: signature, id: trashHotKeyId)
    RegisterEventHotKey(UInt32(kVK_ANSI_X), modifiers, trashHotKeyID, GetEventDispatcherTarget(), 0, &trashHotKeyRef)

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
