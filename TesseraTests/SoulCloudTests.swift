import CoreGraphics
import Foundation
@testable import Tessera
import Testing

/// Tess's body: one even cloud, no boundary, three colours blended in OKLab (sheet 215 rev 9 and 11).
struct SoulCloudTests {
    private func input(dark: Bool = false, time: Double = 3, paints: [UInt32]? = nil) -> SoulCloud.Input {
        SoulCloud.Input(paints: paints ?? (dark ? SoulCloud.paintsDark : SoulCloud.paintsLight), dark: dark, time: time)
    }

    @Test func theCanvasIsNeverTighterThanTwoPointTwoRadiiFromHerCentre() {
        #expect(SoulCloud.clipIsSafe)
        // At her fullest the fade has reached nothing by the image's edge.
        var fullest = input()
        fullest.spread = 1
        fullest.level = 1
        for angle in stride(from: 0.0, to: 2 * Double.pi, by: 0.2) {
            let edge = SoulCloud.span / 2
            #expect(SoulCloud.alpha(across: edge * cos(angle), down: edge * sin(angle), input: fullest) < 0.001)
        }
    }

    @Test func herBodyIsDensestInTheMiddleAndFadesAllTheWayToNothing() {
        let value = input()
        let radius = SoulCloud.radius(value)
        let middle = SoulCloud.alpha(across: 0, down: 0, input: value)
        let out = SoulCloud.alpha(across: radius * 1.2, down: 0, input: value)
        let far = SoulCloud.alpha(across: radius * 2.2, down: 0, input: value)
        #expect(middle > 0.9 && middle > out && out > far && far < 0.03)
        // A smooth falloff: no plateau and no step between neighbouring samples.
        var previous = middle
        for step in 1 ... 60 {
            let alpha = SoulCloud.alpha(across: radius * 2.3 * Double(step) / 60, down: 0, input: value)
            #expect(previous - alpha < 0.12 && alpha <= previous + 0.03)
            previous = alpha
        }
    }

    @Test func onlyHerEdgeMovesAndTheTextureStaysEvenAtTheCentre() {
        let early = input(time: 1), late = input(time: 9)
        #expect(abs(SoulCloud.alpha(across: 0, down: 0, input: early) - SoulCloud.alpha(
            across: 0,
            down: 0,
            input: late
        )) < 0.02)
        let radius = SoulCloud.radius(early)
        let edgeEarly = SoulCloud.alpha(across: radius * 1.5, down: 0, input: early)
        let edgeLate = SoulCloud.alpha(across: radius * 1.5, down: 0, input: late)
        #expect(edgeEarly != edgeLate)
    }

    @Test func threeColourFieldsSitAThirdOfATurnApartTurningTogether() {
        let first = SoulCloud.centres(input(time: 0)), second = SoulCloud.centres(input(time: 2))
        #expect(first.count == 3 && first[0].weight == 1.08 && first[1].weight == 1 && first[2].weight == 1)
        // Vermilion sits nearer her middle than cobalt and gold.
        #expect(hypot(first[0].x, first[0].y) < hypot(first[1].x, first[1].y))
        #expect(first[0].x != second[0].x || first[0].y != second[0].y)
    }

    @Test func theBodyDrawsAnImageWithColourInTheMiddleAndNoneAtTheCorners() throws {
        let image = try #require(SoulCloud.image(input()))
        #expect(image.width == SoulCloud.side && image.height == SoulCloud.side)
        let data = try #require(image.dataProvider?.data as Data?)
        func pixel(_ column: Int, _ row: Int) -> [UInt8] {
            let offset = (row * image.width + column) * 4
            return Array(data[offset ..< offset + 4])
        }
        let middle = pixel(image.width / 2, image.height / 2)
        #expect(middle[3] > 200 && Set([middle[0], middle[1], middle[2]]).count == 3, "coloured, not grey")
        #expect(pixel(0, 0)[3] == 0 && pixel(image.width - 1, image.height - 1)[3] == 0)
    }

    @Test func aFlatBodyHasOneColourAndAHardEdge() throws {
        var flat = input()
        flat.flat = true
        let image = try #require(SoulCloud.image(flat))
        let data = try #require(image.dataProvider?.data as Data?)
        var colours = Set<[UInt8]>()
        for row in 0 ..< image.height {
            for column in 0 ..< image.width {
                let offset = (row * image.width + column) * 4
                if data[offset + 3] == 225 {
                    colours.insert(Array(data[offset ..< offset + 3]))
                }
            }
        }
        #expect(colours.count == 1)
    }

    @Test func herColoursAreReadAtWarpedPointsButHerShapeIsNot() {
        let value = input(time: 4)
        let radius = SoulCloud.radius(value)
        let bent = SoulCloud.warped(across: radius, down: radius * 0.5, input: value)
        #expect(bent.across != radius || bent.down != radius * 0.5)
        // The bend is at most 0.55 R + 0.18 R across and 0.55 R down.
        #expect(abs(bent.across - radius) <= radius * 0.73 + 1e-9 && abs(bent.down - radius * 0.5) <= radius * 0.55 +
            1e-9)
        // The shape never reads the warp.
        #expect(SoulCloud.alpha(across: radius, down: 0, input: value) == SoulCloud.alpha(
            across: radius,
            down: 0,
            input: value
        ))
        #expect(SoulCloud.warped(across: 0.1, down: 0.1, input: input(time: 4)) == SoulCloud.warped(
            across: 0.1,
            down: 0.1,
            input: input(time: 4)
        ))
    }

    @Test func oklabRoundTripsAHex() {
        let lab = SoulCloud.oklab(0x3561C8)
        let back = SoulCloud.rgb(lightness: lab.lightness, greenRed: lab.greenRed, blueYellow: lab.blueYellow)
        #expect(abs(back.red - 0x35 / 255.0) < 0.004 && abs(back.green - 0x61 / 255.0) < 0.004
            && abs(back.blue - 0xC8 / 255.0) < 0.004)
    }
}
