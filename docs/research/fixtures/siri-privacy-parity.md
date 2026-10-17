# Siri privacy parity (P14, P15a, 12:26 pm rulings)

Read against origin/master. Paths: **Ask** = Ask bar (`TessCaptureEngine.capture`, grammar then router); **Tell** = Siri
Tell Tess (`TellTessIntent`, the same pipeline with `TessContext(commitImmediately: true)`, Siri speaks `capture.line`);
**Add** = Siri Add a Task (the type is `CreateTaskIntent`, not `AddTaskIntent`; test `CreateTaskIntent.add(_:startsAt:engine:)`,
Intents.swift:136-145, which speaks `Added “title”.` from `CreateTask.summary`, TrainingActions.swift:445).
Harness: `PrivacyFollowupTests` (now Thu Oct 15 2026, 6:00 pm LA; grammar plus a Claude `Spy`). `KEY` is built at run
time from the Claude key prefix. "Private note" = `CreateNote(isPrivate: true)`, spoken "Private note, kept."
Parity rule: one phrase lands as one kind of object on all three paths, and Siri never speaks a walled phrase.

| id | phrase | path | expected object · spoken | master today (file:line) | status |
|---|---|---|---|---|---|
| S1 | `took advil 400mg` | Ask, Tell | private note · "Private note, kept." | private note: `parseBodyFact` TessGrammar.swift:141, mg rule PrivateFacts.swift:69 | pass |
| S2 | `took advil 400mg` | Add | private note · "Private note, kept." | task, says `Added “took advil 400mg”.` Intents.swift:144 (no `PrivateFacts` check) | FAIL |
| S3 | `take advil 400mg at 9 pm` | Ask, Tell | private note · "Private note, kept." (P15a) | task "Take advil 400mg" at 9 pm, line repeats it: `parseTask` runs first, TessGrammar.swift:141 | FAIL |
| S4 | `take advil 400mg at 9 pm` | Add | private note · "Private note, kept." | task, title spoken, Intents.swift:144 | FAIL |
| S5 | `took advil 400mg yesterday` | Ask, Tell | private note · "Private note, kept." | plain dated note "Advil 400mg", "Noted for Wed.": `parsePastLog` TessGrammar.swift:127 runs before the body check (322-331) | FAIL |
| S6 | `took advil 400mg yesterday` | Add | private note · "Private note, kept." | task, title spoken, Intents.swift:144 | FAIL |
| S7 | `bp 128/82`, `resting hr 52` | Ask, Tell | private note · "Private note, kept." | private note, PrivateFacts.swift:75-77 via TessGrammar.swift:141 | pass |
| S8 | `bp 128/82`, `resting hr 52` | Add | private note · "Private note, kept." | task, title spoken, Intents.swift:144 | FAIL |
| S9 | `slept 6 hours` | Ask, Tell | private note · "Private note, kept." | private note ("slept" is a symptom word, PrivateFacts.swift:58,69) | pass |
| S10 | `slept 6 hours last night` | Ask, Tell | private note · "Private note, kept." | plain note "6 hours" dated Wed, "Noted for Wed.": `parsePastLog` TessGrammar.swift:127, "slept" in `pastVerbs` :311 | FAIL |
| S11 | `slept 6 hours`, `slept 6 hours last night` | Add | private note · "Private note, kept." | task, title spoken, Intents.swift:144 | FAIL |
| S12 | `weigh 82.4 kg` | Ask, Tell | private note · "Private note, kept." | private note, weigh rule PrivateFacts.swift:81-82 | pass |
| S13 | `weighed 82.4 kg this morning` | Ask, Tell | private note · "Private note, kept." | plain note "82.4 kg" dated today: `parsePastLog` TessGrammar.swift:127 ("weighed" ends in -ed, :318) | FAIL |
| S14 | `weigh 82.4 kg`, `weighed 82.4 kg this morning` | Add | private note · "Private note, kept." | task, title spoken, Intents.swift:144 | FAIL |
| S15 | `knee hurts` | Ask, Tell | private note · "Private note, kept." | private note (`healthWithNoNumberIsAPrivateNote`, PrivacyFollowupTests.swift:37) | pass |
| S16 | `knee hurts tonight` | Ask, Tell | private note · "Private note, kept." (P15a) | task "Knee hurts" tonight: `parseTask` first, TessGrammar.swift:141 | FAIL |
| S17 | `knee hurts`, `knee hurts tonight` | Add | private note · "Private note, kept." | task, title spoken, Intents.swift:144 | FAIL |
| S18 | `pay rent $1,800`, `paid 40 for gas` | Ask, Tell | no Claude; object per Q1 · never the amount spoken | grammar returns nil (TessGrammar.swift:117-121), router skips Claude (TessModel.swift:77-79), on-device model or "Didn't catch that." (:101); the miss log keeps the text (TessCaptureEngine.swift:58 checks only key and secret words) | Q1, FAIL (miss log) |
| S19 | `pay rent $1,800`, `paid 40 for gas` | Add | private note · "Private note, kept." (P14) | task, says `Added “pay rent $1,800”.` Intents.swift:144 | FAIL |
| S20 | `pay rent 1800 friday` | Ask, Tell | task Fri (12:13 pm: a day wins over an amount) · line with no title or amount | nil at TessGrammar.swift:117 (`isMoney`, Kitchen.swift:81-87), never reaches `parseTask` | FAIL |
| S21 | `pay rent 1800 friday` | Add | task, title hidden (12:26 pm) · line with no title (Q2) | task, amount spoken, Intents.swift:144 | FAIL |
| S22 | `pay rent friday` | all | task Fri · "Pay rent, Fri …" / `Added “pay rent friday”.` | task (PrivacyFollowupTests.swift:69); Add: task | pass |
| S23 | `pay rent`, `call mom` | Ask, Tell | task in Later · "Pay rent, in Later." | grammar nil (TessGrammar.swift:141), model's call; not walled, so Claude may read it | model |
| S24 | `pay rent`, `call mom` | Add | task · `Added “pay rent”.` | same | pass |
| S25 | `buy milk` | Ask, Tell | groceries (TessGrammar+Kitchen.swift:49-65) | groceries | pass |
| S26 | `buy milk` | Add | task (he asked for a task) | task | pass, Q3 |
| S27 | `wifi password tacocat` | Ask, Tell | private note · "Private note, kept." | private note, TessGrammar.swift:510 | pass |
| S28 | `wifi password tacocat` | Add | private note · "Private note, kept." | task, password spoken: `hasValue` is false (no digit or symbol, SecretWords.swift:52-59), Intents.swift:140 | FAIL |
| S29 | `wifi password is tacocat`, `PIN 4417`, `door code 4417` | all | private note · "Private note, kept." | private note (TessGrammar.swift:510; Intents.swift:140-142; TessTests.swift:230) | pass |
| S30 | `reset my PIN` | Ask, Tell | private note (TessGrammar.swift:510) | private note | pass, Q4 |
| S31 | `reset my PIN` | Add | task, title hidden (12:26 pm) · line with no title | task, says `Added “reset my PIN”.` (TessTests.swift:235 asserts the task) | FAIL, Q4 |
| S32 | `PIN reset friday 3 pm` | Tell | task Fri 3 pm (TessGrammar.swift:500) · line with no title | task, Siri speaks "PIN reset, Fri 3 pm." TessCaptureEngine.swift:296 | FAIL |
| S33 | `PIN reset friday 3 pm` | Add | task, title hidden · line with no title | task, title spoken, Intents.swift:144 | FAIL |
| S34 | `KEY`, `my key is KEY` | all | nothing saved · `claudeKeyLine` | refused: TessModel.swift:69-70; Intents.swift:137-138 | pass |
| S35 | `dentist thu 3 pm` | all | task Thu 3 pm · "Dentist, …" / `Added “dentist thu 3 pm”.` | task | pass |
| S36 | empty, `"   "` | Ask, Tell | nothing saved · "Didn't catch that." | TessGrammar.swift:69, TessModel.swift:101; miss log skips empty | pass |
| S37 | empty, `"   "` | Add | nothing saved · Siri asks for the task | `CreateTask` throws "title is empty" (TrainingActions.swift:429), Siri shows an error | FAIL |
| S38 | any | Add, Tell | `authenticationPolicy == .requiresAuthentication` | not set on either type (Intents.swift:118-123, 149-154) | FAIL |
| S39 | S2 to S33 walled titles | Spotlight, Live Activity | title hidden | no task entity or index on master (Entities.swift: exercises and routines only) | n/a, guard test |

