import Foundation
@testable import Tessera
@testable import TesseraCore
import Testing

/// B7: SAVE A COPY leaves the phone only past a passcode and Face ID; the copy stays whole.
@Suite(.serialized) @MainActor
struct SaveCopyGateTests {
    let context: TesseraContext
    let engine: ActionEngine

    init() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("gate-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = try ObjectStore(context: TesseraContext(url: folder.appendingPathComponent("tessera.sqlite")))
        let classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        try engine.perform(CreateNote(body: "Bench felt heavy"), by: .user)
        context = store.context
    }

    private func restore() {
        BackupKeeper.hasPasscode = { true }
        BackupKeeper.authenticate = { false }
    }

    @Test func noPasscodeRunsNothingAndSaysWhy() async throws {
        defer { restore() }
        var asked = false
        BackupKeeper.hasPasscode = { false }
        BackupKeeper.authenticate = {
            asked = true
            return true
        }
        guard case .needsPasscode = try await BackupKeeper.savedCopy(context) else {
            Issue.record("expected needsPasscode")
            return
        }
        #expect(!asked, "Face ID never asks without a passcode")
        #expect(BackupKeeper.passcodeLine == "Set a passcode first. This copy has your private words.")
    }

    @Test func notPassingFaceIDSavesNothing() async throws {
        defer { restore() }
        BackupKeeper.hasPasscode = { true }
        BackupKeeper.authenticate = { false }
        guard case .declined = try await BackupKeeper.savedCopy(context) else {
            Issue.record("expected declined")
            return
        }
    }

    @Test func aCopyWithPrivateWordsCarriesTheLine() async throws {
        defer { restore() }
        try engine.perform(CreateNote(body: "Spare key\nUnder the blue pot", isPrivate: true), by: .user)
        BackupKeeper.hasPasscode = { true }
        BackupKeeper.authenticate = { true }
        guard case let .copy(url, line) = try await BackupKeeper.savedCopy(context) else {
            Issue.record("expected a copy")
            return
        }
        #expect(line == TesseraBackup.SavedCopyGate.privateWordsLine)
        try? FileManager.default.removeItem(at: url)
    }

    @Test func passingFaceIDHandsOverTheWholeCopy() async throws {
        defer { restore() }
        BackupKeeper.hasPasscode = { true }
        BackupKeeper.authenticate = { true }
        guard case let .copy(url, _) = try await BackupKeeper.savedCopy(context) else {
            Issue.record("expected a copy")
            return
        }
        #expect(FileManager.default.fileExists(atPath: url.path))
        try? FileManager.default.removeItem(at: url)
    }
}
