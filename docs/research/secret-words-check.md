# Secret words on master: a check against 134 (board item 139)

For: Core and QA. Owner: Research lab. Date: Oct 16, 2026 (Pacific). Master read at bb7f082 (#422 merged as 5af8f2c, QA fixes 88423d3). Traced by hand, nothing was run. Every value is a made-up placeholder.

Rulings since #422: R7/SW3 now reads "Private note, kept. It stays out of my memory." Q1: a private note rides in his iCloud backup, never into memory, recent lines, packs or the miss log.

**Summary:** 27 rows: 19 ✓, 5 differ, 3 untested. The engine work is solid: parse order, the router gate, CreateNote/EditNote privacy and the turnover guard all hold. The real gaps are paths #422 didn't touch: the Claude inbox drain skips the router gate, notes and miss-log lines written before #422 keep the words, and Plan my day sends task titles that hold a secret word.

## 1. Lines and rules

Tests are `SecretWordsTests.swift` (ST). Paths: TessGrammar (TG), TessCaptureEngine (TCE), TessModel (TM), Notes (N), all under `TesseraCore/Sources`.

| # | Expected (fixture) | Master now (file:line) | Verdict |
|---|---|---|---|
| S1 | wifi password is tacocat: private note | "is" plus a word, SecretWords.swift:48-49; TG:71; ST:70 | ✓ |
| S2 | wifi: TacoNet / tacocat24: private note | "wifi" before ":" counts, SecretWords.swift:27-28; ST:70 | ✓ |
| S3 | door code 4417 | Digit after the word, SecretWords.swift:52; ST:70 | ✓ |
| S4 | the gate code is 2580 | "is" path; ST:70 | ✓ |
| S5 | my PIN is 0420 | "is" path; ST:71 | ✓ |
| S6 | Spoken passcode, digits said; also out of the transcript buffer | Typed form tested (ST:71). Spoken path: no case, and the Heard line shows it (see §2) | untested |
| S7 | note: wifi password is tacocat: private note, before `parseNote` | parseSecret first, TG:70-72, strips "note:" TG:475-476; Day log ST:141-152 | ✓ |
| S8 | remember …: private note, "Private note, kept. It stays out of my memory." | Note made, memory empty (ST:87-96), but the line is the old one, TCE:300 | differs |
| S9 | netflix password hunter2 | Digit path; ST:72 | ✓ |
| S10 | alarm code 9 9 1 2 | Digit path; ST:72 | ✓ |
| S11 | what's the wifi password?: opens the matching private note | Says "It's in your private notes." and opens nothing, TG:481-482; ST:106-107. Nothing reaches a model | differs |
| S12 | password reset email friday: task, Friday 9 am | No value, `parseTask`, TG:484; ST:100-101 (title only, not the time) | ✓ |
| S13 | change the wifi password tomorrow: task | Same path as S12; no case | untested |
| S14 | todo: reset my PIN: task | TG:484; ST:104-105 | ✓ |
| S15 | call mom about the wifi password: private note | No value, no task shape, TG:487; ST:72 | ✓ |
| S16 | zip code 94110: private note | ST:72 | ✓ |
| S17 | promo code SAVE20 for target: private note | ST:73 | ✓ |
| S18 | code review friday 3pm: task | ST:102-103 | ✓ |
| S19 | pinch of salt: not caught | Whole words, SecretWords.swift:11-24; ST:110 | ✓ |
| S20 | garage 4417: not caught | ST:111 | ✓ |
| R1 | First in `parse`, after the wake word; no router, no miss log | TG:62-72; models gated TM:73-75; miss log gated TCE:57-58 (the miss-log gate has no case: tests call the router, in memory) | ✓ |
| R2 | password, passcode, pin, wifi password, code, combo, "wifi" before ":"/"is"; whole words | SecretWords.swift:11-12 adds plurals, passphrase, combination. "combo" and "wifi is" have no case. Wider list catches "rolling pin", "bobby pins" (groceries become private notes) | ✓ |
| R3 | A value: digit, mixed token, 3+ spoken digits, any word after "is"/":" | SecretWords.swift:39-62. Spoken-digit and symbol-only branches have no case (S6 hits the "is" branch) | untested |
| R4 | No value: task shape stays a task; nothing with a secret word leaves the phone | Grammar ✓ (TG:484). But Plan my day packs task titles, PlanWording.swift:77, so "Reset my PIN" reaches Claude | differs |
| R5 | "Private note" everywhere outside the note | New notes ✓ (N:106-113, DayStory.swift:345-347, Turnover:65-67, pack TessMemory.swift:472). Notes written before #422 keep the words in their title: no migration, and ST:153-154 says "an older note" but makes "plain note" | differs |
| R6 | "Private note, kept.", UNDO 4 s, never repeats the value | TCE:300; ST:78. UNDO is UI (BottomChrome.swift:708) | ✓ |
| R7 | Memory: never a memory line; the new line | Refused, TessMemory.swift:139-140; ST:91-95. Line is the old one | differs |

## 2. Leak paths #422 may have missed

| Where | What leaks | Default proposed fix | Owner |
|---|---|---|---|
| Claude inbox drain, `TessInbox.swift:56-78`; `add` at :25-29 blocks only the key | `readWaiting` calls `claude.run` directly, past the router gate. A phrase saved offline before #422 ("door code 4417") goes to Claude on the next open | `add` and `readWaiting` skip any phrase where `SecretWords.mentions`; one pass turns waiting ones into private notes | Core |
| Notes written before #422 | Title holds the words: Day log "Note: …" (DayStory.swift:347), week best lines (WeekFacts.swift:152), Notes list. Memory is guarded (Turnover:67) | One additive pass at launch: a note whose body mentions a secret word gets `isPrivate` and the "Private note" title. A real case for ST:153 | Core, QA |
| Miss log `capture-misses.jsonl` (CaptureMissLog.swift:31) | Lines missed before #422 keep the words | One scrub drops lines where `mentions` is true | Core |
| Plan my day pack, PlanWording.swift:77 and title words :286 | Task titles with a secret word (S12 to S14, S18); event titles when they are sent | A title with a secret word goes as "Private task" | Core (AI) |
| Spoken transcript (S6): SpeakLayer.swift:25, SpeechListener.swift:42, :143 | "Heard: my passcode is 1234" on screen while the ghost dries; `heard` stays in memory until the next listen (reset only at :114). Recognition is on-device (:124), so nothing leaves the phone | Heard line reads "Heard: Private note" when `mentions`; clear `heard` at `stop` | Design, Core |
| "what's the wifi password?" (TG:481) | Nothing leaks; it just doesn't open the note | Open the matching private note on the Notes page | Core, Design |
| Op summaries (SW5): N:127-129, :178-181 | Nothing: both read "Private note"; tested ST:83, :121 | None | n/a |
| Op body ops and export JSON, TesseraExport.swift:136-139 | The body sits in the note's values and in its set-body ops | None (Q1 allows it in his backup). QA §3 must expect two hits per note in the export | QA |
| Edits, N:151-167 | Nothing: a plain note that gains a code flips to private, drops links; a private note never flips back. Tested ST:114-139 | None | n/a |
| Note made by Claude or the model, TessTools.swift:181-184 | Nothing: `CreateNote` forces privacy on `mentions` (N:106-107). No case with a `.claude` actor | Add one case | QA |
| Undo text | Nothing: UNDO rides Tess's line | None | n/a |
| Spotlight, widgets, Lock Screen, Live Activity, notifications, search | Nothing today: entities are exercises and routines only (TesseraIntents/Entities.swift), the one widget is the rest timer, no notification or note search code | Any future note surface reads the title, never the body | Core |
| Notes list row, Features/Notes/NotesView.swift:173-174 | Line 2 of a private note's body shows under "Private note" | Accept (it's the Notes page), or hide `rest` when private | Design |

## 3. Old wording to change to "Private note, kept. It stays out of my memory."

- `TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:300` (the line he hears)
- `TesseraCore/Sources/TesseraCore/Tess/TessMemory.swift:124` (`Refusal.secret.line`; shown nowhere today, so "It stays out of my memory." alone may read better there, since no note is made on that path) and its comment at :116
- `TesseraCore/Sources/TesseraTess/TessGrammar.swift:20` (doc comment)
- `TesseraCore/Tests/TesseraCoreTests/SecretWordsTests.swift:89` and `:92`
- `docs/research/next-build-script.md:58`
- Leave as history: `docs/qa/review-422.md:30`, `docs/research/fixtures/note-task-list-edges.md:61`
