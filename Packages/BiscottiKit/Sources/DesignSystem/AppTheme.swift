import AppKit
import Foundation

/// The user's appearance preference: follow macOS, or force light/dark for
/// Biscotti only.
public enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// The appearance to force, or `nil` to follow the system.
    public var appearanceName: NSAppearance.Name? {
        switch self {
        case .system: nil
        case .light: .aqua
        case .dark: .darkAqua
        }
    }
}

/// Persists the theme choice in `UserDefaults`. It is a device-local UI
/// preference, so it deliberately lives outside the SwiftData settings model.
public struct ThemeStore: @unchecked Sendable {
    private static let key = "appTheme"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The stored theme. Unknown or missing values read as `.system`.
    public var theme: AppTheme {
        get { defaults.string(forKey: Self.key).flatMap(AppTheme.init(rawValue:)) ?? .system }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.key) }
    }
}

/// Applies a theme app-wide. Setting `NSApp.appearance` reaches every window,
/// sheet, and the menu-bar extra, and the dynamic color tokens resolve from it.
@MainActor
public enum ThemeApplier {
    public static func apply(_ theme: AppTheme) {
        NSApp?.appearance = theme.appearanceName.flatMap(NSAppearance.init(named:))
    }
}
