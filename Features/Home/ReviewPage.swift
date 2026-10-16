import SwiftUI
import TesseraCore

// MARK: - Week maths (pure)

/// Consistency and volume for the Review page. Counts days, never streaks; missed days are neutral.
enum WeekReview {
    /// Weekly working sets per muscle that count as "enough" (a common hypertrophy floor).
    static let weeklySetTarget = 10

    /// The last `count` days ending today, oldest first, each at the start of its day.
    static func lastDays(_ count: Int = 7, endingAt now: Date, calendar: Calendar) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0 ..< count).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    /// One flag per day: whether anything was trained that day.
    static func trainedDays(_ dates: [Date], on days: [Date], calendar: Calendar) -> [Bool] {
        days.map { day in dates.contains { calendar.isDate($0, inSameDayAs: day) } }
    }

    /// Distinct days with training among the last `days` days, today included.
    static func daysTrained(_ dates: [Date], lastDays days: Int = 7, endingAt now: Date, calendar: Calendar) -> Int {
        trainedDays(dates, on: lastDays(days, endingAt: now, calendar: calendar), calendar: calendar)
            .count(where: \.self)
    }

    /// The hero sentence: "Four good days of seven", "A quiet week so far".
    static func headline(_ count: Int, of days: Int = 7) -> String {
        guard count > 0 else { return "A quiet week so far" }
        let number = SpokenTime.number(count)
        let noun = count == 1 ? "good day" : "good days"
        return "\(number.prefix(1).uppercased())\(number.dropFirst()) \(noun) of \(SpokenTime.number(days))"
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
        case trained(Int), rest, open, none
    }

    /// A day of the week, as the marks need it (Core's `WeekDay`, reduced).
    struct Slot {
        let day: Date
        let sessions: Int
        let isRest: Bool
        let isPlanned: Bool

        init(day: Date, sessions: Int, isRest: Bool = false, isPlanned: Bool = false) {
            self.day = day
            self.sessions = sessions
            self.isRest = isRest
            self.isPlanned = isPlanned
        }

        @MainActor
        init(_ day: WeekDay) {
            self.init(day: day.day, sessions: day.done.count, isRest: day.isRest, isPlanned: day.planned != nil)
        }
    }

    static func marks(_ week: [Slot], perWeek: Int?, firstUse: Date?, restToday: Bool, now: Date,
                      calendar: Calendar) -> [DayMark]
    {
        let done = week.reduce(0) { $0 + $1.sessions }
        let ahead = week.count { $0.sessions == 0 && $0.isPlanned }
        let meets = perWeek.map { done + ahead >= $0 } ?? false
        let firstDay = firstUse.map { calendar.startOfDay(for: $0) }
        return week.map { day in
            if day.sessions > 0 {
                return .trained(day.sessions)
            }
            if let firstDay, day.day < firstDay {
                return .none
            }
            let isToday = calendar.isDate(day.day, inSameDayAs: now)
            if day.isRest || (isToday && restToday) || (meets && !day.isPlanned) {
                return .rest
            }
            return .open
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
        return "\(behind.muscle.title): \(sets) this week, toward a usual \(target)."
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
        let calendar = Calendar.current
        // The plan's week from Core: done days carry their workouts, days ahead carry the plan or a rest day.
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan)
        let week = model.ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: perWeek,
                                     calendar: calendar)
        let sessions = week.reduce(0) { $0 + $1.done.count }
        let firstUse = Self.firstUse(model)
        let firstWeek = firstUse.map { use in week.first.map { use >= $0.day } ?? false } ?? false
        let firstUseToday = firstUse.map { calendar.isDate($0, inSameDayAs: now) } ?? false
        let restToday = NowPicker(engine: model.engine).restDay(plan: plan, at: now, sessionsPerWeek: perWeek,
                                                                calendar: calendar) != nil
        let marks = WeekReview.marks(
            week.map(WeekReview.Slot.init),
            perWeek: perWeek,
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

            ReviewHeadline(lead: headline.lead, tail: headline.tail)
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
                .entrance(2)
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
private struct ReviewHeadline: View {
    let lead: String
    let tail: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Text("\(lead) \(tail)").lineLimit(1)
            VStack(alignment: .leading, spacing: 0) {
                Text(lead)
                Text(tail).fixedSize(horizontal: false, vertical: true)
            }
        }
        .textRole(.hero)
        .foregroundStyle(Theme.Colors.ink)
        .id(lead + tail)
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

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(week.enumerated()), id: \.offset) { index, day in
                let isToday = calendar.isDate(day.day, inSameDayAs: now)
                let mark = marks[index]
                VStack(spacing: Theme.Spacing.s) {
                    markView(mark, seed: index)
                        .frame(width: 34, height: 30)
                    Text(day.day.formatted(.dateTime.weekday(.narrow)))
                        .textRole(.label)
                        .foregroundStyle(mark == .none ? Theme.Colors.inkTertiary
                            : isToday ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label(day, mark: mark))
                .accessibilityHidden(mark == .none)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func markView(_ mark: WeekReview.DayMark, seed: Int) -> some View {
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
            RestMark(seed: seed)
        case .open:
            PaintDab(color: Theme.Colors.ink.opacity(0.25), size: CGSize(width: 34, height: 30), seed: seed,
                     filled: false)
        case .none:
            Color.clear
        }
    }

    private func label(_ day: WeekDay, mark: WeekReview.DayMark) -> String {
        let name = day.day.formatted(.dateTime.weekday(.wide))
        return switch mark {
        case .trained(1): "\(name), trained"
        case let .trained(count): "\(name), trained, \(count) sessions"
        case .rest: "\(name), rest"
        case .open, .none: "\(name), open"
        }
    }
}

/// Rest: a short dry ink stroke at 50% across the slot's lower half (32×5 at y 15–21), the same horizon as the
/// rest timer. It draws in left to right (280 ms) as the row arrives.
private struct RestMark: View {
    let seed: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn = false

    var body: some View {
        RestStroke(seed: seed)
            .fill(Theme.Colors.ink.opacity(0.5))
            .frame(width: 32, height: 5)
            .blur(radius: 0.3)
            .scaleEffect(x: drawn || reduceMotion ? 1 : 0.01, anchor: .leading)
            .opacity(drawn || !reduceMotion ? 1 : 0)
            .offset(y: 3)
            .onAppear {
                withTesseraAnimation(.spring(Spring(duration: 0.28, bounce: 0)).delay(0.1),
                                     reduceMotion: reduceMotion) { drawn = true }
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
