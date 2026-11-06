import AppKit
import SwiftUI

// MARK: - Semantic color palette — native, neutral, appearance-adaptive

// Surfaces are neutral greys (Games-style dark showcase in dark mode, plain
// native light surfaces in light mode). Text, separators and the accent come
// straight from AppKit's semantic system colors, which already resolve per
// appearance and follow the user's macOS accent setting. Fixed surface values
// use `dynamicColor`. Views never branch on `colorScheme`.
//
// TODO: rename sage/paper/ink tokens to accent/background/label once the
// redesign settles; the names are legacy from the previous identity.

// MARK: - NSColor tokens (single source of truth)

// Tokens that have AppKit consumers (markdown editor, etc.) are defined as
// `NSColor` first; the `Color` extension derives from them via `Color(nsColor:)`.

public extension NSColor {
    /// Primary text — the system label color.
    static let ink = NSColor.labelColor

    /// Secondary text — the system secondary label color.
    static let inkSecondary = NSColor.secondaryLabelColor

    /// Tertiary text / chevrons — the system tertiary label color.
    static let inkTertiary = NSColor.tertiaryLabelColor

    /// Accent — the user's macOS accent color (legacy name).
    static let sage = NSColor.controlAccentColor

    /// Selection background: accent @ 18%.
    static let accentWashStrong = dynamicNSColor(.controlAccentColor, alpha: 0.18)

    /// Focused find-match highlight: accent @ 35%.
    static let findHighlightFocused = dynamicNSColor(.controlAccentColor, alpha: 0.35)

    /// Card border (0.5pt) — the system separator color.
    static let cardStroke = NSColor.separatorColor
}

