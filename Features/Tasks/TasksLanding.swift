import SwiftUI
import TesseraCore

/// The Tasks landing (sheet 140): one thing in large words, then two after it, and three doors (Today, Soon, Later)
/// that open the rail on that place. Accent is ink; the one underline is Do it. Behind Review › "Tasks app".
struct TasksLandingPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    /// The place the rail is open on; nil shows the landing.
    @State private var rail: String?

    var body: some View {
        let _ = model.revision
        Group {
            if rail != nil {
                TasksRail(front: TasksFront(model: model), open: railBinding) { rail = nil }
            } else {
                landing(TasksFront(model: model))
            }
        }
        .background { ThemedBackground() }
    }

    private var railBinding: Binding<String> {
        Binding(get: { rail ?? "today" }, set: { rail = $0 })
    }

    private func landing(_ front: TasksFront) -> some View {
        var sentence = AttributedString("One thing at a time.")
        sentence.foregroundColor = Theme.Colors.inkSecondary
        return LandingPage(
            back: (title: "Home", action: { dismiss() }),
            title: "Tasks",
            sentence: sentence,
            accent: Theme.Colors.ink,
            lead: { TasksLead(front: front, open: open) },
            doors: [LandingDoor(word: "Today") { rail = "today" },
                    LandingDoor(word: "Soon") { rail = "soon" },
                    LandingDoor(word: "Later") { rail = "later" }],
            action: front.lead.map { lead in
                // No focus mode yet: Do it opens the task's own page.
                LandingAction(word: "Do it", hint: "Opens \(lead.title)") { open(lead) }
            }
        )
    }

    private func open(_ line: TasksFront.Line) {
        model.open(.object(line.id))
        dismiss()
    }
}

/// The lead: the one pick in large words, its first step in ink 2 when Core offers one, then "After that".
private struct TasksLead: View {
    let front: TasksFront
    let open: (TasksFront.Line) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let lead = front.lead {
                TasksSwipeRow(line: lead, onOpen: { open(lead) }) {
                    Text(lead.title)
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let step = front.firstStep {
                    Text("First, two minutes: \(step)")
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Spacing.s)
                }
                if !front.after.isEmpty {
                    Text("After that")
                        .textRole(.data)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, Theme.Spacing.xl)
                    ForEach(front.after) { line in
                        TasksSwipeRow(line: line, onOpen: { open(line) }) {
                            TasksRowText(line: line, carriedOnly: true)
                        }
                    }
                }
            } else {
                Text("Nothing next.")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
            }
        }
    }
}

/// A line's name at the left; at the right, "from Tuesday" (carried, ink 3) or the time (ink 2).
struct TasksRowText: View {
    let line: TasksFront.Line
    /// On the landing only a carried task shows its word; the rail shows the time too.
    var carriedOnly = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let value = carriedOnly && !line.carried ? "" : line.value()
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
        layout {
            Text(line.title)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !value.isEmpty {
                if !typeSize.isAccessibilitySize {
                    Spacer(minLength: Theme.Spacing.s)
                }
                Text(value)
                    .textRole(.data)
                    .foregroundStyle(line.carried ? Theme.Colors.inkTertiary : Theme.Colors.inkSecondary)
                    .multilineTextAlignment(typeSize.isAccessibilitySize ? .leading : .trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// The rail: Now pinned (the pick), the dial's Today, Soon and Later, no knob. "New task" is the foot word.
private struct TasksRail: View {
    let front: TasksFront
    @Binding var open: String
    let back: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        RailPage(
            title: "Tasks",
            subtitle: { _ in "One thing at a time." },
            back: (title: "Tasks", action: back),
            pinned: RailPlace(id: "now", name: "Now", count: front.lines(in: "now").count),
            accent: Theme.Colors.ink,
            places: [place("today", "Today"), place("soon", "Soon"), place("later", "Later")],
            open: $open,
            sectionStyle: .none,
            sections: { [.init(label: nil, rows: front.lines(in: $0))] },
            foot: { _ in "New task" },
            empty: { $0 == "now" ? "Nothing next." : "Nothing here yet." },
            row: row
        )
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    private func place(_ id: String, _ name: String) -> RailPlace {
        RailPlace(id: id, name: name, count: front.lines(in: id).count)
    }

    private func row(_ line: TasksFront.Line) -> some View {
        TasksSwipeRow(line: line, onOpen: {
            model.open(.object(line.id))
            dismiss()
        }) {
            TasksRowText(line: line)
        }
    }
}
