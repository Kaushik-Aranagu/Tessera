import CoreGraphics
import Foundation

/// Tess's body (sheet 215 rev 9 and 11): one cloud of wet paint with a smooth, even texture, densest in her middle and
/// fading all the way into the page, so there is no boundary and no circle. Only her soft edge moves, on slow waves.
/// Her three colours (vermilion, cobalt, cadmium) are three wide fields a third of a turn apart, turning together and
/// each swaying a little on its own; they are mixed in OKLab with the chroma held up, never as stripes.
/// Pure and seeded by the time, so any frame is the same frame (and testable). The image is premultiplied RGBA.
enum SoulCloud {
    struct Input: Equatable {
        /// Vermilion, cobalt, cadmium.
        var paints: [UInt32]
        var dark: Bool
        /// Seconds, 0 under Reduce Motion.
        var time: Double
        /// A drop in her spread (0 ... 1) and a voice's level (0 ... 1).
        var spread = 0.0
        var spin = 0.0
        var level = 0.0
        var quiet = false
        /// How far a colour's chroma may be held up in the mix (1.6, lower on Black).
        var chroma = 1.6
        /// Reduce Transparency: a flat body with no blending.
        var flat = false
    }

    /// The image covers `span` of the reference square, so her fade never meets the edge (see `clipIsSafe`).
    static let span = 1.2
    static let side = 112
    static let paintsDark: [UInt32] = [0xFF5B3A, 0x5E8BFF, 0xFFC23D]
    static let paintsLight: [UInt32] = [0xD2502F, 0x3561C8, 0xE0A21E]

    /// The body's largest radius is 0.19 R at its fullest breath and spread, and her edge reaches out 11% more; the
    /// canvas is never tighter than 2.2 of that from her centre.
    static var clipIsSafe: Bool {
        let radiusMax = 0.19 * (0.96 + 0.08 + 0.08) * 1.1 * 1.11
        return span / 2 >= 2.2 * radiusMax
    }

    /// Breath, in the reference square's units.
    static func radius(_ input: Input) -> Double {
        let phase = input.time * (input.quiet ? 0.35 : 1)
        let breath = 0.96 + (input.quiet ? 0.03 : 0.08) * sin(phase * 0.98) + 0.08 * input.level
        return 0.19 * breath * (1 + 0.1 * input.spread)
    }

    // MARK: Colour

    private static func linear(_ value: Double) -> Double {
        value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }

    private static func encoded(_ value: Double) -> Double {
        let clamped = min(max(value, 0), 1)
        return clamped <= 0.0031308 ? 12.92 * clamped : 1.055 * pow(clamped, 1 / 2.4) - 0.055
    }

    static func oklab(_ hex: UInt32) -> (lightness: Double, greenRed: Double, blueYellow: Double) {
        let red = linear(Double((hex >> 16) & 0xFF) / 255)
        let green = linear(Double((hex >> 8) & 0xFF) / 255)
        let blue = linear(Double(hex & 0xFF) / 255)
        let l = cbrt(0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue)
        let m = cbrt(0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue)
        let s = cbrt(0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue)
        return (0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
                1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
                0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s)
    }

    static func rgb(lightness: Double, greenRed: Double,
                    blueYellow: Double) -> (red: Double, green: Double, blue: Double)
    {
        let lms = (l: pow(lightness + 0.3963377774 * greenRed + 0.2158037573 * blueYellow, 3),
                   m: pow(lightness - 0.1055613458 * greenRed - 0.0638541728 * blueYellow, 3),
                   s: pow(lightness - 0.0894841775 * greenRed - 1.291485548 * blueYellow, 3))
        return (encoded(4.0767416621 * lms.l - 3.3077115913 * lms.m + 0.2309699292 * lms.s),
                encoded(-1.2684380046 * lms.l + 2.6097574011 * lms.m - 0.3413193965 * lms.s),
                encoded(-0.0041960863 * lms.l - 0.7034186147 * lms.m + 1.707614701 * lms.s))
    }

