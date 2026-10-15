import SwiftUI
import TesseraCore

private typealias Paint = WorkoutPaint

// MARK: - The exercise lane (x)

/// One name per page; the next peeks in. Tap the name to zoom into the exercise. Pull down on it for the swap panel:
/// the name follows the finger (rubber-banded to about 10 pt). The pager keeps horizontal.
struct ExerciseLane: View {
    let session: WorkoutSession
    @Binding var laneIndex: Int?
    let isSwapOpen: Bool
    var setSwap: (Bool) -> Void

    @State private var namePull: CGFloat = 0
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.zoomNamespace) private var zoomNamespace

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Array(session.entries.enumerated()), id: \.element.id) { index, entry in
                    let exercise = session.exerciseClass(of: entry)
                    let isCurrent = index == (laneIndex ?? session.currentIndex)
                    let name = exercise?.name ?? "Exercise"
                    Button {
                        if let exercise {
                            model.open(.classDef(exercise.id), .deeper)
                        }
                    } label: {
                        Text(name)
                            .textRole(.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.45)
                            .foregroundStyle(Paint.cream.opacity(isCurrent ? 1 : 0.28))
                            // A long name steps down a size and keeps clear of the next one peeking in.
                            .padding(.trailing, Theme.Spacing.m)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(name)
                            .transition(reduceMotion ? .opacity
                                : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                              removal: .opacity))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .modifier(ZoomSource(id: exercise.map { Route.classDef($0.id) }, namespace: zoomNamespace))
                    .containerRelativeFrame(.horizontal) { width, _ in width - Theme.Spacing.gutter - 46 }
                    .id(index)
                    .offset(y: isCurrent ? Self.rubberBand(namePull) : 0)
                    .contextMenu {
                        if isCurrent {
                            Button("Swap within the movement", systemImage: "arrow.left.arrow.right") {
                                setSwap(true)
                            }
                        }
                    }
                    .accessibilityHint(isCurrent ? "Opens the exercise page" : "")
                    .accessibilityAction(named: "Swap within the movement") { setSwap(true) }
                    .tesseraAnimation(.easeOut(duration: 0.24), value: isCurrent)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.leading, Theme.Spacing.gutter, for: .scrollContent)
        .contentMargins(.trailing, 46, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
        .scrollPosition(id: $laneIndex, anchor: .leading)
        .scrollIndicators(.hidden)
        .frame(height: 64)
        // Pull down on the name for alternatives; the pager keeps horizontal.
        .simultaneousGesture(
            DragGesture(minimumDistance: 14)
                .onChanged { drag in
                    guard session.finishedAt == nil, drag.translation.height > abs(drag.translation.width) else {
                        return
                    }
                    namePull = drag.translation.height
                }
                .onEnded { drag in
                    let pulled = drag.translation.height > 44 && drag.translation.height > abs(drag.translation.width)
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { namePull = 0 }
                    if pulled {
                        setSwap(!isSwapOpen)
                    } else if drag.translation.height < -30, isSwapOpen {
                        setSwap(false)
                    }
                }
        )
    }

    /// The name follows the finger up to about 10 pt, rubber-banded.
    private static func rubberBand(_ pull: CGFloat) -> CGFloat {
        guard pull > 0 else { return 0 }
        return 10 * (1 - exp(-pull / 40))
    }
}

// MARK: - Lines

/// The subline and Tess's line, in words, from the session's state.
@MainActor
enum WorkoutLines {
    static func subline(_ session: WorkoutSession, phase: WorkoutSession.Phase) -> (String, Color) {
        guard let entry = session.currentEntry else { return ("", Paint.secondary) }
        let target = session.targetSets(of: entry)
        let rows = session.setRows(of: entry)
        let tenth = { (value: Double) in Format.kilograms((value * 10).rounded() / 10) }
        switch phase {
        case .rest:
            if let seated = session.lastSeated, !seated.records.isEmpty, let e1RM = seated.e1RM {
                return ("a new best: e1RM \(tenth(e1RM))", Paint.now)
            }
            return ("set \(rows.count) seated", Paint.secondary)
        case .exerciseDone:
            return ("all \(target) sets in. Swipe for the next.", Paint.secondary)
        case .workoutDone:
            return ("every set is in", Paint.secondary)
        case .set:
            if let rpe = session.rpe {
                return ("RPE \(RPEStops.formatted(rpe)), \(RPEStops.words(for: rpe))", Paint.now)
            }
            if session.isPersonalRecord {
                return ("set \(session.currentSetNumber): this would be a new best", Paint.now)
            }
            if session.swappedFrom != nil, rows.isEmpty {
                return ("swapped for today, set \(session.currentSetNumber) of \(target)", Paint.tess)
            }
            let last = rows.last.map { ", last was \(Format.kilograms($0.weight)) × \(Int($0.reps))" } ?? ""
            return ("set \(session.currentSetNumber) of \(target)\(last)", Paint.secondary)
        }
    }

