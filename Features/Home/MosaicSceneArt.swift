import Foundation
import TesseraCore

// Sheet 214: the mosaic scene gallery. Eleven pixel scenes in whole tiles on the Home mosaic grid: city at dusk, beach,
// mountains and lake, woods, desert, rain on window, night sky, fields at sunrise, snow, harbor, autumn trees. Each
// scene is still except for one slow life: at most about one tile changing every 150 ms. A scene is only what the
// mosaic shows when no mood stripe is chosen; it never replaces a moment, a changeover or a reaction, which play on top
// of it, and its edge is the same dithered one as always. Under Reduce Motion (or Low Power) the scene is still.
// Looks: on Black the tiles tint 18% toward (20, 18, 26), dark looks 30%. No scene tile may sit within delta E 10 of
// cobalt or Ember (a test scans every scene).

enum MosaicSceneArt {
    /// The gap between life steps, and so the slowest a tile may change.
    static let stepSeconds = 0.15

    /// One scene's colour at a tile of a `columns` x `rows` window at `time` seconds (0 for a still scene).
    static func colour(_ scene: MosaicScenery, column: Int, row: Int, columns: Int, rows: Int, time: Double)
        -> MosaicTriple
    {
        let across = (Double(column) + 0.5) / Double(max(columns, 1))
        let down = (Double(row) + 0.5) / Double(max(rows, 1))
        let step = Int((time / stepSeconds).rounded(.down))
        let place = Place(
            column: column,
            row: row,
            columns: columns,
            rows: rows,
            across: across,
            down: down,
            step: step
        )
        let value: MosaicTriple = switch scene {
        case .cityAtDusk: city(place)
        case .beach: beach(place)
        case .mountainsAndLake: mountains(place)
        case .woods: woods(place, autumn: false)
        case .autumnTrees: woods(place, autumn: true)
        case .desert: desert(place)
        case .rainOnWindow: rain(place)
        case .nightSky: night(place)
        case .fieldsAtSunrise: fields(place)
        case .snow: snow(place)
        case .harbor: harbor(place)
        }
        return safe(value)
    }

    // MARK: The colour rule

    /// Cobalt (light and dark) and Ember (light and dark): nothing a scene draws may sit within delta E 10 of them.
    static let reserved: [UInt32] = [0x2A4FA8, 0x8FB5FF, 0xFF5A26, 0xE5341C, 0xFFA90F, 0xFF6B3D, 0xFF4A33, 0xFFC23D]
    static let minimumDistance = 10.5

    private static let reservedLab: [(l: Double, a: Double, b: Double)] = reserved.map {
        let lab = SoulCloud.oklab($0)
        return (lab.lightness, lab.greenRed, lab.blueYellow)
    }

    /// A colour pulled toward grey, at its own lightness, until it is clear of the reserved colours: a scene stays
    /// itself
    /// but never wears Tess's paint.
    static func safe(_ colour: MosaicTriple) -> MosaicTriple {
        func byte(_ value: Double) -> UInt32 {
            UInt32((min(max(value, 0), 1) * 255).rounded())
        }
        let hex = byte(colour.red) << 16 | byte(colour.green) << 8 | byte(colour.blue)
        let lab = SoulCloud.oklab(hex)
        func clear(_ keep: Double) -> Bool {
            reservedLab.allSatisfy { reserved in
                let dl = lab.lightness - reserved.l, da = lab.greenRed * keep - reserved.a
                let db = lab.blueYellow * keep - reserved.b
                return 100 * (dl * dl + da * da + db * db).squareRoot() >= minimumDistance
            }
        }
        if clear(1) {
            return colour
        }
        var low = 0.0, high = 1.0
        for _ in 0 ..< 7 {
            let middle = (low + high) / 2
            if clear(middle) {
                low = middle
            } else {
                high = middle
            }
        }
        let tone = SoulCloud.rgbInGamut(lightness: lab.lightness, greenRed: lab.greenRed * low,
                                        blueYellow: lab.blueYellow * low)
        return (tone.red, tone.green, tone.blue)
    }

