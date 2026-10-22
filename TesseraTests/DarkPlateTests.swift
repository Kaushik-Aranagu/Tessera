@testable import Tessera
import Testing
import UIKit

/// The Gym visual on a dark look: the plate goes transparent and the hues stay (Kaushik's OK, Oct 22).
@MainActor
struct DarkPlateTests {
    private func solid(_ color: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: format).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }

    private func pixel(_ image: UIImage) -> (r: Int, g: Int, b: Int, a: Int) {
        var bytes = [UInt8](repeating: 0, count: 4)
        let space = CGColorSpaceCreateDeviceRGB()
        guard let cgImage = image.cgImage,
              let context = CGContext(
                  data: &bytes,
                  width: 1,
                  height: 1,
                  bitsPerComponent: 8,
                  bytesPerRow: 4,
                  space: space,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return (0, 0, 0, 0) }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return (Int(bytes[0]), Int(bytes[1]), Int(bytes[2]), Int(bytes[3]))
    }

    @Test func aWhitePlateBecomesTransparent() {
        let white = pixel(DarkPlate.invert(solid(.white)))
        #expect(white.a < 12, "the plate lets the ground through: \(white)")
    }

    @Test func theFigureTurnsLight() {
        let black = pixel(DarkPlate.invert(solid(.black)))
        #expect(black.a > 243 && black.r > 243 && black.g > 243 && black.b > 243)
    }

    @Test func aRedMuscleStaysRedAndSolid() {
        let red = pixel(DarkPlate.invert(solid(UIColor(red: 0.8, green: 0.25, blue: 0.2, alpha: 1))))
        #expect(red.a > 243, "solid: \(red)")
        #expect(red.r > red.g + 80 && red.r > red.b + 80, "still reads red: \(red)")
    }
}
