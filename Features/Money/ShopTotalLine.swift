import SwiftUI
import TesseraCore

/// The groceries total, asked once (Money slice 3 and screen 5, as a quiet line): after a shop finishes, "Groceries
/// total?" in Tess's ink with where it came from ("From the 5:40 pm shop."). A tap opens the typed field in place
/// (VoiceOver lands there, G305); Log writes Core's `LogShopTotal` ("Groceries total, 38.20, logged.", UNDO 4 s,
/// `.made` once); "Skip" writes `SkipShopTotal` ("Groceries total, skipped.", UNDO 10 s, no haptic). It shows only
/// while Core says a total is awaited and areas are shown; on Now, only where Core's quiet hours allow it.
///
/// The drum dial of the steer (whole units and cents) is not here yet: the typed field is the one path.
struct ShopTotalLine: View {
    /// Space above the line when it shows (none is taken when it doesn't).
    var top: CGFloat = 0
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var open = false
    @State private var text = ""
    @State private var made = 0
    @FocusState private var typing: Bool

    /// Whether the line shows: areas are shown and Core has a shop awaiting its total.
    @MainActor
    static func endedAt(model: AppModel, now: Date) -> Date? {
        guard AreasShown.isOn,
              let shop = ShopReceipt(store: model.store, classes: model.classes).awaiting(at: now) else { return nil }
        return model.store.value("endedAt", of: shop)?.dateValue
    }

    var body: some View {
        let _ = model.revision
        if let ended = Self.endedAt(model: model, now: AppClock.now) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Button {
                    withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { open = true }
                    typing = true
                } label: {
                    Text(MoneyCopy.totalPrompt)
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.tess)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the total")
                .disabled(open)
                if open {
                    AreaWritingLine(word: "Total", prompt: "38.20", label: "Groceries total", text: $text,
                                    focused: $typing, keyboard: .decimalPad, onSubmit: log)
                        .transition(.opacity)
                    HStack(spacing: Theme.Spacing.xl) {
                        Button("Log", action: log)
                            .buttonStyle(InkLabelWordStyle(color: Theme.Colors.health))
                            .frame(minHeight: 44)
                            .accessibilityLabel(text.isEmpty ? "Log" : "Log \(text)")
                        Button("Skip", action: skip)
                            .buttonStyle(InkLabelWordStyle())
                            .frame(minHeight: 44)
                            .accessibilityLabel(MoneyCopy.skipName)
                    }
                    .transition(.opacity)
                } else {
                    Text(MoneyCopy.totalContext(endedAt: ended))
                        .font(Theme.voice(size: 21))
                        .foregroundStyle(Theme.Colors.context)
                }
            }
            .padding(.top, top)
            .tesseraFeedback(.made, trigger: made)
            .transition(.opacity)
        }
    }

    private func log() {
        guard let action = MoneyCapture.total(text) else {
            TessVoice.shared.say("Didn't catch that. Try: 38.20")
            return
        }
        guard let done = try? model.engine.perform(action, by: .user) else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        typing = false
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            open = false
            text = ""
            model.touch()
        }
        // Away from the Month page a spend shows no amount (Money amendment 2, QA on #1148).
        TessVoice.shared.say(AreaPrivacy.shopTotalLogged, undo: done.record,
                             holds: .seconds(4))
        made += 1
    }

    /// Asked once: a skip ends it, with a 10 s UNDO that brings the question back (amendment 8).
    private func skip() {
        guard let record = try? model.engine.perform(SkipShopTotal(time: AppClock.now), by: .user).record else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        typing = false
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            open = false
            text = ""
            model.touch()
        }
        TessVoice.shared.say(record.receipt ?? "Groceries total, skipped.", undo: record, holds: .seconds(10))
    }
}
