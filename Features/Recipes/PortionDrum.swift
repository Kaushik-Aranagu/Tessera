import SwiftUI

/// The serving size as a drum: the reps drum's sibling on paper. Numbers in a vertical snap scroll, no box; the
/// centre one large in ink, its neighbours small and dim, the ends fading out. "serves" sits under it.
struct PortionDrum: View {
    @Binding var serves: Int
    /// Off when the recipe has no size: it shows "–".
    var isEnabled = true
    var range: ClosedRange<Int> = 1 ... 12

    /// From 1 to twice the written size, never less than 12, so "Makes 24" sits centred and highlighted (G57, K87.7).
    static func range(written: Int?) -> ClosedRange<Int> {
        1 ... max(12, 2 * (written ?? 0))
    }

    @State private var scrolled: Int?
    @State private var tick = 0

    private enum Metrics {
        static let width: CGFloat = 72
        static let pitch: CGFloat = 52
        static let rows: CGFloat = 3
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            if isEnabled {
                drum
            } else {
                Text("–")
                    .textRole(.titleNumber)
                    .foregroundStyle(Theme.Colors.inkTertiary)
                    .frame(width: Metrics.width, height: Metrics.pitch * Metrics.rows)
            }
            Text("serves")
                .font(Theme.voice(size: 18))
                .foregroundStyle(Theme.Colors.inkSecondary)
        }
        .onAppear { scrolled = serves }
        .onChange(of: scrolled) { _, new in
            guard let new, new != serves else { return }
            serves = new
            tick += 1
        }
        .onChange(of: serves) { _, new in
            if scrolled != new {
                scrolled = new
            }
        }
        // A detent is the house .selection (Haptics.swift: each weight detent); never a raw sensoryFeedback.
        .tesseraFeedback(.selection, trigger: tick)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Serves")
        .accessibilityValue(isEnabled ? "\(serves)" : "not given")
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            switch direction {
            case .increment: serves = min(range.upperBound, serves + 1)
            case .decrement: serves = max(range.lowerBound, serves - 1)
            @unknown default: break
            }
        }
    }

    private var drum: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(range), id: \.self) { value in
                    let isCurrent = value == (scrolled ?? serves)
                    Text("\(value)")
                        .textRole(isCurrent ? .titleNumber : .body)
                        .foregroundStyle(isCurrent ? Theme.Colors.ink : Theme.Colors.inkTertiary)
                        .frame(width: Metrics.width, height: Metrics.pitch)
                        .animation(.easeOut(duration: 0.16), value: isCurrent)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .never))
        .scrollPosition(id: $scrolled, anchor: .center)
        .contentMargins(.vertical, Metrics.pitch * (Metrics.rows - 1) / 2, for: .scrollContent)
        .frame(width: Metrics.width, height: Metrics.pitch * Metrics.rows)
        .mask {
            LinearGradient(stops: [
                .init(color: .clear, location: 0), .init(color: .black, location: 0.3),
                .init(color: .black, location: 0.7), .init(color: .clear, location: 1),
            ], startPoint: .top, endPoint: .bottom)
        }
    }
}
