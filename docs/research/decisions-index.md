# Decisions index: Oct 15, 2026

*Index of `../product/decisions.md` as it stood on Oct 16 (through the 6:37 PM PT "Tess voice sync" entry, L173). One line per entry: the rule, its time in Pacific, and a pointer (`L<n>` is the line in decisions.md, plus its bold heading). Board item 48.*

## How "today" was set

- The two dated headings (L5, L14) say 2026-10-15. The section headed "Earlier" (L35) also holds Oct 15 calls: entries from 18:50 to 19:47 are UTC on Oct 15 (L62 says so), and entries from 1:56 PM PT on are Pacific (two say "Oct 15" outright, L128 and L129). Every timed entry is therefore Oct 15 Pacific.
- UTC times are converted (PDT is UTC-7). The L5 and L14 headings give 18:41 and 18:40 with no zone; they are UTC like their neighbours, so 11:41 AM and 11:40 AM PT.
- L59 and L67 have no time. They count as today because they sit between timed Oct 15 entries.
- L37 to L40 (body weight, Lists, Tess, Cook mode) have no time and come before the first timed entry. They may be older, so they are listed under "Undated" and not counted. Two of them come up in Contradictions.
- Note on the log itself: the top says "Newest first", but "Earlier" runs oldest first, and the L5/L14 headings give no zone.

## Training (12)

- Watch: yes; sleep stages and resting HR in M4 slice 2; "In bed" stays for nights without the Watch. 11:41 AM. L11 "Apple Watch"
- Without a Watch, sleep shows time in bed ("In bed 7h45"). 11:40 AM. L23
- Resting HR older than 36 hours is hidden. 11:40 AM. L24
- No Watch app yet; read sleep, resting HR, HRV and workout HR from Health; W1 and W2 now, W3 and W4 later. 12:11 PM. L48 "Apple Watch: no Watch app yet"
- Exercise page leads with history and progress; logging stays in the live workout; keep the newer Review screen. 12:47 PM. L60 "Research's three questions"
- One way back into a running workout: the lit top seam plus the Live Activity. 12:47 PM. L61
- On a planned rest day, rest wins on Now with a quiet "Rest day" line; the routine stays one tap away. 3:37 PM. L63
- Rest day order on Now: running process, then an event or timed task within 15 min, then "Rest day"; rest never hides time-bound things. 4:01 PM. L68 (narrows L63)
- W3 recovery line: 28-day baseline, no HRV percent, never feeds "light day"; waits for a HealthKit read layer. 4:13 PM. L74
- Review week: opens with a session count, rest days get a dab, the miss ring marks only real misses, two sessions in a day count as two. 4:58 PM. L127
- Empty states: a zero-set finish is not saved and never counts as trained; plan targets count from creation day; "good day" means at least one set; text-only `EmptyLine`; PPL x2 stays. 5:14 PM. L137 "Empty-state open questions"
- A workout, or a session crossing 4 AM, belongs to the day it started. 6:06 PM and 6:07 PM. L160 item 2, L163

## Grammar (10)

- Grammar collision fix goes right after model layer T1/T2, ahead of Groceries polish. 11:58 AM. L43
- Reading grammar collisions are fixed in Core's first M5 Reading engine slice. Undated, about 3:55 PM. L67
- One M5 parse order: notes, pasted recipes, relative sets; reading, money, people; comma sets, lifts, kitchen; upkeep; tasks. 4:10 PM. L69
- Live misfires ("watered plants sat", "get mom a card", "coffee with ravi at 7") get a Core fix batch right after the ranker. 4:10 PM. L71
- Past-tense logs before Upkeep/People land become a note dated that day, not a task. 4:26 PM. L79 (call 2)
- `buy` stays Groceries and Tess names the list; non-food `get` is a task. 4:26 PM. L80 (call 3, amended by L84)
- "is" questions ("is the gym open sat") go to the question path, never to a task. 4:26 PM. L81 (call 4)
- Core order: N1, then a hotfix for the sweep's top 5 root causes, polish PR, rest of grammar, Day log v1, meal plan feeds groceries. 4:26 PM. L83 "Grammar comes first"
- "buy" with a clearly non-food object is a task; unclear objects default to Groceries. 4:30 PM. L84
- Regression calls: "table" is not a meal word; "next fri" is next week's Friday; R13c/f/g/i/j taken; "paid 12.50 at 12.30" is amount then time; "done" while a timer rings ends the timer first; test clock on LA time. 5:58 PM. L150

