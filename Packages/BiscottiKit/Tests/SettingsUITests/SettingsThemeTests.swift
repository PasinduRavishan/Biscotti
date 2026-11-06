import BiscottiTestSupport
import DesignSystem
import Foundation
import Testing
@testable import SettingsUI

@Suite("SettingsViewModel -- Theme")
@MainActor
struct SettingsThemeTests {
    @Test("setTheme stores the choice and applies it")
    func setThemeStoresAndApplies() throws {
        let fixture = try makeCoreFixture()
        defer { fixture.cleanup() }
        let defaults = try #require(UserDefaults(suiteName: "SettingsThemeTests-\(UUID().uuidString)"))
        let store = ThemeStore(defaults: defaults)
        var recorded: [AppTheme] = []

        let viewModel = SettingsViewModel(
            core: fixture.core,
            themeStore: store,
            applyTheme: { recorded.append($0) }
        )
        #expect(viewModel.theme == .system)

        viewModel.setTheme(.light)

        #expect(viewModel.theme == .light)
        #expect(recorded == [.light])
        #expect(store.theme == .light)
    }
}
