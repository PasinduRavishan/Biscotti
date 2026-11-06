import SwiftUI

/// The large, solid calendar-colored card that features the next meeting.
/// Text is white; actions are supplied by the caller (use `PillButtonStyle`).
public struct FeaturedCard<Actions: View>: View {
    private let colorHex: String?
    private let status: String
    private let title: String
    private let detail: String
    private let actions: Actions

    public init(
        colorHex: String?,
        status: String,
        title: String,
        detail: String,
        @ViewBuilder actions: () -> Actions
    ) {
        self.colorHex = colorHex
        self.status = status
        self.title = title
        self.detail = detail
        self.actions = actions()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(status)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
            Text(title)
                .font(.featuredTitle)
                .foregroundStyle(.white)
                .lineLimit(2)
                .truncationMode(.tail)
                .padding(.top, 4)
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .padding(.top, 2)
            HStack(spacing: 10) {
                actions
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: Tokens.cardRadius)
                .fill(TileColor.fill(hex: colorHex))
        )
    }
}

/// Capsule buttons for the Games-style look.
public struct PillButtonStyle: ButtonStyle {
    public enum Kind: Sendable {
        /// White fill, black label: the main action on a colored card.
        case primaryOnColor
        /// Translucent white fill, white label: a secondary action on a colored card.
        case secondaryOnColor
        /// Accent fill, white label: a main action on a plain surface.
        case accent
    }

    private let kind: Kind
    @Environment(\.isEnabled) private var isEnabled

    public init(_ kind: Kind) {
        self.kind = kind
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.vertical, 7)
            .padding(.horizontal, 14)
            .background(Capsule().fill(background))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.5)
            .contentShape(Capsule())
    }

    private var foreground: Color {
        switch kind {
        case .primaryOnColor: .black
        case .secondaryOnColor, .accent: .white
        }
    }

    private var background: Color {
        switch kind {
        case .primaryOnColor: .white
        case .secondaryOnColor: .white.opacity(0.2)
        case .accent: .accentFill
        }
    }
}

#Preview("Featured card") {
    VStack(spacing: 16) {
        FeaturedCard(
            colorHex: "#3D3FA8",
            status: "Starting in 6 min",
            title: "Design sync",
            detail: "10:30 – 11:00 · Google Meet · Ana, Raj, +3"
        ) {
            Button("Join and record", systemImage: "mic") {}
                .buttonStyle(PillButtonStyle(.primaryOnColor))
            Button("View in calendar") {}
                .buttonStyle(PillButtonStyle(.secondaryOnColor))
        }
        FeaturedCard(
            colorHex: "#FFD60A",
            status: "Tomorrow at 10:30 AM",
            title: "A very long meeting title that keeps going to check that it truncates on two lines cleanly",
            detail: "10:30 – 11:30 · Zoom"
        ) {
            Button("View in calendar") {}
                .buttonStyle(PillButtonStyle(.secondaryOnColor))
        }
        Button("Continue") {}
            .buttonStyle(PillButtonStyle(.accent))
    }
    .padding(20)
    .frame(width: 560)
    .background(Tokens.contentBackground)
}
