# M5 candidates: Money and Reading

For: Product lead (planning)
Date: 2026-10-15

Both fit as small M5 slices. Reading is the safer first pick: it reuses Process and What's running almost as is. Money is one class and one grammar phrase, but it needs a currency decision.

## Money (spend log, no bank data)

**What the best apps do, and why people quit.** Cashew (free, open source, fast entry, no paywall), Money Manager and Toshl (quick keypad, category grid), Spendee (pretty, but key features are behind a subscription). Actual Budget and YNAB's manual mode are budget methods first: envelopes, reconciling, a weekly ritual. Copilot is the contrast: bank sync does the logging, so the habit is reviewing, not entering. Why people quit manual trackers: entry feels like a chore, one missed week makes the totals "wrong" so they stop, category setup before first use, and budget screens in red turn the app into a judge.

**Bank data is not possible.** FinanceKit (Apple Card, Apple Cash, Savings in the US from iOS 17.4; UK open banking from iOS 18.4) needs a paid Developer Program account, an entitlement request per bundle ID, and an App Store app in the Finance category. A personal free-account app cannot use it. Park it with iCloud sync.

**Smallest first version**
- Class `Spend`: amount, currency (defaults to home), note, category (optional, picked up from the note), date, links.
- Actions: log spend, edit, delete (undo via op log). Optional: a shop process ending asks "total?".
- Grammar: `spent 12.40 lunch`, `12.40 lunch`, `450 groceries @Shop`, `spent 20 eur taxi` (other currency, stored as is, not converted).
- Month count line: "October: 41 spends, 312 on groceries". Counts and totals, no budget, no limit, no red.

**First time, under 30 s:** type `spent 4.50 coffee` in the ghost row. Feedback line: "Logged. 1st spend this month." Category "coffee" is created from the word. No setup screen.

**Where it shows**
- Now: nothing by default. After a shop finishes, one "total?" prompt.
- What's running: not used (a spend is an instant event).
- Day log: "Spent 3 times, 26.90 (lunch, coffee, taxi)".

**Pitfalls**
1. Gaps make totals look false, and that causes quitting. Label the line "logged this month", never "you spent".
2. Categories explode. Keep a flat word list; merging is a later class tool.
3. Mixed currencies. Never sum across currencies; show one line per currency until there is a decision.

Receipt capture: skip in v1. VisionKit text scan for a total is possible later, all on device.

## Reading queue (a book is a process)

**What the best apps do, and why people quit.** Goodreads is the default catalog but slow, ad-like and Amazon-owned; the yearly challenge becomes guilt. StoryGraph won switchers with mood tags and stats, but stats pages grow heavy. Bookly and Basmo time every session (tedious, subscription). Literal is social first. Why people quit: logging every session is a chore, challenges and streaks feel like failing, and to-read lists grow into a pile of guilt.

**Lookup sources**
- Open Library: free, no key. Ask for a User-Agent with app name and contact (3 req/s identified, 1 req/s anonymous). No bulk downloads; cache results. Covers come from the Covers API by ISBN.
- Google Books: needs an API key even for public search; Google terms and branding rules apply. Not worth it for v1.
- Barcode: VisionKit `DataScannerViewController` reads EAN-13 (the ISBN on the back) on device; check `isSupported` and `isAvailable`. No network needed to scan, only to look up.

**Smallest first version**
- Class `Book`: title, author, pages (optional), isbn (optional), state (queued, reading, finished, dropped), resume page, review line, cover (optional).
- `Book` is a process: start reading puts it in What's running; `p 142` moves its resume point; finish asks one line; drop is calm ("set aside", not failed).
- Grammar: `read Dune` (adds to queue), `reading Dune` (starts), `p 142` (current book; with two, the latest touched), `finished Dune: slow start, great end`.

**First time, under 30 s:** type `reading Dune`. The book appears in What's running at p 0, title only. Next day `p 40` works with no other step. Scanning and lookup are optional, from the book page.

**Where it shows**
- Now: in the evening slot, "Dune, p 142" with Resume, if nothing else is running.
- What's running: the book, with resume page and "page 142 of 612" if pages are known.
- Day log: "Read Dune, p 120 to 142". Finishing writes "Finished Dune: slow start, great end".

**Pitfalls**
1. Queue guilt. Queued books older than 30 days fade to Later; never show "47 to read".
2. Two books at once makes `p 142` ambiguous. Use the last touched book and show its title in the feedback line.
3. Lookups are the only network call in the app. Keep them opt in and cached, with the typed title as the fallback.

## Yes/no for Kaushik

1. Reading: allow an opt-in network lookup to Open Library (no key, sends only the ISBN or title)? Default if no answer: build offline first, lookup off.
2. Money: one home currency, with other currencies stored but not converted? Default if no answer: yes. Which home currency?
3. Money: confirm bank data stays parked (FinanceKit needs a paid account and an App Store Finance app). Default: parked.

## Sources

- [Apple: Get started with FinanceKit](https://developer.apple.com/financekit)
- [Open Library Developer API](https://openlibrary.org/developers/api)
- [Google Books API: Using the API](https://developers.google.com/books/docs/v1/using)
- [Why expense tracking often ends in failure](https://mybanktracker.com/blog/find-my-answers/expense-tracking-ends-failure-116520)
- [Cashew on GitHub (overview)](https://converter.brightcoding.dev/blog/jameskokoskacashew-open-source-flutter-budget-tracker-for-all-platforms)
- [Why I stopped using Goodreads](https://bookishmind.substack.com/p/why-i-stopped-using-goodreads)
- [Reading tracker apps ranked, 2026](https://unstar.app/fr/blog/goodreads-storygraph-fable-hardcover-bookly-reading-tracker-apps-ranked-2026)
- Apple docs: VisionKit DataScannerViewController
