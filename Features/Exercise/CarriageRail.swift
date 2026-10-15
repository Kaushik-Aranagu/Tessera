import SwiftUI

/// Sibling words in labels with a painted vermilion carriage (uneven radius, 0.5 pt blur) under the active one.
/// `progress` is fractional while paging, so the carriage follows the swipe continuously. Tapping a word selects it.
/// Used by the Exercise page (HISTORY · REP MAXES · MUSCLES) and Plans (WEEK · MONTH).
struct CarriageRail: View {
    enum Spread {
        /// Words share the width in equal columns, aligned left, centre, right (three views on one object).
        case columns
        /// Words sit left to right with a fixed gap (two pages).
        case packed(CGFloat)
    }

    let titles: [String]
    /// 0 … titles.count − 1.
    let progress: Double
    var spread: Spread = .columns
    var carriage = CGSize(width: 64, height: 4)
    var onSelect: (Int) -> Void

    @State private var frames: [Int: CGRect] = [:]

    var body: some View {
        let current = Int(progress.rounded())
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            words(current: current)
                .tesseraAnimation(Theme.Motion.snappy, value: current)
            UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 1.2, bottomTrailingRadius: 2.4,
                                   topTrailingRadius: 1, style: .continuous)
                .fill(Theme.Colors.live)
                .frame(width: carriage.width, height: carriage.height)
                .rotationEffect(.degrees(-1.2))
                .blur(radius: 0.5)
                .offset(x: carriageX)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)
        }
        .coordinateSpace(.named(Self.space))
        .onPreferenceChange(WordFrames.self) { frames = $0 }
        .sensoryFeedback(.selection, trigger: current)
    }

    @ViewBuilder
    private func words(current: Int) -> some View {
        switch spread {
        case .columns:
            HStack(spacing: 0) {
                ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                    word(index, title, current: current)
                        .frame(maxWidth: .infinity, alignment: alignment(index))
                }
            }
        case let .packed(gap):
            HStack(spacing: gap) {
                ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                    word(index, title, current: current)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func word(_ index: Int, _ title: String, current: Int) -> some View {
        Button { onSelect(index) } label: {
            Text(title)
                .textRole(.label)
                .foregroundStyle(index == current ? Theme.Colors.ink : Theme.Colors.muted)
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(key: WordFrames.self,
                                               value: [index: proxy.frame(in: .named(Self.space))])
                    }
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(index == current ? [.isSelected, .isButton] : .isButton)
    }

    private func alignment(_ index: Int) -> Alignment {
        guard titles.count > 1 else { return .leading }
        if index == 0 {
            return .leading
        }
        return index == titles.count - 1 ? .trailing : .center
    }

    /// Where the carriage starts for a word: under its left edge, centred, or under its right edge, matching how
    /// the word itself is aligned. Interpolated between the two words either side of `progress`.
    private var carriageX: CGFloat {
        guard !titles.isEmpty else { return 0 }
        let clamped = min(max(progress, 0), Double(titles.count - 1))
        let lower = Int(clamped.rounded(.down)), upper = min(lower + 1, titles.count - 1)
        let fraction = CGFloat(clamped - Double(lower))
        return anchor(lower) + (anchor(upper) - anchor(lower)) * fraction
    }

    private func anchor(_ index: Int) -> CGFloat {
        guard let frame = frames[index] else { return 0 }
        if case .packed = spread {
            return frame.minX
        }
        switch alignment(index) {
        case .trailing: return frame.maxX - carriage.width
        case .center: return frame.midX - carriage.width / 2
        default: return frame.minX
        }
    }

    private static let space = "carriageRail"
}

private struct WordFrames: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}
