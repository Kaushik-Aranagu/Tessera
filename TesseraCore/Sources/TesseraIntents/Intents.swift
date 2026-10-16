import AppIntents
import Foundation
import TesseraCore
import TesseraTess

// Thin wrappers: each intent performs the same typed action the UI and Tess use, as `.intent`,
// so everything Siri, Shortcuts or the Action button does lands in the op log and can be undone.

public struct LogSetIntent: AppIntent {
    /// Siri writes need Face ID (Product P14, decisions 12:26 PM PT Oct 16).
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

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
    /// Siri writes need Face ID (Product P14, decisions 12:26 PM PT Oct 16).
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public static let title: LocalizedStringResource = "Log Next Set"
    public static let description = IntentDescription("Logs the next set of the workout in progress, as prefilled.")

    @Dependency private var runtime: TesseraRuntime

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let table = ProcessTable(engine: runtime.engine)
        guard let open = table.openWorkout(), let workout = open.subject,
              let entry = WorkoutProgress(of: workout, store: runtime.store).entry
        else { return .result(dialog: "No workout running.") }
        let record = try runtime.engine.perform(LogNextSet(entry: entry.id, source: .lockScreen), by: .intent).record
        return .result(dialog: "\(record.summary).")
    }
}

/// Undoes the most recent set, from anywhere (the Lock Screen's Live Activity uses it).
public extension Notification.Name {
    /// Posted after an intent takes a set back, so a running workout can drop the rest and best that hung on it.
    static let tesseraSetTakenBack = Notification.Name("TesseraSetTakenBack")
}

public struct UndoLastSetIntent: AppIntent {
    /// Siri writes need Face ID (Product P14, decisions 12:26 PM PT Oct 16).
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public static let title: LocalizedStringResource = "Undo Last Set"
    public static let description = IntentDescription("Takes back the most recently logged set, and only that set.")

    @Dependency private var runtime: TesseraRuntime

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let taken = runtime.engine.takeBackLatestSet(by: .intent) else {
            return .result(dialog: "No set to undo.")
        }
        // The open workout screen, its rest and the Live Activity follow the store, not this intent.
        NotificationCenter.default.post(name: .tesseraSetTakenBack, object: nil)
        return .result(dialog: "Set \(taken.number) taken back.")
    }
}

public struct StartRoutineIntent: AppIntent {
    /// Siri writes need Face ID (Product P14, decisions 12:26 PM PT Oct 16).
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

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
    /// Siri writes need Face ID (Product P14, decisions 12:26 PM PT Oct 16).
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public static let title: LocalizedStringResource = "Finish Workout"
    public static let description = IntentDescription("Finishes the workout in progress, keeping every set.")

    @Dependency private var runtime: TesseraRuntime

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let table = ProcessTable(engine: runtime.engine)
        guard let workout = table.openWorkout()?.subject else { return .result(dialog: "No workout running.") }
        try runtime.engine.perform(FinishWorkout(workout: workout.id), by: .intent)
        let progress = WorkoutProgress(of: workout, store: runtime.store)
        return .result(dialog: "Finished. \(progress.entriesStarted) of \(progress.entryCount) exercises.")
    }
}

public struct CreateTaskIntent: AppIntent {
    /// Siri writes need Face ID (Product P14, decisions 12:26 PM PT Oct 16).
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public static let title: LocalizedStringResource = "Add a Task"
    public static let description = IntentDescription("Adds a task to Tessera.")

    @Parameter(title: "Task") public var title: String
    @Parameter(title: "When") public var startsAt: Date?

    @Dependency private var runtime: TesseraRuntime

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        try .result(dialog: "\(Self.add(title, startsAt: startsAt, engine: runtime.engine))")
    }

    /// The Bar's one privacy rule (QA I3, Product P14): a Claude key is never saved; what the Bar files as a private
    /// note is a private note here too, read back as "Private note, kept." and never in his words; a task whose title
    /// is private is read back as "Task added." (a locked phone may be listening).
    @MainActor
    static func add(_ title: String, startsAt: Date?, engine: ActionEngine) throws -> String {
        if looksLikeClaudeKey(title) {
            return TessRouter.keyLine
        }
        let grammar = TessGrammar(store: engine.store, classes: engine.classes)
        switch grammar.privateParse(title, context: TessContext(commitImmediately: true)) {
        case let .privateNote(body, _):
            try engine.perform(CreateNote(body: body, isPrivate: true), by: .intent)
            return "\(SecretWords.title), kept."
        case let .ask(line):
            return line
        default:
            let record = try engine.perform(CreateTask(title: title, startsAt: startsAt), by: .intent).record
            return PrivateFacts.isPrivateTitle(title) ? "Task added." : "\(record.summary)."
        }
    }
}

/// "Tell Tess…": the same capture pipeline as the Bar, committed straight away (there's no ghost row in Siri).
public struct TellTessIntent: AppIntent {
    /// Siri writes need Face ID (Product P14, decisions 12:26 PM PT Oct 16).
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public static let title: LocalizedStringResource = "Tell Tess"
    public static let description =
        IntentDescription("Logs a set or adds a task from a phrase, like \u{201C}bench 80 × 8\u{201D}.")

    @Parameter(title: "Phrase") public var phrase: String

    @Dependency private var runtime: TesseraRuntime

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let capture = await runtime.tess.capture(phrase, context: TessContext(commitImmediately: true))
        // What it wrote is never read back in his words when the words are private (Product P14).
        let hidden = PrivateFacts.isPrivateTitle(phrase) && !capture.records.isEmpty
            && capture.line != "\(SecretWords.title), kept."
        return .result(dialog: "\(hidden ? "Saved." : capture.line)")
    }
}

/// Lets the app's metadata include this package's intents.
public struct TesseraIntentsPackage: AppIntentsPackage {}

#if os(iOS)
    /// The Lock Screen's undo runs in the app's process, against the same op log.
    extension UndoLastSetIntent: LiveActivityIntent {}
    extension LogNextSetIntent: LiveActivityIntent {}
#endif
