import Foundation

#if DEBUG
    /// `-wallsSpy` (simulator only, docs/research/walls-ui-test-spec.md §5): a URLProtocol that answers every Claude
    /// request in memory, so WallsUITests can count calls through the usage ledger without anything reaching the
    /// network.
    final class WallsSpy: URLProtocol, @unchecked Sendable {
        static let reply = #"{"content":[{"type":"text","text":"Spy."}],"stop_reason":"end_turn","#
            + #""usage":{"input_tokens":1,"output_tokens":1}}"#

        static func session() -> URLSession {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [WallsSpy.self]
            return URLSession(configuration: configuration)
        }

        override class func canInit(with _: URLRequest) -> Bool {
            true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            let response = HTTPURLResponse(url: request.url ?? URL(fileURLWithPath: "/"), statusCode: 200,
                                           httpVersion: nil, headerFields: ["Content-Type": "application/json"])
            if let response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocol(self, didLoad: Data(Self.reply.utf8))
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
#endif
