import Foundation

/// His last logged body weight, for the bare-number wall (board 0ai, Product 2:56 and 4:46 PM PT). There is no
/// weight entry yet (M3), so a weigh-in lives as a private note ("82 kg this morning"): the newest private note that
/// reads as a weight gives it. Pounds are turned into kilograms. Nil with none logged.
public enum BodyWeight {
    @MainActor
    public static func lastKg(in store: ObjectStore) -> Double? {
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

    /// "82 kg this morning", "weighed 181 lb", "182.4 this morning": the weight a line holds, in kg.
    static func kilograms(in text: String) -> Double? {
        let lower = text.lowercased()
        guard let match = lower.firstMatch(of: /(\d+(?:[.,]\d+)?)\s*(kg|kgs|kilos|lb|lbs|pounds)?/),
              let value = Double(match.output.1.replacingOccurrences(of: ",", with: ".")) else { return nil }
        let unit = match.output.2.map(String.init)
        let weighs = lower.firstMatch(of: /\b(?:weigh|weighs|weighed|weigh-in|weight|bw)\b/) != nil
        guard unit != nil || weighs || PrivateFacts.isBodyShaped(lower, lastWeightKg: nil) else { return nil }
        let kg = ["lb", "lbs", "pounds"].contains(unit ?? "") ? value * 0.453_592 : value
        return (25 ... 300).contains(kg) ? kg : nil
    }
}
