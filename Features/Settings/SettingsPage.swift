import SwiftUI
import TesseraCore

/// Settings, on its own page at last (batch 0): the look, his rest day, Claude, and Review, the switches he flips
/// live to pick between two ways of doing something. Said in sentences like Backups, never a list of toggles: no
/// cards, no pills, hairlines and margin labels only (Design sheets 80, 93, 100).
struct SettingsPage: View {
    /// The page this was opened from, for the back word ("‹ Review" from Review; "‹ Home" when opened from Home).
    var cameFrom = "Review"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented

    var body: some View {
        let v2 = SettingsV2.isOn
        return ScrollViewReader { reader in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if isPresented {
                        Button { dismiss() } label: {
                            Text(v2 ? "‹ \(cameFrom)" : "‹ Review")
                                .textRole(v2 ? .data : .label)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                                .frame(minHeight: 44)
                        }
                        .buttonStyle(HandleButtonStyle())
                        .accessibilityLabel("Back to \(v2 ? cameFrom : "Review")")
                    }
                    if !v2 {
                        Text("how Tessera runs")
                            .font(Theme.voice)
                            .foregroundStyle(Theme.Colors.context)
                            .entrance(0)
                    }
                    Text("Settings")
                        .textRole(.hero)
                        .wordFit("Settings")
                        .foregroundStyle(Theme.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, Theme.Spacing.s)
                        .entrance(1, hero: true)
                    if v2 {
                        // One sentence under the title, ink 2 (sheet 154).
                        Text(SettingsV2.sentence)
                            .font(Theme.voice)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .padding(.top, Theme.Spacing.xs)
                            .entrance(1)
                    }

                    // His own page: weight, height, age, sex, and what the app knows of his training (Design 108 s3).
                    MeDoor()
                        .padding(.top, Theme.Spacing.m)
                        .entrance(2)

                    // "Porcelain by day, Obsidian by night", each name a value word.
                    LookSentence()
                        .padding(.top, Theme.Spacing.xxl)
                        .entrance(2)

                    // His rest day (RG4).
                    RestDaySentence()
                        .padding(.top, Theme.Spacing.xxl)
                        .entrance(3)

                    // The units every measure reads in (Design sheet 115): the same pick a swipe on a unit word makes.
                    UnitsSentence()
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

                    // Drawn only while some switch ships in this build (Product, Oct 20).
                    if !ReviewChoices.drawnPages().isEmpty {
                        ReviewSection()
                            .padding(.top, Theme.Spacing.section)
                            .entrance(5)
                            .id(Self.reviewAnchor)
                    }

                    NavigationLink {
                        BackupView()
                    } label: {
                        Text("Backups")
                    }
                    .settingsWordStyle()
                    .padding(.top, Theme.Spacing.xxl)
                    .accessibilityHint("Where your history is kept")

                    // Who made what: one line per source.
                    NavigationLink {
                        AboutPage()
                    } label: {
                        Text("About")
                    }
                    .settingsWordStyle()
                    .padding(.top, Theme.Spacing.l)
                    .accessibilityHint("Credits for the pictures and sources")

                    // Which release this is: the git SHA the build was made from, one quiet line at the foot.
                    Text("Build \(BuildStamp.short)")
                        .textRole(v2 ? .data : .label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .padding(.top, Theme.Spacing.section)
                        .accessibilityLabel("Build \(BuildStamp.short)")
                }
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.section)
            }
            .scrollIndicators(.hidden)
            .task {
                // From the "Sample data" word on Today: down to Review, whose Shown page holds the switch.
                guard SampleData.shared.jumpsToSwitch else { return }
                try? await Task.sleep(for: .milliseconds(350))
                withTesseraAnimation(reduceMotion: reduceMotion) { reader.scrollTo(Self.reviewAnchor, anchor: .top) }
                try? await Task.sleep(for: .milliseconds(400))
                SampleData.shared.jumpsToSwitch = false
            }
        }
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .navigationBarBackButtonHidden()
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    private static let reviewAnchor = "review"
}

