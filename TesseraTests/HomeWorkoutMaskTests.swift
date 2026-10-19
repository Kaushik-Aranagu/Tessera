@testable import Tessera
import TesseraCore
import Testing

/// G274 / G591: a private routine or workout reads "Private workout" on Home's ledger row and its Resume key, the
/// same check Tess's done line uses; "Balance and core" (bare words never mask) reads as typed.
@MainActor
struct HomeWorkoutMaskTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private func runningRow(_ title: String) throws -> (title: String, nextStep: String?) {
        let workout = try model.store.create(#require(model.classes[.workout]), title: title)
        try model.engine.perform(StartWorkout(workout: workout.id), by: .user)
        let process = try #require(ProcessTable(engine: model.engine).running())
        return LedgerRow.shown(process, store: model.store, classes: model.classes, lastWeightKg: nil)
    }

    @Test func aPrivateWorkoutReadsPrivateWorkoutOnItsRow() throws {
        #expect(try runningRow("Knee rehab day").title == ObjectPrivacy.routineLabel)
    }

    @Test func anOrdinaryWorkoutKeepsItsName() throws {
        #expect(try runningRow("Balance and core").title == "Balance and core")
    }

    /// The hero and Training read through the same function, so they agree with the row.
    @Test func everySurfaceUsesTheOneCheck() {
        #expect(ObjectPrivacy.routineTitle("Therapy legs", in: model.store) == "Private workout")
        #expect(ObjectPrivacy.routineTitle("Push A", in: model.store) == "Push A")
    }
}
