import SwiftUI
import TesseraCore

// MARK: - Week maths (pure)

/// Consistency and volume for the Review page. Counts days, never streaks; missed days are neutral.
enum WeekReview {
    /// Weekly working sets per muscle that count as "enough" (a common hypertrophy floor).
    static let weeklySetTarget = 10

    /// The last `count` days ending today, oldest first, each at the start of its day.
    static func lastDays(_ count: Int = 7, endingAt now: Date, calendar: Calendar) -> [Date] {
        let today = TesseraDay(calendar: calendar).today(now)
        return (0 ..< count).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    /// One flag per day: whether anything was trained that day.
    static func trainedDays(_ dates: [Date], on days: [Date], calendar: Calendar) -> [Bool] {
        let tesseraDay = TesseraDay(calendar: calendar)
        // `days` are day keys (midnights); compare each moment's own day to them.
        return days.map { day in dates.contains { tesseraDay.day(of: $0) == day } }
    }

    /// Distinct days with training among the last `days` days, today included.
    static func daysTrained(_ dates: [Date], lastDays days: Int = 7, endingAt now: Date, calendar: Calendar) -> Int {
        trainedDays(dates, on: lastDays(days, endingAt: now, calendar: calendar), calendar: calendar)
            .count(where: \.self)
    }

    /// The hero counts sessions (Research's review-sentence §4): "All six sessions in", "Four sessions this week",
    /// "Two sessions in your first week", "Your first week starts today", "A quiet week so far". Never "good", never
    /// "of seven". Returned as a lead and a tail so it can break after the number phrase, never leaving one word
    /// alone on a line.
    static func headline(sessions: Int, perWeek: Int?, firstWeek: Bool, firstUseToday: Bool)
        -> (lead: String, tail: String)
    {
        if sessions == 0 {
            return firstUseToday ? ("Your first week", "starts today") : ("A quiet week", "so far")
        }
        if let perWeek, perWeek > 0, sessions == perWeek {
            return ("All \(SpokenTime.number(perWeek))", "sessions in")
        }
        let number = SpokenTime.number(sessions)
        let lead = number.prefix(1).uppercased() + number.dropFirst()
        let noun = sessions == 1 ? "session" : "sessions"
        return (lead, firstWeek ? "\(noun) in your first week" : "\(noun) this week")
    }

    /// "Trained on 4 of the last 7 days" style plain count, for VoiceOver.
    static func sessionLine(sessions: Int, perWeek: Int?) -> String {
        perWeek.map { "\(sessions) of \($0) sessions this week" } ?? "\(sessions) sessions this week"
    }

    /// One mark a day. Rest is part of the plan: an empty day is rest when the week still meets the plan's count
    /// (done plus still planned reach it), or when Core marks it rest; else it is open. Days before first use get
    /// nothing.
    enum DayMark: Equatable {
        case trained(Int), rest, open, planned, none
    }

    /// Training marks for any day (rest, open, before first use), from the plan's week each day falls in. The full
    /// Review uses it for a rolling window that can span two plan weeks.
    @MainActor
    static func planMarks(_ model: AppModel, days: [Date], now: Date, calendar: Calendar) -> [Date: DayMark] {
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan)
        let firstUse = ReviewPage.firstUse(model)
        let restToday = NowPicker(engine: model.engine).restDay(plan: plan, at: now, sessionsPerWeek: perWeek,
                                                                calendar: calendar) != nil
        var result: [Date: DayMark] = [:]
        var seen = Set<Date>()
        for day in days {
            guard let start = calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .hour, value: 12,
                                                                                        to: day) ?? day)?.start,
                seen.insert(start).inserted else { continue }
            // Day keys are midnights, which belong to the day before in his 04:00 day: ask at noon instead.
            let noon = calendar.date(byAdding: .hour, value: 12, to: day) ?? day
            let week = model.ledger.week(containing: noon, plan: plan, now: now, sessionsPerWeek: perWeek,
                                         calendar: calendar)
            let marks = Self.marks(week.map(Slot.init), firstUse: firstUse, restToday: restToday,
                                   now: now, calendar: calendar)
            for (index, weekDay) in week.enumerated() {
                result[calendar.startOfDay(for: weekDay.day)] = marks[index]
            }
        }
        return result
    }

    /// A day of the week, as the marks need it (Core's `WeekDay`, reduced).
    struct Slot {
        let day: Date
        let sessions: Int
        let isRest: Bool
        let wasDue: Bool

        init(day: Date, sessions: Int, isRest: Bool = false, wasDue: Bool = false) {
            self.day = day
            self.sessions = sessions
            self.isRest = isRest
            self.wasDue = wasDue
        }

        @MainActor
        init(_ day: WeekDay) {
            self.init(day: day.day, sessions: day.done.count, isRest: day.isRest, wasDue: day.wasDue)
        }
    }

    /// The training week runs Monday to Sunday (Sunday's rest last), whatever the locale says.
    static var mondayFirst: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    /// Core's flags decide: a past empty day is rest where the plan (as it stood that morning) left it for rest, and
    /// open (the miss ring) only where a session was due. Days count once however many sessions they hold. Today
    /// is rest when Core says so, else unmarked; days ahead carry no mark; days before first use, nothing. His day
    /// runs to 04:00, so at 01:00 Saturday an untrained Friday is still today (R4).
    static func marks(_ week: [Slot], firstUse: Date?, restToday: Bool, now: Date, calendar: Calendar) -> [DayMark] {
        let tesseraDay = TesseraDay(calendar: calendar)
        let today = tesseraDay.today(now)
        let firstDay = firstUse.map { tesseraDay.day(of: $0) }
        return week.map { slot in
            if slot.sessions > 0 {
                return .trained(slot.sessions)
            }
            if let firstDay, slot.day < firstDay {
                return .none
            }
            if slot.day > today {
                return .planned
            }
            if slot.day == today {
                return slot.isRest || restToday ? .rest : .planned
            }
            if slot.isRest {
                return .rest
            }
            return slot.wasDue ? .open : .planned
        }
    }

    /// "Done 4 of the last 7 days" (for VoiceOver and anywhere the plain count reads better).
    static func consistencyLine(_ count: Int, of days: Int = 7) -> String {
        "Done \(count) of the last \(days) days"
    }

    /// Tess's one line, a fact and never a debt: the muscle furthest from its weekly target (over the last seven days),
    /// if any is.
    @MainActor
    static func tessLine(_ volume: [MuscleVolume], target: Int = weeklySetTarget) -> String? {
        // Only muscles trained this week: an untrained muscle out of 18 isn't "behind", it just isn't in the plan.
        let trained = volume.filter { $0.sets > 0 }
        guard let behind = trained.min(by: { $0.sets < $1.sets }), behind.sets < target else { return nil }
        let sets = behind.sets == 1 ? "1 set" : "\(behind.sets) sets"
        let name = behind.muscle.title.prefix(1).uppercased() + behind.muscle.title.dropFirst().lowercased()
        return "\(name): \(sets) this week, toward a usual \(target)."
    }
}

