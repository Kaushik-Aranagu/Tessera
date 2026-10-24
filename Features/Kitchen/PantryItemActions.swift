import SwiftUI
import TesseraCore

extension PantryRoomItem {
    /// Offer only operations this source can actually perform. A typed shopping row can be checked off, not pinned.
    var moves: [PantryMove] {
        switch source {
        case .stock: [.toggle, .usedUp, .notNow, .pin]
        case .toGet: [.usedUp]
        case .added: []
        }
    }

    func title(for move: PantryMove) -> String {
        switch move {
        case .toggle: isLow ? "Back in" : "Running low"
        case .usedUp:
            if case .toGet = source {
                "Got it"
            } else {
                "Used up"
            }
        case .notNow: "Not now"
        case .pin: isPinned ? "Unpin" : "Pin"
        }
    }
}

/// Direct mutations belong only to a full, unambiguous target. Compact rows disclose actions without changing stock.
struct PantryRowControl<Content: View>: View {
    let item: PantryRoomItem
    let targetHeight: CGFloat
    let direct: Bool
    let perform: (PantryMove, PantryRoomItem) -> Void
    let openActions: () -> Void
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGFloat = 0
    @State private var holdoff = TapHoldoff()
    @State private var held = false

    var body: some View {
        Group {
            if direct {
                button
                    .rowSwipe(item.moves.contains(.notNow) ? .both : .leading) { event in
                        switch event {
                        case let .pulled(pull):
                            offset = pull
                            holdoff.moved(at: ProcessInfo.processInfo.systemUptime)
                        case let .committed(side):
                            perform(side == .leading ? .usedUp : .notNow, item)
                        case .ended:
                            holdoff.moved(at: ProcessInfo.processInfo.systemUptime)
                            withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { offset = 0 }
                        default: break
                        }
                    }
                    .onLongPressGesture(minimumDuration: GestureTuning.holdOpen,
                                        maximumDistance: CGFloat(GestureTuning.holdSlop), perform: {
                                            guard item.moves.contains(.pin) else { return }
                                            held = true
                                            holdoff.moved(at: ProcessInfo.processInfo.systemUptime)
                                            perform(.pin, item)
                                        }, onPressingChanged: { pressing in
                                            if !pressing, held {
                                                holdoff.moved(at: ProcessInfo.processInfo.systemUptime)
                                                held = false
                                            }
                                        })
            } else {
                button
            }
        }
        .accessibilityActions {
            ForEach(item.moves, id: \.self) { move in
                Button(item.title(for: move)) { perform(move, item) }
            }
            Button("Item actions", action: openActions)
        }
    }

    private var button: some View {
        Button {
            guard holdoff.allowsTap(at: ProcessInfo.processInfo.systemUptime) else { return }
            if direct, item.moves.contains(.toggle) {
                perform(.toggle, item)
            } else {
                openActions()
            }
        } label: {
            content()
                .frame(maxWidth: .infinity)
                .frame(height: targetHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(x: offset)
        .accessibilityLabel(item.spoken)
        .accessibilityHint(direct && item.moves.contains(.toggle)
            ? "Tap to change stock. Item actions are also available." : "Opens item actions")
        .accessibilityIdentifier("pantry.row.\(item.id.uuidString)")
    }
}

/// A full-sized route to the same engine actions when the columns are too dense for direct gestures.
struct PantryItemActions: View {
    let items: [PantryRoomItem]
    @State var selectedID: UUID?
    let perform: (PantryMove, PantryRoomItem) -> Void
    @Environment(\.dismiss) private var dismiss

    private var selected: PantryRoomItem? {
        items.first { $0.id == selectedID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                if selected != nil {
                    Button { selectedID = nil } label: {
                        Text("Choose a thing").frame(minHeight: PantryTouch.minimum).contentShape(Rectangle())
                    }
                }
                Spacer(minLength: 0)
                Button { dismiss() } label: {
                    Text("Done").frame(minWidth: PantryTouch.minimum, minHeight: PantryTouch.minimum)
                        .contentShape(Rectangle())
                }
            }
            .font(Theme.voice(size: 17))
            .foregroundStyle(Theme.Colors.Accent.kitchenText)
            if let item = selected {
                Text(item.name)
                    .font(Theme.voice(size: 28).weight(.semibold))
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityIdentifier("pantry.itemTitle")
                ForEach(item.moves, id: \.self) { move in
                    Button {
                        dismiss()
                        perform(move, item)
                    } label: {
                        Text(item.title(for: move))
                            .frame(maxWidth: .infinity, minHeight: PantryTouch.minimum, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("pantry.action.\(move)")
                }
            } else {
                Text("Choose a thing")
                    .font(Theme.voice(size: 28).weight(.semibold))
                    .foregroundStyle(Theme.Colors.ink)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(items) { item in
                            Button { selectedID = item.id } label: {
                                Text(item.spoken)
                                    .frame(maxWidth: .infinity, minHeight: PantryTouch.minimum, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityIdentifier("pantry.choose.\(item.id.uuidString)")
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .font(Theme.voice(size: 19))
        .foregroundStyle(Theme.Colors.Accent.kitchenText)
        .buttonStyle(.plain)
        .padding(Theme.Spacing.gutter)
        .background { ThemedBackground() }
    }
}
