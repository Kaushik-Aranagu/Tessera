# Memory fixtures for TessMemoryStore (board item 119)

For: Core (#356, `core/tess-memory` at e098e7e), with Builder B (AI-9) and the AI thread. Owner: Research lab.
Date: Oct 16, 2026 (Pacific). The calls these rows follow:
- Design 49 `tess-knows.md` and its addendum d73cba4;
- the AI thread's #357 (architecture section 4: groups Training, Kitchen, People and About you; text in the second person; `valueRanges`; no week lines, recent stops at 14 days; a rule id and suppression per noticed pattern; "used" is any read; told health lines kept private; places refused; the forget log re-applied after a restore);
- Research's `tess-knows-trace.md` (M1 to M12).

The "#356 today" column is a hand trace of `TessMemory.swift` and `TessMemory+Turnover.swift` at e098e7e. There is no Swift toolchain here, so nothing was run.

**Summary:**
- 9 of the 12 acceptance rows fail on #356 today.
- 11 of the 20 screen rows misfire, mostly from substring matches (plus S4, where only the group word is wrong).
- The biggest gap: after "Forget everything", the noticed lines come back the **next morning**, not the next Sunday. `turnover` recomputes whenever `lines(of: .noticed).isEmpty` (`TessMemory+Turnover.swift`, the `|| lines(of: .noticed).isEmpty` clause).

## 1. Acceptance rows (M1 to M12, with today's calls)

| # | Do | Expect | #356 today |
|---|---|---|---|
| M1 | "remember that I rest on Sundays" | Kept after the 2 s dry. Text "You rest on Sundays." (second person, stored that way). Group Training. `valueRanges` covers "rest on Sundays". Source "you said so today". Count +1. Tess: "Kept. You rest on Sundays." with UNDO | **Partly.** Kept and the receipt is right, but it lands in **Other**: `guessArea` has "rest day" and not "rest", so "I rest on Sundays" matches nothing. But the text is stored as he said it ("I rest on Sundays") and converted on display. There is no `valueRanges` field |
| M2 | FORGET that line, wait 10 s | Object gone. Its words gone from every op: the memory's create and setTitle, the receipt summary, **and the capture op that carried "remember that I rest on Sundays"** | **Partly.** `redact` scrubs ops whose `objectIDs` contain the memory, by exact title. The capture's raw sentence ("remember that I rest on Sundays") isn't the title, so if the capture op or the miss log keeps the raw input, it survives. Needs a test that greps every op for "rest on Sundays" after the redact |
| M3 | FORGET "You usually train 6 to 8 pm." (noticed), then run the turnover on a Sunday, then on a weekday | Stays gone both times. A suppression keyed by the rule id, no text | **Fails.** No rule ids and no suppression. Sunday recomputes it, and so does **any** day once the noticed lines are empty |
| M4 | "remember my left shoulder gets sore on overhead pressing" | Kept, `isPrivate`, source "…, stays on this phone". Tess: "Kept, on this phone only." Absent from every `pack` | **Passes** for this sentence (body word "shoulder" lets the health word through). The receipt says "Kept. Your left shoulder gets sore on overhead pressing." not "Kept, on this phone only." |
| M5 | "remember I spent $40 at Trader Joe's" | Refused, nothing written. Tess: "I don't keep sums of money." | **Passes** (money: "$"/"spent"). Tess's line depends on how the refusal is worded upstream |
| M6 | Claude's `remember` on a miss | Ghost row with KEEP / NOT NOW, nothing written until KEEP. NOT NOW leaves nothing | **Not in #356.** `RememberFact` writes on apply; the ghost path is the caller's. Test with `pending: true` and NOT NOW |
| M7 | Forget everything, UNDO within 10 s | Every line back. Tess's line was "Everything forgotten, 12 things." | **Partly.** One op, so UNDO restores everything. The summary is "Everything forgotten." with no count (`ForgetAllMemory.summary`) |
| M8 | Forget everything, wait, restore yesterday's backup | Forgotten lines stay forgotten (the forget log re-applied) | **Fails.** No forget log yet |
| M9 | Day 2 after install, 1 day line, nothing else | Count line "Nothing kept yet.". The page has one group, The last 14 days | **Fails.** `countLine()` says "Nothing yet." whenever told + noticed is 0. Groups come back right |
| M10 | 41st told line, all 40 used in the last 90 days | Not kept. Tess: "I keep 40 things. Forget one and say it again." | **Fails.** `RememberFact` writes it, and `trimTold` at 04:00 finds nothing stale, so he keeps 41, then 42 |
| M11 | Siri: "remember that I like tacos" | "Say that in Tessera and I'll keep it.", nothing written | Not in #356 (the intent's side). Test row for the intent PR |
| M12 | "what do you know" at zero | "Nothing yet. Say "remember that…" and I'll keep it." | Not in #356 (the phrase). `countWord()` "Nothing yet" is right for Settings |

## 2. The screen: what is kept, kept private, or refused

The expect column follows #357. In the "#356 today" column, private means `isPrivate`; refused means `ActionError` with its reason.

| # | He says ("remember that …") | Expect | #356 today |
|---|---|---|---|
| S1 | I train after work on weekdays | kept, Training | kept, Training |
| S2 | mom's birthday is Oct 9 | kept, People, digit 9 licensed by his words | kept, People |
| S3 | Tacos means the sheet-pan tacos | kept, Kitchen | kept, **People** (no kitchen word matches; "means" is in the people list) |
| S4 | I work 9 to 5 | kept, About you | kept, **Other** (the group word should be "About you") |
| S5 | my left knee clicks on squats | kept, private | kept, private |
| S6 | my energy is low in the mornings | kept, private, "Kept, on this phone only." | **refused** (health "energy", and no body word to let it through) |
| S7 | I slept badly this week | kept, private | **refused** (health "slept") |
| S8 | my resting heart rate is 52 | refused: a measured value (digits next to a health word) | refused (health "heart") ✓ |
| S9 | I weigh 82.4 kg | refused: a measured value | refused ✓ |
| S10 | call mom back on Sundays | kept, People, **not** private | kept, People, **private**: "back" is in the body words, and `contains` matches it. Never packed |
| S11 | send mom a card for her birthday | kept, People | **refused as money** ("card") |
| S12 | I shop at Trader Joe's on Saturdays | refused: "I don't keep places." | refused **as money** ("trader"). The reason is wrong, so Tess would say the money line |
| S13 | I target 3 workouts a week | kept, Training | **refused as money** ("target") |
| S14 | my chili recipe has 7 steps | kept, Kitchen | **refused** (health "steps") |
| S15 | my key is sk-ant-… (any) | refused, never echoed | refused (`looksLikeKey`) ✓. Tess's line must not repeat the words |
| S16 | I don't eat pork | kept, Kitchen | kept, **Kitchen** ("eat") ✓ |
| S17 | it's too hot to train when the sun sets late | kept, Training | kept, Training (via "train") ✓ |
| S18 | I like espresso after lunch | kept, Kitchen | **Training**: "press" in "espresso" matches first |
| S19 | the weather is great on Sundays | kept, About you | **Kitchen**: "eat" in "weather" and "great" |
| S20 | my sunset walk is my rest | kept, About you | **Training**: "set" in "sunset" |

Fix shapes, Core's choice:
- Match whole words for both the screen and `guessArea` (as `TessMemoryScreen` already tokenises), and do the same for `bodyWords` in `RememberFact`.
- Move merchants to a places list with its own refusal reason.
- Drop "card", "target" and "steps" from the lists, or require a digit next to them.
- A told line with a health word and no digits is kept private. A health word next to a number is refused.

## 3. The turnover

| # | State | Turnover at | Expect | #356 today |
|---|---|---|---|---|
| T1 | Yesterday: Pull A finished, 2 tasks done, cooked chili | Wed 04:05 | One recent line "Tue: Pull A done, 2 tasks, cooked chili." (or the Day log's own words), day = Tuesday | Written. The words follow `DayStory`'s finished lines |
| T2 | A day with 9 finished things | 04:05 | The line fits 80 characters by **dropping whole parts** ("…, and 3 more."), never cut mid-word | **Cut mid-word**: `prefix(79) + "."` |
| T3 | Day lines 15 days old | 04:05 | Removed. No week line written (#357) | **Folded into a "Week of …" line** kept 8 weeks |
| T4 | 6 weeks of training, 70% of starts 18:00 to 19:59 | Sunday 04:05 | "You usually train 6 pm to 8 pm.", second person, rule id `training.window` | "Usually trains 6 pm to 8 pm." (third person, no rule id) |
| T5 | Starts mostly 23:00 to 00:59 | Sunday 04:05 | "You usually train 11 pm to 1 am." Digits 11 and 1 licensed | Same words in third person. `clock(25)` gives "1 am" ✓ |
| T6 | Noticed lines forgotten (M3), then a Monday | Mon 04:05 | No recompute (it's not Sunday), and nothing back | **Recomputes** (`lines(of: .noticed).isEmpty`) |
| T7 | 41 told lines, one unused 120 days | 04:05 | Not reachable under #357 (the 41st is refused at write time) | Drops the stale one and returns its words for Tess's line ✓ (that path holds for the 40th) |
| T8 | Cooked 4 times in 6 weeks, 3 on Sunday | Sunday 04:05 | "You cook most on Sundays.", Kitchen, rule id `kitchen.day` | "Cooks most on Sundays." (third person) |
| T9 | Turnover twice on the same morning | 04:05 and 09:00 | Idempotent: one recent line, noticed lines unchanged | Recent ✓ (guarded by day). Noticed recomputes again on a Sunday morning: same lines, but new object ids, so a forget made at 08:00 would be undone at 09:00 |

## 4. Smaller things for Core

- `thing(of:)` takes the first 3 words, so "my left shoulder gets sore…" gives "My left shoulder, forgotten.". Design's line is "Left shoulder, forgotten.". Drop a leading "my"/"your" (and once text is second person, "You"/"Your").
- `sourceLine` for recent lines says "from the day log". Design shows day lines with no source line under them, so return nil for `.recent`.
- `markUsed` is only reachable from pack callers. #357's "used" includes on-phone rules (living colour, Home's usual slot), so those readers call it too.
- The `.days` case in `Area` stands in for recent lines' group. Under #357 recent is a kind, and the page adds the label. Keeping `.days` is harmless if the page never lists it as a group a told line can be put in.
