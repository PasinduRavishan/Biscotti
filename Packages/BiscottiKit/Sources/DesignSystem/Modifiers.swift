import SwiftUI

// MARK: - Kicker modifier

/// Applies the section-label style: 12pt semibold, secondary color, sentence case.
/// Usage: `Text("Upcoming").kicker()`
private struct KickerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.monoKicker)
            .foregroundStyle(.inkSecondary)
    }
}

public extension View {
    /// Style this text as a small section label.
    func kicker() -> some View {
        modifier(KickerModifier())
    }
}
