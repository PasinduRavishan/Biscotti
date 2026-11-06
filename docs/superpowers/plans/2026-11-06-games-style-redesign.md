# Games-style Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Biscotti's "F Sage" look with an Apple Games-style UI (Design A) that follows the Mac's light/dark setting, with a System/Light/Dark theme control.

**Architecture:** Nearly all styling flows from the `DesignSystem` module (`Color+Theme.swift`, `Font+Theme.swift`, `Tokens.swift`, `Modifiers.swift`, shared components). First retarget those tokens' *values* so every screen changes at once. Then add the theme preference and the new tile/card components. Finally, rework the screens whose layout changes (Home, sidebar, Past Meetings rows) and sweep the rest for leftovers. Token *names* (`sage`, `paper`, `monoMeta`, …) are kept to limit churn, and a `// TODO` notes the rename.

**Tech Stack:** Swift 6, SwiftUI + AppKit, Swift Testing (`@Test`/`#expect`), SwiftPM package `Packages/BiscottiKit`, XcodeGen app target `App/`.

**Spec:** `docs/superpowers/specs/2026-11-06-games-style-redesign-design.md` (mockups: `…-mockups.html` alongside it)

## Global Constraints

- macOS 15+, Apple Silicon only. Bundle ID `net.scosman.biscotti` must not change.
- No feature/behavior/IA changes. No SwiftData schema change. User data is untouched.
- The app icon (`App/Resources/AppIcon.icon`) stays unchanged.
- SF Pro (system font) everywhere. No Newsreader and no JetBrains Mono. Monospaced *digits* only for timers and transport times.
- Sentence case for every label. No `.textCase(.uppercase)`, no tracked kickers.
- No gradients, no decorative shadows, no glow, no emoji.
- Accent = macOS system accent (`NSColor.controlAccentColor`). Red only for recording, destructive and error states.
- Tile and featured-card colors come from `calendarColorHex`, with neutral gray when it's missing. White text on them must reach a contrast ratio of ≥ 4.5:1.
- The featured card keeps the existing actions: "Join and record" (or "Record" when there's no conference link) and "View in calendar". No "Join only".
- Builds and tests run through the `hooks-mcp` MCP tools (`mcp__hooks-mcp__test`, `…__lint`, `…__format`, `…__build_app`), not Bash (see `CLAUDE.md`). Commit only after `mcp__hooks-mcp__precommit_checks` passes, using `git commit --no-verify`.
- `make build-app` and running the app need full Xcode installed and selected (`xcode-select -p` → `/Applications/Xcode.app/...`).

## Review Focus

1. **Theme switching while windows are open:** changing the theme must restyle the open main window, any open sheet and the menu-bar dropdown immediately, and survive a relaunch. Pinned by Task 1's tests (apply + persistence) and Task 9's manual check.
2. **Bad or very light calendar colors** (`#FFFF00`, `#FFF`, `"blue"`, `nil`) must still give a readable tile. Pinned by `TileColorTests` in Task 5.
3. **Long meeting titles** (80+ characters) in tiles and the featured card must truncate on one or two lines without pushing the layout wider. Pinned by previews with long titles in Tasks 5 and 6 and the Task 9 check.
4. **Empty states** (no calendar access, no upcoming events, no past meetings) must still render on the new Home. Pinned by the `featuredEvent == nil` / `secondaryUpcoming` tests in Task 6 plus the existing `showNoUpcoming`/`showConnectCalendar`/`showNoRecent` tests, which must stay green.
5. **A stored theme value from a corrupted or older build** (an unknown string in UserDefaults) must fall back to System, not crash. Pinned by `ThemeStoreTests.unknownValueFallsBackToSystem` in Task 1.

---

### Task 1: Theme preference and app-wide appearance

**Files:**
- Create: `Packages/BiscottiKit/Sources/DesignSystem/AppTheme.swift`
- Test: `Packages/BiscottiKit/Tests/DesignSystemTests/ThemeStoreTests.swift`
- Modify: `Packages/BiscottiKit/Sources/SettingsUI/SettingsViewModel.swift` (init at ~line 20 and ~178; add theme property and setter)
- Modify: `Packages/BiscottiKit/Sources/SettingsUI/SettingsView.swift:99-138` (`generalSection`) and add `themeBinding` next to `launchAtLoginBinding` (~line 505)
- Modify: `App/Sources/BiscottiApp.swift:~138-160` (apply the stored theme at launch; remove `.tint(.sage)`)
- Test: `Packages/BiscottiKit/Tests/SettingsUITests/SettingsThemeTests.swift`

**Interfaces:**
- Produces (DesignSystem):
  - `public enum AppTheme: String, CaseIterable, Identifiable, Sendable { case system, light, dark }`, with `public var id: String`, `public var displayName: String` ("System", "Light", "Dark"), and `public var appearanceName: NSAppearance.Name?` (`nil`, `.aqua`, `.darkAqua`).
  - `public struct ThemeStore: @unchecked Sendable { public init(defaults: UserDefaults = .standard); public var theme: AppTheme { get nonmutating set } }`, with the UserDefaults key `"appTheme"`.
  - `@MainActor public enum ThemeApplier { public static func apply(_ theme: AppTheme) }`, which sets `NSApp.appearance = theme.appearanceName.flatMap(NSAppearance.init(named:))`.
- Produces (SettingsUI): `SettingsViewModel.theme: AppTheme` (read) and `func setTheme(_ theme: AppTheme)`. The init gains `themeStore: ThemeStore = ThemeStore()` and `applyTheme: @escaping @MainActor (AppTheme) -> Void = ThemeApplier.apply` as trailing defaulted parameters, so existing `SettingsViewModel(core:)` call sites compile unchanged.

- [ ] **Step 1: Write failing tests** in `ThemeStoreTests.swift`. Each test uses `UserDefaults(suiteName: UUID().uuidString)!`.
  - `defaultIsSystem`: a fresh store gives `#expect(store.theme == .system)`.
  - `roundTrips`: set `.dark` → `#expect(ThemeStore(defaults: same).theme == .dark)`.
  - `unknownValueFallsBackToSystem`: `defaults.set("sepia", forKey: "appTheme")` → `#expect(store.theme == .system)`.
  - `appearanceNames`: `.system` → `nil`, `.light` → `.aqua`, `.dark` → `.darkAqua`.
- [ ] **Step 2: Run** `mcp__hooks-mcp__test`. Expected: FAIL, because `AppTheme`/`ThemeStore` aren't defined.
- [ ] **Step 3: Implement** `AppTheme.swift` per the Interfaces block.
- [ ] **Step 4: Write a failing test** in `SettingsThemeTests.swift`, `setThemeStoresAndApplies`: build the view model with a temp-suite `ThemeStore` and an `applyTheme` closure that records its argument. Call `setTheme(.light)`, then `#expect(viewModel.theme == .light)`, `#expect(recorded == [.light])` and `#expect(store.theme == .light)`. Reuse the fixture used by `SettingsAIEnhancementsTests` for `core`.
- [ ] **Step 5: Implement** the `SettingsViewModel` additions. In `SettingsView.generalSection`, add `Picker("Theme", selection: themeBinding) { ForEach(AppTheme.allCases) { Text($0.displayName).tag($0) } }.pickerStyle(.segmented)` as the **first** row.
- [ ] **Step 6:** In `BiscottiApp.swift`, call `ThemeApplier.apply(ThemeStore().theme)` in the main scene's `.onAppear` (next to the existing `FontRegistration.ensure()`, which Task 3 removes). Remove `.tint(.sage)` from `AppShellView(...)`.
- [ ] **Step 7: Run** `mcp__hooks-mcp__test`. Expected: PASS.
- [ ] **Step 8: Commit** — run `mcp__hooks-mcp__precommit_checks`, then `git commit --no-verify -m "Add System/Light/Dark theme setting"`.

### Task 2: Retarget color tokens to native, neutral, system-accent values

**Files:**
- Modify: `Packages/BiscottiKit/Sources/DesignSystem/Color+Theme.swift` (values only; keep every public name)
- Modify: `Packages/BiscottiKit/Sources/DesignSystem/Avatar.swift` (gradient → solid fill)
- Modify: `Packages/BiscottiKit/Sources/DesignSystem/HomeCardModifier.swift` (drop shadow; radius `Tokens.cardRadius`)
- Modify: `Packages/BiscottiKit/Sources/DesignSystem/Tokens.swift` (radii: `cardRadius = 14`; add `tileRadius: CGFloat = 10`; update the header comment from "F Sage identity")
- Modify: `App/Resources/Assets.xcassets/AccentColor.colorset/Contents.json` (remove the color entry so the system accent applies)
- Test: `Packages/BiscottiKit/Tests/DesignSystemTests/DynamicColorTests.swift` (update expectations)

**Interfaces:**
- Consumes: nothing.
- Produces: unchanged token names, with these resolved values (light / dark):

| Token | New value |
|---|---|
| `paper` (content bg) | `#FFFFFF` / `#1C1C1E` |
| `listPaneBackground` | `#F5F5F7` / `#1C1C1E` |
| `sidebarTint`, `wall` | `#F2F2F4` / `#2C2C2E` |
| `cardFill`, `elevatedFill` | `#F5F5F7` / `#2C2C2E` |
| `ink`, `read` | `NSColor.labelColor` |
| `inkSecondary` | `NSColor.secondaryLabelColor` |
| `inkTertiary` | `NSColor.tertiaryLabelColor` |
| `hairline`, `cardStroke` | `NSColor.separatorColor` |
| `neutralChip` | `labelColor` @ 6% (light) / white @ 10% (dark) |
| `sage`, `accentFill`, `accentTrack` | `NSColor.controlAccentColor` |
| `accentWashSoft` / `accentWashStrong` / `softSageFill` / `findHighlightFocused` | `controlAccentColor` @ 10% / 18% / 14% / 35% |
| `signalRed`, `signalRedText` | `NSColor.systemRed` |
| `warningOchre`, `warningChipText` | `NSColor.systemOrange` |
| `cardShadow`, `controlShadow` | `.clear` |

  System `NSColor`s are already dynamic: use them directly and don't wrap them in `dynamicNSColor`. Add `// TODO: rename sage/paper/ink tokens to accent/background/label` above the `Color` extension.

- [ ] **Step 1: Update `DynamicColorTests`** to the new expectations: `paper` light = (1,1,1), dark ≈ (0.110, 0.110, 0.118); `cardFill` dark ≈ (0.173, 0.173, 0.180); `sage` resolves equal to `NSColor.controlAccentColor` under both appearances; `cardShadow` alpha = 0. Delete assertions on the old ivory/sage hex values.
- [ ] **Step 2: Run** `mcp__hooks-mcp__test`. Expected: the updated assertions FAIL.
- [ ] **Step 3: Implement** the value table. In `Avatar.swift`, replace the `LinearGradient` fill with `.fill(baseColor)` and keep the hairline ring. In `HomeCardModifier`, remove `.shadow(...)`.
- [ ] **Step 4: Run** `mcp__hooks-mcp__test`. Expected: PASS. Fix any other test that asserted old color values (`AvatarTests`, `TagPaletteTests`) by updating expectations, not by weakening behavior checks.
- [ ] **Step 5: Commit** — precommit checks, then `git commit --no-verify -m "Retarget color tokens to native neutral palette and system accent"`.

### Task 3: System typography; remove bundled fonts and uppercase kickers

**Files:**
- Modify: `Packages/BiscottiKit/Sources/DesignSystem/Font+Theme.swift`
- Delete: `Packages/BiscottiKit/Sources/DesignSystem/FontRegistration.swift`, `Resources/Fonts/` (both JetBrains Mono TTFs, the Newsreader TTF and both license files), `Tests/DesignSystemTests/FontRegistrationTests.swift`
- Modify: `App/Sources/BiscottiApp.swift` (remove `FontRegistration.ensure()`)
- Modify: `Packages/BiscottiKit/Sources/DesignSystem/Modifiers.swift` (kicker)
- Modify: `Packages/BiscottiKit/Sources/DesignSystem/Tokens.swift` (typography section)
- Modify (sentence-case literals passed to `.kicker()`): `SettingsUI/VocabularyListSheet.swift:39`, `DesignSystem/CalendarInfoCard.swift:188,201,210,222`, `MeetingDetailUI/TagPickerPopover.swift:89`, `MeetingDetailUI/EventPreviewView.swift:235,249,259,269`, `SummaryPromptUI/SummaryPromptSheet.swift:79,166`, `OnboardingUI/ProgressHeader.swift:44`, `AppShellUI/AppShellView.swift:347,520`, `OnboardingUI/GrantedTag.swift:26`, `MeetingListUI/MeetingListView.swift:139`, `OnboardingUI/OnboardingStepViews.swift:286`. For the variables (`kickerText`, `label`, `group.title`, `group.sourceTitle`), fix the string where it's produced. Update any test asserting the old uppercase strings.

**Interfaces:**
- Produces: the same `Font` static names, redefined as:

| Name | New definition |
|---|---|
| `serifGreeting` | `.system(size: 26, weight: .bold)` (page title) |
| `serifHeadline` | `.system(size: 22, weight: .bold)` |
| `monoDate`, `monoMeta` | `.system(size: 13)` |
| `monoMetaMedium`, `monoStat` | `.system(size: 13, weight: .medium)` |
| `monoBadge` | `.system(size: 10, weight: .semibold)` |
| `monoKicker` | `.system(size: 12, weight: .semibold)` |
| `monoElapsed` | `.system(size: 34, weight: .medium).monospacedDigit()` |
| `monoCaption` | `.system(size: 11).monospacedDigit()` |

  Also add `public static let pageTitle = Font.system(size: 26, weight: .bold)`, `sectionTitle = .system(size: 17, weight: .bold)`, `featuredTitle = .system(size: 22, weight: .bold)` and `tileTitle = .system(size: 13, weight: .semibold)` to `Font`, and mirror them in `Tokens`. Delete `biscottiSerif`, `biscottiMono` and `MonoWeight`. Set `Tokens.greetingTracking` and `groupLabelTracking` to `0`, with a TODO to delete them once the call sites are gone.
  - The `kicker()` modifier becomes `.font(.monoKicker).foregroundStyle(.inkSecondary)`, with no `textCase` and no tracking.

- [ ] **Step 1: Remove** `FontRegistrationTests.swift`. Run `mcp__hooks-mcp__build`. Expected: compile errors listing every `biscottiSerif`/`biscottiMono`/`FontRegistration` user; that is the work list.
- [ ] **Step 2: Implement** the table, delete the font files and registration, and fix each compile error by switching to the semantic `Font` names above.
- [ ] **Step 3: Sentence-case** every kicker literal listed under Files (e.g. `"UPCOMING"` → `"Upcoming"`, `"ATTENDEES (\(n))"` → `"Attendees (\(n))"`, `"RECORDING NOW"` → `"Recording now"`).
- [ ] **Step 4: Verify** that `grep -rnE "textCase\(\.uppercase\)|JetBrains|Newsreader|biscottiMono|biscottiSerif|FontRegistration" Packages App --include='*.swift'` returns nothing.
- [ ] **Step 5: Run** `mcp__hooks-mcp__test`. Expected: PASS.
- [ ] **Step 6: Commit** — `git commit --no-verify -m "Use system typography; drop bundled fonts and uppercase kickers"`.

### Task 4: Calendar color on past-meeting summaries

**Files:**
- Modify: `Packages/BiscottiKit/Sources/DataStore/DataStore+ReadModels.swift:8-42` (`MeetingSummary`) and `~:469` (`meetingSummaries`)
- Test: `Packages/BiscottiKit/Tests/DataStoreTests/ReadModelTests.swift`

**Interfaces:**
- Produces: `MeetingSummary.calendarColorHex: String?`, a new init parameter `calendarColorHex: String? = nil` (last, defaulted). It is filled from `meeting.calendarSnapshot?.calendarColorHex`.

- [ ] **Step 1: Write failing tests** `summaryCarriesCalendarColor` and `summaryWithoutSnapshotHasNilColor`: create one meeting with a `CalendarSnapshot` whose `calendarColorHex = "#1F6FB2"` (follow the pattern in `VoiceprintTests.swift:429`) and one without. Expect `"#1F6FB2"` and `nil` from `meetingSummaries()`.
- [ ] **Step 2: Run** `mcp__hooks-mcp__test`. Expected: FAIL.
- [ ] **Step 3: Implement** the field and its projection.
- [ ] **Step 4: Run** `mcp__hooks-mcp__test`. Expected: PASS.
- [ ] **Step 5: Commit** — `git commit --no-verify -m "Expose calendar color on MeetingSummary"`.

### Task 5: Tile color helper, MeetingTile and FeaturedCard components

**Files:**
- Create: `Packages/BiscottiKit/Sources/DesignSystem/TileColor.swift`
- Create: `Packages/BiscottiKit/Sources/DesignSystem/MeetingTile.swift`
- Create: `Packages/BiscottiKit/Sources/DesignSystem/FeaturedCard.swift`
- Test: `Packages/BiscottiKit/Tests/DesignSystemTests/TileColorTests.swift`

**Interfaces:**
- Consumes: `Color(hex:)` (`CalendarContextBlock.swift:124`); `Tokens.tileRadius`, `Tokens.cardRadius` (Task 2); `Font.tileTitle`, `Font.featuredTitle` (Task 3).
- Produces:
  - `public enum TileColor { public static func resolve(hex: String?) -> NSColor; static func contrastAgainstWhite(_ c: NSColor) -> CGFloat }`. Parse `#RRGGBB`/`RRGGBB`. If `nil` or invalid, return `#6E6E73`. While the WCAG contrast against white is < 4.5, multiply RGB by 0.85 (at most 12 iterations).
  - `public struct MeetingTile: View { public init(title: String, meta: String, colorHex: String?, systemImage: String, action: @escaping () -> Void) }`: a 78pt-high color block (`Tokens.tileRadius`) with a white 26pt SF Symbol, then the title (`.tileTitle`, `lineLimit(1)`) and meta (`.monoMeta`, `.inkSecondary`). The whole tile is a plain-style button.
  - `public struct FeaturedCard<Actions: View>: View { public init(colorHex: String?, status: String, title: String, detail: String, @ViewBuilder actions: () -> Actions) }`: full width, `Tokens.cardRadius`, solid `TileColor.resolve` fill, 16–18pt padding. Status is 12pt semibold white @ 80%, title `.featuredTitle` white `lineLimit(2)`, detail 13pt white @ 85%.
  - `public struct PillButtonStyle: ButtonStyle { public enum Kind { case primaryOnColor, secondaryOnColor, accent }; public init(_ kind: Kind) }`: capsule, 13pt semibold, 7×14 padding. `primaryOnColor` = white fill with black text; `secondaryOnColor` = white @ 20% with white text; `accent` = `.sage` fill with white text.

- [ ] **Step 1: Write failing tests** in `TileColorTests.swift`:
  - `nilIsGray`: `resolve(hex: nil)` gives sRGB ≈ (0.431, 0.431, 0.451).
  - `invalidIsGray`: `resolve(hex: "blue")` gives the same gray.
  - `darkColorUnchanged`: `resolve(hex: "#1F6FB2")` keeps its components within 0.001.
  - `lightColorDarkenedToContrast`: for each of `"#FFFF00"`, `"#FFFFFF"`, `"#86C295"`, expect `contrastAgainstWhite(resolve(hex: h)) >= 4.5`.
- [ ] **Step 2: Run** `mcp__hooks-mcp__test`. Expected: FAIL.
- [ ] **Step 3: Implement** `TileColor`, then `MeetingTile`, `FeaturedCard` and `PillButtonStyle`. Add `#Preview`s with an 80-character title for each.
- [ ] **Step 4: Run** `mcp__hooks-mcp__test`. Expected: PASS.
- [ ] **Step 5: Commit** — `git commit --no-verify -m "Add tile color helper and Games-style tile/card components"`.

### Task 6: Home screen redesign

**Files:**
- Modify: `Packages/BiscottiKit/Sources/HomeUI/HomeViewModel.swift` (remove `greeting`; add the members below)
- Modify: `Packages/BiscottiKit/Sources/HomeUI/HomeView.swift` (whole layout)
- Test: `Packages/BiscottiKit/Tests/HomeUITests/HomeViewModelTests.swift` (delete the greeting suite at ~line 441; add the tests below)

**Interfaces:**
- Consumes: `FeaturedCard`, `MeetingTile`, `PillButtonStyle`, `TileColor` (Task 5); `MeetingSummary.calendarColorHex` (Task 4); the existing `dateText`, `meetingsLeftText`, `nextInText`, `heroEvent`, `heroIsRecordOnly`, `recordDisabled`, `upcomingPreview`, `recentMeetings`, `pastMeetingsCount`, `showNoUpcoming`, `showConnectCalendar`, `showNoRecent`.
- Produces on `HomeViewModel`:
  - `subtitleText: String`, which is `[dateText, meetingsLeftText, nextInText].compactMap { $0 }` joined with `" · "`.
  - `featuredEvent: CalendarEvent?`, which is `upcomingPreview.first`.
  - `featuredInJoinWindow: Bool`, which is `heroEvent != nil`.
  - `featuredStatusText: String?`. For the featured event, relative to `core.minuteTick`: in the join window and starting in the future → `"Starting in N min"` (N = minutes rounded up, minimum 1); in the window and already started → `"Happening now"`; same calendar day → `"Today at <h:mm a>"`; next day → `"Tomorrow at <h:mm a>"`; otherwise `"<EEEE> at <h:mm a>"`. It's `nil` when there is no featured event.
  - `secondaryUpcoming: [CalendarEvent]`, which is `Array(upcomingPreview.dropFirst())`.

- [ ] **Step 1: Write failing tests**, using the existing HomeViewModel fixture and clock injection from the current suites:
  - `subtitleJoinsAvailableParts`: with both chips present, expect `"\(dateText) · \(meetingsLeftText!) · \(nextInText!)"`; with no chips, expect just `dateText`.
  - `featuredIsFirstUpcoming`: with 3 events, `featuredEvent?.id == events[0].id` and `secondaryUpcoming.count == 2`.
  - `noUpcomingMeansNoFeatured`: no events gives `featuredEvent == nil`, `featuredStatusText == nil` and `secondaryUpcoming.isEmpty`.
  - `statusStartingSoon`: an event 6 min ahead gives `"Starting in 6 min"`.
  - `statusHappeningNow`: an event that started 2 min ago, still in the window, gives `"Happening now"`.
  - `statusTomorrow`: an event tomorrow at 10:30 gives `"Tomorrow at 10:30 AM"`. Use a fixed `en_US_POSIX` locale and time zone in the test, matching how `dateText` tests already do it.
- [ ] **Step 2: Run** `mcp__hooks-mcp__test`. Expected: FAIL.
- [ ] **Step 3: Implement** the view-model members.
- [ ] **Step 4: Rebuild `HomeView`** (max width `Tokens.contentColumnMaxWidth`, padding unchanged):
  1. `Text("Home").font(.pageTitle)`, then `Text(subtitleText)` in 13pt `.inkSecondary`.
  2. If `featuredEvent` is set, show a `FeaturedCard` (colorHex = the event's `calendarColorHex`, status = `featuredStatusText`, detail = "time range · platform · first attendees"). If `featuredInJoinWindow`, the actions are the **existing** hero join/record action labelled "Join and record", or "Record" when `heroIsRecordOnly`, styled `.primaryOnColor` and `.disabled(recordDisabled)`. "View in calendar" (the existing action) is always present, styled `.secondaryOnColor`.
  3. `secondaryUpcoming` appears as compact rows: a 10pt calendar-color rounded square, the title (`Tokens.rowTitle`) and the time (`.monoMeta`). Each row opens the event, as rows do today.
  4. Keep the existing empty and connect-calendar states, restyled.
  5. A "Recent meetings" header (`.sectionTitle`) with the existing "See all" + count in `.sage`, then an `HStack` of up to 3 `MeetingTile`s from `recentMeetings` (meta = "relative day · duration", using the existing formatters; `systemImage` = `"waveform"` if `hasTranscript`, else `"mic"`). Keep the existing `showNoRecent` state.
  6. Remove the greeting block and the `StatChip` row.
- [ ] **Step 5: Run** `mcp__hooks-mcp__test`. Expected: PASS.
- [ ] **Step 6: Commit** — `git commit --no-verify -m "Redesign Home: page title, featured card, recent meeting tiles"`.

### Task 7: Sidebar, brand mark, and Past Meetings rows

**Files:**
- Modify: `Packages/BiscottiKit/Sources/AppShellUI/AppShellView.swift` (section titles, recording row, selection styling)
- Modify: `Packages/BiscottiKit/Sources/DesignSystem/BrandMark.swift` (tint `.ink` instead of `.sage`)
- Modify: `Packages/BiscottiKit/Tests/DesignSystemTests/BrandMarkTests.swift` (expect `.ink`)
- Modify: `Packages/BiscottiKit/Sources/MeetingListUI/MeetingListView.swift` (row styling only; `List(selection:)` untouched)

**Interfaces:**
- Consumes: `MeetingSummary.calendarColorHex` (Task 4), `TileColor` (Task 5), the fonts from Task 3.

- [ ] **Step 1: Update `BrandMarkTests`** to expect the ink tint. Run it and confirm it FAILS.
- [ ] **Step 2: Implement** the brand-mark tint. In the sidebar, use standard `List` sidebar selection. Section headers ("Upcoming", "Recording now") are 11pt semibold `.inkSecondary`, and the content stays the same. Sidebar icons use the accent color.
- [ ] **Step 3: Past Meetings rows:** a leading 10pt rounded square in `Color(nsColor: TileColor.resolve(hex: calendarColorHex))`, the title in 13pt semibold and the meta in `.monoMeta` `.inkSecondary`. Keep the multi-select and bulk-delete behavior exactly as it is.
- [ ] **Step 4: Run** `mcp__hooks-mcp__test`. Expected: PASS.
- [ ] **Step 5: Commit** — `git commit --no-verify -m "Restyle sidebar, brand mark, and Past Meetings rows"`.

### Task 8: Sweep the remaining screens

**Files** (styling only; no layout or behavior changes unless noted):
- `MeetingDetailUI/MeetingDetailView.swift`: large bold title via `.pageTitle`; transcript and summary keep reading columns.
- `MeetingDetailUI/EventPreviewView.swift`, `DesignSystem/CalendarInfoCard.swift`, `DesignSystem/CalendarContextBlock.swift`
- `RecordingUI/RecordingView.swift`, `RecordingTimeChips.swift`, `AutoStopCountdownCard.swift`: flat card, no shadows; timer uses `.monoElapsed`.
- `OnboardingUI/OnboardingPrimaryButtonStyle.swift`: make it equivalent to `PillButtonStyle(.accent)`. Also `ModelDownloadCard.swift` and `PermissionRow.swift`.
- `DesignSystem/JoinRecordButtonStyle.swift`, `LightAlertButtonStyle.swift`, `TagPill.swift`, `AudioTransport.swift`: remove shadows and gradients.
- `ModelManagementUI/ManageModelsSheet.swift`, `SummaryPromptUI/*`, `MarkdownEditorUI/MarkdownPromptField.swift`, `SettingsUI/*`

- [ ] **Step 1: Verify** with `grep -rnE "LinearGradient|RadialGradient|AngularGradient|\.shadow\(" Packages/BiscottiKit/Sources --include='*.swift'`. Expected output: nothing, apart from any shadow that has a functional reason (none is known). Fix each hit.
- [ ] **Step 2:** Make the onboarding primary button use the accent pill. Keep every other screen's layout.
- [ ] **Step 3: Run** `mcp__hooks-mcp__test` and `mcp__hooks-mcp__lint`. Expected: PASS.
- [ ] **Step 4: Commit** — `git commit --no-verify -m "Sweep remaining screens for gradients, shadows, and old styling"`.

### Task 9: Build, install, and check visually in both themes

Requires full Xcode installed and selected.

- [ ] **Step 1: Run** `mcp__hooks-mcp__build_app`. Expected: build succeeds. Note the built `.app` path from the output (under `DerivedData/…/Build/Products/…/Biscotti.app`).
- [ ] **Step 2: Ask the owner before replacing the installed app.** Then quit the running Biscotti, move `/Applications/Biscotti.app` to the Trash (not a permanent delete), and copy the built app to `/Applications`.
- [ ] **Step 3: Manual check, on screen with the owner,** for each theme (System with the Mac in light, System with the Mac in dark, forced Light, forced Dark):
  - Home: featured card, rows, tiles and empty states. Long titles truncate.
  - Past Meetings: multi-select and delete still work.
  - Meeting Detail, Recording, Settings → Theme (switching restyles open windows immediately), onboarding, the menu-bar dropdown.
  - Relaunch: the theme persists.
  - No serif or monospace labels, uppercase kickers, cream backgrounds or sage anywhere except the Dock icon.
- [ ] **Step 4:** If macOS asks again for microphone, system audio or calendar permission (expected with a local build), grant it and confirm that recording works.

---

## Self-review notes

- Spec coverage: Goals 1–3 → Tasks 2–8, Task 2 + Task 1 (light/dark), Task 1. Visual rules → Tasks 2, 3 and 5. Per-screen notes → Tasks 6–8. Theme setting → Task 1. Data → Task 4. Constraints and owner decisions → Global Constraints. Icon unchanged → no task touches `AppIcon.icon`.
- Every Review Focus line is pinned by a named test or the Task 9 check.
