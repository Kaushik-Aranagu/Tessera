import Foundation
#if canImport(FoundationModels)
    import FoundationModels
#endif

/// The on-device Apple model as a Brain (harness H1a): a `LanguageModelSession` streamed as `BrainEvent`s. It reads
/// nothing from the network and costs nothing, so its usage is token counts only (cost 0). Text streams as the model
/// writes it (each snapshot is the text so far; only the new part is emitted).
///
/// Tools: Apple's `Tool` protocol needs a typed `Arguments` per tool, so Claude-style `ToolSpec`s are not offered to
/// this model in this slice (a request with tools answers as text only). The typed adapter arrives with the Tess loop.
public final class AppleBrain: Brain, @unchecked Sendable {
    public var id: BrainID {
        .appleOnDevice
    }

    public init() {}

    public var isAvailable: Bool {
        get async {
            #if canImport(FoundationModels)
                if case .available = SystemLanguageModel.default.availability {
                    return true
                }
            #endif
            return false
        }
    }

    public func stream(_ request: BrainRequest) -> AsyncThrowingStream<BrainEvent, Error> {
        AsyncThrowingStream { continuation in
            #if canImport(FoundationModels)
                let timer = Task {
                    try? await Task.sleep(for: request.deadline)
                    guard !Task.isCancelled else { return }
                    continuation.yield(.failed(.timeout))
                    continuation.finish()
                }
                let work = Task {
                    defer { timer.cancel() }
                    do {
                        let instructions = request.system.map(\.text).joined(separator: "\n\n")
                        let session = instructions.isEmpty ? LanguageModelSession()
                            : LanguageModelSession(instructions: instructions)
                        let prompt = Self.prompt(from: request.messages)
                        var sent = ""
                        for try await snapshot in session.streamResponse(to: prompt) {
                            let text = snapshot.content
                            if text.count > sent.count, text.hasPrefix(sent) {
                                continuation.yield(.text(String(text.dropFirst(sent.count))))
                                sent = text
                            }
                        }
                        continuation.yield(.done(BrainUsage(), stop: "end_turn"))
                        continuation.finish()
                    } catch is CancellationError {
                        continuation.finish()
                    } catch {
                        continuation.yield(.failed(.other))
                        continuation.finish()
                    }
                }
                continuation.onTermination = { _ in
                    work.cancel()
                    timer.cancel()
                }
            #else
                continuation.yield(.failed(.other))
                continuation.finish()
            #endif
        }
    }

    public func warm(_ prefix: BrainRequest) async -> BrainWarm? {
        #if canImport(FoundationModels)
            let instructions = prefix.system.map(\.text).joined(separator: "\n\n")
            let session = instructions
                .isEmpty ? LanguageModelSession() : LanguageModelSession(instructions: instructions)
            session.prewarm()
        #endif
        return nil
    }

    /// The conversation as one prompt: earlier turns as plain lines, then the last user message.
    static func prompt(from messages: [BrainMessage]) -> String {
        messages.enumerated().map { index, message in
            let text = message.content.compactMap { piece -> String? in
                if case let .text(text) = piece {
                    return text
                }
                return nil
            }.joined(separator: "\n")
            return index == messages.count - 1 ? text : "\(message.role == .user ? "User" : "Assistant"): \(text)"
        }.joined(separator: "\n")
    }
}
