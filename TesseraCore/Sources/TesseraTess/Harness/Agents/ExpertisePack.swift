import CryptoKit
import Foundation
import TesseraCore

/// Memory spec M4: an agent's expertise is stable text built from the app's own data and catalog, never per call.
/// It is the packer's `expertise` section, cached for an hour, and is rebuilt only when its hash changes (on release,
/// when the catalog changes, or when the night pass sees new bests). The hash goes in the trace, so a run can say
/// which pack it used.
///
/// Each pack is two steps: `facts(store:classes:)` reads the store through the walls (a private routine or plan is its
/// shown label, nothing more; a private workout's sets count for no best; a private exercise or place name is left
/// out), and `render(_:)` is a pure function of those facts, so the same facts always give the same bytes and the
/// same hash. His 10:25 PM allowance covers private notes and lists, not workouts.
public struct ExpertisePack: Sendable, Equatable {
    public var expertise: AgentSpec.Expertise
    public var text: String
    public var hash: String

    public init(_ expertise: AgentSpec.Expertise, text: String) {
        self.expertise = expertise
        self.text = text
        hash = Self.hash(text)
    }

    /// The first 16 hex digits of the text's SHA-256.
    public static func hash(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined().prefix(16).description
    }

    /// The pack for an agent, or nil when its room has none yet.
    @MainActor
    public static func build(for spec: AgentSpec, store: ObjectStore,
                             classes: [SystemCatalog.Key: ClassDef]) -> ExpertisePack?
    {
        switch spec.expertise {
        case .training: TrainingExpertise.render(TrainingExpertise.facts(store: store, classes: classes))
        case .kitchen: KitchenExpertise.render(KitchenExpertise.facts(store: store, classes: classes))
        case nil: nil
        }
    }

    static func number(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(rounded)
    }
}

// MARK: - Training

public enum TrainingExpertise {
    public struct LibraryLine: Sendable, Equatable {
        public var name: String
        public var equipment: String
        public var pattern: String
        public var primary: [String]
        public var secondary: [String]
        public var reps: ClosedRange<Int>
    }

    public struct Routine: Sendable, Equatable {
        /// The shown name: a private routine reads "Private workout" and lists nothing.
        public var name: String
        public var slots: [(exercise: String, sets: Int?)]

        public static func == (lhs: Routine, rhs: Routine) -> Bool {
            lhs.name == rhs.name && lhs.slots.map(\.exercise) == rhs.slots.map(\.exercise)
                && lhs.slots.map(\.sets) == rhs.slots.map(\.sets)
        }
    }

    public struct Plan: Sendable, Equatable {
        public var name: String
        public var routines: [String]
    }

    public struct Best: Sendable, Equatable {
        public var exercise: String
        /// Kilograms.
        public var e1RM: Double?
        /// Heaviest weight at a rep count, kilograms.
        public var repMaxes: [Int: Double]
        public var sessions: Int
    }

    public struct Facts: Sendable, Equatable {
        public var e1RMFormula: String?
        public var library: [LibraryLine]
        /// Exercises he made outside the library.
        public var yours: [String]
        public var plans: [Plan]
        public var routines: [Routine]
        public var bests: [Best]
    }

    /// Rep counts the bests table shows.
    static let shownReps = [1, 3, 5, 8, 10]

    public static func render(_ facts: Facts) -> ExpertisePack {
        var lines = ["# Training expertise", "", "All weights are in kilograms.", "", "## Rules"]
        if let formula = facts.e1RMFormula {
            lines.append("- e1RM (the Set class's formula): \(formula)")
        }
        lines += [
            "- Effective reps are reps plus (10 - RPE) when RPE is logged; only sets of up to "
                + "\(ExpertisePack.number(TrainingLedger.e1RMRepLimit)) effective reps estimate a max.",
            "- Rep maxes are tracked from \(TrainingLedger.repMaxRange.lowerBound) to "
                + "\(TrainingLedger.repMaxRange.upperBound) reps. Warm-ups never count.",
            "- Weekly sets: a working set counts 1 for each primary muscle and 0.5 for each secondary one. "
                + "Weeks start Monday at 4 am.",
            "",
            "## Exercise library (\(facts.library.count))",
        ]
        for line in facts.library.sorted(by: { $0.name < $1.name }) {
            var text = "\(line.name): \(line.equipment), \(line.pattern); \(line.primary.joined(separator: ", "))"
            if !line.secondary.isEmpty {
                text += "; also \(line.secondary.joined(separator: ", "))"
            }
            text += "; \(line.reps.lowerBound)-\(line.reps.upperBound) reps"
            lines.append(text)
        }
        if !facts.yours.isEmpty {
            lines += ["", "## His own exercises"] + facts.yours.sorted()
        }
        lines += ["", "## Plans"]
        lines += facts.plans.sorted { $0.name < $1.name }.map { "\($0.name): \($0.routines.joined(separator: ", "))" }
        lines += ["", "## Routines"]
        for routine in facts.routines.sorted(by: { $0.name < $1.name }) {
            let slots = routine.slots.map { slot in slot.sets.map { "\(slot.exercise) \($0) sets" } ?? slot.exercise }
            lines.append(slots.isEmpty ? routine.name : "\(routine.name): \(slots.joined(separator: ", "))")
        }
        lines += ["", "## Bests"]
        for best in facts.bests.sorted(by: { $0.exercise < $1.exercise }) {
            var parts: [String] = []
            if let e1RM = best.e1RM {
                parts.append("e1RM \(ExpertisePack.number(e1RM))")
            }
            let maxes = shownReps.compactMap { reps in
                best.repMaxes[reps].map { "\(reps) rep\(reps == 1 ? "" : "s") \(ExpertisePack.number($0))" }
            }
            parts += maxes
            parts.append("\(best.sessions) session\(best.sessions == 1 ? "" : "s")")
            lines.append("\(best.exercise): \(parts.joined(separator: "; "))")
        }
        return ExpertisePack(.training, text: lines.joined(separator: "\n"))
    }

