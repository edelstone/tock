import SwiftUI

struct MenuDismissAction {
  let action: () -> Void

  func callAsFunction() {
    action()
  }
}

private struct MenuDismissKey: EnvironmentKey {
  static let defaultValue = MenuDismissAction {}
}

extension EnvironmentValues {
  var menuDismiss: MenuDismissAction {
    get { self[MenuDismissKey.self] }
    set { self[MenuDismissKey.self] = newValue }
  }
}
