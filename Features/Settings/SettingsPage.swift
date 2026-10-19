import SwiftUI
import TesseraCore

/// Settings, on its own page at last (batch 0): the look, his rest day, Claude, and Review, the switches he flips
/// live to pick between two ways of doing something. Said in sentences like Backups, never a list of toggles: no
/// cards, no pills, hairlines and margin labels only (Design sheets 80, 93, 100).
struct SettingsPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isPresented {
                    Button { dismiss() } label: {
                        Text("‹ Review")
                            .textRole(.label)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityLabel("Back to Review")
                }
                Text("how Tessera runs")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .entrance(0)
                Text("Settings")
                    .textRole(.hero)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1, hero: true)

                // "Porcelain by day, Obsidian by night", each name a value word.
                LookSentence()
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(2)

                // His rest day (RG4).
                RestDaySentence()
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(3)

                // What Tess keeps about him, in ink, the count the door to the page (AI-9).
                TessKnowsDoor()
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(4)

                // The key, the month and what Tess may send.
                ClaudeSection()
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(4)

                ReviewSection()
                    .padding(.top, Theme.Spacing.section)
                    .entrance(5)

                NavigationLink {
                    BackupView()
                } label: {
                    Text("Backups")
                }
                .buttonStyle(.labelWord)
                .padding(.top, Theme.Spacing.xxl)
                .accessibilityHint("Where your history is kept")
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .navigationBarBackButtonHidden()
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

// MARK: - What Tess knows

/// "Tess remembers 12 things.", the count a value word that opens What Tess knows.
private struct TessKnowsDoor: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        let count = TessMemoryStore(engine: model.engine).countWord()
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Memory")
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .accessibilityAddTraits(.isHeader)
            // Only the count is the value word: "Tess remembers 12 things." (Design on #1127).
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(TessKnowsCopy.doorLead(count))
                NavigationLink {
                    TessKnowsPage()
                } label: {
                    Text(TessKnowsCopy.doorCount(count)).fontWeight(.semibold)
                }
                .buttonStyle(.valueWash)
                Text(".")
            }
            .textRole(.body)
            .foregroundStyle(Theme.Colors.ink)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(TessKnowsCopy.door(count))
            .accessibilityHint("Opens what Tess knows")
            .accessibilityAddTraits(.isButton)
        }
    }
}

// MARK: - Review

/// The review switches, six to a page; the side swipe flips between pages (Design sheet 100). Each row is a sentence,
/// "Rest timer: On.", whose value word cycles on a tap. The row he touched says what changed in one line, before and
/// after. A switch whose feature hasn't landed shows today's value, quietly, and doesn't move.
struct ReviewSection: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    /// The switch he touched last and its value before the touch.
    @State private var touched: (id: String, before: String)?
    @State private var resetLine: String?
    @State private var flips = 0

    private let pages = ReviewChoices.facetPages()

    var body: some View {
        let choices = ReviewChoices.shared
        MarginSection(label: "Review") {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text("Try a new way; today's stays one tap away.")
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Named pages with their neighbours peeking (Design sheet 108): Looks and day, Workout, Kitchen,
                // Connected, Shown.
                PeekTabs(tabs: pages.map(\.word), selection: $page) { index in
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(pages[index].rows.enumerated()), id: \.element.id) { offset, choice in
                            row(choice)
                            if offset < pages[index].rows.count - 1 {
                                RowSeparator()
                            }
                        }
                    }
                }

                if choices.anyTrying() || resetLine != nil {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        if choices.anyTrying() {
                            Button(ReviewSwitchCopy.everythingAsBefore) {
                                withTesseraAnimation(reduceMotion: reduceMotion) {
                                    choices.resetAll()
                                    touched = nil
                                    resetLine = ReviewSwitchCopy.reset
                                }
                                AccessibilityNotification.Announcement(ReviewSwitchCopy.reset).post()
                            }
                            .buttonStyle(.labelWord)
                            .frame(minHeight: 44)
                        }
                        if let resetLine {
                            Text(resetLine)
                                .textRole(.body)
                                .foregroundStyle(Theme.Colors.tess)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .tesseraAnimation(value: choices.anyTrying())
        }
        .tesseraFeedback(.selection, trigger: flips)
    }

    private func row(_ choice: ReviewChoices.Choice) -> some View {
        let choices = ReviewChoices.shared
        let value = choices.value(of: choice)
        let live = choice.readiness == .live
        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(choice.name): ")
                    .foregroundStyle(live ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                Button { flip(choice, forward: true) } label: {
                    Text(value)
                        .fontWeight(.semibold)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.valueWash)
                .contentTransition(.opacity)
                .disabled(!live)
                Text(".")
                Spacer(minLength: Theme.Spacing.s)
                if let mark = ReviewSwitchCopy.mark(choice) {
                    Text(mark)
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
            }
            .textRole(.body)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(choice.name)
            .accessibilityValue(value)
            .accessibilityHint(ReviewSwitchCopy.hint(choice, value: value))
            .accessibilityAddTraits(live ? .isButton : [])
            .accessibilityAdjustableAction { direction in
                flip(choice, forward: direction != .decrement)
            }
            // A double tap flips it too, as a tap on the value word does (Design on #1127).
            .accessibilityAction { flip(choice, forward: true) }
            if let touched, touched.id == choice.id {
                Text(choices.beforeAfter(choice, before: touched.before))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.tess)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .frame(minHeight: 44, alignment: .leading)
        .padding(.vertical, Theme.Spacing.s)
    }

    private func flip(_ choice: ReviewChoices.Choice, forward: Bool) {
        guard choice.readiness == .live else { return }
        let choices = ReviewChoices.shared
        let before = touched?.id == choice.id ? touched?.before : choices.value(of: choice)
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
            choices.step(choice, forward: forward)
            touched = (choice.id, before ?? choice.defaultValue)
            resetLine = nil
        }
        flips += 1
        let line = choices.beforeAfter(choice, before: before ?? choice.defaultValue)
        AccessibilityNotification.Announcement(line).post()
    }
}

/// Review's words.
enum ReviewSwitchCopy {
    static let everythingAsBefore = "Everything as before"
    static let reset = "Everything is as before."
    static let needsClaude = "Needs Claude"
    static let later = "Later"

    /// "2 of 3".
    static func pageOf(_ page: Int, _ count: Int) -> String {
        "\(page) of \(count)"
    }

    /// "Workout, 2 of 5": the page's facet beside the counter (Design sheet 100).
    static func facetPage(_ facet: String, _ page: Int, _ count: Int) -> String {
        "\(facet), \(pageOf(page, count))"
    }

    /// The quiet mark beside a row: Needs Claude wins (it never turns Claude on by itself), then Later for an
    /// entitlement, then Soon for a feature still on its way; a live plain row has none.
    static func mark(_ choice: ReviewChoices.Choice) -> String? {
        if choice.needsClaude {
            return needsClaude
        }
        switch choice.readiness {
        case .live: return nil
        case .later: return later
        case .arrivesWith: return "Soon"
        }
    }

    /// VoiceOver's hint: what the value does, or what the switch waits for.
    static func hint(_ choice: ReviewChoices.Choice, value: String) -> String {
        switch choice.readiness {
        case .live: choice.says[value] ?? value
        case .later: "Later: this needs a build with access."
        case let .arrivesWith(feature): "Arrives with \(feature)."
        }
    }
}
