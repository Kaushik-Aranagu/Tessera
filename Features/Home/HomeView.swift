import SwiftUI

/// Home: the launcher Tess paints in when you tap her. Each "app" is a view onto part of the object model.
struct HomeView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        let schedule = model.schedule()
        let left = schedule.filter { !$0.isWorkout && !$0.isDone }.count
        let workout = model.tonightWorkout()
        let scheduled: String = workout.flatMap {
            if case let .date(date)? = model.store.value("scheduledFor", of: $0) {
                return Format.clock(date)
            }
            return nil
        } ?? "—"

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("tessera")
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .entrance(0)
                RevealingHero(text: "Home")
                    .entrance(1, hero: true)
                    .padding(.bottom, Theme.Spacing.xxl)

                VStack(spacing: 0) {
                    row("Today", status: "\(left) left", order: 2) {
                        withTesseraAnimation(reduceMotion: false) { model.isHomeShown = false }
                    }
                    if let workout {
                        row("Training", status: "push · \(scheduled)", order: 3) {
                            model.isHomeShown = false
                            model.open(.object(workout.id), .jump)
                        }
                    }
                    if let task = model.classDef(.task) {
                        row("To-dos", status: "\(model.objects(of: .task).count)", order: 4) {
                            model.isHomeShown = false
                            model.open(.classDef(task.id), .jump)
                        }
                    }
                    if let exercise = model.classDef(.exercise) {
                        row("Exercises", status: "library", order: 5) {
                            model.isHomeShown = false
                            model.open(.classDef(exercise.id), .jump)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.xl)
            .padding(.bottom, 180)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
    }

    private func row(_ title: String, status: String, order: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Hairline()
                HStack(alignment: .firstTextBaseline) {
                    Text(title).textRole(.title).foregroundStyle(Theme.Colors.ink)
                    Spacer()
                    Text(status).textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                }
                .padding(.vertical, Theme.Spacing.l)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .entrance(order)
    }
}

/// The paint that floods the screen from Tess when you tap her: vermilion → violet → cobalt, blurred,
/// scaling up from the bar (~0.5 s), then fading as the new content enters underneath.
struct PaintFlood: View {
    let isOn: Bool
    let origin: CGPoint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(RadialGradient(
                colors: [
                    Color(hex: 0xC8452F),
                    Color(hex: 0x7A5C8E),
                    Color(hex: 0x2E6DA4),
                    Color(hex: 0xE0B341).opacity(0),
                ],
                center: .center, startRadius: 0, endRadius: 60
            ))
            .frame(width: 120, height: 110)
            .blur(radius: 10)
            .scaleEffect(isOn && !reduceMotion ? 16 : 0.3)
            .opacity(isOn ? 1 : 0)
            .position(origin)
            .animation(.timingCurve(0.6, 0, 0.3, 1, duration: 0.52), value: isOn)
            .animation(.easeOut(duration: 0.42), value: isOn)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