/// Sets per muscle, read through the object model: workout → entries → sets, entry → exercise class → its
/// profile's primary muscles (walking up the class chain, so Paused Bench Press counts like Bench Press).
struct MuscleVolume: Identifiable, Equatable {
    let id: UUID
    let muscle: ObjectRecord
    let sets: Int

    @MainActor
    init(muscle: ObjectRecord, sets: Int) {
        id = muscle.id
        self.muscle = muscle
        self.sets = sets
    }

    @MainActor
    static func compute(_ model: AppModel, in interval: DateInterval) -> [MuscleVolume] {
        var counts: [UUID: Int] = [:]
        for (workout, date) in HomeData.trainingDates(model) where interval.contains(date) {
            for entry in workout.orderedChildren {
                guard let exercise = model.store.linkedClass("exercise", of: entry) else { continue }
                let sets = entry.orderedChildren.count(where: { set in
                    model.store.number("reps", of: set) != nil && model.store.value("isWarmup", of: set) != .bool(true)
                })
                guard sets > 0 else { continue }
                for muscle in muscles(of: exercise, model: model) {
                    counts[muscle.id, default: 0] += sets
                }
            }
        }
        return model.objects(of: .muscle)
            .map { MuscleVolume(muscle: $0, sets: counts[$0.id] ?? 0) }
            .sorted { $0.sets == $1.sets ? $0.muscle.title < $1.muscle.title : $0.sets > $1.sets }
    }

