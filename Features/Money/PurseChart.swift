import SwiftUI

// The Purse keystone, first working version (sheets 277 v3, 279; landing contract v2 §2): "you are the stock". One
// chart in the slot, no figures anywhere on it: a solid line for what is still yours by day, a dashed forecast at your
// pace to the month's end, last month faint behind, and a dotted floor for bills once bills exist. The category
// names run across the top (swipe sideways), the index names down the right (swipe up and down).

/// One index drawn as a month by day. Values are in the ledger's one currency; they never leave this struct as text.
struct PurseSeries: Equatable {
    enum Shape: Equatable {
        /// Cumulative in minus out (MONTH): 0 sits inside the axis.
        case balance
        /// Cumulative out for a basket (a kind, SPEND): starts at 0 and only climbs.
        case flow
    }

    let name: String
    let shape: Shape
    /// One value per day from the 1st up to today (index 0 is the 1st).
    let solid: [Double]
    /// Today onward to the month's last day at the month's pace; empty when nothing has happened yet.
    let forecast: [Double]
    /// Last month by day, for the faint line behind.
    let prior: [Double]
    /// The bills still owed this month (the dotted floor); nil until there is a Bills model.
    let floor: Double?
    let daysInMonth: Int

    var isEmpty: Bool {
        solid.allSatisfy { $0 == 0 } && prior.allSatisfy { $0 == 0 }
    }

    /// The vertical range: contains 0 (the baseline first, rule 1), every line, padded 8%.
    var range: ClosedRange<Double> {
        let values = solid + forecast + prior + [0] + (floor.map { [$0] } ?? [])
        let low = values.min() ?? 0
        let high = values.max() ?? 1
        let span = max(high - low, 1)
        return (low - span * 0.08) ... (high + span * 0.08)
    }

    /// Builds a series from daily nets (in minus out for a balance; out for a flow), day 1 first.
    static func build(name: String, shape: Shape, daily: [Double], today: Int, daysInMonth: Int,
                      priorDaily: [Double], floor: Double? = nil) -> PurseSeries
    {
        let upTo = max(1, min(today, daysInMonth))
        var running = 0.0
        let solid = (0 ..< upTo).map { day -> Double in
            running += day < daily.count ? daily[day] : 0
            return running
        }
        var priorRunning = 0.0
        let prior = priorDaily.map { value -> Double in
            priorRunning += value
            return priorRunning
        }
        // Pace: the month so far per day, carried on from today to the last day.
        let pace = running / Double(upTo)
        let hasData = daily.prefix(upTo).contains { $0 != 0 }
        let forecast = hasData && upTo < daysInMonth
            ? (0 ... (daysInMonth - upTo)).map { running + pace * Double($0) } : []
        return PurseSeries(name: name, shape: shape, solid: solid, forecast: forecast, prior: prior, floor: floor,
                           daysInMonth: daysInMonth)
    }
}

/// One category across the top of the slot, with the indices that sit in it down the right.
struct PurseCategory: Equatable, Identifiable {
    let id: String
    let name: String
    let indices: [PurseSeries]
}

/// The keystone: category names across the top, the chart, the index names at the right. Swipe sideways for the
/// category, up and down for the index. The chart has no numbers, no red and no green.
struct PurseIndexView: View {
    let categories: [PurseCategory]
    @Binding var category: Int
    @Binding var index: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var drawn: CGFloat = 0
    @State private var cue = HapticCue()

    static let topRow: CGFloat = 26
    static let scroller: CGFloat = 78

    private var sage: Color {
        scheme == .dark ? Color(hex: 0x8DBFA7) : Color(hex: 0x3F7A62)
    }

    private var clay: Color {
        scheme == .dark ? Color(hex: 0xE2A07F) : Color(hex: 0x9C4B2C)
    }

    private var current: PurseCategory? {
        categories.isEmpty ? nil : categories[min(category, categories.count - 1)]
    }