    /// The look's tint: 18% toward (20, 18, 26) on Black, 30% on the dark looks, none on the light ones.
    static func tinted(_ colour: MosaicTriple, ground: MosaicTriple, dark: Bool) -> MosaicTriple {
        let luminance = 0.2126 * ground.red + 0.7152 * ground.green + 0.0722 * ground.blue
        let toward: MosaicTriple = (20.0 / 255, 18.0 / 255, 26.0 / 255)
        if luminance < 0.02 {
            return MosaicColour.mix(colour, toward, 0.18)
        }
        if dark {
            return MosaicColour.mix(colour, toward, 0.30)
        }
        // White is lightened x1.02; the other light looks keep the scene as drawn.
        return luminance > 0.9 ? MosaicColour.scaled(colour, 1.02) : colour
    }

    // MARK: Pieces

    struct Place {
        let column: Int
        let row: Int
        let columns: Int
        let rows: Int
        let across: Double
        let down: Double
        let step: Int
    }

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> MosaicTriple {
        (red / 255, green / 255, blue / 255)
    }

    private static func mix(_ first: MosaicTriple, _ second: MosaicTriple, _ amount: Double) -> MosaicTriple {
        MosaicColour.mix(first, second, min(max(amount, 0), 1))
    }

    /// A fixed number in 0 ..< 1 for a pair and a salt: the same tile every frame.
    static func hash(_ first: Int, _ second: Int, _ salt: Int = 0) -> Double {
        var value = UInt64(truncatingIfNeeded: first &* 73_856_093 ^ second &* 19_349_663 ^ salt &* 83_492_791)
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        value ^= value >> 31
        return Double(value % 1_000_000) / 1_000_000
    }

    /// Smooth value noise along one axis.
    private static func noise(_ position: Double, _ salt: Int) -> Double {
        let base = Int(position.rounded(.down))
        let fraction = position - Double(base)
        let eased = fraction * fraction * (3 - 2 * fraction)
        return hash(base, salt) * (1 - eased) + hash(base + 1, salt) * eased
    }

    /// Whether a life tile is lit at this step: each tile has its own offset in a cycle of `period` steps.
    private static func lit(_ place: Place, salt: Int, period: Int, duty: Int) -> Bool {
        let offset = Int(hash(place.column, place.row, salt) * Double(period))
        return (place.step + offset) % period < duty
    }

    /// A tile is a life site with probability `density`.
    private static func isSite(_ place: Place, salt: Int, density: Double) -> Bool {
        hash(place.column, place.row, salt &+ 1000) < density
    }

    // MARK: Scenes

    private static func city(_ place: Place) -> MosaicTriple {
        let height = 0.28 + noise(Double(place.column) / 3.2, 1) * 0.34 + (hash(place.column / 4, 2) > 0.7 ? 0.1 : 0)
        let ridge = 1 - height
        if place.down < ridge {
            let sky = mix(rgb(64, 58, 110), rgb(224, 150, 118), place.down / max(ridge, 0.01) * 0.9)
            return place.down < 0.25 && hash(place.column, place.row, 3) > 0.995 ? rgb(244, 236, 220) : sky
        }
        let window = place.column % 4 != 0 && place.row % 3 != 0 && place.down > ridge + 0.05
        let body = mix(rgb(40, 36, 62), rgb(62, 52, 82), (place.down - ridge) / max(height, 0.01))
        guard window, hash(place.column, place.row, 4) > 0.55 else { return body }
        // A few windows blink on and off, a tile at a time.
        let blinks = isSite(place, salt: 5, density: 0.12)
        let on = blinks ? lit(place, salt: 6, period: 120, duty: 60) : true
        return on ? rgb(244, 206, 122) : body
    }

    private static func beach(_ place: Place) -> MosaicTriple {
        if place.down < 0.42 {
            return mix(rgb(150, 196, 214), rgb(244, 220, 186), place.down / 0.42)
        }
        if place.down < 0.72 {
            let depth = (place.down - 0.42) / 0.30
            var sea = mix(rgb(70, 150, 160), rgb(120, 190, 190), depth)
            if place.row % 3 == 0,
               hash(place.column / 2, place.row, 7) > 0.6
            {
                sea = mix(sea, rgb(220, 240, 236), 0.35)
            }
            // A glint on the water.
            if isSite(place, salt: 8, density: 0.03), lit(place, salt: 9, period: 60, duty: 5) {
                return rgb(246, 244, 226)
            }
            return sea
        }
        let sand = mix(rgb(226, 200, 150), rgb(206, 176, 128), (place.down - 0.72) / 0.28)
        return hash(place.column, place.row, 10) > 0.93 ? mix(sand, rgb(186, 156, 112), 0.5) : sand
    }

