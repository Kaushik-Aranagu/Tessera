import Foundation

/// The 18 muscles volume is counted against. Groups let counts roll up (Shoulders holds the three delts).
public enum MuscleSeed: String, CaseIterable, Sendable, Codable {
    case chest, frontDelts, sideDelts, rearDelts, triceps, biceps, forearms, lats, upperBack, lowerBack
    case abs, obliques, glutes, quads, hamstrings, adductors, abductors, calves

    public var name: String {
        switch self {
        case .chest: "Chest"
        case .frontDelts: "Front Delts"
        case .sideDelts: "Side Delts"
        case .rearDelts: "Rear Delts"
        case .triceps: "Triceps"
        case .biceps: "Biceps"
        case .forearms: "Forearms"
        case .lats: "Lats"
        case .upperBack: "Upper Back"
        case .lowerBack: "Lower Back"
        case .abs: "Abs"
        case .obliques: "Obliques"
        case .glutes: "Glutes"
        case .quads: "Quads"
        case .hamstrings: "Hamstrings"
        case .adductors: "Adductors"
        case .abductors: "Abductors"
        case .calves: "Calves"
        }
    }

    public var group: String {
        switch self {
        case .chest: "Chest"
        case .frontDelts, .sideDelts, .rearDelts: "Shoulders"
        case .triceps, .biceps, .forearms: "Arms"
        case .lats, .upperBack, .lowerBack: "Back"
        case .abs, .obliques: "Core"
        case .glutes, .quads, .hamstrings, .adductors, .abductors, .calves: "Legs"
        }
    }
}

/// Movement pattern: the proposed inheritance spine (the class-tree shape is waiting on Kaushik).
public enum MovementPattern: String, CaseIterable, Sendable, Codable {
    case horizontalPush, verticalPush, horizontalPull, verticalPull, squat, lunge, hinge, carry
    case isolation, core
}

public enum EquipmentKind: String, CaseIterable, Sendable, Codable {
    case barbell, dumbbell, ezBar, cable, machine, smith, kettlebell, bodyweight, band
}

public enum Mechanic: String, Sendable, Codable {
    case compound, isolation
}

public enum LogType: String, Sendable, Codable {
    /// Weight × reps.
    case weightReps
    /// Bodyweight plus optional added load.
    case bodyweightPlus
    /// Machine assistance subtracted from bodyweight.
    case assisted
    case repsOnly
    case duration
    /// Distance or time while carrying a load.
    case distanceLoad
}

/// One built-in exercise, written in our own words (no third-party text or images).
/// Structure-agnostic: the installer decides which class it lives under.
public struct ExerciseSeed: Sendable, Hashable {
    /// Stable key, never shown, e.g. "inclineDbPress". Ids are derived from it.
    public let key: String
    public let name: String
    public let aliases: [String]
    public let pattern: MovementPattern
    /// The family (a subclass with 3+ variants sharing a swap pool), e.g. "BenchPress", "Row", "Deadlift".
    public let family: String?
    /// Finer grouping inside isolation and core, e.g. "Curl", "LateralRaise", "AntiExtension".
    public let group: String?
    public let equipment: EquipmentKind
    public let mechanic: Mechanic
    public let logType: LogType
    public let primary: [MuscleSeed]
    public let secondary: [MuscleSeed]
    public let repRange: ClosedRange<Int>
    public let restSeconds: Int
    /// The base exercise's key when this is a variant whose loads aren't comparable (Incline DB Press → DB Bench
    /// Press).
    public let variantOf: String?
    public let isUnilateral: Bool
    public let cue: String

    public init(_ key: String, _ name: String, aliases: [String] = [], pattern: MovementPattern,
                family: String? = nil, group: String? = nil, equipment: EquipmentKind, mechanic: Mechanic,
                logType: LogType = .weightReps, primary: [MuscleSeed], secondary: [MuscleSeed] = [],
                repRange: ClosedRange<Int>, restSeconds: Int, variantOf: String? = nil,
                isUnilateral: Bool = false, cue: String)
    {
        self.key = key
        self.name = name
        self.aliases = aliases
        self.pattern = pattern
        self.family = family
        self.group = group
        self.equipment = equipment
        self.mechanic = mechanic
        self.logType = logType
        self.primary = primary
        self.secondary = secondary
        self.repRange = repRange
        self.restSeconds = restSeconds
        self.variantOf = variantOf
        self.isUnilateral = isUnilateral
        self.cue = cue
    }
}
