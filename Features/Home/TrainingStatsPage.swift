import SwiftUI
import TesseraCore

// Training Stats (Product build sheet, Oct 22). UI only: every number and sentence comes from Core's TrainingStats and
// TrainingSentences, and nothing is recomputed here. No big number leads; the page says "best", never "record".
// Private workouts never reach this page (Core filters them once). Calories and body numbers are not on it.

/// The Review switches this page rides (default Off, not in backups).
enum StatsSwitch {
    nonisolated static let choiceID = "trainingStats"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }

    @MainActor static var balanceIsOn: Bool {
        ReviewChoices.shared.value(of: "statsBalance") == "On"
    }

    @MainActor static var lightWeeksIsOn: Bool {
        ReviewChoices.shared.value(of: "trainingLightWeeks") == "On"
    }
}

/// The range knob's two words.
enum StatsRangeWord: String, CaseIterable, Hashable {
    case threeMonths = "3 months", year = "Year"

    var range: TrainingStats.Range {
        self == .year ? .year : .threeMonths
    }
}

/// What the page shows for one range, read from Core once per draw.
@MainActor
struct StatsReading {
    let best: TrainingStats.Best?
    let lines: [TrainingStats.StrengthLine]
    let volume: TrainingStats.Volume
    let habit: TrainingStats.Habit
    let balance: TrainingStats.Balance?
    let unit: MassUnit
    let range: TrainingStats.Range

    init(_ model: AppModel, range: TrainingStats.Range, now: Date) {
        let stats = TrainingStats(store: model.store, classes: model.classes)
        unit = Format.unit
        self.range = range
        best = stats.bestInRange(range, now: now)
        lines = stats.strengthLines(range, now: now, unit: unit)
        volume = stats.volume(range, now: now)
        habit = stats.habit(range, now: now, lightWeeks: StatsSwitch.lightWeeksIsOn)
        balance = StatsSwitch.balanceIsOn ? stats.balance(range, now: now) : nil
    }

    /// Nothing to show yet: the page is its title and one line.
    var isEmpty: Bool {
        best == nil && lines.isEmpty && volume.totalSets == 0 && habit.weeks.allSatisfy(\.isEmpty)
    }
}

struct TrainingStatsPage: View {
    let close: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var word: StatsRangeWord = .threeMonths
    /// The week whose dates show under Habit.
    @State private var pickedWeek: Date?