    private static func mountains(_ place: Place) -> MosaicTriple {
        let far = 0.46 - noise(Double(place.column) / 6, 11) * 0.22
        let near = 0.58 - noise(Double(place.column) / 4 + 9, 12) * 0.16
        if place.down < far {
            let sky = mix(rgb(176, 202, 226), rgb(238, 226, 214), place.down / far)
            return place.down < 0.05 && hash(place.column, place.row, 13) > 0.97 ? rgb(250, 248, 240) : sky
        }
        if place.down < near {
            let snowCap = place.down < far + 0.05
            return snowCap ? rgb(240, 242, 246) : mix(rgb(120, 130, 160), rgb(92, 104, 138), (place.down - far) / 0.3)
        }
        if place.down < 0.66 {
            return mix(rgb(74, 98, 78), rgb(58, 82, 70), (place.down - near) / 0.1)
        }
        // The lake mirrors the sky, with one slow ripple.
        var water = mix(rgb(120, 156, 176), rgb(88, 124, 150), (place.down - 0.66) / 0.34)
        if isSite(place, salt: 14, density: 0.05), lit(place, salt: 15, period: 80, duty: 8) {
            water = mix(water, rgb(226, 236, 240), 0.5)
        }
        return water
    }

    private static func woods(_ place: Place, autumn: Bool) -> MosaicTriple {
        let sky = mix(rgb(186, 212, 196), rgb(240, 234, 208), place.down / 0.5)
        let trunkLine = (place.column % 5 == 2) && place.down > 0.35
        let treeTop = 0.18 + noise(Double(place.column) / 2.4, 16) * 0.3
        let leaves: [MosaicTriple] = autumn
            ? [rgb(190, 110, 44), rgb(168, 84, 42), rgb(204, 156, 58), rgb(150, 70, 46)]
            : [rgb(70, 118, 80), rgb(56, 98, 70), rgb(94, 140, 90), rgb(48, 84, 64)]
        if place.down > 0.86 {
            return mix(autumn ? rgb(120, 86, 56) : rgb(70, 78, 56), rgb(50, 56, 44), (place.down - 0.86) / 0.14)
        }
        if trunkLine {
            return rgb(86, 66, 54)
        }
        if place.down > treeTop {
            let pick = Int(hash(place.column / 2, place.row / 2, 17) * Double(leaves.count)) % leaves.count
            var leaf = leaves[pick]
            // A leaf lets go and falls: one tile at a time.
            if isSite(place, salt: 18, density: 0.04), lit(place, salt: 19, period: 90, duty: 6) {
                leaf = autumn ? rgb(224, 170, 84) : rgb(150, 184, 120)
            }
            return leaf
        }
        return sky
    }

    private static func desert(_ place: Place) -> MosaicTriple {
        if place.down < 0.5 {
            let sky = mix(rgb(238, 190, 150), rgb(250, 226, 188), place.down / 0.5)
            let sun = hypot(place.across - 0.7, (place.down - 0.34) * 1.7) < 0.09
            return sun ? rgb(252, 244, 214) : sky
        }
        let dune = 0.56 + noise(Double(place.column) / 7, 20) * 0.14
        if place.down < dune {
            return mix(rgb(214, 156, 112), rgb(190, 130, 96), (place.down - 0.5) / 0.2)
        }
        let sand = mix(rgb(226, 178, 128), rgb(204, 150, 106), (place.down - dune) / 0.4)
        // Heat shimmer on one tile at a time.
        if isSite(place, salt: 21, density: 0.03), lit(place, salt: 22, period: 70, duty: 5) {
            return mix(sand, rgb(250, 226, 188), 0.4)
        }
        return hash(place.column, place.row, 23) > 0.95 ? mix(sand, rgb(176, 124, 88), 0.4) : sand
    }

