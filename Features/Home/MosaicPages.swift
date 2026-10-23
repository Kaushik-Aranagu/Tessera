import Foundation
import TesseraCore

// The mosaic's page. Sheet 213's one-thing pages replaced the mosaic's own weather, next and week pages (their art and
// their made-up facts are gone); what is left is the one page, the wipe between things and the wash toward a thing's
// accent.

enum MosaicPage: Int, CaseIterable, Equatable {
    case mood

    /// How many pages B's pager has: the mood only.
    static let count = 1

    /// The wipe between pages: 0.6 s, in the swipe's direction.
    static let wipeSeconds: TimeInterval = 0.6
    /// How far the mosaic washes toward the shown thing's accent (sheet 213).
    static let thingWash = 0.20
}
