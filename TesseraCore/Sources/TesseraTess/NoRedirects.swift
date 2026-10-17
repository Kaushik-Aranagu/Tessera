import Foundation

/// Every request to Claude refuses redirects (Product 9:53 PM PT Oct 16): a 3xx from anywhere on the way would carry
/// the key and his words to another host, so the hop is never taken and the call fails as the response it got. One
/// delegate for all four Claude clients, passed per task so it holds for any session, an injected one included.
final class NoRedirects: NSObject, URLSessionTaskDelegate, Sendable {
    static let shared = NoRedirects()

    func urlSession(_: URLSession, task _: URLSessionTask, willPerformHTTPRedirection _: HTTPURLResponse,
                    newRequest _: URLRequest) async -> URLRequest?
    {
        nil
    }
}
