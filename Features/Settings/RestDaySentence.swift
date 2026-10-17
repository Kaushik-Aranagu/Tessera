import SwiftUI
import TesseraCore

/// Settings' rest day (RG4, Research 146): "Rest day: Sunday." The day is a value word; a tap lays the week out
/// under it as label words, Sun to Sat and Any, and one tap writes it as one op with UNDO in Tess's band.
struct RestDaySentence: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var choosing = false
    /// The day shown in a demo, which never writes his settings.
    @State private var demoDay: Int?

    private static let short = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        let _ = model.revision
        let day = AppModel.isDemo ? demoDay ?? RestWeekday.sunday : RestWeekday.current(in: model.store)
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: 0) {
                Text("Rest day: ")
                Button(Self.word(day)) {
                    withTesseraAnimation(reduceMotion: reduceMotion) { choosing.toggle() }
                }
                .buttonStyle(.valueWash)
                .fontWeight(.semibold)
                .contentTransition(.opacity)
                .accessibilityLabel("Rest day")
                .accessibilityValue(Self.word(day))
                .accessibilityHint("Shows the days to pick from")
                Text(".")
            }
            .textRole(.body)
            .foregroundStyle(Theme.Colors.ink)
            if choosing {
                HStack(spacing: Theme.Spacing.m) {
                    ForEach(1 ... 7, id: \.self) { weekday in
                        Button(Self.short[weekday - 1]) { pick(weekday) }
                            .accessibilityLabel(RestWeekday.name(of: weekday))
                    }
                    Button("Any") { pick(nil) }
                        .accessibilityLabel("Any day")
                }
                .buttonStyle(.labelWord)
                .transition(.opacity)
            }
        }
    }

    /// "Sunday", or "any day" when he has no fixed rest day.
    static func word(_ day: Int?) -> String {
        day.map(RestWeekday.name(of:)) ?? "any day"
    }

    private func pick(_ weekday: Int?) {
        withTesseraAnimation(reduceMotion: reduceMotion) { choosing = false }
        // Never write his settings while a demo flag is on.
        if AppModel.isDemo {
            demoDay = weekday
            return
        }
        var settings = SettingsStore(engine: model.engine).read()
        guard settings.restWeekday != weekday else { return }
        settings.restWeekday = weekday
        guard let record = try? model.engine.perform(WriteSettings(settings: settings), by: .user).record else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        model.touch()
        TessVoice.shared.say(weekday.map(RestWeekday.receipt(for:)) ?? "Any day, rest day.", undo: record)
    }
}
