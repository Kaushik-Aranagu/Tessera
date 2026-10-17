import Foundation

/// His last logged body weight, for the bare-number wall (board 0ai, Product 2:56 and 4:46 PM PT). There is no
/// weight entry yet (M3), so a weigh-in lives as a private note ("82 kg this morning"): the newest private note that
/// reads as a weigh-in gives it. Pounds are turned into kilograms. Nil with none logged.
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
        let exercises = exerciseNames(in: store)
        for note in weighIns {
            if let kg = kilograms(in: store.value("body", of: note)?.stringValue ?? note.title, exercises: exercises) {
                return kg
            }
        }
        return nil
    }

    /// Lifts named often enough to read without the store.
    static let liftWords: Set<String> = ["squat", "squats", "bench", "deadlift", "deadlifts", "dl", "ohp", "press",
                                         "row", "rows", "curl", "curls", "lunge", "lunges", "rdl", "clean", "snatch",
                                         "pullup", "pullups", "dip", "dips", "thrust", "set", "sets", "reps"]

    /// His exercises' names, lowercased ("bench press", "good morning"), matched as whole phrases. A name made only
    /// of day, body or weigh words is left out (QA on #638: "Good Morning" must never hide "82 kg this morning").
    @MainActor
    static func exerciseNames(in store: ObjectStore) -> [String] {
        let plain = PrivateFacts.dayWords.union(PrivateFacts.bodyWords).union(PrivateFacts.bodyUnits)
            .union(PrivateFacts.weighWords).union(["good", "bb", "db", "kb"])
        // The library's exercises are classes under Exercise ("Bench Press"); his own may be objects too.
        guard let exercise = store.allClasses().first(where: { $0.systemKey == SystemCatalog.Key.exercise.systemKey })
        else { return [] }
        let classes = store.allClasses().filter { ClassResolver.isSubclass($0, of: exercise) }
        let names = classes.map(\.name) + classes.flatMap { store.objects(of: $0) }.map(\.title)
        return Set(names.map { $0.lowercased() }).sorted().filter { name in
            !PrivateFacts.words(name).allSatisfy(plain.contains)
        }
    }

    /// "82 kg this morning", "weighed 181", "weighed in at 7:30, 81.8": the weight a weigh-in line holds, in kg. Only a
    /// weigh-in counts (QA W1, AI architecture on #627): a weigh word, or a weight unit with nothing but day words
    /// beside it. "bp 120/80", "ibuprofen 200 mg" and "squat 140 kg" are never his weight, and a clock time is never a
    /// number to read.
    static func kilograms(in text: String, exercises: [String] = []) -> Double? {
        let lower = PrivateFacts.withoutTimes(text.lowercased())
        let words = PrivateFacts.words(lower)
        // A named exercise makes the number a bar, not a weigh-in (Product 8:28 PM PT): "weighed squat at 140 kg".
        let padded = " \(words.joined(separator: " ")) "
        guard !words.contains(where: liftWords.contains),
              !exercises.contains(where: { padded.contains(" \(PrivateFacts.words($0).joined(separator: " ")) ") })
        else { return nil }
        let units: Set = ["kg", "kgs", "kilos", "lb", "lbs", "pounds"]
        let weighs = lower.firstMatch(of: /\b(?:weigh|weighs|weighed|weigh-in|weight|bw)\b/) != nil
        let rest = words
            .filter { $0.first?.isNumber != true && !units.contains($0) && $0.wholeMatch(of: /\d.*/) == nil }
        guard weighs || (words.contains(where: units.contains) || lower.firstMatch(of: /\d\s*(?:kg|lb)/) != nil)
            && rest.allSatisfy(PrivateFacts.dayWords.contains) else { return nil }
        for match in lower.matches(of: /(\d+(?:[.,]\d+)?)\s*(kg|kgs|kilos|lb|lbs|pounds)?\b/) {
            guard let value = Double(match.output.1.replacingOccurrences(of: ",", with: ".")) else { continue }
            let pounds = match.output.2.map { ["lb", "lbs", "pounds"].contains(String($0)) } ?? false
            let kg = pounds ? value * 0.453_592 : value
            if (25 ... 300).contains(kg) {
                return kg
            }
        }
        return nil
    }
}
