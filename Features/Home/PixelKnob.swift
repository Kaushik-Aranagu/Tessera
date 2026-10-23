import SwiftUI

// The Settings knob (sheet 203): 16 pt, made of nine of the screen's own pixels (a 3 x 3 of 3.2 pt tiles on the 4 pt
// step). Eight make the dial in ink 2; the one at the top is the notch, in ink. It turns a quarter with a spring when
// it is pressed and once a minute on its own, never under Reduce Motion. Builder B places it beside "Settings".

enum PixelKnobShape {
    static let frame: CGFloat = 16
    static let step: CGFloat = 4
    static let side: CGFloat = 3.2

    /// The nine pixels as (column, row) in the 3 x 3, row by row.
    static let pixels: [(column: Int, row: Int)] = (0 ..< 3).flatMap { row in (0 ..< 3).map { (column: $0, row: row) } }

    /// The notch's pixel after `turns` quarter turns clockwise: top, right, bottom, left.
    static func notch(turns: Int) -> (column: Int, row: Int) {
        let spots: [(column: Int, row: Int)] = [(1, 0), (2, 1), (1, 2), (0, 1)]
        return spots[((turns % 4) + 4) % 4]
    }

    /// The pixel's top-left corner inside the 16 pt frame.
    static func origin(column: Int, row: Int) -> CGPoint {
        let margin = (frame - 3 * step) / 2 + (step - side) / 2
        return CGPoint(x: margin + CGFloat(column) * step, y: margin + CGFloat(row) * step)
    }

    /// Once a minute the knob turns on its own.
    static let selfTurnSeconds: TimeInterval = 60
}

struct PixelKnob: View {
    /// A press: the knob turns and the action runs (a Settings knob opens Settings).
    var action: () -> Void = {}

    @State private var quarterTurns = 0
    @State private var feel = HapticCue()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            turn()
            action()
        } label: {
            Canvas { context, _ in
                let notch = PixelKnobShape.notch(turns: 0)
                for pixel in PixelKnobShape.pixels {
                    let corner = PixelKnobShape.origin(column: pixel.column, row: pixel.row)
                    let isNotch = pixel.column == notch.column && pixel.row == notch.row
                    let colour = isNotch ? Theme.Colors.ink : Theme.Colors.inkSecondary
                    context.fill(
                        Path(CGRect(x: corner.x, y: corner.y, width: PixelKnobShape.side, height: PixelKnobShape.side)),
                        with: .color(colour)
                    )
                }
            }
            .frame(width: PixelKnobShape.frame, height: PixelKnobShape.frame)
            .rotationEffect(.degrees(Double(quarterTurns) * 90))
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .tesseraFeedback(feel)
        .accessibilityHidden(true)
        .task {
            // Once a minute on its own, unless Reduce Motion is on.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(PixelKnobShape.selfTurnSeconds))
                guard !Task.isCancelled, !reduceMotion else { continue }
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { quarterTurns += 1 }
            }
        }
    }

    private func turn() {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { quarterTurns += 1 }
        feel.play(.selection)
    }
}