    /// Linear channels of an OKLab colour, unclamped.
    private static func linearChannels(_ lightness: Double, _ greenRed: Double, _ blueYellow: Double)
        -> (red: Double, green: Double, blue: Double)
    {
        let lCube = pow(lightness + 0.3963377774 * greenRed + 0.2158037573 * blueYellow, 3)
        let mCube = pow(lightness - 0.1055613458 * greenRed - 0.0638541728 * blueYellow, 3)
        let sCube = pow(lightness - 0.0894841775 * greenRed - 1.291485548 * blueYellow, 3)
        return (4.0767416621 * lCube - 3.3077115913 * mCube + 0.2309699292 * sCube,
                -1.2684380046 * lCube + 2.6097574011 * mCube - 0.3413193965 * sCube,
                -0.0041960863 * lCube - 0.7034186147 * mCube + 1.707614701 * sCube)
    }

    /// Whether an OKLab colour is inside the sRGB gamut.
    static func inGamut(lightness: Double, greenRed: Double, blueYellow: Double) -> Bool {
        let value = linearChannels(lightness, greenRed, blueYellow)
        let slack = -0.0005, top = 1.0005
        return [value.red, value.green, value.blue].allSatisfy { $0 >= slack && $0 <= top }
    }

    /// The colour with its chroma pulled in, at the same lightness and hue, until it fits the gamut: the chroma
    /// never clips in RGB, which would shift its hue.
    static func rgbInGamut(lightness: Double, greenRed: Double, blueYellow: Double)
        -> (red: Double, green: Double, blue: Double)
    {
        let light = min(max(lightness, 0), 1)
        if inGamut(lightness: light, greenRed: greenRed, blueYellow: blueYellow) {
            return rgb(lightness: light, greenRed: greenRed, blueYellow: blueYellow)
        }
        var low = 0.0, high = 1.0
        for _ in 0 ..< 9 {
            let mid = (low + high) / 2
            if inGamut(lightness: light, greenRed: greenRed * mid, blueYellow: blueYellow * mid) {
                low = mid
            } else {
                high = mid
            }
        }
        return rgb(lightness: light, greenRed: greenRed * low, blueYellow: blueYellow * low)
    }

    // MARK: Field

    /// The three colour fields' centres and weights at this moment, in the reference square's units.
    static func centres(_ input: Input) -> [(x: Double, y: Double, weight: Double)] {
        let phase = input.time * (input.quiet ? 0.35 : 1)
        let radius = radius(input)
        let angle = 0.6 + phase * 0.16 + input.spin
        return (0 ..< 3).map { index in
            let step = Double(index)
            let around = angle + step * 2.094 + 0.35 * sin(phase * (0.23 + 0.04 * step) + step * 1.7)
            let distance = radius * ((index == 0 ? 0.4 : 0.56) + 0.08 * sin(phase * (0.31 + 0.05 * step) + step))
            return (distance * cos(around), distance * sin(around), index == 0 ? 1.08 : 1)
        }
    }

    /// Where her colours are read (rev 12, a little abstraction): the point bent by two slow, broad sine waves, so the
    /// places her colours meet curve and drift like brush sweeps. The waves are wider than she is, they bend colour
    /// only, and her texture and her shape stay as they were.
    static func warped(across: Double, down: Double, input: Input) -> (across: Double, down: Double) {
        let phase = input.time * (input.quiet ? 0.35 : 1)
        let radius = radius(input)
        let first = radius * 0.55 * sin(down / radius * 2 + phase * 0.21)
        let second = radius * 0.18 * sin((across + down) / radius * 1.4 - phase * 0.13)
        let third = radius * 0.55 * sin(across / radius * 1.8 - phase * 0.17 + 2)
        return (across + first + second, down + third)
    }

