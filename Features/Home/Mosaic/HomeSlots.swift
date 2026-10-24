import SwiftUI

/// Home's five fixed slots (sheet 236 v2), in screen points from the top of the screen. The board's own numbers hold
/// exactly at 402x874 and 390x844; other heights place the slots by the same slope, and the one thing (196 to 232 pt)
/// shares the difference with the gaps. Pure, so it tests without a screen.
struct HomeSlots: Equatable {
    static let boardHeight: CGFloat = 96
    static let mosaicHeight: CGFloat = 160
    static let appsHeight: CGFloat = 120
    static let footHeight: CGFloat = 72

    /// Screen y of the board's top, and the gaps under the board, the mosaic and the one thing.
    let boardTop: CGFloat
    let gapBoard: CGFloat
    let gapMosaic: CGFloat
    let gapThing: CGFloat
    let thing: CGFloat

    /// The two designed heights and the numbers drawn for them.
    private static let small = (height: CGFloat(844), top: CGFloat(66), gap: CGFloat(26), gapThing: CGFloat(24),
                                thing: CGFloat(204))
    private static let large = (height: CGFloat(874), top: CGFloat(84), gap: CGFloat(30), gapThing: CGFloat(28),
                                thing: CGFloat(212))

    static func make(screenHeight: CGFloat) -> HomeSlots {
        let t = (screenHeight - small.height) / (large.height - small.height)
        func mix(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
            a + (b - a) * t
        }
        let thing = min(max(mix(small.thing, large.thing), 196), 232)
        return HomeSlots(boardTop: max(mix(small.top, large.top), 44), gapBoard: max(mix(small.gap, large.gap), 16),
                         gapMosaic: max(mix(small.gap, large.gap), 16), gapThing: max(
                             mix(small.gapThing, large.gapThing),
                             14
                         ),
                         thing: thing)
    }

    /// Screen y of the top of each slot.
    var mosaicTop: CGFloat {
        boardTop + Self.boardHeight + gapBoard
    }

    var thingTop: CGFloat {
        mosaicTop + Self.mosaicHeight + gapMosaic
    }

    var appsTop: CGFloat {
        thingTop + thing + gapThing
    }
}
