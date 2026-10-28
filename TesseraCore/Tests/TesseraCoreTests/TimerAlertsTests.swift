import Foundation
@testable import TesseraCore
import Testing

/// G217, G222: one local notification per running kitchen timer, kept in step with the timers whatever stopped one.
@MainActor
struct TimerAlertsTests {
    final class Spy: TimerAlertScheduler {
        var scheduled: [UUID: TimerAlert] = [:]
        var permissionAsks = 0

        func requestPermissionIfNeeded() async {
            permissionAsks += 1
        }

        func schedule(_ alert: TimerAlert) async {
            scheduled[alert.id] = alert
        }

        func cancel(ids: [UUID]) async {
            ids.forEach { scheduled[$0] = nil }
        }

        func scheduledIDs() async -> Set<UUID> {
            Set(scheduled.keys)
        }
    }

    let store = ObjectStore.open(inMemory: true)
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func setUp() throws -> (ActionEngine, KitchenTimerAlerts) {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        return (engine, KitchenTimerAlerts(store: store, classes: classes))
    }

    @Test func aRunningTimerGetsOneAlertAtItsEnd() async throws {
        let (engine, alerts) = try setUp()
        let spy = Spy()
        let timer = try engine.perform(StartKitchenTimer(label: "pasta", minutes: 10, time: start), by: .user).output
        await alerts.reconcile(with: spy, now: start)
        #expect(spy.scheduled[timer.id] == TimerAlert(id: timer.id, label: "Pasta", fireAt: start + 600))
        #expect(spy.scheduled[timer.id]?.body == "Pasta is done")
        #expect(spy.permissionAsks == 1)
        // Again, nothing new: one request per timer, permission not asked twice.
        await alerts.reconcile(with: spy, now: start + 30)
        #expect(spy.scheduled.count == 1 && spy.permissionAsks == 1)
    }

    @Test func stopFinishAndUndoAllCancelIt() async throws {
        let (engine, alerts) = try setUp()
        let spy = Spy()
        // Stop.
        let stopped = try engine.perform(StartKitchenTimer(label: "rice", minutes: 15, time: start), by: .user).output
        await alerts.reconcile(with: spy, now: start)
        try engine.perform(StopKitchenTimer(timer: stopped.id), by: .user)
        await alerts.reconcile(with: spy, now: start + 60)
        #expect(spy.scheduled.isEmpty)
        // Undo of the start.
        let started = try engine.perform(StartKitchenTimer(label: "eggs", minutes: 8, time: start), by: .user)
        await alerts.reconcile(with: spy, now: start)
        #expect(spy.scheduled.count == 1)
        engine.undo(started.record)
        await alerts.reconcile(with: spy, now: start + 60)
        #expect(spy.scheduled.isEmpty)
        // Finish cooking stops its timers.
        let recipe = try engine.perform(
            CreateRecipe(text: "Dal\nIngredients\n1 cup lentils\nMethod\n1. Simmer 20 minutes."), by: .user
        ).output
        let cook = try engine.perform(StartCooking(recipe: recipe.id, time: start), by: .user).output
        try engine.perform(StartKitchenTimer(label: "dal", minutes: 20, cook: cook.id, time: start), by: .user)
        await alerts.reconcile(with: spy, now: start)
        #expect(spy.scheduled.count == 1)
        try engine.perform(FinishCooking(cook: cook.id, time: start + 300), by: .user)
        await alerts.reconcile(with: spy, now: start + 300)
        #expect(spy.scheduled.isEmpty)
    }

    @Test func aTimerAlreadyPastItsEndGetsNoAlertAndNoPermissionAsk() async throws {
        let (engine, alerts) = try setUp()
        let spy = Spy()
        try engine.perform(StartKitchenTimer(label: "toast", minutes: 2, time: start), by: .user)
        await alerts.reconcile(with: spy, now: start + 600)
        #expect(spy.scheduled.isEmpty && spy.permissionAsks == 0)
    }

