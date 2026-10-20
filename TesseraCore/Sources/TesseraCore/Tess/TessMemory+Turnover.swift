import Foundation

/// The 04:00 turnover: the forget log, yesterday's day line, the 14-day cut, and on Sundays the noticed lines, all
/// counted on the phone (architecture section 4).
@MainActor
public extension TessMemoryStore {
    // MARK: The turnover

    /// What the 04:00 turnover did.
    struct Turnover: Equatable, Sendable {
        public var wroteRecent = false
        public var recomputedNoticed = false
    }

    /// Run once a day after 04:00 (the app calls it with its other tidying; idempotent within a day): the forget log,
    /// yesterday's recent line, the 14-day cut, and on Sundays the noticed lines.
    @discardableResult
    func turnover(now: Date = .now) -> Turnover {
        var result = Turnover()
        let day = TesseraDay(calendar: calendar)
        // Once per 04:00 day (QA L1): the app calls this on every launch and foreground.
        // Keyed by the calendar day, not an absolute midnight: on a 27-hour travel day the midnight moves with the
        // zone and the turnover would run twice (Research 127 T3).
        let key = ObjectIdentifier(store.context)
        let todayKey = Self.dayLabel(day.today(now), calendar: calendar)
        guard Self.lastTurnoverDay[key] != todayKey else { return result }
        Self.lastTurnoverDay[key] = todayKey
        let yesterday = day.day(-1, after: now)
        let yesterdayKey = Self.dayLabel(yesterday, calendar: calendar)
        let recent = lines(of: .recent)
        sweepForgotten(now: now)
        let written = recent.contains { $0.day.map { Self.dayLabel($0, calendar: calendar) } == yesterdayKey }
        if !written, let text = recentLine(for: yesterday, now: now) {
            let rule = "recent.\(yesterdayKey)"
            result.wroteRecent = write(kind: .recent, area: .days, text: text, evidence: [], day: yesterday,
                                       rule: rule) != nil
        }
        foldRecent(now: now)
        // Sundays, or the first time ever (a forgotten rule counts as computed: it stays quiet).
        if calendar.component(.weekday, from: day.today(now)) == 1
            || (lines(of: .noticed).isEmpty && suppressedRules().isEmpty)
        {
            recomputeNoticed(now: now)
            result.recomputedNoticed = true
        }
        return result
    }

    /// The day the turnover last ran in this process; the data itself is idempotent across launches.
    nonisolated(unsafe) static var lastTurnoverDay: [ObjectIdentifier: String] = [:]

