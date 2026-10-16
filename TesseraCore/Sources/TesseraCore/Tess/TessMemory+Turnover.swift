import Foundation

/// The 04:00 turnover: yesterday's day line, the 14-day fold, the 40 cap, and on Sundays the noticed lines, all counted
/// on the phone (architecture section 4).
@MainActor
public extension TessMemoryStore {
    // MARK: The turnover

    /// What the 04:00 turnover did, for Tess's one-time lines.
    struct Turnover: Equatable, Sendable {
        /// A told line let go to make room: "I let one go to make room: Tacos means the sheet-pan tacos."
        public var dropped: String?
        public var wroteRecent = false
        public var recomputedNoticed = false
    }

    /// Run once a day after 04:00 (the app calls it with its other tidying; idempotent within a day): yesterday's
    /// recent line, the 14-day fold, the 40 cap, and on Sundays the noticed lines.
    @discardableResult
    func turnover(now: Date = .now) -> Turnover {
        var result = Turnover()
        let day = TesseraDay(calendar: calendar)
        let yesterday = day.day(-1, after: now)
        let recent = lines(of: .recent)
        if !recent.contains(where: { $0.day == yesterday }), let text = recentLine(for: yesterday, now: now) {
            write(kind: .recent, area: .days, text: text, evidence: [], day: yesterday)
            result.wroteRecent = true
        }
        foldRecent(now: now)
        if calendar.component(.weekday, from: day.today(now)) == 1 || lines(of: .noticed).isEmpty {
            recomputeNoticed(now: now)
            result.recomputedNoticed = true
        }
        result.dropped = trimTold(now: now)
        return result
    }

    /// "Wed: Pull A done, 2 tasks, cooked chili." Counts and titles from the Day log; nil for an empty day.
    func recentLine(for dayKey: Date, now: Date) -> String? {
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: dayKey) ?? dayKey
        let lines = DayStory.lines(engine: engine, on: noon, calendar: calendar, now: now)
            .filter { $0.kind == .finished }
        guard !lines.isEmpty else { return nil }
        var parts: [String] = []
        for line in lines {
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
        let weekday = Weekdays.short[calendar.component(.weekday, from: noon) - 1]
        var text = "\(weekday): \(parts.joined(separator: ", "))."
        if text.count > TessMemory.maxTextLength {
            text = String(text.prefix(TessMemory.maxTextLength - 1)).trimmingCharacters(in: .whitespaces) + "."
        }
        return TessMemoryScreen.refusal(for: text, numbers: Set(HomeLines.digits(in: text))) == nil ? text : nil
    }

    /// Day lines older than 14 days fold into one week line ("Week of Oct 5: trained 3 days, cooked twice."), kept
    /// 8 weeks; older week lines go.
    func foldRecent(now: Date) {
        let day = TesseraDay(calendar: calendar)
        let cutoff = day.day(-TessMemory.recentDays, after: now)
        let old = lines(of: .recent).filter { ($0.day ?? $0.createdAt) < cutoff }
        let days = old.filter { !$0.text.hasPrefix("Week of ") }
        for (monday, lines) in Dictionary(grouping: days, by: { day.week(containing: $0.day ?? $0.createdAt).start }) {
            let trained = lines.count { $0.text.contains(" done") }
            let cooked = lines.count { $0.text.contains("cooked ") }
            let label = monday.formatted(.dateTime.month(.abbreviated).day().locale(Locale(identifier: "en_US")))
            var parts: [String] = []
            if trained > 0 {
                parts.append("trained \(trained) \(trained == 1 ? "day" : "days")")
            }
            if cooked > 0 {
                parts.append("cooked \(cooked == 1 ? "once" : cooked == 2 ? "twice" : "\(cooked) times")")
            }
            let text = "Week of \(label): \(parts.isEmpty ? "quiet" : parts.joined(separator: ", "))."
            write(kind: .recent, area: .days, text: text, evidence: lines.flatMap(\.evidence), day: monday)
            for line in lines {
                remove(line.id)
            }
        }
        let weekCutoff = day.day(-7 * TessMemory.weekLinesKept, after: now)
        for week in lines(of: .recent)
            where week.text.hasPrefix("Week of ") && (week.day ?? week.createdAt) < weekCutoff
        {
            remove(week.id)
        }
    }

