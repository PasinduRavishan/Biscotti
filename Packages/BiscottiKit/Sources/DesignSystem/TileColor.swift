import AppKit
import SwiftUI

/// Turns a calendar's `#RRGGBB` color into a fill that white text and icons
/// can sit on. Missing or unparseable colors become neutral gray; colors too
/// light for white text are darkened until they reach WCAG 4.5:1.
public enum TileColor {
    /// #6E6E73 — used when there's no usable calendar color.
    static let neutral = NSColor(srgbRed: 110 / 255, green: 110 / 255, blue: 115 / 255, alpha: 1)

    private static let minimumContrast: CGFloat = 4.5
    private static let darkenFactor: CGFloat = 0.85
    private static let maxDarkenSteps = 12

    public static func resolve(hex: String?) -> NSColor {
        guard let hex, var color = parse(hex) else { return neutral }
        for _ in 0 ..< maxDarkenSteps where contrastAgainstWhite(color) < minimumContrast {
            color = NSColor(
                srgbRed: color.redComponent * darkenFactor,
                green: color.greenComponent * darkenFactor,
                blue: color.blueComponent * darkenFactor,
                alpha: 1
            )
        }
        return color
    }

    /// SwiftUI convenience for `resolve(hex:)`.
    public static func fill(hex: String?) -> Color {
        Color(nsColor: resolve(hex: hex))
    }

    /// WCAG contrast ratio of white against `color`.
    static func contrastAgainstWhite(_ color: NSColor) -> CGFloat {
        guard let srgb = color.usingColorSpace(.sRGB) else { return 1 }
        func linear(_ channel: CGFloat) -> CGFloat {
            channel <= 0.039_28 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * linear(srgb.redComponent)
            + 0.7152 * linear(srgb.greenComponent)
            + 0.0722 * linear(srgb.blueComponent)
        return 1.05 / (luminance + 0.05)
    }

    private static func parse(_ hex: String) -> NSColor? {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        return NSColor(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