    private static func rain(_ place: Place) -> MosaicTriple {
        let glass = mix(rgb(96, 110, 130), rgb(132, 146, 160), place.down)
        // A few drops run down the window, one tile at a time.
        let streak = place.column % 6 == Int(hash(place.column / 6, 24) * 6) % 6
        if streak, isSite(place, salt: 25, density: 0.3) {
            let fall =
                (
                    (place.step + Int(hash(place.column, 38) * 5)) / 5 + Int(
                        hash(place.column, 26) * Double(place.rows)
                    )
                ) %
                (place.rows * 3)
            if fall == place.row {
                return rgb(214, 226, 236)
            }
        }
        let blur = hash(place.column / 3, place.row / 3, 27)
        return blur > 0.8 ? rgb(214, 190, 150) : (blur < 0.12 ? rgb(88, 100, 122) : glass)
    }

    private static func night(_ place: Place) -> MosaicTriple {
        let sky = mix(rgb(20, 24, 54), rgb(52, 48, 92), place.down)
        if hash(place.column, place.row, 28) > 0.985 {
            // A star twinkles: only the slow ones change.
            let twinkles = isSite(place, salt: 29, density: 0.5)
            let on = twinkles ? lit(place, salt: 30, period: 70, duty: 52) : true
            return on ? rgb(246, 244, 232) : sky
        }
        let moon = hypot(place.across - 0.76, (place.down - 0.24) * 1.7) < 0.07
        return moon ? rgb(246, 240, 216) : sky
    }

    private static func fields(_ place: Place) -> MosaicTriple {
        if place.down < 0.5 {
            let sky = mix(rgb(250, 214, 168), rgb(176, 202, 226), 1 - place.down / 0.5)
            let sun = hypot(place.across - 0.3, (place.down - 0.48) * 1.5) < 0.1
            return sun ? rgb(254, 240, 196) : sky
        }
        let band = Int((place.down - 0.5) / 0.1)
        let rows = [rgb(176, 168, 90), rgb(150, 156, 80), rgb(124, 140, 74), rgb(100, 124, 72), rgb(82, 108, 66)]
        var tone = rows[min(band, rows.count - 1)]
        if place.row % 2 == 0 {
            tone = mix(tone, rgb(210, 190, 110), 0.12)
        }
        // Dew catches the light on one tile at a time.
        if isSite(place, salt: 31, density: 0.03), lit(place, salt: 32, period: 70, duty: 5) {
            tone = mix(tone, rgb(252, 244, 214), 0.5)
        }
        return tone
    }

    private static func snow(_ place: Place) -> MosaicTriple {
        let sky = mix(rgb(204, 212, 224), rgb(234, 238, 244), place.down)
        let ground = 0.78 - noise(Double(place.column) / 6, 33) * 0.06
        if place.down > ground {
            return mix(rgb(244, 246, 250), rgb(222, 228, 238), (place.down - ground) / 0.25)
        }
        // A flake falls, one tile at a time.
        let flakes = isSite(place, salt: 34, density: 0.05)
        if flakes {
            let drift =
                (
                    (place.step + Int(hash(place.column, 39) * 6)) / 6 + Int(
                        hash(place.column, 35) * Double(place.rows)
                    )
                ) %
                (place.rows * 3)
            if drift == place.row {
                return rgb(252, 252, 255)
            }
        }
        let pine = place.column % 9 == 3 || place.column % 9 == 4
        return pine && place.down > 0.45 ? rgb(78, 100, 96) : sky
    }

    private static func harbor(_ place: Place) -> MosaicTriple {
        if place.down < 0.4 {
            return mix(rgb(234, 200, 170), rgb(182, 206, 222), 1 - place.down / 0.4)
        }
        let mast = place.column % 11 == 5 && place.down > 0.2 && place.down < 0.62
        if mast {
            return rgb(92, 78, 70)
        }
        let hull = place.down > 0.56 && place.down < 0.64 && (place.column / 3) % 3 != 2
        if hull {
            return place.column % 7 < 3 ? rgb(176, 90, 72) : rgb(66, 86, 110)
        }
        var water = mix(rgb(86, 132, 154), rgb(60, 98, 126), (place.down - 0.4) / 0.6)
        if isSite(place, salt: 36, density: 0.04), lit(place, salt: 37, period: 70, duty: 6) {
            water = mix(water, rgb(236, 226, 206), 0.5)
        }
        return water
    }
}
