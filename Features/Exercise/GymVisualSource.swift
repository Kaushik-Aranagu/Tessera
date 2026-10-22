import ImageIO
import SwiftUI
import UIKit

/// Gym visual's moving pictures (180 x 180 GIFs), bundled at build time from the git-ignored `Resources/ExerciseGifs/`
/// folder (docs/research/reference-library/gif-set-plan.md). Never committed, never fetched, never sent anywhere.
/// A build without the folder has no GIFs, so every exercise falls through to the Workout Guide frames.
struct GymVisualSource: ExercisePictureSource {
    let name = "Gym visual"

    /// Our exercise name → GIF file name (without the extension) and whether it is a sibling motion.
    static let files: [String: (file: String, sibling: Bool)] = [
        "Bench Press": ("0025-EIeI8Vf", false),
        "Incline Bench Press": ("0047-3TZduzM", false),
        "Close-Grip Bench Press": ("0030-J6Dx1Mu", false),
        "Dumbbell Bench Press": ("0289-SpYC0Kp", false),
        "Incline Dumbbell Press": ("0314-ns0SIbU", false),
        "Machine Chest Press": ("0576-DOoWcnA", false),
        "Push-Up": ("0662-I4hDWkc", false),
        "Dip": ("0251-9WTm7dq", false),
        "Cable Fly": ("0188-xLYSdtg", true),
        "Pec Deck": ("0596-v3xmPAR", false),
        "Overhead Press": ("0091-kTbSH9h", true),
        "Seated Dumbbell Shoulder Press": ("0405-znQUdHY", false),
        "Machine Shoulder Press": ("0603-67n3r98", false),
        "Dumbbell Lateral Raise": ("0334-DsgkuIt", false),
        "Cable Lateral Raise": ("0178-goJ6ezq", false),
        "Barbell Row": ("0027-eZyBC3j", false),
        "One-Arm Dumbbell Row": ("0292-C0MA9bC", false),
        "Seated Cable Row": ("0861-fUBheHs", false),
        "Chest-Supported Row": ("0574-X3cqyXz", true),
        "T-Bar Row": ("0606-aaXr7ld", false),
        "Reverse Pec Deck": ("0602-myfUsKf", false),
        "Pull-Up": ("0652-lBDjFxJ", false),
        "Chin-Up": ("1326-T2mxWqc", false),
        "Assisted Pull-Up": ("0017-kiJ4Z2K", false),
        "Lat Pulldown": ("2330-LEprlgG", false),
        "Close-Grip Pulldown": ("0818-rkg41Fb", true),
        "Straight-Arm Pulldown": ("0238-x69MAlq", false),
        "Back Squat": ("0043-qXTaZnJ", false),
        "Front Squat": ("0042-zG0zs85", false),
        "Goblet Squat": ("1760-yn8yg1r", false),
        "Hack Squat": ("0743-Qa55kX1", false),
        "Leg Press": ("1463-2Qh2J1e", false),
        "Smith Machine Squat": ("0770-jFtipLl", false),
        "Bulgarian Split Squat": ("0410-qx4fgX7", true),
        "Walking Lunge": ("1460-IZVHb27", false),
        "Reverse Lunge": ("0078-VaP75jl", true),
        "Step-Up": ("0431-aXtJhlg", false),
        "Deadlift": ("0032-ila4NZS", false),
        "Sumo Deadlift": ("0117-KgI0tqW", false),
        "Romanian Deadlift": ("0085-wQ2c4XD", false),
        "Dumbbell Romanian Deadlift": ("1459-rR0LJzx", false),
        "Good Morning": ("0044-XlZ4lAC", false),
        "Kettlebell Swing": ("0549-UHJlbu3", false),
        "Hip Thrust": ("1409-qKBpF7I", true),
        "Back Extension": ("0573-rUXfn3R", false),
        "Cable Pull-Through": ("0196-OM46QHm", false),
        "Leg Extension": ("0585-my33uHU", false),
        "Lying Leg Curl": ("0586-17lJ1kr", false),
        "Seated Leg Curl": ("0599-Zg3XY7P", false),
        "Hip Adduction": ("0598-oHsrypV", false),
        "Hip Abduction": ("0597-CHpahtl", false),
        "Standing Calf Raise": ("1372-8ozhUIZ", true),
        "Seated Calf Raise": ("1371-ipvgBnC", true),
        "Barbell Curl": ("0031-25GPyDY", false),
        "Dumbbell Curl": ("0294-NbVPDMW", false),
        "Hammer Curl": ("0313-slDvUAU", false),
        "Incline Dumbbell Curl": ("0318-ae9UoXQ", false),
        "Preacher Curl": ("0070-qOgPVf6", false),
        "Cable Curl": ("0868-G08RZcQ", false),
        "Rope Pushdown": ("0200-dU605di", false),
        "Overhead Cable Extension": ("0194-2IxROQ1", false),
        "Skull Crusher": ("0060-h8LFzo9", false),
        "Dumbbell Overhead Extension": ("1738-5fKX7wi", true),
        "Barbell Shrug": ("0095-dG7tG5y", false),
        "Dumbbell Shrug": ("0406-NJzBsGJ", false),
        "Plank": ("2135-VBAWRPG", true),
        "Ab Wheel Rollout": ("0857-NAgVB3t", false),
        "Hanging Leg Raise": ("0472-I3tsCnC", false),
        "Cable Crunch": ("0175-WW95auq", false),
        "Pallof Press": ("0979-9pa4H5m", true),
        "Farmer's Carry": ("2133-qPEzJjA", false),
    ]

    func picture(forExerciseNamed name: String) -> ExercisePicture? {
        guard let entry = Self.files[name],
              let url = Bundle.main.url(forResource: entry.file, withExtension: "gif") else { return nil }
        return ExercisePicture(frames: [], source: self.name, isSibling: entry.sibling, gifURL: url)
    }
}

/// An animated GIF drawn at its own size or smaller (the terms forbid upscaling past 180 points). Reduce Motion
/// shows the middle frame still.
struct GifView: UIViewRepresentable {
    let url: URL
    let isStill: Bool

    func makeUIView(context _: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ view: UIImageView, context _: Context) {
        let loaded = Self.frames(at: url)
        if isStill {
            view.stopAnimating()
            view.animationImages = nil
            view.image = loaded.images.isEmpty ? nil : loaded.images[loaded.images.count / 2]
        } else {
            view.image = loaded.images.first
            view.animationImages = loaded.images
            view.animationDuration = loaded.duration
            view.startAnimating()
        }
    }

    /// Decoded once per file and kept: 71 GIFs at 180 x 180 are small.
    private static func frames(at url: URL) -> (images: [UIImage], duration: TimeInterval) {
        if let cached = cache.object(forKey: url as NSURL) {
            return (cached.images, cached.duration)
        }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return ([], 1) }
        var images: [UIImage] = []
        var duration = 0.0
        for index in 0 ..< CGImageSourceGetCount(source) {
            guard let image = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            images.append(UIImage(cgImage: image))
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            duration += (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
                ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double) ?? 0.1
        }
        cache.setObject(GifFrames(images: images, duration: max(duration, 0.1)), forKey: url as NSURL)
        return (images, max(duration, 0.1))
    }

    private final class GifFrames {
        let images: [UIImage]
        let duration: TimeInterval
        init(images: [UIImage], duration: TimeInterval) {
            self.images = images
            self.duration = duration
        }
    }

    private static let cache = NSCache<NSURL, GifFrames>()
}
