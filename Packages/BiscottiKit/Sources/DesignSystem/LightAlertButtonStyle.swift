import SwiftUI

/// Red recording pill shared by Stop & Save and the recording-state header
/// button.
///
/// Solid `signalRed` capsule with white content, slightly dimmed on hover.
/// The caller's label controls layout (padding, height); this style only
/// provides the chrome. Red is reserved for recording, so only recording
/// controls use it.
public struct LightAlertButtonStyle: ButtonStyle {
    @State private var isHovering = false
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(Capsule().fill(Color.signalRed.opacity(isHovering ? 0.88 : 1)))
            .contentShape(Capsule())
            .opacity(
                !isEnabled ? 0.4 : configuration.isPressed ? 0.7 : 1.0
            )
            .onHover { isHovering = $0 }
    }
}

#Preview("LightAlertButtonStyle") {
    VStack(spacing: 16) {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 9))
                Text("Stop & Save")
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 15)
            .frame(height: 34)
        }
        .buttonStyle(LightAlertButtonStyle())

        Button {} label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.signalRed)
                    .frame(width: 8, height: 8)
                Text("REC 02:14")
                    .font(.monoMetaMedium)
            }
            .padding(.horizontal, 16)
            .frame(height: 34)
        }
        .buttonStyle(LightAlertButtonStyle())
    }
    .padding()
    .background(Tokens.contentBackground)
}
