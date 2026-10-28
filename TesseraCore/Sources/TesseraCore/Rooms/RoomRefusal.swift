import Foundation

// How the Chart room says no (Design sheet 361, R1 spec section 4). Tess never says "can't" or "error": a refusal names
// the rule in plain words and, where one exists, offers the nearest thing the rules allow. The offer is a patch, so its
// button runs with no second model call. A kit miss is queued for the next install (R5 builds the part on the Mac).

public struct RoomRefusal: Equatable, Sendable {
    /// What Tess says in the widget place, e.g. "No boxes in this house. Bigger numbers instead?".
    public var line: String
    /// The receipt line, e.g. "Boxes, not here".
    public var receipt: String
    /// The nearest allowed change, and the words on its button ("Bigger numbers").
    public var offer: RoomPatch?
    public var offerLabel: String?
    /// A part the kit does not have yet, named as he said it.
    public var queue: String?
}

@MainActor
public enum RoomRefusals {
    /// Parts that break the house rules (no cards, boxes, pills, bars, dots, tiles or decorative underlines).
    static let decorations: [String: String] = [
        "box": "boxes", "card": "cards", "pill": "pills", "border": "borders", "frame": "frames", "badge": "badges",
        "chip": "chips", "tile": "tiles", "shadow": "shadows", "underline": "underlines", "bar": "bars", "dot": "dots",
    ]
    /// A word after the offered color, so "Olive, like the leaves?" reads as Tess says it.
    static let flavor: [String: String] = [
        "olive": "like the leaves",
        "sage": "like new growth",
        "rain": "like a wet window",
    ]

    /// The refusal for a patch, or nil when it is allowed. House rules are looked at first, in the order the steps
    /// come,
    /// so the answer names the rule he broke and offers the nearest change.
    public static func refusal(for patch: RoomPatch, against document: RoomDocument, store: ObjectStore,
                               classes: [SystemCatalog.Key: ClassDef], picked: String? = nil) -> RoomRefusal?
    {
        let validator = RoomPatchValidator(store: store, classes: classes)
        for step in patch.ops {
            if let kind = step.kind?.lowercased(), RoomKit.kind(kind) == nil, step.op == "add" || step.op == "set" {
                return kitRefusal(kind)
            }
            if step.op == "look", step.trait == "color", let value = step.value,
               validator.colorRefusal(value, room: document.name) != nil
            {
                return colorRefusal(value, room: document.name, validator: validator)
            }
        }
        switch validator.validate(patch, against: document, picked: picked) {
        case .ok: return nil
        case let .refused(reason):
            return RoomRefusal(line: reason, receipt: "Not changed", offer: nil,
                               offerLabel: nil, queue: nil)
        }
    }

    private static func kitRefusal(_ kind: String) -> RoomRefusal {
        if let plural = decorations[kind] {
            let offer = RoomPatch(room: "Chart room", say: "Numbers, bigger",
                                  ops: [.init(op: "look", trait: "size", value: "bigger")])
            return RoomRefusal(line: "No \(plural) in this house. Bigger numbers instead?",
                               receipt: "\(plural.capitalized), not here", offer: offer, offerLabel: "Bigger numbers",
                               queue: nil)
        }
        return RoomRefusal(
            line: "A \(kind) is a new kind of part. I'm building it on the Mac, and it comes with your next install",
            receipt: "\(kind.capitalized), queued for your next install", offer: nil, offerLabel: nil, queue: kind
        )
    }

    private static func colorRefusal(_ value: String, room: String, validator _: RoomPatchValidator) -> RoomRefusal {
        let word = value.lowercased()
        if RoomKit.tessRoles.contains(word) {
            let offer = RoomPatch(room: "Chart room", say: "Slate, set",
                                  ops: [.init(op: "look", trait: "color", value: "slate")])
            return RoomRefusal(line: "That's Tess's color. Slate instead?", receipt: "\(value.capitalized), Tess's",
                               offer: offer, offerLabel: "Slate", queue: nil)
        }
        let wanted = RoomColor.roles[word] ?? RoomColor.words[word]
        let nearest = wanted.flatMap { RoomColor.nearestAllowedRole(to: $0, besides: room) }
            ?? RoomColor.nearestAllowedRole(to: RoomColor.Pair(0x808080, 0x808080), besides: room)
        let owner = wanted.flatMap { RoomColor.clash(of: $0, besides: room)?.room }
        let opener = owner.map { "\(value.capitalized) is the \($0)'s." }
            ?? (RoomKit.colorRoles.contains(word) ? "\(value.capitalized) colors parts, not a room."
                : "Rooms use named colors.")
        guard let nearest else {
            return RoomRefusal(
                line: opener,
                receipt: "\(value.capitalized), taken",
                offer: nil,
                offerLabel: nil,
                queue: nil
            )
        }
        let name = nearest.capitalized
        let tail = flavor[nearest].map { "\(name), \($0)?" } ?? "\(name) instead?"
        let offer = RoomPatch(room: "Chart room", say: "\(name), set",
                              ops: [.init(op: "look", trait: "color", value: nearest)])
        return RoomRefusal(line: "\(opener) \(tail)", receipt: "\(value.capitalized), taken", offer: offer,
                           offerLabel: name, queue: nil)
    }
}
