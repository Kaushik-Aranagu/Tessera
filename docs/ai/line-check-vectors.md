# TessLineCheck: test vectors and ownership

For: Core (AI-3, ship list). Owner: AI architecture team. Date: Oct 16, 2026 (Pacific).

Sources: `TesseraCore/Sources/TesseraTess/PlanWording.swift` (`PlanProposalValidator`), `TesseraCore/Sources/TesseraTess/TessCapturing.swift` (`TessVoice`), `TesseraCore/Sources/TesseraCore/Home/HomeLines.swift` (`HomeLine`, `HomeFact`, `HomeLines`), `TesseraCore/Sources/TesseraCore/Notes/SecretWords.swift`, `TesseraCore/Sources/TesseraCore/Diagnostics/ClaudeKeyGuard.swift` (`looksLikeClaudeKey`), `TesseraCore/Sources/TesseraCore/Tess/TessMemory.swift` (`TessMemoryScreen`), `docs/ai/home-lines.md` section 2, `docs/research/ai5-home-lines-eval.md` (C1-C14, D2), `docs/ai/memory-experiment.md` "Result and decision", `docs/ai/architecture.md` sections 5.4 and 7.

`TessLineCheck` is the one on-phone check every Claude-written Tess line passes before it shows. Any failed check keeps that item's rules line, and nothing visible happens. Core lifts it out of `PlanProposalValidator` as one small PR.

## What TessLineCheck owns

