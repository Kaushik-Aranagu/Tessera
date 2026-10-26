import Foundation

/// Where he is when he asks: the room and level, the switcher's word, what every place shows, and what he touched
/// last. The navigator builds it from the current `Screen` and `RoomState` at the moment he opens Tess; it replaces
/// the plain `screen:` line `TessRun.ask` takes today.
public struct TessFrame: Sendable, Equatable {
    /// The last place he touched, and the item on it.
    public struct Touch: Sendable, Equatable {
        public var place: ElementPlace
        public var item: ElementItem
        public var at: Date

        public init(place: ElementPlace, item: ElementItem, at: Date) {
            self.place = place
            self.item = item
            self.at = at
        }
    }

    /// A touch older than this no longer says what "this" is.
    public static let touchWindow: TimeInterval = 30
    /// Words that point at the referent.
    static let pointing: Set<String> = ["this", "it", "that", "these", "those", "them", "here"]
    /// The places "this" falls back to, in order, when he touched nothing lately.
    static let focusOrder: [ElementPlace] = [.widget, .page, .keystone, .dial]

    /// The room's ship name in lowercase: "bridge", "log", "lookout", "deck", "galley", "watch", "purse".
    public var room: String
    /// 0 is the landing, 1 a door page.
    public var level: Int
    public var door: String?
    /// The switcher's word now, across then up and down ("Due", "This week").
    public var window: String?
    public var elements: [ElementMeaning]
    public var touch: Touch?
    public var now: Date

    public init(room: String, level: Int = 0, door: String? = nil, window: String? = nil,
                elements: [ElementMeaning] = [], touch: Touch? = nil, now: Date = .now)
    {
        self.room = room
        self.level = level
        self.door = door
        self.window = window
        self.elements = elements
        self.touch = touch
        self.now = now
    }

    public func element(_ place: ElementPlace) -> ElementMeaning? {
        elements.first { $0.place == place }
    }

    /// What "this" means: a touch in the last 30 s, then the widget's item, the page's focused row, the keystone's
    /// focused part, the dial's door. Nil when nothing is in focus.
    public func referent() -> (place: ElementPlace, item: ElementItem)? {
        if let touch, now.timeIntervalSince(touch.at) <= Self.touchWindow, touch.at <= now {
            return (touch.place, touch.item)
        }
        for place in Self.focusOrder {
            if let item = element(place)?.focused {
                return (place, item)
            }
        }
        return nil
    }

    /// Whether the ask points at something on screen ("move it", "this is done").
    public static func points(_ ask: String) -> Bool {
        !pointing.isDisjoint(with: words(ask))
    }

    static func words(_ text: String) -> [String] {
        text.lowercased().split { !$0.isLetter && $0 != "'" }.map(String.init)
    }

    /// Every call the screen offers, once each, the touched place's first, then in place order.
    public var calls: [(place: ElementPlace, call: ElementCall)] {
        var ordered = elements
        if let touched = touch?.place, let index = ordered.firstIndex(where: { $0.place == touched }) {
            ordered.insert(ordered.remove(at: index), at: 0)
        }
        var seen: Set<String> = []
        var out: [(place: ElementPlace, call: ElementCall)] = []
        for element in ordered {
            for call in element.calls where seen.insert(call.name).inserted {
                out.append((element.place, call))
            }
        }
        return out
    }

    /// The objects the ask is likely about, referent first: they become the run's `about` handles.
    public var aboutIDs: [UUID] {
        var ids: [UUID] = []
        if let id = referent()?.item.id {
            ids.append(id)
        }
        for element in elements {
            for item in element.items {
                if let id = item.id, !ids.contains(id) {
                    ids.append(id)
                }
            }
        }
        return ids
    }

    /// The frame as context: where he is (always safe), what "this" is, and what each place shows by shown name.
    /// A name or fact keeps its own taint, so the Door drops money, body and calendar under strict.
    public func fragments(itemsPerPlace: Int = 5) -> [PackFragment] {
        let level = level == 0 ? "the landing" : "the \(door ?? "door") page"
        var fragments = [PackFragment("Where: \(room.capitalized), \(level)\(window.map { ", \($0)" } ?? "")")]
        if let referent = referent() {
            fragments.append(PackFragment("This: \(line(referent.item)) (\(referent.place.rawValue))",
                                          taint: taint(of: referent.item)))
        }
        for element in elements where !element.items.isEmpty {
            for item in element.items.prefix(itemsPerPlace) {
                fragments.append(PackFragment("\(element.place.rawValue): \(line(item))", taint: taint(of: item)))
            }
        }
        return fragments
    }

    func line(_ item: ElementItem) -> String {
        let facts: [String] = item.facts.map(\.text)
        let head = "\(item.kind) \(item.name)"
        return facts.isEmpty ? head : "\(head), \(facts.joined(separator: ", "))"
    }

    /// What kinds of thing are money, whichever room shows them.
    static let moneyKinds: Set<String> = [
        "spend",
        "paycheck",
        "inflow",
        "pool",
        "pool move",
        "move",
        "rate note",
        "bill",
    ]

    /// A thing is device-only when it says so, when any of its facts do, when it is private, when it is money, or
    /// when it sits in the Purse: the wall holds even if the navigator forgot to set a taint.
    func taint(of item: ElementItem) -> Taint {
        let own = item.taint == .deviceOnly || item.facts.contains { $0.taint == .deviceOnly }
        let money = Self.moneyKinds.contains(item.kind.lowercased())
        return own || item.isPrivate || room == "purse" || money ? .deviceOnly : .claudeSafe
    }
}
