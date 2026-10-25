import SwiftUI
import UIKit

/// The keystone word wall (246): the room's own words, packed into bricks in capitals, tappable, alive in small
/// ways. Fills the keystone slot it is given. Reduce Motion: no moments, no re-pack, one still wall.
struct WordWallView: View {
    let words: [WallWord]
    var open: (String) -> Void
    /// The spoken name of a brick, e.g. "Plumber, note".
    var label: (WallWord) -> String = { $0.text.capitalized }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var generation = 0
    @State private var flipping: String?

    private static let light: [UInt32] = [
        0xB5452B, 0x1E6E77, 0x7A5A12, 0x5A3F8E, 0x2F6A8F, 0x8A4570,
        0x3F6B2A, 0x9A2541, 0x0F766E, 0x92400E, 0x1F4E8C, 0x1D1B19,
    ]
    private static let dark: [UInt32] = [
        0xF09A7E, 0x84C3C9, 0xE2C26A, 0xB4A3E6, 0x8DBAD6, 0xE3A3CB,
        0xA9D48A, 0xF08E9C, 0x5FD0C0, 0xF0B07A, 0x9DB8F0, 0xF1EEE9,
    ]

    var body: some View {
        GeometryReader { proxy in
            let bricks = WordWallLayout.pack(words: arranged, size: proxy.size, advance: WordWallMeasure.advance)
            ZStack(alignment: .topLeading) {
                ForEach(bricks) { brick in
                    Button { open(brick.wordID) } label: {
                        Text(brick.text.uppercased())
                            .font(.custom("Figtree", fixedSize: brick.fontSize).weight(.black))
                            .tracking(-0.01 * brick.fontSize)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .foregroundStyle(color(brick.colorIndex))
                            .frame(width: brick.frame.width, height: brick.frame.height)
                            .rotation3DEffect(.degrees(flipping == brick.id ? 360 : 0), axis: (x: 1, y: 0, z: 0))
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .position(x: brick.frame.midX, y: brick.frame.midY)
                    .accessibilityLabel(label(words.first { $0.id == brick.wordID } ?? WallWord(id: "", text: brick.text, weight: 0)))
                    .accessibilityHint("Opens it")
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .tesseraAnimation(Theme.Motion.house, value: generation)
            .task(id: bricks.map(\.id)) { await moments(bricks) }
        }
    }

    /// The top words stay; the rest rotate one place every 40 s so the wall swaps a word and re-packs.
    private var arranged: [WallWord] {
        let sorted = words.sorted { $0.weight != $1.weight ? $0.weight > $1.weight : $0.id < $1.id }
        let anchors = Array(sorted.prefix(6))
        var rest = Array(sorted.dropFirst(6))
        if !rest.isEmpty {
            let shift = generation % rest.count
            rest = Array(rest[shift...] + rest[..<shift])
        }
        return anchors + rest
    }

    private func color(_ index: Int) -> Color {
        Color(hex: (scheme == .dark ? Self.dark : Self.light)[index % WordWallLayout.colorCount])
    }

    /// One flip every 5 s (0.8 s long); a swap and re-pack every 40 s. Nothing runs under Reduce Motion.
    private func moments(_ bricks: [WallBrick]) async {
        guard !reduceMotion, !bricks.isEmpty else { return }
        var tick = 0
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(5))
            if Task.isCancelled { return }
            tick += 1
            if tick % 8 == 0 {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { generation += 1 }
                return
            }
            guard let pick = bricks.randomElement() else { continue }
            withAnimation(.easeInOut(duration: 0.8)) { flipping = pick.id }
            try? await Task.sleep(for: .seconds(0.8))
            flipping = nil
        }
    }
}

/// Width per point of font size, in Figtree Black capitals with the wall's tracking, cached.
enum WordWallMeasure {
    nonisolated(unsafe) private static var cache: [String: CGFloat] = [:]
    private static let lock = NSLock()

    static func advance(_ text: String) -> CGFloat {
        let key = text.uppercased()
        lock.lock()
        defer { lock.unlock() }
        if let hit = cache[key] { return hit }
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: "Figtree",
            .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.black],
        ])
        let font = UIFont(descriptor: descriptor, size: 100)
        let width = (key as NSString).size(withAttributes: [.font: font, .kern: -1.0]).width / 100
        cache[key] = width
        return width
    }
}
