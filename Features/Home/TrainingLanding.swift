import SwiftUI
import TesseraCore

// Training's landing, v2 (design/landing-pages-131.md): a sentence first, then the one action, today's lanes, the week
// as set marks and the doors. The working weight never leads; it lives inside the sentence.

// MARK: - The sentence

/// A sentence and the one word drawn in the accent (Core's `LandingSentence`, which the page re-wraps to splice an hour
/// or more in the house words).
struct SentenceParts: Equatable {
    let text: String
    let key: String?
}

/// One or two short sentences with the key word in the app's accent. The key word is a link that opens the same
/// object the old title did; Reduce Motion and Dynamic Type follow the text role.
struct LandingSentenceView: View {
    let sentence: SentenceParts
    let opens: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Text(attributed)
            .font(Theme.voice(size: 28))
            .foregroundStyle(Theme.Colors.ink)
            // Never cut with "...": at accessibility sizes the sentence takes the lines it needs.
            .lineLimit(typeSize.isAccessibilitySize ? nil : 5)
            .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.8)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.openURL, OpenURLAction { _ in
                opens()
                return .handled
            })
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityAction(named: sentence.key.map { "Open \($0)" } ?? "Open") { opens() }
    }

    private var attributed: AttributedString {
        var text = AttributedString(sentence.text)
        guard let key = sentence.key, let range = text.range(of: key) else { return text }
        text[range].foregroundColor = Theme.Colors.liveInk
        text[range].link = URL(string: "tessera://open")
        return text
    }
}

// MARK: - The week

/// One day of the week as a set mark: done filled with ink, today open in the accent, the rest faint rings.
struct WeekDot: Identifiable, Equatable {
    enum State { case done, today, rest, ahead }

    let id: Date
    let label: String
    let state: State
}

enum TrainingWeek {
    /// Monday to Sunday from the same plan week Review reads, so the two never disagree.
    @MainActor
    static func dots(_ model: AppModel, now: Date, hasSessionToday: Bool, calendar: Calendar = .current) -> [WeekDot] {
        let tesseraDay = TesseraDay(calendar: calendar)
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan)
        let week = model.ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: perWeek,
                                     calendar: calendar)
        let firstUse = ReviewPage.firstUse(model)
        let restToday = NowPicker(engine: model.engine).restDay(plan: plan, at: now, sessionsPerWeek: perWeek,
                                                                calendar: calendar) != nil
        let marks = WeekReview.marks(week.map(WeekReview.Slot.init), firstUse: firstUse,
                                     restToday: restToday, now: now, calendar: calendar)
        let today = tesseraDay.today(now)
        let symbols = calendar.shortWeekdaySymbols
        return zip(week, marks).map { slot, mark in
            let isToday = slot.day == today
            // Today is open in the accent whenever there is a session to do; trained days fill.
            let state: WeekDot.State = switch mark {
            case .trained: .done
            case .rest: isToday && hasSessionToday ? .today : .rest
            default: isToday ? .today : .ahead
            }
            let weekday = symbols[calendar.component(.weekday, from: slot.day) - 1]
            return WeekDot(id: slot.day, label: isToday ? "Today" : weekday, state: state)
        }
    }
}

extension TrainingWeek {
    /// Sessions done in the plan's week so far.
    @MainActor
    static func doneThisWeek(_ model: AppModel, now: Date, calendar: Calendar = .current) -> Int {
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan)
        return model.ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: perWeek, calendar: calendar)
            .reduce(0) { $0 + $1.done.count }
    }
}

struct TrainingWeekMarks: View {
    let dots: [WeekDot]
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(dots) { dot in
                VStack(spacing: 6) {
                    mark(dot)
                        .frame(width: 24, height: 24)
                    Text(dot.label)
                        .textRole(.label)
                        .foregroundStyle(dot.state == .today ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)
            }
        }
        // The week is a read of the page, not a control: one spoken line.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    /// A day done is a closed brush circle in dried ink; today is an open one, still wet in the accent (the week
    /// uses the set marks, the page's one drawn thing).
    private static let doneMark = SetMarkSpec(id: UUID(), number: 1, reps: 8, target: 8, weight: 1, heaviest: 1,
                                              isBest: false)
    private static let todayMark = SetMarkSpec(id: UUID(), number: 1, reps: 7, target: 8, weight: 1, heaviest: 1,
                                               isBest: false)

    @ViewBuilder
    private func mark(_ dot: WeekDot) -> some View {
        // Finishing marks (139): a session just finished, so today's mark gathers its sets and closes.
        if FinishWords.isOn, dot.id == TesseraDay().today(AppClock.now), dot.state == .today || dot.state == .done,
           FinishMoment.shared.current != nil
        {
            FinishingTodayMark(side: 24, open: Self.todayMark, closed: Self.doneMark)
        } else {
            plainMark(dot.state)
        }
    }

    @ViewBuilder
    private func plainMark(_ state: WeekDot.State) -> some View {
        switch state {
        case .done:
            SetMarkCircle(spec: Self.doneMark, side: 24)
        case .today:
            SetMarkCircle(spec: Self.todayMark, side: 24, age: 0)
        case .rest:
            Capsule().fill(Theme.Colors.ink.opacity(0.22)).frame(width: 10, height: 1.4)
        case .ahead:
            Circle().stroke(Theme.Colors.ink.opacity(0.22), lineWidth: 1.4)
        }
    }

    private var spoken: String {
        let done = dots.filter { $0.state == .done }.count
        let rest = dots.contains { $0.state == .today } ? ", today still open" : ""
        return "This week, \(done) \(done == 1 ? "session" : "sessions") done\(rest)"
    }
}

// MARK: - The doors

/// An ink word into a place, with a short value word at the right.
struct TrainingDoor: Identifiable {
    let id: String
    let word: String
    let value: String?
    let open: () -> Void
}

struct TrainingDoors: View {
    let doors: [TrainingDoor]
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(doors) { door in
                Button { door.open() } label: {
                    let layout = typeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                        : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.s))
                    layout {
                        Text(door.word)
                            .textRole(.bodyStrong)
                            .foregroundStyle(Theme.Colors.ink)
                        if !typeSize.isAccessibilitySize {
                            Spacer(minLength: Theme.Spacing.s)
                        }
                        if let value = door.value {
                            Text(value)
                                .textRole(.data)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityLabel([door.word, door.value].compactMap(\.self).joined(separator: ", "))
            }
        }
    }
}

// MARK: - Words

extension TrainingPage {
    /// Each set about two and a half minutes with its rest, to the nearest five. The one estimate every line reads.
    static func estimatedMinutes(sets: Int) -> Int {
        max(5, Int((Double(sets) * 2.5 / 5).rounded()) * 5)
    }

    /// The Training sentence from Core's template (its lengths read the house way: "1 hr 30 min").
    static func sentence(session: String?, minutes: Int?, opener: (exercise: String, weight: String)?)
        -> SentenceParts
    {
        let base = LandingSentences.training(session: session, minutes: minutes, opener: opener)
        return SentenceParts(text: base.text, key: base.key)
    }
}
