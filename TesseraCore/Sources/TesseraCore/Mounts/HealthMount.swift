import Foundation

/// The Health mount (M4 slice 2, docs/research/calendar-health-fixtures.md H01 to H17): last night's sleep, today's
/// steps and the resting heart rate, read on foreground. Pure Swift: the app turns HealthKit samples into these
/// inputs. Missing data is no object at all, and a read error is never "no data" (H11, H12, H17).
public enum SleepValue: String, Codable, Sendable {
    case inBed, awake, asleepCore, asleepDeep, asleepREM, asleepUnspecified

    var isAsleep: Bool {
        switch self {
        case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified: true
        case .inBed, .awake: false
        }
    }
}

public struct SleepSample: Codable, Sendable, Equatable {
    public var value: SleepValue
    public var start: Date
    public var end: Date
    public var sourceBundle: String
    public var productType: String

    public init(value: SleepValue, start: Date, end: Date, sourceBundle: String = "com.apple.health",
                productType: String = "")
    {
        self.value = value
        self.start = start
        self.end = end
        self.sourceBundle = sourceBundle
        self.productType = productType
    }

    var minutes: Double {
        end.timeIntervalSince(start) / 60
    }

    var isWatch: Bool {
        productType.hasPrefix("Watch")
    }
}

/// One night, picked from the samples whose end falls in 18:00 yesterday to 14:00 today.
public struct SleepNightResult: Equatable, Sendable {
    public var date: Date
    public var asleepMinutes: Int?
    public var inBedMinutes: Int?
    public var awakeMinutes: Int?
    public var coreMinutes: Int?
    public var deepMinutes: Int?
    public var remMinutes: Int?
    public var source: String
    /// "asleep" or "inBed" (no asleep samples at all: shown as in bed, never fed to the under-6-hour cap).
    public var basis: String
    /// Tracking stopped well before the night did: shown with a note, never caps the plan.
    public var partial: Bool
}

public enum SleepNightBuilder {
    /// Gaps under this join samples into one cluster; the night is the cluster with the most asleep minutes.
    static let clusterGap: TimeInterval = 90 * 60

    public static func night(from samples: [SleepSample], now: Date, calendar: Calendar) -> SleepNightResult? {
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              let windowStart = calendar.date(byAdding: .hour, value: 18, to: yesterday),
              let windowEnd = calendar.date(byAdding: .hour, value: 14, to: today) else { return nil }
        let inWindow = samples.filter { $0.end > windowStart && $0.end <= windowEnd && $0.end > $0.start }
        let asleep = inWindow.filter(\.value.isAsleep)
        guard !asleep.isEmpty else { return inBedOnly(inWindow, calendar: calendar) }

        // The source: a Watch if any wrote asleep samples, else the one with the most asleep minutes; never summed.
        let bySource = Dictionary(grouping: asleep, by: \.sourceBundle)
        let source = bySource.keys.sorted { lhs, rhs in
            let watchL = bySource[lhs]?.contains(where: \.isWatch) == true
            let watchR = bySource[rhs]?.contains(where: \.isWatch) == true
            if watchL != watchR {
                return watchL
            }
            let minutesL = bySource[lhs]?.reduce(0) { $0 + $1.minutes } ?? 0
            let minutesR = bySource[rhs]?.reduce(0) { $0 + $1.minutes } ?? 0
            return minutesL != minutesR ? minutesL > minutesR : lhs < rhs
        }[0]
        let chosen = (bySource[source] ?? []).sorted { $0.start < $1.start }

        // Cluster by gaps under 90 minutes; the night is the biggest cluster, naps are ignored.
        var clusters: [[SleepSample]] = []
        for sample in chosen {
            if let last = clusters.last?.last, sample.start.timeIntervalSince(last.end) < clusterGap {
                clusters[clusters.count - 1].append(sample)
            } else {
                clusters.append([sample])
            }
        }
        guard let night = clusters.max(by: { total($0) < total($1) }), let first = night.first, let last = night.last
        else { return nil }
        let span = (start: first.start, end: last.end)

        func minutes(_ values: [SleepValue]) -> Int? {
            let matching = night.filter { values.contains($0.value) }
            return matching.isEmpty ? nil : Int(matching.reduce(0) { $0 + $1.minutes }.rounded())
        }
        let awake = inWindow.filter {
            $0.value == .awake && $0.sourceBundle == source && $0.start >= span.start && $0.end <= span.end
        }.reduce(0) { $0 + $1.minutes }
        let inBed = inWindow.filter { $0.value == .inBed }.map(\.minutes).max()
        let hasStages = night.contains { [.asleepCore, .asleepDeep, .asleepREM].contains($0.value) }
        // Partial: the chosen source stopped 2 hours or more before another source's in-bed end, or before 05:00.
        let otherInBedEnd = inWindow.filter { $0.value == .inBed && $0.sourceBundle != source }.map(\.end).max()
        let five = calendar.date(byAdding: .hour, value: 5, to: today) ?? today
        let partial = (otherInBedEnd.map { $0.timeIntervalSince(span.end) >= 2 * 3600 } ?? false)
            || (span.end < five && inBed != nil)
        let displaySource = bySource[source]?.contains(where: \.isWatch) == true ? "Apple Watch" : source
        return SleepNightResult(
            date: calendar.startOfDay(for: span.end), asleepMinutes: Int(total(night).rounded()),
            inBedMinutes: inBed.map { Int($0.rounded()) }, awakeMinutes: awake > 0 ? Int(awake.rounded()) : nil,
            coreMinutes: hasStages ? minutes([.asleepCore]) : nil,
            deepMinutes: hasStages ? minutes([.asleepDeep]) : nil,
            remMinutes: hasStages ? minutes([.asleepREM]) : nil, source: displaySource, basis: "asleep",
            partial: partial
        )
    }

