import Foundation
@testable import Tessera
import TesseraCore
import Testing
import UIKit

/// The long-press sheet's pictures: Workout Guide's frames cover every seeded exercise, siblings are marked and the
/// source is swappable.
@MainActor
struct ExercisePicturesTests {
    @Test func everySeededExerciseHasAPictureFromTheBundledSet() {
        for seed in ExerciseLibrary.seeds {
            let picture = WorkoutGuideSource().picture(forExerciseNamed: seed.name)
            #expect(picture != nil, "\(seed.name) has no picture")
            #expect(picture?.frames.count == 3, "\(seed.name) should have three frames")
            #expect(picture?.source == "Workout Guide")
        }
    }

    @Test func seventyOnePicturesServeTheSeventyTwoExercises() {
        let slugs = Set(WorkoutGuideSource.slugs.values.map(\.slug))
        #expect(ExerciseLibrary.seeds.count == WorkoutGuideSource.slugs.count)
        #expect(slugs.count == WorkoutGuideSource.slugs.count - 1)
        #expect(WorkoutGuideSource.slugs["Barbell Curl"]?.slug == WorkoutGuideSource.slugs["Dumbbell Curl"]?.slug)
    }

    @Test func siblingsAreMarkedAndExactMatchesAreNot() {
        let guide = WorkoutGuideSource()
        #expect(guide.picture(forExerciseNamed: "Bench Press")?.isSibling == false)
        #expect(guide.picture(forExerciseNamed: "Back Squat")?.isSibling == true)
        #expect(ExercisePictures.picture(forExerciseNamed: "Not An Exercise") == nil)
    }

    @Test func aRicherSourceGoesInFrontAndTheRestFallBack() {
        struct Fixed: ExercisePictureSource {
            let name = "Fixed"
            func picture(forExerciseNamed name: String) -> ExercisePicture? {
                name == "Bench Press" ? ExercisePicture(frames: ["x"], source: "Fixed") : nil
            }
        }
        let original = ExercisePictures.sources
        defer { ExercisePictures.sources = original }
        ExercisePictures.sources = [Fixed(), WorkoutGuideSource()]
        #expect(ExercisePictures.picture(forExerciseNamed: "Bench Press")?.source == "Fixed")
        #expect(ExercisePictures.picture(forExerciseNamed: "Deadlift")?.source == "Workout Guide")
    }

    @Test func theGymVisualSetNamesOnlySeededExercisesAndEveryOneBundledHasItsFile() {
        let seeded = Set(ExerciseLibrary.seeds.map(\.name))
        #expect(GymVisualSource.files.keys.allSatisfy { seeded.contains($0) })
        #expect(GymVisualSource.files.count == 71)
        // The files are git-ignored: a build without the folder falls back to Workout Guide for every exercise.
        let source = GymVisualSource()
        for name in GymVisualSource.files.keys {
            if let picture = source.picture(forExerciseNamed: name) {
                #expect(picture.gifURL != nil && picture.source == "Gym visual")
            }
        }
        #expect(ExerciseCredits.gymVisualLine == "(c) Gym visual - https://gymvisual.com/")
    }

    @Test func theFramesLoopOutAndBack() {
        #expect(PlayingPicture.cycle(frameCount: 3) == [0, 1, 2, 1])
        #expect(PlayingPicture.cycle(frameCount: 2) == [0, 1])
        #expect(PlayingPicture.cycle(frameCount: 1) == [0])
    }

    @Test func theCreditNamesBothSourcesTheLicenceAndTheChanges() {
        let line = ExerciseCredits.line
        #expect(line.contains("Workout Guide") && line.contains("Bryl Lim") && line.contains("Everkinetic"))
        #expect(line.contains("CC BY-SA 4.0") && line.contains("recolored and resized"))
    }

    @Test func theCalorieLineIsOffUntilTheSwitchIsOn() throws {
        let defaults = try #require(UserDefaults(suiteName: "ExercisePicturesTests"))
        defaults.removePersistentDomain(forName: "ExercisePicturesTests")
        #expect(!Choice.caloriesBurnedIsOn(defaults: defaults))
        defaults.set("On", forKey: "review.caloriesBurned")
        #expect(Choice.caloriesBurnedIsOn(defaults: defaults))
        defaults.removePersistentDomain(forName: "ExercisePicturesTests")
    }
}
