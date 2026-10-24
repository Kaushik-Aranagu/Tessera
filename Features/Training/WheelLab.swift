#if DEBUG
    import SwiftUI

    /// `-wheelLab` (simulator, Debug): one wheel and one number alone on a page, so the UI tests can drive them. A
    /// plain tap on a row must centre it, and a tap on the focused row must report it opened.
    struct WheelLab: View {
        private struct Lift: Identifiable {
            let id: Int
        }

        private let lifts = (0 ..< 7).map(Lift.init)
        @State private var focus = 3
        @State private var opened = "none"
        @State private var weight = 185.0

        var body: some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("Focused \(focus)")
                    .accessibilityIdentifier("wheel-focus")
                Text("Opened \(opened)")
                    .accessibilityIdentifier("wheel-opened")
                DepthWheel(items: lifts, focus: $focus, home: 3, style: .plan, label: "Lab wheel",
                           onTap: { lift, wasFocused in
                               if wasFocused {
                                   opened = "\(lift.id)"
                               }
                           },
                           rowIdentifier: { "wheel-row-\($0.id)" })
                { lift, state in
                    Text("Lift \(lift.id)")
                        .font(Theme.Training.words(30, weight: .semibold))
                        .foregroundStyle(state.isFocused ? Theme.Colors.Accent.training : Theme.Colors.inkSecondary)
                }
                ScrollingNumber(value: $weight, step: 5, range: 0 ... 600, format: { String(Int($0)) },
                                name: "Weight", spokenUnit: "pounds", font: Theme.Training.number(84), width: 200)
                    .accessibilityIdentifier("wheel-number")
            }
            .padding(Theme.Spacing.gutter)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.Colors.paper)
        }
    }
#endif
