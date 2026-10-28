import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// `about` links can point at any class. A query that walks one must read a Spend, an event or a sleep night as no
/// value, so money, calendar and sleep never reach an answer through a note, a task or a list item.
@MainActor
@Suite(.oldWalls)
struct QueryWallTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func make(_ key: SystemCatalog.Key, _ title: String) throws -> ObjectRecord {
        try store.create(#require(engine.classes[key]), title: title)
    }

    /// A note, a task and a list item, each about the same object.
    func about(_ target: ObjectRecord) throws {
        for key in [SystemCatalog.Key.note, .task, .listItem] {
            let object = try make(key, "Linked \(key.rawValue)")
            try store.setLinks("about", on: object, to: [target])
        }
    }

    func run(_ query: Query) throws -> QueryResult {
        try QueryEngine.run(query, engine: engine, now: .now, calendar: .current)
    }

    func targets() throws -> [(String, ObjectRecord)] {
        let spend = try make(.spend, "Blue door")
        try store.set("amount", to: .number(1850), on: spend)
        let event = try make(.event, "Sam catch-up")
        let night = try make(.sleepNight, "Night forty one")
        return [("spend", spend), ("event", event), ("sleep night", night)]
    }

    @Test func aboutALinkedMoneyEventOrSleepObjectReadsAsNoValue() throws {
        for (name, target) in try targets() {
            try about(target)
            for from in ["notes", "tasks", "list items"] {
                let titles = try run(Query(from: [from], group: "about.title", agg: Query.Agg(kind: "count")))
                #expect(!titles.line.contains(target.title), "\(from) about a \(name) leaked its title")
                let sum = try run(Query(from: [from], agg: Query.Agg(kind: "sum", field: "about.amount")))
                #expect(sum.value == nil || sum.value == 0, "\(from) about a \(name) summed a value")
                #expect(!sum.line.contains("1850") && !sum.line.contains("1,850"))
                let byClass = try run(Query(from: [from], where: [Query.Pred(field: "about.class", op: "=",
                                                                             value: target.classDef?.name)]))
                #expect(byClass.matched.isEmpty, "\(from) matched on a \(name) class")
            }
        }
    }

    @Test func theProbeSeesAllowedTargets() throws {
        let workout = try make(.workout, "Push A")
        try about(workout)
        let titles = try run(Query(from: ["notes"], group: "about.title", agg: Query.Agg(kind: "count")))
        #expect(titles.line.contains("Push A"), "\(titles.line)")
    }

    @Test func aPlainTaskLinkedToAWorkoutStillReads() throws {
        let workout = try make(.workout, "Push A")
        let task = try make(.task, "Log the session")
        try store.setLinks("about", on: task, to: [workout])
        let result = try run(Query(
            from: ["tasks"],
            where: [Query.Pred(field: "about.title", op: "=", value: "Push A")]
        ))
        #expect(result.matched == [task.id])
    }

    @Test func parentAndChildrenStepsAlsoStopAtTheAllowList() throws {
        let spend = try make(.spend, "Coffee")
        let note = try store.create(#require(engine.classes[.note]), title: "Under a spend", parent: spend)
        let parentTitle = try run(Query(from: ["notes"], where: [Query.Pred(field: "parent.title", op: "=",
                                                                            value: "Coffee")]))
        #expect(parentTitle.matched.isEmpty)
        let child = try store.create(#require(engine.classes[.spend]), title: "Kid", parent: note)
        let kids = try run(Query(from: ["notes"], group: "children.title", agg: Query.Agg(kind: "count")))
        #expect(!kids.line.contains(child.title))
    }

    @Test func aPrivateClassNameReadsAsNoValue() throws {
        let classDef = try #require(engine.classes[.exercise])
        let walled = store.createClass(name: "Weight 82.5 kg", parent: classDef)
        let entry = try store.create(#require(engine.classes[.exerciseEntry]), title: "Entry")
        try store.setClassLink("exercise", on: entry, to: walled)
        let result = try run(Query(from: ["entries"], group: "exercise.name", agg: Query.Agg(kind: "count")))
        #expect(!result.line.contains("82.5"))
    }
}
