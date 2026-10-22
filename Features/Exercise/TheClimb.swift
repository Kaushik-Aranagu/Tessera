import SwiftUI
import TesseraCore

/// One session on the climb: the heaviest set it had (docs/design/training-app-124.md, "Exercise page").
struct ClimbSession: Identifiable, Hashable {
    /// The exercise entry's id.
    let id: UUID
    let workoutID: UUID
    let date: Date
    let weight: Double
    let reps: Int
    /// Holds the best set: drawn as the hot ring.
    let isBest: Bool

    /// How many sessions the climb shows.
    static let limit = 12

    /// The last `limit` sessions, oldest first. `sessions` is newest first, as the ledger returns them.
    static func recent(_ sessions: [TrainingLedger.Session], bestID: UUID?, limit: Int = limit) -> [ClimbSession] {
        sessions.prefix(limit).reversed().compactMap { session in
            guard let top = session.sets.max(by: { ($0.weight, $0.reps) < ($1.weight, $1.reps) }) else { return nil }
            return ClimbSession(id: session.id, workoutID: session.workoutID, date: session.date, weight: top.weight,
                                reps: Int(top.reps.rounded()),
                                isBest: bestID.map { id in session.sets.contains { $0.id == id } } ?? false)
        }
    }

    /// "82.5 × 7"
    var setText: String {
        ExerciseWords.set(weight: weight, reps: Double(reps))
    }
}

/// Weight across, on a light grid at 5 kg or 10 lb steps. Pure so it can be tested; the weights are in the unit shown.
struct ClimbAxis: Equatable {
    /// The grid step in a unit: 5 kg, or 10 lb (a step a plate set can make).
    static func step(for unit: MassUnit) -> Double {
        unit == .pounds ? 10 : 5
    }

    let low: Double
    let high: Double
    let step: Double

    /// Nil when there is no weight to climb (bodyweight work: the rows go without the plot).
    init?(weights: [Double], step: Double = 5) {
        guard let max = weights.max(), let min = weights.min(), max > 0 else { return nil }
        var low = (min / step).rounded(.down) * step
        var high = (max / step).rounded(.up) * step
        // Never a one-step plot: a flat climb still has room to move.
        if high - low < 2 * step {
            high = low + 2 * step
        }
        if low < 0 {
            low = 0
        }
        self.low = low
        self.high = high
        self.step = step
    }

    /// The labelled lines: 75, 80, 85.
    var gridlines: [Double] {
        stride(from: low, through: high, by: step).map(\.self)
    }

    /// 0 at the lowest line, 1 at the highest.
    func unit(_ weight: Double) -> Double {
        high > low ? (weight - low) / (high - low) : 0
    }
}

/// "The climb": sessions down the page, weight across, each session a dot joined to the next by a thin line, the
/// best a hot ring, the set as Outfit text at the right. Tap a row to open that session.
struct TheClimb: View {
    let sessions: [ClimbSession]
    let total: Int

    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize

    /// One form for every row: "Sep 29", "Oct 5".
    static func dateWord(_ date: Date, zone: TimeZone?, calendar: Calendar = .current) -> String {
        var style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        style.timeZone = zone ?? calendar.timeZone
        return date.formatted(style)
    }

    /// A session's weight in the unit shown, for the plot.
    private static func shownWeight(_ session: ClimbSession) -> Double {
        Format.unit.fromKilograms(session.weight, rounded: false)
    }

    private static let rowHeight: CGFloat = 46
    private static let dateWidth: CGFloat = 78
    private static let setWidth: CGFloat = 104
    /// The Tess orb's width and glow at the lower right: no set text runs under it, at any text size.
    private static let orbRoom: CGFloat = 68
    /// Points one axis number needs.
    private static let labelRoom: CGFloat = 40

