import Foundation
import GRDB
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Sheet 215 rev 5: her conversation store. Filtered at write time, seven days, no ops, in no backup copy, nothing to
/// Claude unless asksClaude and never a held-back turn.
@MainActor
struct TessConversationTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var conversation: TessConversation {
        TessConversation(store: store, classes: engine.classes)
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func make(_ key: SystemCatalog.Key, _ title: String) throws -> ObjectRecord {
        try store.create(#require(engine.classes[key]), title: title)
    }

    // MARK: The class filter

    @Test func aPlainTurnIsStoredAsSaidWithItsLinks() throws {
        let task = try engine.perform(CreateTask(title: "Mail forms"), by: .user).output
        let turn = try #require(conversation.append(role: .user, text: "Move this to Friday", about: [task]))
        #expect(conversation.text(of: turn) == "Move this to Friday" && conversation.role(of: turn) == .user)
        #expect(!conversation.isHeldBack(turn) && conversation.about(turn).map(\.id) == [task.id])
    }

    @Test func moneyHealthBodyAndCalendarThingsAreNeverNamed() throws {
        let pool = try engine.perform(CreatePool(name: "US checking", opening: "100"), by: .user).output
        let event = try make(.event, "Dentist")
        let me = try make(.meProfile, "Me")
        let night = try make(.sleepNight, "Slept 7 hours")
        for object in [pool, event, me, night] {
            let turn = try #require(conversation.append(role: .tess, text: "That one moved", about: [object]))
            #expect(conversation.text(of: turn) == TessConversation.placeholder, "\(object.title)")
            #expect(conversation.isHeldBack(turn))
        }
    }

    @Test func aPrivateThingIsNamedByItsShownLabelOnly() throws {
        let secret = try engine.perform(CreateRoutine(title: "Knee rehab day"), by: .user).output
        let turn = try #require(conversation.append(role: .tess, text: "Knee rehab day moved to 7", about: [secret]))
        #expect(conversation.text(of: turn) == ObjectPrivacy.routineLabel && conversation.isHeldBack(turn))
    }

    @Test func walledWordsAreStoredAsAPlaceholderAndHeldBack() throws {
        for words in ["I paid 1200 rent", "I weighed 82 kg this morning", "I ate 600 calories", "Lexapro is low"] {
            let turn = try #require(conversation.append(role: .user, text: words))
            #expect(conversation.text(of: turn) == TessConversation.placeholder, "\(words)")
            #expect(conversation.isHeldBack(turn))
        }
        let plain = try #require(conversation.append(role: .user, text: "Limes are low"))
        #expect(conversation.text(of: plain) == "Limes are low" && !conversation.isHeldBack(plain))
        let key = try #require(conversation.append(role: .user, text: "sk-ant-api03-abcdefghijklmnop"))
        #expect(conversation.text(of: key) == TessConversation.placeholder)
        let empty = try #require(conversation.append(role: .user, text: "   "))
        #expect(conversation.isHeldBack(empty))
    }

    // MARK: Toward Claude

    @Test func claudeGetsNothingUnlessAsksClaudeAndNeverAHeldBackTurn() {
        _ = conversation.append(role: .user, text: "Limes are low")
        _ = conversation.append(role: .tess, text: "Want them on Groceries?")
        _ = conversation.append(role: .user, text: "I paid 1200 rent")
        _ = conversation.append(role: .user, text: "Yes please")
        #expect(conversation.forClaude(asksClaude: false).isEmpty)
        let turns = conversation.forClaude(asksClaude: true)
        #expect(turns.map(\.text) == ["Limes are low", "Want them on Groceries?", "Yes please"])
        #expect(turns.map(\.role) == [.user, .tess, .user])
        // At most the last few.
        for index in 0 ..< 6 {
            _ = conversation.append(role: .user, text: "Note \(index)")
        }
        #expect(conversation.forClaude(asksClaude: true).count == 4)
        #expect(conversation.forClaude(asksClaude: true, limit: 2).count == 2)
        #expect(conversation.forClaude(asksClaude: true, limit: 0).isEmpty)
        #expect(conversation.clear() == "Cleared")
        #expect(conversation.forClaude(asksClaude: true).isEmpty)
    }

    // MARK: Expiry and clear

    @Test func turnsExpireAfterSevenDaysAtLaunchAndOnTheNextWrite() throws {
        let now = Date.now
        let old = try #require(conversation.append(
            role: .user,
            text: "Old one",
            at: now.addingTimeInterval(-8 * 86400)
        ))
        let edge = try #require(conversation.append(
            role: .user,
            text: "Six days",
            at: now.addingTimeInterval(-6 * 86400)
        ))
        // The first append expired nothing it should keep; at launch the old one goes.
        #expect(conversation.expire(now: now) == 1 || old.isDeleted)
        #expect(conversation.turns().map(\.id) == [edge.id])
        _ = try #require(conversation.append(role: .tess, text: "New", at: now))
        #expect(conversation.count == 2)
        // A write far in the future expires what is then old.
        _ = conversation.append(role: .tess, text: "Later", at: now.addingTimeInterval(8 * 86400))
        #expect(conversation.turns().map { conversation.text(of: $0) } == ["Later"])
    }

    @Test func clearErasesEveryTurnAndSaysCleared() throws {
        for index in 0 ..< 5 {
            _ = conversation.append(role: .user, text: "Turn \(index)")
        }
        #expect(conversation.count == 5)
        #expect(conversation.clear() == "Cleared" && TessConversation.clearedLine == "Cleared")
        #expect(conversation.count == 0)
        let remaining = try #require(engine.classes[.tessTurn]).id
        #expect(store.context.all(ObjectRecord.self).allSatisfy { $0.classDef?.id != remaining })
    }

    // MARK: Never in the op log, never in a backup

    @Test func writingAndClearingLeaveNoOpsAndNoHistory() throws {
        let before = engine.history(limit: 1000).count
        let turn = try #require(conversation.append(role: .user, text: "Limes are low"))
        #expect(engine.history(limit: 1000).count == before)
        #expect(engine.history(of: turn.id).isEmpty)
        conversation.clear()
        #expect(engine.history(limit: 1000).count == before)
    }

    @Test func noBackupCopyHoldsATurnNotEvenTheLocalOne() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("tessera.sqlite")
        let store = try ObjectStore(context: TesseraContext(url: file))
        let classes = try store.prepareCatalog()
        let conversation = TessConversation(store: store, classes: classes)
        let turn = try #require(conversation.append(role: .user, text: "zebraturnwords"))
        store.save()
        #expect(store.object(id: turn.id) != nil) // it is really in the store being copied
        let local = dir.appendingPathComponent("local.sqlite"), cloud = dir.appendingPathComponent("cloud.sqlite")
        try TesseraBackup.write(from: store.context, to: local)
        try TesseraBackup.write(from: store.context, to: cloud, leavingOutPrivate: true)
        for url in [local, cloud] {
            let rows = try DatabaseQueue(path: url.path).read { db in
                try Int.fetchOne(db, sql: "SELECT count(*) FROM object WHERE id = ?",
                                 arguments: [turn.id.uuidString]) ?? -1
            }
            // Not a row, and not a byte of the words anywhere in the file.
            let bytes = try Data(contentsOf: url)
            #expect(bytes.range(of: Data("zebraturnwords".utf8)) == nil, "the words are in \(url.lastPathComponent)")
            let counts = [rows]
            #expect(counts[0] == 0, "the turn row is in \(url.lastPathComponent)")
        }
        #expect(try String(data: TesseraExport(context: store.context).encoded(), encoding: .utf8)?
            .contains("zebraturnwords") == false)
    }

    @Test func theTurnTypesStayOutOfWidgetsWatchIntentsAndSurfaces() throws {
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
        var checked = 0
        for (path, _) in [("../Widgets", ""), ("../Watch", ""), ("../Shared", ""), ("Sources/TesseraIntents", ""),
                          ("../DesignSystem", ""), ("../Features/Surfaces", ""),
                          ("Sources/TesseraCore", "")]
        {
            var inThisFolder = 0
            guard let walker = FileManager.default.enumerator(at: package.appending(path: path),
                                                              includingPropertiesForKeys: nil) else { continue }
            for case let url as URL in walker where url.pathExtension == "swift" {
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
                inThisFolder += 1
                checked += 1
                for word in ["TessConversation"] {
                    let pattern = try Regex("\\b\(word)\\b")
                    #expect(text.firstMatch(of: pattern) == nil, "\(word) in \(url.path)")
                }
            }
            #expect(inThisFolder > 0, "no Swift files found in \(path)")
        }
        #expect(checked > 100)
    }
}
