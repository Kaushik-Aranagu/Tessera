import SwiftUI
import TesseraCore

/// An exercise as an object (docs/design/exercise-page.md): path, the name, what it works, best e1RM and best set,
/// a painted 90-day trend, then three sibling views of the same object on x (HISTORY · REP MAXES · MUSCLES) in one
/// bounded window, the methods, and Tess's forward line. One screen tall; only the window scrolls.
struct ExercisePage: View {
    let exercise: ClassDef

    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.animateEntrance) private var animateEntrance

    var body: some View {
        let _ = model.revision
        let digest = ExerciseDigest(exercise: exercise, ledger: model.ledger, store: model.store, now: AppClock.now)
        Group {
            if typeSize.isAccessibilitySize {
                // Reflow wins over one-screen at accessibility sizes: the page scrolls, the window grows.
                ScrollView(.vertical) { content(digest, windowHeight: 360) }
                    .scrollIndicators(.hidden)
            } else {
                content(digest, windowHeight: nil)
            }
        }
        .background { ThemedBackground() }
        .toolbarTitleDisplayMode(.inline)
    }

    private func content(_ digest: ExerciseDigest, windowHeight: CGFloat?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ExerciseHeader(digest: digest)
                .padding(.bottom, Theme.Spacing.l)

            ExerciseSummary(digest: digest, isPrivate: MuscleReading.openedFromPrivate(model))
                .entrance(3)
                .padding(.bottom, Theme.Spacing.l)

            if let trend = digest.trend {
                TrendStrip(trend: trend, animate: animateEntrance)
                    .entrance(4)
                    .padding(.bottom, Theme.Spacing.l)
            }

            ExerciseViews(digest: digest)
                .frame(minHeight: 140, maxHeight: windowHeight ?? 236)
                .layoutPriority(-1)
                .entrance(5)

            Spacer(minLength: Theme.Spacing.s)

            if let line = digest.nextTime {
                Text(line)
                    .font(PageType.voice)
                    .foregroundStyle(Theme.Colors.tess)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, Theme.Spacing.m)
                    .accessibilityLabel("Tess: \(line)")
            }

            ExerciseMethods(exercise: exercise)
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .padding(.top, Theme.Spacing.xs)
        // The dock (Ask Tess) floats over pushed pages too.
        .padding(.bottom, HomeSpatialView.dockClearance)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Header

private struct ExerciseHeader: View {
    let digest: ExerciseDigest
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !digest.path.isEmpty {
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(Array(digest.path.enumerated()), id: \.element.id) { index, part in
                        if index > 0 {
                            Text("›").textRole(.label).foregroundStyle(Theme.Colors.muted)
                                .accessibilityHidden(true)
                        }
                        Button { model.open(.classDef(part.id), .up) } label: {
                            Text(part.title)
                                .textRole(.label)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                                .lineLimit(1)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(HandleButtonStyle())
                        .accessibilityHint("Goes up to \(part.title)")
                    }
                }
                .padding(.bottom, -Theme.Spacing.xs)
                .entrance(0)
            }

            HeroText(text: digest.name) { $0 }
                .foregroundStyle(Theme.Colors.ink)
                .accessibilityAddTraits(.isHeader)
                .arrivesFromRight()
                .padding(.bottom, Theme.Spacing.s)

            if let context = digest.context {
                Text(context)
                    .font(PageType.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Works \(context)")
                    .entrance(2)
            }
        }
    }
}

// MARK: - Summary

