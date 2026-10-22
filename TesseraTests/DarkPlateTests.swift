@testable import Tessera
import Testing
import UIKit

/// The Gym visual on a dark look: light and dark swap, the hues stay (Kaushik's OK, Oct 22).
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

    private func pixel(_ image: UIImage) -> (r: Int, g: Int, b: Int) {
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
              ) else { return (0, 0, 0) }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return (Int(bytes[0]), Int(bytes[1]), Int(bytes[2]))
    }

    @Test func aWhitePlateBecomesADarkOne() {
        let white = pixel(DarkPlate.invert(solid(.white)))
        #expect(white.r < 12 && white.g < 12 && white.b < 12)
        let black = pixel(DarkPlate.invert(solid(.black)))
        #expect(black.r > 243 && black.g > 243 && black.b > 243)
    }

    @Test func aRedMuscleStaysRed() {
        // A mid red turns to a mid red: the light/dark swap must not turn it cyan.
        let red = pixel(DarkPlate.invert(solid(UIColor(red: 0.8, green: 0.25, blue: 0.2, alpha: 1))))
        #expect(red.r > red.g + 30 && red.r > red.b + 30, "still reads red: \(red)")
    }
}
