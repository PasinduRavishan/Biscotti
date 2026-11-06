import DesignSystem
import Foundation

/// Observable holder for the appearance preference. Kept out of
/// `SettingsViewModel`'s body so the class stays within the type-length limit.
@MainActor @Observable
final class ThemeSettings {
    private(set) var theme: AppTheme
    private let store: ThemeStore
    private let apply: @MainActor (AppTheme) -> Void

    init(store: ThemeStore, apply: @escaping @MainActor (AppTheme) -> Void) {
        self.store = store
        self.apply = apply
        theme = store.theme
    }

    func set(_ newTheme: AppTheme) {
        theme = newTheme
        store.theme = newTheme
        apply(newTheme)
    }
}

public extension SettingsViewModel {
    /// Appearance preference: System (default), Light, or Dark.
    var theme: AppTheme {
        themeSettings.theme
    }

    /// Persists the theme choice and applies it to every window immediately.
    func setTheme(_ newTheme: AppTheme) {
        themeSettings.set(newTheme)
    }
}
