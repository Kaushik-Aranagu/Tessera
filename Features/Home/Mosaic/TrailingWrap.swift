import SwiftUI

/// Words flowing onto new lines when the next one would not fit, each line pushed to the right edge (ragged left).
struct TrailingWrap: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    private typealias Line = [(index: Int, size: CGSize)]

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let lines = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = lines.map { $0.map(\.size.height).max() ?? 0 }.reduce(0, +)
            + lineSpacing * CGFloat(max(lines.count - 1, 0))
        let widest = lines.map { width(of: $0) }.max() ?? 0
        return CGSize(width: proposal.width ?? widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        var y = bounds.minY
        for line in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.maxX - width(of: line)
            let height = line.map(\.size.height).max() ?? 0
            for item in line {
                subviews[item.index].place(at: CGPoint(x: x, y: y + (height - item.size.height) / 2),
                                           proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += height + lineSpacing
        }
    }

    private func width(of line: Line) -> CGFloat {
        line.reduce(0) { $0 + $1.size.width } + spacing * CGFloat(max(line.count - 1, 0))
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Line] {
        var lines: [Line] = [[]]
        var used: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil))
            if !(lines.last?.isEmpty ?? true), used + spacing + size.width > width {
                lines.append([])
                used = 0
            }
            used += (lines.last?.isEmpty ?? true ? 0 : spacing) + size.width
            lines[lines.count - 1].append((index, size))
        }
        return lines
    }
}
