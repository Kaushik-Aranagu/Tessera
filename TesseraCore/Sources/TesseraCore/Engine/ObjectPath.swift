import Foundation

/// The file-system view of an object or class: every segment is a handle the UI can open.
public struct ObjectPath: Hashable, Sendable, CustomStringConvertible {
    public enum Target: Hashable, Sendable {
        case classDef(UUID)
        case object(UUID)
    }

    public struct Segment: Hashable, Sendable {
        public let target: Target
        public let title: String

        public init(target: Target, title: String) {
            self.target = target
            self.title = title
        }

        /// URL-safe, lowercase, hyphenated ("Bench Press" → "bench-press").
        public var slug: String {
            let words = title.lowercased().split { !$0.isLetter && !$0.isNumber }
            return words.isEmpty ? "untitled" : words.joined(separator: "-")
        }
    }

    public var segments: [Segment]

    public init(segments: [Segment]) {
        self.segments = segments
    }

    public var description: String {
        "/" + segments.map(\.slug).joined(separator: "/")
    }

    public func appending(_ segment: Segment) -> ObjectPath {
        ObjectPath(segments: segments + [segment])
    }
}