    private var series: PurseSeries? {
        guard let current, !current.indices.isEmpty else { return nil }
        return current.indices[min(index, current.indices.count - 1)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            categoryRow
            HStack(alignment: .top, spacing: 8) {
                chart
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                scrollerColumn
                    .frame(width: Self.scroller, alignment: .leading)
            }
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 10).onEnded { value in
            let dx = value.translation.width
            let dy = value.translation.height
            if abs(dx) > abs(dy), abs(dx) > 40 {
                turnCategory(dx < 0 ? 1 : -1)
            } else if abs(dy) > 30 {
                turnIndex(dy < 0 ? 1 : -1)
            }
        })
        .tesseraFeedback(cue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .accessibilityHint("Swipe up or down for the next index")
        .accessibilityAdjustableAction { direction in turnIndex(direction == .increment ? 1 : -1) }
        .accessibilityAction(named: Text("Next category")) { turnCategory(1) }
        .accessibilityAction(named: Text("Previous category")) { turnCategory(-1) }
        .onAppear { draw() }
        .onChange(of: category) { _, _ in draw() }
        .onChange(of: index) { _, _ in draw() }
    }

    /// The current category bold in ink, the next ones after it in ink 2, clipped at the right edge.
    private var categoryRow: some View {
        HStack(spacing: 16) {
            ForEach(Array(categories.enumerated()), id: \.element.id) { offset, item in
                if offset >= category {
                    Text(item.name)
                        .font(.custom("Figtree", fixedSize: offset == category ? 15 : 13)
                            .weight(offset == category ? .bold : .regular))
                        .foregroundStyle(offset == category ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
        }
        .frame(height: Self.topRow - 6, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .tesseraAnimation(Theme.Motion.firm, value: category)
    }

    private var scrollerColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array((current?.indices ?? []).enumerated()), id: \.offset) { offset, item in
                Text(item.name.uppercased())
                    .font(.custom("Figtree", fixedSize: 13).weight(offset == index ? .bold : .regular))
                    .tracking(0.78)
                    .foregroundStyle(offset == index ? sage : Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .tesseraAnimation(Theme.Motion.firm, value: index)
    }

    @ViewBuilder
    private var chart: some View {
        if let series, !series.isEmpty {
            Canvas { context, size in
                let range = series.range
                let days = max(series.daysInMonth - 1, 1)
                func point(_ day: Int, _ value: Double) -> CGPoint {
                    CGPoint(x: size.width * CGFloat(day) / CGFloat(days),
                            y: size
                                .height *
                                (1 - CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))))
                }
                func line(_ values: [Double], from start: Int) -> Path {
                    var path = Path()
                    for (offset, value) in values.enumerated() {
                        let spot = point(start + offset, value)
                        if offset == 0 {
                            path.move(to: spot)
                        } else {
                            path.addLine(to: spot)
                        }
                    }
                    return path
                }
                // The baseline (0) as a hairline, last month faint, the bills floor dotted clay.
                var zero = Path()
                zero.move(to: point(0, 0))
                zero.addLine(to: point(days, 0))
                context.stroke(zero, with: .color(Theme.Colors.inkSecondary.opacity(0.35)), lineWidth: 0.5)
                context.stroke(line(series.prior, from: 0), with: .color(Theme.Colors.inkSecondary.opacity(0.35)),
                               lineWidth: 1)
                if let floor = series.floor {
                    var bills = Path()
                    bills.move(to: point(0, floor))
                    bills.addLine(to: point(days, floor))
                    context.stroke(bills, with: .color(clay), style: StrokeStyle(lineWidth: 1.2, dash: [1, 4]))
                }
                let solid = line(series.solid, from: 0).trimmedPath(from: 0, to: drawn)
                context.stroke(
                    solid,
                    with: .color(sage),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                if drawn >= 1, !series.forecast.isEmpty {
                    context.stroke(line(series.forecast, from: series.solid.count - 1), with: .color(Theme.Colors.ink),
                                   style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                }
            }
        } else {
            Text(series == nil ? "Not set up yet" : "Nothing yet")
                .font(.custom("Figtree", fixedSize: 15))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private var spoken: String {
        let name = current?.name ?? "Purse"
        guard let series else { return "\(name), not set up yet" }
        if series.isEmpty {
            return "\(name), \(series.name), nothing yet"
        }
        let heading = series.forecast.count > 1 && series.forecast.last! < series.forecast.first! ? "heading down" : "heading up"
        return "\(name), \(series.name), \(heading) at this pace"
    }

    private func draw() {
        drawn = reduceMotion ? 1 : 0
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { drawn = 1 }
    }

    private func turnCategory(_ step: Int) {
        guard categories.count > 1 else { return }
        withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) {
            category = (category + step + categories.count) % categories.count
            index = 0
        }
        cue.play(.selection)
    }

    private func turnIndex(_ step: Int) {
        guard let count = current?.indices.count, count > 1 else { return }
        withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { index = (index + step + count) % count }
        cue.play(.selection)
    }
}
