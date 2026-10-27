import CryptoKit
import Foundation
#if canImport(Security)
    import Security
#endif
import TesseraCore

/// Tess's agents as objects he can see (docs/ai/harness/agents.md). The shipped ones mirror `AgentSpec`, which stays
/// their source. A new room or app spawns exactly one agent; nothing else spawns one, and an agent is never spawned
/// per ask. Agents persist: each run of one starts from its personality, its notebook and its recent episodes
/// (`AgentContext`), so it is the same one every time.
@MainActor
public struct AgentRegistry {
    public let engine: ActionEngine
    /// This install's salt for private room keys. It lives in the Keychain, this device only, never in the store or a
    /// device backup, so neither a Tessera backup nor a full phone backup can be used to confirm a guessed room name.
    let roomSalt: Data

    public init(engine: ActionEngine, roomSalt: Data = AgentRegistry.installSalt()) {
        self.engine = engine
        self.roomSalt = roomSalt
    }

    /// The install's room salt: 32 random bytes made on first use and kept in the Keychain. When the Keychain can't
    /// be read (before first unlock, or no Keychain), this launch uses a salt of its own and never overwrites the kept
    /// one; a private room spawned then is found again only in that launch.
    public static func installSalt() -> Data {
        #if canImport(Security)
            switch RoomSaltKeychain.read() {
            case let .found(salt):
                return salt
            case .missing:
                let salt = freshSalt()
                return RoomSaltKeychain.save(salt) ? salt : launchSalt
            case .unreadable:
                return launchSalt
            }
        #else
            return launchSalt
        #endif
    }

    static let launchSalt = freshSalt()

    static func freshSalt() -> Data {
        SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
    }

    var store: ObjectStore {
        engine.store
    }

    func rows() -> [ObjectRecord] {
        guard let agentClass = engine.classes[.tessAgent] else { return [] }
        return store.objects(of: agentClass).filter { !$0.isDeleted }
            .sorted { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }
    }

    func row(named name: String) -> ObjectRecord? {
        rows().first { store.value("agentName", of: $0)?.stringValue?.lowercased() == name.lowercased() }
    }

    // MARK: Shipped

    /// Mirrors the shipped agents into Agent objects: one each, updated in place when a spec's room name, personality
    /// or notebook changes. Idempotent; written without ops (they are the app's, not something he did). Returns how
    /// many rows it wrote.
    @discardableResult
    public func sync(now: Date = .now) -> Int {
        guard let agentClass = engine.classes[.tessAgent] else { return 0 }
        var wrote = 0
        for spec in AgentSpec.shipped {
            let existing = row(named: spec.name)
            let same = existing.map { row in
                row.title == spec.title && store.value("persona", of: row)?.stringValue == spec.persona
                    && store.value("notebook", of: row)?.stringValue == spec.notebook
            } ?? false
            guard !same, let target = existing ?? (try? store.create(agentClass, title: spec.title)) else { continue }
            target.title = spec.title
            try? store.set("agentName", to: .text(spec.name), on: target)
            try? store.set("room", to: .text(spec.room), on: target)
            try? store.set("persona", to: .text(spec.persona), on: target)
            try? store.set("notebook", to: .text(spec.notebook), on: target)
            try? store.set("shipped", to: .bool(true), on: target)
            if existing == nil {
                try? store.set("spawnedAt", to: .date(now), on: target)
            }
            wrote += 1
        }
        if wrote > 0 {
            store.save()
        }
        return wrote
    }

    // MARK: Spawning

    public enum Refusal: String, Error, Sendable {
        case shippedRoom = "That room already has its agent."
        case noName = "A room needs a name for its agent."
        case unreadable = "That agent couldn't be read back."
    }

    /// The one agent for a new room or app. A room that already has one gets that one back, so calling this again
    /// never makes a second. `classIDs` are the kinds the room keeps.
    @discardableResult
    public func spawn(room: String, title: String, classIDs: [UUID] = [], now: Date = .now) throws -> AgentSpec {
        guard !AgentSpec.shipped.contains(where: { $0.room == room.lowercased() }) else { throw Refusal.shippedRoom }
        let typed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !typed.isEmpty, let agentClass = engine.classes[.tessAgent] else { throw Refusal.noName }
        // Agent objects ride in backups and the export, so a private room ("Therapy") is kept as "Private room" and
        // its room key as a salted digest: the name never leaves the room it was typed in.
        let name = isPrivate(typed) ? Self.privateTitle : typed
        let roomKey = key(for: room, title: typed)
        let either: Set = [room.lowercased(), digest(room)]
        if let existing = rows().first(where: { either.contains(store.value("room", of: $0)?.stringValue ?? "") }),
           let found = spec(from: existing)
        {
            return found
        }
        let agentName = uniqueName(name)
        let slug = ObjectPath.Segment(target: .object(UUID()), title: agentName).slug
        let row = try store.create(agentClass, title: name)
        try store.set("agentName", to: .text(agentName), on: row)
        try store.set("room", to: .text(roomKey), on: row)
        try store.set("persona", to: .text(Persona.spawned(room: name)), on: row)
        try store.set("notebook", to: .text("/memories/\(slug)"), on: row)
        try store.set("classIDs", to: .text(Self.encode(classIDs)), on: row)
        try store.set("shipped", to: .bool(false), on: row)
        try store.set("spawnedAt", to: .date(now), on: row)
        store.save()
        guard let made = spec(from: row) else { throw Refusal.unreadable }
        return made
    }

