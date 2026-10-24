import Foundation
import Speech
@testable import TesseraTess
import Testing

private struct FakeEngine: TessSpeechEngine {
    var missing: TessListenGap?
    var heard = "  add milk  "
    var fails = false

    func gap() async -> TessListenGap? {
        missing
    }

    func finalText(from _: AsyncStream<AnalyzerInput>) async throws -> String {
        if fails {
            throw CancellationError()
        }
        return heard
    }
}

@Suite("Tess speech")
struct TessSpeechTests {
    private var silence: AsyncStream<AnalyzerInput> {
        AsyncStream { $0.finish() }
    }

    @Test func finalTextIsTrimmed() async {
        let result = await TessSpeech.listen(engine: FakeEngine(), audio: silence)
        #expect(result == .text("add milk"))
    }

    @Test func aMissingModelFallsBackWithoutListening() async {
        let result = await TessSpeech.listen(engine: FakeEngine(missing: .modelNotDownloaded), audio: silence)
        #expect(result == .unavailable(.modelNotDownloaded))
        #expect(TessListenGap.modelNotDownloaded.line.contains("Type it"))
    }

    @Test func emptyAndFailedListensSayNothingElse() async {
        #expect(await TessSpeech.listen(engine: FakeEngine(heard: " "), audio: silence) == .nothingHeard)
        #expect(await TessSpeech.listen(engine: FakeEngine(fails: true), audio: silence) == .unavailable(.failed))
    }

    @Test func noServerOrSiriPathExists() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("../../Sources/TesseraTess/TessSpeech.swift").standardized
        let text = try String(contentsOf: root, encoding: .utf8)
        let code = text.split(separator: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("///") }
            .joined(separator: "\n")
        for banned in [
            "SFSpeechRecognizer",
            "DictationTranscriber",
            "INInteraction",
            "URLSession",
            "requiresOnDeviceRecognition = false",
        ] {
            #expect(!code.contains(banned), "\(banned)")
        }
    }
}