    var body: some View {
        let now = AppClock.now
        let reading = StatsReading(model, range: word.range, now: now)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header(reading)
                if reading.isEmpty {
                    EmptyView()
                } else {
                    content(reading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
    }

    // MARK: Header

    private func header(_ reading: StatsReading) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: close) {
                Text("‹ Training")
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(minHeight: 44, alignment: .leading)
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityLabel("Back to Training")
            Text("Stats")
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle(reading))
                .textRole(.body)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Theme.Spacing.xs)
        }
    }

    private func subtitle(_ reading: StatsReading) -> String {
        if reading.isEmpty {
            return "Your numbers start with your first session."
        }
        return TrainingSentences.strengthOpening(reading.lines, range: reading.range, unit: reading.unit)
            ?? "Where your training stands."
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ reading: StatsReading) -> some View {
        if let best = reading.best {
            bestBlock(best, reading.unit)
                .padding(.top, Theme.Spacing.xl)
        }
        KnobWords(values: StatsRangeWord.allCases, selection: $word, word: \.rawValue,
                  spoken: "Range, \(word.rawValue), adjustable")
            .padding(.top, Theme.Spacing.l)
        if !reading.lines.isEmpty {
            strengthBlock(reading)
                .padding(.top, Theme.Spacing.xl)
        }
        if reading.volume.totalSets > 0 {
            volumeBlock(reading.volume)
                .padding(.top, Theme.Spacing.xl)
        }
        habitBlock(reading)
            .padding(.top, Theme.Spacing.xl)
        if let balance = reading.balance {
            balanceBlock(balance)
                .padding(.top, Theme.Spacing.xl)
        }
    }

    private func kicker(_ text: String) -> some View {
        Text(text)
            .textRole(.label)
            .foregroundStyle(Theme.Colors.inkSecondary)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: Best (pinned)

    private func bestBlock(_ best: TrainingStats.Best, _ unit: MassUnit) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            kicker("Best")
            Text(StatsMass.estimate(kg: best.e1RM, unit: unit))
                .textRole(.heroNumber)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, Theme.Spacing.s)
            Text(TrainingSentences.best(best, unit: unit))
                .textRole(.body)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenBest(best, unit))
    }

    private func spokenBest(_ best: TrainingStats.Best, _ unit: MassUnit) -> String {
        let amount = StatsMass.estimate(kg: best.e1RM, unit: unit)
            .replacingOccurrences(of: " kg", with: " kilograms").replacingOccurrences(of: " lb", with: " pounds")
        let date = best.date.formatted(.dateTime.month(.wide).day())
        return "Your best \(best.exercise.lowercased()) is about \(amount) for 1, \(date)."
    }

    // MARK: Strength

    private func strengthBlock(_ reading: StatsReading) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            kicker("Strength")
            ForEach(reading.lines, id: \.exercise) { line in
                StrengthRow(line: line, unit: reading.unit, range: reading.range, open: { open(line.exercise) })
            }
        }
    }

    /// A lift's exercise page, found by name among the library's exercises.
    private func open(_ name: String) {
        guard let root = model.classDef(.exercise) else { return }
        if let match = ClassResolver.descendants(of: root).first(where: { $0.name == name }) {
            close()
            model.open(.classDef(match.id))
        }
    }

    // MARK: Volume

    private func volumeBlock(_ volume: TrainingStats.Volume) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            kicker("Sets this week")
            Text(TrainingSentencesWords.number(volume.totalSets))
                .textRole(.titleNumber)
                .foregroundStyle(Theme.Colors.ink)
                .padding(.top, Theme.Spacing.xs)
                .padding(.bottom, Theme.Spacing.s)
            if let lead = volume.rows.first {
                Text(TrainingSentences.volume(lead))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, Theme.Spacing.s)
            }
            ForEach(volume.rows, id: \.name) { row in
                VolumeRow(row: row)
            }
        }
    }

    // MARK: Habit

    private func habitBlock(_ reading: StatsReading) -> some View {
        let habit = reading.habit
        return VStack(alignment: .leading, spacing: 0) {
            kicker("Your weeks")
            if let current = habit.current {
                Text("\(current.sessions)")
                    .textRole(.titleNumber)
                    .foregroundStyle(Theme.Colors.ink)
                    .padding(.top, Theme.Spacing.xs)
            }
            HabitMarks(weeks: habit.weeks, narrow: reading.range == .year, picked: $pickedWeek)
                .padding(.top, Theme.Spacing.s)
            if let week = habit.weeks.first(where: { $0.start == pickedWeek }) {
                Text(weekWords(week))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .padding(.top, Theme.Spacing.s)
            }
            Text(TrainingSentences.sessions(habit.current?.sessions ?? 0, usual: habit.usual))
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Theme.Spacing.s)
            if let run = TrainingSentences.bestRun(habit.bestRun) {
                Text(run)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
        }
    }

    private func weekWords(_ week: TrainingStats.HabitWeek) -> String {
        let date = week.start.formatted(.dateTime.month(.wide).day())
        var text = "Week of \(date), \(week.sessions) \(week.sessions == 1 ? "session" : "sessions")."
        if StatsSwitch.lightWeeksIsOn, week.isLight {
            text += " \(TrainingSentences.lighterWeek)"
        }
        return text
    }

    // MARK: Balance

    private func balanceBlock(_ balance: TrainingStats.Balance) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            kicker("Balance")
            ForEach(TrainingSentences.balance(balance), id: \.self) { line in
                Text(line)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Plain words for numbers the page shows ("12", "12.5").
enum TrainingSentencesWords {
    static func number(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(format: "%g", rounded)
    }
}

// MARK: - Strength row

/// A lift: its name, a thin ink line on its own scale with the best as a hot outline ring, and its number at the right.
private struct StrengthRow: View {
    let line: TrainingStats.StrengthLine
    let unit: MassUnit
    let range: TrainingStats.Range
    let open: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: open) {
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
                : AnyLayout(HStackLayout(alignment: .center, spacing: Theme.Spacing.m))
            layout {
                // The name wraps rather than cutting.
                Text(line.exercise)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : 112, alignment: .leading)
                TrendLine(points: line.points, best: line.bestRing)
                    .frame(height: 24)
                    .accessibilityHidden(true)
                if let now = line.nowKg {
                    Text(StatsMass.estimate(kg: now, unit: unit))
                        .textRole(.titleNumber)
                        .foregroundStyle(Theme.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minWidth: typeSize.isAccessibilitySize ? 0 : 96, alignment: .trailing)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .accessibilityHint("Opens the exercise")
    }

    private var spoken: String {
        let amount = line.nowKg.map { StatsMass.estimate(kg: $0, unit: unit) } ?? ""
        let spokenAmount = amount.replacingOccurrences(of: " kg", with: " kilograms")
            .replacingOccurrences(of: " lb", with: " pounds")
        let words = TrainingSentences.strength(line, range: range, unit: unit) ?? ""
        return "\(line.exercise), about \(spokenAmount). \(words)"
    }
}

/// A thin ink line on its own scale (lowest to highest); the best is a hot outline ring on it.
private struct TrendLine: View {
    let points: [Double]
    let best: Double

    var body: some View {
        Canvas { context, size in
            guard points.count > 1, let low = points.min(), let high = points.max() else { return }
            let span = max(high - low, 0.0001)
            let inset: CGFloat = 5
            func position(_ index: Int, _ value: Double) -> CGPoint {
                CGPoint(x: inset + (size.width - 2 * inset) * CGFloat(index) / CGFloat(points.count - 1),
                        y: size.height - inset - (size.height - 2 * inset) * CGFloat((value - low) / span))
            }
            var path = Path()
            for (index, value) in points.enumerated() {
                index == 0 ? path.move(to: position(index, value)) : path.addLine(to: position(index, value))
            }
            context.stroke(path, with: .color(Theme.Colors.ink.opacity(0.8)), style: StrokeStyle(lineWidth: 1.2,
                                                                                                 lineCap: .round,
                                                                                                 lineJoin: .round))
            if let top = points.firstIndex(of: best) {
                let centre = position(top, best)
                context.stroke(Path(ellipseIn: CGRect(x: centre.x - 4, y: centre.y - 4, width: 8, height: 8)),
                               with: .color(Theme.Colors.Accent.training), lineWidth: 1.4)
            }
        }
    }
}

// MARK: - Volume row

/// A muscle with its sets this week as tallies in fives; the words say it plainly.
private struct VolumeRow: View {
    let row: TrainingStats.MuscleRow
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Theme.Spacing.m))
        layout {
            Text(row.name)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : 110, alignment: .leading)
            Tallies(count: Int(row.sets.rounded()), wraps: typeSize.isAccessibilitySize)
                .accessibilityHidden(true)
        }
        .frame(minHeight: 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TrainingSentences.volume(row))
    }
}