    @Test func aPrivateLabelReadsTimer() async throws {
        let (engine, alerts) = try setUp()
        let spy = Spy()
        try engine.perform(StartKitchenTimer(label: "lexapro", minutes: 5, time: start), by: .user)
        await alerts.reconcile(with: spy, now: start)
        #expect(spy.scheduled.values.map(\.title) == ["Timer"] && spy.scheduled.values
            .map(\.body) == ["Timer is done"])
    }

    @Test(arguments: [
        ("lexapro", "Timer is done"),
        ("10", "Timer is done"),
        ("", "Timer is done"),
        ("  ", "Timer is done"),
        ("Rice", "Rice is done"),
    ])
    func theBodyNamesTheTimerOrSaysTimer(_ label: String, _ body: String) async throws {
        let (engine, alerts) = try setUp()
        let spy = Spy()
        try engine.perform(StartKitchenTimer(label: label, minutes: 5, time: start), by: .user)
        await alerts.reconcile(with: spy, now: start)
        let alert = try #require(spy.scheduled.values.first)
        #expect(alert.title == "Timer" && alert.body == body, "\(label) -> \(alert.body)")
    }

    @Test func thePlanAddsWhatIsMissingAndCancelsWhatIsStale() {
        let one = TimerAlert(id: UUID(), label: "a", fireAt: start)
        let two = TimerAlert(id: UUID(), label: "b", fireAt: start)
        let stale = UUID()
        let plan = KitchenTimerAlerts.plan(wanted: [one, two], scheduled: [two.id, stale])
        #expect(plan.add == [one] && plan.cancel == [stale])
    }

    // MARK: A private recipe's cook

    @Test func aPrivateRecipesTimerReadsTimerWhateverItsLabel() async throws {
        let (engine, alerts) = try setUp()
        let spy = Spy()
        let recipe = try engine.perform(
            CreateRecipe(text: "Melatonin lasagna\nIngredients\n2 onions\nMethod\n1. Bake 30 minutes."), by: .user
        ).output
        let cook = try engine.perform(StartCooking(recipe: recipe.id, time: start), by: .user).output
        try engine.perform(StartKitchenTimer(label: "lasagna", minutes: 30, cook: cook.id, time: start), by: .user)
        await alerts.reconcile(with: spy, now: start)
        let alert = try #require(spy.scheduled.values.first)
        #expect(alert.title == "Timer" && alert.body == "Timer is done", "\(alert.body)")
    }

    @Test func aPrivateCooksStepAndFinishLineCarryNoWords() throws {
        let (engine, _) = try setUp()
        let recipe = try engine.perform(
            CreateRecipe(text: "Melatonin lasagna\nIngredients\n2 onions\nMethod\n1. Crush the melatonin.\n2. Bake."),
            by: .user
        ).output
        let cook = try engine.perform(StartCooking(recipe: recipe.id, time: start), by: .user).output
        let table = ProcessTable(engine: engine)
        #expect(table.running()?.nextStep == "Private recipe", "\(table.running()?.nextStep ?? "nil")")
        try engine.perform(GoToCookStep(cook: cook.id, step: 1, time: start + 60), by: .user)
        #expect(table.running()?.nextStep == "Private recipe")
        let line = CookLog(store: store, classes: engine.classes).finishLine(for: recipe, at: start + 120)
        #expect(!line.lowercased().contains("lasagna") && line.hasPrefix("Private recipe,"), "\(line)")
    }

    @Test func aPlainCookKeepsItsStepAndFinishLine() throws {
        let (engine, _) = try setUp()
        let recipe = try engine.perform(
            CreateRecipe(text: "Tacos\nIngredients\n2 onions\nMethod\n1. Fry the onions."), by: .user
        ).output
        let cook = try engine.perform(StartCooking(recipe: recipe.id, time: start), by: .user).output
        #expect(ProcessTable(engine: engine).running()?.nextStep == "Fry the onions.")
        #expect(CookLog(store: store, classes: engine.classes).finishLine(for: recipe, at: start + 120)
            .hasPrefix("Tacos,"))
    }

    @Test func aPrivateCooksTimerReadsTimerOnNow() throws {
        let (engine, _) = try setUp()
        let recipe = try engine.perform(
            CreateRecipe(text: "Melatonin lasagna\nIngredients\n2 onions\nMethod\n1. Bake 30 minutes."), by: .user
        ).output
        let cook = try engine.perform(StartCooking(recipe: recipe.id, time: start), by: .user).output
        try engine.perform(StartKitchenTimer(label: "lasagna", minutes: 30, cook: cook.id, time: start), by: .user)
        let now = NowPicker(engine: engine).pick(at: start + 30).now
        #expect(now?.nextStep == "Timer, 30 min", "\(now?.nextStep ?? "nil")")
    }

    @Test func aPrivateWordTimerOnAPlainCookReadsTimerOnNow() throws {
        let (engine, _) = try setUp()
        let recipe = try engine.perform(
            CreateRecipe(text: "Tacos\nIngredients\n2 onions\nMethod\n1. Fry."), by: .user
        ).output
        let cook = try engine.perform(StartCooking(recipe: recipe.id, time: start), by: .user).output
        try engine.perform(StartKitchenTimer(label: "lexapro", minutes: 5, cook: cook.id, time: start), by: .user)
        #expect(NowPicker(engine: engine).pick(at: start + 30).now?.nextStep == "Timer, 5 min")
    }
}
