import SwiftUI

/// The set screen (docs/design/watch-set-logging-105.md): exercise, weight, reps, set count and the word Done on its ink
/// line. After Done the weight row turns into the rest countdown on the same screen. Sizes 44 / 21 / 16, nothing else.
struct SetFace: View {
    @Environment(WatchStore.self) private var store
    @Environment(\.isLuminanceReduced) private var dimmed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var crown: Double = 0
    @State private var repsWidth: CGFloat = 160
    @FocusState private var crownFocused: Bool

    private var snap: WatchSnapshot { store.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            name
            if snap.phase == .rest {
                RestRow()
            } else {
                numeral(WatchSnapshot.number(store.weight), unit: snap.unit, active: store.crownMovesWeight)
                    .onTapGesture { store.crownMovesWeight = true }
                numeral("\(store.reps)", unit: nil, active: !store.crownMovesWeight)
                    .contentShape(Rectangle())
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { repsWidth = $0 }
                    .onTapGesture { location in step(reps: location.x) }
            }
            setLabel
            Spacer(minLength: 4)
            bottomLine
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .opacity(dimmed ? 0.7 : 1)
        .focusable()
        .focused($crownFocused)
        .digitalCrownRotation($crown, from: 0, through: 400, by: store.crownMovesWeight ? snap.weightStep : 1,
                              sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
        .onChange(of: crown) { _, value in
            if store.crownMovesWeight { store.weight = value } else { store.reps = max(1, Int(value)) }
        }
        .onChange(of: store.crownMovesWeight) { syncCrown() }
        .onChange(of: snap) { syncCrown() }
        .onAppear { crownFocused = true; syncCrown() }
        .overlay(alignment: .topTrailing) {
            if store.writeFailed { Text("Not saved").font(WatchInk.face(16)).opacity(0.7).padding(.trailing, 12) }
        }
        .modifier(SetFaceAccess(store: store, label: spokenLabel, onDefault: defaultAction, onAdjust: adjust))
    }

    private func adjust(_ direction: AccessibilityAdjustmentDirection) {
        let sign: Double = direction == .increment ? 1 : -1
        if store.crownMovesWeight {
            store.weight = max(0, store.weight + sign * snap.weightStep)
        } else {
            store.reps = max(1, store.reps + Int(sign))
        }
        syncCrown()
    }

    /// "SET 4 of 5", or for ten seconds after an undo "Set 4, removed." as plain text with the ink word UNDO.
    @ViewBuilder
    private var setLabel: some View {
        if snap.phase == .set, let note = store.undoNote {
            HStack(spacing: 8) {
                Text(note).font(WatchInk.face(16, .regular)).opacity(0.7).lineLimit(1).minimumScaleFactor(0.8)
                Button("UNDO") { store.putBack() }
                    .buttonStyle(.plain).font(WatchInk.face(16)).tracking(0.6)
                    .accessibilityLabel("Undo. Log the removed set back.")
            }
            .padding(.top, 2)
        } else {
            Text("SET \(snap.setNumber) of \(snap.setCount)")
                .font(WatchInk.face(16, .regular)).tracking(0.6).opacity(0.7)
                .padding(.top, 2)
        }
    }

    private var spokenLabel: String {
        let unit = snap.unit == "kg" ? "kilograms" : "pounds"
        let base = "\(snap.exercise), set \(snap.setNumber) of \(snap.setCount), "
        if snap.phase == .rest {
            return base + "resting. Double tap to remove the set just logged."
        }
        return base + "weight \(WatchSnapshot.number(store.weight)) \(unit), reps \(store.reps). Done."
    }

    private func defaultAction() {
        if snap.phase == .rest {
            if (snap.restEndsAt ?? .distantPast) <= Date.now { store.skipRest() } else { store.undo() }
        } else {
            store.done()
        }
    }

    private func syncCrown() {
        crown = store.crownMovesWeight ? store.weight : Double(store.reps)
    }

    /// Tap the left half of the reps row to step down, the right half to step up.
    private func step(reps location: CGFloat) {
        store.crownMovesWeight = false
        store.reps = max(1, store.reps + (location > repsWidth / 2 ? 1 : -1))
        syncCrown()
    }

    private var name: some View {
        ViewThatFits(in: .horizontal) {
            Text(snap.exercise).font(WatchInk.face(16)).lineLimit(1).fixedSize()
            ForEach(WatchSnapshot.shortNames(snap.exercise), id: \.self) { form in
                Text(form).font(WatchInk.face(16)).lineLimit(1).fixedSize()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func numeral(_ text: String, unit: String?, active: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(text).font(WatchInk.face(44)).monospacedDigit().minimumScaleFactor(0.7).lineLimit(1)
            if let unit { Text(unit).font(WatchInk.face(16, .regular)).opacity(0.7) }
        }
        .opacity(active ? 1 : 0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Done, or while resting the set just logged (tap it to take it out).
    @ViewBuilder
    private var bottomLine: some View {
        if snap.phase == .rest {
            let line = snap.sets.first ?? ""
            inkLine(line, action: store.undo)
                // A swipe back on the line takes the set out, as the tap does.
                .gesture(DragGesture(minimumDistance: 16).onEnded { drag in
                    if drag.translation.width > 30, abs(drag.translation.height) < 30 { store.undo() }
                })
        } else {
            inkLine("Done", action: store.done)
        }
    }

    private func inkLine(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Text(text).font(WatchInk.face(21)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
                Rectangle().fill(WatchInk.cream).frame(height: 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Rest: the countdown in the weight row (tabular, colon at 55%), "+15" on the right, the cream horizon emptying
/// from the right. When it is up the countdown becomes "Go" (tap it to take the set).
struct RestRow: View {
    @Environment(WatchStore.self) private var store
    @Environment(\.isLuminanceReduced) private var dimmed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let end = store.snapshot.restEndsAt ?? .distantPast
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(end.timeIntervalSince(context.date), 0)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    if remaining > 0 {
                        countdown(remaining)
                        Spacer(minLength: 0)
                        Button("+15") { store.extendRest() }
                            .buttonStyle(.plain).font(WatchInk.face(16)).opacity(0.7)
                            .accessibilityLabel("Add 15 seconds")
                    } else {
                        Button("Go") { store.skipRest() }
                            .buttonStyle(.plain).font(WatchInk.face(44))
                            .accessibilityLabel("Go. Rest is over.")
                    }
                }
                horizon(remaining: remaining, at: context.date)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func countdown(_ remaining: TimeInterval) -> some View {
        let total = Int(remaining.rounded(.up))
        return HStack(spacing: 0) {
            Text("\(total / 60)").font(WatchInk.face(44)).monospacedDigit()
            Text(":").font(WatchInk.face(44)).opacity(0.55)
            Text(String(format: "%02d", total % 60)).font(WatchInk.face(44)).monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rest, \(total / 60) minutes \(total % 60) seconds left")
    }

    /// A 2 pt cream line that empties from the right; it glides, except always-on and Reduce Motion, where it steps.
    private func horizon(remaining: TimeInterval, at date: Date) -> some View {
        let total = max(store.snapshot.restTotal, 1)
        let end = store.snapshot.restEndsAt ?? .distantPast
        return GeometryReader { proxy in
            if dimmed || reduceMotion {
                line(width: proxy.size.width * remaining / total)
            } else {
                TimelineView(.animation) { inner in
                    line(width: proxy.size.width * max(end.timeIntervalSince(inner.date), 0) / total)
                }
            }
        }
        .frame(height: 2)
    }

    private func line(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            Rectangle().fill(WatchInk.cream).frame(width: max(width, 0))
            Spacer(minLength: 0)
        }
    }
}

/// VoiceOver can do everything the screen does: the default action is Done (in the rest, Go once it is over, else take
/// the set out), and the rest are named.
private struct SetFaceAccess: ViewModifier {
    let store: WatchStore
    let label: String
    let onDefault: () -> Void
    let onAdjust: (AccessibilityAdjustmentDirection) -> Void

    func body(content: Content) -> some View {
        let resting = store.snapshot.phase == .rest
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityAction(.default, onDefault)
            .accessibilityAction(named: "Add 15 seconds") { if resting { store.extendRest() } }
            .accessibilityAction(named: "Go") { if resting { store.skipRest() } }
            .accessibilityAction(named: "Remove set") { if resting { store.undo() } }
            .accessibilityAction(named: "This exercise") { store.sideShown = true }
            .accessibilityAdjustableAction(onAdjust)
    }
}
