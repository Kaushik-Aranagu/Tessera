import Foundation

/// One of the extra exercises beside the 72 we wrote: a name, muscles, equipment and a one-line cue in our own words.
/// Names, equipment and muscles come from free-exercise-db (Unlicense); its instructions and images do not ship.
/// Read-only: it becomes a real exercise class the first time anyone edits, logs or schedules it (`LibraryAdopter`).
public struct LibraryExercise: Sendable, Hashable, Identifiable {
    public enum Place: String, Sendable { case home, gym }

    /// Research's label, e.g. "E05". Stable.
    public let id: String
    public let name: String
    public let equipment: EquipmentKind
    public let primary: [MuscleSeed]
    public let secondary: [MuscleSeed]
    public let mechanic: Mechanic
    public let place: Place
    /// The free-exercise-db entry it was named from, for credit.
    public let sourceID: String
    public let cue: String

    /// What a row shows under the name: "Chest, Triceps · Bodyweight".
    public var summary: String {
        primary.map(\.name).joined(separator: ", ") + " · " + equipment.displayName
    }
}

public enum LibraryExtras {
    public static let all: [LibraryExercise] = parseExercises()
    private static let byName: [String: LibraryExercise] = Dictionary(
        all.map { (normalised($0.name), $0) }, uniquingKeysWith: { first, _ in first }
    )

    public static func exercise(named name: String) -> LibraryExercise? {
        byName[normalised(name)]
    }

    public static func exercise(id: String) -> LibraryExercise? {
        all.first { $0.id == id }
    }

    /// The exercises matching every word of `text` (a name, a muscle, a kind of equipment: "curl cable", "quads",
    /// "bands back"), `muscle` as a primary or secondary muscle, `equipment` and `place` exactly. Primary-muscle hits
    /// rank first, then name hits, then A to Z.
    public static func search(_ text: String = "", muscle: MuscleSeed? = nil, equipment: EquipmentKind? = nil,
                              place: LibraryExercise.Place? = nil) -> [LibraryExercise]
    {
        let words = text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        var ranked: [(exercise: LibraryExercise, rank: Int)] = []
        for exercise in all {
            if let equipment, exercise.equipment != equipment {
                continue
            }
            if let place, exercise.place != place {
                continue
            }
            var rank = 0
            if let muscle {
                if exercise.primary.contains(muscle) {
                    rank += 4
                } else if exercise.secondary.contains(muscle) {
                    rank += 1
                } else {
                    continue
                }
            }
            var hits: [Int] = []
            for word in words {
                guard let hit = wordRank(word, in: exercise) else { break }
                hits.append(hit)
            }
            guard hits.count == words.count else { continue }
            ranked.append((exercise, rank + hits.reduce(0, +)))
        }
        return ranked.sorted { $0.rank != $1.rank ? $0.rank > $1.rank : $0.exercise.name < $1.exercise.name }
            .map(\.exercise)
    }

    private static func wordRank(_ word: String, in exercise: LibraryExercise) -> Int? {
        let nameWords = exercise.name.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        if nameWords.contains(where: { $0.hasPrefix(word) }) {
            return 3
        }
        if exercise.primary.contains(where: { $0.searchWords.contains(word) }) {
            return 2
        }
        if exercise.equipment.searchWords.contains(word) {
            return 2
        }
        if exercise.secondary.contains(where: { $0.searchWords.contains(word) }) {
            return 1
        }
        return nil
    }

    /// "Push-Up", "Pushups" and "push up" are one exercise.
    static func normalised(_ name: String) -> String {
        var letters = String(name.lowercased().filter { $0.isLetter || $0.isNumber })
        if letters.hasSuffix("s") {
            letters.removeLast()
        }
        return letters
    }

    static func muscles(_ text: String) -> [MuscleSeed] {
        text.split(separator: ",").compactMap { word in
            let name = word.trimmingCharacters(in: .whitespaces)
            return MuscleSeed.allCases.first { $0.name == name }
        }
    }

    static func equipmentKind(_ word: String) -> EquipmentKind? {
        switch word {
        case "Barbell": .barbell
        case "Dumbbell": .dumbbell
        case "Cable": .cable
        case "Machine": .machine
        case "Kettlebell": .kettlebell
        case "Band": .band
        case "Body": .bodyweight
        default: nil
        }
    }

    private static func parseExercises() -> [LibraryExercise] {
        exerciseTable.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard parts.count == 9, let equipment = equipmentKind(parts[2]),
                  let mechanic = Mechanic(rawValue: parts[5]),
                  let place = LibraryExercise.Place(rawValue: parts[6].lowercased()) else { return nil }
            return LibraryExercise(id: parts[0], name: parts[1], equipment: equipment, primary: muscles(parts[3]),
                                   secondary: muscles(parts[4]), mechanic: mechanic, place: place,
                                   sourceID: parts[7], cue: parts[8])
        }
    }
}

extension MuscleSeed {
    /// What someone types for it: "quads", "abs", "delts", "back", "legs".
    var searchWords: [String] {
        var words = [name.lowercased(), group.lowercased()]
        switch self {
        case .abs, .obliques: words += ["core", "abdominals"]
        case .frontDelts, .sideDelts, .rearDelts: words += ["delts", "delt", "shoulder"]
        case .quads: words += ["quad", "quadriceps"]
        case .upperBack: words += ["traps", "back"]
        default: break
        }
        return words
    }
}

extension EquipmentKind {
    var displayName: String {
        switch self {
        case .barbell: "Barbell"
        case .dumbbell: "Dumbbells"
        case .ezBar: "EZ Bar"
        case .cable: "Cable"
        case .machine: "Machine"
        case .smith: "Smith Machine"
        case .kettlebell: "Kettlebell"
        case .bodyweight: "Bodyweight"
        case .band: "Bands"
        }
    }

    /// What someone types for it: "barbell", "dumbbells", "cable", "bodyweight", "bands".
    var searchWords: [String] {
        switch self {
        case .barbell: ["barbell", "bb"]
        case .dumbbell: ["dumbbell", "dumbbells", "db"]
        case .ezBar: ["ez", "e-z", "curl bar"]
        case .cable: ["cable", "cables"]
        case .machine: ["machine", "machines"]
        case .smith: ["smith"]
        case .kettlebell: ["kettlebell", "kettlebells", "kb"]
        case .bodyweight: ["bodyweight", "body", "none", "home"]
        case .band: ["band", "bands", "resistance"]
        }
    }
}