// MARK: - What Tess knows

/// "Tess remembers 12 things.", the count a value word that opens What Tess knows.
private struct TessKnowsDoor: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        let count = TessMemoryStore(engine: model.engine, forgetLogURL: model.forgetLogURL).countWord()
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            if SettingsV2.isOn {
                SettingsV2Label(text: "Memory")
            } else {
                Text("Memory")
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .accessibilityAddTraits(.isHeader)
            }
            // Only the count is the value word: "Tess remembers 12 things." (Design on #1127).
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(TessKnowsCopy.doorLead(count))
                NavigationLink {
                    TessKnowsPage()
                } label: {
                    Text(TessKnowsCopy.doorCount(count)).fontWeight(.semibold)
                        .foregroundStyle(SettingsV2.valueInk)
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

    private let pages = ReviewChoices.drawnPages()

    /// The page holding the Sample data switch, for the jump from Today.
    private var samplePage: Int? {
        pages.firstIndex { $0.rows.contains { $0.id == SampleData.choiceID } }
    }

    var body: some View {
        let choices = ReviewChoices.shared
        return reviewFrame(SettingsV2.isOn) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text("Try a new way; today's stays one tap away.")
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Named pages with their neighbours peeking (Design sheet 108): Looks and day, Workout, Kitchen,
                // Connected, Shown.
                // The Page turn switch turns Review's own pages, so he feels his pick right here (Product, Oct 20).
                let turn = PageTurnStyle.current
                PeekTabs(tabs: pages.map(\.word), selection: $page, turns: turn) { index in
                    if turn == .today {
                        // No lines between rows (Kaushik's rule): space alone separates them.
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            ForEach(pages[index].rows) { choice in
                                row(choice)
                            }
                        }
                    } else {
                        PageTurnRows(items: pages[index].rows, page: index, style: turn) { choice in
                            row(choice)
                                .padding(.vertical, Theme.Spacing.s)
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
                            .settingsWordStyle()
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
        .onAppear {
            if SampleData.shared.jumpsToSwitch, let samplePage {
                page = samplePage
            }
        }
    }

    /// Today's margin label, or v2's sentence-case one above the rows.
    @ViewBuilder
    private func reviewFrame(_ v2: Bool, @ViewBuilder content: () -> some View) -> some View {
        if v2 {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                SettingsV2Label(text: "Review")
                content()
            }
        } else {
            MarginSection(label: "Review", content: content)
        }
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
                        .foregroundStyle(live ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.valueWash)
                .contentTransition(.opacity)
                .disabled(!live)
                Text(".")
                Spacer(minLength: 0)
            }
            .textRole(.body)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(choice.name)
            // The mark below is drawn apart, so VoiceOver hears it with the value: "On, Needs Claude".
            .accessibilityValue(ReviewSwitchCopy.spokenValue(choice, value: value))
            .accessibilityHint(ReviewSwitchCopy.hint(choice, value: value))
            .accessibilityAddTraits(live ? .isButton : [])
            .accessibilityAdjustableAction { direction in
                flip(choice, forward: direction != .decrement)
            }
            // A double tap flips it too, as a tap on the value word does (Design on #1127).
            .accessibilityAction { flip(choice, forward: true) }
            // The mark sits under the sentence, so a long name never wraps beside its value (the clip on #1184:
            // "Tess names / training days: On." squeezed by NEEDS CLAUDE).
            if let mark = ReviewSwitchCopy.mark(choice) {
                Text(mark)
                    .textRole(SettingsV2.isOn ? .data : .label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .accessibilityHidden(true)
            }
            // Page turn plays its pick once on a two-line mini page (sheet 93).
            if choice.id == "pageTurn" {
                PageTurnPreview(style: PageTurnStyle(rawValue: value) ?? .today)
            }
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

    /// The value VoiceOver hears, with the row's mark when it has one: "On, Needs Claude".
    static func spokenValue(_ choice: ReviewChoices.Choice, value: String) -> String {
        mark(choice).map { "\(value), \($0)" } ?? value
    }

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
