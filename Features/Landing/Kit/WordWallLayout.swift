import CoreGraphics
import Foundation

/// One word the wall can show. `weight` is importance, 0 to 1 (pinned, recent, due, opened often).
struct WallWord: Identifiable, Hashable, Sendable {
    let id: String
    let text: String
    let weight: Double
}

/// One placed brick: a word at an exact frame and font size.
struct WallBrick: Identifiable, Equatable, Sendable {
    let id: String
    let wordID: String
    let text: String
    let frame: CGRect
    let fontSize: CGFloat
    let colorIndex: Int
}

/// The packed word wall (246, landing-living-242 rounds 4-6): capitals, line box = cap height, 3 pt gaps, every row
/// justified to both edges by solving its own font size, so no letter is ever stretched or spaced unevenly.
/// Pure geometry: the caller supplies `advance`, the width of a word per point of font size.
enum WordWallLayout {
    static let gap: CGFloat = 3
    static let minimumSize: CGFloat = 13
    static let maximumSize: CGFloat = 64
    /// Figtree cap height over the em.
    static let capRatio: CGFloat = 0.70
    static let colorCount = 12
    /// A wall whose leftover height is under this many points is accepted; the leftover goes into the row gaps.
    static let leftoverLimit: CGFloat = 8

    private struct Row {
        var words: [WallWord]
        var fontSize: CGFloat
        var height: CGFloat {
            fontSize * capRatio
        }
    }

    /// The colour slot for the nth brick: stepped by 5 so neighbours never match (246).
    static func colorIndex(_ index: Int) -> Int {
        (index * 5) % colorCount
    }

    static func pack(words: [WallWord], size: CGSize, advance: (String) -> CGFloat) -> [WallBrick] {
        let ordered = words.sorted { $0.weight != $1.weight ? $0.weight > $1.weight : $0.id < $1.id }
        guard !ordered.isEmpty, size.width > 0, size.height > 0 else { return [] }
        var best: (rows: [Row], leftover: CGFloat)?
        var target = maximumSize * 0.85
        while target >= minimumSize {
            let rows = rows(for: ordered, target: target, size: size, advance: advance)
            let used = rows.reduce(0) { $0 + $1.height } + gap * CGFloat(max(0, rows.count - 1))
            let leftover = size.height - used
            if !rows.isEmpty, leftover >= 0 {
                if best == nil || leftover < best!.leftover {
                    best = (rows, leftover)
                }
                if leftover < leftoverLimit {
                    break
                }
            }
            target -= 0.5
        }
        guard let chosen = best else { return [] }
        return place(chosen.rows, leftover: chosen.leftover, size: size, advance: advance)
    }

    // MARK: Rows

    private static func rows(for ordered: [WallWord], target: CGFloat, size: CGSize,
                             advance: (String) -> CGFloat) -> [Row]
    {
        var rows: [Row] = []
        var used: CGFloat = 0
        var cursor = 0
        // Repeats refill the wall only when the room has fewer words than the wall holds (246).
        var guardCount = 0
        let repeats = ordered.count >= 4
        while guardCount < 64 {
            if !repeats, cursor >= ordered.count {
                break
            }
            guardCount += 1
            var choice: (words: [WallWord], size: CGFloat)?
            // The heaviest words get the tallest rows (the keystone reads as a ranked wall, not a grid).
            let rowTarget = target * (0.75 + 0.7 * ordered[cursor % ordered.count].weight)
            for count in 1 ... 4 {
                if !repeats, cursor + count > ordered.count {
                    break
                }
                let picked = (0 ..< count).map { ordered[(cursor + $0) % ordered.count] }
                let total = picked.reduce(0) { $0 + advance($1.text) }
                guard total > 0 else { continue }
                let fit = (size.width - gap * CGFloat(count - 1)) / total
                guard fit >= minimumSize, fit <= maximumSize else { continue }
                if choice == nil || abs(fit - rowTarget) < abs(choice!.size - rowTarget) {
                    choice = (picked, fit)
                }
            }
            if choice == nil, !repeats {
                // A lone short word is set at the largest size, left-aligned, instead of stretched across the wall.
                let word = ordered[cursor]
                let natural = size.width / max(advance(word.text), 0.01)
                if natural > maximumSize {
                    choice = ([word], maximumSize)
                }
            }
            guard let row = choice else { break }
            let height = row.size * capRatio
            let next = used + height + (rows.isEmpty ? 0 : gap)
            if next > size.height {
                break
            }
            rows.append(Row(words: row.words, fontSize: row.size))
            used = next
            cursor += row.words.count
            if cursor >= ordered.count, rows.count >= 2, used + target * capRatio + gap > size.height {
                break
            }
        }
        return rows
    }

    private static func place(_ rows: [Row], leftover: CGFloat, size _: CGSize,
                              advance: (String) -> CGFloat) -> [WallBrick]
    {
        // A full wall spreads its small leftover into the row gaps; a sparse one (few words) sits centred.
        let sparse = leftover >= leftoverLimit * 2
        let extra = rows.count > 1 && !sparse ? leftover / CGFloat(rows.count - 1) : 0
        var bricks: [WallBrick] = []
        var y: CGFloat = sparse ? leftover / 2 : 0
        var index = 0
        var seen: [String: Int] = [:]
        for row in rows {
            var x: CGFloat = 0
            for word in row.words {
                let width = advance(word.text) * row.fontSize
                let repeatIndex = seen[word.id, default: 0]
                seen[word.id] = repeatIndex + 1
                bricks.append(WallBrick(id: "\(word.id)#\(repeatIndex)", wordID: word.id, text: word.text,
                                        frame: CGRect(x: x, y: y, width: width, height: row.height),
                                        fontSize: row.fontSize, colorIndex: colorIndex(index)))
                x += width + gap
                index += 1
            }
            y += row.height + gap + extra
        }
        return bricks
    }
}
