import AppKit
import SwiftUI

#if canImport(KeyboardShortcuts)
import KeyboardShortcuts
final class RecorderContainerView: NSView {
  let recorder: KeyboardShortcuts.RecorderCocoa

  init(name: KeyboardShortcuts.Name, onChange: @escaping (KeyboardShortcuts.Shortcut?) -> Void) {
    recorder = KeyboardShortcuts.RecorderCocoa(for: name, onChange: onChange)
    super.init(frame: .zero)
    recorder.focusRingType = .default
    recorder.wantsLayer = true
    recorder.layer?.borderWidth = 1
    recorder.layer?.borderColor = borderColor().cgColor
    recorder.translatesAutoresizingMaskIntoConstraints = false
    addSubview(recorder)
    setContentHuggingPriority(.defaultHigh, for: .vertical)
    setContentHuggingPriority(.defaultHigh, for: .horizontal)
    NSLayoutConstraint.activate([
      recorder.leadingAnchor.constraint(equalTo: leadingAnchor),
      recorder.trailingAnchor.constraint(equalTo: trailingAnchor),
      recorder.topAnchor.constraint(equalTo: topAnchor),
      recorder.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: NSSize {
    recorder.intrinsicContentSize
  }

  override func layout() {
    super.layout()
    recorder.layer?.cornerCurve = .continuous
    recorder.layer?.cornerRadius = recorder.bounds.height / 2
    recorder.layer?.borderColor = borderColor().cgColor
  }

  private func borderColor() -> NSColor {
    let match = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
    if match == .darkAqua {
      return NSColor.tertiaryLabelColor
    }
    return NSColor.separatorColor
  }

}

struct KeyboardShortcutsRecorderRepresentable: NSViewRepresentable {
  typealias NSViewType = RecorderContainerView

  let name: KeyboardShortcuts.Name
  let onChange: (KeyboardShortcuts.Shortcut?) -> Void

  func makeNSView(context: Context) -> NSViewType {
    RecorderContainerView(name: name, onChange: onChange)
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {
    nsView.recorder.shortcutName = name
  }
}
#endif