## Time and day (8)

- All times shown to Kaushik are Pacific, never UTC; new log entries use PT. 1:56 PM. L62
- "call mom thu" said on a Thursday means today. 11:58 AM. L42
- Bare hours: 1 to 6 are PM, 7 to 11 are the next one not yet passed today, 12 is noon; Tess never asks. 4:26 PM. L78 (call 1, partly replaced by L103)
- A time today that has passed lands tomorrow at that time; ghost row says "Tomorrow 7 am". 4:26 PM. L82 (call 5)
- Time forms: a named weekday said on that day after its time means next week; bare 7 to 11 on another day is PM only with a meal or evening word; "tonight" after 8 PM stays today until 11:30 PM. 4:41 PM. L103
- Light day: squeezed week, 480+ booked minutes or 5+ fixed blocks, never Health; calendar read once 4 AM to 4 AM, titles only (40 chars); midnight cuts move to 4 AM. 5:48 PM. L146
- The 4 AM day comes first for Core after N1: a DST-safe `TesseraDay`, then one-line swaps. 5:56 PM. L149
- Zones and late night: each log stores its zone; "1:30am" on Nov 1 is the first one; day caches keyed by zone; "tomorrow" before 4 AM means the coming daytime and the reply names the weekday ("Dentist, Saturday 3 pm"). 6:06 PM and 6:07 PM. L158, L163

## Undo and copy (7)

- Widget and snippet copy: "All quiet."; "×" in sets; FinishWorkoutIntent uses `WorkoutSummary.line`; "Set 3 taken back". 5:02 PM. L128
- One undo rule: name the thing, then what happened; Undo says the same name plus "taken back"; UNDO reverts the record its line names; "Undone." goes. 5:14 PM. L129
- Undo defaults: Siri "Undo Last Set" removes one set; silent writes stay silent; undoing a finish deletes the Health workout; destructive writes keep UNDO 10 s, not 4. 5:14 PM. L130
- Hint ledger: S and G lines stop on day 15 (4 AM days); H lines read "Next time, just say it: ..."; in Show the hint sits under the waiting ghost with no dry time. 4:50 PM. L104
- Back word: "< NAME" replaces every system back button, "< HOME" replaces "Close", edge swipe stays. 4:12 PM. L72
- No rounded-rectangle, oval or pill buttons anywhere, Apple defaults included. 12:00 PM. L45
- Tess voice sync: Tess times use master's format ("Saturday 3 pm", "9 am"); undoing a removal says "Set 3 is back.", the one exception to "taken back"; the 21 disagreeing lines go to their owners. 6:37 PM. L173

## Claude (10)

- Claude for Plan my day: yes; M4 slice 6b unparked. 11:41 AM. L8
- Claude is part of the base, built in early; a "Tess model layer" slice goes early after tonight's release. 11:41 AM. L9
- Plan my day: window ends 21:00, DayLoad counts free time to 23:00; ghost lines are tasks only; full days drop Later offers; priority ignored. 11:40 AM. L17 to L20
- Questions: minimal query AST from `questions-eval.md`; movement pattern is a field filter; list items get a date. 11:40 AM. L28 to L30
- Model layer: Research T1 to T7, S1, S2 are the plan; $10 a month hard stop, no daily cap; streaming allowed. 11:50 AM. L41
- Model tools: add completeTask and rescheduleTask (10 in all). 12:12 PM. L50
- Plan my day fallback on timeout or failure: "Here's your usual plan." 12:22 PM. L52
- Key entry: Kaushik types the key into a Settings field (Keychain, this device only) with a Test call; $10 cap ships in v1; key never in repo, docs or threads. 5:49 PM. L147
- A rolled-over task is flexible, never timed, in the ranker and the planner. 5:41 PM. L145
- First uses: grammar misses to Haiku once the key Test passes; plan wording on Sonnet after gates; log questions on Haiku after a question-only mode; answerQuery counts only finished workouts; new line "Claude is busy. Kept it for later." 6:22 PM. L166 to L170

