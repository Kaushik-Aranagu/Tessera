# Planning lead (Product lead thread)

**Two lanes (11:25 AM PT Oct 16, Kaushik: no idle agents):** when one lane waits on a review, build, gate or answer, work the other in the same turn. Next keeps 3 or more ready items. The coordinator sweeps every 30 minutes.
- **Lane 1:** Boards, decisions and the index; each team's Next at 3 or more; mirror to master by small docs PRs.
- **Lane 2:** The pin-naming checklist (`../../product/pin-checklist.md`), so the pin SHA is named the minute #366 and the stuck-listening fix merge.

**Now:** keep every team's Next at 3 or more ready items, and keep `../board.md` (the index) current. Done when no team's Next holds fewer than 2 items.

**Next:**
1. A v1 acceptance pass. Done when each v1 slice has been checked against the latest recordings, with any gaps added to `ios-a.md` Next.
2. M5 next area after Reading: Money, from `../research/m5-money-reading.md`. Done when there's a ship list in the house format. (Reading is approved as `ship-list-m5-reading.md`.)
3. Kitchen v2 scope review with the Kitchen lead, after Kaushik has used the kitchen for a week.

**Later:**
- More M5 candidates: Money, People and Home upkeep. Also "build me an app" with Claude, and daemons.

**Done 6:20 PM PT:** review-session.md rewritten for the next install from Research's `review-refresh.md` (20 items, current known gaps). Re-check it against the install commit before the install.

**Pending review-guide edits (when the phone gets its next build):** remove the #109 known gap (tap to edit is merged), add back the Today swipe line (QA passed Builder B's hotfix, 4:50 PM PT), and add a Groceries check that the last aisle scrolls clear of the closed basket.

**When Core's grammar hotfix reaches the phone:** remove the "typed phrases land wrong" known gap from review-session.md (added 4:26 PM PT).

**When Builder A's cook mode (kitchen slice 12) reaches the phone:** add Kitchen's 10-step `cook-mode-script.md` (#137, f77bb01) to review-session.md as the cook mode item, and drop the "no cook mode" known gap.

**When Builder B's Speak (V1 and V2) reaches the phone:** add Research's `speech-test-script.md` (#138) to review-session.md: 30 phrases, run on a Thursday. It writes to real data, so the guide ends with the cleanup step.

**After widgets ship:** the expired-signing widget timeline (Research #156) needs one look on an expired build. Signing is refreshed before it lapses, so his phone never expires for a test; letting it lapse would be a deliberate call with Kaushik.

**Mon Oct 19:** the coordinator asks the three training week-one questions (`training-week-one.md`). Defaults until he answers: keep the rest timer, swap is easy enough, finish isn't forgotten.

**Thursday Oct 22, end of his first kitchen week** (Groceries and Recipes reached the phone with 21566b8 on Oct 15): the three one-word questions from `kitchen-week-one.md` go on that day's morning list in one message (pantry check, saving a recipe from a website, reaching for something else). The answers go to the Kitchen lead to scope v2.
