import SwiftUI
import TesseraCore

/// An exercise as one plain page (docs/design/training-app-124.md, sheets 124 and 125): the name and what it works with
/// its best, the Gym visual, the best set with "about N kg for 1", the climb (sessions down the page, weight across),
/// the exercise's notes, Similar, and the two keys. Not a rail: the data here is one long list, so it scrolls.
struct ExercisePage: View {
    let exercise: ClassDef

    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pageBackTitle) private var backTitle
    @State private var isSimilarOpen = false

    var body: some View {
        let _ = model.revision
        let digest = ExerciseDigest(exercise: exercise, ledger: model.ledger, store: model.store, now: AppClock.now)
        ScrollView(.vertical) {
            content(digest)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if TrainingV3.isOn {
                DoItNowFoot(exercise: exercise)
            }
        }
        .background { ThemedBackground() }
        .toolbarTitleDisplayMode(.inline)
        // The plain back word, not the round glass button (Design on #1219); the edge swipe stays.
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .background { EdgeSwipeBack() }
        .sheet(isPresented: $isSimilarOpen) {
            SimilarExercisesSheet(exercise: exercise)
        }
    }

    /// "Similar, 4 to try", or just "Similar" when nothing is close.
    private var similarWord: String {
        let count = ExerciseSwaps(store: model.store, ledger: model.ledger)
            .options(for: exercise, from: 0, excludingWorkout: nil).count
        return count > 0 ? "Similar, \(count) to try" : "Similar"
    }

    private func content(_ digest: ExerciseDigest) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            BackWord(title: backTitle) { dismiss() }
            ExerciseHeader(digest: digest)
                .padding(.bottom, Theme.Spacing.l)

            if let picture = ExercisePictures.picture(forExerciseNamed: exercise.name) {
                PlayingPicture(picture: picture)
                    .frame(maxWidth: .infinity)
                    .frame(height: picture.gifURL == nil ? 200 : 180)
                    .accessibilityHidden(true)
                    .entrance(2)
                    .padding(.bottom, Theme.Spacing.l)
            }

            if TrainingV3.isOn {
                LiftSetsBlock(exercise: exercise)
            }

            ExerciseBest(digest: digest)
                .entrance(3)
                .padding(.bottom, Theme.Spacing.xl)

            if !digest.climb.isEmpty {
                TheClimb(sessions: digest.climb, total: digest.sessionCount)
                    .padding(.bottom, Theme.Spacing.xl)
            }

            if let notes = digest.notes {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Notes").textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                    Text(notes)
                        .font(Theme.voice(size: 21))
                        .foregroundStyle(Theme.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .padding(.bottom, Theme.Spacing.xl)
            }

            // A door, not a label: ink, with how many there are to try.
            Button { isSimilarOpen = true } label: {
                Text(similarWord)
                    .textRole(.keyWord)
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityHint("Shows exercises close to \(exercise.name)")
            .padding(.bottom, Theme.Spacing.l)

            if let line = digest.nextLine {
                Text(line)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, Theme.Spacing.m)
            }

            ExerciseMethods(exercise: exercise)
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .padding(.top, Theme.Spacing.xs)
        // The dock (Ask Tess) floats over pushed pages too.
        .padding(.bottom, HomeSpatialView.dockClearance)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

/// "Best set 85 × 5. About 104 kg for 1." in words, or the first-time line.
private struct ExerciseBest: View {
    let digest: ExerciseDigest

    var body: some View {
        Text(line)
            .font(Theme.voice(size: 21))
            .foregroundStyle(Theme.Colors.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var line: String {
        ExerciseWords.bestLine(bestSet: digest.bestSet, aboutKilograms: digest.aboutOneRep)
    }
}

// MARK: - Header

private struct ExerciseHeader: View {
    let digest: ExerciseDigest
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(digest.name)
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .arrivesFromRight()
                .padding(.bottom, Theme.Spacing.s)

            if let subtitle = digest.subtitle {
                Text(subtitle)
                    .font(PageType.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(subtitle)
                    .entrance(2)
            }
        }
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
                Text("Log a set").textRole(.keyWord)
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
                .textRole(.keyWord)
                .foregroundStyle(Theme.Colors.inkSecondary)
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
