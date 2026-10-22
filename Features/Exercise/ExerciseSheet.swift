import SwiftUI
import TesseraCore

/// What fills the sheet's slots beyond the picture. Empty until the library's content lands (cues, kit drawings and
/// the calorie line come after it); a nil slot draws nothing, so the sheet is the picture and the figure until then.
enum ExerciseSheetContent {
    /// One plain coaching line.
    static func cue(forExerciseNamed _: String) -> String? {
        nil
    }

    /// The name of the kit drawing in the asset catalog for this exercise's equipment.
    static func kitDrawing(forExerciseNamed _: String) -> String? {
        nil
    }

    /// "About 90 kcal for these sets": only ever shown while the Review key caloriesBurned is On (Off by default).
    static func calorieLine(forExerciseNamed _: String) -> String? {
        nil
    }
}

/// The long-press sheet on an exercise: its moving picture, a cue, the kit, the muscle figure and (when the Review
/// switch is on) a calorie line. A private workout's figure is the plain outline, as everywhere.
struct ExerciseSheet: View {
    let exercise: ClassDef
    var isPrivate = false
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let muscles = MuscleReading.muscles(of: exercise, store: model.store)
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text(exercise.name)
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)

                if let picture = ExercisePictures.picture(forExerciseNamed: exercise.name) {
                    PlayingPicture(picture: picture)
                        .frame(maxWidth: .infinity)
                        .frame(height: picture.gifURL == nil ? 240 : 180)
                        .accessibilityHidden(true)
                }
                if let cue = ExerciseSheetContent.cue(forExerciseNamed: exercise.name) {
                    Text(cue)
                        .font(Theme.voice(size: 21))
                        .foregroundStyle(Theme.Colors.context)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let kit = ExerciseSheetContent.kitDrawing(forExerciseNamed: exercise.name) {
                    Image(kit)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(height: 72)
                        .accessibilityHidden(true)
                }
                if !muscles.isEmpty {
                    ExerciseFigures(muscles: muscles, isPrivate: isPrivate)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if Choice.caloriesBurnedIsOn(),
                   let line = ExerciseSheetContent.calorieLine(forExerciseNamed: exercise.name)
                {
                    Text(line)
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.vertical, Theme.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityAction(.escape) { dismiss() }
    }
}

/// The picture's frames in a loop, 1 → 2 → 3 → 2, with a 150 ms cross-fade between frames, drawn in the ink colour.
/// Reduce Motion holds the middle frame still.
struct PlayingPicture: View {
    let picture: ExercisePicture
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    /// Seconds each frame holds.
    static let hold = 0.55
    /// The frame order of one loop: out, the middle, and back.
    static func cycle(frameCount: Int) -> [Int] {
        switch frameCount {
        case ...1: [0]
        case 2: [0, 1]
        default: [0, 1, 2, 1]
        }
    }

    var body: some View {
        if let gif = picture.gifURL {
            // Never drawn past its own 180 points (Gym visual's terms).
            GifView(url: gif, isStill: reduceMotion, isDarkPlate: colorScheme == .dark)
                .frame(maxWidth: 180, maxHeight: 180)
        } else if reduceMotion || picture.frames.count < 2 {
            frames(showing: picture.frames.count > 1 ? 1 : 0)
        } else {
            TimelineView(.periodic(from: .now, by: Self.hold)) { context in
                let cycle = Self.cycle(frameCount: picture.frames.count)
                let step = Int(context.date.timeIntervalSinceReferenceDate / Self.hold) % cycle.count
                frames(showing: cycle[step])
                    .tesseraAnimation(.easeInOut(duration: 0.15), value: cycle[step])
            }
        }
    }

    private func frames(showing index: Int) -> some View {
        ZStack {
            ForEach(picture.frames.indices, id: \.self) { frame in
                Image(picture.frames[frame])
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Theme.Colors.ink)
                    .opacity(frame == index ? 1 : 0)
            }
        }
    }
}

/// Long press on an exercise opens its sheet; VoiceOver gets the same as a named action.
struct ExerciseSheetModifier: ViewModifier {
    let exercise: ClassDef?
    let isPrivate: Bool
    @State private var presented = false
    @State private var haptic = 0

    func body(content: Content) -> some View {
        if let exercise {
            content
                .highPriorityGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                    haptic += 1
                    presented = true
                })
                .accessibilityAction(named: "Show \(exercise.name)") { presented = true }
                .tesseraFeedback(.selection, trigger: haptic)
                .sheet(isPresented: $presented) {
                    ExerciseSheet(exercise: exercise, isPrivate: isPrivate)
                }
        } else {
            content
        }
    }
}

extension View {
    /// Long press on this opens the exercise's sheet (picture, cue, kit, figure).
    func exerciseSheet(_ exercise: ClassDef?, isPrivate: Bool = false) -> some View {
        modifier(ExerciseSheetModifier(exercise: exercise, isPrivate: isPrivate))
    }
}
