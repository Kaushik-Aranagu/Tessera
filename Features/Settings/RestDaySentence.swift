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
        let rest = AppModel.isDemo ? demoDay ?? RestWeekday.sunday : RestWeekday.current(in: model.store)
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: 0) {
                Text("Rest day: ")
                Button(Self.word(rest)) {
                    withTesseraAnimation(reduceMotion: reduceMotion) { choosing.toggle() }
                }
                .buttonStyle(.valueWash)
                .fontWeight(.semibold)
                .foregroundStyle(SettingsV2.valueInk)
                .contentTransition(.opacity)
                .accessibilityLabel("Rest day")
                .accessibilityValue(Self.word(rest))
                .accessibilityHint("Shows the days to pick from")
                Text(".")
            }
            .textRole(.body)
            .foregroundStyle(Theme.Colors.ink)
            if choosing {
                // One row of eight words, or two at large type (Design). Static children: ViewThatFits must not be
                // handed a ForEach.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Spacing.m) {
                        day(1)
                        day(2)
                        day(3)
                        day(4)
                        day(5)
                        day(6)
                        day(7)
                        any
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        HStack(spacing: Theme.Spacing.m) {
                            day(1)
                            day(2)
                            day(3)
                            day(4)
                        }
                        HStack(spacing: Theme.Spacing.m) {
                            day(5)
                            day(6)
                            day(7)
                            any
                        }
                    }
                }
                .settingsWordStyle()
                .transition(.opacity)
            }
        }
    }

    private func day(_ weekday: Int) -> some View {
        Button(Self.short[weekday - 1]) { pick(weekday) }
            .accessibilityLabel(RestWeekday.name(of: weekday))
    }

    private var any: some View {
        Button("Any") { pick(nil) }
            .accessibilityLabel("Any day")
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
            TessVoice.shared.say("Didn't save that. Try again")
            return
        }
        model.touch()
        TessVoice.shared.say(weekday.map(RestWeekday.receipt(for:)) ?? "Rest day, any day", undo: record)
    }
}