    /// Alpha (0 ... 1) of her body at a point `(u, v)` of the reference square from her centre: dense in the middle, a
    /// long even fall-off, a soft edge that swells and draws in on slow waves.
    static func alpha(across: Double, down: Double, input: Input) -> Double {
        let phase = input.time * (input.quiet ? 0.35 : 1)
        let theta = atan2(down, across)
        let reach = 1 + 0.045 * sin(2 * theta + phase * 0.42) + 0.03 * sin(3 * theta - phase * 0.33 + 1.1)
            + 0.035 * sin(theta - phase * 0.19)
        let ratio = hypot(across, down) / (radius(input) * reach)
        if ratio > 2.3 {
            return 0
        }
        let density = exp(-pow(ratio, 2.2) * 0.95)
        return max(0, 1 - exp(-3.1 * density) - 0.02) / 0.98
    }

    /// The image of her body for `input`: `side` x `side`, premultiplied RGBA, centred on her.
    static func image(_ input: Input) -> CGImage? {
        let count = side
        let lab = input.paints.map(oklab)
        guard lab.count == 3 else { return nil }
        let centres = centres(input)
        let radius = radius(input)
        let sigma2 = 2 * pow(radius * 0.70, 2)
        let cap = (input.dark ? 235.0 : 225.0) / 255
        var flatColour: (Double, Double, Double)?
        if input.flat {
            let mean = (
                lab.reduce(0) { $0 + $1.lightness } / 3,
                lab.reduce(0) { $0 + $1.greenRed } / 3,
                lab.reduce(0) { $0 + $1.blueYellow } / 3
            )
            flatColour = (mean.0, mean.1, mean.2)
        }
        var pixels = [UInt8](repeating: 0, count: count * count * 4)
        for row in 0 ..< count {
            for column in 0 ..< count {
                let across = (Double(column) / Double(count) - 0.5) * span
                let down = (Double(row) / Double(count) - 0.5) * span
                var cover = alpha(across: across, down: down, input: input)
                if let flatColour {
                    let ratio = hypot(across, down) / radius
                    cover = min(max((1.7 - ratio) / 0.12, 0), 1)
                    if cover <= 0 {
                        continue
                    }
                    let tone = rgb(lightness: flatColour.0, greenRed: flatColour.1, blueYellow: flatColour.2)
                    store(&pixels, at: (row * count + column) * 4, tone, alpha: cover * cap)
                    continue
                }
                if cover <= 0 {
                    continue
                }
                let bent = warped(across: across, down: down, input: input)
                var weights = 0.0, lightness = 0.0, redGreen = 0.0, blueYellow = 0.0, chroma = 0.0
                for index in 0 ..< 3 {
                    let centre = centres[index]
                    let dx = bent.across - centre.x, dy = bent.down - centre.y
                    let weight = centre.weight * exp(-(dx * dx + dy * dy) / sigma2)
                    weights += weight
                    lightness += weight * lab[index].lightness
                    redGreen += weight * lab[index].greenRed
                    blueYellow += weight * lab[index].blueYellow
                    chroma += weight * hypot(lab[index].greenRed, lab[index].blueYellow)
                }
                lightness /= weights
                redGreen /= weights
                blueYellow /= weights
                chroma /= weights
                let held = max(hypot(redGreen, blueYellow), 1e-6)
                let keep = min(input.chroma, chroma / held)
                let shade = -0.03 * (down / radius) * exp(-pow(hypot(across, down) / radius, 2)) + 0.012
                let tone = rgbInGamut(
                    lightness: lightness + shade,
                    greenRed: redGreen * keep,
                    blueYellow: blueYellow * keep
                )
                store(&pixels, at: (row * count + column) * 4, tone, alpha: cover * cap)
            }
        }
        let provider = CGDataProvider(data: Data(pixels) as CFData)
        return provider.flatMap {
            CGImage(width: count, height: count, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: count * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                    provider: $0, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        }
    }

    private static func store(
        _ pixels: inout [UInt8],
        at offset: Int,
        _ tone: (red: Double, green: Double, blue: Double),
        alpha: Double
    ) {
        pixels[offset] = UInt8((tone.red * alpha * 255).rounded())
        pixels[offset + 1] = UInt8((tone.green * alpha * 255).rounded())
        pixels[offset + 2] = UInt8((tone.blue * alpha * 255).rounded())
        pixels[offset + 3] = UInt8((alpha * 255).rounded())
    }
}