## Kitchen (8)

- Home rail gets KITCHEN as a fourth word. 11:41 AM. L7
- Recipe fetch from a pasted link: approved for kitchen v2, which still waits for a week of use. 11:41 AM. L10
- Cook mode has its own idle rule (never suspended while a timer runs or within 45 min of the last step); paste-hardening slice adds `packSize` and `section`. 11:58 AM. L44
- Recipe fetch uses an honest Tessera user agent; blocked sites get "paste the text"; entry is an App Intent plus Shortcut; Recipe gets `sourceURL`. 12:07 PM. L47
- Cook stays hidden until cook mode (slice 12) lands. 12:47 PM. L60 (second call)
- Lists daily-use gaps: all 13 defaults taken; G1 "Lists" HomeLink under Groceries. 3:53 PM. L65
- Cook timers: bare length takes the step verb; unnamed means flared then soonest, never asking; bare-number cap 180 min; "2 onions" mid-cook writes nothing; under 2 min reads in seconds; Extend and Pause wait for 12b. 4:50 PM. L105
- Cook mode screen moves from Core to Builder A. 3:50 PM. L64 (first clause)

## M5: Money, Reading, Upkeep, People (8)

- Reading approved with all defaults: a book never takes Now from a workout; evening slot from 19:00; never put away; its own app, offline first. 11:40 AM. L33
- Money approved: no home currency; bare amounts only with two decimals or a currency mark; "total?" asked once after a shop; one-word category; ordinal in feedback; bank data parked. 12:07 PM. L46
- Upkeep approved with all seven defaults, after Money, needs M3 slice 2. 12:11 PM. L49
- People approved with all 9 defaults, after Upkeep, no Contacts access. 12:22 PM. L53
- Money copy stays currency-neutral ("Groceries, 38.20") until the home currency question is answered; amounts stored as typed. Undated, about 12:40 PM. L59
- Money defaults: no merchant field; four currencies; a bare "38" answers a waiting shop total only when no workout runs; "paid" plus amount is a spend; a split logs his share. 4:10 PM. L70
- "paid" plus an amount belongs to Money, and ticks a named chore in the same ghost row. 4:34 PM. L86
- Upkeep starters: 12 shown plus "more"; noun-first logs work; "fine" counts for check chores; seasonal chores are plain 30 days; "alarm" is no longer an AM cue. 4:50 PM. L116

## Notifications (5)

- W3 asks for Health with a one-time line on Now; a no is final. 4:20 PM. L75
- One ask a day: at most one permission or one-time ask per 4 AM day, never from a background finish. 5:56 PM. L148
- First set: timed task, rest done while closed, cook timer done; quiet hours 11 PM to 7 AM; a task with no time is never saved as 9:00. 6:20 PM. L164
- Ask lines final: the notification ask fires only on the first "remind me", timed task or cook timer; rest notification rings and the Live Activity stays silent, never both. 6:30 PM. L171 (supersedes old Q5/A7)
- "remind me" plus a day alerts at 9 AM; "call mom sat" gets no time and no alert. 6:30 PM. L172

## Other (16)

