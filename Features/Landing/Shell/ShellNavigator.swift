import Observation
import SwiftUI

/// One change from one route to another, as the shell plays it. Only one is ever in flight: a new route during a
/// change replaces it (`retargeted`), starting from what the shell was presenting; nothing queues.
struct ShellChange: Equatable {
    let id: Int
    let from: ShellRoute
    let to: ShellRoute
    let retargeted: Bool
}

/// The navigator (sheet 283 v5, layer 3): owns the route stack and each route's `RoomState`. Pushing a door keeps
/// the landing's state; popping drops the door's and restores the landing's exactly, so every place returns to what
/// it showed before.
@MainActor
@Observable
final class ShellNavigator {
    private(set) var stack: [ShellRoute]
    private var states: [ShellRoute: RoomState] = [:]
    /// The change in flight, or nil when the shell is at rest.
    private(set) var change: ShellChange?
    private var nextChangeID = 1

    init(root: ShellRoute) {
        stack = [root]
    }

    var route: ShellRoute {
        stack[stack.count - 1]
    }

    var canPop: Bool {
        stack.count > 1
    }

    func state(for route: ShellRoute) -> RoomState {
        states[route] ?? RoomState()
    }

    /// The current route's state; places write back into it (switcher, widget, dial, keystone page, scroll).
    var state: RoomState {
        get { state(for: route) }
        set { states[route] = newValue }
    }

    /// A binding to one field of the current route's state, for a place's own gestures.
    func binding<Value>(_ keyPath: WritableKeyPath<RoomState, Value>) -> Binding<Value> {
        Binding(get: { self.state[keyPath: keyPath] }, set: { self.state[keyPath: keyPath] = $0 })
    }

    func push(_ next: ShellRoute) {
        guard next != route else { return }
        let from = presenting
        stack.append(next)
        begin(from: from)
    }

    func pop() {
        guard canPop else { return }
        let from = presenting
        let left = stack.removeLast()
        // A door's own state goes with it; the route below keeps its state untouched.
        if !stack.contains(left) {
            states[left] = nil
        }
        begin(from: from)
    }

    /// The shell calls this when a change's clock has run out. A stale id (a retargeted change) is ignored.
    func finish(_ id: Int) {
        if change?.id == id {
            change = nil
        }
    }

    /// The route the shell is showing, or heading to while a change is in flight: a retarget starts from here.
    private var presenting: ShellRoute {
        change?.to ?? route
    }

    private func begin(from: ShellRoute) {
        let retargeted = change != nil
        change = ShellChange(id: nextChangeID, from: from, to: route, retargeted: retargeted)
        nextChangeID += 1
    }
}
