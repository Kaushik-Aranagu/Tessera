import Foundation

/// The launch notes as a queue (G694, hunt 28 CALL 3 B): every note that waited for this launch is read, oldest
/// first, one line at a time in Tess's slot, each shown once. Nothing stacks: the next note takes the slot only when
/// the one before is let go (he opens the Ask bar).
struct LaunchNoteQueue: Equatable {
    private(set) var notes: [String] = []

    init(_ notes: [String?] = []) {
        for note in notes {
            enqueue(note)
        }
    }

    /// The one line showing now.
    var current: String? {
        notes.first
    }

    /// Adds a note at the back. Empty notes and a note already waiting are dropped, so the same words never show
    /// twice in one launch.
    mutating func enqueue(_ note: String?) {
        guard let note = note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty,
              !notes.contains(note) else { return }
        notes.append(note)
    }

    /// The current note was read: the next one, if any, takes the slot.
    mutating func advance() {
        if !notes.isEmpty {
            notes.removeFirst()
        }
    }
}
