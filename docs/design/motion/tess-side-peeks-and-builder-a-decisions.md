# Board 43 (side peeks on three holes) and 44 (motion items needing a Builder A decision). Oct 17, PM; (lab) = default for Design to overrule

## 43 Side-swipe peeks (gaps-98 section 5): Lists shelf LAST RUNS (**stale: sheet 87 ruled ON THEM, see `tess-pantry-first-day-and-four-sides-motion.md` row 28; a list's past rides on its own line**), a list page WHAT IT HOLDS, Put away page WHAT WENT BACK
All three ride `SideHost` with no motion of their own (tess-sides-motion.md). What differs:
| Side | Page entry | Glance's one big fact (arrives with the glance, 300 ms blur-in, no count-up) | Run end |
|---|---|---|---|
| LAST RUNS (Lists shelf, BEFORE) | Rows arrive with the page, no stagger | The last run, one line ("Packing, Thursday") | Not a run |
| WHAT IT HOLDS (a list page, FACTS) | Sections and counts arrive with the page; the reusable flag is a word, no toggle motion | The item count (Hero 56), e.g. "8" | Not a run |
| WHAT WENT BACK (Put away page, BEFORE) | Rows arrive with the page; newest first | The last thing put back, one line | Not a run |
- Shared: body moves 1:1 under the thumb, settles on the house spring 380 ms; her glance is `sideTurned` into stop 1 only; one `.selection` on landing on the full side, none for the glance. Reduce Motion: 150 ms crossfade, no settle, no edge shadow. Low Power = Reduce Motion on sides (ruled 7:39 PM Oct 17): a 150 ms crossfade, no drag spring.
- A count that changes while a side is open just changes, no roll. A private item reads "Private item" in the same type and motion; the soul behaves identically.
- Whose swipe: a list row's horizontal swipe (open/remove) stays its own; the side swipe is the edge zone or a swipe on a name/empty space, per sheet 76.

## 44 Decisions waiting on Builder A (one question each, so the Mac can act in one pass)
D1. #662 stroke fix: is d17c0f9 still the head, and may the lab re-run check-pick.sh on its new clip (frozen-PR rule)? Answer: head SHA, or "not ready".
D2. Wake clock: start it on her first drawn frame instead of AppModel init (about 100 ms early today); do it in the next soul PR, yes or no?
D3 (RULED 7:39 PM Oct 17: yes, one soft .warning per failed save, none offline). `.warning` haptic: add the one `Haptic.notSaved` case (the set was closed), yes or no? Needed by "Didn't save that. Try again." (board 42).
D4 (RULED 7:39 PM Oct 17: yes, full opacity). Reduce Motion Working grade: drop the whole-soul opacity x0.6 and keep full opacity (tess-never-diffused-audit.md fix 1), yes or no?
D5 (RULED 7:39 PM Oct 17: Low Power = Reduce Motion everywhere for screens, sides and page turns; tess-sides-motion.md fixed in #927). Low Power on sides: tess-sides-motion.md keeps the drag spring in Low Power, but Design ruled the page turn is the 150 ms crossfade in Low Power (R3). Do sides follow R3 too, or keep the spring?
D6 (RULED 7:39 PM Oct 17: yes, full pigment). Asleep pigment: keep full pigment with closed eyes (audit fix 2), yes or no?
D7 (RULED 7:39 PM Oct 17: yes). Poster frames: add a rule that no poster or thumbnail is taken inside the 500 ms working fade (audit fix 3); where do poster times live in the build, if anywhere?
D8. Ideas 13 to 15 (list cleared, week met, rest day): build now or hold? Each needs a row in tess-picks.md section 20 when built.
D9. PagedRun slots: does a screen declare its N row slots in code (Rotate needs them up front), or does PagedRun infer N = 6 for every screen?
D10. Page-turn drag: build the 1:1 follow for Slide and Rotate in the first PageTurn PR, or release-only first (Turn and Soften are release-only anyway)?
Product forwards these to Builder A through the coordinator as one batch; the lab does not message the Mac directly.
