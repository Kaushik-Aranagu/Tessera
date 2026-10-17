import Foundation

/// His last logged body weight, for the bare-number wall (board 0ai, Product 2:56 and 4:46 PM PT). There is no
/// weight entry yet (M3), so a weigh-in lives as a private note ("82 kg this morning"): the newest private note that
/// reads as a weight gives it. Pounds are turned into kilograms. Nil with none logged.
public enum BodyWeight {
    @MainActor
    public static func lastKg(in store: ObjectStore) -> Double? {
        let context = store.context
        if let cache = context.lastWeightCache, cache.revision == context.revision {
            return cache.kilograms
        }
        let kilograms = read(in: store)
        context.lastWeightCache = (context.revision, kilograms)
        return kilograms
    }

    @MainActor
    static func read(in store: ObjectStore) -> Double? {
        let notes = store.allClasses().filter { $0.systemKey == SystemCatalog.Key.note.systemKey }
        guard let noteClass = notes.first else { return nil }
        let weighIns = store.objects(of: noteClass).filter { note in
            !note.isDeleted && store.value("isPrivate", of: note) == .bool(true)
        }.sorted { $0.createdAt > $1.createdAt }
        for note in weighIns {
            if let kg = kilograms(in: store.value("body", of: note)?.stringValue ?? note.title) {
                return kg
            }
        }
        return nil
    }

    /// "82 kg this morning", "weighed 181", "bw 182.4 lb": the weight a line holds, in kg. It needs a weight unit or a
    /// weigh word (QA W1 on 0ai): "bp 120/80" and "ibuprofen 200 mg" are never his weight.
    static func kilograms(in text: String) -> Double? {
        let lower = text.lowercased()
        let number = /(\d+(?:[.,]\d+)?)/
        let withUnit = lower.firstMatch(of: /(\d+(?:[.,]\d+)?)\s*(kg|kgs|kilos|lb|lbs|pounds)\b/)
        let weighs = lower.firstMatch(of: /\b(?:weigh|weighs|weighed|weigh-in|weight|bw)\b/) != nil
        let unit = withUnit.map { String($0.output.2) }
        guard let digits = withUnit.map({ String($0.output.1) }) ?? (weighs ? lower.firstMatch(of: number)
            .map { String($0.output.1) } : nil),
            let value = Double(digits.replacingOccurrences(of: ",", with: ".")) else { return nil }
        let kg = ["lb", "lbs", "pounds"].contains(unit ?? "") ? value * 0.453_592 : value
        return (25 ... 300).contains(kg) ? kg : nil
    }
}
