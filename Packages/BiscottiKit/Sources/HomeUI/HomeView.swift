import AppCore
import Calendar
import DataStore
import DesignSystem
import Formatting
import SwiftUI

/// The Home screen: page title and stats line, a featured card for the next
/// meeting, compact rows for the rest, and recent meetings as tiles.
public struct HomeView: View {
    @Bindable private var viewModel: HomeViewModel

    public init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    titleBlock

                    HomeUpcomingSection(viewModel: viewModel)
                        .padding(.top, 18)

                    HomeRecentSection(viewModel: viewModel)
                        .padding(.top, Tokens.cardToGroupGap)

                    BrandFooter()
                        .padding(.top, 30)
                }
                .frame(maxWidth: Tokens.contentColumnMaxWidth, alignment: .leading)
                .padding(.vertical, Tokens.homeVerticalPadding)
                .padding(.horizontal, Tokens.homeHorizontalPadding)
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height)
            }
        }
        .background(Tokens.contentBackground.ignoresSafeArea())
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Home")
                .font(.pageTitle)
                .foregroundStyle(.ink)

            Text(viewModel.subtitleText)
                .font(.system(size: 13))
                .foregroundStyle(.inkSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

// MARK: - Upcoming section (featured card + compact rows)

private struct HomeUpcomingSection: View {
    let viewModel: HomeViewModel

    var body: some View {
        if viewModel.showConnectCalendar {
            connectCalendarCard
        } else if viewModel.showNoUpcoming {
            noUpcomingCard
        } else if let event = viewModel.featuredEvent {
            VStack(alignment: .leading, spacing: 10) {
                featuredCard(event: event)
                if !viewModel.secondaryUpcoming.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(
                            Array(viewModel.secondaryUpcoming.enumerated()),
                            id: \.element.id
                        ) { index, upcoming in
                            if index > 0 {
                                InsetDivider(leadingInset: 34)
                            }
                            compactRow(event: upcoming)
                        }
                    }
                    .homeCard()
                }
            }
        }
    }

    private var connectCalendarCard: some View {
        VStack(spacing: Tokens.spacingSM) {
            Text("Connect your calendar to see upcoming meetings")
                .font(Tokens.metaText)
                .foregroundStyle(.inkSecondary)

            Button("Allow Calendar Access") {
                Task { await viewModel.requestCalendarAccess() }
            }
            .buttonStyle(PillButtonStyle(.accent))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Tokens.spacingLG)
        .homeCard()
    }

    private var noUpcomingCard: some View {
        Text("No meetings coming up")
            .font(Tokens.metaText)
            .foregroundStyle(.inkSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Tokens.spacingLG)
            .homeCard()
    }

    // MARK: Featured card

    /// The whole card is a button that opens the event (keyboard-focusable,
    /// like the old hero row); its pill buttons take their own clicks.
    private func featuredCard(event: CalendarEvent) -> some View {
        Button {
            viewModel.selectEvent(event.id)
        } label: {
            FeaturedCard(
                colorHex: event.calendarColorHex,
                status: viewModel.featuredStatusText ?? "",
                title: event.title,
                detail: featuredDetail(event: event)
            ) {
                if viewModel.featuredInJoinWindow {
                    Button {
                        Task { await viewModel.joinAndRecord(event) }
                    } label: {
                        Label(
                            viewModel.heroIsRecordOnly ? "Record" : "Join and record",
                            systemImage: "record.circle"
                        )
                    }
                    .buttonStyle(PillButtonStyle(.primaryOnColor))
                    .disabled(viewModel.recordDisabled)
                }

                Button("View in calendar") {
                    viewModel.openInCalendar(event)
                }
                .buttonStyle(PillButtonStyle(.secondaryOnColor))
            }
            .contentShape(RoundedRectangle(cornerRadius: Tokens.cardRadius))
        }
        .buttonStyle(.plain)
    }

    /// "10:30 – 11:00 AM · Google Meet · Ana, Raj, +3"
    private func featuredDetail(event: CalendarEvent) -> String {
        let data = viewModel.avatarData(for: event)
        let names = data.people.prefix(3).map(\.displayName)
        let overflow = data.total - names.count
        var people = names.joined(separator: ", ")
        if overflow > 0, !people.isEmpty {
            people += ", +\(overflow)"
        }
        let time = "\(HomeSharedViews.formattedTime(event.start)) – \(HomeSharedViews.formattedTime(event.end))"
        return [time, event.conferencePlatform, people.isEmpty ? nil : people]
            .compactMap(\.self)
            .joined(separator: " · ")
    }

    // MARK: Compact row

    private func compactRow(event: CalendarEvent) -> some View {
        Button {
            viewModel.selectEvent(event.id)
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(TileColor.fill(hex: event.calendarColorHex))
                    .frame(width: 10, height: 10)

                Text(event.title)
                    .font(.tileTitle)
                    .foregroundStyle(.ink)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(viewModel.tickTimeText(for: event))
                    .font(.monoMeta)
                    .foregroundStyle(.inkSecondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.inkTertiary)
            }
            .padding(.vertical, Tokens.rowVerticalPadding)
            .padding(.horizontal, Tokens.rowHorizontalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent meetings section (tiles)

private struct HomeRecentSection: View {
    let viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recent meetings")
                    .font(.sectionTitle)
                    .foregroundStyle(.ink)

                Spacer(minLength: 8)

                if !viewModel.showNoRecent {
                    Button {
                        viewModel.showMeetings()
                    } label: {
                        Text("See all (\(viewModel.pastMeetingsCount))")
                            .font(.system(size: 13))
                            .foregroundStyle(.sage)
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.showNoRecent {
                Text("No recordings yet")
                    .font(Tokens.metaText)
                    .foregroundStyle(.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Tokens.spacingLG)
                    .homeCard()
            } else {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(viewModel.recentMeetings) { meeting in
                        MeetingTile(
                            title: meeting.title,
                            meta: TimeFormatting.meetingSecondLine(
                                date: meeting.date,
                                duration: meeting.recordingDuration
                            ),
                            colorHex: meeting.calendarColorHex,
                            systemImage: meeting.hasTranscript ? "waveform" : "mic"
                        ) {
                            viewModel.selectMeeting(meeting.id)
                        }
                    }
                    // Keep tiles a third of the row wide even with fewer meetings.
                    ForEach(0 ..< max(0, 3 - viewModel.recentMeetings.count), id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    }
                }
            }
        }
    }
}

// MARK: - Shared helpers

/// Shared view helpers used by the extracted section structs.
private enum HomeSharedViews {
    /// Formats an event start time as e.g. "9:00 AM".
    static func formattedTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

#if DEBUG
    #Preview("Home - Populated") {
        let core = try! PreviewAppCore.make() // swiftlint:disable:this force_try
        let viewModel = HomeViewModel(core: core)
        HomeView(viewModel: viewModel)
            .frame(width: 700, height: 600)
    }

    #Preview("Home - Empty") {
        let core = try! PreviewAppCore.make() // swiftlint:disable:this force_try
        let viewModel = HomeViewModel(core: core)
        HomeView(viewModel: viewModel)
            .frame(width: 700, height: 500)
    }
#endif
