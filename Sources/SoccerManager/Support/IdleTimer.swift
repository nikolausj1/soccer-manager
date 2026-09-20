import SwiftUI
import UIKit

private struct KeepsScreenAwakeModifier: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        content
            .onAppear { UIApplication.shared.isIdleTimerDisabled = isOn }
            .onChange(of: isOn) { _, newValue in
                UIApplication.shared.isIdleTimerDisabled = newValue
            }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

extension View {
    /// Disables the idle timer (screen auto-lock) while `on` is true and
    /// this view is visible, and restores normal auto-lock behavior once it
    /// disappears or `on` becomes false.
    func keepsScreenAwake(_ on: Bool) -> some View {
        modifier(KeepsScreenAwakeModifier(isOn: on))
    }
}
