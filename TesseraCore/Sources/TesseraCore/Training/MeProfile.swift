import Foundation

/// Him, for the You page and calorie estimates: height, birth year and sex, each optional ("not said"). One object
/// with a fixed id, always private: it follows exactly the rules a weigh-in note does (typed values stay in the local
/// backup; the iCloud copy drops the object and the ops that touched it; exports show only "Private profile").
/// Nothing in it reaches Claude, the Sent log, logs or widgets. A weight from Health is held in memory only and never
/// written here, to a backup, to the op log or to an export.
public struct MeProfile: Equatable, Sendable {
    public var heightCm: Double?
    public var birthYear: Int?
    /// "female", "male" or nil (not said).
    public var sex: String?

    public init(heightCm: Double? = nil, birthYear: Int? = nil, sex: String? = nil) {
        self.heightCm = heightCm
        self.birthYear = birthYear
        self.sex = sex
    }

    /// The line shown beside the fields.
    public static let privacyLine = "That stays on this phone."
    public static let sexChoices = ["female", "male"]
    public nonisolated static let objectID = SystemCatalog.stableID("meProfile")

    /// What he has said; all nil until he says something. Creates nothing.
    @MainActor
    public static func read(in store: ObjectStore) -> MeProfile {
        guard let object = store.object(id: objectID), !object.isDeleted else { return MeProfile() }
        let sex = store.value("sex", of: object)?.stringValue
        return MeProfile(heightCm: store.number("heightCm", of: object),
                         birthYear: store.number("birthYear", of: object).map { Int($0) },
                         sex: sex.flatMap { sexChoices.contains($0) ? $0 : nil })
    }

    /// Height as a measure, so it swipes between cm and in like every other number with a unit.
    public var height: Measure? {
        heightCm.map { Measure($0, "cm") }
    }

    /// Age in whole years in `year`, from the birth year alone.
    public func age(inYear year: Int) -> Int? {
        birthYear.map { max(0, year - $0) }
    }

    /// The weight to use for an estimate: what he last typed (BodyWeight) wins; else the Health weight the app passes
    /// in, held in memory for this call only.
    @MainActor
    public static func weightKg(in store: ObjectStore, healthKg: Double? = nil) -> Double? {
        BodyWeight.lastKg(in: store) ?? healthKg.flatMap { $0 > 0 ? $0 : nil }
    }

    /// The weight as a measure, in kilograms (swipe it to pounds with `DisplayUnits`).
    @MainActor
    public static func weight(in store: ObjectStore, healthKg: Double? = nil) -> Measure? {
        weightKg(in: store, healthKg: healthKg).map { Measure($0, "kg") }
    }
}

/// Sets what he says about himself. A field left nil is unchanged; `clear` names fields to forget ("height",
/// "birthYear", "sex"). The summary carries no value. Not offered to the model.
public struct SetMeProfile: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setMeProfile", summary: "Update your profile",
        parameters: [
            .init("heightCm", .number, "Height in centimetres", required: false),
            .init("birthYear", .integer, "Year of birth", required: false),
            .init("sex", .string, "female or male", required: false),
            .init("clear", .string, "height, birthYear or sex to forget, comma separated", required: false),
        ], isOfferedToModel: false
    )

    public var heightCm: Double?
    public var birthYear: Int?
    public var sex: String?
    public var clear: String?

    public init(heightCm: Double? = nil, birthYear: Int? = nil, sex: String? = nil, clear: String? = nil) {
        self.heightCm = heightCm
        self.birthYear = birthYear
        self.sex = sex
        self.clear = clear
    }

    public func apply(_ transaction: inout Transaction) throws {
        let name = Self.descriptor.name
        if let heightCm, !(50 ... 260).contains(heightCm) {
            throw ActionError.invalidArguments(action: name, reason: "height out of range")
        }
        if let birthYear, !(1900 ... 2100).contains(birthYear) {
            throw ActionError.invalidArguments(action: name, reason: "year out of range")
        }
        if let sex, !MeProfile.sexChoices.contains(sex) {
            throw ActionError.invalidArguments(action: name, reason: "sex not recognised")
        }
        let object = try transaction.store.object(id: MeProfile.objectID)
            ?? transaction.create(transaction.classDef(.meProfile), title: "Me", id: MeProfile.objectID)
        if object.isDeleted {
            object.deletedAt = nil
        }
        let forget = Set((clear ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        if let heightCm {
            try transaction.set("heightCm", to: .number(heightCm), on: object)
        } else if forget.contains("height") {
            try transaction.set("heightCm", to: nil, on: object)
        }
        if let birthYear {
            try transaction.set("birthYear", to: .number(Double(birthYear)), on: object)
        } else if forget.contains("birthYear") {
            try transaction.set("birthYear", to: nil, on: object)
        }
        if let sex {
            try transaction.set("sex", to: .text(sex), on: object)
        } else if forget.contains("sex") {
            try transaction.set("sex", to: nil, on: object)
        }
    }

    public func summary(in _: ObjectStore) -> String {
        "Updated your profile"
    }
}