    @MainActor
    public static func facts(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) -> Facts {
        let library = ExerciseLibrary.seeds.map {
            LibraryLine(name: $0.name, equipment: $0.equipment.rawValue, pattern: $0.pattern.rawValue,
                        primary: $0.primary.map(\.name), secondary: $0.secondary.map(\.name), reps: $0.repRange)
        }
        let lastKg = BodyWeight.lastKg(in: store)
        func isPlain(_ name: String) -> Bool {
            !ObjectPrivacy.isPrivateTitle(name, lastWeightKg: lastKg)
        }
        let groups = store.exerciseGroups(root: classes[.exercise])
        let yours = groups.first { $0.pattern == nil }?.exercises.map(\.name).filter(isPlain) ?? []
        let formula = classes[.set].flatMap { ClassResolver.field("e1rm", of: $0)?.expression }

        func shown(_ object: ObjectRecord) -> (name: String, isPrivate: Bool) {
            if let label = ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) {
                return (label, true)
            }
            return (object.title, false)
        }

        var routines: [Routine] = []
        if let routineClass = classes[.routine] {
            for routine in store.objects(of: routineClass) where !routine.isDeleted {
                let name = shown(routine)
                guard !name.isPrivate else {
                    routines.append(Routine(name: name.name, slots: []))
                    continue
                }
                let slots = routine.orderedChildren
                    .filter { !$0.isDeleted && $0.classDef?.systemKey == SystemCatalog.Key.slot.systemKey }
                    .compactMap { slot -> (exercise: String, sets: Int?)? in
                        guard let exercise = store.linkedClass("exercise", of: slot), isPlain(exercise.name) else {
                            return nil
                        }
                        return (exercise: exercise.name, sets: store.number("sets", of: slot).map { Int($0) })
                    }
                routines.append(Routine(name: name.name, slots: slots))
            }
        }

        var plans: [Plan] = []
        if let planClass = classes[.plan] {
            for plan in store.objects(of: planClass) where !plan.isDeleted {
                let name = shown(plan)
                // A private plan lists nothing, not even its routines' shown names.
                let routineNames = name.isPrivate ? [] : store.linkedObjects("routines", of: plan)
                    .filter { !$0.isDeleted }.map { shown($0).name }
                plans.append(Plan(name: name.name, routines: routineNames))
            }
        }

        let ledger = TrainingLedger(store: store, classes: classes)
        let stats = TrainingStats(store: store, classes: classes)
        let exercises = groups.flatMap(\.exercises).filter { isPlain($0.name) }
        let bests: [Best] = exercises.compactMap { exercise in
            // Only sets from workouts that aren't private: a rehab workout's sets move no best and no hash.
            let sessions = stats.counted(ledger.sessions(of: exercise))
            guard !sessions.isEmpty else { return nil }
            var e1RM: Double?
            var repMaxes: [Int: Double] = [:]
            for set in sessions.flatMap(\.sets) {
                if set.isE1RMEligible, set.e1RM > (e1RM ?? -.infinity) {
                    e1RM = set.e1RM
                }
                let reps = Int(set.reps.rounded())
                if TrainingLedger.repMaxRange.contains(reps) {
                    repMaxes[reps] = max(repMaxes[reps] ?? 0, set.weight)
                }
            }
            return Best(exercise: exercise.name, e1RM: e1RM, repMaxes: repMaxes, sessions: sessions.count)
        }
        return Facts(e1RMFormula: formula, library: library, yours: yours, plans: plans, routines: routines,
                     bests: bests)
    }
}

// MARK: - Kitchen

public enum KitchenExpertise {
    public struct Facts: Sendable, Equatable {
        public var aisles: [String]
        public var staples: [String]
        public var places: [String]
        /// Shown names: a private recipe reads by its label.
        public var recipes: [String]
    }

    public static func render(_ facts: Facts) -> ExpertisePack {
        var lines = ["# Kitchen expertise", "", "## Rules",
                     "- The Groceries list is the Pantry's first place, \"\(PantryPlaces.toGet)\".",
                     "- Calories show only inside the Kitchen room, and only with \"Show calories\" on.",
                     "", "## Grocery aisles, in store order"]
        lines += facts.aisles
        lines += ["", "## Staples (skipped when a recipe goes on the list)"] + facts.staples.sorted()
        lines += ["", "## Pantry places"] + facts.places
        lines += ["", "## His recipes (\(facts.recipes.count))"] + facts.recipes.sorted()
        return ExpertisePack(.kitchen, text: lines.joined(separator: "\n"))
    }

    @MainActor
    public static func facts(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) -> Facts {
        let places = classes[.place].map { placeClass in
            store.objects(of: placeClass).filter { !$0.isDeleted }.sorted { $0.createdAt < $1.createdAt }
                .map { ObjectPrivacy.shownLabel(of: $0, in: store, classes: classes) ?? $0.title }
        } ?? []
        let recipes = classes[.recipe].map { recipeClass in
            store.objects(of: recipeClass).filter { !$0.isDeleted }.map {
                ObjectPrivacy.shownLabel(of: $0, in: store, classes: classes) ?? $0.title
            }
        } ?? []
        return Facts(aisles: Aisle.allCases.map(\.rawValue), staples: AisleGuide.staples.sorted(), places: places,
                     recipes: recipes)
    }
}
