import AppCore
import Calendar
import DataStore
import DesignSystem
import Formatting
import Foundation

/// View model for the Home screen.
///
/// Provides the welcome/start/upcoming/recent state and actions.
/// All data is derived from `AppCore` observable properties; no
/// direct DataStore queries.
@MainActor @Observable
public final class HomeViewModel {
    private let core: AppCore
    private let urlOpener: (URL) -> Void

    public init(
        core: AppCore,
        urlOpener: @escaping (URL) -> Void = { _ in }
    ) {
        self.core = core
        self.urlOpener = urlOpener
    }

    // MARK: - Date & subtitle

    /// Today's date formatted as "Wednesday, June 12".
    public var dateText: String {
        Self.dateFormatter.string(from: core.minuteTick)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    // MARK: - Stat chips

    /// Today's remaining meeting-like events from the upcoming set.
    private var todaysMeetings: [CalendarEvent] {
        let tick = core.minuteTick
        return core.displayedUpcoming.filter { event in
            event.isMeetingLike
                && Foundation.Calendar.current.isDate(
                    event.start, inSameDayAs: tick
                )
        }
    }

    /// "{n} meetings left today" or nil when no calendar access.
    public var meetingsLeftText: String? {
        guard calendarAccess == .authorized else { return nil }
        let count = todaysMeetings.count
        return "\(count) meeting\(count == 1 ? "" : "s") left today"
    }

    /// Coarse relative-time text for the soonest upcoming event, or nil.
    /// Returns just the relative portion (e.g. "in 5h", "in 2 days");
    /// the View composes the "Next " prefix for the stat chip.
    public var nextInText: String? {
        guard let first = core.displayedUpcoming.first else { return nil }
        return TimeFormatting.coarseRelativeTimeText(
            first.start, relativeTo: core.minuteTick
        )
    }

    /// Whether to show the stat chip row (only when calendar is authorized).
    public var showStatChips: Bool {
        calendarAccess == .authorized
    }

    /// The line under the page title: date, then whichever stats exist,
    /// e.g. "Thursday, November 6 · 2 meetings left today · Next in 5h".
    public var subtitleText: String {
        [dateText, meetingsLeftText, nextInText.map { "Next \($0)" }]
            .compactMap(\.self)
            .joined(separator: " · ")
    }

    // MARK: - Featured meeting

    /// The meeting shown in the large featured card: the first upcoming one.
    public var featuredEvent: CalendarEvent? {
        upcomingPreview.first
    }

    /// Whether the featured meeting is close enough to show join/record actions.
    public var featuredInJoinWindow: Bool {
        heroEvent != nil
    }

    /// Status line for the featured card ("Starting in 6 min", "Tomorrow at 10:30 AM").
    public var featuredStatusText: String? {
        featuredEvent.map { Self.featuredStatus(for: $0, relativeTo: core.minuteTick) }
    }

    /// Upcoming meetings after the featured one, shown as compact rows.
    public var secondaryUpcoming: [CalendarEvent] {
        Array(upcomingPreview.dropFirst())
    }

    /// Status text for a featured event relative to `now`. Inside the join
    /// window it counts down (or says it's happening); otherwise it names the
    /// day and time.
    public nonisolated static func featuredStatus(
        for event: CalendarEvent,
        relativeTo now: Date,
        calendar: Foundation.Calendar = .current,
        locale: Locale = .current
    ) -> String {
        let delta = event.start.timeIntervalSince(now)
        if delta <= 0, now < event.end || -delta <= MeetingTiming.joinWindowSeconds {
            return "Happening now"
        }
        if delta > 0, delta <= MeetingTiming.joinWindowSeconds {
            return "Starting in \(max(1, Int((delta / 60).rounded(.up)))) min"
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateFormat = "h:mm a"
        let time = formatter.string(from: event.start)
        if calendar.isDate(event.start, inSameDayAs: now) {
            return "Today at \(time)"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(event.start, inSameDayAs: tomorrow)
        {
            return "Tomorrow at \(time)"
        }
        formatter.dateFormat = "EEEE"
        return "\(formatter.string(from: event.start)) at \(time)"
    }

    // MARK: - Hero detection

    /// The first upcoming event if it falls within the join window.
    public var heroEvent: CalendarEvent? {
        guard let first = upcomingPreview.first else { return nil }
        let delta = abs(
            first.start.timeIntervalSince(core.minuteTick)
        )
        return delta <= MeetingTiming.joinWindowSeconds ? first : nil
    }

    /// Whether the hero event has no conference URL (record-only mode).
    public var heroIsRecordOnly: Bool {
        heroEvent?.conferenceURL == nil
    }

    /// Whether recording is currently in progress (disables Join & Record).
    public var recordDisabled: Bool {
        core.recording.state.isRecording
    }

    // MARK: - State (derived from core)

    /// The upcoming meeting-like events to show as a preview list (max 3).
    /// Uses `displayedUpcoming` which filters out ended events.
    public var upcomingPreview: [CalendarEvent] {
        Array(core.displayedUpcoming.prefix(3))
    }

    /// The most recent meetings (max 3, newest-first).
    public var recentMeetings: [MeetingSummary] {
        Array(core.summaries.prefix(3))
    }

    /// Calendar access state for empty/connect display.
    public var calendarAccess: CalendarAuthStatus {
        core.calendar.auth
    }

    /// Show "No meetings coming up" when authorized but no upcoming events
    /// (including events that have since ended).
    public var showNoUpcoming: Bool {
        calendarAccess == .authorized && upcomingPreview.isEmpty
    }

    /// Show "Connect your calendar" when not authorized.
    public var showConnectCalendar: Bool {
        calendarAccess != .authorized
    }

    /// Show the "No recordings yet" empty state when there are no meetings.
    public var showNoRecent: Bool {
        core.summaries.isEmpty
    }

    /// Total number of past meetings (for the "See All" row count badge).
    public var pastMeetingsCount: Int {
        core.summaries.count
    }

    // MARK: - Actions

    /// Request calendar access (from the "Connect" empty state).
    public func requestCalendarAccess() async {
        _ = await core.calendar.requestAccess()
    }

    /// Select an upcoming event to preview its detail.
    public func selectEvent(_ key: String) {
        core.selectEvent(key)
    }

    /// Select a recent meeting to view its detail.
    public func selectMeeting(_ id: UUID) {
        core.select(id)
    }

    /// Navigate to the Meetings screen (browse mode) -- the "See all" action.
    public func showMeetings() {
        core.showMeetings()
    }

    /// Open the conference URL (if present) and start recording for this event.
    public func joinAndRecord(_ event: CalendarEvent) async {
        if let url = event.conferenceURL {
            urlOpener(url)
        }
        await core.startRecording(eventKey: event.id)
    }

    /// Open Calendar.app to the event via the shared deep-link helper.
    public func openInCalendar(_ event: CalendarEvent) {
        // Extract the EKEvent identifier from the composite key (first |-component).
        let eventID = event.id.components(separatedBy: "|").first
        if let url = CalendarDeepLink.calendarAppURL(
            eventIdentifier: eventID,
            startDate: event.start
        ) {
            urlOpener(url)
        }
    }

    // MARK: - Avatar & names mapping

    /// Maps a CalendarEvent's attendees to avatar display data.
    public func avatarData(
        for event: CalendarEvent
    ) -> (people: [AvatarPerson], total: Int) {
        var people: [AvatarPerson] = []
        var seen: Set<String> = []

        // Organizer first
        if let org = event.organizer {
            let key = dedupeKey(name: org.displayName, email: org.email)
            if seen.insert(key).inserted {
                people.append(
                    AvatarPerson(
                        displayName: org.displayName,
                        email: org.email
                    )
                )
            }
        }

        // Then attendees
        for attendee in event.attendees {
            let key = dedupeKey(
                name: attendee.displayName, email: attendee.email
            )
            if seen.insert(key).inserted {
                people.append(
                    AvatarPerson(
                        displayName: attendee.displayName,
                        email: attendee.email
                    )
                )
            }
        }

        let total = max(people.count, event.attendeeCount)
        return (people: people, total: total)
    }

    /// Maps a MeetingSummary's participants to avatar display data.
    public func avatarData(
        for meeting: MeetingSummary
    ) -> (people: [AvatarPerson], total: Int) {
        let people = meeting.participants.map {
            AvatarPerson(displayName: $0.name, email: $0.email)
        }
        return (people: people, total: meeting.participantCount)
    }

    /// Builds the second-line text for a past meeting row.
    /// Appends participant names to the standard date+duration line.
    public func pastSecondLine(for meeting: MeetingSummary) -> String {
        let base = TimeFormatting.meetingSecondLine(
            date: meeting.date,
            duration: meeting.recordingDuration
        )
        let names = meeting.participants.prefix(3)
            .map(\.name)
            .joined(separator: ", ")
        if names.isEmpty { return base }
        return "\(base) \u{00B7} \(names)"
    }

    // MARK: - Formatting

    /// Formats a CalendarEvent's start time as coarse relative text
    /// ("in 2 days", "in 5h", "in 12m") or "now".
    /// Delegates to `TimeFormatting.coarseRelativeTimeText` (shared helper).
    public nonisolated static func timeText(
        for event: CalendarEvent,
        relativeTo now: Date = Date()
    ) -> String {
        TimeFormatting.coarseRelativeTimeText(event.start, relativeTo: now)
    }

    /// Formats a CalendarEvent's start time relative to the
    /// minute-tick, ensuring the label refreshes every minute.
    public func tickTimeText(for event: CalendarEvent) -> String {
        TimeFormatting.coarseRelativeTimeText(
            event.start, relativeTo: core.minuteTick
        )
    }

    // MARK: - Private

    private func dedupeKey(name: String, email: String?) -> String {
        if let email, !email.isEmpty {
            return email.lowercased()
        }
        return name.lowercased()
    }
}