    /// At the cap, the oldest told line not used in 90 days drops; returns its words for Tess's one-time line.
    func trimTold(now: Date) -> String? {
        let told = lines(of: .told)
        guard told.count > TessMemory.toldCap else { return nil }
        let stale = told
            .filter { !$0.pinned && now.timeIntervalSince($0.lastUsedAt ?? $0.createdAt) > TessMemory.unusedDropAfter }
            .sorted { ($0.lastUsedAt ?? $0.createdAt) < ($1.lastUsedAt ?? $1.createdAt) }
        guard let oldest = stale.first else { return nil }
        remove(oldest.id)
        return oldest.text
    }

    // MARK: Noticed (counted on the phone, never by Claude)

    /// Replaces the noticed lines with what the last six weeks show: when he trains, how many days a week, which day
    /// he cooks most. Each needs enough evidence to be a pattern, and every number in a line is one it counted.
    func recomputeNoticed(now: Date) {
        for old in lines(of: .noticed) {
            remove(old.id)
        }
        let since = now.addingTimeInterval(-42 * 86400)
        guard let workoutClass = engine.classes[.workout] else { return }
        let workouts = store.objects(of: workoutClass).filter { workout in
            guard !workout.isDeleted, let started = store.value("startedAt", of: workout)?.dateValue,
                  store.value("endedAt", of: workout) != nil else { return false }
            return started >= since && started <= now
        }
        noticeTraining(workouts, now: now)
        noticeCooking(since: since, now: now)
    }

    func noticeTraining(_ workouts: [ObjectRecord], now: Date) {
        let starts = workouts.compactMap { store.value("startedAt", of: $0)?.dateValue }
        if starts.count >= 4 {
            // The two-hour window around the usual hour, when it holds at least 60% of the starts.
            let hours = starts.map { calendar.component(.hour, from: $0) }
            let counts = Dictionary(grouping: hours, by: { $0 }).mapValues(\.count)
            let mode = counts.max { ($0.value, $0.key) < ($1.value, $1.key) }?.key ?? 18
            let best = (counts[mode + 1] ?? 0) >= (counts[mode - 1] ?? 0) ? mode : mode - 1
            if Double(hours.count { $0 == best || $0 == best + 1 }) >= Double(hours.count) * 0.6 {
                let text = "Usually trains \(Self.clock(best)) to \(Self.clock(best + 2))."
                write(kind: .noticed, area: .training, text: text, evidence: workouts.map(\.id), day: nil,
                      numbers: [best % 12 == 0 ? 12 : best % 12, (best + 2) % 12 == 0 ? 12 : (best + 2) % 12])
            }
            let weeks = max(1, Int((now.timeIntervalSince(starts.min() ?? now) / (7 * 86400)).rounded(.up)))
            if weeks >= 2 {
                let perWeek = Int((Double(starts.count) / Double(weeks)).rounded())
                if perWeek >= 1 {
                    write(
                        kind: .noticed,
                        area: .training,
                        text: "Trains about \(perWeek) \(perWeek == 1 ? "day" : "days") a week.",
                        evidence: workouts.map(\.id),
                        day: nil,
                        numbers: [perWeek]
                    )
                }
            }
        }
    }

    func noticeCooking(since: Date, now: Date) {
        guard let cookClass = engine.classes[.cook] else { return }
        let cooks = store.objects(of: cookClass).filter { cook in
            guard !cook.isDeleted, let at = store.value("cookedAt", of: cook)?.dateValue else { return false }
            return at >= since && at <= now
        }
        if cooks.count >= 3 {
            let weekdays = cooks.compactMap { store.value("cookedAt", of: $0)?.dateValue }
                .map { calendar.component(.weekday, from: $0) }
            if let top = Dictionary(grouping: weekdays, by: { $0 }).max(by: { $0.value.count < $1.value.count }),
               Double(top.value.count) >= Double(weekdays.count) * 0.5
            {
                write(kind: .noticed, area: .kitchen, text: "Cooks most on \(Weekdays.name(top.key))s.",
                      evidence: cooks.map(\.id), day: nil)
            }
        }
    }

    static func clock(_ hour: Int) -> String {
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        return "\(twelve) \(hour % 24 < 12 ? "am" : "pm")"
    }
}
