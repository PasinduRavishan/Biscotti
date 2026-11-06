# Games-style redesign — design

Date: 2026-11-06 · Branch: `redesign/games-style-ui` · Status: draft for approval

## Intent and why

This is a personal fork of Biscotti. Its owner finds the current UI looks
"AI-generated": warm ivory background, Newsreader serif greeting, JetBrains Mono
dates and stats, small uppercase tracked labels ("UPCOMING"), sage-green accent,
rounded white cards with whisper shadows, and gradient avatars. They want the
app to feel like Apple's own **Games app** on macOS instead: bold, native, and
confident, with big featured cards and rows of tiles.

The owner picked **Design A, "dark showcase"**, from three mockups:

- Bold large page title ("Home"), with a one-line subtitle: date · meetings this
  week · time recorded.
- A **featured card** for the next meeting: solid color fill, small "Starting in
  6 min" line, large bold title, time · platform · attendees, and two pill
  buttons, "Join and record" (primary, white) and "Join only" (secondary).
- A **"Recent meetings" row** of tiles: a solid color block with a white icon,
  then a bold title and a gray meta line ("Yesterday · 32 min"), plus a "See all"
  link in the accent color.
- A plain sidebar with standard Mac selection, accent-colored icons, and a
  "Today" list of upcoming meetings.

The mockups are saved next to this file as
`2026-11-06-games-style-redesign-mockups.html`. Design A is the target in dark
mode. Mockup B shows roughly how light surfaces should look. They are
low-fidelity: when they disagree with this document, the document wins.

## Goals

1. Replace the "F Sage" visual identity across **every screen** with the Games-style
   look above. The screens are Home, Past Meetings list, Meeting Detail, Event
   Preview, Recording, Settings, Onboarding, Manage Models, sheets and popovers,
   and the menu-bar dropdown.
