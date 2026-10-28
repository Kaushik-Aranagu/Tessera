import Foundation

// One lifecycle (r1-spec section 9, sheets 358 to 373): every change Tess makes to a room, and the room itself, move
// through these states and no others. Pure: a state and an event give the next state, or nil when the arrow is not in
// the spec's tables (so nothing has an unlisted exit). `ChartRoomModel` holds both and routes every flow through here.

/// A change: one op group from one sentence.
enum ChangeState: String, CaseIterable, Sendable {
    /// Nothing in flight.
    case idle
    /// His words in his line, the parts in ghost, the drying line running (2 s).
    case staged
    /// Touched while staged: the line holds, runs back, the ghost lets go. Nothing was written.
    case stopped
    /// Waiting for Allow: the wine reach line with Allow; nothing it asks for can happen yet.
    case waiting
    /// Full ink, the outline let go, a receipt with Undo.
    case set
    /// The ghost is back and the line runs back right to left; the group is undone when it reaches 0.
    case undried
    /// A validator refused: Tess says why and offers what the rules allow. Nothing changed.
    case refused
    /// A part the kit does not have yet: the receipt names the next install. Nothing changed now.
    case queued
}

enum ChangeEvent: Equatable, Sendable {
    /// A sentence arrives.
    case sentence
    /// The drying line reached its end; `needsAllow` is the validator's answer.
    case lineEnded(needsAllow: Bool)
    /// A new sentence arrives while one is still drying: the line runs to its end in 160 ms and it sets.
    case newSentence
    /// A touch on his own words, or "wait"/"stop".
    case touchWords
    /// The stop's run-back finished.
    case stopEnded
    case allow
    case notNow
    case undo
    /// The un-drying line reached 0.
    case unDryEnded
    case refuse
    case queue
    /// The refusal or the queue notice went away (or the install landed).
    case settled
}

enum Lifecycle {
    static func next(_ state: ChangeState, _ event: ChangeEvent) -> ChangeState? {
        switch (state, event) {
        // A sentence starts a change from any resting state; a waiting change is left waiting (Allow can come later).
        case (.idle, .sentence), (.set, .sentence), (.refused, .sentence), (.queued, .sentence): .staged
        case (.waiting, .sentence): .waiting
        case (.idle, .refuse), (.set, .refuse), (.refused, .refuse), (.queued, .refuse): .refused
        case (.idle, .queue), (.set, .queue), (.refused, .queue), (.queued, .queue): .queued
        case (.refused, .settled), (.queued, .settled): .idle
        case (.staged, .lineEnded(needsAllow: false)): .set
        case (.staged, .lineEnded(needsAllow: true)): .waiting
        case (.staged, .newSentence): .set
        case (.staged, .touchWords): .stopped
        case (.stopped, .stopEnded): .idle
        case (.waiting, .allow): .set
        case (.waiting, .notNow): .undried
        case (.set, .undo): .undried
        case (.undried, .unDryEnded): .idle
        default: nil
        }
    }

    /// Whether Undo may be offered: only on a set change.
    static func canUndo(_ state: ChangeState) -> Bool {
        next(state, .undo) != nil
    }

    /// Whether the room is in flight: a change is staged, waiting, stopping or un-drying.
    static func isBusy(_ state: ChangeState) -> Bool {
        [.staged, .stopped, .waiting, .undried].contains(state)
    }
}

/// The room itself.
enum RoomPhase: String, CaseIterable, Sendable {
    /// The frame sketches in from each place's top-left corner.
    case blank
    /// The room, kept between visits.
    case live
    /// Ghost, outlines up then folded into their corners, the empty room dissolves.
    case archiving
    /// No row in the dial; the foot reads "Room taken down, not the plants" with Undo for 10 s.
    case archived
    /// The first open replays his set sentences once.
    case restored
}

enum RoomEvent: Equatable, Sendable {
    /// A change set.
    case firstSet
    /// "Take this room down".
    case takeDown
    /// The fold ended.
    case foldEnded
    /// He touched his words half way through the fold.
    case touchWords
    /// Undo, or "Bring back my plant room".
    case restore
    /// The replay ended (or was skipped).
    case replayEnded
}

enum RoomLifecycle {
    static func next(_ phase: RoomPhase, _ event: RoomEvent) -> RoomPhase? {
        switch (phase, event) {
        case (.blank, .firstSet): .live
        case (.live, .takeDown): .archiving
        case (.archiving, .foldEnded): .archived
        case (.archiving, .touchWords): .live
        case (.archived, .restore): .restored
        case (.restored, .replayEnded): .live
        default: nil
        }
    }
}
