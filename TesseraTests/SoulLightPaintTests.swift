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
            SoulRenderer.draw(frame, in: &context, size: size, palette: palette)
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
