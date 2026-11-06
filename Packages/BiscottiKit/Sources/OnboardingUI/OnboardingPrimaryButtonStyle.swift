import DesignSystem
import SwiftUI

/// Roomy accent capsule for onboarding CTAs (Continue, Get Started,
/// Download Now): the `PillButtonStyle(.accent)` idiom at onboarding scale.
struct OnboardingPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14.5, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(height: 40)
            .background(Capsule().fill(Color.accentFill))
            .contentShape(Capsule())
            .opacity(
                !isEnabled ? 0.4 : configuration.isPressed ? 0.7 : 1.0
            )
    }
}
