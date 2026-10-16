# Tess hint ledger fixtures (15 days)

For: Core (`TessHintLedger`, built alongside `PageReader`), Builder B (the S, G and H lines). Research lab, board item 17, 2026-10-15.

**Traced:** `origin/master` at `6cc61ec` (Merge pull request #150), read by hand with `git show`. Nothing was run. Sources: `docs/research/tess-discoverability.md` (the rules and the 20 lines), `design/show-and-hints.md` from the shared folder (not on master), `docs/research/screen-fast-paths.md`, and `product/decisions.md` from 4:26 PM PT on (grammar calls, "buy" non-food, Show photo calls, time-form rules).

## What master has today

| Piece | On master? | Where |
|---|---|---|
| `TessHintLedger`, `tess.hints.v1`, `-resetHints` | No | Only named in the two research docs |
| The Write field | Yes | `Features/Command/BottomChrome.swift:271`, fixed placeholder "log 82.5×8, or ask" |
| Two suggestion phrases under the field | Yes | `BottomChrome.swift:304`, "log bench 82.5x8 · bench best?". A tap fills the field and focuses it; it no longer submits. The discoverability doc's "three outlined chips that submit" is out of date |
| Tess's question | Yes | `BottomChrome.swift:190-195`: "Tell me a set." in a workout, else "What's next?" or "Log it, ask, or note it." |
| Speak and Show | Words only | `BottomChrome.swift:256`: "Speak and Show are words until their layers ship", and Tess says "<Mode> comes next." |
| `TessVoice.violations(in:)` | Yes | `TesseraTess/TessCapturing.swift:64`. 12+ words, "!", emoji, newline, banned words |
| Tess lines last 4 s | Yes | `Features/Home/HomeQueue.swift:29-33` (`TessVoice.say`, app side, a different type from the engine `TessVoice` enum) |
| Who did it | Yes | `Actor` in `Actions/Op.swift`: `.user`, `.tess`, `.intent` (Siri, Shortcuts, Action button, widgets), `.system` |
| A hook for committed actions | Yes | `ActionEngine.observe(_:)`: called on the main actor for every action once it commits, including a preview that commits. The ledger's use counts and H triggers hang off this |
| Parse kind on a capture | No | `TessCapture` has `records`, `line`, `source` only. Slice 2 adds the kind |
| 04:00 day start | Yes | `RollForward.dayStartHour = 4`. `RollForward.logicalDay(of:calendar:)` is `static` and internal to `TesseraCore`, so `TesseraTess` can't call it today |
| The word "Next time" | Yes, elsewhere | `ExerciseWords.nextTime`: "Next time: 82.5 for 8." on the Exercise page. Same opening words as the H line |

Action names below are the real descriptor names from `ActionRegistry`: `logSet`, `createTask`, `addGroceries`, `startKitchenTimer`, `createNote`, `startWorkout`, `startCooking`. Parse cases are `TessGrammar.Parse` on master: `.lift`, `.set` (with `SetPhrase` `.same`, `.repsOnly`, `.full`, `.drop`), `.sets`, `.task`, `.note`, `.groceries`, `.timer`, `.list`.

## Rules the fixtures use

From the docs, with the defaults this file had to pick marked **Default**.

1. **Days.** A day runs 04:00 to 04:00, America/Los_Angeles (PDT, UTC-7, all 15 days). A show at 01:30 belongs to the day before. Day 1 is the logical day of his first committed Tess capture (`firstCaptureDay`). Shows before that capture, on the same day, count for day 1.
2. **3 a day.** At most 3 hint shows a day, S, G and H together. Each hint id counts once a day, however often it reappears. **Default:** the placeholder counts as a show, because discoverability §4 counts "hint shows in total" and the placeholder is hint 1 to 6.
3. **When the cap is hit:** no new hint id shows that day. **Default:** the placeholder may reuse a line already shown today if it fits the context; otherwise the field has no placeholder (an empty field under Tess's question). No under-field phrase after the cap.
4. **S lines** show the moment Write opens. Placeholder = the first line still active in the context's list; the one under-field phrase (build sheet: above the field, y 468) = the next active line in the same list. Lists: workout W `S2, S3`; kitchen K `S6`; morning (04:00 to 11:59) `S5, S1`; evening (17:00 to 20:59) `S4, S1`; otherwise `S1`. W beats K beats the time of day. **Default:** in the under-field slot S1 drops ", or ask" and reads "bench 80x8", so a tap fills a real phrase.
5. **G lines** fade in 300 ms after the drying line starts (drying starts at Return) and leave when the ghost commits or is swiped away. A G line hides the under-field phrase. Lists by trigger: after `.lift` `G7, G8`; after `.set` in a workout `G9, G10`; after a dated `.task` `G11`; after an undated `.task` `G12`; after `.groceries` `G13`; after `.timer` `G14`; after `.note` `G15`.
6. **H lines** ("Next time, this works: ...") come from a committed op with actor `.user` and action `logSet` (H16), `createTask` with a date (H17) or `addGroceries` (H18). Each shows **once ever per action**, then retires. At most 1 H line a day. The phrase is built from his object at show time and must parse back through `TessGrammar.parse` to the same kind and title (case-insensitive) and, for a task, the same `startsAt`.
7. **When an H line shows:** the first moment the soul is at rest, Tess's line slot is empty, no ghost is drying and no rest is running. H16 also needs a workout entry in focus, because "80x8" only parses as `.set` with one. It stays 4 s. **Default:** a queued H line waits across days until it can show; it is dropped if the op is undone or the round trip fails at show time. H16 uses his latest hand-logged set on the entry in focus.
8. **Uses.** A use is a committed grammar capture (`source == .grammar`) of the hint's kind that is not undone. Model answers, questions, photo reads, Shortcuts with `commitImmediately` and anything done by hand are not uses. Kinds: S1, G7, G8 `lift`; S2 `set` (same, reps only, full); S3 `set.drop`; G9 `set.repsOnly`; G10 `sets`; S5, G11, G12 `task`; S4, G13 `groceries`; S6, G14 `timer`; G15 `list`. One capture can count for two kinds ("8" is `set` and `set.repsOnly`). Uses keep counting while the Settings switch is off.
9. **Retire:** used (kind reaches 2 uses; a G line drying while the 2nd use commits still shows, then retires), ignored (shown on 3 different days and its kind has 0 uses; checked at the 04:00 rollover), swiped (G or H line swiped right, at once), once (H lines, after their one show), ended (all S and G lines at 04:00 on day 15).
10. **Off:** Settings "Phrase hints" off means no S, G or H lines at all.

## The lines used here (copy from discoverability §6)

| Id | Where | Copy | Words |
|---|---|---|---|
| S1 | placeholder / under field | bench 80x8, or ask (under the field: "bench 80x8") | 4 |
| S2 | placeholder | same, 8, or 80x8 | 4 |
| S3 | placeholder / under field | drop to 70 for 10 | 5 |
| S4 | placeholder | milk, eggs, 2 lemons | 4 |
| S5 | placeholder | dentist thu 3pm | 3 |
| S6 | placeholder | timer pasta 10 | 3 |
| G7 | under ghost | You can also say **3x10 bench 80**. | 7 |
| G10 | under ghost | You can also say **80x8, 80x8, 80x6**. | 7 |
| G11 | under ghost | You can also say **remind me to call mom thu**. | 10 |
| G13 | under ghost | You can also say **buy milk and eggs**. | 8 |
| G14 | under ghost | Rest timers count seconds: **rest timer 90**. | 7 |
| G15 | under ghost | Lists work the same way: **list: packing**. | 7 |
| H16 | beside the soul | Next time, this works: **72.5x10**. | 5 |
| H17 | beside the soul | Next time, this works: **book physio fri 9am**. | 8 |
| H18 | beside the soul | Next time, this works: **buy bread**. | 6 |

G8, G9 and G12 retire by use in this run without ever showing.

## The 15 days

Times are PDT. `[n]` is the day's running show count. Bold = a show.

### Day 1, Thu 1 Oct
| Time | He does | Shows (exact copy) | Ledger |
|---|---|---|---|
| 07:05:10 | Opens Tess on Today, taps Write | **S5 placeholder "dentist thu 3pm"** [1], **S1 above the field "bench 80x8"** [2] | |
| 07:05:40 | Types "call bank fri 10am", Return | 07:05:40.3 **G11 "You can also say remind me to call mom thu."** [3]; gone at commit 07:05:42.0 | `createTask` by `.tess`. firstCaptureDay = 1 Oct. task 1 |
| 18:30 | Opens Write on Today (evening) | S4 would be first, but cap reached. Placeholder reuses S1 "bench 80x8, or ask" (no count). No under-field phrase | |
| 18:31 | "buy oat milk", Return | None: G13 blocked by the cap | groceries 1 |
| 20:10 | Adds "bread" by hand in Groceries | None: cap reached. H18 queued | `addGroceries` by `.user` |

### Day 2, Fri 2 Oct
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 06:50:00 | Opens the app on Today, soul at rest | 06:50:00 to 06:50:04 **H18 "Next time, this works: buy bread."** [1] | H18 retired (once). Day's H used |
| 07:00 | Starts Push A (hold) | | `startWorkout` |
| 07:03 | Logs bench 80x8 by hold | None: rest running. At 07:05:30 rest ends, entry in focus, but the day's H is used. H16 queued | `logSet` by `.user` |
| 07:12:00 | Opens Tess in the workout, Write | **S2 placeholder "same, 8, or 80x8"** [2], **S3 above the field "drop to 70 for 10"** [3] | |
| 07:12:20 | "same", Return | None: cap (G9 would show) | set 1 |
| 07:20 | "8", Return | None | set 2, set.repsOnly 1. S2 retired (used) |
| 07:27 | "8", Return | None | set 3, set.repsOnly 2. G9 retired (used, never shown) |

### Day 3, Sat 3 Oct (rest day)
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 09:58 | Opens the app | None: H16 queued, but no entry in focus, so "80x8" does not parse as `.set` | H16 stays queued |
| 10:00:00 | Opens Write (morning) | **S5 "dentist thu 3pm"** [1], **S1 "bench 80x8"** [2] | |
| 10:00:30 | "dentist tue 3pm", Return | 10:00:30.3 **G11 "You can also say remind me to call mom thu."** [3]; gone at commit 10:00:32.0 | task 2. S5, G11, G12 retired (used) |

### Day 4, Sun 4 Oct
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 17:30 | Starts Pull A | | |
| 17:33 | Logs row 72.5x10 by hold; rest to 17:35:30 | 17:35:30 to 17:35:34 **H16 "Next time, this works: 72.5x10."** [1] | H16 retired (once) |
| 17:41 | Write in the workout | **S3 placeholder "drop to 70 for 10"** [2]. No under-field phrase (S2 retired) | |
| 17:48 | "drop to 50 for 12", Return | 17:48:00.3 **G10 "You can also say 80x8, 80x8, 80x6."** [3] | set.drop 1 |
| 19:30 | Write on Today (evening) | Cap reached, nothing shown today fits evening: empty placeholder | |
| 19:31 | "call plumber mon 9am", Return | None: task kind retired, and the cap | task 3 |

### Day 5, Mon 5 Oct
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 07:00 | Starts Push B | | |
| 07:20 | Write in the workout | **S3 "drop to 70 for 10"** [1] | |
| 07:21 | "incline 30x10", Return (a named lift) | 07:21:00.3 **G7 "You can also say 3x10 bench 80."** [2] | lift 1 |
| 12:30:00 | Adds "Book physio", Fri 9 Oct 09:00, by hand | 12:30:01 to 12:30:05 **H17 "Next time, this works: book physio fri 9am."** [3]. Round trip on Mon: Fri 9 Oct 09:00, "Book physio" | `createTask` by `.user`. H17 retired (once) |
| 18:15 | Write on Today (evening) | Cap reached: empty placeholder | |

### Day 6, Tue 6 Oct
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 07:00 to 07:50 | Legs A, every set by hold | None: H16 already retired | |
| 18:00 | Write on Today (evening) | **S4 "milk, eggs, 2 lemons"** [1], **S1 "bench 80x8"** [2] | |
| 18:01 | "milk, eggs, bread", Return | 18:01:00.3 **G13 "You can also say buy milk and eggs."** [3]; it shows, then retires at commit | groceries 2. S4, G13 retired (used) |

### Day 7, Wed 7 Oct
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 18:40 | Starts cooking carbonara | | `startCooking` |
| 18:42 | Write with the cook running | **S6 "timer pasta 10"** [1] | |
| 18:43 | "timer pasta 9", Return | 18:43:00.3 **G14 "Rest timers count seconds: rest timer 90."** [2] | timer 1 |
| 18:50 | Starts a step timer by hand | None: no H line exists for timers | `startKitchenTimer` by `.user` |

### Day 8, Thu 8 Oct
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 07:15 | Push A; Write in the workout | **S3 "drop to 70 for 10"** [1] | |
| 07:16 | "82.5x6", Return | 07:16:00.3 **G10 "You can also say 80x8, 80x8, 80x6."** [2] | set 4 |
| 07:25 | "80x8, 77.5x8", Return | None: no G line follows `.sets` | sets 1 |
| 20:15 | Write on Today (evening) | **S1 placeholder "bench 80x8, or ask"** [3] (S4 retired). He closes without typing | |

### Day 9, Fri 9 Oct
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 08:30 | Write on Today (morning) | **S1 "bench 80x8, or ask"** [1]. No under-field phrase (S5 retired) | |
| 08:31 | "note: physio said ease off", Return | 08:31:00.3 **G15 "Lists work the same way: list: packing."** [2] | |
| 17:45 | Pull B; Write in the workout | **S3 "drop to 70 for 10"** [3] | |
| 17:46 | "bench 100x5" (a typo), Return, then Undo | None: G7 blocked by the cap | lift stays 1 (undone) |

### Day 10, Sat 10 Oct
| Time | He does | Shows | Ledger |
|---|---|---|---|
| All day | No Tess | None | |
| Sun 11 Oct 01:30 | Opens Write, closes it | **S1 "bench 80x8, or ask"** [1], counted on day 10 | |

### Day 11, Sun 11 Oct
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 10:10:00 | Legs B; Write in the workout | **S3 "drop to 70 for 10"** [1] | |
| 10:10:40 | "100x5", Return | 10:10:40.3 **G10 "You can also say 80x8, 80x8, 80x6."** [2]. At 10:10:41 he swipes the line right: it follows the finger and fades in 200 ms. The ghost keeps drying and commits at 10:10:42.0 | set 5. G10 retired (swiped) |
| 14:05 | Cooking; Write | **S6 "timer pasta 10"** [3] | |
| 14:06 | "timer rice 12", Return | None: G14 blocked by the cap | timer 2. S6, G14 retired (used) |

### Day 12, Mon 12 Oct
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 07:20 | Push B; Write in the workout | **S3 "drop to 70 for 10"** [1] | |
| 07:21 | "bench 3x8 at 80", Return | 07:21:00.3 **G7 "You can also say 3x10 bench 80."** [2]; retires at commit | lift 2. S1, G7, G8 retired (used) |
| 12:00 | Turns Phrase hints off | | |
| 12:05 | "note: lunch with ravi", Return | None: switched off (G15 would show) | |
| 21:00 | Turns Phrase hints on | | |

### Day 13, Tue 13 Oct
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 07:10 | Pull A; Write in the workout | **S3 "drop to 70 for 10"** [1] | |
| 07:11 | "8", Return | None: G9 used, G10 swiped | set 6, set.repsOnly 3 |
| 18:00 | Write on Today (evening) | Empty placeholder: S4 and S1 retired | |
| 18:01 | "note: shoulder ok", Return | 18:01:00.3 **G15 "Lists work the same way: list: packing."** [2] | |

### Day 14, Wed 14 Oct (last day of S and G)
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 07:10 | Write on Today (morning) | Empty placeholder | |
| 07:11 | "note: knee fine", Return | 07:11:00.3 **G15 "Lists work the same way: list: packing."** [1] | G15 now shown on 3 days, list 0 |
| 07:40 | Push A; Write in the workout | **S3 "drop to 70 for 10"** [2] | |
| 07:41 | "same", Return | None | set 7 |

### Day 15, Thu 15 Oct
| Time | He does | Shows | Ledger |
|---|---|---|---|
| 04:00 | Rollover | | G15 retired (ignored; checked before "ended"). S3 retired (ended) |
| 07:10 | Push A; Write in the workout | Empty placeholder | |
| 07:11 | "drop to 70 for 10", Return | None: S and G lines have ended | set.drop 2 |
| 12:00 | Adds a dated task by hand | None: H17 already shown | |

### Totals
Shows per day: 3, 3, 3, 3, 3, 3, 2, 3, 3, 1, 3, 2, 2, 2, 0 = **36**. S 21, G 12, H 3. No day passes 3, no day has 2 H lines.

### Ledger at the end of day 15
| Id | Shown days | Kind uses | Retired | Reason |
|---|---|---|---|---|
| S1 | 1, 3, 6, 8, 9, 10 | lift 2 | Day 12 | used |
| S2 | 2 | set 3 by then | Day 2 | used |
| S3 | 2, 4, 5, 8, 9, 11, 12, 13, 14 | set.drop 1 | Day 15 04:00 | ended |
| S4 | 6 | groceries 2 | Day 6 | used |
| S5 | 1, 3 | task 2 | Day 3 | used |
| S6 | 7, 11 | timer 2 | Day 11 | used |
| G7 | 5, 12 | lift 2 | Day 12 | used |
| G8 | none | lift 2 | Day 12 | used |
| G9 | none | set.repsOnly 2 | Day 2 | used |
| G10 | 4, 8, 11 | sets 1 | Day 11 | swiped |
| G11 | 1, 3 | task 2 | Day 3 | used |
| G12 | none | task 2 | Day 3 | used |
| G13 | 6 | groceries 2 | Day 6 | used |
| G14 | 7 | timer 2 | Day 11 | used |
| G15 | 9, 13, 14 | list 0 | Day 15 04:00 | ignored |
| H16 | 4 | | Day 4 | once |
| H17 | 5 | | Day 5 | once |
| H18 | 2 | | Day 2 | once |

## Cases that show no hint

From the 15 days above:

| # | Case | Day |
|---|---|---|
| N1 | Daily cap of 3 reached: a G line does not show | 1, 2, 9, 11 |
| N2 | Cap reached and nothing shown today fits: empty placeholder | 4, 5 |
| N3 | One H line a day already shown: the next H waits | 2 |
| N4 | H16 queued but no entry in focus, so "80x8" can't parse | 3 |
| N5 | Same action by hand after its H line was shown | 6, 15 |
| N6 | Kind already retired by use | 4, 13 |
| N7 | Swiped G line never returns | 13 |
| N8 | Phrase hints switched off | 12 |
| N9 | Day 15 onward: no S or G line | 15 |
| N10 | A capture with no G line for its kind (`.sets`) | 8 |
| N11 | A timer started by hand: no H copy for timers | 7 |

Standalone (fresh ledger, Thu 15 Oct 2026 unless said):

| # | Setup | Expected |
|---|---|---|
| N12 | Shortcut "Add Task" or the Action button's "Log a Set" (actor `.intent`) | No H line |
| N13 | `RollForwardTasks` moves a task, or `-resetDemo` seeds (actor `.system`) | No H line |
| N14 | Tess logs the set (actor `.tess`) | No H line; it may count as a use |
| N15 | Task added by hand with no date | No H line: "book physio" doesn't parse as `.task` (`TessGrammar.swift:369` needs "remind me" or a date) |
| N16 | Task added by hand Thu 16:00 for today 18:00, H can't show until 18:30 | No H line: at 18:30 "thu 6pm" means next Thursday (4:41 PM PT rule), so the round trip fails |
| N17 | Task added by hand for Fri 23 Oct 09:00 | No H line: "fri 9am" parses to Fri 16 Oct |
| N18 | "train tickets" added to Groceries by hand | No H line: "buy train tickets" parses as a task (4:30 PM PT) |
| N19 | "salt and pepper crisps" added by hand | No H line: "buy salt and pepper crisps" parses as 2 lines |
| N20 | Set logged by hand, then undone before rest ends | H16 is dropped |
| N21 | A ghost is drying, rest is running, or Tess's line "Done. Next one is up." is in the slot | H waits; it is not dropped |
| N22 | A photo read in Show (any route) | No G line, and not a use (4:39 PM PT call 1: photo reads never dry) |
| N23 | Note written by hand in Notes | No H line (no copy yet) |
| N24 | He taps the under-field phrase, then clears the field | Not a use; the show still counts |
| N25 | A question ("bench best?") or a model capture | No G line, not a use |
| N26 | A capture that isn't understood (`source == .none`) | No G line |
| N27 | Tell Tess from a Shortcut with `commitImmediately` | No ghost, so no G line |
| N28 | Speak line (#20) | Not shown until Speak V2 ships |
| N29 | Opening his bench best by hand (#19) | Not in the ledger: no op to observe |

## Swift Testing stubs

`TesseraCore/Tests/TesseraCoreTests/TessHintLedgerTests.swift`, `@Suite("TessHintLedger")`, pinned clock in America/Los_Angeles.

```swift
@Test func dayRollsOverAt0400Pacific()
@Test func showAt0130CountsForThePreviousDay()
@Test func dayOneIsTheFirstCommittedCaptureDay()
@Test func showsBeforeTheFirstCaptureCountForDayOne()
@Test func atMostThreeShowsADay()
@Test func sameHintCountsOnceADay()
@Test func placeholderCountsTowardTheCap()
@Test func capReachedReusesALineShownTodayElseEmpty()
@Test func placeholderPicksFromTheContextList()
@Test func workoutBeatsKitchenBeatsTimeOfDay()
@Test func underFieldPhraseDropsOrAsk()
@Test func gLinePicksTheFirstActiveLineForTheTrigger()
@Test func noGLineAfterSetsQuestionsOrModelCaptures()
@Test func retiresAfterTwoCommittedUsesOfItsKind()
@Test func undoneCaptureIsNotAUse()
@Test func oneCaptureCanCountForTwoKinds()
@Test func gLineDryingOnTheSecondUseStillShows()
@Test func retiresWhenShownOnThreeDaysWithNoUse()
@Test func ignoredIsCheckedBeforeEndedAtRollover()
@Test func swipeRetiresAtOnce()
@Test func sAndGLinesEndOnDayFifteen()
@Test func hLineShowsOncePerAction()
@Test func atMostOneHLineADay()
@Test func hLineOnlyForUserActor()
@Test func hLineWaitsForDryingRestAndTessLine()
@Test func queuedHLineCarriesToTheNextDay()
@Test func hLineDroppedWhenItsOpIsUndone()
@Test func logSetHLineNeedsAnEntryInFocus()
@Test func hLineRoundTripFailsForPassedSameWeekdayTime()
@Test func hLineRoundTripFailsForTaskBeyondAWeek()
@Test func hLineRoundTripFailsForNonFoodGrocery()
@Test func switchOffShowsNothingButStillCountsUses()
@Test func photoReadIsNotAUse()
@Test func allLinesPassTessVoiceViolations()
@Test func fifteenDayFixtureMatchesTheTable()   // replays this file: 36 shows, the end-of-day-15 ledger
@Test func resetHintsClearsTheStore()
```

## Open questions

1. **Day 15 and H lines.** The brief says hints stop on day 15. Both docs say only S and G stop, and H lines keep running for actions never seen. This file follows the docs. Which wins?
2. **Is day 15 the 15th day counting day 1, or 15 days after it?** This file ends S and G at 04:00 on 15 Oct (day 1 = 1 Oct).
3. **Does the placeholder count toward 3?** Counted here. If not, most days gain one G line.
4. **Once per action vs once per kind.** The brief says per action, discoverability says per kind. Mapped 1:1 here (`logSet`, `createTask` dated, `addGroceries`). Does `createTask` without a date get its own H line someday?
5. **G lines retire on kind uses**, so they show at most twice. Track the taught form instead ("3x10 bench 80" vs "bench 85x5")? That needs the parse to report its surface form.
6. **Placement.** Discoverability puts the extra phrase under the field and the H line in the collapsed Bar; the build sheet puts the phrase above the field (y 468) and the H line beside the soul. This file follows the build sheet.
7. **Speak line copy** differs: discoverability #20 "Holding the bar listens: 80 for 8." vs the build sheet "Hold me and say it: 80 for 8."
8. **G lines in Show.** The build sheet puts them under the route words while the ghost dries; the 4:39 PM PT photo call 1 says photo reads never dry. Default here: no G line in Show.
9. **Swipe collision.** Swiping the ghost away discards it; swiping the G line under it retires the line. Which gesture area owns which?
10. **No copy for H lines on timers or notes**, though discoverability §3C lists both. Want "Next time, this works: timer pasta 10."?
11. **H16 copy** "80x8" only parses with an entry in focus, so it can only show mid-workout. Use the lift form ("bench 80x8") so it can show anywhere?
12. **Retire reason "once"** is not in the doc's list (used, ignored, swiped, ended). Add it?
13. **Empty placeholder** after the cap and after all S lines retire: fine, or keep a neutral line?
14. **"Next time"** already opens the Exercise page's progression line ("Next time: 82.5 for 8."). Two different meanings under the same words.
15. **Day helper.** `RollForward.logicalDay` is internal; make it public in `TesseraCore`, or let `TessHintLedger` keep its own 04:00 logic?
16. **Lasting instruction lines** (`RoutineEditor.swift:106`, `ExerciseStrip.swift:103`, `WorkoutModeView.swift:419`) should go through the same ledger (screen-fast-paths). Do they count toward the 3 a day? Assumed not here; they have their own rule (3 views).
17. **Groceries, Notes and Recipes are DEBUG-only roots** on master, so H18 can't fire from a release build until they are routes.
