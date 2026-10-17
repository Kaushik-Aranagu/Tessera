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
        EditSlot.descriptor, RemoveSlot.descriptor,
        SwapSlotExercise.descriptor,
        SwapEntryExercise.descriptor, MoveTask.descriptor, CreateNote.descriptor, EditNote.descriptor,
        StartShop.descriptor, FinishShop.descriptor,
        StartCooking.descriptor, GoToCookStep.descriptor, StartKitchenTimer.descriptor, StopKitchenTimer.descriptor,
        FinishCooking.descriptor,
        AddRecipeToGroceries.descriptor, RemoveRecipeFromGroceries.descriptor, AddGroceries.descriptor,
        CreateRecipe.descriptor, EditRecipe.descriptor,
        CreateList.descriptor, AddListItem.descriptor, CheckListItem.descriptor, MoveListItem.descriptor,
        RenameListSection.descriptor, ClearDoneItems.descriptor,
        FinishWorkoutEarly.descriptor,
        RollForwardTasks.descriptor, StartTask.descriptor,
        WaitOnTask.descriptor, KeepPlannedTask.descriptor,
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
        KeepPlannedTask.descriptor.name: { try decode(KeepPlannedTask.self, KeepPlannedTask.descriptor.name, $0) },
        CreateNote.descriptor.name: { try decode(CreateNote.self, CreateNote.descriptor.name, $0) },
        EditNote.descriptor.name: { try decode(EditNote.self, EditNote.descriptor.name, $0) },
        StartShop.descriptor.name: { try decode(StartShop.self, StartShop.descriptor.name, $0) },
        FinishShop.descriptor.name: { try decode(FinishShop.self, FinishShop.descriptor.name, $0) },
        StartCooking.descriptor.name: { try decode(StartCooking.self, StartCooking.descriptor.name, $0) },
        GoToCookStep.descriptor.name: { try decode(GoToCookStep.self, GoToCookStep.descriptor.name, $0) },
        StartKitchenTimer.descriptor
            .name: { try decode(StartKitchenTimer.self, StartKitchenTimer.descriptor.name, $0) },
        StopKitchenTimer.descriptor.name: { try decode(StopKitchenTimer.self, StopKitchenTimer.descriptor.name, $0) },
        FinishCooking.descriptor.name: { try decode(FinishCooking.self, FinishCooking.descriptor.name, $0) },
        AddRecipeToGroceries.descriptor.name: { try decode(
            AddRecipeToGroceries.self,
            AddRecipeToGroceries.descriptor.name,
            $0
        ) },
        RemoveRecipeFromGroceries.descriptor.name: { try decode(
            RemoveRecipeFromGroceries.self,
            RemoveRecipeFromGroceries.descriptor.name,
            $0
        ) },
        AddGroceries.descriptor.name: { try decode(AddGroceries.self, AddGroceries.descriptor.name, $0) },
        CreateRecipe.descriptor.name: { try decode(CreateRecipe.self, CreateRecipe.descriptor.name, $0) },
        EditRecipe.descriptor.name: { try decode(EditRecipe.self, EditRecipe.descriptor.name, $0) },
        CreateList.descriptor.name: { try decode(CreateList.self, CreateList.descriptor.name, $0) },
        AddListItem.descriptor.name: { try decode(AddListItem.self, AddListItem.descriptor.name, $0) },
        CheckListItem.descriptor.name: { try decode(CheckListItem.self, CheckListItem.descriptor.name, $0) },
        MoveListItem.descriptor.name: { try decode(MoveListItem.self, MoveListItem.descriptor.name, $0) },
        RenameListSection.descriptor
            .name: { try decode(RenameListSection.self, RenameListSection.descriptor.name, $0) },
        ClearDoneItems.descriptor.name: { try decode(ClearDoneItems.self, ClearDoneItems.descriptor.name, $0) },
        FinishWorkoutEarly.descriptor.name: {
            try decode(FinishWorkoutEarly.self, FinishWorkoutEarly.descriptor.name, $0)
        },
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
        AddRoutineToPlan.descriptor.name: { try decode(AddRoutineToPlan.self, AddRoutineToPlan.descriptor.name, $0) },
        MoveRoutineInPlan.descriptor.name: {
            try decode(MoveRoutineInPlan.self, MoveRoutineInPlan.descriptor.name, $0)
        },
        DropRoutineFromPlan.descriptor.name: {
            try decode(DropRoutineFromPlan.self, DropRoutineFromPlan.descriptor.name, $0)
        },
        SetScheduleMode.descriptor.name: { try decode(SetScheduleMode.self, SetScheduleMode.descriptor.name, $0) },
        SetRoutineWeekdays.descriptor.name: {
            try decode(SetRoutineWeekdays.self, SetRoutineWeekdays.descriptor.name, $0)
        },
        RememberFact.descriptor.name: { try decode(RememberFact.self, RememberFact.descriptor.name, $0) },
        ForgetMemory.descriptor.name: { try decode(ForgetMemory.self, ForgetMemory.descriptor.name, $0) },
        ForgetAllMemory.descriptor.name: { try decode(ForgetAllMemory.self, ForgetAllMemory.descriptor.name, $0) },
        LogNextSet.descriptor.name: { try decode(LogNextSet.self, LogNextSet.descriptor.name, $0) },
        MoveSlot.descriptor.name: { try decode(MoveSlot.self, MoveSlot.descriptor.name, $0) },
        EditSlot.descriptor.name: { try decode(EditSlot.self, EditSlot.descriptor.name, $0) },
        RemoveSlot.descriptor.name: { try decode(RemoveSlot.self, RemoveSlot.descriptor.name, $0) },
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
