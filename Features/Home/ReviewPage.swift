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
        return days.map { day in dates.contains { tesseraDay.isSameDay($0, day) } }
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

/// REVIEW: "the week so far", a sentence instead of a chart, seven day dabs and one line from Tess.
struct ReviewPage: View {
    @Environment(AppModel.self) private var model

    /// When Tessera was first used: the starter plan is seeded on first launch; older history (an import) wins.
    static func firstUse(_ model: AppModel) -> Date? {
        let workout = model.objects(of: .workout).compactMap { model.store.value("startedAt", of: $0)?.dateValue }.min()
        return [model.plan?.createdAt, workout].compactMap(\.self).min()
    }

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let calendar = WeekReview.mondayFirst
        // The plan's week from Core: done days carry their workouts, days ahead carry the plan or a rest day.
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan)
        let week = model.ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: perWeek,
                                     calendar: calendar)
        let sessions = week.reduce(0) { $0 + $1.done.count }
        let firstUse = Self.firstUse(model)
        let firstWeek = firstUse.map { use in week.first.map { use >= $0.day } ?? false } ?? false
        let firstUseToday = firstUse.map { TesseraDay(calendar: calendar).isSameDay($0, now) } ?? false
        let restToday = NowPicker(engine: model.engine).restDay(plan: plan, at: now, sessionsPerWeek: perWeek,
                                                                calendar: calendar) != nil
        let marks = WeekReview.marks(
            week.map(WeekReview.Slot.init),
            firstUse: firstUse,
            restToday: restToday,
            now: now,
            calendar: calendar
        )
        let headline = WeekReview.headline(sessions: sessions, perWeek: perWeek, firstWeek: firstWeek,
                                           firstUseToday: firstUseToday)
        let window = week.first.map { DateInterval(start: $0.day, end: now) }
        let volume = window.map { MuscleVolume.compute(model, in: $0) } ?? []

        VStack(alignment: .leading, spacing: 0) {
            Text("the week so far")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .padding(.bottom, Theme.Spacing.m)
                .entrance(0)

            ReviewHeadline(text: "\(headline.lead) \(headline.tail)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(
                    "\(headline.lead) \(headline.tail). \(WeekReview.sessionLine(sessions: sessions, perWeek: perWeek))."
                )
                .siblingParallax()
                .entrance(1, hero: true)
                .padding(.bottom, Theme.Spacing.xxl)

            DayDabs(week: week, marks: marks, now: now, calendar: calendar)
                .padding(.bottom, Theme.Spacing.xxl)

            if sessions > 3, let line = WeekReview.tessLine(volume) {
                Text(line)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.tess)
                    .fixedSize(horizontal: false, vertical: true)
                    .entrance(3)
            }

            Spacer(minLength: 0)
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

/// The week, one mark a day in a 34×30 slot with the letter under it: trained is the sage dab (a second small dab
/// for a second session), rest is a short dry ink stroke on the rest-timer horizon, open is the faint 25% ring,
/// and days before first use stay empty. Never red, never a score.
private struct DayDabs: View {
    let week: [WeekDay]
    let marks: [WeekReview.DayMark]
    let now: Date
    let calendar: Calendar
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(week.enumerated()), id: \.offset) { index, day in
                let isToday = day.day == TesseraDay(calendar: calendar).today(now)
                let mark = marks[index]
                VStack(spacing: Theme.Spacing.s) {
                    // The existing pop stagger: each mark arrives 50 ms after the one before.
                    DayMarkView(mark: mark, seed: index, delay: 0.1 + Double(index) * 0.05)
                        .frame(width: 34, height: 30)
                        .scaleEffect(shown || reduceMotion ? 1 : 0.8)
                        .opacity(shown || reduceMotion ? 1 : 0)
                        .animation(reduceMotion ? nil : Theme.Motion.house.delay(Double(index) * 0.05),
                                   value: shown)
                    Text(day.day.formatted(.dateTime.weekday(.narrow)))
                        .textRole(.label)
                        .foregroundStyle(mark == .none || mark == .planned ? Theme.Colors.inkTertiary
                            : isToday ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label(day, mark: mark))
                .accessibilityHidden(mark == .none)
            }
        }
        .accessibilityElement(children: .contain)
        .onAppear { shown = true }
    }

    private func label(_ day: WeekDay, mark: WeekReview.DayMark) -> String {
        let name = day.day.formatted(.dateTime.weekday(.wide))
        return switch mark {
        case .trained(1): "\(name), trained"
        case let .trained(count): "\(name), trained, \(count) sessions"
        case .rest: "\(name), rest"
        case .planned: "\(name), planned"
        case .open, .none: "\(name), open"
        }
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
            ZStack(alignment: .topTrailing) {
                PaintDab(color: Theme.Colors.health, size: CGSize(width: 34, height: 30), seed: seed)
                if count > 1 {
                    PaintDab(color: Theme.Colors.health.opacity(0.8), size: CGSize(width: 16, height: 14),
                             seed: seed + 3)
                        .offset(x: 8, y: -6)
                }
            }
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

/// Opacity noise along a stroke: thin vertical bands from 55% to 100%, seeded per day.
private struct DryBreakUp: View {
    let seed: Int

    var body: some View {
        Canvas { context, size in
            let bands = 16
            let width = size.width / CGFloat(bands)
            for band in 0 ..< bands {
                let noise = Double((band * 7 + seed * 13) % 9) / 8
                let rect = CGRect(x: CGFloat(band) * width, y: 0, width: width + 0.5, height: size.height)
                context.fill(Path(rect), with: .color(.black.opacity(0.55 + 0.45 * noise)))
                if (band + seed) % 5 == 0 {
                    let gap = CGRect(x: CGFloat(band) * width + width * 0.3, y: size.height * 0.55,
                                     width: width * 0.5, height: size.height * 0.45)
                    context.blendMode = .clear
                    context.fill(Path(gap), with: .color(.black))
                    context.blendMode = .normal
                }
            }
        }
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
