import Foundation
import TesseraCore

/// What the layer needs of a face for one retarget: the art for the current face and its neighbours, the tint every
/// face tile goes through (the colour rule and the look), the baked colour of a tile, the live light that redraws only
/// what changed since the bake (a ticking numeral, a scene's one slow life), and the 1:1 slide under the finger.
struct MosaicFaceRig {
    let art: MosaicFaceArt?
    private let drag: MosaicFaceDrag?
    private let ground: MosaicTriple
    private let dark: Bool
    private let calm: Bool
    private let bake: Date

    struct Setup {
        var face: MosaicFace?
        var neighbours: (previous: MosaicFace?, next: MosaicFace?)
        var model: MosaicFaceModel?
        var palette: MosaicFacePalette
        var columns: Int
        var ground: MosaicTriple
        var dark: Bool
        /// Reduce Motion or Low Power: faces hold still (numerals still tick).
        var calm: Bool
        var bake: Date
    }

    init(_ setup: Setup) {
        let palette = setup.palette
        let bake = setup.bake
        func makeArt(_ face: MosaicFace, columns: Int) -> MosaicFaceArt {
            MosaicFaceArt(face: face, columns: columns, rows: MosaicFaceArt.rowsDefault, palette: palette, now: bake)
        }
        let current = setup.face.map { makeArt($0, columns: setup.columns) }
        art = current
        drag = setup.model?.drag
        ground = setup.ground
        dark = setup.dark
        calm = setup.calm
        self.bake = bake
        if let drag = setup.model?.drag {
            drag.arts = .init(previous: setup.neighbours.previous.map { makeArt($0, columns: $0.width) },
                              current: current, next: setup.neighbours.next.map { makeArt($0, columns: $0.width) })
            drag.width = setup.columns
        }
    }

    /// The colour rule and the look's tint, for every face tile.
    func tint(_ colour: MosaicTriple) -> MosaicTriple {
        MosaicSceneArt.tinted(MosaicSceneArt.safe(colour), ground: ground, dark: dark)
    }

    /// The baked colour of a window tile, nil with no face.
    func colour(column: Int, row: Int) -> MosaicTriple? {
        art.map { art in
            tint(art.colour(column: min(column, art.columns - 1), row: min(row, art.rows - 1), animation: 0,
                            now: bake))
        }
    }

    /// The live light: a tile that differs from its bake is drawn as it is now.
    var light: MosaicMoodField.Overlay? {
        guard let art else { return nil }
        let frame = FaceFrame()
        let calm = calm, bake = bake
        return { column, row, time, colour in
            let now = frame.now(at: time)
            let still = tint(art.colour(column: column, row: row, animation: 0, now: bake))
            let live = tint(art.colour(column: column, row: row, animation: calm ? 0 : time, now: now))
            guard live.red != still.red || live.green != still.green || live.blue != still.blue else {
                return colour
            }
            return live
        }
    }

    /// The engine's overlay: `inner` (a face's or a mood's light) with the slide over it while a finger is down.
    func overlay(_ inner: MosaicMoodField.Overlay?, mapped: @escaping (Int, Int) -> (Int, Int))
        -> (Int, Int, TimeInterval, MosaicTriple) -> MosaicTriple
    {
        let frame = FaceFrame()
        let drag = drag
        return { column, row, time, colour in
            let place = mapped(column, row)
            let base = inner?(place.0, place.1, time, colour) ?? colour
            guard let drag, drag.isActive,
                  let slid = slid(drag, column: place.0, row: place.1, time: time, now: frame.now(at: time))
            else { return base }
            return slid
        }
    }

    /// A tile while the faces slide (1:1, nothing over them): the current face moved by the travel and its neighbour
    /// following it, both live.
    private func slid(_ drag: MosaicFaceDrag, column: Int, row: Int, time: TimeInterval, now: Date) -> MosaicTriple? {
        let shift = Int(drag.shift().rounded())
        guard shift != 0, let current = drag.arts.current else { return nil }
        let x = column - shift
        func colour(_ art: MosaicFaceArt, _ own: Int) -> MosaicTriple {
            tint(art.colour(column: own, row: min(row, art.rows - 1), animation: calm ? 0 : time, now: now))
        }
        if (0 ..< current.columns).contains(x) {
            return colour(current, x)
        }
        if shift < 0, let next = drag.arts.next {
            let own = x - current.columns
            return (0 ..< next.columns).contains(own) ? colour(next, own) : ground
        }
        if shift > 0, let previous = drag.arts.previous {
            let own = x + previous.columns
            return (0 ..< previous.columns).contains(own) ? colour(previous, own) : ground
        }
        return ground
    }

    // MARK: Arrival

    enum Arrival: Equatable {
        /// Already there (the finger slid it, or a quiet change): settle with no changeover.
        case settle
        case morph(MosaicChangeoverKind, total: TimeInterval?)
    }

    /// How a new face comes in: slid by the finger, one of the sheet 200 changeovers, the page's wipe in the swipe's
    /// direction, or a plain swap.
    static func arrival(_ transition: MosaicFaceTransition) -> Arrival {
        switch transition {
        case .slid, .none: .settle
        case let .changeover(index):
            .morph(MosaicTurnPolicy.changeovers[index % MosaicTurnPolicy.changeovers.count], total: nil)
        case let .wipe(reverse): .morph(.wipeColumns(reverse: reverse), total: MosaicPage.wipeSeconds)
        case .plain: .morph(.standard(.wave), total: nil)
        }
    }
}

extension MosaicColour {
    /// Home 236 v2.2: on a light page the mosaic's blend (outside its frame) lifts saturation by 30% and deepens by
    /// 10%; inside its frame the mosaic keeps full strength, and on a dark page nothing changes.
    static let rimSaturation = 1.3
    static let rimDeepen = 0.10

    static func isLightPage(_ ground: MosaicTriple) -> Bool {
        0.2126 * ground.red + 0.7152 * ground.green + 0.0722 * ground.blue > 0.5
    }

    static func graded(_ colour: MosaicTriple) -> MosaicTriple {
        let luma = 0.2126 * colour.red + 0.7152 * colour.green + 0.0722 * colour.blue
        func lift(_ value: Double) -> Double {
            min(max(luma + (value - luma) * rimSaturation, 0), 1) * (1 - rimDeepen)
        }
        return (lift(colour.red), lift(colour.green), lift(colour.blue))
    }

    static func rimGrade(_ colour: MosaicTriple, ground: MosaicTriple) -> MosaicTriple {
        isLightPage(ground) ? graded(colour) : colour
    }
}
