import AppIntents
import Foundation
import TesseraCore
import TesseraTess

// Thin wrappers: each intent performs the same typed action the UI and Tess use, as `.intent`,
// so everything Siri, Shortcuts or the Action button does lands in the op log and can be undone.

public struct LogSetIntent: AppIntent {
    public static let title: LocalizedStringResource = "Log a Set"
    public static let description = IntentDescription("Logs sets of an exercise into today's workout.")

    @Parameter(title: "Exercise") public var exercise: ExerciseEntity
    @Parameter(title: "Weight (kg)") public var weight: Double
    @Parameter(title: "Reps", default: 8) public var reps: Int
    @Parameter(title: "Sets", default: 1) public var sets: Int

    @Dependency private var runtime: TesseraRuntime

    public init() {}

    public static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$sets) × \(\.$reps) \(\.$exercise) at \(\.$weight) kg")
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let record = try runtime.engine.perform(
            LogExercise(exercise: exercise.id, weight: weight, reps: Double(reps), sets: sets), by: .intent
        ).record
        return .result(dialog: "\(record.summary).")
    }
}

/// Logs the next set of the running workout exactly as prefilled (the Lock Screen's Done).
public struct LogNextSetIntent: AppIntent {
    public static let title: LocalizedStringResource = "Log Next Set"
    public static let description = IntentDescription("Logs the next set of the workout in progress, as prefilled.")

    @Dependency private var runtime: TesseraRuntime

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let table = ProcessTable(engine: runtime.engine)
        guard let workout = table.running()?.subject,
              let entry = WorkoutProgress(of: workout, store: runtime.store).entry
        else { return .result(dialog: "No workout running.") }
        let record = try runtime.engine.perform(LogNextSet(entry: entry.id, source: .lockScreen), by: .intent).record
        return .result(dialog: "\(record.summary).")
    }
}

/// Undoes the most recent set, from anywhere (the Lock Screen's Live Activity uses it).
public struct UndoLastSetIntent: AppIntent {
    public static let title: LocalizedStringResource = "Undo Last Set"
    public static let description = IntentDescription("Removes the most recently logged set. Undo brings it back.")

    @Dependency private var runtime: TesseraRuntime

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        guard runtime.engine.undoLatest(action: LogSet.descriptor.name) != nil else {
            return .result(dialog: "No set to undo.")
        }
        return .result(dialog: "Last set removed.")
    }
}

public struct StartRoutineIntent: AppIntent {
    public static let title: LocalizedStringResource = "Start a Workout"
    public static let description =
        IntentDescription("Starts a workout from a routine, prefilled with today's targets.")
    public static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Routine") public var routine: RoutineEntity

    @Dependency private var runtime: TesseraRuntime

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = try runtime.engine.perform(StartRoutine(routine: routine.id), by: .intent)
        let count = result.output.orderedChildren.count
        return .result(dialog: "\(routine.title) started. \(count) exercises.")
    }
}

public struct FinishWorkoutIntent: AppIntent {
    public static let title: LocalizedStringResource = "Finish Workout"
    public static let description = IntentDescription("Finishes the workout in progress, keeping every set.")

    @Dependency private var runtime: TesseraRuntime

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let table = ProcessTable(engine: runtime.engine)
        guard let workout = table.running()?.subject ?? table.ledger().first?.subject,
              let workoutClass = runtime.engine.classes[.workout], let classDef = workout.classDef,
              ClassResolver.isSubclass(classDef, of: workoutClass)
        else { return .result(dialog: "No workout running.") }
        try runtime.engine.perform(FinishWorkout(workout: workout.id), by: .intent)
        let progress = WorkoutProgress(of: workout, store: runtime.store)
        return .result(dialog: "Finished. \(progress.entriesStarted) of \(progress.entryCount) exercises.")
    }
}

public struct CreateTaskIntent: AppIntent {
    public static let title: LocalizedStringResource = "Add a Task"
    public static let description = IntentDescription("Adds a task to Tessera.")

    @Parameter(title: "Task") public var title: String
    @Parameter(title: "When") public var startsAt: Date?

    @Dependency private var runtime: TesseraRuntime

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let record = try runtime.engine.perform(CreateTask(title: title, startsAt: startsAt), by: .intent).record
        return .result(dialog: "\(record.summary).")
    }
}

/// "Tell Tess…": the same capture pipeline as the Bar, committed straight away (there's no ghost row in Siri).
public struct TellTessIntent: AppIntent {
    public static let title: LocalizedStringResource = "Tell Tess"
    public static let description =
        IntentDescription("Logs a set or adds a task from a phrase, like \u{201C}bench 80 x 8\u{201D}.")

    @Parameter(title: "Phrase") public var phrase: String

    @Dependency private var runtime: TesseraRuntime

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let capture = await runtime.tess.capture(phrase, context: TessContext(commitImmediately: true))
        return .result(dialog: "\(capture.line)")
    }
}

public struct TesseraShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: TellTessIntent(), phrases: ["Tell \(.applicationName)", "Log in \(.applicationName)"],
                    shortTitle: "Tell Tess", systemImageName: "text.bubble")
        AppShortcut(intent: LogSetIntent(), phrases: ["Log a set in \(.applicationName)"],
                    shortTitle: "Log a Set", systemImageName: "dumbbell")
        AppShortcut(intent: UndoLastSetIntent(), phrases: ["Undo last set in \(.applicationName)"],
                    shortTitle: "Undo Last Set", systemImageName: "arrow.uturn.backward")
        AppShortcut(intent: StartRoutineIntent(), phrases: ["Start \(\.$routine) in \(.applicationName)"],
                    shortTitle: "Start Workout", systemImageName: "figure.strengthtraining.traditional")
        AppShortcut(intent: FinishWorkoutIntent(), phrases: ["Finish my workout in \(.applicationName)"],
                    shortTitle: "Finish Workout", systemImageName: "flag.checkered")
        AppShortcut(intent: CreateTaskIntent(), phrases: ["Add a task in \(.applicationName)"],
                    shortTitle: "Add Task", systemImageName: "checkmark.circle")
    }
}

/// Lets the app's metadata include this package's intents.
public struct TesseraIntentsPackage: AppIntentsPackage {}

#if os(iOS)
    /// The Lock Screen's undo runs in the app's process, against the same op log.
    extension UndoLastSetIntent: LiveActivityIntent {}
    extension LogNextSetIntent: LiveActivityIntent {}
#endif
