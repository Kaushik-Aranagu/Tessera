import Foundation
@testable import Tessera
import TesseraCore

/// The one file that holds the Chart room's test data, so it is easy to swap. Core's `RoomFixture.chart` (all twelve
/// kinds, over a Plant class, one grant) is the document; the plants are the board's, through `DemoRoomData`.
enum ChartFixture {
    static var document: ChartDoc {
        ChartDoc(RoomFixture.chart)
    }

    /// The same room as JSON text, the shape Core stores.
    static var json: String {
        document.encoded()
    }

    /// The tool's shape from the spec, section 2.
    static let patchJSON = """
    {"room": "Chart room", "say": "Plants, set", "ops": [
      {"op": "add", "id": "title", "kind": "title", "place": "title", "props": {"text": "Plants"}},
      {"op": "add", "id": "line", "kind": "line", "place": "switcher",
       "props": {"text": "{count} plants, the {top} is thirsty"}, "bind": "Plant"},
      {"op": "set", "id": "list", "props": {"sort": "-daysSince(lastWatered)"}},
      {"op": "look", "trait": "motion", "value": "calm"},
      {"op": "grant", "reach": "write Plant.lastWatered"},
      {"op": "remove", "id": "old"},
      {"op": "move", "id": "list", "place": "widget", "index": 0}]}
    """
}