private struct ExerciseSummary: View {
    let digest: ExerciseDigest
    /// Opened from a private workout or routine: the figures draw the plain outline.
    var isPrivate = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if digest.bestSet == nil {
            // Zero history: one plain line instead of two empty numbers.
            Text("No best yet. The first logged set sets one.")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            stats
                .frame(maxWidth: .infinity, alignment: .leading)
                // The pair of figures stands beside the two numbers (Design brief 1): 100 pt tall, the back one at the
                // right edge, drawn a little into the gutter, and hidden from VoiceOver.
                .overlay(alignment: .topTrailing) {
                    if !typeSize.isAccessibilitySize {
                        ExerciseFigures(muscles: digest.muscles.map { (name: $0.name, role: MuscleRole($0.role)) },
                                        isPrivate: isPrivate)
                            .offset(x: 20, y: -16)
                    }
                }
        }
    }

    private var stats: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.m))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 0))
        return layout {
            // An empty value drops out; no lone dash (decisions 5:57).
            if let best = digest.bestE1RM {
                stat(Format.kilograms(best), label: "Best e1RM, kg",
                     spoken: "Best estimated one-rep max, \(Format.kilograms(best)) kilograms")
                    // The second number starts at x 152 (the first at 24); its label wraps rather than touch the next
                    // one.
                    .frame(width: typeSize.isAccessibilitySize || digest.bestSet == nil ? nil : 120)
            }
            if let set = digest.bestSet {
                stat(set, label: "Best set", spoken: "Best set, \(set.replacingOccurrences(of: "×", with: "by"))")
                    // Stays clear of the figures at the right (they begin at x 296; this starts at x 152).
                    .frame(width: typeSize.isAccessibilitySize || digest.bestE1RM == nil ? nil : 136)
                    .padding(.leading, typeSize.isAccessibilitySize || digest.bestE1RM == nil ? 0 : 8)
            }
        }
    }

    private func stat(_ value: String, label: String, spoken: String?) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(value)
                .font(Theme.numeral(44))
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                // One height whether or not the numeral shrank, so both labels sit on one line.
                .frame(height: 54, alignment: .leading)
            Text(label).textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken ?? "\(label), none yet")
    }
}

/// The front and back figures for an exercise's muscles, 100 pt tall, in the Training colour (an exercise is not in a
/// routine). Info only: hidden from VoiceOver, the rows say the same.
struct ExerciseFigures: View {
    let muscles: [(name: String, role: MuscleRole)]
    var tint: Color = Theme.Colors.training
    /// Opened from a private workout or routine: nothing is lit.
    var isPrivate = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach([false, true], id: \.self) { back in
                MuscleFigure(back: back,
                             roles: MuscleFigureMap.roles(MuscleReading.lit(muscles, isPrivate: isPrivate), back: back),
                             tint: tint,
                             lineOpacity: 0.45, lineWidth: 2.2)
                    .frame(height: 100)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Trend

private struct TrendStrip: View {
    let trend: ExerciseDigest.Trend
    let animate: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            PaintedTrend(points: trend.points, animate: animate)
                .frame(height: 56)
            HStack {
                Text(trend.span).textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                Spacer(minLength: Theme.Spacing.m)
                if let change = trend.change {
                    Text(change).textRole(.label)
                        .foregroundStyle(trend.isRise ? Theme.Colors.tess : Theme.Colors.inkSecondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Estimated one-rep max over \(trend.span)" + (trend.change.map { ", \($0)" } ?? ""))
    }
}

// MARK: - Methods

private struct ExerciseMethods: View {
    let exercise: ClassDef
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var added = 0

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.m))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Theme.Spacing.l))
        layout {
            PaintKey(isTap: true, height: 64, action: logASet) { _ in
                Text("Log a set")
            }

            addToRoutine
        }
        .tesseraFeedback(.made, trigger: added)
    }

    /// Logging goes through the command bar, prefilled with the exercise (Tess parses "log bench press 82.5×8").
    private func logASet() {
        model.commandDraft = "log \(exercise.name.lowercased()) "
        withTesseraAnimation(reduceMotion: reduceMotion) { model.isCommandExpanded = true }
    }

    @ViewBuilder private var addToRoutine: some View {
        let routines = model.objects(of: .routine)
        Menu {
            ForEach(routines) { routine in
                Button(routine.title) { add(to: routine) }
            }
            Button("Ask Tess for a new routine") {
                model.commandDraft = "add \(exercise.name.lowercased()) to a new routine "
                withTesseraAnimation(reduceMotion: reduceMotion) { model.isCommandExpanded = true }
            }
        } label: {
            Text("Add to routine")
                .textRole(.bodyStrong)
                .foregroundStyle(Theme.Colors.ink)
                .frame(minHeight: 56)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityHint("Adds \(exercise.name) to one of your routines")
    }

    private func add(to routine: ObjectRecord) {
        guard (try? model.engine.perform(AddSlot(routine: routine.id, exercise: exercise.id), by: .user)) != nil
        else { return }
        added += 1
        model.touch()
    }
}
