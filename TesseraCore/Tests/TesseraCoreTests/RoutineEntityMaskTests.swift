import AppIntents
import Foundation
@testable import TesseraCore
@testable import TesseraIntents
import Testing

/// A private routine's words never reach Shortcuts, Siri's picker or Spotlight: one masked constructor serves the
/// by-id lookup, the suggestions, the search and the entity's display.
@MainActor
struct RoutineEntityMaskTests {
    let store = ObjectStore.open(inMemory: true)

    func runtime() throws -> TesseraRuntime {
        let classes = try store.prepareCatalog()
        return TesseraRuntime(engine: ActionEngine(store: store, classes: classes))
    }

    func routine(_ title: String, _ runtime: TesseraRuntime) throws -> ObjectRecord {
        try runtime.engine.perform(CreateRoutine(title: title), by: .user).output
    }

    @Test(arguments: ["Lexapro day", "Weigh in 82.4 kg"])
    func routineEntityTitleIsMaskedForPrivateRoutine(_ title: String) throws {
        let runtime = try runtime()
        let private_ = try routine(title, runtime)
        let entity = RoutineEntity(routine: private_, in: store)
        #expect(entity.title == "Private workout")
        let shown = String(describing: entity.displayRepresentation.title)
        #expect(!shown.lowercased().contains("lexapro") && !shown.contains("82.4"), "\(shown)")
        let plain = try RoutineEntity(routine: routine("Push Day A", runtime), in: store)
        #expect(plain.title == "Push Day A")
    }

    @Test func suggestedRoutineEntitiesAreMasked() throws {
        let runtime = try runtime()
        let secret = try routine("Lexapro day", runtime)
        let plain = try routine("Push Day A", runtime)
        let suggested = Dictionary(uniqueKeysWithValues: RoutineQuery.all(runtime).map { ($0.id, $0.title) })
        #expect(suggested[secret.id] == "Private workout" && suggested[plain.id] == "Push Day A")
        let byID = Dictionary(uniqueKeysWithValues: RoutineQuery.entities(for: [secret.id, plain.id], runtime)
            .map { ($0.id, $0.title) })
        #expect(byID[secret.id] == "Private workout" && byID[plain.id] == "Push Day A")
    }

    @Test func routineQueryDoesNotMatchPrivateRoutineByRawTitle() throws {
        let runtime = try runtime()
        let secret = try routine("Lexapro day", runtime)
        #expect(RoutineQuery.entities(matching: "lexapro", runtime).isEmpty)
        #expect(RoutineQuery.entities(matching: "Lexapro day", runtime).isEmpty)
        #expect(RoutineQuery.entities(matching: "Private workout", runtime).map(\.id) == [secret.id])
        // The op log keeps the raw title.
        #expect(secret.title == "Lexapro day")
    }
}
