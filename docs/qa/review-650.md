# QA review: #650 (Core, no redirects on Claude calls, C4 + Product 9:53 PM)

Head: 90c20377. Merge-tree clean on master f1283c87. 9 files, +99/-4: NoRedirects.swift (new), one call-site line in each of ClaudeKey, ClaudeTessModel, PlanWording, RecipeLinkReader (the Claude reader), and a 301 test per client.

## Verdict: PASS at 90c20377. The redirect finding is fully closed.

- NoRedirects is a final, Sendable NSObject URLSessionTaskDelegate whose willPerformHTTPRedirection returns nil, so the 3xx is delivered as the response and never followed. It is passed per task (`session.data(for:delegate:)`), so it holds for any session, an injected one included. The key travels in a custom header, which URLSession does NOT strip on a cross-host hop (only Authorization is), so this was a real exposure and the per-task delegate is the right fix.
- Call-site grep over Sources, Features and App (tests and docs excluded): the only requests to api.anthropic.com are the four patched ones (ClaudeKey.swift:302, ClaudeTessModel.swift:231, PlanWording.swift:605, RecipeLinkReader.swift:401). There is a single Claude URL constant (ClaudeKey.swift:200). No URLSession.shared, dataTask, uploadTask or download call exists in Sources or the app target. The only other network read is the recipe page fetch (RecipeLinkReader.swift:197, `session.bytes(for:delegate: redirects)`), which is not a Claude call and keeps its own per-hop validated redirect delegate; it carries no key.
- Tests: each stub answers with a 301 to a run-time-built host ("evil" + ".example"), then asserts no request reaches that host and the call does not succeed (key check != .works, Tess capture not .claude with no records, plan not .worded, link read not .readByClaude). Without the delegate the stub's second hop would hit the other host, so the assertions have teeth. Hosts are built from pieces; no key literal appears.
- LinkStub also delivers the 302 as a response when the hop is refused, so page redirects in the other tests still follow through their own delegate.

## Lows (optional)
1. Add one source-level guard to the planned HouseRulesTests lint (D1): any `session.data(for:` or `.bytes(for:` in TesseraTess must pass `delegate:`, and no file may name the Claude host outside ClaudeKey.base. That keeps a fifth Claude call from skipping NoRedirects later.
2. The Claude client treats the delivered 3xx as a plain failure (offline/unavailable line); fine, but a one-line note in docs/ai on what-was-sent that a redirect is refused would help the next reviewer.
