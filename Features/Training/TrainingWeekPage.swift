import SwiftUI
import TesseraCore

/// One day on the This week wheel.
struct WeekDayRow: Identifiable, Equatable {
    enum Kind: Equatable {
        case done, today, ahead, past, rest
    }

    let id: Date
    var kind: Kind
    var name: String?
    var minutes: Int?
    var isSkipped = false

    var isMovable: Bool {
        (kind == .today || kind == .ahead) && name != nil && !isSkipped
    }
}

/// Moves and skips on the week, kept on this phone (the plan is never rewritten from here): a session slid a day
/// later swaps places with the day after it; a skipped one strikes in ink 3. Pure, so it is tested.
enum WeekTweaks {
    /// Applies the moves, in order, then the skips, to the week's rows.
    static func apply(_ rows: [WeekDayRow], moves: [Int], skips: Set<Int>) -> [WeekDayRow] {
        var rows = rows
        for index in moves where rows.indices.contains(index) && rows.indices.contains(index + 1) {
            guard rows[index].kind != .done, rows[index].name != nil, rows[index + 1].kind != .done else { continue }
            let (name, minutes) = (rows[index].name, rows[index].minutes)
            rows[index].name = rows[index + 1].name
            rows[index].minutes = rows[index + 1].minutes
            rows[index + 1].name = name
            rows[index + 1].minutes = minutes
            // A day that now has nothing is a rest day; one that gained a session is a day ahead.
            for slot in [index, index + 1] where rows[slot].kind != .today {
                rows[slot].kind = rows[slot].name == nil ? .rest : .ahead
            }
            if rows[index].kind == .today, rows[index].name == nil {
                rows[index].kind = .rest
            }
        }
        for index in skips where rows.indices.contains(index) {
            rows[index].isSkipped = true
        }
        return rows
    }
}

/// This week (sheet 230): the shared depth wheel centred on today. Today keeps the accent even off focus; done names
/// get
/// a 1 px green strike and green minutes; rest rows are ink 3. The brief follows the row in front, and tapping today
/// opens it. The action word "Move Push A": a tap slides it a day later, with Undo; drag left to skip.
struct TrainingWeekPage: View {
    var openToday: () -> Void = {}

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focus = 0
    @State private var moves: [Int] = []
    @State private var skips: Set<Int> = []
    @State private var cue = HapticCue()
    @State private var brief: (id: UUID, text: String, undo: () -> Void)?
    @State private var seeded = false

