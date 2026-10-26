import SwiftUI
import TesseraCore

/// The pick moment (lists-screens 12.2 to 12.5): over the dimmed page, one open item lifts out to the centre at 56.
/// A tap takes it (stamped picked, never checked) and opens it; a left swipe sends it back and picks again after
/// 200 ms; after the last skip, "That's all of them."; a tap outside closes. A private item reads "Private item".
struct PickMoment: View {
    let listID: UUID
    @Binding var picking: PickState?
    @Binding var picked: Int
    let rows: ShopTrip
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let picking {
            moment(picking)
        }
    }

    /// A left swipe sends it back and picks again after 200 ms; a skip writes nothing (12.3, 12.4).
    private func skipPick() {
        guard var state = picking, let item = state.item,
              let list = model.store.object(id: listID) else { return }
        state.skipped.insert(item.id)
        withTesseraAnimation(.easeOut(duration: 0.18), reduceMotion: reduceMotion) {
            picking = PickState(item: nil, skipped: state.skipped, between: true)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            // Closed during the gap (a tap outside): it stays closed (QA on #851).
            guard picking != nil else { return }
            let next = ListContents(store: model.store, classes: model.classes)
                .pick(from: list, excluding: state.skipped, now: AppClock.now)
            withTesseraAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.52, bounce: 0.18),
                                 reduceMotion: reduceMotion)
            {
                picking = PickState(item: next, skipped: state.skipped)
            }
            if next != nil {
                picked += 1
            }
        }
    }

    /// Tapping the pick takes it: stamped picked (never checked), "Heat, from Films." with UNDO 4 s, and it opens.
    private func acceptPick() {
        guard let item = picking?.item else { return }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { picking = nil }
        guard let record = try? model.engine.perform(AcceptPick(item: item.id, time: AppClock.now), by: .user).record
        else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        if let receipt = record.receipt {
            TessVoice.shared.say(receipt.hasSuffix(".") ? receipt : receipt + ".", undo: record, holds: .seconds(4))
        }
        model.open(.object(item.id))
    }

    /// The moment itself: the picked name at 56 in the centre, or "That's all of them." after the last skip.
    private func moment(_ state: PickState) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { picking = nil } }
                .accessibilityHidden(true)
            if let item = state.item {
                let shown = rows.maskedLabel(
                    for: item,
                    name: item.text,
                    lastWeightKg: BodyWeight.lastKg(in: model.store)
                )
                Button(action: acceptPick) {
                    Text(shown.prefix(1).uppercased() + shown.dropFirst())
                        .textRole(.hero)
                        .wordFit(shown)
                        .foregroundStyle(Theme.Colors.ink)
                        .multilineTextAlignment(.center)
                        .padding(Theme.Spacing.l)
                }
                .buttonStyle(HandleButtonStyle())
                .id(item.id)
                .transition(reduceMotion ? .opacity
                    : .asymmetric(insertion: .scale(scale: 0.4).combined(with: .opacity),
                                  removal: .move(edge: .leading).combined(with: .opacity)))
                .rowSwipe(.trailing, arm: CGFloat(GestureTuning.armUndrawn)) { event in
                    if case .committed = event {
                        skipPick()
                    }
                }
                .accessibilityHint("Opens it")
                .accessibilityAction(named: "Skip") { skipPick() }
            } else if !state.between {
                Text(ListsCopy.allPicked)
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.tess)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        // VoiceOver's scrub closes it, as a tap outside does (Design on #851).
        .accessibilityAction(.escape) {
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { picking = nil }
        }
    }
}