/// #1C1C1E — dark content background.
private let darkBase = NSColor(srgbRed: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
/// #2C2C2E — dark raised surface (cards, sidebar).
private let darkRaised = NSColor(srgbRed: 44 / 255, green: 44 / 255, blue: 46 / 255, alpha: 1)
/// #F5F5F7 — light raised surface (cards, list pane).
private let lightRaised = NSColor(srgbRed: 245 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1)
/// #F2F2F4 — light sidebar.
private let lightSidebar = NSColor(srgbRed: 242 / 255, green: 242 / 255, blue: 244 / 255, alpha: 1)

// MARK: - Color tokens (SwiftUI)

public extension Color {
    /// Content background: white / #1C1C1E.
    static let paper = dynamicColor(light: .white, dark: darkBase)

    /// Primary text.
    static let ink = Color(nsColor: .ink)

    /// Accent — the user's macOS accent color (legacy name).
    static let sage = Color(nsColor: .sage)

    /// Secondary text.
    static let inkSecondary = Color(nsColor: .inkSecondary)

    /// Tertiary text / chevrons.
    static let inkTertiary = Color(nsColor: .inkTertiary)

    /// Separator.
    static let hairline = Color(nsColor: .separatorColor)

    /// Neutral chip fill: black @ 6% / white @ 10%.
    static let neutralChip = dynamicColor(
        light: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.06),
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.10)
    )

    /// Card border (0.5pt).
    static let cardStroke = Color(nsColor: .cardStroke)

    /// Selection background: accent @ 18%.
    static let accentWashStrong = Color(nsColor: .accentWashStrong)

    /// Focused find-match highlight: accent @ 35%.
    static let findHighlightFocused = Color(nsColor: .findHighlightFocused)

    /// Soft accent tint (speaker chips): accent @ 10%.
    static let accentWashSoft = Color(nsColor: dynamicNSColor(.controlAccentColor, alpha: 0.10))

    /// **The single canonical red for the entire app** — system red.
    ///
    /// Use for **marks**: dots, icons, stop-square, fills, borders.
    ///
    /// **Approved usages:**
    /// - **Error / failure states:** error icons, error-tinted backgrounds
    ///   (`signalRed.opacity(0.15)`).
    /// - **Recording indicators:** the pulsing recording dot, Stop button fill.
    /// - **Destructive actions & buttons:** destructive icons and filled
    ///   destructive buttons (pair with white label).
    static let signalRed = Color(nsColor: .systemRed)

    /// **The single canonical warning color** — system orange.
    static let warningOchre = Color(nsColor: .systemOrange)

    /// Window wall: #F2F2F4 / #2C2C2E.
    static let wall = dynamicColor(light: lightSidebar, dark: darkRaised)

    /// Sidebar tint: #F2F2F4 / #2C2C2E.
    static let sidebarTint = dynamicColor(light: lightSidebar, dark: darkRaised)

    // MARK: - Recording tokens

    /// Sidebar "Recording now" row fill; auto-stop card wash: signalRed @ 8%.
    static let recordingTintSoft = signalRed.opacity(0.08)

    /// Selected sidebar recording row fill: signalRed @ 12%.
    static let recordingTintStrong = signalRed.opacity(0.12)

    /// Stop/REC button hairline: system red @ 32%.
    static let recordingOutline = Color(nsColor: dynamicNSColor(.systemRed, alpha: 0.32))

    /// Selected recording row inset stroke: signalRed @ 20%.
    static let recordingOutlineStrong = signalRed.opacity(0.20)

    /// Stop/REC button hover: signalRed @ 5%.
    static let recordingHoverFill = signalRed.opacity(0.05)

    /// Amber chip text — system orange.
    static let warningChipText = Color(nsColor: .systemOrange)

    /// "Add note" + "Keep Recording" button fill: accent @ 14% (legacy name).
    static let softSageFill = Color(nsColor: dynamicNSColor(.controlAccentColor, alpha: 0.14))

    // MARK: - Surfaces

    /// Card fill: #F5F5F7 / #2C2C2E. All card surfaces adapt via this token.
    static let cardFill = dynamicColor(light: lightRaised, dark: darkRaised)

    /// Button fills — the system accent.
    static let accentFill = Color(nsColor: .controlAccentColor)

    /// Long-form body text (transcripts) — the system label color.
    static let read = Color(nsColor: .labelColor)

    /// Elevated control fill: #F5F5F7 / #2C2C2E.
    static let elevatedFill = dynamicColor(light: lightRaised, dark: darkRaised)

    /// Progress-bar fills — the system accent.
    static let accentTrack = Color(nsColor: .controlAccentColor)

    /// Standalone red text labels — system red (already adapts for dark).
    static let signalRedText = Color(nsColor: .systemRed)

    /// Card shadow — none. Flat surfaces only.
    static let cardShadow = Color.clear

    /// Control shadow — none. Flat surfaces only.
    static let controlShadow = Color.clear

    /// Avatar stacked-ring border: matches `cardFill` so the ring cuts a gap
    /// between overlapping circles.
    static let avatarRing = dynamicColor(light: lightRaised, dark: darkRaised)

    /// Brand mark tint: opaque black / white. Opaque (unlike `labelColor`) so
    /// the mark isn't faded by the mask.
    static let brandMarkTint = dynamicColor(light: .black, dark: .white)

    // MARK: - List pane

    /// List pane background (meetings list): #F5F5F7 / #1C1C1E.
    static let listPaneBackground = dynamicColor(light: lightRaised, dark: darkBase)

    // MARK: - On solid-accent (selected) surface tokens

    /// Primary text on a solid-accent (selected) surface — pure white.
    /// Appearance-independent (white reads on both light and dark `accentFill`).
    static let onAccent: Color = .white

    /// Secondary text on a solid-accent surface — white @ 72%.
    /// Used for the when-line and `+N` overflow on selected rows.
    static let onAccentMuted: Color = .white.opacity(0.72)

    /// Tag pill fill on a solid-accent surface — white @ 18%.
    static let onAccentChipFill: Color = .white.opacity(0.18)

    /// Tag dot ring on a solid-accent surface — white @ 50%.
    /// A 0.5px ring around coloured dots so slate/teal/olive stay legible on sage.
    static let onAccentChipRing: Color = .white.opacity(0.5)

    // MARK: - Tag-dot palette (8 swatches)

    /// Fixed, ordered palette of 8 adaptive tag-dot colours. Sage is
    /// reserved and absent. Assigned round-robin by creation order; stored
    /// as a stable `colorSlot` on each tag. Dark values are starting
    /// proposals -- a human eyeballs them on hardware (Phase 4).
    static let tagSwatches: [Color] = [
        // 0: Blue
        dynamicColor(
            light: NSColor(srgbRed: 0.243, green: 0.427, blue: 0.659, alpha: 1),
            dark: NSColor(srgbRed: 0.431, green: 0.604, blue: 0.816, alpha: 1)
        ),
        // 1: Clay
        dynamicColor(
            light: NSColor(srgbRed: 0.710, green: 0.408, blue: 0.243, alpha: 1),
            dark: NSColor(srgbRed: 0.816, green: 0.541, blue: 0.369, alpha: 1)
        ),
        // 2: Violet
        dynamicColor(
            light: NSColor(srgbRed: 0.478, green: 0.416, blue: 0.682, alpha: 1),
            dark: NSColor(srgbRed: 0.639, green: 0.584, blue: 0.816, alpha: 1)
        ),
        // 3: Slate
        dynamicColor(
            light: NSColor(srgbRed: 0.420, green: 0.482, blue: 0.525, alpha: 1),
            dark: NSColor(srgbRed: 0.604, green: 0.667, blue: 0.710, alpha: 1)
        ),
        // 4: Red -- reuses signalRed light/dark pair
        signalRed,
        // 5: Teal
        dynamicColor(
            light: NSColor(srgbRed: 0.165, green: 0.549, blue: 0.494, alpha: 1),
            dark: NSColor(srgbRed: 0.310, green: 0.702, blue: 0.639, alpha: 1)
        ),
        // 6: Amber
        dynamicColor(
            light: NSColor(srgbRed: 0.659, green: 0.518, blue: 0.227, alpha: 1),
            dark: NSColor(srgbRed: 0.796, green: 0.659, blue: 0.369, alpha: 1)
        ),
        // 7: Olive
        dynamicColor(
            light: NSColor(srgbRed: 0.369, green: 0.549, blue: 0.227, alpha: 1),
            dark: NSColor(srgbRed: 0.541, green: 0.722, blue: 0.380, alpha: 1)
        )
    ]

    /// Returns the tag-dot colour for a given palette slot (0-7).
    /// Wraps safely for any integer (negative, >7).
    static func tagSwatch(slot: Int) -> Color {
        tagSwatches[((slot % 8) + 8) % 8]
    }
}

