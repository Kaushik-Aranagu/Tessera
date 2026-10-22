import SwiftUI
import TesseraCore

/// You (Design 108 section 3, mockup `long-press-and-you-108.png`; huddle B2): his own page, reached from Settings.
/// Four sentences with the values as words: weight from his last weigh-in, height, age, sex, all kept on this phone.
/// The weight is private (it comes from a private note), so its word reads "hidden" until he taps it, and hides
/// again when he leaves. Under the sentences, what the app knows of him in the same voice: how he trains and his rest
/// day, his totals, his best lift per exercise (each a door to the exercise), what Tess knows, and his areas.
/// Left edge goes back; the right edge goes in to what Tess knows (sheets 75, 76).
struct MePage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @Environment(\.scenePhase) private var scenePhase

    @State private var facts = MeFacts.empty
    @State private var weightShown = false
    @State private var allBests = false
    @State private var knowsOpen = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isPresented {
                    Button { dismiss() } label: {
                        Text("‹ Settings")
                            .textRole(.label)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityLabel("Back to Settings")
                }
                Text(MeCopy.eyebrow)
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .entrance(0)
                Text(MeCopy.title)
                    .textRole(.hero)
                    .wordFit(MeCopy.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1, hero: true)

                sentences
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(2)

                training
                    .padding(.top, Theme.Spacing.section)
                    .entrance(3)

                bests
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(4)

                tess
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(5)

                areas
                    .padding(.top, Theme.Spacing.xxl)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .overlay(alignment: .trailing) { inEdge }
        .navigationBarBackButtonHidden()
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $knowsOpen) { TessKnowsPage() }
        .onAppear { facts = MeFacts.read(model) }
        .onChange(of: model.revision) { facts = MeFacts.read(model) }
        // Shown for this visit only: leaving hides the weight again.
        .onDisappear { weightShown = false }
        // And whenever the app leaves the front (background, app switcher).
        .onChange(of: scenePhase) { _, phase in
            weightShown = MeCopy.weightStaysShown(weightShown, in: phase)
        }
    }

    // MARK: The four sentences

    private var sentences: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            // One wrapping run, so the sentence reflows at accessibility sizes; the whole sentence is the 44 pt door.
            if facts.weightKg != nil {
                Button {
                    withTesseraAnimation(reduceMotion: reduceMotion) { weightShown.toggle() }
                } label: {
                    weightSentence
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.valueWash)
                .privacySensitive(weightShown)
                .tesseraFeedback(.selection, trigger: weightShown)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Weight")
                .accessibilityValue(MeCopy.weightWord(facts.weightKg, shown: weightShown))
                .accessibilityHint(weightShown ? MeCopy.weightHideHint : MeCopy.weightShowHint)
                .accessibilityAddTraits(.isButton)
            } else {
                weightSentence
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Weight")
                    .accessibilityValue(MeCopy.weightWord(nil, shown: false))
            }

            ForEach(MeCopy.unsaidFields, id: \.self) { field in
                Text("\(field) \(Text(MeCopy.notSaid).fontWeight(.semibold)).")
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(field)
                    .accessibilityValue(MeCopy.notSaid)
            }

            Text(MeCopy.keptLine)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Theme.Spacing.s)
        }
        .accessibilityElement(children: .contain)
    }

    /// "Weight hidden, from your last weigh-in." as one Text, the value word in semibold, so it wraps as a sentence.
    private var weightSentence: some View {
        let word = Text(MeCopy.weightWord(facts.weightKg, shown: weightShown)).fontWeight(.semibold)
        return Text("Weight \(word)\(MeCopy.weightTail(facts.weightKg))")
            .textRole(.body)
            .foregroundStyle(Theme.Colors.ink)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(.opacity)
    }

    // MARK: Training

    private var training: some View {
        MarginSection(label: MeCopy.trainingLabel) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                if let rhythm = MeCopy.rhythm(NowPage.sessionsPerWeek(model: model, plan: model.plan)) {
                    Text(rhythm)
                }
                // His rest day, the same sentence as Settings: a tap picks another day.
                RestDaySentence()
                Text(MeCopy.workouts(facts.workouts, since: facts.firstWorkout))
                    .contentTransition(.numericText())
                if let sets = MeCopy.sets(facts.workingSets) {
                    Text(sets)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .contentTransition(.numericText())
                }
            }
            .textRole(.body)
            .foregroundStyle(Theme.Colors.ink)
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Bests

    private var bests: some View {
        let shown = allBests ? facts.bests : Array(facts.bests.prefix(MeCopy.bestsShown))
        return MarginSection(label: MeCopy.bestsLabel) {
            VStack(alignment: .leading, spacing: 0) {
                if facts.bests.isEmpty {
                    Text(MeCopy.noBests)
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.tess)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(Array(shown.enumerated()), id: \.element.id) { offset, best in
                    bestRow(best)
                        .transition(.opacity)
                    if offset < shown.count - 1 {
                        RowSeparator()
                    }
                }
                if let more = MeCopy.moreWord(total: facts.bests.count, expanded: allBests) {
                    Button(more) {
                        withTesseraAnimation(reduceMotion: reduceMotion) { allBests.toggle() }
                    }
                    .buttonStyle(.labelWord)
                    .frame(minHeight: 44)
                    .padding(.top, Theme.Spacing.s)
                    .accessibilityHint(allBests ? "Shows the five you train most" : "Shows every lift")
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// A lift as a door: its name dotted-underlined, its best in the hanging mono column, the exercise page behind.
    private func bestRow(_ best: MeFacts.Best) -> some View {
        NavigationLink {
            ObjectPage(route: .classDef(best.id))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                Text(best.name)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 4)
                    .overlay(alignment: .bottom) { DottedRule(color: Theme.Colors.inkTertiary) }
                Spacer(minLength: Theme.Spacing.s)
                Text(MeCopy.bestTrailing(best))
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                Text("→").textRole(.label).foregroundStyle(Theme.Colors.inkTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Theme.Spacing.m)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MeCopy.bestSpoken(best))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens the page")
    }

    // MARK: Tess

    private var tess: some View {
        let count = TessMemoryStore(engine: model.engine, forgetLogURL: model.forgetLogURL).countWord()
        return MarginSection(label: MeCopy.tessLabel) {
            Button { knowsOpen = true } label: {
                Text(TessKnowsCopy.door(count))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 44, alignment: .leading)
            }
            .buttonStyle(.valueWash)
            .accessibilityHint("Opens what Tess knows")
        }
    }

    // MARK: Areas

    /// His four areas with the line each is holding now (the area index's lines, read, never changed).
    private var areas: some View {
        let lines = AreaLines.lines(model, now: AppClock.now)
        let pages = HomeSpatialView.Page.allCases
        return MarginSection(label: MeCopy.areasLabel) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(pages.enumerated()), id: \.element) { offset, page in
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                        Text(page.title)
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.ink)
                        Spacer(minLength: Theme.Spacing.s)
                        Text(lines[page] ?? "")
                            .textRole(.data)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, Theme.Spacing.m)
                    .frame(minHeight: 44)
                    .accessibilityElement(children: .combine)
                    if offset < pages.count - 1 {
                        RowSeparator()
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Side swipe in

    /// The right edge (32 pt) goes in to what Tess knows, like every page's side swipe.
    private var inEdge: some View {
        Color.clear
            .frame(width: 32)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 16)
                    .onEnded { value in
                        if value.translation.width < -48, abs(value.translation.height) < 60 {
                            knowsOpen = true
                        }
                    }
            )
            .accessibilityHidden(true)
    }
}

/// Settings' door to You: "You" as a label word, the page behind.
struct MeDoor: View {
    var body: some View {
        NavigationLink {
            MePage()
        } label: {
            Text(MeCopy.door)
        }
        .buttonStyle(.labelWord)
        .frame(minHeight: 44)
        .accessibilityHint(MeCopy.doorHint)
    }
}
