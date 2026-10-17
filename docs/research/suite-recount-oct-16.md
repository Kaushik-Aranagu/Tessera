# Grammar suite recount, Oct 16

For: Core (grammar). Research lab, 2026-10-16. Suite: `docs/research/fixtures/grammar-regression.md` (913 rows).

**Master traced:** `0eca9bb` (worktree of `origin/master`). Master moved to `20f0a16` (Merge #450) during the trace; `git diff 0eca9bb 20f0a16 -- TesseraCore` is empty, so every result holds there too.
**Last recount:** `7f1feb7` (Merge #282, suite commit `1a5b535`): 913 rows, 734 pass, 107 wrong write, 72 miss. Rows A to M still carried their `12f1c43` (#262) statuses; #274 and #282 had never been re-traced against them, so this pass covers those too.
**Method:** no Swift toolchain here (`command -v swift` is empty). Every result below is a hand trace against `TessGrammar.swift` (TG), `TessGrammar+Lift.swift` (Lift), `TessGrammar+Live.swift` (Live), `TessGrammar+Kitchen.swift` (Kitchen), `TessGrammar+Dated.swift` (Dated) and `SecretWords.swift` at `0eca9bb`. Nothing was run. I used Core's new `SetLossTests` and `SecretWordsTests` cases as a cross-check where they cover the same phrase.

## Grammar commits since the last recount

`git log 7f1feb7..origin/master -- TesseraCore` lists 50+ commits; these are the ones that change what `TessGrammar.parse` returns:

| Merge | Commit | What changes for the parse |
|---|---|---|
| #287 | `f7bc487` | `parseLift` moves to Lift: "N sets of M" keeps the sets, no weight asks; a bare N x M (N up to 10, no unit) on loaded kit asks; Tess's wake strip only takes "Tess," "Tess:" or "okay/hey Tess"; "for groceries" rule runs before buy/get and drops the verb; `isMoney`; the shop run returns nil for "for groceries", a set shape or money |
| #289 | `a7cb270` to `9bf00b9` | Same loaded-kit ask in focus (set-count ask under half the last weight); a small "at N" the kit can't load asks; "Tess 80 for 8" |
| #298 | `134f76a` | TG:116-121, a phrase that starts with spent, spend, paid, pay, cost or bought, or with a currency sign, returns nil ("money is never a task"); TG:122-125, a bare set with nothing in focus returns nil |
| #422 | `71be2af`, `88423d3` | TG:70-73 runs `parseSecret` (TG:471) first: a secret word makes `.privateNote`, a task shape with no value stays a task, a question asks "It's in your private notes." |
| #303, #316 | `e835a61`, `06ebf46` | Comment wording ("mum" to "mom") and a capture-level "already on Groceries" line; no parse change |

Earlier, never recounted: #274 (`7dd4e85`: `parseLiftAndErrand` at TG:100, the "at 7" rule at TG:109-114, "today" in Dated:10 and 22, `shortName` "Back Squat" to "Squat") and #282 (`65707a5`).

## Totals

| | rows | pass | wrong write | miss |
|---|---|---|---|---|
| Last recount (`7f1feb7`) | 913 | 734 | 107 | 72 |
| This trace (`0eca9bb`) | 913 | 745 | 87 | 81 |
| Change | 0 | +11 | -20 | +9 |

20 rows go to pass (18 from wrong write, 2 from miss). 11 rows regress to miss (9 from pass, 2 from wrong write). No row becomes a new wrong write.

## Rows whose result changed

| Row | Phrase (context) | Before | After | Responsible |
|---|---|---|---|---|
| A027 | `squat 100x5 tue` | wrong write (NAME) | pass: asks "Squat 100 × 5 for Tuesday?" | TessCaptureEngine.swift:391 (#274) |
| A059 | `buy milk and bench 80x8` | wrong write (RC6) | pass: groceries [milk] + lift | Live:170-184, TG:100 (#274) |
| A162 | `bench 80x8, call mom thu` | wrong write (RC6) | pass: lift + task "Call mom" Thu 15 19:00 | Live:170-184 |
| A163 | `bench 80x8 and call mom thu` | wrong write (RC6) | pass, as A162 | Live:170-184 |
| A164 | `squat 100x5 and buy milk` | miss (RC6) | pass: lift Back Squat 100x5 + groceries [milk] | Live:170-184 |
| A167 | `bench 3x5 at 80 then call mom at 7` | wrong write (RC6) | pass: lift 3x5 at 80 + task Thu 15 19:00 | Live:170-184 |
| A171 | `bench 80x8 dentist fri` (live) | wrong write (RC6) | pass: set 80x8 + task "Dentist" Fri 16 09:00 | Live:186-224 |
| A181 | `pull ups 3x8` | wrong write (RC12) | pass: lift Pull-Up 3 sets x 8 at bodyweight | Lift:35-37 |
| A182 | `curls 15x12` | wrong write (RC12) | pass: lift Dumbbell Curl 15x12 | TG:419 alias |
| A183 | `bench 80x8 today` | wrong write (RC12) | pass: lift Bench Press 80x8 | Dated:10, 22 |
| A184 | `bench 80x8 at 7` | wrong write (RC12) | pass: nil | TG:109-114 |
| K901 | `bench 3 sets of 8` (live) | wrong write | pass: asks "Bench 3 × 8 at what weight?" | Lift:12-19, 69-72 (#287) |
| K902 | `bench 3 sets of 8` (idle) | wrong write | pass, as K901 | Lift:69-72 |
| K903 | `add eggs for groceries` | wrong write | pass: groceries [eggs] | Kitchen:43-48 |
| K904 | `buy milk for groceries` | wrong write | pass: groceries [milk] | Kitchen:43-48 |
| K905 | `milk for groceries` (shopping) | wrong write | pass: shop rule steps aside, then groceries [milk] | TG:236-243, Kitchen:43-48 |
| K906 | `80 for 8` (shopping, Bench in focus) | wrong write | pass: set 80x8 | TG:242 set shape, then TG:90 |
| K908 | `pull ups 3 sets of 8` (live, bw) | miss | pass: lift Pull-Up 3 sets x 8 at 0 | Lift:12-19, 44-47 |
| K909 | `Tess's ideas list` | wrong write | pass: "Tess's" kept | TG:66-67 (#287) |
| K910 | `spent $40 on groceries` | wrong write | pass: nil | TG:116-121, Kitchen:45 |
| A011 | `paid rent fri` | pass | **miss**: nil, was note "Paid rent" Fri 9 | TG:116-121 (#298) |
| A012 | `paid 40 for gas sat` | pass | **miss**: nil, was a dated note | TG:116-121 |
| A013 | `bought milk sat` | pass | **miss**: nil, was note "Bought milk" Sat 10 | TG:116-121 |
| B339 | `Pay the window cleaner Thursday` | pass | **miss**: nil, was task Thu 15 | TG:116-121 |
| E504 | `paid bill sat` (people) | pass | **miss**: nil, was note "Paid bill" Sat 10 | TG:116-121 |
| H612 | `pay rent 650 fri` | pass | **miss**: nil, was task "Pay rent 650" Fri 16 | TG:116-121 |
| H613 | `pay rent fri` | pass | **miss**: nil, was task "Pay rent" Fri 16 | TG:116-121 |
| H615 | `spent the day at the beach sat` | pass | **miss**: nil, was a task (no money in it) | TG:116-121 |
| I730 | `pay council tax fri` (chores) | pass | **miss**: nil, was task Fri 16 | TG:116-121 |
| H609 | `spent 30 dinner sat` | wrong write (RC2) | miss: nil; the table's "now" is a dated note | TG:116-121 |
| H610 | `spent 12.40 lunch thu` | wrong write (RC2) | miss: nil, as H609 | TG:116-121 |

Unchanged after a re-trace: A160, A161, A165, A166, A168 (still RC6: an errand with no day can't split off), K907 (still miss, see below), and every money row whose expected value is nil (B348 to B355, C430, E503, E505, E506, E508, F549, H591 to H605, H614, H634, H635, I666, I670, I725, I728, I729, B320, H598, H601, H602, H621).

## New wrong writes

None in the suite. One found in phrases the suite lacks, owner **Core**:
- `buy pins` and `get a combination lock` become `.privateNote` titled "Private note": `SecretWords.words` (SecretWords.swift:11) counts "pins" and "combination" as secret words, `hasValue` is false, and `parseTask` (TG:514) needs a day, so `parseSecret` (TG:487) falls to a private note. Expected: groceries [pins] and a Later task. Wrong kind and wrong title, no ask. A comma list such as `milk, eggs, pins` goes the same way.

## Regressions to flag (owner Core, with a Product call)

1. **Money guard swallows plain errands and past logs** (TG:116-121, #298). The verb alone triggers it, so `pay rent fri`, `pay council tax fri` and `Pay the window cleaner Thursday` no longer make tasks, and C2's past logs (`paid rent fri`, `bought milk sat`) no longer make dated notes. These are misses, not wrong writes, but `pay rent fri` is an everyday phrase. Suggested fix: fire only on a past-tense money verb with an amount or a currency sign, and leave `pay X <day>` to `parseTask`. Product to confirm whether H609 and H610 keep a dated note as their "now" or take nil (Core's comment says "the miss line").
2. **K907 `pull-ups 8` still misses.** Lift:39-43 handles it, but `resolveExercise` (TG:424-457) never finds Pull-Up from the hyphenated plural "pull-ups" (no alias, and its word split drops the hyphen). Core's test uses `pull ups 8`. Add `"pull-ups": "pull-up"` (and `chin-ups`) to `aliases` at TG:415.

## Rows the suite lacks

Suggested group N (secret words, #422) and additions to H (money), all idle unless noted:
- `wifi password is tacocat` → privateNote; `my pin is 4417` → privateNote; `note: gym locker combo 4417` → privateNote; `remember the wifi password is hunter2` → privateNote, remembered.
- `password reset email friday` → task "Password reset email" Fri 16; `code review friday 3pm` → task Fri 16 15:00; `todo: reset my PIN` → task Later.
- `what's the wifi password?` → ask "It's in your private notes."
- `pinch of salt`, `spinach and feta` → no secret (groceries as today); `buy pins` → groceries [pins] (fails today, above).
- `door code 4417` with shopping running, and `pin 4417` in a live workout → privateNote (secret runs before the shop rule and the live rules).
- Money: `spent $23.47 at trader joe's sat` → nil; `spent $1,250 on rent` → nil; `chicken $1.29/lb, rice` → groceries [chicken $1.29/lb, rice]; `$5 coffee` → nil; `Tess dinner fri` → task "Tess dinner" Fri 16.
- Lifts from #287 and #289: `lat pulldown 3x8` and `curls 3x10 at 5` → ask "... at what weight?"; `leg press 5 kg x 5` → lift 5x5; `bench 3x8` (live, last 80) → set-count ask.
- Body words: these sit in `TessMemory` (TessMemory.swift:199-214), not the grammar, so they belong in a memory suite. The grammar has no "remember" rule outside `parseSecret`.

## Coverage and doubts

Fully traced: every row with a money verb or currency sign first (37 rows), every named-lift row with a number (38), every shop-run row (31), every bare N x M or "N for M" row (37), the wake-word rows, and K901 to K913. I grepped for secret words; no current row has one. Not re-traced: groups C, D, G, J, L and M, and the remaining A, B, E, F and I rows. None of their phrases reaches a changed line, by grep. The Kitchen `Quantities` and `Aisles` changes (#305 and #380) could move `looksLikeGroceries` on comma lists; I sampled H626, A195 and A194, which are unchanged.

Unsure: K906 passes only if `context.entry` stays set while the workout is suspended; if the app clears it, TG:122-125 returns nil (a miss, not a wrong write). K908 comes back as `.lift` (3 sets), not `.sets` into the entry in focus, and I didn't check where the capture files it. A162, A163 and A167 still take master's 19:00 for "thu" said on a Thursday (N1 gate), as the table's "now" says.

**Product (decisions.md 12:04 PM PT):** H609 and H610 write dated notes under the past-tense log rule ("paid rent fri", "bought milk sat"); Core changes the code comment. The money-verb fix, the secret-word list shape and the "pull-ups" alias are one small Core PR that rides the pin.
