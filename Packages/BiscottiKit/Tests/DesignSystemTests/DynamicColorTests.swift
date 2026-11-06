import AppKit
import Foundation
import SwiftUI
import Testing
@testable import DesignSystem

// MARK: - Test helpers

/// Resolved sRGB color components for comparison.
private struct SRGB {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat
}

/// Resolves a dynamic `NSColor` under a specific appearance and returns sRGB components.
private func resolve(
    _ color: NSColor, appearance appearanceName: NSAppearance.Name
) -> SRGB {
    var result = SRGB(red: 0, green: 0, blue: 0, alpha: 0)
    // swiftlint:disable:next force_unwrapping
    NSAppearance(named: appearanceName)!.performAsCurrentDrawingAppearance {
        // swiftlint:disable:next force_unwrapping
        let resolved = color.usingColorSpace(.sRGB)!
        result = SRGB(
            red: resolved.redComponent,
            green: resolved.greenComponent,
            blue: resolved.blueComponent,
            alpha: resolved.alphaComponent
        )
    }
    return result
}

/// Resolves a dynamic SwiftUI `Color` (via its NSColor backing) under a specific appearance.
/// **Assumption:** all SwiftUI `Color` tokens in this codebase are backed by `Color(nsColor:)` or
/// `dynamicColor(light:dark:)` (which uses `Color(nsColor:)` internally), so round-tripping
/// through `NSColor(Color)` recovers the underlying dynamic `NSColor` for appearance resolution.
/// If a token were ever built from a raw `Color(red:green:blue:)` initializer, this helper would
/// lose the dynamic provider and always return the light value.
private func resolve(
    _ color: Color, appearance appearanceName: NSAppearance.Name
) -> SRGB {
    let nsColor = NSColor(color)
    return resolve(nsColor, appearance: appearanceName)
}

/// Sub-8-bit tolerance (1/512 ~ 0.00195).
private let tolerance: CGFloat = 1.0 / 512.0

private func assertSRGB(
    _ actual: SRGB,
    expected: SRGB,
    label: String,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(
        abs(actual.red - expected.red) <= tolerance,
        "\(label) red: expected \(expected.red), got \(actual.red)",
        sourceLocation: sourceLocation
    )
    #expect(
        abs(actual.green - expected.green) <= tolerance,
        "\(label) green: expected \(expected.green), got \(actual.green)",
        sourceLocation: sourceLocation
    )
    #expect(
        abs(actual.blue - expected.blue) <= tolerance,
        "\(label) blue: expected \(expected.blue), got \(actual.blue)",
        sourceLocation: sourceLocation
    )
    #expect(
        abs(actual.alpha - expected.alpha) <= tolerance,
        "\(label) alpha: expected \(expected.alpha), got \(actual.alpha)",
        sourceLocation: sourceLocation
    )
}

private func hex(_ red: Int, _ green: Int, _ blue: Int, alpha: CGFloat = 1) -> SRGB {
    SRGB(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: alpha)
}

/// Asserts a token resolves to the same sRGB value as a system color, optionally
/// with a different alpha, under both appearances.
private func assertMatchesSystem(
    _ token: NSColor,
    _ system: NSColor,
    alpha: CGFloat? = nil,
    label: String,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for appearance in [NSAppearance.Name.aqua, .darkAqua] {
        var expected = resolve(system, appearance: appearance)
        if let alpha {
            expected = SRGB(red: expected.red, green: expected.green, blue: expected.blue, alpha: alpha)
        }
        assertSRGB(
            resolve(token, appearance: appearance),
            expected: expected,
            label: "\(label) \(appearance.rawValue)",
            sourceLocation: sourceLocation
        )
    }
}

// MARK: - Test 1: Neutral surfaces

@Suite("Surfaces are neutral, not warm")
struct SurfaceValuesTests {
    @Test("paper is white / #1C1C1E")
    func paper() {
        assertSRGB(resolve(Color.paper, appearance: .aqua), expected: hex(255, 255, 255), label: "paper light")
        assertSRGB(resolve(Color.paper, appearance: .darkAqua), expected: hex(28, 28, 30), label: "paper dark")
    }

    @Test("listPaneBackground is #F5F5F7 / #1C1C1E")
    func listPane() {
        assertSRGB(resolve(Color.listPaneBackground, appearance: .aqua), expected: hex(245, 245, 247), label: "list light")
        assertSRGB(resolve(Color.listPaneBackground, appearance: .darkAqua), expected: hex(28, 28, 30), label: "list dark")
    }

    @Test("sidebarTint and wall are #F2F2F4 / #2C2C2E")
    func sidebar() {
        for color in [Color.sidebarTint, Color.wall] {
            assertSRGB(resolve(color, appearance: .aqua), expected: hex(242, 242, 244), label: "sidebar light")
            assertSRGB(resolve(color, appearance: .darkAqua), expected: hex(44, 44, 46), label: "sidebar dark")
        }
    }

