import Foundation

/// Settings > Home > Mosaic (Home 236): one switch per face and "Turn by itself". Kept beside the faces, not in the
/// long
/// list of `ReviewChoices`.
enum MosaicFaceChoices {
    nonisolated static let all: [ReviewChoices.Choice] = [
        ReviewChoices.Choice(id: "homeFace.now", name: "Now face", values: ["On", "Off"], defaultValue: "On",
                             says: ["On": "The mosaic plays the board's latest line as a drawing.",
                                    "Off": "The mosaic never plays the board's line."],
                             readiness: .live),
        ReviewChoices.Choice(id: "homeFace.gallery", name: "Gallery face", values: ["On", "Off"], defaultValue: "On",
                             says: [
                                 "On": "Pixel scenes by the hour, the weather and the place.",
                                 "Off": "No gallery scenes.",
                             ],
                             readiness: .live),
        ReviewChoices.Choice(id: "homeFace.weather", name: "Weather face", values: ["On", "Off"], defaultValue: "On",
                             says: [
                                 "On": "The weather as a scene with its numbers. Sample numbers until a source is allowed.",
                                 "Off": "No weather face.",
                             ],
                             readiness: .live),
        ReviewChoices.Choice(id: "homeFace.workout", name: "Workout face", values: ["On", "Off"], defaultValue: "On",
                             says: ["On": "While you train the mosaic shows the lift and the rest countdown.",
                                    "Off": "The mosaic stays out of your workout."],
                             readiness: .live),
        ReviewChoices.Choice(id: "homeFaceTurn", name: "Turn by itself", values: ["On", "Off"], defaultValue: "On",
                             says: ["On": "The faces turn every few seconds. A touch pauses them for 30 seconds.",
                                    "Off": "The faces turn only when you swipe."],
                             readiness: .live),
    ]
}
