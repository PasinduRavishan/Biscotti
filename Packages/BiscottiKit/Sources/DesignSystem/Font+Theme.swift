import SwiftUI

// MARK: - Semantic type ramp (system font only)

// Every face is SF Pro. Monospaced digits appear only where numbers must line
// up (timers, transport times, countdowns).
//
// TODO: rename the legacy `serif*` / `mono*` names to role names
// (e.g. `onboardingTitle`, `metaText`); they no longer describe the faces.

public extension Font {
    /// Page title ("Home", "Settings"): 26pt bold.
    static let pageTitle: Font = .system(size: 26, weight: .bold)

    /// Section title ("Recent meetings"): 17pt bold.
    static let sectionTitle: Font = .system(size: 17, weight: .bold)

    /// Featured card title: 22pt bold.
    static let featuredTitle: Font = .system(size: 22, weight: .bold)

    /// Tile / row title: 13pt semibold.
    static let tileTitle: Font = .system(size: 13, weight: .semibold)

    /// Legacy greeting slot, now the page title.
    static let serifGreeting: Font = pageTitle

    /// Onboarding headline / large empty-state headline: 22pt bold.
    static let serifHeadline: Font = .system(size: 22, weight: .bold)

    /// Date line: 13pt regular.
    static let monoDate: Font = .system(size: 13)

    /// Times, past meta, sidebar meeting time: 13pt regular, aligned digits.
    static let monoMeta: Font = .system(size: 13).monospacedDigit()

    /// Countdown ("in 6m"): 13pt medium, aligned digits.
    static let monoMetaMedium: Font = .system(size: 13, weight: .medium).monospacedDigit()

    /// Stat value: 13pt medium, aligned digits.
    static let monoStat: Font = .system(size: 13, weight: .medium).monospacedDigit()

    /// "+N" overflow badge: 10pt semibold.
    static let monoBadge: Font = .system(size: 10, weight: .semibold)

    /// Section labels ("Upcoming"): 12pt semibold, sentence case.
    static let monoKicker: Font = .system(size: 12, weight: .semibold)

    /// Recording elapsed counter: 34pt medium, aligned digits.
    static let monoElapsed: Font = .system(size: 34, weight: .medium).monospacedDigit()

    /// Audio transport times: 11pt, aligned digits.
    static let monoCaption: Font = .system(size: 11).monospacedDigit()
}
