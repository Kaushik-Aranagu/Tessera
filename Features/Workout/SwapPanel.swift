import SwiftUI
import TesseraCore

private typealias Paint = WorkoutPaint

/// Swap within the movement: pulled down from the exercise name, a glass panel of alternatives in two groups (same
/// family, then same movement), at most four rows. An estimated load is marked "≈". Picking one fills its row with a
/// cobalt wash, then the panel closes and the new name writes in.
struct SwapPanel: View {
    let options: [ExerciseSwaps.Option]
    /// "Bench Press", for the footer.
    let current: String
    var onPick: (ExerciseSwaps.Option) -> Void

    @State private var picked: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if options.isEmpty {
                Text("Nothing else in the library moves like \(current.lowercased()).")
                    .font(Theme.voice)
                    .foregroundStyle(Paint.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, Theme.Spacing.m)
            }
            ForEach([ExerciseSwaps.Group.family, .movement], id: \.self) { group in
                let rows = options.filter { $0.group == group }
                if !rows.isEmpty {
                    Text(group.title)
                        .textRole(.label)
                        .foregroundStyle(Paint.secondary)
                        .padding(.top, Theme.Spacing.m)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(rows) { option in
                        row(option)
                    }
                }
            }
            if options.contains(where: \.isEstimate) {
                Text("≈ is an estimate. \(shortName) stays in the plan.")
                    .font(Theme.voice(size: 18))
                    .foregroundStyle(Paint.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Theme.Spacing.s)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .workoutGlass(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    /// "Bench" from "Bench Press": how Tess shortens a lift's name.
    private var shortName: String {
        Self.short(current)
    }

    static func short(_ name: String) -> String {
        let words = name.split(separator: " ")
        guard words.count > 1, let first = words.first else { return name }
        return String(first)
    }

    private func row(_ option: ExerciseSwaps.Option) -> some View {
        let isPicked = picked == option.id
        return Button {
            guard picked == nil else { return }
            withTesseraAnimation(.easeOut(duration: 0.18), reduceMotion: reduceMotion) { picked = option.id }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(220))
                onPick(option)
            }
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(option.exercise.name)
                    .font(Theme.numeral(24, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(Paint.cream)
                Spacer(minLength: Theme.Spacing.s)
                Text(loadText(option))
                    .font(Theme.numeral(21, weight: .regular))
                    .foregroundStyle(Paint.cream.opacity(0.8))
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 56)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Paint.cobalt.opacity(isPicked ? 0.55 : 0))
            }
            .padding(.horizontal, -10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.exercise.name)
        .accessibilityValue(accessibilityLoad(option))
        .accessibilityHint("Swaps for today only")
    }

    private func loadText(_ option: ExerciseSwaps.Option) -> String {
        guard let load = option.load else { return "—" }
        let each = option.isPerHand ? " each" : ""
        return "\(option.isEstimate ? "≈ " : "")\(Format.kilograms(load))\(each)"
    }

    private func accessibilityLoad(_ option: ExerciseSwaps.Option) -> String {
        guard let load = option.load else { return "No load yet" }
        let each = option.isPerHand ? " each" : ""
        return "\(option.isEstimate ? "About " : "")\(Format.kilograms(load)) kilograms\(each)"
    }
}

/// The top-set check: one line from Tess inside the set area, in cobalt, breathing gently, with a cobalt
/// brushstroke painting in under it to mark it as tappable. One tap accepts; then it reads "Done. 77.5 for sets 2
/// to 4." without the stroke. Ignoring it is fine; it leaves when the next set is logged.
struct TopSetCheckLine: View {
    let check: WorkoutSession.TopSetCheck
    var onAccept: () -> Void

    @State private var stroke: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let weight = Format.kilograms(check.suggested)
        let text = check.isAccepted
            ? "Done. \(weight) for sets \(check.fromSet) to \(check.toSet)."
            : "That was heavy. Drop to \(weight) for the rest?"
        Button(action: onAccept) {
            VStack(alignment: .leading, spacing: 2) {
                TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion || check.isAccepted)) { context in
                    let breath = (sin(context.date.timeIntervalSinceReferenceDate / 1.6 * 2 * .pi) + 1) / 2
                    Text(text)
                        .font(Theme.voice)
                        .lineSpacing(4)
                        .foregroundStyle(Paint.tess)
                        .opacity(check.isAccepted || reduceMotion ? 1 : 0.78 + 0.22 * breath)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                }
                if !check.isAccepted {
                    Brushstroke(progress: stroke)
                        .stroke(Paint.cobalt, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 120, height: 12)
                        .transition(.opacity)
                }
            }
            .frame(width: 250, alignment: .leading)
            .frame(minHeight: 60, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!check.isAccepted)
        .tesseraAnimation(value: check.isAccepted)
        .onAppear {
            withTesseraAnimation(.timingCurve(0.3, 0.7, 0.2, 1, duration: 0.7), reduceMotion: reduceMotion) {
                stroke = 1
            }
        }
        .accessibilityLabel(text)
        .accessibilityHint(check.isAccepted ? "" : "Drops the weight for the rest of this exercise")
    }
}