- **Empty line.** A nil or blank line (Claude skipped the tool, or sent nothing for the item) gives `.noLine`. The rules line stays. Not a failure, not logged as a miss.
- **Slot shape (C2, C3, C4, C5).** Input: the line and its slot. Context: 6 words or fewer, 32 characters or fewer, no stop at the end (`.`, `:` or `;`). Detail (SO FAR): 14 words or fewer, 80 characters or fewer, exactly one sentence, shown with no stop (Kaushik, Oct 26: a closing `.` is let through and dropped by `ShownLine.unstopped` before it shows). Both: no `!`, `…`, newline or emoji. Caps come from `HomeLines.contextWords`, `contextCharacters`, `detailWords`, `detailCharacters`; `HomeLines.fitsContext` and `fitsDetail` are the start.
- **Licensed digits (C6, C7, C8).** Input: the item's `HomeLine.numbers` and the rules line. Every digit group must be in `numbers`. Every digit group in the rules line survives, except D2: on a done item the context line may drop its whole clock time. No number words. The time and length parsing comes from `PlanProposalValidator.numbersAreLicensed`, which moves here.
- **Names (C9).** Input: the pack's `names` for the item (`HomeFact.names`: title, exercise in focus, records). A capitalised word must be one of those names' words, with the exemptions below.
- **Grading and voice (C10, C11).** `TessVoice.bannedWords` plus `PlanProposalValidator.planBanned` and `planBannedPhrases`, plus the words home-lines.md section 2 adds: still, streak, should, finally. "record" fails; the house word is "best".
- **Off limits (C12).** Health and body: `PlanProposalValidator.healthWords` and `TessMemoryScreen.healthWords`, plus "body". Money: `TessMemoryScreen.moneyWords`. Places and shops: `TessMemoryScreen.placeWords`. A word in the item's own title is allowed (as V12 allows title words today).
- **Greetings and apologies.** `TessVoice.violations` catches "sorry" and "oops"; the check adds hi, hello, hey and "good morning" as a greeting at the start, and apologize. A bare "Morning" that starts a line is not a greeting.
- **No-repeat rule (context line only).** Input: the day label and the hero. The context line may not carry the day label's weekday, the item's title as a phrase ("Push A"), or a state word the hero already shows ("done", "paused", "finished").
- **Secret wall.** `SecretWords.mentions` and `looksLikeClaudeKey` on the line. Either one fails it.
- **Stays in `PlanProposalValidator`:** V1 to V8 (ids, same blocks, fixed blocks, runs back to back, window, overlap, ghost lines, start-with) and V13 (other names, training on a rest day). It calls `TessLineCheck` for the line rules (today's V9 to V12) and keeps its V-codes. The plan tests must still pass unchanged.

Suggested signature (suggested only, nothing like it exists yet):

```swift
public enum TessLineCheck {
    public enum Slot { case context, detail, planLine }
    public enum Verdict: Equatable { case pass, noLine, fail([String]) } // C-ids or V-codes
    public static func check(_ line: String?, slot: Slot, numbers: [Int], names: [String],
                             rulesLine: String?, isDone: Bool, dayLabel: String?, hero: String?) -> Verdict
}
```

## Vectors: context line (6 words, 32 characters, no stop)

Unless the row says otherwise, the item is planned Push A: hero "Push A", day label "Thursday night", rules context "this evening", numbers `[]`, names `["Push A"]`. "Done" means hero "Push A done", rules context "7:40 pm", numbers `[3, 12, 7, 40, 1]`, names `["Push A", "Bench"]`.

| id | line | numbers | names | day label / hero | expect | check |
|---|---|---|---|---|---|---|
| L1 | this evening, your usual slot | [] | Push A | default | pass | all |
| L2 | this evening, at your usual time | [] | Push A | default | pass | C2, C3 at the cap (6 words, 32 chars) |
| L3 | tonight, at the time you like it | [] | Push A | default | fail | C2, 7 words (32 chars) |
| L4 | this evening, at your normal time | [] | Push A | default | fail | C3, 33 chars (6 words) |
| L5 | this evening, your usual slot. | [] | Push A | default | fail | C4, stop on a context line |
| L6 | your usual 6 pm slot | [] | Push A | default | fail | C6, "6 pm" leaked from memory |
| L7 | a bench best | done | Push A, Bench | done | pass | C7 via D2, clock dropped on a done item |
| L8 | 7:40 pm, a bench best | done | Push A, Bench | done | pass | C6, C7 |
| L9 | 7 pm, a bench best | done | Push A, Bench | done | fail | C7, part of the clock kept, 40 lost |
| L10 | first in 9 days | [9] | Push A | default | pass | C6 |
| L11 | missed yesterday, today instead | [] | Push A | default | fail | C10 missed |
| L12 | a little behind today | [] | Push A | default | fail | C10 behind |
| L13 | a late start today | [] | Push A | default | fail | C10 late |
| L14 | this evening, again | [] | Push A | default | fail | C10 again |
| L15 | only 2 left | [2] | Groceries | hero "Groceries, 2 left" | fail | C10 only |
| L16 | still on for today | [] | Push A | default | fail | C10 still (H6) |
| L17 | keep the streak going | [] | Push A | default | fail | C10 streak |
| L18 | you should go tonight | [] | Push A | default | fail | C10 should |
| L19 | finally, a bench best | done | Push A, Bench | done | fail | C10 finally |
| L20 | a bench record | done | Push A, Bench | done | fail | house word: "best", never "record" |
| L21 | today, if energy allows | [] | Push A | default | fail | C12 health |
| L22 | this evening, rest the body | [] | Push A | default | fail | C12 body |
| L23 | 4 left, little spent | [4] | Groceries | hero "Groceries, 4 left" | fail | C12 money ("spent") |
| L24 | this evening, down the road | [] | Push A | default | fail | C12 place ("road") |
| L25 | this evening, your slot! | [] | Push A | default | fail | C5 "!" |
| L26 | this evening 💪 | [] | Push A | default | fail | C5 emoji |
| L27 | Hi, this evening | [] | Push A | default | fail | greeting |
| L28 | sorry, this evening now | [] | Push A | default | fail | apology (`TessVoice.bannedWords`) |
| L29 | two left at the store | [2] | Groceries | hero "Groceries, 2 left" | fail | C8 number word |
| L30 | Thursday, your usual slot | [] | Push A | label "Thursday night" | fail | no-repeat, weekday in the day label |
| L31 | Push A, this evening | [] | Push A | default | fail | no-repeat, title in the hero |
| L32 | done at 7:40 pm | done | Push A, Bench | done | fail | no-repeat, "done" in the hero |
| L33 | this evening, then Push B | [] | Push A | default | fail | C9, "B" is not in the pack's names |
| L34 | this evening, with Sarah | [] | Push A | default | fail | C9 invented name (and a person) |
| L35 | Your usual slot | [] | Push A | default | pass | C9, sentence-initial word |
| L36 | today, a Cook day | [] | Rest day | hero "Rest day", label "Sunday" | fail | C9, capital mid-sentence |
| L37 | your wifi code is 4417 | [] | Push A | default | fail | secret wall (`SecretWords`), C6 |
| L38 | (empty) | [] | Push A | default | `.noLine` | rules line "this evening" stays |

## Vectors: detail, the SO FAR sentence (14 words, 80 characters, one stop)

Unless the row says otherwise, the item is the done Push A above, with rules detail "3 exercises, 12 sets, 1 new best." (so 3, 12 and 1 must survive). No-repeat does not apply to the detail.

| id | line | numbers | names | expect | check |
|---|---|---|---|---|---|
| L39 | You got through 3 exercises and 12 sets, with 1 new bench best today. | done | Push A, Bench; house day = the finish's day | pass | C2 at the cap, 14 words; "today" passes only with a house day (C15), with none it fails closed |
| L40 | You got through all 3 exercises and 12 sets, with 1 new bench best today. | done | Push A, Bench | fail | C2, 15 words |
| L41 | Bench, incline barbell press, cable crossover: 3 exercises, 12 sets, 1 new best. | done | Push A, Bench, incline barbell press, cable crossover | pass | C3 at the cap, 80 chars |
| L42 | Bench, incline barbell press, cable crossovers: 3 exercises, 12 sets, 1 new best. | done | Push A, Bench, incline barbell press, cable crossovers | fail | C3, 81 chars |
| L43 | 3 exercises, 12 sets, 1 new best | done | Push A, Bench | pass | shown with no stop (Oct 26) |
| L44 | 3 exercises, 12 sets. 1 new best. | done | Push A, Bench | fail | C4, two sentences |
| L45 | 3 exercises and 1 new best. | done | Push A, Bench | fail | C7, 12 dropped (no D2 on a detail) |
| L46 | 3 exercises, 12 sets, 2 new bests. | done | Push A, Bench | fail | C6, 2 not licensed |
| L47 | It went to plan: 3 exercises, 12 sets, 1 new best. | done | Push A, Bench | pass | C9, "It" starts the sentence |
| L48 | 3 exercises, 12 sets, 1 new best with Sarah. | done | Push A, Bench | fail | C9 invented name |
| L49 | 3 exercises, 12 sets, 1 new best, on little sleep. | done | Push A, Bench | fail | C12 health |
| L50 | 3 exercises, 12 sets, 1 new bench record. | done | Push A, Bench | fail | "record" |
| L51 | Cook day, with 2 to buy. | [2] | Tacos | pass | C9 sentence-initial, C6 (planned cook, no rules detail) |
| L52 | Last trained on a Monday, 9 days ago. | [9] | Push A | pass | C9 weekday exempt (planned, no rules detail) |
| L53 | Back for the first time since March. | [] | Push A | pass | C9 month exempt (planned, no rules detail) |
| L54 | Saved your key, (the Claude key prefix)7Q2. | [] | Push A | fail | secret wall (`looksLikeClaudeKey`) |

## Vectors: plan lines (the shared part only)

Plan pack: blocks at 7:30 am and 5 pm, block lengths 30 min, titles "Email", "Reading". Today's V-code in brackets; the codes must not change.

| id | line | expect | check |
|---|---|---|---|
| P1 | Email first, then 30 min of reading. | pass | V11 length licensed |
| P2 | Start at 7:30 am, before the rest. | pass | V11 time licensed |
| P3 | Start at 6 am. | fail | V11 (C6) time not in the plan |
| P4 | Reading at 17:00. | fail | V11, clock with no am/pm |
| P5 | Catch up on email after lunch. | fail | V10 phrase "catch up" |
| P6 | Go easy, you slept badly. | fail | V10 "go easy", V12 (C12) "slept" |
| P7 | Awesome, a great start! | fail | V9, `TessVoice` ("!", "great", "awesome") |

## Exemptions (names check, C9)

The names check looks at every word that starts with a capital letter. It skips exactly these:

1. The first word of each sentence: the first word of the line, and the first word after `. ` or `? `. A word after `:` or `,` is not a sentence start. "Cook day.", "Your usual slot", "Usual time", "Morning session", "It went to plan" all pass.
2. Weekdays: Sunday to Saturday (the list in `HomeLines.weekdays`).
3. Months: January to December.
4. Words of the pack's `names` for that item ("Push", "A", "Bench" for a done Push A with a bench best).

A capitalised word mid-sentence that is not in that list still fails: "today, a Cook day" (L36), "then Push B" when only Push A is in the pack (L33), "with Sarah" (L34). Lowercase words are never checked as names.

## Where the code and the docs disagree

- `TessVoice.violations` fails any line of 12 words or more. The detail slot allows 14 (L39 passes the slot but fails `TessVoice`). `TessLineCheck` must take the word cap from the slot, not from `TessVoice`; plan lines keep `TessVoice` as is.
- No word list in code holds "still", "record", "body", or any greeting. `planBanned` has no "streak" or "should" (only `TessVoice.bannedWords` does). "still" is in no list at all.
- `PlanProposalValidator.healthWords` is shorter than `TessMemoryScreen.healthWords` (no pain, weight, kg, lb).
- `HomeLines.fitsContext` only refuses a trailing `.`, not `:` or `;` (C4).
- `fixtures/home-lines-eval.json` `allowedNamesAlways` holds "Push", "Pull", "Legs", "A", "B", so the eval's C9 passes "Push B" (L33). This sheet fails it.
- Read word by word, the no-repeat rule would fail home-lines.md's own examples ("a bench best" under "Push A done", "today, a cook day" under "Rest day"). This sheet reads it as weekday, title phrase and state word.
- No months list exists in code yet.

## Added in the build (Core 0t, #652 and #655; Oct 17)

The code is the owner of these; this sheet records what the vectors above rely on.

- **C15, the house-day check, done items only.** A weekday name or relative-day word ("yesterday", "today", "tonight", "tomorrow", "last night", "this morning", "this evening") must be supported by the finish's house day (4 am turnover). "usual", "usually", "as usual", "after work" and "before work" fail outright. With no house day passed it fails closed. Part of day comes from the finish time, not the label. Planned items keep L1, L2 and L52 as written.
- **Times the facts can't show** (also C15): last/this week, weekend, lately, recently, earlier, midnight, dawn, dusk, sunrise, sunset, lunch, dinner, breakfast, bedtime, this/last year.
- **CLOCK.** Every clock reads "7:40 pm" or "7 pm" (12-hour, a space, am or pm); "7:40pm", "19:40", "7.40 pm" and "7:4 pm" fail.
- **C6 per noun.** Digits are compared as values, and a counted noun takes only the values the facts give it: days since, exercises, sets, bests. "first in 3 days" fails when 3 is the exercise count and the gap is 9. "4 of 5 exercises": the 5 is the plan, licensed by `numbers`.
- **C9 and names.** Exercise names a line may use must be in the item's names, so L41 and L42 list their lifts there and stay a pure length test (C3).
- **C12 with his weight.** The engine's own wall runs on the line with his last weigh-in.
- **C13.** US English: a British spelling (house list, -ise/-isation and -our stems) fails; a short American list (promising, surprising, praising, supervised, supervising, advising) is exempt.
- **Named checks:** HOUSE ("record" for "best"), GREET, NOREPEAT, SECRET. C1 is the whole-reply check (`replyProblems`).
- **Home done job on Sonnet** uses `tool_choice` auto: Sonnet 5.5 refuses a forced tool. 0 of 192 eval items came back with no tool call; a miss lands as C1 and keeps the rules line.