Test shape: Ask/Tell assert `line` and `records.map(\.action)`, plus `store` has no object whose title holds the phrase.
Add asserts the returned line never contains the phrase's number or secret value, and `claude.heard.isEmpty` everywhere.

## Top fails
1. Add skips `PrivateFacts`: every money and body row (S2, S4, S6, S8, S11, S14, S17, S19) saves a task and speaks it. Intents.swift:136-145.
2. Add's secret check is looser than the Ask bar's: `wifi password tacocat` (S28) is a task and is spoken. Intents.swift:140 uses `hasValue`; the Ask bar walls any `mentions` (TessGrammar.swift:488, 510).
3. P15a is wider than line 141: `parsePastLog` (TessGrammar.swift:127) makes plain, unprivate notes of past-tense body facts with a day (S5, S10, S13), and it even drops the verb ("6 hours").
4. Day-wins money rows never become tasks on the Ask bar (S20): TessGrammar.swift:117 returns before `parseTask`.
5. No Face ID on Add or Tell (S38); Tell speaks walled task titles (S32).
6. Walled money misses land in `capture-misses.jsonl` (TessCaptureEngine.swift:58).

## Questions for Product
- Q1: Money with an amount and no day: the ruled Ask bar outcome is the miss line (no Money class yet), but P14 makes Add save a private note. Same object on all three: private note everywhere, or the miss line on Add too?
- Q2: A walled title that is still a task (S20, S21, S31 to S33): what does Siri say? Suggest "Task added for Friday at 3 pm." And does P14's "walled means private note" bow to the 12:13 pm day-wins ruling on Add?
- Q3: Add with `buy milk`: a task (he said "add a task") or groceries like the Ask bar?
- Q4: `reset my PIN`: private note on the Ask bar, task on Add (an existing test asserts that). Which one?
- Q5: A med reminder with a time (S3, S4): a private note loses the 9 pm reminder. Private note, or a task with a hidden title?
