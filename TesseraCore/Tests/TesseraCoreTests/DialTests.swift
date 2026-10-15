import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct DialTests {
    @Test func barbellDialSnapsToLoadableWeightsAndShowsPlates() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let dial = try store.weightDial(for: #require(classes[.benchPress]))
        #expect(dial.equipment == .barbell && dial.bar == 20)
        #expect(dial.detents.first == 20)
        #expect(dial.snap(81.4) == 82.5)
        #expect(dial.step(from: 80, by: 1) == 82.5 && dial.step(from: 80, by: -2) == 75)
        #expect(dial.platesPerSide(82.5) == [25, 5, 1.25])
        #expect(dial.plateLine(82.5) == "25 + 5 + 1.25")
        #expect(dial.plateLine(20) == "bar")
        #expect(dial.platesPerSide(83) == nil)

        let dumbbells = try store
            .weightDial(for: #require(store.classDef(id: SystemCatalog.stableID("library.dbCurl"))))
        #expect(dumbbells.equipment == .dumbbell && dumbbells.bar == nil)
        #expect(dumbbells.step(from: 12, by: 1) == 14)
        #expect(dumbbells.plateLine(12) == nil)
    }
}