    @MainActor
    static func muscles(of exercise: ClassDef, model: AppModel) -> [ObjectRecord] {
        var current: ClassDef? = exercise
        var seen = Set<UUID>()
        while let classDef = current, seen.insert(classDef.id).inserted {
            if let profile = model.prototype(of: classDef) {
                let muscles = model.store.linkedObjects("primaryMuscles", of: profile)
                if !muscles.isEmpty {
                    return muscles
                }
            }
            current = classDef.parent
        }
        return []
    }
}

// MARK: - Page

/// REVIEW as the week on one page (review-week.md): the day letters, one band per thing with its week figure at the
/// right and a mark per day under it, then the week's best lines. Tap a day and the page reads that day: the other
/// columns recede, the hero and the lines become the day's. No rules, no boxes: the columns align by the letters.
struct ReviewPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The column being read, if any.
    @State private var reading: Int?
    @State private var taps = 0

    /// When Tessera was first used: the starter plan is seeded on first launch; older history (an import) wins.
    static func firstUse(_ model: AppModel) -> Date? {
        let workout = model.objects(of: .workout).compactMap { model.store.value("startedAt", of: $0)?.dateValue }.min()
        return [model.plan?.createdAt, workout].compactMap(\.self).min()
    }

    var body: some View {
        let _ = model.revision
        let week = ReviewWeekData.compute(model, now: AppClock.now, calendar: WeekReview.mondayFirst)
        let day = reading.map { week.day($0) }

        VStack(alignment: .leading, spacing: 0) {
            Text(day?.name ?? "the week so far")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .padding(.bottom, Theme.Spacing.m)
                .contentTransition(.opacity)
                .entrance(0)

            // Title 44, one line: the session count, or the day's own line in the longest form that fits.
            ViewThatFits(in: .horizontal) {
                ForEach(day?.heroForms ?? [week.headline], id: \.self) { form in
                    Text(form).lineLimit(1).fixedSize(horizontal: true, vertical: false)
                }
            }
            .textRole(.title)
            .foregroundStyle(Theme.Colors.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(day?.hero ?? "\(week.headline). \(week.sessionLine).")
            .contentTransition(.opacity)
            .siblingParallax()
            .entrance(1, hero: true)
            .padding(.bottom, Theme.Spacing.l)

            DayLetters(week: week, reading: reading, read: read)
                .padding(.bottom, Theme.Spacing.s)
                .entrance(2)

            WeekBand(label: "Training", figure: week.trainingFigure, height: 58, reading: reading, read: read,
                     spoken: week.trainingSpoken)
            { index in
                DayMarkView(mark: week.marks[index], seed: index, delay: 0.1 + Double(index) * 0.03)
                    .frame(width: 34, height: 30)
                    // A dab opens its session once the day is being read; the first tap reads the day.
                    .onTapGesture {
                        if reading == index, let workout = week.sessions[index].first {
                            model.open(.object(workout.id))
                        } else {
                            read(index)
                        }
                    }
            }
            .entrance(3)

            WeekBand(
                label: "Tasks done",
                figure: String(week.tasksDone.compactMap(\.self).reduce(0, +)),
                height: 54,
                reading: reading,
                read: read,
                spoken: week.tasksSpoken
            ) { index in
                WeekNumeral(value: week.tasksDone[index].map(String.init), muted: !week.isPast(index))
            }
            .entrance(4)

            if week.cooked.contains(where: { ($0 ?? 0) > 0 }) {
                WeekBand(label: "Cooked", figure: String(week.cooked.compactMap(\.self).reduce(0, +)), height: 54,
                         reading: reading, read: read, spoken: week.cookedSpoken)
                { index in
                    if (week.cooked[index] ?? 0) > 0 {
                        PaintDab(color: Theme.Colors.restTint(Theme.Colors.now), size: CGSize(width: 30, height: 26),
                                 seed: index + 7)
                    }
                }
                .transition(.opacity)
                .entrance(5)
            }

            WeekLines(title: day?.name.uppercased() ?? "The week’s lines",
                      rows: day?.lines ?? week.bestLines, calendar: WeekReview.mondayFirst)
                .id(day?.name ?? "week")
                .transition(.opacity)
                .padding(.top, Theme.Spacing.m)
                .entrance(6)

            Spacer(minLength: 0)
        }
        .tesseraAnimation(Theme.Motion.house, value: reading)
        .sensoryFeedback(.selection, trigger: taps)
        .contentShape(Rectangle())
        // Tap anywhere else and the week comes back.
        .onTapGesture {
            guard reading != nil else { return }
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { reading = nil }
        }
    }

    /// Reads a day; the same day again, or a day still ahead, returns to the week.
    private func read(_ index: Int) {
        taps += 1
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            reading = reading == index ? nil : index
        }
    }
}

