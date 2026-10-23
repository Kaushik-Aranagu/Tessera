import Foundation

/// His own "it arrived" mark for a delivery (sheet 201, the delivery moment). Nothing outside the phone tells the app a
/// parcel came: he taps it. The mark is an op with no object, so it holds no name, no address and no amount; the
/// mosaic reads it from the log for a moment and no more.
public struct MarkArrived: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "markArrived", summary: "Mark a delivery as arrived",
        parameters: [
            .init("what", .string, "groceries, or nothing for any delivery", required: false),
        ], isOfferedToModel: false
    )

    public static let groceries = "groceries"

    public var what: String?

    public init(what: String? = nil) {
        self.what = what
    }

    public func apply(_: inout Transaction) throws {}

    /// Generic on purpose: the op log keeps "Groceries arrived" or "A delivery arrived", nothing else.
    public func summary(in _: ObjectStore) -> String {
        what == Self.groceries ? "Groceries arrived" : "A delivery arrived"
    }
}