- First phone build cut at 12:45 PM PT (19:45 UTC), reviewed with `review-session.md`, then a huddle. 11:41 AM. L12
- Calendar denied: one plain line with a Settings link, never an error. 11:40 AM. L25
- One ground layer: show what matters now, reveal more on demand; Ask Tess becomes a glyph that opens a capture surface. 12:18 PM. L51
- Build list approved; A1 (undo for schema changes) first, after M3 slices 3, 6, 10 and T1 to T3. 12:22 PM. L54
- Context ranker: NowPicker rebuilt around `rank()` as Core Next 3, after v1 gaps and the grammar fix. 12:27 PM. L55
- Capture surface ships Write, Speak and Show; images never leave the phone; Core adds a photo field. 12:30 PM. L56
- Backup and restore is Core Next 1: daily .tessera copies, newest 7, in an iCloud Drive folder he picks. 12:37 PM. L57
- Design goes breadthwise: a "just enough" sheet for every upcoming screen, deepen after use. 12:37 PM. L58
- Screen work spread: Reading and Money screens to Builder A; every area's first screen gets a HomeLink word. 3:50 PM. L64
- Day log v1 brought forward; a started workout with sets shows on the day even if never finished. 3:53 PM. L66
- Day log rule gaps: proper singulars; captures fold into one line; a planned rest day shows "Rest day". 4:30 PM. L85
- Build A1: a shipped field can be hidden, never deleted; keys never reused; 11 blockers. 4:13 PM. L73
- Show and hints split: Builder B builds the Show layer and hint lines; Core builds PageReader and the hint ledger. 4:22 PM. L76
- Show photo calls: a photo read never commits by itself; card numbers refused; duplicates flagged; 14 calls plus "1,280" as a thousands mark. 4:39 PM. L87 to L102
- Accessibility mostly waits; pulled forward: the MotionPolicy Reduce Motion fix and Home queue heights. 5:25 PM. L144
- The review guide tags every item with its PR or branch and every gap with its fix. 6:20 PM. L165

## Undated (not counted as today)

- Body weight: the trend line is the headline. L37
- Lists: "reusable", never "template"; Copy next to Reset; a preview before saving a paste. L38
- Tess: grammar first, then the on-device model; cloud models need Kaushik's OK. L39
- Cook mode: Core builds it, Builder A reviews the shared instruments. L40

## Contradictions

Rule of thumb: the later entry wins unless it is narrower, in which case it is an exception and both stand.

