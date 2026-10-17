import Foundation
@testable import TesseraCore
import Testing

/// G44 (docs/product/kitchen-test-specs-wall-g40-g43-g44-oct17.md B3): a shop never goes idle on its own.
@MainActor
struct ShoppingIdleTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let idle = ProcessTable.Limits.idleShop

    /// 12 rows, a running shop started at `t0`, all 12 checked an hour later.
    func shop(checked: Int = 12) throws -> (engine: ActionEngine, store: ObjectStore, table: ProcessTable) {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(AddGroceries(lines: (1 ... 12).map { "thing\($0)" }), by: .user)
        try engine.perform(StartShop(time: t0), by: .user)
        let groceries = Groceries(store: store, classes: classes)
        for row in groceries.shoppingOrder().prefix(checked) {
            try engine.perform(CheckListItem(item: row.id, time: t0 + 3600), by: .user)
        }
        return (engine, store, ProcessTable(engine: engine))
    }

    @Test func idleLimitIsTwelveHours() {
        #expect(idle == 12 * 3600)
    }

    @Test func runningShopGoesIdleOvernight() throws {
        let (engine, _, table) = try shop()
        let touched = t0 + 3600
        let suspended = try #require(table.suspendIfIdle(now: touched + idle + 60, idleLimit: idle))
        #expect(table.running() == nil)
        let now = try #require(table.all().first { $0.id == suspended.id })
        #expect(now.state == .suspended)
        #expect(now.lastTouchedAt == touched)
        let record = try #require(engine.history(limit: 5).first { $0.action == SuspendProcess.descriptor.name })
        #expect(record.actor == .system)
    }

    @Test func shopTouchedRecentlyStaysRunning() throws {
        let (_, _, table) = try shop()
        #expect(table.suspendIfIdle(now: t0 + 3600 + idle - 60, idleLimit: idle) == nil)
        #expect(table.running() != nil)
    }

    @Test func checkingARowResetsTheShopIdleClock() throws {
        let (engine, store, table) = try shop(checked: 11)
        let groceries = Groceries(store: store, classes: engine.classes)
        let row = try #require(groceries.shoppingOrder().first)
        try engine.perform(CheckListItem(item: row.id, time: t0 + 11 * 3600), by: .user)
        #expect(table.suspendIfIdle(now: t0 + 13 * 3600, idleLimit: idle) == nil)
        #expect(table.running() != nil)
    }

    @Test func idleShopKeepsItsBasket() throws {
        let (engine, store, table) = try shop()
        let groceries = Groceries(store: store, classes: engine.classes)
        let line = groceries.shoppingLine()
        _ = table.suspendIfIdle(now: t0 + 3600 + idle + 60, idleLimit: idle)
        let rows = try ListContents(store: store, classes: engine.classes).items(of: #require(groceries.list))
        #expect(rows.count == 12 && rows.allSatisfy { $0.isDone } && rows.allSatisfy { !$0.object.isDeleted })
        #expect(groceries.shoppingLine() == line)
    }

    @Test func idleShopResumesWithStartShop() throws {
        let (engine, _, table) = try shop()
        let id = try #require(table.running()).id
        _ = table.suspendIfIdle(now: t0 + 3600 + idle + 60, idleLimit: idle)
        try engine.perform(StartShop(time: t0 + 20 * 3600), by: .user)
        #expect(table.running()?.id == id)
    }

    @Test func workoutIdleRuleUnchanged() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        try engine.perform(StartProcess(subject: workout.id, time: t0), by: .user)
        let table = ProcessTable(engine: engine)
        #expect(table.suspendIfIdle(now: t0 + 5 * 60, idleLimit: 12 * 60) == nil)
        #expect(table.suspendIfIdle(now: t0 + 13 * 60, idleLimit: 12 * 60) != nil)
        #expect(table.running() == nil)
    }

    @Test func putAwayShopNoteCountsTheBasket() throws {
        let (engine, _, table) = try shop()
        _ = table.suspendIfIdle(now: t0 + 3600 + idle + 60, idleLimit: idle)
        let notes = table.tidyNotes(now: t0 + 3600 + ProcessTable.Limits.putAway + 60)
        #expect(notes.map(\.line) == ["Shopping moved to Later. 12 in the basket."])
        #expect(notes.first?.undo == nil)
        #expect(table.later().count == 1)
        #expect(engine.classes.isEmpty == false)
    }

    @Test func putAwayShopWithNothingCheckedKeepsTheGenericNote() throws {
        let (_, _, table) = try shop(checked: 0)
        _ = table.suspendIfIdle(now: t0 + idle + 60, idleLimit: idle)
        let notes = table.tidyNotes(now: t0 + ProcessTable.Limits.putAway + 60)
        #expect(notes.map(\.line) == ["One thing moved to Later."])
    }

    @Test func putAwayShopKeepsRowsForPantry() throws {
        let (engine, store, table) = try shop()
        _ = table.suspendIfIdle(now: t0 + 3600 + idle + 60, idleLimit: idle)
        _ = table.tidyNotes(now: t0 + 3600 + ProcessTable.Limits.putAway + 60)
        let list = try #require(Groceries(store: store, classes: engine.classes).list)
        let rows = ListContents(store: store, classes: engine.classes).items(of: list)
        #expect(rows.count == 12)
        #expect(rows.allSatisfy { $0.isDone && $0.checkedAt != nil && !$0.object.isDeleted })
    }
}
