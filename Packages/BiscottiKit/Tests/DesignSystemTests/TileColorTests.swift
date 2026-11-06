import AppKit
import Testing
@testable import DesignSystem

@Suite("TileColor")
struct TileColorTests {
    private func components(_ color: NSColor) throws -> [CGFloat] {
        let srgb = try #require(color.usingColorSpace(.sRGB))
        return [srgb.redComponent, srgb.greenComponent, srgb.blueComponent]
    }

    private func expectGray(_ color: NSColor) throws {
        let rgb = try components(color)
        #expect(abs(rgb[0] - 110 / 255) < 0.002)
        #expect(abs(rgb[1] - 110 / 255) < 0.002)
        #expect(abs(rgb[2] - 115 / 255) < 0.002)
    }

    @Test("a missing color is neutral gray")
    func nilIsGray() throws {
        try expectGray(TileColor.resolve(hex: nil))
    }

    @Test("an unparseable color is neutral gray", arguments: ["blue", "#FFF", "", "#12345G"])
    func invalidIsGray(hex: String) throws {
        try expectGray(TileColor.resolve(hex: hex))
    }

    @Test("a dark enough color is left unchanged")
    func darkColorUnchanged() throws {
        let rgb = try components(TileColor.resolve(hex: "#1F6FB2"))
        #expect(abs(rgb[0] - 0x1F / 255) < 0.001)
        #expect(abs(rgb[1] - 0x6F / 255) < 0.001)
        #expect(abs(rgb[2] - 0xB2 / 255) < 0.001)
    }

    @Test("a light color is darkened until white text reaches 4.5:1", arguments: ["#FFFF00", "#FFFFFF", "#86C295", "FFD60A"])
    func lightColorDarkenedToContrast(hex: String) {
        #expect(TileColor.contrastAgainstWhite(TileColor.resolve(hex: hex)) >= 4.5)
    }
}
