# Cook-phrase gate acceptance rows (N21-N26)

Docs only. Core answered the hold shapes and the router line (see Open items). Sources: research/fixtures/capture-miss-route-eval.md (N21-N26), research/fixtures/decisions-328-332-338.md (K03-K12, G01-G08, D01-D05), product/decisions.md (3:38 PM PT Oct 17 narrowing; 4:14 PM PT Oct 17 cap of 600 characters, line "That's too long to send. Say it shorter."), qa/review-884.md.

## Ruling in one paragraph (Kaushik's capture-miss route, narrowed by Product's 3:38 PM Oct 17 ruling)
While a cook runs, the six cook phrases N21-N26 stay on the phone. They are never sent to Claude through the capture-miss route (#860). Key-shaped text never leaves, with or without a cook. A phrase over 600 characters is refused. An unrelated miss mid-cook (for example "call mom half 7") takes the normal route. Once FinishCooking has run, the six phrases are ordinary misses.

## Setup and how to read the rows
- "Cook running" = a Cook process for a recipe with at least one timer running. "Spy" = the call log (zero Claude requests). "Miss log" = capture-misses.jsonl.
- Key-shaped text is built in test code from two halves (ClaudeSection.fakeKey). It is never written in a doc, a row or a screenshot. Where a row needs it, it says "the Claude key prefix plus filler".
- Receipt wording: lines quoted below are the existing lines in the fixtures. Thing first, then "on". Clocks read "8:30 pm". Private items read "Private note", "Private item", "Private recipe", "Private list".
- A fail is any Claude request for N21-N26 while a cook runs, or the wrong on-phone action.

## A. The six cook phrases, cook running (all must make zero Claude requests)

| Row | Phrase | Expected route | Expected receipt wording | A fail looks like | Test name |
|---|---|---|---|---|---|
| N21 | `8 mins` | On the phone: cook timer, 8 min, linked to the cook. Spy: 0. Miss log: no row | "Timer, 8 min." | Spy shows 1 request; or a task "8 mins" lands; or no timer starts and the line is "Didn't catch that." | `cook_bareMinutesStartsATimer` |
| N22 | `pasta 10` | On the phone: timer "Pasta", 10 min, linked to the cook. Spy: 0 | "Pasta, 10 min." | Spy shows 1 request; or a lift-shaped miss is logged; or the timer is not linked to the cook | `cook_nounNumberStartsATimer` |
| N23 | `finished cooking` | On the phone: FinishCooking runs. Spy: 0 | The existing finish line (no new copy) | Spy shows 1 request; or the cook keeps running after the line shows | `cook_finishedCookingFinishesTheCook` |
| N24 | `how long left` | On the phone: read-only answer, minutes left rounded up. Nothing written. Spy: 0 | Minutes-left line from the timer answer (no new copy) | Spy shows 1 request; or a task or note is written; or the answer rounds down | `cook_howLongLeftAnswersLocally` |
| N25 | `stop the rice` | On the phone: StopKitchenTimer for "Rice". Spy: 0 | The existing stop line for the Rice timer | Spy shows 1 request; or a different timer stops; or Rice keeps running | `cook_stopTheRiceStopsThatTimer` |
| N26 | `step 3` | On the phone: GoToCookStep, index 2 (step 3). No task. Spy: 0 | The step-3 line from Cook (no new copy) | Spy shows 1 request; or a task "Step 3" appears; or the cook stays on its old step | `cook_stepNumberGoesToThatStep` |

## B. Same phrases, no cook (the gate must not apply)

| Row | Phrase | State | Expected route | Expected receipt wording | A fail looks like |
|---|---|---|---|---|---|
| N21-N26 off | each of the six phrases | no cook, or FinishCooking already ran | Normal route: grammar, then on-device model, then Claude (when Claude is on). Plain miss rules apply and the miss log may take a row | Whatever the normal route gives (for `step 3`, possibly a task; for `pasta 10`, a lift-shaped miss) | The phrase is held on the phone with no cook running, or is swallowed with "Didn't catch that." without trying the normal route. Test: `cook_cookPhrasesWithoutACookTakeTheNormalRoute` |
| N-plural | `timers` with a cook running | cook running | Counts as a cook phrase, held on the phone | Same on-phone answer as a timer phrase | Plural slips past the keyword guard and goes to Claude. Test: `cook_pluralTimersIsACookPhrase` |

## C. Dropped cook phrase (held, but no local reading can act on it)

| Row | Phrase | State | Expected route | Expected receipt wording | A fail looks like |
|---|---|---|---|---|---|
| D01 | `stop the pasta` (no timer named pasta is running) | cook running | Held on the phone. Spy: 0. Not queued in the inbox. Not in the miss log. No haptic. No retry | "Didn't catch that." exactly (PROPOSED: this line for a held cook phrase with no local reading is not yet ruled) | The phrase reaches Claude; or any suffix such as "Try ..." is added; or a miss row is logged; or a haptic fires; or the phrase is queued and re-sent later |

## D. Key-shaped text (never leaves, with or without a cook)

| Row | Phrase | State | Expected route | Expected receipt wording | A fail looks like |
|---|---|---|---|---|---|
| KEY-1 | `8 mins` with the Claude key prefix plus filler added before it (built in test code) | cook running | Refused first by the key-shape check, before the cook gate and before any route. Spy: 0. Not logged. Key text never in a request, the miss log or the sent log | The existing key line, or "Didn't catch that." where the route returns it (CM11) | Any request is built; or the miss log or sent log holds the key text; or the cook gate answers the "8 mins" part and keeps the key text |
| KEY-2 | `pasta 10` with the Claude key prefix plus filler (test code) | no cook | Same wall: refused before any route. Spy: 0 | Same as KEY-1 | A request carries the key text |
| KEY-3 | `step 3` with a key-shaped string pasted after it (test code) | cook running | Refused, not read as step 3. Cook stays on its step | Same as KEY-1 | The cook jumps to step 3 and the key text goes anywhere |

## E. Length cap (600 characters)

| Row | Phrase | State | Expected route | Expected receipt wording | A fail looks like |
|---|---|---|---|---|---|
| LEN-1 | A phrase of exactly 600 characters, ending in `step 3` | cook running | Not refused by the cap. The cook gate handles it on the phone. Spy: 0 | Step line, as N26 | The cap refuses at 600 (off by one) |
| LEN-2 | A phrase of 601 characters, ending in `step 3` | cook running | Refused. Spy: 0. Not written. Miss log skips it (refusals are not logged). Once, no haptic, no retry | "That's too long to send. Say it shorter." | The phrase is sent; or the cook jumps to step 3; or the old line "That's long. Keep it as a note?" or a 500-character cap shows (superseded 4:14 PM PT Oct 17); or the text lands in the miss log |
| LEN-3 | A 700-character phrase with no cook phrase in it | cook running | Refused the same way | "That's too long to send. Say it shorter." | Reaches Claude, or reaches the normal route |
| LEN-4 | A phrase of 601 characters with key-shaped text inside (test code) | cook running | Key check wins. Nothing sent, nothing logged | Key line, not "That's too long to send. Say it shorter." | The cap line shows and the key text is stored anywhere |

## F. Not held (the narrowing; the gate is the six cook phrases only)

| Row | Phrase | State | Expected route | Expected receipt wording | A fail looks like |
|---|---|---|---|---|---|
| G01 | `call mom half 7` | cook running | Normal route. Grammar first, then the model. May become a dated task | Task thing-first, with the time as "7:30 pm" in any line that shows a clock | Held on the phone with "Didn't catch that." (this is how #884 behaved as built) |
| G02 | `dentist by 4.15` | cook running | Normal route; the clock rule reads it as a time (not money) | Clock shown as "4:15 pm" if the context gives pm, else as spoken | Held; or masked as money |
| G03 | `buy milk` | cook running | Groceries as usual | The usual add line, item on Groceries | Held mid-cook |
| G04 | `bench 80 x 8` | cook running | Normal route | The usual lift line or the usual miss | Held mid-cook |
| G05 | A walled phrase (a money amount) | cook running | Walled rules exactly as without a cook | "Private item, on Groceries." only where the grammar can place it; else "Didn't catch that." | The wall behaves differently with a cook, or the amount reaches Claude |
| G06 | `how long is the flight`, `call mom half 7` | cook running | **At #884 (5665c600) the hold is all or nothing**: while a cook is the running process no phrase of any kind goes to Claude (TessModel.swift:102-107), so both are held and end at "Didn't catch that." (TessModel.swift:129). **After Core's narrowing PR** (branch from #884): normal route, because only N21-N26 are cook phrases | #884: "Didn't catch that." After the narrowing PR: the normal route's line | Judged against the wrong build; or, after the narrowing PR, treated as N24 and answered with minutes left |
| G07 | `step on the scale`, `step counter` | cook running | Same split as G06: held at #884; normal route after the narrowing PR (a cook phrase is "step N" only) | #884: "Didn't catch that." After: the normal route's line | After the narrowing PR, treated as N26 |

## Cross-checks for every row above
- The sent log gets no row for any phrase held on the phone.
- The "What was sent" row in Claude settings shows nothing new after N21-N26.
- Offline: same result (the held rows need no network).
- Spend meter does not move for N21-N26.

## Open items for the Kitchen lead
- Answered by Core at #884 5665c600: the hold is all or nothing (TessModel.swift:98-107); a phrase containing "timer" or "timers" is held with or without a cook (TessModel.swift:98-99). The narrowing to N21-N26 comes in Core's next PR; run F (G01-G08) against that PR, not #884.
- There is no new key line: the grammar and the on-device model try first, an unread phrase ends at TessModel.swift:129 with "Didn't catch that." plus the context example (a shop adds ' Try "milk, eggs".', a workout ' Try "80 × 8".'). Nothing is written, no retry copy. Rows D01 and the context suffix are proposed, not ruled.
- Existing quoted lines ("Timer, 8 min.", "Pasta, 10 min.") are kept as the fixtures have them. Flag if Kitchen wants the timer lines to read "Timer on Cook, 8 min." instead.
