import Foundation

/// Rule names for a training day, built from what its exercises really work (Kaushik, Oct 20: "weak and sometimes
/// wrong" names). Specific names first, in the style of the on-device examples (Heavy chest, Back and biceps, Long
/// legs, Heavy pull, Press day, Carry and core, Shoulders and arms), the plain split after them. A name never
/// contradicts the split: a pull day is never "Push and pull". Every name is 1 to 3 words and 22 characters or fewer.
public enum DayRuleNames {
    /// How a day's working sets divide, and what leads it.
    public struct Shape: Equatable, Sendable {
        public var push = 0.0, pull = 0.0, legs = 0.0, trunk = 0.0
        public var chest = 0.0, shoulders = 0.0, arms = 0.0, back = 0.0, biceps = 0.0, glutesHams = 0.0, quads = 0.0
        /// The first exercise's name (lowercased) and whether it is a barbell lift.
        public var lead = ""
        public var leadIsBarbell = false
        public var names: [String] = []

        public var total: Double {
            push + pull + legs + trunk
        }

        func share(_ value: Double) -> Double {
            total > 0 ? value / total : 0
        }
    }

    static let pushMuscles: Set = ["chest", "front delts", "side delts", "shoulders", "triceps"]
    static let pullMuscles: Set = ["lats", "upper back", "lower back", "rear delts", "biceps", "forearms", "traps",
                                   "back"]
    static let legMuscles: Set = ["quads", "glutes", "hamstrings", "calves", "adductors", "abductors", "hip flexors"]
    static let trunkMuscles: Set = ["abs", "obliques", "core"]

    @MainActor
    public static func shape(of routine: ObjectRecord, store: ObjectStore) -> Shape {
        var shape = Shape()
        for slot in routine.orderedChildren where !slot.isDeleted {
            let sets = store.number("sets", of: slot) ?? 0
            guard sets > 0, let exercise = store.linkedClass("exercise", of: slot) else { continue }
            if shape.names.isEmpty {
                shape.lead = exercise.name.lowercased()
                shape.leadIsBarbell = store.equipmentKind(of: exercise) == .barbell
            }
            shape.names.append(exercise.name.lowercased())
            for muscle in store.linkedObjects("primaryMuscles", ofClass: exercise) {
                let word = muscle.title.lowercased()
                if pushMuscles.contains(word) {
                    shape.push += sets
                    if word == "chest" {
                        shape.chest += sets
                    }
                    if word == "triceps" {
                        shape.arms += sets
                    }
                    if word.hasSuffix("delts") || word == "shoulders" {
                        shape.shoulders += sets
                    }
                } else if pullMuscles.contains(word) {
                    shape.pull += sets
                    if word == "biceps" || word == "forearms" {
                        shape.arms += sets
                        shape.biceps += sets
                    }
                    if ["lats", "upper back", "lower back", "back", "traps"].contains(word) {
                        shape.back += sets
                    }
                } else if legMuscles.contains(word) {
                    shape.legs += sets
                    if word == "glutes" || word == "hamstrings" {
                        shape.glutesHams += sets
                    }
                    if word == "quads" {
                        shape.quads += sets
                    }
                } else if trunkMuscles.contains(word) {
                    shape.trunk += sets
                }
            }
        }
        return shape
    }

    /// Names for a shape, best first; empty when nothing was worked.
    public static func choices(_ shape: Shape) -> [String] {
        guard shape.total > 0 else { return [] }
        let legs = shape.share(shape.legs), push = shape.share(shape.push), pull = shape.share(shape.pull)
        let trunk = shape.share(shape.trunk), arms = shape.share(shape.arms)
        let lead = shape.lead
        let carries = shape.names.contains { $0.contains("carry") || $0.contains("farmer") }
        let overheadLead = lead.contains("overhead press") || lead.contains("shoulder press")
        return if trunk >= 0.5 {
            carries ? ["Carry and core", "Core day", "Abs and core"] : ["Core day", "Abs and core", "Core work"]
        } else if legs >= 0.6 {
            if shape.share(shape.glutesHams) >= 0.5, shape.quads * 3 <= shape.glutesHams, !lead.contains("squat") {
                ["Glutes and hamstrings", "Leg day", "Long legs"]
            } else if lead.contains("squat") {
                ["Squat day", "Heavy legs", "Long legs", "Leg day", "Lower body"]
            } else if shape.leadIsBarbell {
                ["Heavy legs", "Long legs", "Leg day", "Lower body"]
            } else {
                ["Long legs", "Leg day", "Lower body", "Legs"]
            }
        } else if legs >= 0.25, push + pull >= 0.3 {
            ["Full body", "Full body day"]
        } else if arms >= 0.55, legs < 0.2 {
            ["Arms day", "Shoulders and arms", "Biceps and triceps"]
        } else if push >= 0.25, pull >= 0.25 {
            ["Upper body", "Chest and back", "Shoulders and arms", "Upper day"]
        } else if pull > push {
            if shape.leadIsBarbell {
                ["Heavy pull", "Pull day", "Back and biceps", "Back day"]
            } else if shape.share(shape.biceps) >= 0.2 {
                ["Back and biceps", "Pull day", "Heavy pull", "Back day"]
            } else {
                ["Pull day", "Back day", "Back and biceps"]
            }
        } else if push > 0 {
            if overheadLead {
                ["Press day", "Push day", "Shoulders and arms", "Chest and shoulders"]
            } else if shape.leadIsBarbell, shape.share(shape.chest) >= 0.25 {
                ["Heavy chest", "Push day", "Chest and shoulders", "Press day"]
            } else if shape.share(shape.chest) >= 0.25 {
                ["Chest and shoulders", "Push day", "Chest day"]
            } else {
                ["Push day", "Shoulders and arms", "Press day"]
            }
        } else {
            ["Leg day"]
        }
    }
}
