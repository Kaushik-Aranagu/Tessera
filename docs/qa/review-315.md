# Review: PR #315, recipe link-fetch L1-L3 (head 078cb54)

QA thread, Oct 15 PT. Static review. Base 2655789, which is on master. Files: `TesseraCore/Sources/TesseraTess/RecipeLinkReader.swift` (new), `TesseraCore/Sources/TesseraCore/Kitchen/RecipeImport.swift` (new) and `Tests/TesseraCoreTests/RecipeLinkTests.swift`. The copy is checked against Design's `kitchen/link-fetch-us.md` at 971f220 (Research's final strings), on branch claude/project-thread-b3tu3f.

**Verdict: FIX FIRST.** The Claude side is right: it's gated, reserved, logged in the ledger, skipped at the cap, and never writes. But two of the network-safety promises don't hold yet: redirects to private hosts are followed (N1), and the 3 MB cap only applies after the whole body has downloaded (N2).

## Network safety
- **PASS: the link itself.** `safeURL` (RecipeLinkReader.swift:197-212) upgrades http to https, adds https when there's no scheme, and allows only port 443 and hosts with a dot. It refuses:
  - localhost, `.local` and `.localhost`;
  - 10/8, 127/8, 0/8, 192.168/16, 172.16/12 and 169.254/16;
  - any IPv6 literal.
  - Tested in `linksThatAreNeverRead`.
- **PASS:** one ephemeral session, the honest user agent (:86, tested), and `Accept: text/html`. Only 2xx is read (:166). The content type must contain "html", and a missing header is taken as html (:167-168). The final URL must be https (:170).
- **N1 (must fix): redirects to a private host are followed.** `session.data(for:)` (:153) follows redirects on its own, and nothing checks where they go. The final-URL check (:169-170) only looks at the scheme. So `https://evil.example/r` → 302 → `https://192.168.1.1/admin` makes a GET to his router, and `https://10.0.0.2/` works the same way. The only reason that page isn't read is that it probably isn't a recipe; the request has already happened.
  - Fix: pass a per-task delegate, `session.data(for: request, delegate: RedirectGuard())`, whose `urlSession(_:task:willPerformHTTPRedirection:newRequest:)` returns nil unless `safeURL(newRequest.url)` passes, and limit it to 5 hops. Then run `safeURL` on `http.url` at :169 as well.
  - Test: a stubbed 302 to `https://192.168.1.1/` makes no second request and shows the blocked line.
- **N2 (must fix): the 3 MB cap is checked after the whole body is in memory.** `session.data(for:)` downloads all of it first, and `data.count <= maxBytes` (:168) runs afterwards. A 500 MB response is downloaded in full over his data plan and held in memory before "Too big" shows. The 8 s timeout is an idle timeout, so a slow trickle never trips it.
  - Fix: use `session.bytes(for:)` and stop past 3 MB (check `expectedContentLength > maxBytes` first to stop early), plus a hard deadline like `withDeadline` in PlanWording.
- **N3 (should fix): parsing runs on the main actor.** `RecipeLinkReader` is `@MainActor`, so on pages up to 3 MB these all run on the main thread:
  - `RecipeImport.recipes`, `isPaywalled` and `fromText`;
  - `visibleText`, which makes several Swift Regex passes, including a lazy `(?is)<script\b.*?</script\s*>` per tag (RecipeImport.swift:139-149).
  - Swift Regex is slow on large inputs, and the tests only use small fixtures, so the UI may freeze while a big page parses. Fix: make the parse functions `nonisolated` and run them in a `Task.detached`, or time a 2 MB fixture to show it's under 100 ms.
- Lows:
  - `https://localhost./` (trailing dot) passes `safeURL`, so strip a trailing dot first.
  - Hex, octal and decimal IPv4 forms (`0x7f.0.0.1`) aren't matched.
  - A public name that resolves to a private address isn't caught (DNS). That's acceptable for a personal app once N1 is fixed.

## L3 (Claude): PASS
- `allowed()` and the key are checked first (:300). With "Tess asks Claude" off, no request goes to api.anthropic.com (tested), and the line is "No recipe on that page. Paste the text instead."
- It reserves before sending (:302-308). `defer { settle }`, and a ledger row (`use: .paste`, Haiku 5.5, real usage, outcome) is written on every path after the reservation (:320-326).
- At the cap it returns the paused line with no request. The test counts only the page fetch, and the line reads "Claude's paused until Nov 1. Paste the text instead.", which ends the month correctly. The reader returns before anything could say "Asking Claude.", so Builder B must show that line only after `read` has passed the reserve (worth telling Builder B).
- It never writes the store. The reply is parsed into recipe text that he checks and saves, with a cap of 80 ingredients and 60 steps (:344-346).
- The page is sent as the user message, and the system prompt calls it data (:280-285). It's trimmed to about 24,000 characters around "ingredient" (:288-294).
- No logs: neither file uses Logger, print or os_log, and the key is only in the `x-api-key` header.
- Lows:
  - `stop_reason` isn't read, so a reply cut off at max_tokens can parse as a short recipe. That's caught when he checks it, but returning nil on "max_tokens" would be safer.
  - A 401 or 429 shows the no-recipe line, and the ledger outcome is "other".
  - The 20 s timeout is an idle timeout, not the hard 20 s Design's timeout row assumes.

## The lines: PASS, with one extra
- These match link-fetch-us.md (971f220) word for word:
  - blocked, both paywall lines, no recipe, timeout, paused;
  - the video description line, the video link line, no video recipe;
  - offline, too big;
  - "Reading host…", "7 ingredients, 3 steps, 2 timers." in digits, "3 recipes on that page. I read the first.";
  - "No recipe card there. Asking Claude.", "Claude read it. Check it, then save.", "… saved." and "… taken back."
  - `theLinesAreTheTable` pins them.
- **N4 (should fix):** `httpsOnly`, "That site only works without https, so I can't read it. Paste the text instead." (:14, used at :159 and :170), isn't in Design's table. Map it to "Too big or odd", or ask Design to add a row. A link `safeURL` refuses also gets "Too big to read safely." (:100). That's Design's "odd" row, so it's fine.

## Paywall and video paths: PASS
- A complete card (2+ ingredients and steps) is read even on a paywalled page. Otherwise a paywall gives the ingredients ("The steps are paywalled. Paste them below.", kind `.partial`) or the paywall line, and Claude is never asked (:122-128).
- Video hosts (YouTube, youtu.be, TikTok, Instagram) only read `og:description` or `description`. A recipe with 2+ ingredients gets "N ingredients, from the video's description." A non-video https link in the description is offered as "The video links to host. Read that?" and goes back through `read()`, so `safeURL` still applies. Otherwise "No written recipe in that video…" (:179-192).
- Low: a small page with "captcha" in it counts as blocked whatever its status (:173), which is fine.

## Must fix before merge
1. N1: block redirects to private hosts and check `safeURL` on the final URL, plus a test.
2. N2: stream with a hard 3 MB cap and a hard deadline.
3. N3 and N4 should ride the same push.
