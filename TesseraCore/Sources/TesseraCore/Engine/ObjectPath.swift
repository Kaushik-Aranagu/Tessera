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

@MainActor
public extension ObjectStore {
    // MARK: Paths

    /// The class path, then the composition chain: `/activity/workout/push-day-a/bench-press/set-2`.
    /// Untitled objects are named after a linked class (an entry → "Bench Press") or their class and position.
    func path(of object: ObjectRecord) -> ObjectPath {
        var chain: [ObjectRecord] = []
        var seen = Set<UUID>()
        var current: ObjectRecord? = object
        while let node = current, seen.insert(node.id).inserted {
            chain.append(node)
            current = node.parent
        }
        chain.reverse()
        var path = chain.first?.classDef.map(ClassResolver.path(of:)) ?? ObjectPath(segments: [])
        for node in chain where !node.isClassObject {
            path = path.appending(.init(target: .object(node.id), title: displayTitle(of: node)))
        }
        return path
    }

    /// The title anything he reads shows: a workout's or routine's private title reads "Private workout" (Product:
    /// mask at the source). The op log, the editor's text field and the engine's walls use `rawTitle(of:)`.
    func displayTitle(of object: ObjectRecord) -> String {
        let title = rawTitle(of: object)
        if isWorkoutOrRoutine(object) { return ObjectPrivacy.routineTitle(title, in: self) }
        if isA(.list, object) { return ListContents.shownName(of: object, in: self) }
        return title
    }

    private func isA(_ key: SystemCatalog.Key, _ object: ObjectRecord) -> Bool {
        guard let classDef = object.classDef else { return false }
        return lineage(of: classDef).contains { $0.systemKey == key.systemKey }
    }

    private func isWorkoutOrRoutine(_ object: ObjectRecord) -> Bool {
        isA(.workout, object) || isA(.routine, object)
    }

    /// The object's title as stored, or a stand-in for untitled objects such as sets and entries.
    func rawTitle(of object: ObjectRecord) -> String {
        if !object.title.isEmpty {
            return object.title
        }
        let linkedClass = (object.outgoingLinks ?? []).compactMap(\.toClass).first
        if let linkedClass {
            return linkedClass.name
        }
        let className = object.classDef?.name ?? "Object"
        guard let siblings = object.parent?.orderedChildren,
              let index = siblings.firstIndex(where: { $0.id == object.id }) else { return className }
        return "\(className) \(index + 1)"
    }
}
