import Foundation
import UIKit

/// A moving picture of an exercise: a few frames played in order. The source is swappable (`ExercisePictureSource`):
/// the first source that has the exercise wins, so a richer set can be put in front of this one later and the rest
/// fall back to the bundled Workout Guide frames.
struct ExercisePicture: Equatable {
    /// Asset names of the frames, in playing order.
    let frames: [String]
    /// Which source drew it ("Workout Guide").
    let source: String
    /// A sibling (a near-identical motion with the same muscles), not the exercise's own picture.
    var isSibling = false
}

protocol ExercisePictureSource {
    var name: String { get }
    func picture(forExerciseNamed name: String) -> ExercisePicture?
}

/// Workout Guide by Bryl Lim (CC BY-SA 4.0), bundled as vector frames in ExercisePictures.xcassets: three frames per
/// exercise, white lines drawn as template images so they take the ink colour. 71 pictures cover our 72 exercises
/// (Barbell and Dumbbell Curl share one). Credit: see `ExerciseCredits`.
struct WorkoutGuideSource: ExercisePictureSource {
    let name = "Workout Guide"

    /// Our exercise name → Workout Guide slug and whether it is a sibling motion (docs/research/reference-library/
    /// workout-guide-asset-plan.md).
    static let slugs: [String: (slug: String, sibling: Bool)] = [
        "Bench Press": ("bench-press", false), "Incline Bench Press": ("incline-bench-press", false),
        "Close-Grip Bench Press": ("close-grip-bench-press", false),
        "Dumbbell Bench Press": ("dumbbell-bench-press", false),
        "Incline Dumbbell Press": ("incline-dumbbell-press", false),
        "Machine Chest Press": ("machine-chest-press", false), "Push-Up": ("push-up", false), "Dip": ("dip", false),
        "Cable Fly": ("cable-fly", false), "Pec Deck": ("pec-deck", false),
        "Overhead Press": ("overhead-press", false),
        "Seated Dumbbell Shoulder Press": ("seated-dumbbell-press", true),
        "Machine Shoulder Press": ("machine-shoulder-press", false),
        "Dumbbell Lateral Raise": ("lateral-raise", true), "Cable Lateral Raise": ("cable-lateral-raise", false),
        "Barbell Row": ("barbell-row", false), "One-Arm Dumbbell Row": ("one-arm-dumbbell-row", false),
        "Seated Cable Row": ("seated-row", true), "Chest-Supported Row": ("chest-supported-row", false),
        "T-Bar Row": ("t-bar-row", false), "Face Pull": ("face-pull", false),
        "Reverse Pec Deck": ("reverse-pec-deck", false), "Pull-Up": ("pull-up", false),
        "Chin-Up": ("chin-up", false), "Assisted Pull-Up": ("assisted-pull-up", false),
        "Lat Pulldown": ("lat-pulldown", false), "Close-Grip Pulldown": ("close-grip-lat-pulldown", true),
        "Straight-Arm Pulldown": ("straight-arm-pulldown", false), "Back Squat": ("squat", true),
        "Front Squat": ("front-squat", false), "Goblet Squat": ("goblet-squat", false),
        "Hack Squat": ("hack-squat", false), "Leg Press": ("leg-press", false),
        "Smith Machine Squat": ("smith-machine-squat", false),
        "Bulgarian Split Squat": ("bulgarian-split-squat", false), "Walking Lunge": ("walking-lunge", false),
        "Reverse Lunge": ("reverse-lunge", false), "Step-Up": ("step-up", false), "Deadlift": ("deadlift", false),
        "Sumo Deadlift": ("sumo-deadlift", false), "Romanian Deadlift": ("romanian-deadlift", false),
        "Dumbbell Romanian Deadlift": ("dumbbell-romanian-deadlift", false),
        "Good Morning": ("good-morning", false), "Kettlebell Swing": ("kettlebell-swing", false),
        "Hip Thrust": ("hip-thrust", false), "Back Extension": ("back-extension", false),
        "Cable Pull-Through": ("cable-pull-through", false), "Leg Extension": ("leg-extension", false),
        "Lying Leg Curl": ("lying-leg-curl", false), "Seated Leg Curl": ("seated-leg-curl", false),
        "Hip Adduction": ("hip-adduction-machine", true), "Hip Abduction": ("hip-abduction-machine", true),
        "Standing Calf Raise": ("standing-calf-raise", false), "Seated Calf Raise": ("seated-calf-raise", false),
        "Barbell Curl": ("bicep-curl", true), "Dumbbell Curl": ("bicep-curl", true),
        "Hammer Curl": ("hammer-curl", false), "Incline Dumbbell Curl": ("incline-dumbbell-curl", false),
        "Preacher Curl": ("preacher-curl", false), "Cable Curl": ("cable-curl", false),
        "Rope Pushdown": ("rope-tricep-pushdown", true), "Overhead Cable Extension": (
            "overhead-tricep-extension",
            true
        ),
        "Skull Crusher": ("skull-crusher", false),
        "Dumbbell Overhead Extension": ("dumbbell-overhead-tricep-extension", true),
        "Barbell Shrug": ("shrug", true), "Dumbbell Shrug": ("dumbbell-shrug", false), "Plank": ("plank", false),
        "Ab Wheel Rollout": ("ab-wheel", true), "Hanging Leg Raise": ("hanging-leg-raise", false),
        "Cable Crunch": ("cable-crunch", false), "Pallof Press": ("pallof-press", false),
        "Farmer's Carry": ("farmer-carry", true),
    ]

    func picture(forExerciseNamed name: String) -> ExercisePicture? {
        guard let entry = Self.slugs[name] else { return nil }
        let frames = (1 ... 3).map { "wg-\(entry.slug)-\($0)" }.filter { UIImage(named: $0) != nil }
        guard !frames.isEmpty else { return nil }
        return ExercisePicture(frames: frames, source: self.name, isSibling: entry.sibling)
    }
}

/// The pictures the app plays, first match wins. A richer set goes in front of Workout Guide when it is approved.
enum ExercisePictures {
    nonisolated(unsafe) static var sources: [any ExercisePictureSource] = [WorkoutGuideSource()]

    static func picture(forExerciseNamed name: String) -> ExercisePicture? {
        for source in sources {
            if let picture = source.picture(forExerciseNamed: name) {
                return picture
            }
        }
        return nil
    }
}

/// The About page's picture credit, one plain line (Product's ruling): the source's licence, the upstream art's
/// licence and what was changed here.
enum ExerciseCredits {
    static let line = "Exercise pictures: Workout Guide by Bryl Lim (bryllim.com), CC BY-SA 4.0. Artwork by "
        + "Everkinetic / Greg Priday, CC BY-SA 4.0. Changes: recolored and resized."
    static let licenseURL = URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!
    static let sourceURL = URL(string: "https://github.com/bryllim/workout-guide")!
    static let upstreamURL = URL(string: "https://github.com/everkinetic/data")!
}