    /// "2026-10-21": the day as a label, the same in every zone he reads it from.
    static func dayLabel(_ key: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: key)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// "Wed: Pull A done, 2 tasks, cooked chili." Counts and titles from the Day log; nil for an empty day.
    func recentLine(for dayKey: Date, now: Date) -> String? {
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: dayKey) ?? dayKey
        let lines = DayStory.lines(engine: engine, on: noon, calendar: calendar, now: now)
            .filter { $0.kind == .finished }
        guard !lines.isEmpty else { return nil }
        var parts: [String] = []
        // Second guard (Research 134 SW2): a private note, or any older note holding a secret word, never reaches
        // a memory line, so it can never reach a pack.
        // Third guard (board 0ai): a money or body-weight line never reaches memory either.
        let lastKg = BodyWeight.lastKg(in: engine.store)
        // Fourth guard: a spend line ("Spent ...") is money and never becomes a memory line, and a private book
        // ("Private book") has nothing to remember. Reading lines ("read dune to p 142") are fine.
        for line in lines where line.text != SecretWords.title && !SecretWords.mentions(line.text)
            && !PrivateFacts.isWalled(line.text, lastWeightKg: lastKg) && !line.text.hasPrefix("Spent ")
            && !line.text.contains(ObjectPrivacy.bookLabel)
        {
            var text = line.text
            let workout = text.contains(" min") || text.hasSuffix(" sets.")
            if let cut = text.range(of: ", "), workout || text.hasPrefix("Cooked ") {
                text = String(text[..<cut.lowerBound])
            }
            if text.hasPrefix("Cooked ") {
                text = "cooked " + text.dropFirst("Cooked ".count).lowercased()
            } else if workout {
                text += " done"
            } else {
                text = text.replacingOccurrences(of: "Added ", with: "").replacingOccurrences(
                    of: "Done: ",
                    with: "done "
                )
                .lowercased()
            }
            parts.append(text.trimmingCharacters(in: CharacterSet(charactersIn: ". ")))
        }
        // Every line of the day was kept out of memory: nothing to remember ("Tue: ." is not a line).
        guard !parts.isEmpty else { return nil }
        let weekday = Weekdays.short[calendar.component(.weekday, from: noon) - 1]
        var text = "\(weekday): \(parts.joined(separator: ", "))."
        if text.count > TessMemory.maxTextLength {
            // Cut at a word, never mid-word.
            // Whole parts only: "Thu: Push A done, 2 tasks." rather than "…, cooked."
            var kept = parts
            while kept.count > 1, "\(weekday): \(kept.joined(separator: ", ")).".count > TessMemory.maxTextLength {
                kept.removeLast()
            }
            text = "\(weekday): \(kept.joined(separator: ", "))."
            if text.count > TessMemory.maxTextLength {
                var cut = String(text.prefix(TessMemory.maxTextLength - 1))
                if let space = cut.lastIndex(of: " ") {
                    cut = String(cut[..<space])
                }
                text = cut.trimmingCharacters(in: CharacterSet(charactersIn: " ,")) + "."
            }
        }
        return TessMemoryScreen.refusal(for: text, numbers: Set(HomeLines.digits(in: text))) == nil ? text : nil
    }

    /// Day lines older than 14 days go; the week is never stored (WeekFacts counts it live; AI thread S1).
    func foldRecent(now: Date) {
        let day = TesseraDay(calendar: calendar)
        let cutoff = day.day(-TessMemory.recentDays, after: now)
        for old in lines(of: .recent) where (old.day ?? old.createdAt) < cutoff {
            remove(old.id)
        }
    }

    // MARK: Noticed (counted on the phone, never by Claude)

    /// Replaces the noticed lines with what the last six weeks show: when he trains, how many days a week, which day
    /// he cooks most. Each needs enough evidence to be a pattern, and every number in a line is one it counted.
    func recomputeNoticed(now: Date) {
        // Each rule's line is updated in place (same id; QA T9); a rule that no longer holds is let go without being
        // marked as forgotten, so it can come back when the pattern does.
        let before = Set(lines(of: .noticed).map(\.id))
        let since = now.addingTimeInterval(-42 * 86400)
        var kept = Set<UUID>()
        defer {
            for old in lines(of: .noticed) where before.contains(old.id) && !kept.contains(old.id) {
                if let object = store.object(id: old.id) {
                    try? store.set("rule", to: nil, on: object)
                }
                remove(old.id)
            }
        }
        guard let workoutClass = engine.classes[.workout] else { return }
        let workouts = store.objects(of: workoutClass).filter { workout in
            guard !workout.isDeleted, let started = store.value("startedAt", of: workout)?.dateValue,
                  store.value("endedAt", of: workout) != nil else { return false }
            return started >= since && started <= now
        }
        kept.formUnion(noticeTraining(workouts, now: now).map(\.id))
        kept.formUnion(noticeCooking(since: since, now: now).map(\.id))
    }

    /// The training lines written or refreshed.
    func noticeTraining(_ workouts: [ObjectRecord], now: Date) -> [ObjectRecord] {
        var written: [ObjectRecord?] = []
        defer { _ = written }
        let starts = workouts.compactMap { store.value("startedAt", of: $0)?.dateValue }
        if starts.count >= 4 {
            // The two-hour window around the usual hour, when it holds at least 60% of the starts.
            let hours = starts.map { calendar.component(.hour, from: $0) }
            let counts = Dictionary(grouping: hours, by: { $0 }).mapValues(\.count)
            let mode = counts.max { ($0.value, $0.key) < ($1.value, $1.key) }?.key ?? 18
            let best = (counts[mode + 1] ?? 0) >= (counts[mode - 1] ?? 0) ? mode : mode - 1
            if Double(hours.count { $0 == best || $0 == best + 1 }) >= Double(hours.count) * 0.6 {
                let text = "You usually train \(Self.clock(best)) to \(Self.clock(best + 2))."
                written.append(write(kind: .noticed, area: .training, text: text, evidence: workouts.map(\.id),
                                     day: nil, numbers: [best % 12 == 0 ? 12 : best % 12,
                                                         (best + 2) % 12 == 0 ? 12 : (best + 2) % 12],
                                     rule: "training.hours"))
            }
            // Weeks from his days, not elapsed seconds: two weeks across the fall-back night are 2, not 3 (DS36).
            let tesseraDay = TesseraDay(calendar: calendar)
            let days = calendar.dateComponents([.day], from: tesseraDay.day(of: starts.min() ?? now),
                                               to: tesseraDay.day(of: now)).day ?? 0
            let weeks = max(1, Int((Double(days) / 7).rounded(.up)))
            if weeks >= 2 {
                let perWeek = Int((Double(starts.count) / Double(weeks)).rounded())
                if perWeek >= 1 {
                    written.append(write(
                        kind: .noticed,
                        area: .training,
                        text: "You train about \(perWeek) \(perWeek == 1 ? "day" : "days") a week.",
                        evidence: workouts.map(\.id),
                        day: nil,
                        numbers: [perWeek], rule: "training.perWeek"
                    ))
                }
            }
        }
        return written.compactMap(\.self)
    }

    /// The kitchen line written or refreshed.
    func noticeCooking(since: Date, now: Date) -> [ObjectRecord] {
        guard let cookClass = engine.classes[.cook] else { return [] }
        let cooks = store.objects(of: cookClass).filter { cook in
            guard !cook.isDeleted, let at = store.value("cookedAt", of: cook)?.dateValue else { return false }
            return at >= since && at <= now
        }
        if cooks.count >= 3 {
            let weekdays = cooks.compactMap { store.value("cookedAt", of: $0)?.dateValue }
                // The weekday of his day: a Friday-night cook at 12:30 am is a Friday (TW27).
                .map { calendar.component(.weekday, from: TesseraDay(calendar: calendar).day(of: $0)) }
            if let top = Dictionary(grouping: weekdays, by: { $0 }).max(by: { $0.value.count < $1.value.count }),
               Double(top.value.count) >= Double(weekdays.count) * 0.5
            {
                return [write(kind: .noticed, area: .kitchen, text: "You cook most on \(Weekdays.name(top.key))s.",
                              evidence: cooks.map(\.id), day: nil, rule: "kitchen.cookDay")].compactMap(\.self)
            }
        }
        return []
    }

    static func clock(_ hour: Int) -> String {
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        return "\(twelve) \(hour % 24 < 12 ? "am" : "pm")"
    }
}