    @Test("cardFill, elevatedFill and avatarRing are #F5F5F7 / #2C2C2E")
    func cards() {
        for color in [Color.cardFill, Color.elevatedFill, Color.avatarRing, Tokens.cardFill] {
            assertSRGB(resolve(color, appearance: .aqua), expected: hex(245, 245, 247), label: "card light")
            assertSRGB(resolve(color, appearance: .darkAqua), expected: hex(44, 44, 46), label: "card dark")
        }
    }

    @Test("neutralChip is black 6% / white 10%")
    func neutralChip() {
        assertSRGB(resolve(Color.neutralChip, appearance: .aqua), expected: hex(0, 0, 0, alpha: 0.06), label: "chip light")
        assertSRGB(resolve(Color.neutralChip, appearance: .darkAqua), expected: hex(255, 255, 255, alpha: 0.10), label: "chip dark")
    }

    @Test("shadows are fully transparent")
    func shadows() {
        for color in [Color.cardShadow, Color.controlShadow] {
            for appearance in [NSAppearance.Name.aqua, .darkAqua] {
                #expect(resolve(color, appearance: appearance).alpha == 0)
            }
        }
    }
}

// MARK: - Test 2: Text and accents follow the system

@Suite("Text and accent tokens follow system colors")
struct SystemColorTests {
    @Test("text tokens match label colors")
    func text() {
        assertMatchesSystem(.ink, .labelColor, label: "ink")
        assertMatchesSystem(NSColor(Color.read), .labelColor, label: "read")
        assertMatchesSystem(.inkSecondary, .secondaryLabelColor, label: "inkSecondary")
        assertMatchesSystem(.inkTertiary, .tertiaryLabelColor, label: "inkTertiary")
    }

    @Test("separators match separatorColor")
    func separators() {
        assertMatchesSystem(.cardStroke, .separatorColor, label: "cardStroke")
        assertMatchesSystem(NSColor(Color.hairline), .separatorColor, label: "hairline")
    }

    @Test("sage and accent fills are the system accent color")
    func accent() {
        assertMatchesSystem(.sage, .controlAccentColor, label: "sage")
        assertMatchesSystem(NSColor(Color.accentFill), .controlAccentColor, label: "accentFill")
        assertMatchesSystem(NSColor(Color.accentTrack), .controlAccentColor, label: "accentTrack")
    }

    @Test("accent washes are the system accent at fixed alphas")
    func washes() {
        assertMatchesSystem(NSColor(Color.accentWashSoft), .controlAccentColor, alpha: 0.10, label: "accentWashSoft")
        assertMatchesSystem(.accentWashStrong, .controlAccentColor, alpha: 0.18, label: "accentWashStrong")
        assertMatchesSystem(NSColor(Color.softSageFill), .controlAccentColor, alpha: 0.14, label: "softSageFill")
        assertMatchesSystem(.findHighlightFocused, .controlAccentColor, alpha: 0.35, label: "findHighlightFocused")
    }

    @Test("red and warning tokens use system red and orange")
    func status() {
        assertMatchesSystem(NSColor(Color.signalRed), .systemRed, label: "signalRed")
        assertMatchesSystem(NSColor(Color.signalRedText), .systemRed, label: "signalRedText")
        assertMatchesSystem(NSColor(Color.recordingOutline), .systemRed, alpha: 0.32, label: "recordingOutline")
        assertMatchesSystem(NSColor(Color.warningOchre), .systemOrange, label: "warningOchre")
        assertMatchesSystem(NSColor(Color.warningChipText), .systemOrange, label: "warningChipText")
    }
}

// MARK: - Test 4: No colorScheme conditionals in view code

@Suite("No colorScheme conditionals in view code")
struct NoColorSchemeConditionalsTests {
    @Test("No @Environment colorScheme or colorScheme == in view sources")
    func noColorSchemeInViews() throws {
        // Find the Sources directory relative to this test file.
        // The repo structure is: Packages/BiscottiKit/Sources/... and .../Tests/...
        let testsDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let biscottiKitDir = testsDir
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // BiscottiKit/
        let sourcesDir = biscottiKitDir.appendingPathComponent("Sources")

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: sourcesDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            Issue.record("Could not enumerate Sources directory at \(sourcesDir.path)")
            return
        }

        var violations: [String] = []
        let dynamicColorFile = "DynamicColor.swift"

        while let url = enumerator.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            let filename = url.lastPathComponent
            // The only allowed appearance logic lives in DynamicColor.swift.
            if filename == dynamicColorFile { continue }

            let contents = try String(contentsOf: url, encoding: .utf8)
            if contents.contains("colorScheme ==")
                || contents.contains("@Environment(\\.colorScheme)")
            {
                violations.append(filename)
            }
        }

        #expect(
            violations.isEmpty,
            "Files with colorScheme conditionals (should be zero): \(violations)"
        )
    }
}
