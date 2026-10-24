import SwiftUI
import TesseraCore

/// Quiet hours (sheet 167): one sentence, "Quiet 10 pm to 7 am. 2 things are waiting.", and a line that spans the day
/// with two ends to drag. The digits roll, a tick falls at each hour, and the change is written when the finger lifts
/// (one op with Undo in Tess's band). Timers always come through. The house clock is always am/pm.
struct QuietHoursPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = QuietHours.standard.startMinute
    @State private var end = QuietHours.standard.endMinute
    /// The values when a drag began, for the one Undo.
    @State private var before: (start: Int, end: Int)?
    @State private var ticks = 0

    private static let space = "quietTrack"
    private static let handle: CGFloat = 44

    private var hours: QuietHours {
        QuietHours(startMinute: start, endMinute: end)
    }

    var body: some View {
        let _ = model.revision
        HubPage(title: "Quiet") {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                sentence
                dayLine
                Text("Timers always come through.")
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkTertiary)
            }
        }
        .tesseraFeedback(.selection, trigger: ticks)
        .onAppear(perform: load)
    }

    private var waiting: Int {
        QuietInterrupts(store: model.engine.store, classes: model.engine.classes).waitingCount
    }

    private var sentence: some View {
        let left = waiting
        let tail = left == 0 ? "Nothing is waiting." : left == 1 ? "1 thing is waiting." : "\(left) things are waiting."
        return Text(hours.isNone ? "Quiet is off. \(tail)" : "Quiet \(hours.words). \(tail)")
            .textRole(.body)
            .foregroundStyle(Theme.Colors.ink)
            .contentTransition(reduceMotion ? .identity : .numericText())
            .animation(MotionPolicy.resolve(Theme.Motion.snappy, reduceMotion: reduceMotion), value: hours.words)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Quiet hours, \(hours.isNone ? "off" : hours.words)")
    }

    /// A line spanning midnight to midnight with the quiet stretch drawn heavier and an end to drag at each side.
    private var dayLine: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let x: (Int) -> CGFloat = { CGFloat($0) / 1440 * width }
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Theme.Colors.inkTertiary).frame(width: width, height: 1).offset(y: 21.5)
                if !hours.isNone {
                    if start < end {
                        Rectangle().fill(Theme.Colors.ink).frame(width: x(end) - x(start), height: 3)
                            .offset(x: x(start), y: 20.5)
                    } else {
                        Rectangle().fill(Theme.Colors.ink).frame(width: x(end), height: 3).offset(y: 20.5)
                        Rectangle().fill(Theme.Colors.ink).frame(width: width - x(start), height: 3)
                            .offset(x: x(start), y: 20.5)
                    }
                }
                end(at: x(start), isStart: true, width: width)
                end(at: x(end), isStart: false, width: width)
            }
            .coordinateSpace(.named(Self.space))
        }
        .frame(height: 44)
        .accessibilityElement(children: .contain)
    }

    /// One end of the quiet stretch: a 44 pt target on the line where its weight changes.
    private func end(at position: CGFloat, isStart: Bool, width: CGFloat) -> some View {
        // No mark stands off the line: the end is where its weight changes. Only the 44 pt target is here.
        Color.clear
            .frame(width: Self.handle, height: Self.handle)
            .contentShape(Rectangle())
            .offset(x: position - Self.handle / 2, y: 0)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
                    .onChanged { value in
                        if before == nil {
                            before = (start, end)
                        }
                        let hour = Int((value.location.x / max(width, 1) * 24).rounded())
                        let minute = (min(max(hour, 0), 24) % 24) * 60
                        let current = isStart ? start : end
                        guard minute != current else { return }
                        withTesseraAnimation(reduceMotion: reduceMotion) {
                            if isStart {
                                start = minute
                            } else {
                                end = minute
                            }
                        }
                        ticks += 1
                    }
                    .onEnded { _ in commit() }
            )
            .accessibilityElement()
            .accessibilityLabel(isStart ? "Quiet starts" : "Quiet ends")
            .accessibilityValue(HouseTime.clock(minuteOfDay: isStart ? start : end))
            .accessibilityAdjustableAction { direction in
                before = (start, end)
                let step = direction == .increment ? 60 : -60
                if isStart {
                    start = ((start + step) % 1440 + 1440) % 1440
                } else {
                    end = ((end + step) % 1440 + 1440) % 1440
                }
                ticks += 1
                commit()
            }
    }

    private func load() {
        guard model.settingsAreReal else { return }
        let now = SettingsStore(engine: model.engine).read().quietHours
        start = now.startMinute
        end = now.endMinute
    }

    /// The finger lifted: write both ends as one change and say it with the one Undo.
    private func commit() {
        guard let was = before else { return }
        before = nil
        guard (was.start, was.end) != (start, end) else { return }
        let (newStart, newEnd) = (start, end)
        model.updateSettings { $0.quietStartMinute = newStart; $0.quietEndMinute = newEnd }
        TessVoice.shared.say(hours.isNone ? "Quiet is off." : "Quiet \(hours.words).", takeBack: {
            model.updateSettings { $0.quietStartMinute = was.start; $0.quietEndMinute = was.end }
            start = was.start
            end = was.end
        })
    }
}
