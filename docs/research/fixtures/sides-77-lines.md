# The last eight sides: lines and glances (Research CD)

*Research, Oct 17. Docs only. Sources: Design sheet 77 (`design/sides-77.md` at 3c3e8cd on the shared mount), Product's decision 5:53 pm Oct 16 (adopted, owners named), Product's rulings (decisions 6:01, listed at the end), the earlier side-line fixtures (`fixtures/side-lines.md`, rows SL- and GL-), `drawn-sides-acceptance.md` (SA-, Research BQ), `fixtures/depth-76.md`, and Product's decisions 2:41, 2:44, 2:45, 2:46 (daily pins, no side rule), 2:59, 5:07 and 5:20. Read against origin/master a8c3e6e. Every value is made up; placeholders are hunter2, tacocat and 4417. "Today" in every row is Friday Oct 16, 2026 at 6:10 pm (`-demoTime 18:10`).*

Product's ask: "The private Paste lines show only a bar and 'ignored'." Each of the eight sides has an ordinary day (two examples), an empty case and a private case, 37 rows in all (GR, RT, CK, PS, WK, PL, CP, DF), 288 counted lines.

## 1. The rules every line is checked against

1. **Glance** (stop 1): one big fact with its unit, at most two small facts, the foot word. A small fact with no data is left out (GL-E1), and a glance with no big fact does not exist: the swipe opens the full side (GL-E3, GL-E4). A zero is never a big fact.
2. **Caps.** Context slots (glance big plus unit, small 1, small 2, foot, a full-side heading, one cell of a full-side row): at most 6 words and 32 characters, no stop (`HomeLines.fitsContext`, `HomeLines.swift:187`). Detail slots (Tess's line, an empty-state line, a small fact that is a sentence): at most 14 words and 80 characters, one sentence ending in a stop, no "?" or "!", no ". " inside (`HomeLines.fitsDetail`, :194). A full-side row with two columns (a name and how long) is counted as two cells. His own pasted words and the names of his own objects are not capped.
3. **Writing.** The thing leads (a count, a name, a day), see C1. Times are lowercase 12-hour with no "at" before them ("4 am", never "at 4 am"); no line here holds a clock time, and the test still checks. "best", never "record" or "PR". No em-dashes, no "...", no "?" or "!". Days are words ("Thursday"), older ones "Oct 4". Duration is "46 min" or "6 h 55 min". Plain US English.
4. **Tess's line** is the same at both stops, computed on the phone, one sentence, never the page's own title (2:44). It is empty when the side's only fact is a zero or the side is private.
5. **What must never show, on any side or line:** a money amount (the single exception is the $3.20 on The week's glance, 5:53 call 3), a body number or a body measure, a private note's, task's, memory's, recipe's, routine's or plan's title, a secret word or the value after it, a medicine name with a dose. Private things are shown as their label ("Private note", "Private task", "Private memory"; C10 for the rest) or as a count, never named. Nothing on a side goes to Claude (2:41, 2:40).
6. **No controls on a side.** Reduce Motion: each stop a 150 ms crossfade (`MotionPolicy`).

The count check (re-run it after any copy change; it is the whole checker):

```python
import re
def check(kind, t):               # kind: context slots or "tess"
    w, c = len(t.split()), len(t)
    if kind != "tess":
        ok = w <= 6 and c <= 32 and not t.endswith(".")
    else:
        body = t[:-1]
        ok = (t.endswith(".") and w <= 14 and c <= 80
              and not re.search(r"[?!]", body) and ". " not in body)
    ok = ok and not re.search("\\u2014|\\u2026| record|\\bat \\d", t)
    return w, c, ok
```

All 288 lines pass (0 marked NO). Since the 6:01 rulings no context line ends in a stop, see C5.

## 2. What master has today (a8c3e6e)

| Finding | Where |
|---|---|
| **No SideHost.** No side declaration, glance or full-side view exists, so every row in section 4 is a test for Core 0ak's host and for the builder's side. | n/a |
| `HomeLines.fitsContext` and `fitsDetail` exist and are public. | `TesseraCore/Home/HomeLines.swift:187`, `:194` |
| `SecretWords.mentions` and `hasValue` are public. `isPrivateLine` and `cut` are **internal**, so the paste screen cannot tell a secret line (bar) from a plain ignored line (dim words). | `Notes/SecretWords.swift:34`, `:40`, `:73`, `:85` |
| `CreateRecipe.lines(of:corrections:)` is public and folds secret-looking lines into `.ignored`, the same kind as a plain ignored line. | `Kitchen/Recipes.swift:146-168` |
| `PrivateFacts` and `isPrivateTitle` are **not on master** (no match in `TesseraCore/Sources` or `Features`). The private label exists only for notes (`SecretWords.title`, "Private note"). | grep of `a8c3e6e` |
| `CookLog.cooks(of:)` gives finished cooks newest first with `cookedAt`; the start is the cook's `createdAt`. No duration, no median. | `Kitchen/Cooking.swift:30-37`, `:241` |
| `TessUse` has five cases (capture, question, paste, plan, keyCheck). The job names on sheet 77 (Today's lines, Plan my day, Your week, Recipe reading) are not there. `TessUsageLedger` has `calls()` and `monthTotal` (from `costNano`). | `TesseraTess/TessModel.swift:5-15`, `ClaudeKey.swift:86-118` |
| `daysSinceLastRun` is internal to HomeLines. No per-routine "this month" count. | `Home/HomeLines.swift:593` |
| `sessionsPerWeek`, `scheduleMode`, and half-set secondary muscles (primary 1, secondary 0.5) exist. A planned total for the month does not. | `Catalog/SystemCatalog.swift:196-198`, `Training/TrainingLedger.swift:217-226` |
| `HomeLines.fact(plannedCook:recipe:)` exists; a planned cook per day for a Groceries group does not. | `Home/HomeLines.swift:552` |
| Recipe fields on master: serves, active minutes, total minutes. No Book class (Dune is an example, D10). | `Kitchen/Recipes.swift` (`CreateRecipe.apply`) |

## 3. Owners

Core 0ak (SideHost, the default object side, the class page). Builder B: Groceries FOR WHAT, Recipe original COOKS, Paste WHAT I READ, The week WHAT LEAVES THE PHONE, Plans THE PLAN (5:53, confirmed 6:01, see C3). Builder A: Routines LAST TIMES. Kitchen: the cook's name and day on each Groceries group, and the median for COOKS. All after Core 0ak.

## 4. Fixtures

For each side, the first table gives the case, the data, what must never show, the Swift Testing name and the owner. The second table gives every line with its words and characters. Read an empty row's lines as "what the full side says when nothing is there"; Tess's band is empty on those rows and there is no glance. The empty-state lines are proposals, because Design owns them (5:07 call 1).

### Groceries: FOR WHAT (LINKS)

Owner: Builder B builds the side; Core 0ak hosts it. Rows below list every line the side may show, with its words and characters.

| ID | Case | Data (made up) | Never on this row | Swift Testing name | Owner |
|---|---|---|---|---|---|
| GR-1 | Ordinary | 10 rows: tacos (Sunday Oct 18) has 5, chili (Tuesday Oct 20) has 2, ground beef and onion are for both so they show once; 3 with no cook; USUALLY knows rice and butter | prices, any money amount; a row twice | `groceriesForWhatShowsSharedRowOnceWithAlso` | Builder B (host Core 0ak) |
| GR-2 | Ordinary | 5 rows, none linked to a cook, so no cook groups and no USUALLY line | a "FOR" group with no cook; "usual" invented | `groceriesWithNoCooksHasOnlyJustBecause` | Builder B (host Core 0ak) |
| GR-3 | Empty | the list has 0 rows (no big fact, so no glance: the swipe opens the full side) | a zero as a big fact; "All stocked up" | `emptyGroceriesOpensFullSideWithNoTessLine` | Builder B (host Core 0ak) |
| GR-4 | Private | Sunday cook is a recipe titled "Lin's low-sodium plan" (fails the private-title check); chili Tuesday; 7 for 2 cooks, 3 just because; one row shows twice-cook rule as in GR-1 | "Lin's low-sodium plan", "low-sodium", "Lin"; the recipe's own title in Tess's line, the glance, a heading or VoiceOver | `privateRecipeCookReadsPrivateRecipeNeverItsTitle` | Builder B (host Core 0ak) |

| ID | Slot | Text | Words | Chars | Cap | Fits |
|---|---|---|---|---|---|---|
| GR-1 | glance big | 7 for 2 cooks | 4 | 13 | ctx | yes |
| GR-1 | glance small 1 | Tacos and chili | 3 | 15 | ctx | yes |
| GR-1 | glance small 2 | 3 just because | 3 | 14 | ctx | yes |
| GR-1 | glance foot | ALL LINKS | 2 | 9 | ctx | yes |
| GR-1 | Tess's line | 7 for 2 cooks, 3 just because. | 7 | 30 | det | yes |
| GR-1 | full side heading | TACOS, SUNDAY | 2 | 13 | ctx | yes |
| GR-1 | full side row | Ground beef, also chili | 4 | 23 | ctx | yes |
| GR-1 | full side row | Onion, also chili | 3 | 17 | ctx | yes |
| GR-1 | full side row | Tortillas | 1 | 9 | ctx | yes |
| GR-1 | full side row | Cheddar | 1 | 7 | ctx | yes |
| GR-1 | full side row | Limes | 1 | 5 | ctx | yes |
| GR-1 | full side heading | CHILI, TUESDAY | 2 | 14 | ctx | yes |
| GR-1 | full side row | Kidney beans | 2 | 12 | ctx | yes |
| GR-1 | full side row | Chili powder | 2 | 12 | ctx | yes |
| GR-1 | full side heading | JUST BECAUSE | 2 | 12 | ctx | yes |
| GR-1 | full side row | Milk | 1 | 4 | ctx | yes |
| GR-1 | full side row | Eggs | 1 | 4 | ctx | yes |
| GR-1 | full side row | Coffee | 1 | 6 | ctx | yes |
| GR-1 | full side heading | USUALLY | 1 | 7 | ctx | yes |
| GR-1 | full side row | Rice and butter | 3 | 15 | ctx | yes |
| GR-2 | glance big | 5 just because | 3 | 14 | ctx | yes |
| GR-2 | glance foot | ALL LINKS | 2 | 9 | ctx | yes |
| GR-2 | Tess's line | 5 just because, none for a cook. | 7 | 32 | det | yes |
| GR-2 | full side heading | JUST BECAUSE | 2 | 12 | ctx | yes |
| GR-2 | full side row | Milk | 1 | 4 | ctx | yes |
| GR-2 | full side row | Eggs | 1 | 4 | ctx | yes |
| GR-2 | full side row | Coffee | 1 | 6 | ctx | yes |
| GR-2 | full side row | Bread | 1 | 5 | ctx | yes |
| GR-2 | full side row | Bananas | 1 | 7 | ctx | yes |
| GR-3 | full side line | Nothing on the list. | 4 | 20 | det | yes |
| GR-4 | glance big | 7 for 2 cooks | 4 | 13 | ctx | yes |
| GR-4 | glance small 1 | Private recipe and chili | 4 | 24 | ctx | yes |
| GR-4 | glance small 2 | 3 just because | 3 | 14 | ctx | yes |
| GR-4 | glance foot | ALL LINKS | 2 | 9 | ctx | yes |
| GR-4 | Tess's line | 7 for 2 cooks, 3 just because. | 7 | 30 | det | yes |
| GR-4 | full side heading | PRIVATE RECIPE, SUNDAY | 3 | 22 | ctx | yes |
| GR-4 | full side row | Chicken thigh | 2 | 13 | ctx | yes |
| GR-4 | full side row | Onion, also chili | 3 | 17 | ctx | yes |
| GR-4 | full side heading | CHILI, TUESDAY | 2 | 14 | ctx | yes |
| GR-4 | full side row | Kidney beans | 2 | 12 | ctx | yes |

### Routines: LAST TIMES (BEFORE)

Owner: Builder A builds the side; Core 0ak hosts it. Rows below list every line the side may show, with its words and characters.

| ID | Case | Data (made up) | Never on this row | Swift Testing name | Owner |
|---|---|---|---|---|---|
| RT-1 | Ordinary | Today Fri Oct 16. Push A done today (52 min); Legs A Wed Oct 14 (1 h 1 min); Pull A Tue Oct 13 (48 min); Push A 4 times in October | workout notes, body weight, volume in kg | `lastTimesListsNewestFirstWithHowLong` | Builder A (host Core 0ak) |
| RT-2 | Ordinary | Newest is Pull A on Thu Oct 15 (48 min), its only run this month; Push A Tue Oct 13 (55 min); Legs A Oct 10 (57 min) | a count of 1 written as "1 times"; "neglected" | `lastTimesSaysOnceForOneRunThisMonth` | Builder A (host Core 0ak) |
| RT-3 | Empty | no finished workout yet (a plan with routines, none run) | "Time to start"; a next-due row (this is LAST TIMES) | `noFinishedWorkoutsOpensFullSideWithNoTessLine` | Builder A (host Core 0ak) |
| RT-4 | Private | Push A done today is routine "Private routine" (its title fails the private-title check); workout notes "left knee sore, see Dr. Lin" (masked, 5:20); a weigh-in of 82.4 kg that day | the routine's title, "knee", "Lin", "82.4", "kg", the note label "Note kept private"; Tess's line stays empty when the newest run is private | `privateRoutineShowsLabelAndNoNotesOrBodyNumbers` | Builder A (host Core 0ak) |

| ID | Slot | Text | Words | Chars | Cap | Fits |
|---|---|---|---|---|---|---|
| RT-1 | glance big | Push A | 2 | 6 | ctx | yes |
| RT-1 | glance small 1 | today | 1 | 5 | ctx | yes |
| RT-1 | glance small 2 | Legs A, Wednesday | 3 | 17 | ctx | yes |
| RT-1 | glance foot | THE WHOLE STORY | 3 | 15 | ctx | yes |
| RT-1 | Tess's line | Push A, 4 times this month. | 6 | 27 | det | yes |
| RT-1 | full side row | Push A, today | 3 | 13 | ctx | yes |
| RT-1 | full side row | 52 min | 2 | 6 | ctx | yes |
| RT-1 | full side row | Legs A, Wednesday | 3 | 17 | ctx | yes |
| RT-1 | full side row | 1 h 1 min | 4 | 9 | ctx | yes |
| RT-1 | full side row | Pull A, Tuesday | 3 | 15 | ctx | yes |
| RT-1 | full side row | 48 min | 2 | 6 | ctx | yes |
| RT-2 | glance big | Pull A | 2 | 6 | ctx | yes |
| RT-2 | glance small 1 | Thursday | 1 | 8 | ctx | yes |
| RT-2 | glance small 2 | Push A, Tuesday | 3 | 15 | ctx | yes |
| RT-2 | glance foot | THE WHOLE STORY | 3 | 15 | ctx | yes |
| RT-2 | Tess's line | Pull A, once this month. | 5 | 24 | det | yes |
| RT-2 | full side row | Pull A, Thursday | 3 | 16 | ctx | yes |
| RT-2 | full side row | 48 min | 2 | 6 | ctx | yes |
| RT-2 | full side row | Push A, Tuesday | 3 | 15 | ctx | yes |
| RT-2 | full side row | 55 min | 2 | 6 | ctx | yes |
| RT-2 | full side row | Legs A, Oct 10 | 4 | 14 | ctx | yes |
| RT-2 | full side row | 57 min | 2 | 6 | ctx | yes |
| RT-3 | full side line | No finished workouts yet. | 4 | 25 | det | yes |
| RT-4 | glance big | Private routine | 2 | 15 | ctx | yes |
| RT-4 | glance small 1 | today | 1 | 5 | ctx | yes |
| RT-4 | glance small 2 | Legs A, Wednesday | 3 | 17 | ctx | yes |
| RT-4 | glance foot | THE WHOLE STORY | 3 | 15 | ctx | yes |
| RT-4 | full side row | Private routine, today | 3 | 22 | ctx | yes |
| RT-4 | full side row | 52 min | 2 | 6 | ctx | yes |
| RT-4 | full side row | Legs A, Wednesday | 3 | 17 | ctx | yes |
| RT-4 | full side row | 1 h 1 min | 4 | 9 | ctx | yes |

### Recipe original: COOKS (BEFORE)

Owner: Builder B builds the side; Core 0ak hosts it. Rows below list every line the side may show, with its words and characters.

| ID | Case | Data (made up) | Never on this row | Swift Testing name | Owner |
|---|---|---|---|---|---|
| CK-1 | Ordinary | Chili, 4 finished cooks: Thu Oct 15 46 min, Sun Oct 11 44 min, Oct 4 38 min, Sep 27 51 min (median 45) | cook notes, "favorite" | `cooksListsEachCookNewestFirstWithMedian` | Builder B (host Core 0ak) |
| CK-2 | Ordinary | Dal, 2 cooks: Mon Oct 12 54 min, Sep 28 44 min (median 49) | "getting faster" | `cooksMedianNeedsTwoCooks` | Builder B (host Core 0ak) |
| CK-3 | Empty | Soup, 0 finished cooks (a started cook that never finished does not count) | "First of many", a zero as a big fact | `noCooksOpensFullSideWithNoTessLine` | Builder B (host Core 0ak) |
| CK-4 | Empty (edge) | Stew, exactly 1 cook (Thu Oct 15, 46 min): glance stays, no median, Tess empty | a median from one cook; "about 46 min" | `oneCookKeepsGlanceDropsMedianAndTessLine` | Builder B (host Core 0ak) |
| CK-5 | Ordinary (long) | Slow stew written as 60 min; 3 cooks: Sun Oct 11 6 h 55 min, Oct 4 5 h 40 min, Sep 20 6 h 10 min (median 6 h 10 min) | minutes over 59 written as "415 min" | `cooksShowHoursAndMinutesPastAnHour` | Builder B (host Core 0ak) |
| CK-6 | Private | Recipe "Lin's low-sodium plan" (private title), 4 finished cooks. Count only, as a private task's side is (5:07 call 3), because dates and times of a cook reveal what the label hides | the title, "low-sodium", any date, weekday or duration of a cook; Tess's line stays empty | `privateRecipeCooksShowCountOnly` | Builder B (host Core 0ak) |

| ID | Slot | Text | Words | Chars | Cap | Fits |
|---|---|---|---|---|---|---|
| CK-1 | glance big | 4 times | 2 | 7 | ctx | yes |
| CK-1 | glance small 1 | Thursday, 46 min | 3 | 16 | ctx | yes |
| CK-1 | glance small 2 | about 45 min | 3 | 12 | ctx | yes |
| CK-1 | glance foot | THE WHOLE STORY | 3 | 15 | ctx | yes |
| CK-1 | Tess's line | Cooked 4 times, about 45 min. | 6 | 29 | det | yes |
| CK-1 | full side row | Thursday | 1 | 8 | ctx | yes |
| CK-1 | full side row | 46 min | 2 | 6 | ctx | yes |
| CK-1 | full side row | Sunday | 1 | 6 | ctx | yes |
| CK-1 | full side row | 44 min | 2 | 6 | ctx | yes |
| CK-1 | full side row | Oct 4 | 2 | 5 | ctx | yes |
| CK-1 | full side row | 38 min | 2 | 6 | ctx | yes |
| CK-1 | full side row | Sep 27 | 2 | 6 | ctx | yes |
| CK-1 | full side row | 51 min | 2 | 6 | ctx | yes |
| CK-2 | glance big | 2 times | 2 | 7 | ctx | yes |
| CK-2 | glance small 1 | Monday, 54 min | 3 | 14 | ctx | yes |
| CK-2 | glance small 2 | about 49 min | 3 | 12 | ctx | yes |
| CK-2 | glance foot | THE WHOLE STORY | 3 | 15 | ctx | yes |
| CK-2 | Tess's line | Cooked 2 times, about 49 min. | 6 | 29 | det | yes |
| CK-2 | full side row | Monday | 1 | 6 | ctx | yes |
| CK-2 | full side row | 54 min | 2 | 6 | ctx | yes |
| CK-2 | full side row | Sep 28 | 2 | 6 | ctx | yes |
| CK-2 | full side row | 44 min | 2 | 6 | ctx | yes |
| CK-3 | full side line | Not cooked yet. | 3 | 15 | det | yes |
| CK-4 | glance big | 1 time | 2 | 6 | ctx | yes |
| CK-4 | glance small 1 | Thursday, 46 min | 3 | 16 | ctx | yes |
| CK-4 | glance foot | THE WHOLE STORY | 3 | 15 | ctx | yes |
| CK-4 | full side row | Thursday | 1 | 8 | ctx | yes |
| CK-4 | full side row | 46 min | 2 | 6 | ctx | yes |
| CK-5 | glance big | 3 times | 2 | 7 | ctx | yes |
| CK-5 | glance small 1 | Sunday, 6 h 55 min | 5 | 18 | ctx | yes |
| CK-5 | glance small 2 | about 6 h 10 min | 5 | 16 | ctx | yes |
| CK-5 | glance foot | THE WHOLE STORY | 3 | 15 | ctx | yes |
| CK-5 | Tess's line | Cooked 3 times, about 6 h 10 min. | 8 | 33 | det | yes |
| CK-5 | full side row | Sunday | 1 | 6 | ctx | yes |
| CK-5 | full side row | 6 h 55 min | 4 | 10 | ctx | yes |
| CK-5 | full side row | Oct 4 | 2 | 5 | ctx | yes |
| CK-5 | full side row | 5 h 40 min | 4 | 10 | ctx | yes |
| CK-5 | full side row | Sep 20 | 2 | 6 | ctx | yes |
| CK-5 | full side row | 6 h 10 min | 4 | 10 | ctx | yes |
| CK-6 | glance big | 4 times | 2 | 7 | ctx | yes |
| CK-6 | glance foot | THE WHOLE STORY | 3 | 15 | ctx | yes |
| CK-6 | full side heading | PRIVATE RECIPE | 2 | 14 | ctx | yes |
| CK-6 | full side row | Cooked 4 times | 3 | 14 | ctx | yes |

### Paste a recipe: WHAT I READ (PARTS)

Owner: Builder B builds the side; Core 0ak hosts it. Rows below list every line the side may show, with its words and characters.

| ID | Case | Data (made up) | Never on this row | Swift Testing name | Owner |
|---|---|---|---|---|---|
| PS-1 | Ordinary | 17 lines read from nytimes.com: 14 kept, 3 plain ignored ("Jump to recipe", "Print", "Advertisement"), shown dim with the word ignored. His own pasted words are not capped. | nothing private here; still no line count in Tess beyond kept of total | `pasteShowsKeptPlainAndDimIgnoredLines` | Builder B (host Core 0ak) |
| PS-2 | Ordinary | 9 lines typed in, all 9 kept, no source site: big fact alone; Tess empty because no line is ignored (SL-PA3 kept) | "Perfect", "9 of 9" | `pasteWithEverythingKeptHasBigFactOnly` | Builder B (host Core 0ak) |
| PS-3 | Empty | nothing pasted (0 lines) | a zero as a big fact | `emptyPasteOpensFullSideWithNoTessLine` | Builder B (host Core 0ak) |
| PS-4 | Private | 17 lines, 14 kept, 3 ignored: "Print" (plain) and two secret-looking lines, "wifi password is hunter2" and "locker pin 4417". Each secret line shows a bar and the word ignored, nothing else. The count of 3 includes them. | "wifi", "hunter2", "locker", "pin", "4417", their length or first letter in the bar, VoiceOver or Claude | `privatePasteLineShowsBarAndIgnoredOnly` | Builder B (host Core 0ak) |
| PS-5 | Private (edge) | every line is secret-looking (a pasted password list): 0 kept, so no big fact and no glance; full side is bars, each with ignored; Tess empty | every word of every line | `allPrivatePasteShowsOnlyBarsAndIgnored` | Builder B (host Core 0ak) |

| ID | Slot | Text | Words | Chars | Cap | Fits |
|---|---|---|---|---|---|---|
| PS-1 | glance big | 14 lines kept | 3 | 13 | ctx | yes |
| PS-1 | glance small 1 | 3 ignored | 2 | 9 | ctx | yes |
| PS-1 | glance small 2 | nytimes.com | 1 | 11 | ctx | yes |
| PS-1 | glance foot | ALL OF IT | 3 | 9 | ctx | yes |
| PS-1 | Tess's line | 14 of 17 lines kept. | 5 | 20 | det | yes |
| PS-1 | full side row | ignored | 1 | 7 | ctx | yes |
| PS-2 | glance big | 9 lines kept | 3 | 12 | ctx | yes |
| PS-2 | glance foot | ALL OF IT | 3 | 9 | ctx | yes |
| PS-3 | full side line | Nothing pasted yet. | 3 | 19 | det | yes |
| PS-4 | glance big | 14 lines kept | 3 | 13 | ctx | yes |
| PS-4 | glance small 1 | 3 ignored | 2 | 9 | ctx | yes |
| PS-4 | glance small 2 | nytimes.com | 1 | 11 | ctx | yes |
| PS-4 | glance foot | ALL OF IT | 3 | 9 | ctx | yes |
| PS-4 | Tess's line | 14 of 17 lines kept. | 5 | 20 | det | yes |
| PS-4 | full side row | ignored | 1 | 7 | ctx | yes |
| PS-5 | full side row | ignored | 1 | 7 | ctx | yes |

### The week (Settings): WHAT LEAVES THE PHONE (FACTS)

Owner: Builder B builds the side; Core 0ak hosts it. Rows below list every line the side may show, with its words and characters.

| ID | Case | Data (made up) | Never on this row | Swift Testing name | Owner |
|---|---|---|---|---|---|
| WK-1 | Ordinary | October: 38 calls, $3.20 receipts cost (Claude's own spend, not his money, 5:53 call 3). Today's lines 21, Plan my day 9, Your week 5, Recipe reading 3 | any amount on the full side or in Tess's line; the $3.20 appears once, on the glance only | `weekFactsShowCountsByJobAndOneCostOnGlance` | Builder B (host Core 0ak) |
| WK-2 | Ordinary | a quiet month: 12 calls, all Today's lines, a small cost | any money amount on the side | `weekWithOneJobSaysAll` | Builder B (host Core 0ak) |
| WK-3 | Empty | "Tess asks Claude" is off, 0 calls (E6: a zero is not a Tess line; SL-S2 is kept as the full side's own empty line) | "Stay private", "$0.00" | `noCallsOpensFullSideWithNoTessLine` | Builder B (host Core 0ak) |
| WK-4 | Private | Same as WK-1, but a task "Reset bank pin" (secret word) and a task "Pay rent 1,200" (money) were on the day Claude helped plan. The side names jobs, never what was in them. | "bank", "pin", "rent", "1,200", any second "$"; no task title anywhere on the side | `weekFactsNeverNameTitlesOrSecondAmount` | Builder B (host Core 0ak) |

| ID | Slot | Text | Words | Chars | Cap | Fits |
|---|---|---|---|---|---|---|
| WK-1 | glance big | $3.20 this month | 3 | 16 | ctx | yes |
| WK-1 | glance small 1 | 38 calls | 2 | 8 | ctx | yes |
| WK-1 | glance small 2 | Titles, counts, recipe text | 4 | 27 | ctx | yes |
| WK-1 | glance foot | ALL FACTS | 2 | 9 | ctx | yes |
| WK-1 | Tess's line | Today's lines made 21 of 38 calls. | 7 | 34 | det | yes |
| WK-1 | full side row | Today's lines | 2 | 13 | ctx | yes |
| WK-1 | full side row | 21 calls | 2 | 8 | ctx | yes |
| WK-1 | full side row | task titles and counts | 4 | 22 | ctx | yes |
| WK-1 | full side row | Plan my day | 3 | 11 | ctx | yes |
| WK-1 | full side row | 9 calls | 2 | 7 | ctx | yes |
| WK-1 | full side row | task titles and counts | 4 | 22 | ctx | yes |
| WK-1 | full side row | Your week | 2 | 9 | ctx | yes |
| WK-1 | full side row | 5 calls | 2 | 7 | ctx | yes |
| WK-1 | full side row | counts only | 2 | 11 | ctx | yes |
| WK-1 | full side row | Recipe reading | 2 | 14 | ctx | yes |
| WK-1 | full side row | 3 calls | 2 | 7 | ctx | yes |
| WK-1 | full side row | recipe text, no prices | 4 | 22 | ctx | yes |
| WK-2 | glance big | 12 calls this month | 4 | 19 | ctx | yes |
| WK-2 | glance small 1 | all Today's lines | 3 | 17 | ctx | yes |
| WK-2 | glance foot | ALL FACTS | 2 | 9 | ctx | yes |
| WK-2 | Tess's line | Today's lines made all 12 calls. | 6 | 32 | det | yes |
| WK-2 | full side row | Today's lines | 2 | 13 | ctx | yes |
| WK-2 | full side row | 12 calls | 2 | 8 | ctx | yes |
| WK-2 | full side row | task titles and counts | 4 | 22 | ctx | yes |
| WK-3 | full side line | Nothing has gone to Claude this month. | 7 | 38 | det | yes |
| WK-4 | glance big | $3.20 this month | 3 | 16 | ctx | yes |
| WK-4 | glance small 1 | 38 calls | 2 | 8 | ctx | yes |
| WK-4 | glance small 2 | Titles, counts, recipe text | 4 | 27 | ctx | yes |
| WK-4 | glance foot | ALL FACTS | 2 | 9 | ctx | yes |
| WK-4 | Tess's line | Today's lines made 21 of 38 calls. | 7 | 34 | det | yes |
| WK-4 | full side row | Plan my day | 3 | 11 | ctx | yes |
| WK-4 | full side row | 9 calls | 2 | 7 | ctx | yes |
| WK-4 | full side row | task titles and counts | 4 | 22 | ctx | yes |

### Plans: THE PLAN (FACTS)

Owner: Builder B builds the side; Core 0ak hosts it. Rows below list every line the side may show, with its words and characters. The session number stays 17 (6:01 ruling 2); the real number is computed from the plan (D4).

| ID | Case | Data (made up) | Never on this row | Swift Testing name | Owner |
|---|---|---|---|---|---|
| PL-1 | Ordinary | Push Pull Legs, 4 a week, fixed days; 9th session of 17 planned in October (fixed days make the month knowable) | "behind", "on track"; a body goal | `planFactsShowSplitDaysAndHowItProgresses` | Builder B (host Core 0ak) |
| PL-2 | Ordinary | Upper Lower, 3 a week, rolling; 7th session in October, no planned total because a rolling plan has none | "of 13" invented for a rolling plan | `rollingPlanTessLineHasNoTotal` | Builder B (host Core 0ak) |
| PL-3 | Empty | no routines and no sessions a week set (SL-P2) | "Build your plan" | `emptyPlanOpensFullSideWithNoTessLine` | Builder B (host Core 0ak) |
| PL-4 | Private | Plan titled "Cut to 78 kg" (a body number, fails the private-title check), otherwise as PL-1 | "Cut", "78", "kg", the plan's title; the side names the split and the days, never the goal | `privatePlanTitleNeverReachesSide` | Builder B (host Core 0ak) |

| ID | Slot | Text | Words | Chars | Cap | Fits |
|---|---|---|---|---|---|---|
| PL-1 | glance big | 4 days a week | 4 | 13 | ctx | yes |
| PL-1 | glance small 1 | Push Pull Legs | 3 | 14 | ctx | yes |
| PL-1 | glance small 2 | on fixed days | 3 | 13 | ctx | yes |
| PL-1 | glance foot | ALL FACTS | 2 | 9 | ctx | yes |
| PL-1 | Tess's line | Session 9 of 17 this month. | 6 | 27 | det | yes |
| PL-1 | full side heading | WHAT IT IS | 3 | 10 | ctx | yes |
| PL-1 | full side row | Push, Pull, Legs | 3 | 16 | ctx | yes |
| PL-1 | full side row | 4 a week | 3 | 8 | ctx | yes |
| PL-1 | full side row | On fixed days | 3 | 13 | ctx | yes |
| PL-1 | full side heading | HOW IT PROGRESSES | 3 | 17 | ctx | yes |
| PL-1 | full side row | Rolls on | 2 | 8 | ctx | yes |
| PL-1 | full side row | Primary sets count 1 | 4 | 20 | ctx | yes |
| PL-1 | full side row | Secondary sets count ½ | 4 | 22 | ctx | yes |
| PL-1 | full side row | Under a range stays neutral | 5 | 27 | ctx | yes |
| PL-2 | glance big | 3 days a week | 4 | 13 | ctx | yes |
| PL-2 | glance small 1 | Upper Lower | 2 | 11 | ctx | yes |
| PL-2 | glance small 2 | rolling on | 2 | 10 | ctx | yes |
| PL-2 | glance foot | ALL FACTS | 2 | 9 | ctx | yes |
| PL-2 | Tess's line | Session 7 this month. | 4 | 21 | det | yes |
| PL-2 | full side heading | WHAT IT IS | 3 | 10 | ctx | yes |
| PL-2 | full side row | Upper, Lower | 2 | 12 | ctx | yes |
| PL-2 | full side row | 3 a week | 3 | 8 | ctx | yes |
| PL-2 | full side row | Rolling on | 2 | 10 | ctx | yes |
| PL-2 | full side heading | HOW IT PROGRESSES | 3 | 17 | ctx | yes |
| PL-2 | full side row | Rolls on | 2 | 8 | ctx | yes |
| PL-2 | full side row | Primary sets count 1 | 4 | 20 | ctx | yes |
| PL-2 | full side row | Secondary sets count ½ | 4 | 22 | ctx | yes |
| PL-3 | full side line | No plan set up yet. | 5 | 19 | det | yes |
| PL-4 | glance big | 4 days a week | 4 | 13 | ctx | yes |
| PL-4 | glance small 1 | Push Pull Legs | 3 | 14 | ctx | yes |
| PL-4 | glance small 2 | on fixed days | 3 | 13 | ctx | yes |
| PL-4 | glance foot | ALL FACTS | 2 | 9 | ctx | yes |
| PL-4 | Tess's line | Session 9 of 17 this month. | 6 | 27 | det | yes |

### A class page (Recipes): ITS OBJECTS (LINKS)

Owner: Core 0ak builds the side and the host.

| ID | Case | Data (made up) | Never on this row | Swift Testing name | Owner |
|---|---|---|---|---|---|
| CP-1 | Ordinary | Recipes class, 38 objects; newest Dal, Tacos al pastor, Lentil soup; most cooked Chili, Tacos al pastor, Dal; every recipe has Serves, Total minutes, Active minutes | a private object's title | `classPageNamesThreeNewestThenAndNMore` | Core 0ak |
| CP-2 | Ordinary | Equipment class, 3 objects (all fit, so no "and N more"); most linked Olympic bar | "and 0 more" | `classPageWithThreeObjectsHasNoAndNMore` | Core 0ak |
| CP-3 | Empty | a class with 0 objects | "Add one" | `emptyClassPageOpensFullSideWithNoTessLine` | Core 0ak |
| CP-4 | Private | Notes class, 12 notes, 5 private, the newest is private. Newest slot reads Private note and does not skip (2:45); private notes link nothing so cannot be most used | a private note's title or words ("wifi password is hunter2"); a private note in MOST USED | `classPageNamesPrivateNewestAsLabelAndCountsRest` | Core 0ak |
| CP-5 | Private (edge) | Notes class where all 3 notes are private | any title or word; a MOST USED row | `allPrivateClassPageCountsAndLabelsOnly` | Core 0ak |

| ID | Slot | Text | Words | Chars | Cap | Fits |
|---|---|---|---|---|---|---|
| CP-1 | glance big | 38 objects | 2 | 10 | ctx | yes |
| CP-1 | glance small 1 | Newest, Dal | 2 | 11 | ctx | yes |
| CP-1 | glance small 2 | Most used, Chili | 3 | 16 | ctx | yes |
| CP-1 | glance foot | ALL LINKS | 2 | 9 | ctx | yes |
| CP-1 | Tess's line | Chili is the one you cook most. | 7 | 31 | det | yes |
| CP-1 | full side heading | NEWEST | 1 | 6 | ctx | yes |
| CP-1 | full side row | Dal | 1 | 3 | ctx | yes |
| CP-1 | full side row | Tacos al pastor | 3 | 15 | ctx | yes |
| CP-1 | full side row | Lentil soup | 2 | 11 | ctx | yes |
| CP-1 | full side row | and 35 more | 3 | 11 | ctx | yes |
| CP-1 | full side heading | MOST USED | 2 | 9 | ctx | yes |
| CP-1 | full side row | Chili | 1 | 5 | ctx | yes |
| CP-1 | full side row | Tacos al pastor | 3 | 15 | ctx | yes |
| CP-1 | full side row | Dal | 1 | 3 | ctx | yes |
| CP-1 | full side heading | EVERY ONE HAS | 3 | 13 | ctx | yes |
| CP-1 | full side row | Serves | 1 | 6 | ctx | yes |
| CP-1 | full side row | Total minutes | 2 | 13 | ctx | yes |
| CP-1 | full side row | Active minutes | 2 | 14 | ctx | yes |
| CP-2 | glance big | 3 objects | 2 | 9 | ctx | yes |
| CP-2 | glance small 1 | Newest, Squat rack | 3 | 18 | ctx | yes |
| CP-2 | glance small 2 | Most used, Olympic bar | 4 | 22 | ctx | yes |
| CP-2 | glance foot | ALL LINKS | 2 | 9 | ctx | yes |
| CP-2 | Tess's line | Olympic bar is linked from the most things. | 8 | 43 | det | yes |
| CP-2 | full side heading | NEWEST | 1 | 6 | ctx | yes |
| CP-2 | full side row | Squat rack | 2 | 10 | ctx | yes |
| CP-2 | full side row | Cable stack | 2 | 11 | ctx | yes |
| CP-2 | full side row | Olympic bar | 2 | 11 | ctx | yes |
| CP-2 | full side heading | MOST USED | 2 | 9 | ctx | yes |
| CP-2 | full side row | Olympic bar | 2 | 11 | ctx | yes |
| CP-2 | full side row | Squat rack | 2 | 10 | ctx | yes |
| CP-2 | full side row | Cable stack | 2 | 11 | ctx | yes |
| CP-3 | full side line | None yet. | 2 | 9 | det | yes |
| CP-4 | glance big | 12 objects | 2 | 10 | ctx | yes |
| CP-4 | glance small 1 | Newest, Private note | 3 | 20 | ctx | yes |
| CP-4 | glance small 2 | Most used, Tile quotes | 4 | 22 | ctx | yes |
| CP-4 | glance foot | ALL LINKS | 2 | 9 | ctx | yes |
| CP-4 | Tess's line | Tile quotes is linked from the most things. | 8 | 43 | det | yes |
| CP-4 | full side heading | NEWEST | 1 | 6 | ctx | yes |
| CP-4 | full side row | Private note | 2 | 12 | ctx | yes |
| CP-4 | full side row | Tile quotes | 2 | 11 | ctx | yes |
| CP-4 | full side row | Garage ideas | 2 | 12 | ctx | yes |
| CP-4 | full side row | and 9 more | 3 | 10 | ctx | yes |
| CP-4 | full side heading | MOST USED | 2 | 9 | ctx | yes |
| CP-4 | full side row | Tile quotes | 2 | 11 | ctx | yes |
| CP-4 | full side row | Garage ideas | 2 | 12 | ctx | yes |
| CP-4 | full side row | Landlord | 1 | 8 | ctx | yes |
| CP-4 | full side row | 5 private | 2 | 9 | ctx | yes |
| CP-5 | glance big | 3 objects | 2 | 9 | ctx | yes |
| CP-5 | glance small 1 | Newest, Private note | 3 | 20 | ctx | yes |
| CP-5 | glance foot | ALL LINKS | 2 | 9 | ctx | yes |
| CP-5 | full side heading | NEWEST | 1 | 6 | ctx | yes |
| CP-5 | full side row | Private note | 2 | 12 | ctx | yes |
| CP-5 | full side row | 3 private | 2 | 9 | ctx | yes |

### Any other object (Dune): DETAILS (LINKS + FACTS)

Owner: Core 0ak builds the side and the host.

| ID | Case | Data (made up) | Never on this row | Swift Testing name | Owner |
|---|---|---|---|---|---|
| DF-1 | Ordinary | Dune (a Book, not a class on master): Reading, 412 pages, started Oct 2, added Oct 2, from the library, linked from 3 notes | a field that the front already shows | `defaultSideListsLinksThenFieldsNotOnFront` | Core 0ak |
| DF-2 | Ordinary | Equipment Olympic bar: bar weight 20 kg (front shows the name), plate limit 25 kg, added Sep 3, linked from 3 workouts. The line falls back to the generic one (SL-O1) | a body weight; a field named only on the front | `defaultSideFallsBackToLinkedFromLine` | Core 0ak |
| DF-3 | Empty | an object with no links and no field hidden by the front (GL-E10: too small for two stops) | "Lonely" | `emptyDefaultSideOpensFullSideWithNoTessLine` | Core 0ak |
| DF-4 | Private | A private memory (the rule text "Take creatine after training" is hidden). The page reads its label; its fields and its links are masked, so the side shows the label only (2:45) | the memory's rule, evidence, dates, link count; no glance | `privateObjectDefaultSideShowsLabelOnly` | Core 0ak |
| DF-5 | Private | Dune again, with one private field (a notes field "locker code 4471"). The side prints the other fields and does not name or count the hidden one (2:44, sheet 77) | "locker", "4471", "notes", "1 hidden", the field's name; the hidden field never feeds Tess or a small fact | `defaultSideOmitsPrivateFieldWithoutNamingIt` | Core 0ak |

| ID | Slot | Text | Words | Chars | Cap | Fits |
|---|---|---|---|---|---|---|
| DF-1 | glance big | Reading | 1 | 7 | ctx | yes |
| DF-1 | glance small 1 | 412 pages | 2 | 9 | ctx | yes |
| DF-1 | glance small 2 | linked from 3 | 3 | 13 | ctx | yes |
| DF-1 | glance foot | ALL FACTS | 2 | 9 | ctx | yes |
| DF-1 | Tess's line | Reading since Oct 2. | 4 | 20 | det | yes |
| DF-1 | full side heading | LINKED FROM | 2 | 11 | ctx | yes |
| DF-1 | full side row | Book club notes | 3 | 15 | ctx | yes |
| DF-1 | full side row | Reading list | 2 | 12 | ctx | yes |
| DF-1 | full side row | Weekend plan | 2 | 12 | ctx | yes |
| DF-1 | full side heading | DETAILS | 1 | 7 | ctx | yes |
| DF-1 | full side row | Pages, 412 | 2 | 10 | ctx | yes |
| DF-1 | full side row | Started, Oct 2 | 3 | 14 | ctx | yes |
| DF-1 | full side row | Added, Oct 2 | 3 | 12 | ctx | yes |
| DF-1 | full side row | From, the library | 3 | 17 | ctx | yes |
| DF-2 | glance big | 20 kg bar | 3 | 9 | ctx | yes |
| DF-2 | glance small 1 | plates to 25 kg | 4 | 15 | ctx | yes |
| DF-2 | glance small 2 | linked from 3 | 3 | 13 | ctx | yes |
| DF-2 | glance foot | ALL FACTS | 2 | 9 | ctx | yes |
| DF-2 | Tess's line | Linked from 3 things. | 4 | 21 | det | yes |
| DF-2 | full side heading | LINKED FROM | 2 | 11 | ctx | yes |
| DF-2 | full side row | Bench Press | 2 | 11 | ctx | yes |
| DF-2 | full side row | Back Squat | 2 | 10 | ctx | yes |
| DF-2 | full side row | Overhead Press | 2 | 14 | ctx | yes |
| DF-2 | full side heading | DETAILS | 1 | 7 | ctx | yes |
| DF-2 | full side row | Bar weight, 20 kg | 4 | 17 | ctx | yes |
| DF-2 | full side row | Plate limit, 25 kg | 4 | 18 | ctx | yes |
| DF-2 | full side row | Added, Sep 3 | 3 | 12 | ctx | yes |
| DF-3 | full side line | Nothing more to show. | 4 | 21 | det | yes |
| DF-4 | full side heading | Private memory | 2 | 14 | ctx | yes |
| DF-5 | glance big | Reading | 1 | 7 | ctx | yes |
| DF-5 | glance small 1 | 412 pages | 2 | 9 | ctx | yes |
| DF-5 | glance small 2 | linked from 3 | 3 | 13 | ctx | yes |
| DF-5 | glance foot | ALL FACTS | 2 | 9 | ctx | yes |
| DF-5 | Tess's line | Reading since Oct 2. | 4 | 20 | det | yes |
| DF-5 | full side heading | LINKED FROM | 2 | 11 | ctx | yes |
| DF-5 | full side row | Book club notes | 3 | 15 | ctx | yes |
| DF-5 | full side heading | DETAILS | 1 | 7 | ctx | yes |
| DF-5 | full side row | Pages, 412 | 2 | 10 | ctx | yes |
| DF-5 | full side row | Started, Oct 2 | 3 | 14 | ctx | yes |
## 5. Shared tests (Core, `TesseraCoreTests`, `@Suite("Sides 77 lines")`)

- `sides77EveryLineFitsItsCap` (every row's lines, using the table's Cap column)
- `sides77NoEmDashNoEllipsisNoQuestionOrBang`
- `sides77SaysBestNeverRecord`
- `sides77NoAtBeforeATime` (lowercase 12-hour, no "at" before a time)
- `sides77NoMoneyAmountExceptWeekGlance` (WK-1 and WK-4: the one allowed $3.20 on the glance, none in Tess's line or the full side; WK-2 and every other row none)
- `sides77NoBodyNumberOrPrivateTitle` (RT-4, CK-6, PL-4, CP-4, DF-4, DF-5, PS-4, PS-5)
- `sides77TessLineIsEmptyWhenPrivateOrZero` (RT-4, CK-6, PS-5, CP-5, DF-4, every Empty row)
- `sides77SecretLineNeverReachesSideTextOrClaude` (PS-4, PS-5; the side's text, VoiceOver labels and any request body)
- `sides77GlanceLeavesOutEmptySmallFact` (GR-2, PS-2, CK-4)
- `sides77GlanceWithNoBigFactOpensFullSide` (every Empty row)
- `sides77TessLineSameAtBothStops` (every non-empty Tess line)

## 6. Conflicts with earlier rulings (what I assumed)

| # | Sheet 77 says | Earlier ruling | I assumed |
|---|---|---|---|
| C1 | The ask says "thing first". | 2:44 call 2: no thing-first on a side, because the side is already the thing's page. | "Thing first" means the line leads with its subject (a count, a name, a day), as 2:44 allows. No line repeats the page title. |
| C2 | Routines glance small 2 is "Pull A, Tuesday", but the full side lists "Legs A, Wednesday" before it, newest first. | The side is LAST TIMES, newest first. | Ruled 6:01 (ruling 3): newest first. Small 2 is the previous run, so RT-1 reads "Legs A, Wednesday". All RT rows were checked and none is out of order. |
| C3 | Sheet 77 gives Plans THE PLAN to Builder A. | 5:53 names Builder B for Plans. | Ruled 6:01 (ruling 1): Builder B. |
| C4 | Plans' line is "Session 11 of 26 this month." | A plan of 4 days a week has about 17 sessions in October, so 26 cannot be right. | Ruled 6:01 (ruling 2): keep 17 in "Session 9 of 17 this month." (PL-1, PL-4). The real number is computed from the plan (D4). A rolling plan has no total: "Session 7 this month." (PL-2). |
| C5 | Glance small 2 "Titles and counts only." | Sheet 77 rules: context lines of 6 words, and `fitsContext` refuses a trailing stop. | Ruled 6:01 (ruling 4): no stop on a context line, so the context cap applies. WK-1 and WK-4 read "Titles, counts, recipe text"; WK-2 has one small fact. |
| C6 | "Titles and counts only." on The week. | 2:40 call 1 and `RecipeLinkReader`: Recipe reading sends page text, with money stripped. | Ruled 6:01 (ruling 4): no blanket line on The week. Per-class rows name what was sent: Today's lines and Plan my day, task titles and counts; Your week, counts only; Recipe reading, recipe text with no prices. |
| C7 | The week's glance holds "$3.20". | The rule: no money amounts on a side (2:41). | 5:53 call 3 allows it: it is the app's own Claude cost, on the glance only. Full side and Tess's line carry counts only. Ruled 6:01 (ruling 5): the $3.20 stays the one allowed amount, and WK-2's $0.90 is now a count. |
| C8 | Tess's lines for six sides differ from the earlier ones. | SL-R1, SL-PA1, SL-S1, SL-P1, SL-CL1, and SL-O1 are the older lines. | Sheet 77 supersedes SL-R1 ("Push A today, Pull A next on Tuesday."), SL-PA1 ("14 lines kept, 3 ignored."), SL-S1, SL-P1 and SL-CL1 for these screens. SL-O1 stays as the default side's fallback (DF-2). SL-G1, SL-C3 and SL-C5 are unchanged. SL-S2 ("Nothing has gone to Claude this month.") becomes the full side's empty line (WK-3) and Tess's band is empty (E6). SL-PA3 (empty when every line is kept) stays (PS-2); sheet 77 is silent. SL-T4 and SL-E4-style rows are not touched. GL-4, GL-10, GL-12, GL-14, GL-16, GL-21 and GL-22 match or are refined. |
| C9 | The ask says no "at" before a time. | SL-D1 "Stretch at 8:30 pm", SL-B1 "ran at 4 am", SL-SD1 "Push A at 7 am" and GL-1 use "at". | None of these eight sides holds a clock time, so no row conflicts. Those older rows would fail `sides77NoAtBeforeATime` if the rule applied to them. Product to say. |
| C10 | The private paste line is a bar; no other private label is named. | 2:45 names "Private note", "Private task", "Private memory" only. Research BQ Q10 picked "Private recipe". | Ruled 6:01 (ruling 6): accepted. "Private recipe" (GR-4, CK-6) and "Private routine" (RT-4). A private plan's title is never printed, so it needs no label (PL-4). |
| C11 | COOKS lists each cook with a date and a time. | 5:07 call 3: a private task's side shows the count only, because dates reveal what the label hides. | A private recipe's COOKS shows the count only (CK-6), by the same reasoning. Product to rule. |
| C12 | Full-side rows such as "Legs A, Wednesday  1 h 1 min" and "Ground beef, also chili". | Context lines are 6 words or fewer. | A row is counted as cells (a name cell, a time cell). As one string, "Legs A, Wednesday 1 h 1 min" is 7 words. |
| C13 | The class page's "Most used". | 2:44 call 7 defines most-used for a field only. | For Recipes it is the most cooked (`CookLog`); for any other class it is the most backlinks. Product to confirm. |
| C14 | The default side hides a private field and names none. | GL-E8 shows "1 line kept private" on the exercise side. | Different sides: the default side says nothing about a hidden field (DF-5), and an exercise keeps GL-E8. |
| C15 | Paste: "3 ignored" and "14 of 17". | None. | The count of ignored includes secret-looking lines (PS-4). A count reveals that a line exists, not what it says. Product to say if even the count is too much. |

## 7. Rows that depend on data master lacks

| # | Missing | Rows | Where it would live |
|---|---|---|---|
| D1 | SideHost, glance and full-side views for all eight | all 37 | Core 0ak |
| D2 | Cook duration and median (start is the cook's `createdAt`, end is `cookedAt`; no helper, no rounding rule for the median or hours) | CK-1, CK-2, CK-4, CK-5 | Kitchen helper, Builder B |
| D3 | Last run per routine with how long, public (the helper is internal), and a per-routine "this month" count | RT-1, RT-2, RT-4 | Builder A, a TrainingLedger helper |
| D4 | Planned sessions this month and the session's number, for fixed-day plans | PL-1, PL-4 | Core, plan forecast |
| D5 | Cadence for the USUALLY line (reads the op log; part of 0ak, 2:44 call 5) | GR-1 | Core 0ak |
| D6 | Job names for Claude calls (master has `TessUse` capture, question, paste, plan, keyCheck, not Today's lines, Your week or Recipe reading) and a per-call `use` read | WK-1, WK-2, WK-4 | Builder B and AI, a job-name map |
| D7 | Resolved 6:01 (ruling 7): `isPrivateLine` goes public through Core 0ak, so a secret line can be told from a plain ignored one. Still open: a source site for pasted text (only `RecipeLinkReader` has a URL), needed by PS-1 and PS-4 | PS-1, PS-4, PS-5 | Core 0ak |
| D8 | The cook's name and day for each Groceries group (planned cook per day) | GR-1, GR-4 | Kitchen |
| D9 | `PrivateFacts.isPrivateTitle` (not on master) and the 2:45 mask for recipes, routines and plans | GR-4, RT-4, CK-6, PL-4, CP-4, DF-4, DF-5 | Core 0ai |
| D10 | Book class (Dune), its Reading status, Started and From fields | DF-1, DF-5 | Not built; Dune stands in for any object |
| D11 | The default side's "fields the front does not show", and a class's "every one has" and "most used" | DF-1, DF-2, CP-1 to CP-5 | Core 0ak |
| D12 | The Equipment class's fields (bar weight, plate limit) are not confirmed on master | DF-2, CP-2 | Core |

## 8. Open questions

- **Q1.** C2: answered 6:01 (ruling 3): the previous run.
- **Q2.** C4: answered 6:01 (ruling 2): keep 17; the real number is computed from the plan. Rolling plans have none.
- **Q3.** C11 and C15: private recipe cooks, count only (assumed); does the paste count of "ignored" stay when it includes secret lines?
- **Q4.** C6: answered 6:01 (ruling 4): no blanket line; the per-class rows name what was sent.
- **Q5.** D2: round the median to whole minutes and write hours past 59 min as "N h M min"? (CK-5 assumed yes.)

## Rulings applied (decisions 6:01)

1. Plans' owner is Builder B everywhere. Section 3 and every PL row say Builder B (C3).
2. "17" stays in "Session 9 of 17 this month." The real number is computed from the plan (C4, D4).
3. Routines small rows are newest first. Every RT row was checked; none was out of order, so no RT row changed (C2).
4. No stop on a context line. The week's glance small 2 lines are rewritten, and the blanket "Titles and counts only." is gone. Each class names what it sent (C5, C6). Counts were rechecked.
5. The $3.20 stays the one allowed money amount. WK-2's $0.90 is now "12 calls this month" (C7).
6. "Private recipe" and "Private routine" are accepted, and their flags are removed (C10).
7. isPrivateLine goes public through Core 0ak: D7 is resolved for the secret-line part. The source site for pasted text is still open. Other missing-data items stay as placeholders (D7).
