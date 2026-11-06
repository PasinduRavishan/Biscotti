import AppKit
import Foundation
import Testing
@testable import DesignSystem

@Suite("ThemeStore")
struct ThemeStoreTests {
    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "ThemeStoreTests-\(UUID().uuidString)"))
    }

    @Test("a fresh store defaults to System")
    func defaultIsSystem() throws {
        let store = try ThemeStore(defaults: makeDefaults())
        #expect(store.theme == .system)
    }

    @Test("a stored theme survives a new store instance")
    func roundTrips() throws {
        let defaults = try makeDefaults()
        ThemeStore(defaults: defaults).theme = .dark
        #expect(ThemeStore(defaults: defaults).theme == .dark)
    }

    @Test("an unknown stored value falls back to System")
    func unknownValueFallsBackToSystem() throws {
        let defaults = try makeDefaults()
        defaults.set("sepia", forKey: "appTheme")
        #expect(ThemeStore(defaults: defaults).theme == .system)
    }

    @Test("each theme maps to the expected appearance")
    func appearanceNames() {
        #expect(AppTheme.system.appearanceName == nil)
        #expect(AppTheme.light.appearanceName == .aqua)
        #expect(AppTheme.dark.appearanceName == .darkAqua)
    }
}
