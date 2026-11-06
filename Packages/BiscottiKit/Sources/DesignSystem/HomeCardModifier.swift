import SwiftUI

/// Applies the card style: flat raised fill, `Tokens.cardRadius` corners and a
/// hairline stroke. No shadow.
public struct HomeCardModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(Tokens.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.cardRadius)
                    .strokeBorder(Tokens.cardStroke, lineWidth: 0.5)
            )
    }
}

public extension View {
    /// Wraps the view in a flat card (raised fill, hairline border).
    func homeCard() -> some View {
        modifier(HomeCardModifier())
    }
}

/// A thin hairline divider inset from the leading edge to align under text, not avatars.
public struct InsetDivider: View {
    private let leadingInset: CGFloat

    public init(leadingInset: CGFloat = 14) {
        self.leadingInset = leadingInset
    }

    public var body: some View {
        Tokens.hairline
            .frame(height: 0.5)
            .padding(.leading, leadingInset)
    }
}

#Preview("Home Card") {
    VStack(spacing: 8) {
        Text("Row 1")
            .padding(12)

        InsetDivider()

        Text("Row 2")
            .padding(12)
    }
    .homeCard()
    .padding(32)
    .background(Tokens.contentBackground)
}
