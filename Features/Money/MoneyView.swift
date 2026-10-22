import SwiftUI
import TesseraCore

/// Money, the front (ship list screen 7 under the one-line grammar, sheet money-reading-grammar): ‹ REVIEW, the
/// title, the context line ("October, 16 days in"), the month sentence with its numbers at 600, other currencies as
/// "Also" lines under it, the writing line, then one line per spend under its day label: the word in ink, the amount
/// at the right at 600, tabular, as typed. No chart, no budget, no "left to spend", never red. A line opens its
/// spend's page (one tap down: the amount as the hero).
///
/// Entry: present `MoneyView()` from the area index once areas are shown (`AreasShown.isOn`).
struct MoneyView: View {
    var back = "Review"

    var body: some View {
        NavigationStack {
            MoneyPage(back: back)
                // The page asks for the day's rates once on opening, so a currency swipes to an estimate.
                .refreshesRates()
                .navigationDestination(for: Route.self) { ObjectPage(route: $0) }
                .toolbar(.hidden, for: .navigationBar)
        }
        .environment(\.animateEntrance, true)
    }
}

private struct MoneyPage: View {
    let back: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var draft = ""
    @State private var made = 0
    @State private var spoke = false
    @FocusState private var writing: Bool

    var body: some View {
        let _ = model.revision
        let front = MoneyFront(store: model.store, classes: model.classes, now: AppClock.now)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BackWord(title: back) { dismiss() }
                    .entrance(0)
                Text("Money")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(0)
                Text(front.context)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.top, Theme.Spacing.xs)
                    .entrance(1)
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    ForEach(Array(front.sentence.enumerated()), id: \.offset) { index, line in
                        NumberedSentence(text: line)
                            .opacity(index == 0 ? 1 : 0.6)
                    }
                }
                .contentTransition(.numericText())
                .padding(.top, Theme.Spacing.xl)
                .accessibilityElement(children: .combine)
                .entrance(2)

                AreaWritingLine(word: "Spent", prompt: MoneyCopy.prompt, label: "Log a spend", text: $draft,
                                focused: $writing, onSubmit: log)
                    .padding(.top, Theme.Spacing.xl)
                    .entrance(3)

                if front.isEmpty {
                    Text("No spends yet.")
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .padding(.top, Theme.Spacing.xxl)
                        .entrance(4)
                }

                ForEach(front.groups) { group in
                    VStack(alignment: .leading, spacing: 0) {
                        if let heading = group.heading {
                            Text(heading)
                                .textRole(.labelStrong)
                                .textCase(.uppercase)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                                .accessibilityAddTraits(.isHeader)
                                .padding(.bottom, Theme.Spacing.s)
                        }
                        ForEach(group.days) { day in
                            MoneyDay(day: day, stacked: typeSize.isAccessibilitySize, onDelete: delete)
                        }
                    }
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(4)
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
            .tesseraAnimation(Theme.Motion.house, value: front.groups.flatMap { $0.days.flatMap(\.lines) }.map(\.id))
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .safeAreaInset(edge: .bottom, spacing: 0) { AreaTessLine() }
        .tesseraFeedback(.made, trigger: made)
        .onAppear {
            guard !spoke else { return }
            spoke = true
            if front.isEmpty, TessVoice.shared.note == nil {
                TessVoice.shared.say(MoneyCopy.emptyTess)
            }
        }
    }

    /// "spent 12.40 lunch": a new spend, "12.40 lunch, logged." with UNDO 4 s (a new thing; 10 s under VoiceOver).
    /// A line it can't read stays in the field, so nothing he typed is lost.
    private func log() {
        guard let action = MoneyCapture.spend(draft) else {
            TessVoice.shared.say(MoneyCopy.didntCatch)
            return
        }
        guard let done = try? model.engine.perform(action, by: .user) else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            draft = ""
            model.touch()
        }
        TessVoice.shared.say(done.record.receipt ?? "\(done.output.title), logged.", undo: done.record,
                             holds: .seconds(4))
        made += 1
    }

    /// The named delete (G304): "12.40 lunch, deleted." with UNDO 10 s.
    private func delete(_ line: MoneyFront.Line) {
        guard let record = try? model.engine.perform(DeleteObject(object: line.id), by: .user).record else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        TessVoice.shared.say(MoneyCopy.deleted(line.title), undo: record, holds: .seconds(10))
    }
}

/// One day: its label ("OCT 15"), then a line per spend. At accessibility sizes the amount sits under the word.
private struct MoneyDay: View {
    let day: MoneyFront.Day
    let stacked: Bool
    let onDelete: (MoneyFront.Line) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(day.label)
                .textRole(.label)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .padding(.top, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.xs)
                .accessibilityHidden(true)
            ForEach(day.lines) { line in
                NavigationLink(value: Route.object(line.id)) {
                    layout(line)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(line.spoken)
                .accessibilityHint("Opens the spend")
                .accessibilityAction(named: MoneyCopy.deleteName(line.title)) { onDelete(line) }
                .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private func layout(_ line: MoneyFront.Line) -> some View {
        if stacked {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                word(line)
                amount(line)
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                word(line)
                Spacer(minLength: Theme.Spacing.m)
                amount(line)
            }
        }
    }

    private func word(_ line: MoneyFront.Line) -> some View {
        Text(line.word)
            .textRole(.body)
            .foregroundStyle(Theme.Colors.ink)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The amount drawn as a measure: the number in ink, the currency a small word that swipes to an estimate.
    private func amount(_ line: MoneyFront.Line) -> some View {
        MeasureView(measure: line.measure, size: Theme.concept.scale.body.size, weight: .medium)
    }
}