/// The hero at 56, breaking after the number phrase when one line won't fit ("All six / sessions in"). A new
/// count fades out with a 4 pt blur and the next fades in; there's no celebration, the sentence is the reward.
struct ReviewHeadline: View {
    let text: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Lines in two-word pairs (three on the first line when the count is odd), so none holds one word alone.
    private var pairs: [String] {
        var words = text.split(separator: " ").map(String.init)
        var lines: [String] = []
        if words.count % 2 == 1, words.count > 1 {
            lines.append(words.prefix(3).joined(separator: " "))
            words.removeFirst(3)
        }
        while !words.isEmpty {
            lines.append(words.prefix(2).joined(separator: " "))
            words.removeFirst(min(2, words.count))
        }
        return lines
    }

    var body: some View {
        // One line; else break before the last two words ("Four sessions / this week", "All six / sessions in");
        // else two-word lines. No line ever holds one word alone.
        let words = text.split(separator: " ").map(String.init)
        ViewThatFits(in: .horizontal) {
            Text(text).lineLimit(1)
            VStack(alignment: .leading, spacing: 0) {
                Text(words.dropLast(2).joined(separator: " ")).lineLimit(1)
                Text(words.suffix(2).joined(separator: " ")).lineLimit(1)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(pairs.enumerated()), id: \.offset) { _, line in
                    Text(line).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .textRole(.hero)
        .foregroundStyle(Theme.Colors.ink)
        .id(text)
        .transition(reduceMotion ? .opacity : .asymmetric(
            insertion: .opacity.animation(.easeOut(duration: 0.22).delay(0.16)),
            removal: .modifier(active: BlurFade(blur: 4, opacity: 0), identity: BlurFade(blur: 0, opacity: 1))
                .animation(.easeIn(duration: 0.16))
        ))
    }
}

private struct BlurFade: ViewModifier {
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content.blur(radius: blur).opacity(opacity)
    }
}

/// One day's mark in its 34×30 slot (shared by Home's Review page and the full Review screen).
struct DayMarkView: View {
    let mark: WeekReview.DayMark
    let seed: Int
    /// When its draw-in starts (the row's pop stagger).
    var delay: Double = 0.1

    var body: some View {
        switch mark {
        case let .trained(count):
            TrainedMark(count: count, seed: seed, delay: delay)
        case .rest:
            RestMark(seed: seed, delay: delay)
        case .open:
            PaintDab(color: Theme.Colors.ink.opacity(0.25), size: CGSize(width: 34, height: 30), seed: seed,
                     filled: false)
        case .planned, .none:
            Color.clear
        }
    }
}

/// A trained day: the sage dab lands wet at full pigment, then dries to its rest tint (no-dots.md).
private struct TrainedMark: View {
    let count: Int
    let seed: Int
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dried = false