1. **Same-day weekday.** L42 (11:58 AM): "thu" said on a Thursday means today. L103 (4:41 PM): "thu 3pm" said on a Thursday after 3 PM means next Thursday, "because a named weekday means that weekday". Later: L103, narrower. Resolve: both stand; a named weekday on that day means today unless its time has passed, then next week. Restate L42 with that clause.
2. **Bare hours on other days.** L78 (4:26 PM): 7 to 11 mean the next one not yet passed. L103 (4:41 PM): on another day they are AM unless a meal or evening word. L103 says it replaces part of the 4:26 calls, but L78 is not marked. Resolve: L103 wins for other days; mark L78 "amended at 4:41 PM".
3. **"tonight".** L103 (4:41 PM): after 8 PM stays today "until 11:30 PM". L150 item 2 (5:58 PM): after 8 PM means tonight "as at 4:41", with no cap. After 11:30 PM, and before 4 AM under L149, is undefined. Resolve: L150 cites L103, so keep the 11:30 PM cap; say what "tonight" means from 11:30 PM to 4 AM (default: the coming evening, as "tomorrow" before 4 AM in L163).
4. **"tonight" vs quiet hours.** L103 lets "tonight" land on today up to 11:30 PM; L164 (6:20 PM) holds notifications 11 PM to 7 AM. A "tonight" task timed 11 to 11:30 PM saves but never rings. Resolve: product call; default: the task stays as typed and the ghost row says it will not ring.
5. **9:00 for undated tasks.** L164 (6:20 PM): a task with no time is never saved as 9:00. L172 (6:30 PM): "remind me" plus a day rings at 9 AM. Later: L172, narrower. Resolve: both stand; store the alert at 9 AM only for "remind me", and add "except a 'remind me' alert" to L164. Fix `notifications.md` N1 (tess-voice X20).
6. **Bare money amounts.** L46 (12:07 PM): bare amounts need two decimals or a currency mark. L70 (4:10 PM): a bare "38" answers a waiting "total?". Later: L70, narrower. Resolve: both stand; the reply to "total?" is the one exception. Add it to `ship-list-m5-money.md`.
7. **Home currency.** L46 (12:07 PM) decides "no home currency"; L59 (about 12:40 PM) treats it as an open question for Kaushik; L70 (4:10 PM) sets four currencies. Resolve: L70 wins on currencies; reword L59 so no one waits on an answer already given, or move the question to the morning list explicitly.
8. **`buy` routing.** L80 (4:26 PM call 3): `buy` stays Groceries. L84 (4:30 PM): non-food `buy` is a task, and says it amends call 3. Resolve: L84 wins; mark L80 amended.
9. **Core's queue.** L83 (4:26 PM): after N1 comes the grammar hotfix. L149 (5:56 PM): after N1 comes the 4 AM day. L71 (4:10 PM): grammar fix batch right after the ranker, while L55 (12:27 PM) puts the ranker after the grammar fix, and L66 puts Day log after the ranker. Resolve: latest wins: N1, `TesseraDay`, grammar hotfix, polish, rest of grammar, ranker, Day log v1. Coordinator to restate the queue in one place.
10. **What counts as trained.** L66 (3:53 PM): an unfinished workout with sets shows on the day. L137 (5:14 PM): a good day is at least one set logged. L170 (6:22 PM): answerQuery counts only finished workouts. Review and a question can disagree on the same week. L170 is later but narrower, so it does not win by default. Resolve: Product picks one definition (default: L137, at least one set), and answerQuery follows it.
11. **Cook ownership.** L40 (undated): Core builds cook mode. L64 (3:50 PM): the cook mode screen moves to Builder A. Resolve: L64 wins; mark L40 superseded.
12. **Cloud models.** L39 (undated): grammar first, then the on-device model, cloud needs Kaushik's OK. L9 (11:41 AM) makes Claude part of the base, and L166 (6:22 PM) sends grammar misses to Haiku. Resolve: the OK is given, so mark L39 superseded by L9 and L41.
13. **Cook word on Home.** L64 (3:50 PM): every area's first screen gets a HomeLink word. L60 (12:47 PM): Cook stays hidden until slice 12. Later: L64, but broader. Resolve: L60 stands as the exception for Cook only; KITCHEN (L7) is shown, its Cook entry is not, until slice 12.

Checked, no conflict: rest day (L68 narrows L63 and says so); Q5/A7 (L171 supersedes it and L164 agrees); the one-ask rule (L148, L171, L75); "×" vs the typed hint "bench 80x8" (input, not a Tess line); the $10 cap (L41, L147); "Set 3 is back." (L173 is a stated, narrower exception to L129, so both stand); time format (L173 sets "Saturday 3 pm" / "9 am" and L82 and L163 were rewritten to match; "9 AM" in L172 is prose, which L173 allows).

## Cross-check: tess-voice.md "Lines that still disagree with decisions.md"

All 21 rows (X1 to X21) set a line in tess-voice or a research file against a decision. None is a decision-vs-decision conflict. Notes:

- X6 and X19 (time format): never a decision-vs-decision clash; settled at 6:37 PM by L173 in master's favour ("Saturday 3 pm"), and L163 and L82 now match. Leftover nit: L82 writes "Tomorrow 7 am" with no comma, while L163 writes "Dentist, Saturday 3 pm"; that is a ghost-row label vs a reply, so it is fine as is. The 24-hour plan ghost lines in `claude-first-uses.md` should follow L173.
- X20 (09:00): it is the file's N1 that disagrees with L164 and L172. The decision-vs-decision part is Contradiction 5 above, and it resolves the same way.
- X11 ("Set 3 is back"): an exception to L129, granted by L173; not a clash.
- X12 (4 s vs 10 s): L130 already settles it; only `undo-lines.md` is stale.
- The rest (X1 to X5, X7 to X10, X13 to X18, X21) are copy updates to match L128, L129, L130, L137 and L163.