// MARK: - ShapeStyle sugar

// Lets call sites use `.foregroundStyle(.ink)`, `.fill(.sage)`, `.background(.paper)`.

public extension ShapeStyle where Self == Color {
    static var paper: Color {
        .paper
    }

    static var ink: Color {
        .ink
    }

    static var sage: Color {
        .sage
    }

    static var inkSecondary: Color {
        .inkSecondary
    }

    static var inkTertiary: Color {
        .inkTertiary
    }

    static var signalRed: Color {
        .signalRed
    }

    static var warningOchre: Color {
        .warningOchre
    }

    // Note: `.hairline` and `.neutralChip` are less commonly used as ShapeStyles
    // so they are accessed through Color.hairline / Color.neutralChip directly.

    /// New tokens (Phase 1)
    static var accentFill: Color {
        .accentFill
    }

    static var read: Color {
        .read
    }

    static var elevatedFill: Color {
        .elevatedFill
    }

    static var accentTrack: Color {
        .accentTrack
    }

    static var signalRedText: Color {
        .signalRedText
    }

    static var cardShadow: Color {
        .cardShadow
    }

    static var controlShadow: Color {
        .controlShadow
    }

    static var cardFill: Color {
        .cardFill
    }

    static var avatarRing: Color {
        .avatarRing
    }

    /// On solid-accent (selected) surface tokens
    static var onAccent: Color {
        .onAccent
    }

    static var onAccentMuted: Color {
        .onAccentMuted
    }
}
