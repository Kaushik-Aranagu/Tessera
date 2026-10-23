import SwiftUI
@testable import Tessera
import Testing

/// Tess on a light ground: the dabs stay colours, and no part of her is darker than her eyes.
@MainActor
struct SoulLightPaintTests {
    private func luminance(_ red: Double, _ green: Double, _ blue: Double) -> Double {
        0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    private func components(_ hex: UInt32) -> (Double, Double, Double) {
        (Double((hex >> 16) & 0xFF) / 255, Double((hex >> 8) & 0xFF) / 255, Double(hex & 0xFF) / 255)
    }

    private func darkestPixel(on look: Look) throws -> Double {
        let date = Date(timeIntervalSinceReferenceDate: 1000)
        let layers = SoulBlend.push(.idle, onto: [], at: date.addingTimeInterval(-5))
        let frame = try #require(SoulBlend.frame(layers, at: date, loops: true))
        let palette = SoulPalette.look(look)
        let size = CGSize(width: 150, height: 150)
        let view = Canvas { context, size in
            var context = context
            SoulRenderer.draw(frame, in: &context, size: size, palette: palette,
                              cloud: SoulCloud.image(.init(paints: SoulCloud.paintsLight, dark: false, time: 3)))
        }
        .frame(width: size.width, height: size.height)
        .background(Color(hex: look.ground))
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let image = try #require(renderer.cgImage)
        let data = try #require(image.dataProvider?.data as Data?)
        let bytesPerPixel = image.bitsPerPixel / 8
        // The renderer's pixel order (BGRA on little-endian premultiplied-first, else RGBA or ARGB).
        let alphaFirst = [CGImageAlphaInfo.premultipliedFirst, .first, .noneSkipFirst].contains(image.alphaInfo)
        let little = image.bitmapInfo.contains(.byteOrder32Little)
        let (redAt, greenAt, blueAt) = switch (little, alphaFirst) {
        case (true, true): (2, 1, 0)
        case (false, true): (1, 2, 3)
        case (true, false): (3, 2, 1)
        case (false, false): (0, 1, 2)
        }
        var darkest = 1.0
        for y in 0 ..< image.height {
            for x in 0 ..< image.width {
                let offset = y * image.bytesPerRow + x * bytesPerPixel
                darkest = min(
                    darkest,
                    luminance(Double(data[offset + redAt]) / 255, Double(data[offset + greenAt]) / 255,
                              Double(data[offset + blueAt]) / 255)
                )
            }
        }
        return darkest
    }

    @Test func noPartOfHerIsDarkerThanHerEyesOnTheLightLooks() throws {
        for look in Look.light {
            let ink = components(look.ink), ground = components(look.ground)
            let eyes = luminance(
                ink.0 * 0.86 + ground.0 * 0.14, ink.1 * 0.86 + ground.1 * 0.14, ink.2 * 0.86 + ground.2 * 0.14
            )
            let darkest = try darkestPixel(on: look)
            #expect(darkest < luminance(ground.0, ground.1, ground.2), "\(look.name): she is drawn")
            #expect(darkest >= eyes, "\(look.name): darkest \(darkest) vs eyes \(eyes)")
        }
    }

    @Test func pleinPaintsLiveInsideHerAndLightWashesUseTheNewStops() {
        let light = SoulPalette.look(.plein)
        #expect(light.layered && SoulPalette.look(.obsidian).layered == false)
        #expect(light.washes.count == 3)
        #expect(light.washes[0].stops[0].color != SoulPalette.look(.porcelain).washes[0].stops[0].color)
    }
}

/// Her eyes against her body, on every look and at the peak of a burst (3:1 or better).
struct SoulEyeContrastTests {
    private func luminance(_ red: Double, _ green: Double, _ blue: Double) -> Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
    }

    private func components(_ hex: UInt32) -> (Double, Double, Double) {
        (Double((hex >> 16) & 0xFF) / 255, Double((hex >> 8) & 0xFF) / 255, Double(hex & 0xFF) / 255)
    }

    /// The darkest and lightest body luminance within 0.9 R of her centre, composited over `ground`.
    private func range(_ input: SoulCloud.Input, ground: UInt32) throws -> (low: Double, high: Double) {
        let image = try #require(SoulCloud.image(input))
        let data = try #require(image.dataProvider?.data as Data?)
        let back = components(ground)
        let radiusPixels = SoulCloud.radius(input) / SoulCloud.span * Double(image.width)
        let centre = Double(image.width) / 2
        var low = 1.0, high = 0.0
        for row in 0 ..< image.height {
            for column in 0 ..< image.width
                where hypot(Double(column) - centre, Double(row) - centre) < radiusPixels * 0.9
            {
                let offset = (row * image.width + column) * 4
                let alpha = Double(data[offset + 3]) / 255
                // Premultiplied: the colour over the ground is the stored colour plus the ground's remainder.
                let red = Double(data[offset]) / 255 + back.0 * (1 - alpha)
                let green = Double(data[offset + 1]) / 255 + back.1 * (1 - alpha)
                let blue = Double(data[offset + 2]) / 255 + back.2 * (1 - alpha)
                let value = luminance(red, green, blue)
                low = min(low, value)
                high = max(high, value)
            }
        }
        return (low, high)
    }

    @Test @MainActor func herEyesHaveThreeToOneAgainstHerBodyOnEveryLookAtTheBurstPeak() throws {
        let peak = SoulCloud.bursts(quiet: false)[2]
        let time = peak.start + peak.length / 2
        for look in Look.all {
            var input = SoulCloud.Input(paints: look.isDark ? SoulCloud.paintsDark : SoulCloud.paintsLight,
                                        dark: look.isDark, time: time)
            if look.isDark, look.ground == 0x000000 {
                input.chroma = 1.25
            }
            let ink = components(look.isDark ? look.ground : look.ink)
            let ground = components(look.ground)
            let mix = look.isDark ? ink : (ink.0 * 0.86 + ground.0 * 0.14, ink.1 * 0.86 + ground.1 * 0.14,
                                           ink.2 * 0.86 + ground.2 * 0.14)
            let eyes = luminance(mix.0, mix.1, mix.2)
            let body = try range(input, ground: look.ground)
            let ratio = look.isDark ? (body.low + 0.05) / (eyes + 0.05) : (eyes < body.low
                ? (body.low + 0.05) / (eyes + 0.05) : 1)
            #expect(ratio >= 3, "\(look.name): eyes \(eyes), body from \(body.low) to \(body.high), ratio \(ratio)")
        }
    }
}
