import SwiftUI

/// A Games-style meeting tile: a solid calendar-colored block with a white
/// symbol, then a bold one-line title and a secondary meta line.
public struct MeetingTile: View {
    private let title: String
    private let meta: String
    private let colorHex: String?
    private let systemImage: String
    private let action: () -> Void

    public init(
        title: String,
        meta: String,
        colorHex: String?,
        systemImage: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.meta = meta
        self.colorHex = colorHex
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: Tokens.tileRadius)
                    .fill(TileColor.fill(hex: colorHex))
                    .frame(height: 78)
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(.white)
                    }
                Text(title)
                    .font(.tileTitle)
                    .foregroundStyle(.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, 7)
                Text(meta)
                    .font(.monoMeta)
                    .foregroundStyle(.inkSecondary)
                    .lineLimit(1)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Meeting tiles") {
    HStack(spacing: 10) {
        MeetingTile(title: "Weekly 1:1 with Sam", meta: "Yesterday · 32 min", colorHex: "#D9622B", systemImage: "waveform") {}
        MeetingTile(
            title: "Quarterly planning review with the whole product and design org, part two",
            meta: "Tue · 58 min",
            colorHex: "#FFFF00",
            systemImage: "waveform"
        ) {}
        MeetingTile(title: "Hallway chat", meta: "Mon · 9 min", colorHex: nil, systemImage: "mic") {}
    }
    .padding(20)
    .frame(width: 520)
    .background(Tokens.contentBackground)
}