    private var base: [WeekDayRow] {
        let now = AppClock.now
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: model.plan)
        let week = model.ledger.week(containing: now, plan: model.plan, now: now, sessionsPerWeek: perWeek)
        return week.map { day in
            let kind: WeekDayRow.Kind = switch day.state {
            case .done: .done
            case .today: day.isRest ? .rest : .today
            case .upcoming: day.isRest ? .rest : .ahead
            case .past: .past
            }
            if let finished = day.done.first {
                return WeekDayRow(id: day.day, kind: .done,
                                  name: ObjectPrivacy.routineTitle(finished.title, in: model.store),
                                  minutes: finished.duration.map { Int(($0 / 60).rounded()) })
            }
            let name = day.planned.map { ObjectPrivacy.routineTitle($0.title, in: model.store) }
            let sets = day.planned
                .map { $0.orderedChildren.reduce(0) { $0 + Int(model.store.number("sets", of: $1) ?? 3) } }
            return WeekDayRow(id: day.day, kind: kind, name: day.isRest ? nil : name,
                              minutes: sets.map(TrainingPage.estimatedMinutes(sets:)))
        }
    }

    private var rows: [WeekDayRow] {
        WeekTweaks.apply(base, moves: moves, skips: skips)
    }

    private var todayIndex: Int {
        let today = TesseraDay().today(AppClock.now)
        return base.firstIndex { TesseraDay().isSameDay($0.id, today) } ?? 0
    }

    var body: some View {
        let _ = model.revision
        let rows = rows
        let current = rows.indices.contains(focus) ? rows[focus] : nil
        VStack(alignment: .leading, spacing: 0) {
            Text("This week")
                .font(Theme.Training.words(40, weight: .semibold, relativeTo: .largeTitle))
                .foregroundStyle(Theme.Colors.Accent.training)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Theme.Spacing.m)
            DepthWheel(items: rows, focus: $focus, home: todayIndex, style: .week, label: "This week",
                       onTap: { row, wasFocused in
                           if wasFocused, row.kind == .today {
                               openToday()
                           }
                       },
                       rowIdentifier: { "week-\($0.id.timeIntervalSince1970)" })
            { row, state in
                weekRow(row, state: state)
            }
            Spacer(minLength: Theme.Spacing.m)
            briefLine(for: current)
                .frame(height: 40, alignment: .leading)
            foot(current)
                .frame(height: 36)
                .padding(.bottom, HomeSpatialView.dockClearance)
        }
        .frame(maxWidth: .infinity, minHeight: 560, alignment: .topLeading)
        .tesseraFeedback(cue)
        .onAppear {
            guard !seeded else { return }
            seeded = true
            focus = todayIndex
        }
    }

    // MARK: Rows

    private func weekRow(_ row: WeekDayRow, state: WheelRowState) -> some View {
        let isToday = row.kind == .today
        let isRest = row.kind == .rest || row.name == nil
        // Today wears its split's colour, done days go green, planned days are slate, rest rows ink 3.
        let color: Color = isToday ? Theme.Colors.Split.color(forName: row.name ?? "")
            : isRest ? Theme.Colors.inkTertiary
            : row.kind == .done ? Theme.Colors.Go.green
            : row.kind == .ahead ? Theme.Colors.Slate.label
            : Theme.Colors.inkSecondary
        let day = row.id.formatted(.dateTime.weekday(.abbreviated))
        let weight: Font.Weight = state.isFocused || isToday ? .semibold : .regular
        return HStack(spacing: Theme.Spacing.m) {
            Text(day)
                .font(Theme.Training.words(30, weight: weight, relativeTo: .title))
                .foregroundStyle(color)
                .frame(width: 96, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(row.name ?? "Rest")
                .font(Theme.Training.words(30, weight: weight, relativeTo: .title))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .overlay { strike(row) }
                .layoutPriority(1)
            Spacer(minLength: Theme.Spacing.s)
            if let minutes = row.minutes, !isRest {
                MeasuredNumber(number: "\(minutes)", unit: "min", size: 26, weight: .light,
                               color: row.kind == .done ? Theme.Colors.Go.green : Theme.Colors.inkSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spoken(row, isToday: isToday))
    }

    @ViewBuilder
    private func strike(_ row: WeekDayRow) -> some View {
        if row.kind == .done {
            Rectangle().fill(Theme.Colors.Go.green).frame(height: 1)
        } else if row.isSkipped {
            Rectangle().fill(Theme.Colors.inkTertiary).frame(height: 1)
        }
    }

    private func spoken(_ row: WeekDayRow, isToday: Bool) -> String {
        let day = isToday ? "today" : row.id.formatted(.dateTime.weekday(.wide))
        guard let name = row.name, row.kind != .rest else { return "\(day), rest" }
        let state = row.kind == .done ? ", done" : row.isSkipped ? ", skipped" : ""
        return "\(day), \(name)\(state)"
    }

    // MARK: Brief and foot

    /// The line follows the row in front.
    @ViewBuilder
    private func briefLine(for row: WeekDayRow?) -> some View {
        if let brief {
            HStack(spacing: Theme.Spacing.m) {
                MeasureLine.text(brief.text, size: 17)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Button {
                    cue.play(.undo)
                    brief.undo()
                    self.brief = nil
                } label: {
                    Text("Undo")
                        .font(Theme.Training.words(17, weight: .semibold))
                        .foregroundStyle(Theme.Colors.Accent.training)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } else if let row {
            MeasureLine.text(line(for: row), size: 17)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.opacity)
                .tesseraAnimation(Theme.Motion.house, value: row.id)
        } else {
            Color.clear
        }
    }

    private func line(for row: WeekDayRow) -> String {
        guard let name = row.name, row.kind != .rest else { return "Rest day." }
        switch row.kind {
        case .done: return "\(name), done\(row.minutes.map { ". \($0) min." } ?? ".")"
        case .today: return row.isSkipped ? "\(name), skipped today." : "\(name) today\(row.minutes.map { ", about \($0) min." } ?? ".")"
        case .ahead: return row.isSkipped ? "\(name), skipped." : "\(name)\(row.minutes.map { ", about \($0) min." } ?? ".")"
        case .past, .rest: return "\(name)."
        }
    }

    @ViewBuilder
    private func foot(_ row: WeekDayRow?) -> some View {
        if let row, row.isMovable, let name = row.name, let index = rows.firstIndex(of: row),
           rows.indices.contains(index + 1)
        {
            ActionWord(word: "Move \(name)", left: ActionOption(name: "Skip \(name)") { skip(index, name) }) {
                move(index, name)
            }
        } else {
            Color.clear
        }
    }

    private func move(_ index: Int, _ name: String) {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { moves.append(index) }
        say("\(name), a day later.") {
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { _ = moves.popLast() }
        }
    }

    private func skip(_ index: Int, _ name: String) {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { _ = skips.insert(index) }
        say("\(name), skipped.") {
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { _ = skips.remove(index) }
        }
    }

    private func say(_ text: String, undo: @escaping () -> Void) {
        let id = UUID()
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { brief = (id, text, undo) }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(GestureTuning.undoSeconds))
            if brief?.id == id {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { brief = nil }
            }
        }
    }
}
