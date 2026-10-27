import Foundation
import TesseraCore

/// Writes the test world into a store through the app's own actions, by `.system`, so the rows look like real use
/// (docs/ai/harness/test-world.md section 1). The store is stamped as a test store first.
///
/// Time: every action reads the engine's clock, so each row is written with the clock set to the moment the world
/// says it happened, and the clock and zone are put back afterwards. The world's own dates are used as they are.
///
/// One file per room (`EvalWorldSeeder+Training.swift`, `+Kitchen.swift`, `+Money.swift`, `+Life.swift`,
/// `+Memory.swift`). They write only what their room owns and never read another room's rows.
@MainActor
public enum EvalWorldSeeder {
    /// What was written, by room, so a test can check the store holds what the world planted.
    public struct Report: Sendable, Equatable {
        public var workouts = 0
        public var renames = 0
        public var recipes = 0
        public var cooks = 0
        public var leftovers = 0
        public var spends = 0
        public var inflows = 0
        public var notes = 0
        public var chores = 0
        public var habitDays = 0
        public var nights = 0
        public var weighIns = 0
        public var events = 0
        public var told = 0
        public var beliefs = 0
    }

    /// Seeds `world` into the engine's store and returns what it wrote.
    @discardableResult
    public static func seed(_ world: EvalWorld, into engine: ActionEngine) throws -> Report {
        let savedNow = engine.now
        let savedZone = engine.zone
        defer {
            engine.now = savedNow
            engine.zone = savedZone
        }
        engine.zone = { EvalWorld.calendar.timeZone }
        engine.now = { world.now }
        try SettingsStore(engine: engine).stampAsTestStore()
        var report = Report()
        try seedTraining(world, engine, &report)
        try seedKitchen(world, engine, &report)
        try seedMoney(world, engine, &report)
        try seedLife(world, engine, &report)
        try seedMemory(world, engine, &report)
        try engine.store.context.save()
        return report
    }

    /// Runs `work` with the engine's clock at `date`.
    static func at<T>(_ date: Date, _ engine: ActionEngine, _ work: () throws -> T) rethrows -> T {
        let saved = engine.now
        engine.now = { date }
        defer { engine.now = saved }
        return try work()
    }
}