    var body: some View {
        let unit = Format.unit
        let axis = ClimbAxis(weights: sessions.map { unit.fromKilograms($0.weight, rounded: false) },
                             step: ClimbAxis.step(for: unit))
        let plots = axis != nil && !typeSize.isAccessibilitySize
        VStack(alignment: .leading, spacing: 0) {
            Text("The climb, \(total) \(total == 1 ? "session" : "sessions")")
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, Theme.Spacing.s)
            if plots, let axis {
                scale(axis)
            }
            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                row(session, at: index, axis: plots ? axis : nil)
                    .entrance(min(index, 8) + 6)
            }
        }
    }

    /// The numbers over the grid: 75 80 85.
    private func scale(_ axis: ClimbAxis) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: Self.dateWidth, height: 1)
            Canvas { context, size in
                // A number only where there is room for it: every line, or every second or third when it is wide.
                let gap = size.width / max(Double(axis.gridlines.count - 1), 1)
                let every = max(1, Int((Self.labelRoom / max(gap, 1)).rounded(.up)))
                for (index, line) in axis.gridlines.enumerated() where index % every == 0 {
                    let x = size.width * axis.unit(line)
                    let label = Text(Format.kilograms(line)).font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                    if index == 0 {
                        // The first number starts at its own line, not shoved off it by a clamp.
                        context.draw(label, at: CGPoint(x: x + 2, y: 8), anchor: .leading)
                    } else {
                        context.draw(label, at: CGPoint(x: min(x, size.width - 10), y: 8))
                    }
                }
            }
            .frame(height: 18)
            // The same right-hand room as the rows, so each number sits over its own line.
            Color.clear.frame(width: Self.setWidth + Self.orbRoom, height: 1)
        }
        .accessibilityHidden(true)
    }

    private func row(_ session: ClimbSession, at index: Int, axis: ClimbAxis?) -> some View {
        let date = Self.dateWord(session.date, zone: OpZones(store: model.store).zone(of: session.workoutID))
        let ink = session.isBest ? Theme.Colors.live : Theme.Colors.ink
        return Button { model.open(.object(session.workoutID)) } label: {
            // At accessibility sizes the set drops under the date: nothing wraps and nothing runs under the orb.
            let stacked = typeSize.isAccessibilitySize
            let layout = stacked
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
                : axis == nil
                ? AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
                : AnyLayout(HStackLayout(alignment: .center, spacing: 0))
            layout {
                Text(date)
                    .font(Theme.voice(size: 16))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(width: axis == nil ? nil : Self.dateWidth, alignment: .leading)
                    .fixedSize(horizontal: axis == nil, vertical: false)
                if let axis {
                    ClimbTrack(axis: axis, previous: sessions[safe: index - 1].map(Self.shownWeight),
                               weight: Self.shownWeight(session), next: sessions[safe: index + 1].map(Self.shownWeight),
                               isBest: session.isBest)
                        .frame(height: Self.rowHeight)
                } else if !stacked {
                    Spacer(minLength: 0)
                }
                Text(session.setText.keepingUnits)
                    .numeral(21, weight: .light)
                    .foregroundStyle(ink)
                    .frame(width: axis == nil ? nil : Self.setWidth, alignment: stacked ? .leading : .trailing)
                    // Clear of the Tess orb that floats at the lower right.
                    .padding(.trailing, stacked ? 0 : Self.orbRoom)
            }
            .padding(.vertical, stacked ? Theme.Spacing.xs : 0)
            .frame(minHeight: Self.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(date), \(session.setText.replacingOccurrences(of: "×", with: "by")) "
            + (Format.unit == .pounds ? "pounds" : "kilograms")
            + (session.isBest ? ", your best" : ""))
        .accessibilityHint("Opens that session")
    }
}

/// One row of the plot: the grid, the line in from the row above and out to the row below, and the dot.
private struct ClimbTrack: View {
    let axis: ClimbAxis
    let previous: Double?
    let weight: Double
    let next: Double?
    let isBest: Bool

    var body: some View {
        Canvas { context, size in
            let x = { (value: Double) in size.width * axis.unit(value) }
            let mid = size.height / 2
            for line in axis.gridlines {
                var grid = Path()
                grid.move(to: CGPoint(x: x(line), y: 0))
                grid.addLine(to: CGPoint(x: x(line), y: size.height))
                context.stroke(grid, with: .color(Theme.Colors.ink.opacity(0.10)), lineWidth: 1)
            }
            // The joins meet halfway across the row seam, so the line runs on from one row to the next.
            var line = Path()
            if let previous {
                line.move(to: CGPoint(x: (x(previous) + x(weight)) / 2, y: 0))
                line.addLine(to: CGPoint(x: x(weight), y: mid))
            } else {
                line.move(to: CGPoint(x: x(weight), y: mid))
            }
            if let next {
                line.addLine(to: CGPoint(x: (x(weight) + x(next)) / 2, y: size.height))
            }
            context.stroke(line, with: .color(Theme.Colors.ink.opacity(0.55)), lineWidth: 1)
            let center = CGPoint(x: x(weight), y: mid)
            if isBest {
                let ring = CGRect(x: center.x - 7, y: center.y - 7, width: 14, height: 14)
                context.stroke(Path(ellipseIn: ring), with: .color(Theme.Colors.live), lineWidth: 2)
            } else {
                context.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)),
                             with: .color(Theme.Colors.ink))
            }
        }
        .accessibilityHidden(true)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
