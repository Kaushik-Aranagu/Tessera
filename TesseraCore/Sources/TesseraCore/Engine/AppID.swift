import Foundation

/// The six apps with a landing page. One name for each, used by the day sentence, the mentions of a thing and the
/// write router (Together, sheet 135). Never persisted: it is derived from a class on every read.
public enum AppID: String, CaseIterable, Sendable, Codable {
    case training, kitchen, money, notes, lists, routines

    /// The word the app is known by.
    public var name: String {
        switch self {
        case .training: "Training"
        case .kitchen: "Kitchen"
        case .money: "Money"
        case .notes: "Notes"
        case .lists: "Lists"
        case .routines: "Routines"
        }
    }
}