    static let privateTitle = "Private room"

    func isPrivate(_ text: String) -> Bool {
        ObjectPrivacy.isPrivateTitle(text, lastWeightKg: BodyWeight.lastKg(in: store))
    }

    /// The stored room key: the room as typed, or a digest of it when the room or its title is private.
    func key(for room: String, title: String = "") -> String {
        let lower = room.lowercased()
        return isPrivate(lower) || (!title.isEmpty && isPrivate(title)) ? digest(lower) : lower
    }

    /// A keyed digest of the room, so the same room finds its agent again on this install and nowhere else.
    func digest(_ room: String) -> String {
        let key = SymmetricKey(data: roomSalt)
        let code = HMAC<SHA256>.authenticationCode(for: Data(room.lowercased().utf8), using: key)
        return "private-" + code.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    /// A name no other agent has (a spawned "Deck" room's agent is "Deck 2").
    func uniqueName(_ name: String) -> String {
        let taken = Set(AgentSpec.shipped.flatMap { [$0.name.lowercased(), $0.title.lowercased()] })
            .union(rows().compactMap { store.value("agentName", of: $0)?.stringValue?.lowercased() })
        var candidate = name
        var count = 1
        while taken.contains(candidate.lowercased()) {
            count += 1
            candidate = "\(name) \(count)"
        }
        return candidate
    }

    // MARK: Reading

    /// Every agent a policy allows: the shipped ones, then the spawned ones oldest first.
    public func agents(under policy: DoorPolicy) -> [AgentSpec] {
        let spawned = rows().filter { store.value("shipped", of: $0) != .bool(true) }.compactMap(spec(from:))
        return AgentSpec.available(under: policy) + spawned
    }

    /// The agent for a room, by its room key, name or room name.
    public func agent(_ key: String, under policy: DoorPolicy) -> AgentSpec? {
        let wanted = key.lowercased()
        let hidden = digest(wanted)
        return agents(under: policy).first {
            $0.room == wanted || $0.room == hidden || $0.name.lowercased() == wanted || $0.title.lowercased() == wanted
        }
    }

    /// A spawned agent's spec from its row: plain reads and the safe writes, its room's kinds, no sub-agents.
    func spec(from row: ObjectRecord) -> AgentSpec? {
        guard let name = store.value("agentName", of: row)?.stringValue,
              let room = store.value("room", of: row)?.stringValue,
              let notebook = store.value("notebook", of: row)?.stringValue
        else { return nil }
        if store.value("shipped", of: row) == .bool(true) {
            return AgentSpec.named(name)
        }
        let classIDs = Self.decode(store.value("classIDs", of: row)?.stringValue ?? "")
        return AgentSpec(
            name: name, title: row.title, persona: store.value("persona", of: row)?.stringValue ?? "",
            classIDs: classIDs, room: room, plain: .plain, open: .open,
            tools: AgentSpec.reads + ["remember", "createNote", "createTask"], beliefClasses: [], notebook: notebook,
            summaries: [.day, .week], expertise: nil, maxRounds: 8, maxChildren: 0, depth: 1, labOnly: false
        )
    }

    static func encode(_ ids: [UUID]) -> String {
        (try? JSONEncoder().encode(ids.map(\.uuidString))).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }

    static func decode(_ text: String) -> [UUID] {
        ((try? JSONDecoder().decode([String].self, from: Data(text.utf8))) ?? []).compactMap(UUID.init(uuidString:))
    }
}

#if canImport(Security)
    /// The room salt's Keychain item: a generic password, available after first unlock (the 4 am pass runs locked),
    /// this device only, never synced.
    enum RoomSaltKeychain {
        enum Read {
            case found(Data)
            case missing
            case unreadable
        }

        static let service = "com.kaushikaranagu.tessera.agentRoomSalt"

        static var query: [String: Any] {
            [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
             kSecAttrAccount as String: "salt", kSecAttrSynchronizable as String: false]
        }

        static func read() -> Read {
            var lookup = query
            lookup[kSecReturnData as String] = true
            lookup[kSecMatchLimit as String] = kSecMatchLimitOne
            var item: CFTypeRef?
            switch SecItemCopyMatching(lookup as CFDictionary, &item) {
            case errSecSuccess:
                guard let data = item as? Data, data.count == 32 else { return .unreadable }
                return .found(data)
            case errSecItemNotFound:
                return .missing
            default:
                return .unreadable
            }
        }

        static func save(_ salt: Data) -> Bool {
            var item = query
            item[kSecValueData as String] = salt
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
        }
    }
#endif
