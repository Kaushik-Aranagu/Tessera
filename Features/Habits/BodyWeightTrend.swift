import Foundation
import TesseraCore

/// The body weight trend (docs/research/body-weight-trend.md): each weigh-in nudges the trend 10% of the way toward
/// it, a gap decays as if the trend had waited, a step is capped at 2 kg, and a gap over 30 days starts again.
enum BodyWeightTrend {
    struct WeighIn: Equatable {
        /// The day's start (his 04:00 day).
        let day: Date
        let kg: Double
    }

    struct Point: Equatable {
        let day: Date
        let kg: Double
        let trend: Double
    }

    static let smoothing = 0.1
    static let stepCap = 2.0
    static let reseedDays = 30

    /// One weigh-in per day: the last of the day wins. Oldest first.
    static func daily(_ entries: [(at: Date, kg: Double)], day: (Date) -> Date) -> [WeighIn] {
        var last: [Date: (at: Date, kg: Double)] = [:]
        for entry in entries {
            let key = day(entry.at)
            if let kept = last[key], kept.at > entry.at {
                continue
            }
            last[key] = entry
        }
        return last.map { WeighIn(day: $0.key, kg: $0.value.kg) }.sorted { $0.day < $1.day }
    }

    static func series(_ weighIns: [WeighIn], calendar: Calendar = .current) -> [Point] {
        var points: [Point] = []
        for entry in weighIns.sorted(by: { $0.day < $1.day }) {
            guard let previous = points.last else {
                points.append(Point(day: entry.day, kg: entry.kg, trend: entry.kg))
                continue
            }
            let gap = max(1, calendar.dateComponents([.day], from: previous.day, to: entry.day).day ?? 1)
            if gap > reseedDays {
                points.append(Point(day: entry.day, kg: entry.kg, trend: entry.kg))
                continue
            }
            let alpha = 1 - pow(1 - smoothing, Double(gap))
            let step = min(max(entry.kg - previous.trend, -stepCap), stepCap)
            points.append(Point(day: entry.day, kg: entry.kg, trend: previous.trend + alpha * step))
        }
        return points
    }

    /// The trend's change over the last week, in kg (negative is less); nil until a week has passed since the first
    /// weigh-in.
    static func weeklyRate(_ points: [Point], calendar: Calendar = .current) -> Double? {
        guard let first = points.first, let last = points.last,
              let weekAgo = calendar.date(byAdding: .day, value: -7, to: last.day), first.day <= weekAgo,
              let then = points.last(where: { $0.day <= weekAgo }) else { return nil }
        return last.trend - then.trend
    }

    /// "0.3 kg less than last week", "0.4 kg more than last week", "About the same as last week" (under 0.1 kg).
    /// No arrows, no colour, no judgement.
    static func rateLine(_ rate: Double?) -> String? {
        guard let rate else { return nil }
        let size = (abs(rate) * 10).rounded() / 10
        guard size >= 0.1 else { return "About the same as last week" }
        return "\(format(size)) kg \(rate < 0 ? "less" : "more") than last week"
    }

    /// One decimal, always: "80.0".
    static func format(_ kg: Double) -> String {
        String(format: "%.1f", (kg * 10).rounded() / 10)
    }

    /// The last `days` days of points, for the quiet line.
    static func recent(_ points: [Point], days: Int = 90, calendar: Calendar = .current) -> [Point] {
        guard let last = points.last, let start = calendar.date(byAdding: .day, value: -days, to: last.day) else {
            return points
        }
        return points.filter { $0.day > start }
    }
}

/// His weigh-ins, read from private notes. Core keeps only the newest (`BodyWeight.lastKg`), so this reads the
/// rest with a strict subset of Core's rule: a note that is nothing but a weight ("82 kg", "weighed 181 lb",
/// "bw 81.8 this morning"). Anything else is never read as his weight.
enum WeighInNotes {
    /// The weight a note holds, in kg, or nil.
    static func kilograms(in text: String) -> Double? {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #/
            ^(?:(weighed\ in\ at|weighed\ in|weighed|weight|weigh-in|bw)\s*:?\s*)?
            (\d{2,3}(?:[.,]\d{1,2})?)\s*
            (kg|kgs|kilos|lb|lbs|pounds)?
            (?:\s+(?:this\ morning|today|tonight|this\ evening))?\.?$
        /#
        guard let match = lower.wholeMatch(of: pattern), match.output.1 != nil || match.output.3 != nil,
              let value = Double(match.output.2.replacingOccurrences(of: ",", with: ".")) else { return nil }
        let pounds = match.output.3.map { ["lb", "lbs", "pounds"].contains(String($0)) } ?? false
        let kg = pounds ? value * 0.453_592 : value
        return (25 ... 300).contains(kg) ? kg : nil
    }

    @MainActor
    static func read(_ model: AppModel) -> [(at: Date, kg: Double)] {
        guard let noteClass = model.classDef(.note) else { return [] }
        let store = model.store
        return store.objects(of: noteClass).compactMap { note in
            guard !note.isDeleted, store.value("isPrivate", of: note) == .bool(true) else { return nil }
            let body = store.value("body", of: note)?.stringValue ?? ""
            let text = body.isEmpty ? note.title : body
            return kilograms(in: text).map { (at: note.createdAt, kg: $0) }
        }
    }
}
