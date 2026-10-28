import SwiftUI

// The shared Undo line (Design sheet 382). Rooms never draw their own: every room's receipt and Undo go through this
// view. Moved here from Features/Landing/GalleyModeKit.swift (Builder B built it) with its API kept; the Undo word's
// face is a parameter so the Galley keeps its Plex.

/// One Undo line (sheet 382): the word Undo stays at full ink for 6 s, then thins to 45% by the tenth; the line fades
/// over a quarter second when the time runs out; tapping Undo reverses the change at once and winds the line back
/// from its right end in 0.22 s. Reduce Motion: no thinning and no winding.
struct UndoLine<Text_: View>: View {
    let id: UUID
    let canUndo: Bool
    var tint: Color
    var reduceMotion: Bool
    /// The Undo word's face: Figtree 700 15 unless a room writes in its own (the Galley's Plex).
    var font: Font = .custom("Figtree", size: 15).weight(.bold)
    @ViewBuilder var text: Text_
    var undo: () -> Void
    @State private var start = Date.now

    static var thinStart: Double {
        6
    }

    static var thinEnd: Double {
        10
    }

    static var thinnest: Double {
        0.45
    }

    static var windDuration: Double {
        0.22
    }

    /// The word's ink at `age` seconds: 1 until 6 s, then down to 45% at 10 s.
    static func opacity(at age: Double, reduceMotion: Bool) -> Double {
        guard !reduceMotion, age > thinStart else { return 1 }
        let t = min((age - thinStart) / (thinEnd - thinStart), 1)
        return 1 - t * (1 - thinnest)
    }

    var body: some View {
        HStack(spacing: 12) {
            text
            if canUndo {
                TimelineView(.animation(minimumInterval: 0.25, paused: reduceMotion)) { context in
                    Button("Undo") { undo() }
                        .font(font)
                        .foregroundStyle(tint)
                        .opacity(Self.opacity(at: context.date.timeIntervalSince(start), reduceMotion: reduceMotion))
                        .buttonStyle(.plain)
                        .frame(minHeight: 44)
                }
            }
        }
        .onChange(of: id, initial: true) { _, _ in
            start = .now
        }
    }
}
