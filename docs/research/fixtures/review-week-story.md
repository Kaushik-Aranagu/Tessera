# Review week story: 12 weeks (Product item AD)

For: Builder B (Review, #348 #352), Core (WeekFacts, DayStory, the weekStory job), Product. Owner: Research lab.
Oct 16, 2026 (Pacific). Read at origin/master **ec47bd3**; traced by hand, nothing run, no API called. All values made up.

**Setup for every case.** Monday 04:00 to Monday 04:00, America/Los_Angeles, kg, PPL x2 rolling at 6 a week
(Push A, Pull A, Legs A, Push B, Pull B, Legs B), Sunday rest. Read on Sunday at 9 pm unless the case says so.
The page is `ReviewPage` (Features/Home/ReviewPage.swift:218) fed by `ReviewWeekData` (Features/Home/ReviewWeek.swift:29).

**Expected rules used.** Hero is the session count in words (decisions 11:50 AM). Bands: Training "{w} of {p}",
Tasks done, Cooked (shown only with a cook). Week lines are the three plain rules lines (decisions 11:45 AM, item 5;
templates from `week-rules-lines.md`: "{w} of {p} workouts, {b} new bests." / "{t} tasks done, {c} cooks." /
"{next} is first up Monday."). A tapped day: hero is the thing first ("Bench best, 3 done"), then its log lines with
12-hour lowercase times. An empty day says "All quiet." once. Weekdays come from the 4 am day. "Best", never "record".
**Claude:** the week just ended, Monday after 04:00, facts changed, never in a live workout; Tess shows working
(decisions 12:14 PM, `soul-ask-claude.md` A8); Home lines send nothing. The pack (`week-story-job.md` §1.2) may carry
counts, routine and recipe titles, best exercise short names, weekday words, `next`; it may never carry DayLine text,
weights, reps, minutes, clock times, task titles, notes, places or zones, money, body or health.
**HomeLines caps:** Review does not reuse HomeLines (no reference in ReviewPage.swift or ReviewWeek.swift), so its
6-word / 32-character caps don't apply; the story uses the detail slot (14 words, 80 characters).

Verdicts: H headline, B bands, L week lines, T tapped day (clock format counted once, in gap 6), C Claude.

| # | Week, seeded | Expected | Master today | Verdict |
|---|---|---|---|---|
| W1 | **Full week** Oct 5-11. All 6 done Mon-Sat; Push A Mon 6:10 pm, Bench best (85 × 8); Squat 5RM and e1RM best on one set Wed; 14 tasks; chili Sun 7 pm | H "All six sessions". B Training 6 of 6, Tasks 14, Cooked 1 (Sun). L "6 of 6 workouts, 2 new bests." / "14 tasks done, 1 cook." / "Push A is first up Monday." T Mon: "Bench best, 3 done"; "6:10 pm Push A, 58 min. Bench 85 × 8, best." C yes, Mon Oct 12 after 4 am; may: 6, 6, 2, 14, Bench, Squat, chili, Push A, Monday; never 85, × 8, 58 | H ReviewWeek.swift:74. Bests one per exercise WeekFacts.swift:97. L shows DayLine picks "Mon Push A, 58 min. Bench 85 × 8, PR." (WeekFacts.swift:152, ReviewWeek.swift:130). T hero "Push best, 3 done": it splits the line's first word (ReviewWeek.swift:175); ", PR" (DayStory.swift:225) | H pass, B pass, L wrong, T wrong, C not built |
| W2 | **Missed and paused** Oct 12-18. Push A Mon, Pull A Tue, nothing Wed, Legs A Thu 7:05 pm paused after 4 sets and never finished, Push B Fri, Pull B Sat; 9 tasks | H "Five sessions" (a logged set is trained, decisions 6:44 PM). B 5 of 6; Wed open ring, never "missed"; Thu sage. L "5 of 6 workouts." / "9 tasks done." / "Legs B is first up Monday." T Thu: "Legs A"; "7:05 pm Legs A, 4 sets." no words about pausing | Unfinished workouts are skipped (WorkoutSummary.swift:102): H "Four sessions", 4 of 6, Thu open ring. T Thu "A quiet day" (ReviewWeek.swift:187) over a faint "19:05 Legs A, 4 sets. Squat 100 × 5." | H wrong, B wrong, L wrong, T wrong, C not built |
| W3 | **Trip day** Mon Oct 26 in New York. Push A 6:30 am ET (3:30 am PT); "call the bank" done 4:30 am ET Tue (1:30 am PT); read Fri Oct 30 at home | B Push A on Mon; the task on **Tue** (filed where he was). T Mon: "Push A"; time question Q7. C may: Push A, Monday; never New York, a zone or a time | Training on Mon via OpZones (WorkoutSummary.swift:103) passes. Tasks band uses the phone zone, so the task lands Mon (ReviewWeek.swift:58; cooks :64), though WeekFacts files it Tue (WeekFacts.swift:220). Tap lead "03:30" | H pass, B wrong, L wrong, T pass, C not built |
| W4 | **DST week** Oct 26-Nov 1. Legs B Sat Oct 31 11:50 pm to Sun 1:40 am PST (the repeated hour); a task done Sun 1:30 am PDT | Both on **Sat**; Sun rest stroke; 6 of 6; seven columns. T Sat: "11:50 pm Legs B, 170 min." (real minutes). C no clock digits, no minutes | 04:00 edges by `bySettingHour` (TesseraDay.swift:65) hold; start-day filing passes. Tap lead "23:50" | H pass, B pass, L wrong, T pass, C not built |
| W5 | **Empty week** Oct 19-25 (used before). Nothing logged | H "A quiet week". B 0 of 6, six open rings, Sun rest; Tasks 0 as dots; no Cooked band. L "No workouts this week." / "Nothing else logged." / "Push A is first up Monday." T Wed: "All quiet." once, no second empty line. C not asked (Q6) | H ReviewWeek.swift:73 passes. L "Nothing written down yet." (ReviewWeek.swift:340). T "A quiet day" (ReviewWeek.swift:187) plus "Nothing written down yet.": two empty lines | H pass, B pass, L wrong, T wrong, C not built |
| W6 | **Only private notes** Sep 21-27. "wifi password is tacocat" Mon, "door code 4417" Wed, "my password is hunter2" Fri | As W5 for H, B, L: notes never make a week line. T Mon: "9:12 pm Private note" and nothing more. C no call (pack equals W5's); never tacocat, 4417, hunter2 or "note" | WeekFacts ranks every `.finished` line (WeekFacts.swift:157), so L reads "Mon Private note / Wed Private note / Fri Private note". T passes (DayStory.swift:347). Full Review counts "3 notes." (ReviewView.swift:118) | H pass, B pass, L wrong, T pass, C not built |
| W7 | **Money and body** Sep 14-20. "$212.37 at Costco" Tue; "82.4 this morning" Mon, Wed, Fri; "slept 5 hours" Thu; 4 workouts; 5 tasks | No 212.37, 82.4, kg of body, sleep on any band, line, tap or pack. "Four sessions", 4 of 6. #83's "weight down 0.4 kg" clause only if Product keeps it (Q5) | No money or body object exists in Core, so nothing can show (pass by absence). WeekFacts says so (WeekFacts.swift:3). #83 clause not built | H pass, B pass, L wrong, T pass, C not built |
| W8 | **Live at 4 am** Oct 12-18 variant. Mon-Fri done, Sat missed, Legs B starts Sun 11:30 pm, still running Mon 4:10 am, finished 4:40 am | Sun 11:55 pm: "Five sessions", Sun unmarked, running line in ink. Mon 4:10 am: no story call while live (N7). After 4:40 am Sun counts (start day): 6 of 6, one call | Start-day filing (WorkoutSummary.swift:104) and the 6 h running line (DayStory.swift:230) pass. No job, so no live guard | H pass, B pass, L wrong, T pass, C not built |
| W9 | **Month split** Sep 28-Oct 4. Pull B 12:20 am Thu Oct 1; a task done 3:50 am Oct 1 | Both on **Wed Sep 30**; letters M T W T F S S. T Wed: "12:20 am Pull B, 61 min." | 4 am day passes across the month. Tap lead "00:20" | H pass, B pass, L wrong, T pass, C not built |
| W10 | **Day mark back one day** Oct 12-18 variant. Nothing Tue; Wed 8 am "was sick yesterday"; 5 done | Tue rest stroke, not a ring; 5 of 5; T Tue: "Rest day" alone. "sick" never on Review, in memory ("rest day") or to Claude. "sick 2 days ago" marks nothing | No day-mark object in Core; Tue is `wasDue` (WeekView.swift:90): open ring, 5 of 6, "A quiet day" | H pass, B not built, L wrong, T not built, C not built |
| W11 | **Cooking** Oct 5-11 variant. Tacos Tue and Thu 7 pm, chili Sun; Mon, Wed, Fri trained; 6 tasks | B Cooked 3 (three dabs). L2 "6 tasks done, 3 cooks." T Thu: "Tacos"; "7 pm Tacos, 35 min." | Band counts per day (ReviewWeek.swift:63). Hero forms ignore cooks (ReviewWeek.swift:178-190): Thu reads "A quiet day" | H pass, B pass, L wrong, T miss, C not built |
| W12 | **First week** First use Wed Oct 14 8:10 pm, nothing that evening; Thu, Fri, Sat trained | H "Three sessions" (VoiceOver "...in your first week"). B 3 of 3; Mon-Wed no mark. L1 "3 of 3 workouts since Thursday." T Mon: not readable (a tap returns to the week) | Late start handled in WeekFacts (WeekFacts.swift:88-94), but the band reads perWeek: "3 of 6" (ReviewWeek.swift:100). T Mon hero "Still ahead" (ReviewWeek.swift:189) | H pass, B wrong, L wrong, T wrong, C not built |

**Counts (60 checks).** pass 25, wrong 20, miss 1, not built 14. By column: H 11 pass, 1 wrong; B 8 pass, 3 wrong,
1 not built; L 12 wrong; T 6 pass, 4 wrong, 1 miss, 1 not built; C 12 not built.

## Top gaps

1. **Week lines are DayLine picks, not the decided count lines** (all 12). They carry weights, minutes and "PR".
   Core: a `WeekRulesLines` from `WeekFacts` (week-rules-lines.md §1). Builder B: draw it in `WeekLines`, drop `bestLines`.
2. **Tapped-day hero parses text.** "Push best" from the first word (ReviewWeek.swift:175); DayStory still says ", PR"
   (DayStory.swift:225) though "best" is decided everywhere. Core: "best" in DayStory. Builder B: hero from `WorkoutSummary.records`.
3. **A paused or unfinished session with sets is not trained** (WorkoutSummary.swift:102), against decisions 6:44 PM. Core.
4. **Bands read the phone zone** (ReviewWeek.swift:58, :64) while WeekFacts uses OpZones. Builder B: read `WeekFacts.days`.
5. **Empty states.** "Nothing written down yet." and "A quiet day" stack; private notes rank as week lines
   (WeekFacts.swift:157). Builder B: "All quiet." once. Core: only workouts, cooks and firsts rank.
6. **Clock leads are 24-hour** ("18:10", ReviewWeek.swift:193 via DayLine.clock) in every tapped day. Builder B, after Q3.
7. **The weekStory job is not built:** no `WeekPack`, handles, ids, live guard, working soul or cache. Core.
8. **Smaller:** cooks missing from the day hero (W11), "Still ahead" before first use and "3 of 6" in a first week
   (W12), day marks (W10). The full Review screen still has its own hero, "Something done on four days"
   (ReviewView.swift:104), against ReviewPage's "Four sessions". Builder B; day marks need Core first.

## Questions for Product

1. Monday morning the page shows the new week's "the week so far", but the story tells the week just ended. Where does
   last week's story sit, and for how long?
2. Rules wording: "6 of 6 workouts, 2 new bests." (week-rules-lines) or "Bests on Bench and Squat." and "sessions"
   (week-story-job §1.5)? And "3 cooks" or "1 recipe cooked" (R3)?
3. Tapped-day times: 12-hour "6:10 pm" (this item's rule) or the Day log's "18:10" column (decisions 7:34 PM)?
4. Does a paused session that was never finished count as a session in the hero and the figure (W2)?
5. #83's weight clause on Review against "money and body never show": keep it on the phone only, or drop it?
6. Empty week (W5) and notes-only week (W6): skip the call and show rules lines? Proposed: yes.
7. Trip day (W3): times in the zone he was in ("6:30 am") or the zone he's in now ("3:30 am")?
8. Day mark (W10): does the figure read "5 of 5" and the hero stay "Five sessions" with the plan at 6?
