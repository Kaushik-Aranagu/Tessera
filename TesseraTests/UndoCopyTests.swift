@testable import Tessera
import Testing

/// K36.2 (Product 10:55): UNDO names what it took back, thing first.
struct UndoCopyTests {
    @Test func theThingThenTakenBack() {
        #expect(UndoCopy.takenBack(after: "Tacos, 7 added.") == "Tacos, taken back.")
        #expect(UndoCopy.takenBack(after: "Milk and eggs, on Groceries.") == "Milk and eggs, taken back.")
        #expect(UndoCopy.takenBack(after: "Private item, on Groceries.") == "Private item, taken back.")
        #expect(UndoCopy.takenBack(after: "Cleared 3 from the basket.") == "Taken back.")
    }
}