/// Tally marks in groups of five: four strokes and the slash across them.
private struct Tallies: View {
    let count: Int
    let wraps: Bool

    var body: some View {
        let groups = (0 ..< (count + 4) / 5).map { index in min(5, count - index * 5) }
        let layout = wraps ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 8))
        layout {
            ForEach(groups.indices, id: \.self) { index in
                TallyGroup(strokes: groups[index])
                    .frame(width: 22, height: 18)
            }
        }
    }
}

private struct TallyGroup: View {
    let strokes: Int

    var body: some View {
        Canvas { context, size in
            let ink = GraphicsContext.Shading.color(Theme.Colors.ink)
            for index in 0 ..< min(strokes, 4) {
                let x = 3 + CGFloat(index) * 5
                var stroke = Path()
                stroke.move(to: CGPoint(x: x, y: 1))
                stroke.addLine(to: CGPoint(x: x, y: size.height - 1))
                context.stroke(stroke, with: ink, style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            }
            if strokes == 5 {
                var slash = Path()
                slash.move(to: CGPoint(x: 0, y: size.height - 2))
                slash.addLine(to: CGPoint(x: size.width, y: 2))
                context.stroke(slash, with: ink, style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            }
        }
    }
}

// MARK: - Habit marks

/// One column per week, one mark per session stacked from the bottom; this week in the accent; an empty week is a
/// flat hairline and is never named. A tap picks a week.
private struct HabitMarks: View {
    let weeks: [TrainingStats.HabitWeek]
    let narrow: Bool
    @Binding var picked: Date?

    /// A session is a closed brush ring in dried ink; this week's are the open, wet ring in the accent (the same marks
    /// as the landing's week).
    private static let doneMark = SetMarkSpec(id: UUID(), number: 1, reps: 8, target: 8, weight: 1, heaviest: 1,
                                              isBest: false)
    private static let nowMark = SetMarkSpec(id: UUID(), number: 1, reps: 7, target: 8, weight: 1, heaviest: 1,
                                             isBest: false)

    var body: some View {
        let mark: CGFloat = narrow ? 5 : 12
        HStack(alignment: .bottom, spacing: narrow ? 1 : 3) {
            ForEach(weeks.indices, id: \.self) { index in
                let week = weeks[index]
                let isCurrent = index == weeks.count - 1
                VStack(spacing: narrow ? 0 : 1) {
                    if week.isEmpty {
                        Rectangle().fill(Theme.Colors.ink.opacity(0.22)).frame(height: 1)
                    } else {
                        ForEach(0 ..< min(week.sessions, 7), id: \.self) { _ in
                            SetMarkCircle(spec: isCurrent ? Self.nowMark : Self.doneMark, side: mark,
                                          age: isCurrent ? 0 : 99)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: narrow ? 40 : 96, alignment: .bottom)
                .contentShape(Rectangle())
                .onTapGesture { picked = week.start }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "Week of \(week.start.formatted(.dateTime.month(.wide).day())), \(week.sessions) \(week.sessions == 1 ? "session" : "sessions")"
                )
                .accessibilityAddTraits(.isButton)
            }
        }
    }
}
