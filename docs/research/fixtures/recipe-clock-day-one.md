# Recipe clock: the day-one walk (Design 69)

For: Builder B (clock page), Builder A (timers, Live Activity), Core (parser, scheduler), Kitchen lead, QA.
Owner: Research lab. Date: Oct 16, 2026 (Pacific). Master `20f0a16`, traced by hand, nothing was run.

**Sources.** Sheet 69 `docs/design/recipe-clock.md` (Design branch `a4801e4`; not on master yet, decisions 10:00 AM PT
Oct 16 cites it); Kitchen rulings in `product/cook-mode-acceptance.md` "The recipe clock" (#419); step vectors and demo
recipes D1 to D3 in `fixtures/recipe-clock-steps.md` (#427); `fixtures/kitchen-timer-alerts.md` (KT1 to KT19);
`product/cook-mode-script.md`; `product/decisions.md` (CL6, CL9, CL11, AQ6, house rule on side pages).

**Setup.** Thursday Oct 22, Pacific, phone, D1 Paprika chicken pasted from the fixture (not seeded today:
`-demoKitchen` seeds carbonara and dal only, `Features/Groceries/GroceriesView.swift:708`). Groceries empty. First
kitchen timer ever, notifications not asked yet. For QA: `-demoTime 18:28` shifts the page clock; timers ring on the
real clock (KT5), so use a shortened copy of D1 to see rings inside a clip.

## Parser adds already decided (Core)

- **"a side", "per side", "each side"** double the duration they follow: "sear 1 minute a side" is 2 min; "sear 3 min a
  side, then 10 min in the oven" is 16. Master: `RecipeParser.durations` has no side rule (`RecipeParser.swift:172-185`).
- **"overnight"** = 8 h (480 min). A written range in the same step wins ("overnight, 12 to 18 hours" is 12 HR).
  Master: the word is not read, so "Rest overnight." is untimed today.
- Unchanged: lower bound of a range, sum of a step's durations, untimed = 2 min floor and no timer, under 1 min timed
  (drawn at 2), over 3 h fixed 10-minute width with no timer, "Cook time: 20 min" is never a step.

## Quiet hours for alerts

His own timers ring at any hour with sound and haptic, on a closed day too (CL9, CL11, KT2). Quiet hours (11 pm to
7 am) and the day close hold only app-raised asks (AQ6): the one notification permission ask, and nothing else in
this walk. A step lighting is not an alert: Tess's step line and the soft haptic play only in the app, never as a
notification. Focus is his setting (KT12). A wait over 3 h has no timer, so an overnight rise never rings.

## The walk

| # | Moment | He does or says | Expected screen and line | Timers and alerts | Master today |
|---|---|---|---|---|---|
| W1 | 6:28 pm | Kitchen, Recipes, opens Paprika chicken | Name, "serves 4, 45 min"; the clock with steps at 0, 2, 17, 19, 39, 41; key row COOK "45 MIN", INGREDIENTS at right | none | Ingredient column, "6 steps", Cook key; no clock, no step minutes (`Features/Recipes/RecipePage.swift:110-127`); D1 has no time line, so no "45 min" |
| W2 | 6:29 pm | Swipes left anywhere | Peek: clock slides 44 pt and fades, spine and bead stay at left; "SERVES 4", 10 rows; "ADD 7 TO GROCERIES" | none | Swipe sends the whole column at once, no dry-run key word (`RecipePage.swift:170-197`) |
| W3 | 6:29 pm | Taps ADD, then UNDO inside 10 s | "Chicken, 7 added." with UNDO; UNDO removes exactly those 7 rows | none | Count is `result.output.count` (`RecipePage.swift:184-189`); no "Chicken" short name |
| W4 | 6:30 pm | Swipes right, taps COOK | Step 1 lit wet, bead at 0, key row STOP "45 MIN LEFT"; one soft haptic; screen stays awake | Step 1 untimed: no timer | `StartCooking`, "Cooking" plus "Step 1 of 6" (`RecipePage.swift:152-160, 374-378`); no awake |
| W5 | 6:32 pm | Nothing | Bead reaches step 2: lit, "15 MIN" counting down at right; step 1 dims | Roast 15 starts on its own, ends 6:47 pm; request `kitchen-timer.<id>`. First timer: "Want timers to alert you when locked?" Allow · Not now; he allows | Steps never start timers; only "timer X N" does (`TesseraTess/TessGrammar+Kitchen.swift:100`); no ask |
| W6 | 6:42 pm | Looks | Step 2 "5 MIN", key row "33 MIN LEFT" (sheet 69's numbers) | Roast 5 min left | not built |
| W7 | 6:44 pm | "timer bread 8" (garlic bread) | Receipt "Bread, 8 min."; the clock stays one lane | Two timers: Roast 6:47 pm, Bread 6:52 pm | Stored and linked to the cook (`TessCaptureEngine.swift:345-352`); Now shows the cook's soonest (`NowPicker.swift:56-57`) |
| W8 | 6:45 pm | Locks the phone | Lock Screen: cook activity "Roast the potatoes, 2 min" and "+1" | none yet | No cook activity (`Widgets/TesseraWidgetsBundle.swift:7`) |
| W9 | 6:47 pm, locked | Nothing | Banner "Roast, done." / "Paprika chicken, step 2." | One sound and haptic from the notification; activity flips to Done silently (KT18) | Nothing rings: no `UNUserNotificationCenter` anywhere |
| W10 | 6:47 pm, locked | Nothing | Bead reaches step 3 (untimed); activity shows step 3's title, no minutes, plus Bread | No alert: a step start never notifies | not built |
| W11 | 6:48 pm | Unlocks, taps the banner | Page opens in its cook state on minute 18; Roast line flared until stopped; step 3 lit | Roast stays flared (KT17); tap the flare stops it | No `tessera://cook` deep link |
| W12 | 6:49 pm | Nothing | Step 4 lit wet, Tess "Chicken in, on the pan.", "20 MIN" | Step 4 timer, ends 7:09 pm, label "Roast" (the verb by the duration) | not built; the ASSUMED-2 first-verb rule would label it "Add" |
| W13 | 6:50 pm | Swipes left | Peek during the cook: used rows at 42%; "ADD 1 TO GROCERIES" (Greek yogurt) | none | not built (no used set) |
| W14 | 6:52 pm, app open | Nothing | Bread line flares "Bread, done." with the haptic, no banner (KT10) | `willPresent` `[.sound, .list]` | Ended timer drops off Now (`NowPicker.swift:57`) |
| W15 | 6:55 pm | Doorbell: "pause" | Bead holds; key row "PAUSED" with "20 MIN LEFT" kept; Lock Screen shows paused | Proposed: this cook's running timers pause with it; Roast request removed | Pause is slice 12b; no pause grammar |
| W16 | 7:00 pm | "go on" | Bead walks again; later minutes shift +5 | Roast rescheduled, now ends 7:14 pm, same id | not built |
| W17 | 7:14 pm, locked | Nothing | Banner "Roast, done." / "Paprika chicken, step 4." | One ring | Nothing rings |
| W18 | 7:15 pm | Skin not crisp: "5 more minutes" | Step 4 stretches 5 min; bead held at its end until then; "11 MIN LEFT" | Roast restarts, same id, ends 7:20 pm (KT7) | "timer chicken 5" makes a second timer (`Cooking.swift:176-194`); no "more" grammar |
| W19 | 7:20 pm | "next" | Step 5 lit (yogurt); key row still STOP "6 MIN LEFT" | Roast flare stops | "next" → `GoToCookStep` from the stale resume point: "Step 2." (`TessCaptureEngine.swift:363-368`) |
| W20 | 7:22 pm | Nothing | Step 6 lit, "4 MIN"; key row DONE with HOLD | Rest 4, ends 7:26 pm | not built |
| W21 | 7:26 pm | Holds DONE 0.7 s | Stroke dries, steps rest; Tess "Paprika chicken, cooked." UNDO 10 s; line reads "cooked today" | Cook's timers stop silently, pending and delivered removed (KT6); activity ends | Only Tess "done" finishes: "Paprika chicken, done." (`TessCaptureEngine.swift:370-371`); timers marked stopped (`Cooking.swift:248-252`), nothing to cancel |
| W22 | Fri Oct 23, 7 pm | Opens Garlic butter shrimp pasta, COOK | Step 4 "sear 1 minute a side" shows "2 MIN"; key row "16 MIN" | Shrimp timer 2 min | `durations` gives 1, no side rule |
| W23 | Sat Oct 24, 10:30 pm | No-knead bread, COOK, step 2 at 10:32 pm | Step 2 "12 HR" at fixed width, no countdown; key row "2 HR 45 MIN LEFT" | No timer: nothing rings overnight | 720 min passes the 24 h cap (`Cooking.swift:177`) if a timer is started; "overnight" alone unread |
| W24 | Sat 11:05 pm | "timer tea 4" | "Tea, 4 min." | Rings 11:09 pm with sound and haptic (CL9). Had this been his first timer, the ask holds to the next timer after 7 am (KT Q1) | Stored; silent |
| W25 | Sun Oct 25, 10:30 am | Opens Kitchen | Bread cook suspended after 45 min idle; COOK picks it up on step 3 | none | Cooks never go idle (`ProcessTable.swift:87`, workouts only); stays Now all night; COOK resume exists (`Cooking.swift:91-101`) |

## Gaps

| # | Gap | Proposed fix | Owner |
|---|---|---|---|
| G1 | No clock: no step start and end minutes, used set, or `RecipeClockView` | Core's 69 slice against `recipe-clock-steps.md`, then the page in one cook state | Core, Builder B |
| G2 | Nothing rings and no cook Live Activity (W9, W17) | `NotificationScheduler` per KG1; `CookTimerAttributes` with soonest plus "+N" | Core, Builder A |
| G3 | Bead walks real time, but the resume point moves only on "next" (W19 says "Step 2.") | One source: the bead's step is the resume point; "next" and swipe move both (see ★) | Kitchen lead, Core |
| G4 | Steps don't start timers | Bead entering a timed step starts its timer, keyed by step, not label (a second "Roast" must not restart step 2's) | Core, Builder A |
| G5 | "per side" and "overnight" not parsed | The two adds above, with vectors s5, s6, s11, s12 | Core |
| G6 | Timer label from the first verb gives "Add" | Label = the verb nearest the duration, else "Step 4" | Kitchen lead |
| G7 | Pause and "5 more minutes" undefined on the clock | Pause holds bead and this cook's timers; "N more" restarts the step's timer and stretches its span | Kitchen lead, Builder A (12b) |
| G8 | A spoken timer in a cook has no place on the clock (W7) | A labelled line under the key row, outside the stroke | Builder A, with Design |
| G9 | Done line says "done", not "cooked"; no DONE hold | `FinishCooking` line "Paprika chicken, cooked."; DONE key | Core, Builder B |
| G10 | Peek key is not a dry run; no short name | Dry run of `AddRecipeToGroceries`, receipt "Chicken, 7 added." | Core, Builder B |
| G11 | Cooks never idle-suspend; screen not kept awake | 45 min idle rule for cooks; idle timer off while the clock runs | Core, Builder B |
| G12 | D1 to D3 not seeded; context line lacks "45 min" without a time line | Seed under `-demoKitchen`; fall back to the clock total | Builder B |

★ **For Product:** when a timed step runs over (W18), does the bead hold at the step's end until he moves on, or keep
walking at real time and light the next step on its own? Proposed: hold, and the minutes ahead shift.

**Ruled (Product, decisions.md 12:05 PM PT):** the bead waits at the end of a step that runs over until he moves on, and later minutes shift. G2 is Core CL6 (cook timers ring on a locked phone); Core also takes G3, G4 and seeding D1-D3; Builder A takes the cook-timer Live Activity; G1 is on the 69 slice. Pause and "5 more minutes" are with the Kitchen lead.

**Ruled (Kitchen lead, product/cook-mode-acceptance.md rulings 3-5 and ASSUMED-2, #461):** pause holds the bead and this cook's step timers (key row PAUSED, pending step notification removed; a spoken timer keeps running); resume shifts later minutes by the paused length. "5 more minutes" / "5 more" / "give it 5" stretches the current step and restarts its own timer under the same id (KT7), never a second timer. Timer label is the verb nearest the duration ("Roast"), else "Step N". A spoken timer sits on its own labelled line under the key row ("Bread · 8 MIN"), soonest first, and survives pause and done. W23 "2 HR 45 MIN LEFT" stands; 2 HR 47 is the at-rest figure.