    private static func total(_ cluster: [SleepSample]) -> Double {
        cluster.reduce(0) { $0 + $1.minutes }
    }

    /// No asleep samples at all (an iPhone alone): in bed, labelled as in bed (H03).
    private static func inBedOnly(_ samples: [SleepSample], calendar: Calendar) -> SleepNightResult? {
        guard let longest = samples.filter({ $0.value == .inBed }).max(by: { $0.minutes < $1.minutes }) else {
            return nil
        }
        return SleepNightResult(
            date: calendar.startOfDay(for: longest.end), asleepMinutes: nil,
            inBedMinutes: Int(longest.minutes.rounded()),
            awakeMinutes: nil, coreMinutes: nil, deepMinutes: nil, remMinutes: nil,
            source: longest.isWatch ? "Apple Watch" : "iPhone", basis: "inBed", partial: false
        )
    }
}

/// What the app read this foreground. `readFailed` (a locked Health store) changes nothing: no data is not an error.
public struct HealthInputs: Codable, Sendable {
    public var sleep: [SleepSample]
    /// Today's steps from `HKStatisticsQuery .cumulativeSum`, which merges sources; never added up per source.
    public var stepsToday: Int?
    public var restingHeartRate: Double?
    public var restingHeartRateAt: Date?
    public var readFailed: Bool

    public init(sleep: [SleepSample] = [], stepsToday: Int? = nil, restingHeartRate: Double? = nil,
                restingHeartRateAt: Date? = nil, readFailed: Bool = false)
    {
        self.sleep = sleep
        self.stepsToday = stepsToday
        self.restingHeartRate = restingHeartRate
        self.restingHeartRateAt = restingHeartRateAt
        self.readFailed = readFailed
    }
}

/// Upserts last night, today's steps and the resting heart rate by date, as the system. A day after its wake day is
/// frozen: only the date of `now` is recomputed.
public struct SyncHealth: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "syncHealth", summary: "Read Health on foreground", parameters: [], isOfferedToModel: false
    )

    public var inputs: HealthInputs
    public var now: Date
    public var zone: String

    public init(inputs: HealthInputs, now: Date, zone: String = TimeZone.current.identifier) {
        self.inputs = inputs
        self.now = now
        self.zone = zone
    }

    /// Resting heart rate older than this is stale and hidden, not carried forward (H15).
    static let staleAfter: TimeInterval = 36 * 3600

    static func id(_ kind: String, _ date: Date, _ calendar: Calendar) -> UUID {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return SystemCatalog.stableID(String(format: "health:%@:%04d-%02d-%02d", kind, parts.year ?? 0,
                                             parts.month ?? 0, parts.day ?? 0))
    }

    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> Int {
        guard !inputs.readFailed else { return 0 }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone) ?? .current
        var written = 0
        if let night = SleepNightBuilder.night(from: inputs.sleep, now: now, calendar: calendar) {
            let object = try upsert("sleepNight", night.date, title: "Sleep", calendar: calendar, in: &transaction)
            let values: [(String, FieldValue?)] = [
                ("date", .date(night.date)), ("asleepMinutes", night.asleepMinutes.map { .number(Double($0)) }),
                ("inBedMinutes", night.inBedMinutes.map { .number(Double($0)) }),
                ("awakeMinutes", night.awakeMinutes.map { .number(Double($0)) }),
                ("coreMinutes", night.coreMinutes.map { .number(Double($0)) }),
                ("deepMinutes", night.deepMinutes.map { .number(Double($0)) }),
                ("remMinutes", night.remMinutes.map { .number(Double($0)) }), ("source", .text(night.source)),
                ("basis", .text(night.basis)), ("partial", .bool(night.partial)),
            ]
            for (key, value) in values {
                try transaction.set(key, to: value, on: object)
            }
            written += 1
        }
        let today = calendar.startOfDay(for: now)
        if let steps = inputs.stepsToday, steps >= 0 {
            let object = try upsert("stepsDay", today, title: "Steps", calendar: calendar, in: &transaction)
            try transaction.set("date", to: .date(today), on: object)
            try transaction.set("count", to: .number(Double(steps)), on: object)
            written += 1
        }
        if let bpm = inputs.restingHeartRate, let at = inputs.restingHeartRateAt,
           now.timeIntervalSince(at) <= Self.staleAfter
        {
            let object = try upsert("restingHeartRate", today, title: "Resting heart rate", calendar: calendar,
                                    in: &transaction)
            try transaction.set("date", to: .date(today), on: object)
            try transaction.set("bpm", to: .number(bpm), on: object)
            written += 1
        }
        return written
    }

    @MainActor
    private func upsert(_ kind: String, _ date: Date, title: String, calendar: Calendar,
                        in transaction: inout Transaction) throws -> ObjectRecord
    {
        let key: SystemCatalog.Key = switch kind {
        case "sleepNight": .sleepNight
        case "stepsDay": .stepsDay
        default: .restingHeartRate
        }
        let id = Self.id(kind, date, calendar)
        if let existing = transaction.store.object(id: id), !existing.isDeleted {
            return existing
        }
        return try transaction.create(transaction.classDef(key), title: title, id: id)
    }

    public var logsWhenEmpty: Bool {
        false
    }

    public func summary(in _: ObjectStore) -> String {
        "Read Health"
    }
}