    var body: some View {
        let pigment = dried ? Theme.Colors.restTint(Theme.Colors.health) : Theme.Colors.health
        ZStack(alignment: .topTrailing) {
            PaintDab(color: pigment, size: CGSize(width: 34, height: 30), seed: seed)
            if count > 1 {
                PaintDab(color: pigment, size: CGSize(width: 16, height: 14), seed: seed + 3)
                    .offset(x: 8, y: -6)
            }
        }
        .onAppear {
            guard let dry = Theme.Motion.dry(reduceMotion: reduceMotion) else {
                dried = true
                return
            }
            withAnimation(dry.delay(delay)) { dried = true }
        }
    }
}

/// Rest: a short dry ink stroke at 50% across the slot's lower half (32×5 at y 15–21), the same horizon as the
/// rest timer. It draws in left to right (280 ms) as the row arrives.
private struct RestMark: View {
    let seed: Int
    var delay: Double = 0.1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn = false

    var body: some View {
        RestStroke(seed: seed)
            .fill(Theme.Colors.ink.opacity(0.5))
            .frame(width: 32, height: 6)
            // Dry brush: the paint breaks up along the stroke, a little differently each day.
            .mask(DryBreakUp(seed: seed))
            .mask(alignment: .leading) {
                Rectangle().frame(width: drawn || reduceMotion ? 32 : 0)
            }
            .frame(width: 34, height: 30, alignment: .top)
            .padding(.top, 15)
            .frame(width: 34, height: 30, alignment: .top)
            .opacity(drawn || !reduceMotion ? 1 : 0)
            .onAppear {
                withTesseraAnimation(.easeOut(duration: 0.28).delay(delay), reduceMotion: reduceMotion) {
                    drawn = true
                }
            }
    }
}

/// Dry brush: bristle streaks running along the stroke (noise high in y, low in x), seeded per day, softening at the
/// ends.
private struct DryBreakUp: View {
    let seed: Int

    var body: some View {
        Canvas { context, size in
            let streaks = 6
            let height = size.height / CGFloat(streaks)
            for streak in 0 ..< streaks {
                let noise = Double((streak * 5 + seed * 11) % 7) / 6
                // A streak may stop short at either end, like a bristle running dry.
                let inset = CGFloat((streak + seed) % 4) * size.width * 0.06
                let rect = CGRect(x: inset, y: CGFloat(streak) * height,
                                  width: size.width - inset * (streak % 2 == 0 ? 1 : 2), height: height + 0.3)
                context.fill(Path(rect), with: .color(.black.opacity(0.5 + 0.5 * noise)))
            }
        }
        .mask(LinearGradient(
            stops: [.init(color: .black.opacity(0.6), location: 0), .init(color: .black, location: 0.15),
                    .init(color: .black, location: 0.85), .init(
                        color: .black.opacity(0.6),
                        location: 1
                    )],
            startPoint: .leading,
            endPoint: .trailing
        ))
    }
}

/// A filled dry stroke: 5 pt at the middle tapering to 3.5 at the ends, with a slightly ragged edge per seed.
struct RestStroke: Shape {
    var seed: Int

    func path(in rect: CGRect) -> Path {
        let jitter: [CGFloat] = [0.0, 0.25, -0.2, 0.15, -0.1, 0.3, -0.25, 0.05]
        func wobble(_ index: Int) -> CGFloat {
            jitter[(index + seed) % jitter.count] * rect.height * 0.25
        }
        let mid = rect.midY, half = rect.height / 2, end = rect.height * 0.35
        let steps = 6
        var top: [CGPoint] = []
        var bottom: [CGPoint] = []
        for step in 0 ... steps {
            let progress = CGFloat(step) / CGFloat(steps)
            let x = rect.minX + rect.width * progress
            let taper = end + (half - end) * sin(.pi * progress)
            top.append(CGPoint(x: x, y: mid - taper + wobble(step)))
            bottom.append(CGPoint(x: x, y: mid + taper + wobble(step + 3)))
        }
        var path = Path()
        path.move(to: top[0])
        top.dropFirst().forEach { path.addLine(to: $0) }
        bottom.reversed().forEach { path.addLine(to: $0) }
        path.closeSubpath()
        return path
    }
}
