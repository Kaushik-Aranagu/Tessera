import Foundation

/// Every built-in action, by name. Tess's tool list, the Claude tool schema and App Intents come from here,
/// so an action declared once is callable from all three.
public enum ActionRegistry {
    public static let descriptors: [ActionDescriptor] = [
        LogSet.descriptor, EditSet.descriptor, AddExercise.descriptor, StartWorkout.descriptor,
        FinishWorkout.descriptor, LogExercise.descriptor, CreateTask.descriptor, SetTaskDone.descriptor,
        RenameObject.descriptor, DeleteObject.descriptor, StartProcess.descriptor, SaveContext.descriptor,
        SuspendProcess.descriptor, ResumeProcess.descriptor, EndProcess.descriptor, CreateRoutine.descriptor,
        AddSlot.descriptor, StartRoutine.descriptor, CreatePlan.descriptor, LogNextSet.descriptor, MoveSlot.descriptor,
        EditSlot.descriptor,
        SwapSlotExercise.descriptor,
        SwapEntryExercise.descriptor, MoveTask.descriptor, RollForwardTasks.descriptor, StartTask.descriptor,
        WaitOnTask.descriptor,
    ]

    /// The compact catalog for the on-device model's instructions, one action per line.
    public static var catalog: String {
        descriptors.map(\.catalogLine).joined(separator: "\n")
    }

    /// Tool definitions as JSON, ready for a Claude request's `tools` array.
    public static func toolDefinitionsJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(descriptors.map(\.toolDefinition))
    }

    /// Decodes a tool call's JSON arguments into a typed action. Dates are ISO 8601.
    public static func decode(name: String, arguments: Data) throws -> any EngineAction {
        guard let decoder = decoders[name] else { throw ActionError.unknownAction(name) }
        return try decoder(arguments)
    }

    private static let decoders: [String: @Sendable (Data) throws -> any EngineAction] = [
        MoveTask.descriptor.name: { try decode(MoveTask.self, MoveTask.descriptor.name, $0) },
        StartTask.descriptor.name: { try decode(StartTask.self, StartTask.descriptor.name, $0) },
        WaitOnTask.descriptor.name: { try decode(WaitOnTask.self, WaitOnTask.descriptor.name, $0) },
        RollForwardTasks.descriptor.name: { try decode(RollForwardTasks.self, RollForwardTasks.descriptor.name, $0) },
        LogSet.descriptor.name: { try decode(LogSet.self, LogSet.descriptor.name, $0) },
        EditSet.descriptor.name: { try decode(EditSet.self, EditSet.descriptor.name, $0) },
        AddExercise.descriptor.name: { try decode(AddExercise.self, AddExercise.descriptor.name, $0) },
        StartWorkout.descriptor.name: { try decode(StartWorkout.self, StartWorkout.descriptor.name, $0) },
        FinishWorkout.descriptor.name: { try decode(FinishWorkout.self, FinishWorkout.descriptor.name, $0) },
        LogExercise.descriptor.name: { try decode(LogExercise.self, LogExercise.descriptor.name, $0) },
        CreateTask.descriptor.name: { try decode(CreateTask.self, CreateTask.descriptor.name, $0) },
        SetTaskDone.descriptor.name: { try decode(SetTaskDone.self, SetTaskDone.descriptor.name, $0) },
        RenameObject.descriptor.name: { try decode(RenameObject.self, RenameObject.descriptor.name, $0) },
        DeleteObject.descriptor.name: { try decode(DeleteObject.self, DeleteObject.descriptor.name, $0) },
        StartProcess.descriptor.name: { try decode(StartProcess.self, StartProcess.descriptor.name, $0) },
        SaveContext.descriptor.name: { try decode(SaveContext.self, SaveContext.descriptor.name, $0) },
        SuspendProcess.descriptor.name: { try decode(SuspendProcess.self, SuspendProcess.descriptor.name, $0) },
        ResumeProcess.descriptor.name: { try decode(ResumeProcess.self, ResumeProcess.descriptor.name, $0) },
        EndProcess.descriptor.name: { try decode(EndProcess.self, EndProcess.descriptor.name, $0) },
        CreateRoutine.descriptor.name: { try decode(CreateRoutine.self, CreateRoutine.descriptor.name, $0) },
        AddSlot.descriptor.name: { try decode(AddSlot.self, AddSlot.descriptor.name, $0) },
        StartRoutine.descriptor.name: { try decode(StartRoutine.self, StartRoutine.descriptor.name, $0) },
        CreatePlan.descriptor.name: { try decode(CreatePlan.self, CreatePlan.descriptor.name, $0) },
        LogNextSet.descriptor.name: { try decode(LogNextSet.self, LogNextSet.descriptor.name, $0) },
        MoveSlot.descriptor.name: { try decode(MoveSlot.self, MoveSlot.descriptor.name, $0) },
        EditSlot.descriptor.name: { try decode(EditSlot.self, EditSlot.descriptor.name, $0) },
        SwapSlotExercise.descriptor.name: { try decode(SwapSlotExercise.self, SwapSlotExercise.descriptor.name, $0) },
        SwapEntryExercise.descriptor
            .name: { try decode(SwapEntryExercise.self, SwapEntryExercise.descriptor.name, $0) },
    ]

    private static func decode<A: EngineAction>(_ type: A.Type, _ name: String, _ arguments: Data) throws -> A {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(type, from: arguments)
        } catch let DecodingError.keyNotFound(key, _) {
            throw ActionError.invalidArguments(action: name, reason: "missing \(key.stringValue)")
        } catch let DecodingError.typeMismatch(_, context) {
            throw ActionError.invalidArguments(action: name, reason: "wrong type for \(path(context))")
        } catch let DecodingError.valueNotFound(_, context) {
            throw ActionError.invalidArguments(action: name, reason: "missing value for \(path(context))")
        } catch {
            throw ActionError.invalidArguments(action: name, reason: "unreadable arguments")
        }
    }

    private static func path(_ context: DecodingError.Context) -> String {
        context.codingPath.map(\.stringValue).joined(separator: ".")
    }
}