    static func tess(_ session: WorkoutSession, phase: WorkoutSession.Phase, summary: String?) -> String {
        if session.finishedAt != nil {
            return summary ?? ""
        }
        if case .rest = phase, let seated = session.lastSeated {
            return seated.records.isEmpty ? "Logged." : "That one goes on the wall."
        }
        switch phase {
        case .exerciseDone: return "\(session.currentExercise?.name ?? "That") is done."
        case .workoutDone: return "Last one. Hold to finish."
        default:
            return setLine(session)
        }
    }

    /// While dialling a set.
    private static func setLine(_ session: WorkoutSession) -> String {
        if let from = session.swappedFrom, let entry = session.currentEntry, session.setRows(of: entry).isEmpty {
            return "\(SwapPanel.short(from)) stays in the plan."
        }
        if session.isPersonalRecord {
            return "Go on. You have this."
        }
        if let note = session.restNote, note.hasPrefix("Skipped") {
            return note
        }
        if session.canUndo {
            return "Logged."
        }
        if let reason = session.targetReason, session.currentSetNumber == 1 {
            return reason + "."
        }
        if let best = session.previousBest {
            return "Last best was \(Format.kilograms(best.weight)) × \(Int(best.reps))."
        }
        return "Set \(session.currentSetNumber). \(Format.kilograms(session.weight)) × \(Int(session.reps))."
    }
}

// MARK: - Effort handle

/// Pull up on the reps (or tap "reps") to slide the effort stop-slider out; pull down to put it away.
struct EffortHandle: View {
    let isShown: Bool
    let enabled: Bool
    var setShown: (Bool) -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("reps").font(Theme.voice(size: 18)).foregroundStyle(Paint.cream.opacity(0.55))
            Text("effort")
                .textRole(.label)
                .foregroundStyle((isShown ? Paint.now : Paint.secondary).opacity(0.7))
        }
        .frame(minWidth: 92, minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            if enabled {
                setShown(!isShown)
            }
        }
        .gesture(DragGesture(minimumDistance: 10).onEnded { drag in
            guard enabled else { return }
            if drag.translation.height < -20 {
                setShown(true)
            } else if drag.translation.height > 20 {
                setShown(false)
            }
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isShown ? "Hide effort" : "Add effort")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            if enabled {
                setShown(!isShown)
            }
        }
    }
}

// MARK: - Tess bar

/// Dark glass with Tess's soul in screen blend and her line. After a set is logged it carries Undo on the right
/// until the next set is logged. No toast timer, never "Are you sure?".
struct WorkoutTessBar: View {
    let line: String
    let mode: TessSoul.Mode
    let canUndo: Bool
    var onUndo: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return HStack(spacing: Theme.Spacing.s) {
            TessSoul(mode: mode)
                .scaleEffect(0.5)
                .frame(width: 56, height: 56)
            Text(line)
                .font(Theme.voice)
                .foregroundStyle(Paint.tessBar)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .contentTransition(.opacity)
                .tesseraAnimation(value: line)
            Spacer(minLength: 0)
            if canUndo {
                Button(action: onUndo) {
                    Text("Undo")
                        .textRole(.labelStrong)
                        .foregroundStyle(Paint.cream)
                        .frame(minWidth: 60, minHeight: 60)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Undo the last set")
                .transition(.opacity)
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .frame(height: 66)
        .background(shape.fill(.white.opacity(0.07)))
        .glassEffect(.regular, in: shape)
        .overlay {
            shape.strokeBorder(LinearGradient(stops: [.init(color: .white.opacity(0.16), location: 0),
                                                      .init(color: .clear, location: 0.06)],
                                              startPoint: .top, endPoint: .bottom), lineWidth: 1)
        }
        .overlay { shape.stroke(.black.opacity(0.6), lineWidth: 0.5) }
        .tesseraAnimation(value: canUndo)
        .accessibilityElement(children: .contain)
    }
}
