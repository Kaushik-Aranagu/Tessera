import SwiftUI
import TesseraCore

/// A plan's routines (docs/design/training-mode.md, "Routines"): Title 44, the context line, one 62 pt row per
/// routine in cycle order. Tap a row to open the routine. Making, reordering and dropping routines and the plan's
/// mode (ROLLS ON / FIXED DAYS) arrive with Core's plan actions.
struct RoutinesPage: View {
    let plan: ObjectRecord
    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let _ = model.revision
        let routines = model.store.linkedObjects("routines", of: plan)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // The back word names the page he came from; no system chevron anywhere (back-word.md).
                Button { dismiss() } label: {
                    Text("‹ Training")
                        .textRole(.label)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityLabel("Back to Training")
                .padding(.bottom, Theme.Spacing.m)
                Text("Routines")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, Theme.Spacing.s)
                    .entrance(0, hero: true)
                Text("\(plan.title), rolls on")
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.bottom, Theme.Spacing.xl)
                    .entrance(1)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(routines) { routine in
                        RoutineRow(routine: routine, isNext: routine.id == next?.id)
                    }
                }
                .entrance(2)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, 180)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .background { ThemedBackground() }
        .toolbarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
        // Hiding the system back button also drops the edge swipe; keep it (QA K1).
        .background { EdgeSwipeBack() }
    }

    private var next: ObjectRecord? {
        model.ledger.nextRoutine(in: plan)
    }
}

/// "Push A" at Body 21/500, under it "5 exercises, about 55 min"; the plan's next routine says so.
private struct RoutineRow: View {
    let routine: ObjectRecord
    var isNext = false
    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        let slots = routine.orderedChildren
        let sets = slots.reduce(0) { $0 + Int(model.store.number("sets", of: $1) ?? 3) }
        Button { model.open(.object(routine.id)) } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(routine.title)
                        .font(Theme.voice(size: 21).weight(.medium))
                        .foregroundStyle(Theme.Colors.ink)
                    Spacer(minLength: Theme.Spacing.s)
                    if isNext {
                        Text("Next")
                            .textRole(.label)
                            .textCase(.uppercase)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    }
                }
                Text(detail(slots: slots.count, sets: sets))
                    .font(Theme.voice(size: 16))
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .modifier(ZoomSource(id: Route.object(routine.id), namespace: namespace))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens \(routine.title)")
    }

    private func detail(slots: Int, sets: Int) -> String {
        guard slots > 0 else { return "no exercises yet" }
        return "\(slots) \(slots == 1 ? "exercise" : "exercises"), \(TrainingPage.about(sets: sets))"
    }
}