2. **Follow the Mac's light/dark setting by default.** Dark mode looks like
   Design A. Light mode has the same layout with light surfaces (as in mockup B,
   but with A's large featured card).
3. Add a **Theme** control: a picker in Settings → General with **System**
   (default), **Light** and **Dark**. It applies immediately to every window,
   including the menu-bar dropdown, and is remembered across launches.

## Non-goals

- No feature, behavior or information-architecture changes. Buttons and
  actions stay on the same screens; only their styling changes.
- No change to the data model, database schema, or user data.
- No upstream contribution. This is a personal build, so upstream's spec docs
  under `specs/` are not updated.

## Anti-goals (a failure even if it works)

- Any surviving trace of the old identity: serif headings, monospace labels,
  UPPERCASE tracked kickers, cream/ivory backgrounds, sage green.
- Swapping one decorative style for another: no gradients (including on
  avatars), glows, glassy blur added for decoration, or emoji.
- Colors without meaning. Tile colors must come from data (see below), not a
  rainbow cycle.
- Breaking readability of long text. Transcripts and summaries must stay easy to
  read in both modes.

## Visual rules

**Type.** System font (SF Pro) everywhere. Remove the bundled Newsreader and
JetBrains Mono fonts, their registration, and their license files. Keep a
monospaced face only where digits must line up (recording timer, audio
transport times), using the system monospaced font or `.monospacedDigit()`.
Suggested ramp:

| Role | Font |
|---|---|
| Page title | ~26pt bold (`.largeTitle`/`.title` bold) |
| Section title ("Recent meetings") | ~17pt bold (`.title3` bold) |
| Featured card title | ~22pt bold |
| Tile / row title | 13pt semibold |
| Meta / secondary | 12–13pt regular, secondary color |
| Small status line ("Starting in 6 min") | 12pt semibold |

Section labels use sentence case ("Today", "Recent meetings"), never uppercase
with tracking.

**Color.**
- Surfaces use system semantic colors (window background, control background,
  separators, label colors). Dark mode is a neutral near-black (Design A used
  `#1C1C1E` content, `#2C2C2E` sidebar), not warm.
- Accent is the **system accent color** (`Color.accentColor`), so it follows
  the user's macOS accent setting. Default is blue.
- **Red is reserved for recording** (record button, recording indicators, stop),
  plus destructive actions and errors. Warning amber stays for warnings.
- **Tile and featured-card colors come from the event's calendar color.**
  Recordings without a calendar event use a neutral gray. The color must be
  dark enough for white text and icons in both modes. If a calendar color is
  too light, the builder darkens it to reach contrast.
- Avatars: solid color circles (no gradient), keeping the existing 16-color
  deterministic palette and its order.

**Shape and depth.** Large cards ~14pt radius, tiles ~10pt, buttons are pills.
Flat fills, with no decorative shadows. Hairline borders only where a surface
would otherwise disappear against its background.

## Per-screen notes

- **Home:** layout as in Design A. The greeting ("Good morning") is replaced
  by the bold "Home" title. The subtitle is today's date followed by the
  **existing** stat chips' text, e.g. "Thursday, 6 November · 2 meetings left
  today · Next in 5h". No new statistics: the mockup's "meetings this week" and
  "time recorded" were placeholders. *(Designer's call.)*
  - **Featured card:** a full-width card showing the first upcoming event
    (`displayedUpcoming.first`), whenever there is one. Inside the join window
    (today's `heroEvent` condition) it shows a status line ("Starting in 6 min")
    and today's hero actions, restyled as pills. Outside the window it shows the
    status as a relative time ("Tomorrow at 10:30") and only "View in
    calendar". *(Designer's call; the actions themselves were decided by the
    owner, see below.)*
  - **Other upcoming events:** events 2–3 (today's `prefix(3)`) stay on Home as
    compact rows under the featured card, with a calendar-color square, title
    and time. Nothing that is shown today disappears. *(Designer's call.)*
  - If there are no upcoming events, show the current empty-state or
    connect-calendar copy in the new style.
  - **Recent meetings:** the past-meetings section becomes a fixed (not
    scrolling) row of the same 3 meetings shown today (`summaries.prefix(3)`),
    as tiles, with the existing "See all" link and count. *(Designer's call.)*
- **Past Meetings list:** keep the native `List` with multi-select. Restyle the
  rows: a small calendar-colored square on the left, bold title, gray meta.
  Don't convert it to a tile grid (selection and bulk delete must keep working).
- **Meeting Detail:** same fonts, colors and buttons. Transcript and summary stay
  as readable text columns, not tiles. The header may use a large bold title.
- **Recording view:** large timer in monospaced digits, red record/stop pill,
  calendar-colored context. The auto-stop countdown card is restyled as a flat
  card.
- **Settings:** standard grouped `Form`. Add the Theme picker to General.
  Remove the custom serif/mono styling.
- **Onboarding:** bold system-font headline in place of the serif headline. The
  primary button becomes an accent-filled pill. Permission and model rows use
  the new flat style.
- **Sidebar:** the "UPCOMING" section keeps its current content (next 6 events
  from the 7-day lookahead) and is retitled "Upcoming" in sentence case. The
  mockup's "Today" label was wrong. *(Designer's call.)* The "RECORDING NOW"
  kicker becomes "Recording now" in the same way.
- **Brand mark** in the sidebar: monochrome, using the primary label color
  instead of sage. *(Designer's call.)*
- **Menu bar dropdown, sheets and popovers:** pick up the new tokens. No layout
  changes. The dropdown is a native menu, so it needs almost no custom work.

## Theme setting

- Values: `system`, `light`, `dark`. Default: `system`.
- Stored in `UserDefaults`, **not** in the SwiftData `AppSettingsData`. It's a
  device-local UI preference, and this avoids a schema migration.
- Applied app-wide by setting `NSApp.appearance` (`nil` / `.aqua` /
  `.darkAqua`) at launch and whenever it changes. This reaches every window and
  the `MenuBarExtra`, and the existing `DynamicColor` light/dark tokens resolve
  correctly from it.
- UI: a `Picker` labelled "Theme" in Settings → General, segmented or menu
  style.

## Data needed

Upcoming events already carry `calendarColorHex`. The past-meeting read model
`MeetingSummary` (in `DataStore+ReadModels.swift`) does not. Add an optional
`calendarColorHex` to `MeetingSummary`, filled from the meeting's existing
stored calendar context. This is a read-model projection only, with no schema
change.

## Constraints

- macOS 15+, Apple Silicon, SwiftUI. The bundle ID `net.scosman.biscotti` must
  not change.
- Styling lives in the `DesignSystem` module (`Tokens.swift`,
  `Color+Theme.swift`, `Font+Theme.swift`, shared components). Change it there
  first, so screens pick it up, then fix screen-specific styling.
- `App/Resources/Assets.xcassets/AccentColor.colorset` is currently sage
  (#4E7D5C). Remove its color, or make it system blue, so the system accent
  applies. *(Designer's call.)*
- `make test` and `make lint` must pass. Tests that assert the old look may be
  updated or deleted, for example `BrandMarkTests` (sage), `FontRegistrationTests`
  (fonts being removed) and the `HomeViewModelTests` greeting suite. Tests that
  cover behavior must not be weakened. *(Designer's call.)*
  Builds and tests run through the `hooks-mcp` tools, not Bash (see
  `CLAUDE.md`).
- The installed app is replaced by a local build. It will be ad-hoc or
  personally signed, so macOS may ask for permissions again.

## Decisions made by the owner after review

1. ~~Featured-card buttons~~ **Decided by owner:** keep the current actions,
   restyled as pills: "Join and record" (or "Record" when there's no conference
   link) as the primary white pill, and "View in calendar" as the secondary pill.
   No "Join only" action is added.
2. ~~App icon~~ **Decided by owner:** keep `App/Resources/AppIcon.icon`
   unchanged. It is the one allowed exception to the "no trace of sage"
   anti-goal.

## Calls made by the designer (not decided by the owner)

- Tile colors come from the calendar color, with gray when there is no event.
- Fonts: SF Pro only; system monospaced digits only for timers.
- Accent follows the macOS system accent color.
- The theme is stored in UserDefaults and applied via `NSApp.appearance`.
- Past Meetings stays a native list, not a grid.
- Transcript and summary text stay as reading columns.

## Left to the builder

Exact token values and the dark/light hex pairs (within the rules above),
spacing details, which existing tokens to rename or delete, how to darken
low-contrast calendar colors, and SF Symbol choices for tile icons (suggested:
by conference platform, e.g. video for Meet/Zoom/Teams, person.2 for in-person,
phone for calls).
