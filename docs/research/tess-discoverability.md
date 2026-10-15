# Tess discoverability: learning phrases without a manual

For: Builder B, Design, Product
Date: 2026-10-15 · Research lab
Reads with: `tess-voice.md` (rules and `TessVoice.violations`), `speech-capture.md` (Bar states, slices V1 to V3), `capture-modes.md` (attach glyph), `context-packing.md` (one ask per screen, never flicker), and `TessGrammar.swift` plus `TessGrammar+Kitchen.swift` on origin/master (`0c0bfdb`).

**Recommendation in one line.** Kaushik learns Tess by seeing one real phrase at the moment it would help, in the same place he types, and each phrase goes away for good once he has used it twice or ignored it three times.

## 1. What master does today

- The collapsed Bar says "Ask Tess, or log a set". The open panel's field says "log 82.5×8, or ask", and under it sit three chips ("log bench 82.5x8", "bench best?", "stretch at 21:00") drawn with a `RoundedRectangle` outline. Those outlines break the no-button-shapes rule, and a tap submits at once, so a chip can write a set he did not do. The first slice replaces them.
- `TessVoice.violations(in:)` already checks a line for 12+ words, "!", emoji and the banned words. Every hint line goes through it in a test.
- `OpRecord` carries an `Actor` (`.user`, `.tess`), so "done by hand" is readable from the op log. `TessCapture` has `records`, `line`, `source` but no parse kind yet; slice 2 adds one.
- Two grammar findings from the brief's own examples. "milk eggs" with no comma does not parse (the bare list needs a comma, or "buy ... and ..."). "remind me thu to call mum" parses, but the title comes out as "To call mum", because "to" is only stripped right after "remind me". The hints below use the forms that parse cleanly: "milk, eggs, 2 lemons" and "remind me to call mum thu". A one-line grammar fix (strip a leading "to" after the date is taken) is worth a Core ticket.

## 2. How others teach their syntax (scouting)

- **Things:** the date field reads partial words, so "wed jul" offers a list of matching dates while you type ([Things support](https://culturedcode.com/things/support/articles/9780167/)); the result shows before you commit.
- **Fantastical:** typing a sentence makes a live event preview you can still drag, and "with" or "at" pops contact and place suggestions ([Flexibits help](https://flexibits.com/fantastical/help/adding-events-and-tasks)).
- **Drafts:** ships a default action set and points new users to the Action Directory and screencasts, not in-app hints ([Drafts docs](https://docs.getdrafts.com/actions/), [MacStories](https://www.macstories.net/reviews/drafts-5-the-macstories-review/3/)).
- **Raycast:** shows a command's alias as a small badge and its hotkey beside it in root search ([Raycast manual](https://manual.raycast.com/command-aliases-and-hotkeys.md)). **Superhuman:** Cmd+K lists each shortcut next to its command, and after a mouse action it suggests the shortcut for next time ([Superhuman help](https://help.superhuman.com/article/478-superhuman-command)).
- Lesson for Tess: show the phrase where the action happens (Things, Fantastical, Raycast), and after a manual action, show its spoken form once (Superhuman). Skip Drafts' "go read the directory" route.

## 3. Three places a hint can appear

**A. Inside the capture surface (S lines).** When the soul glyph opens into type, speak and attach, the type field's placeholder is a real phrase picked from context, and at most one more phrase sits under the field as an ink word. Tapping that word fills the field and leaves the cursor at the end; it never submits. Context: a workout entry in focus gives set phrases, a recipe or cook timer gives kitchen phrases, 17:00 to 21:00 gives groceries, otherwise tasks or a lift. The speak option gets one line of its own after slice V2; attach gets none until `capture-modes.md` slice 1.

**B. Under a ghost row (G lines).** When a phrase parses and the ghost row is drying, one line under it shows another form of the same kind that he has not used yet: "You can also say 3x10 bench 80." It sits in `inkSecondary` under the cobalt ghost row and fades with the row when it commits or he swipes it away. It never delays the 2 s commit.

**C. After he does something by hand (H lines).** When a `.user` op has a grammar twin (a set from the dial, a task with a date, a grocery item, a timer, a note), the next time the collapsed Bar is idle it says the phrase once, for 4 s, in the slot where "Added to Later." shows today: "Next time, this works: book physio fri 9am." The phrase is built from his own object, then run through `TessGrammar.parse`; it shows only if it parses back to the same kind and title. Never while a set ghost is drying or the rest dial is running.

## 4. How often, and when a hint retires

| Rule | Value |
|---|---|
| On screen at once | 1 hint line, plus the placeholder. A G or H line hides the under-field word |
| Per day | At most 3 hint shows in total; each hint counts once per day however often the panel opens |
| H lines | One-time: shown once ever per kind, then retired. At most 1 H line a day |
| Retires when used | He uses that phrase kind through Tess twice (grammar parse of that kind, committed, not undone) |
| Retires when ignored | Shown on 3 different days without a use |
| Retires by hand | Swiping the line sideways retires it at once. No confirm, no "are you sure" |
| Ends | Day 15 after his first capture, S and G lines stop. H lines still run for kinds never seen. A Settings switch "Phrase hints" (on by default) turns all of it off |
| Never | Coach marks, tooltips, tours, modals, badges, dots, counters, red, notifications, sound, a "you haven't tried" line, any count of hints left |

Visual rules: Inter Tight, upright, 16pt minimum (placeholder uses `Theme` body at 21pt, hint lines at least 16pt and scale with Dynamic Type), ink words with no outline, fill or capsule, `inkSecondary` for the line and `ink` for the phrase inside it, appear by opacity only through `MotionPolicy` (Reduce Motion: no movement at all). VoiceOver reads the hint as the field's `accessibilityHint`, once.

## 5. Where hints are stored

On the phone only, in `UserDefaults` under `tess.hints.v1` (the way `launchNote` is stored today), as about 2 KB of JSON: `firstCaptureDay`, then per hint id `shownDays`, `uses`, `lastShown`, `retiredAt`, `reason` (used, ignored, swiped, ended). It is not an object in `TesseraContext`, not in the op log, not in the JSON export, and never in a context pack sent to Claude. The ledger logic is a plain struct in `TesseraTess` (`TessHintLedger`) with a pinned clock so it can be tested; the app owns reading and writing it. `-resetDemo` and a DEBUG `-resetHints` clear it.

## 6. The 20 hint lines

Ctx: I idle, W workout entry in focus with a last set, E evening, K recipe or cook timer open. "Parses" names the `TessGrammar.Parse` case on master. Voice check: every line passes `TessVoice.violations` (under 12 words, no "!", no emoji, no banned word), uses digits, and offers rather than instructs (rule 4).

| # | Where, ctx | Line as shown | Parses | Voice check notes |
|---|---|---|---|---|
| 1 | S, I | bench 80x8, or ask | `.lift` | 4 words; a phrase, not a command |
| 2 | S, W | same, 8, or 80x8 | `.set` (.same, .repsOnly, .full) | 4 words; needs a last set in the entry |
| 3 | S, W | drop to 70 for 10 | `.set` (.drop) | 5 words |
| 4 | S, E | milk, eggs, 2 lemons | `.groceries` | 4 words; commas required |
| 5 | S, I morning | dentist thu 3pm | `.task` | 3 words |
| 6 | S, K | timer pasta 10 | `.timer` | 3 words |
| 7 | G after a lift | You can also say 3x10 bench 80. | `.lift`, 3 sets | 7 words; "can" keeps it an offer |
| 8 | G after a lift | You can also say bench 3x8 at 80. | `.lift` | 8 words |
| 9 | G after a set in W | Next set can be just 8. | `.set` (.repsOnly) | 6 words |
| 10 | G after a set in W | You can also say 80x8, 80x8, 80x6. | `.sets` | 7 words |
| 11 | G after a dated task | You can also say remind me to call mum thu. | `.task` "Call mum", Thu 09:00 | 10 words; the clean form, see section 1 |
| 12 | G after an undated task | A day works too: tonight, or fri 9am. | `.task` with `startsAt` | 7 words; "tonight" sets 20:00 |
| 13 | G after groceries | You can also say buy milk and eggs. | `.groceries` (2 lines) | 8 words |
| 14 | G after a timer | Rest timers count seconds: rest timer 90. | `.timer` 1.5 min | 7 words; a fact |
| 15 | G after a note | Lists work the same way: list: packing. | `.list` | 7 words |
| 16 | H, set from the dial | Next time, this works: 80x8. | `.set` (.full) | 5 words; numbers are his own set |
| 17 | H, dated task by hand | Next time, this works: book physio fri 9am. | `.task` | 8 words; filled from his task, round-trip checked |
| 18 | H, grocery added by hand | Next time, this works: buy oat milk. | `.groceries` | 7 words; filled from his item |
| 19 | H, best opened by hand | Next time, this works: bench best? | Question path (`CommandInterpreter`), not the grammar | 6 words; reads only, no write |
| 20 | S, speak option | Holding the bar listens: 80 for 8. | After slices V1 and V2 (`speech-capture.md`) | 7 words; no mic glyph until V2 ships |

Left out on purpose until their slice lands: "rest 90" (grammar-collisions rule 4), "bench 80 for 8 and call mum tomorrow" (rule 3 split), "milk eggs" with no comma (not planned; line 4 teaches the comma). Self-check: no line uses should, must, missed, streak, try or don't; none counts what he has not done; humour is not used, since hints are not done states.

## 7. Smallest first slice

**Slice 1: placeholder hints and the ledger** (Builder B, with Core for the parse table). Replace the three outlined chips with the context placeholder and one under-field ink word (lines 1 to 6), backed by `TessHintLedger` in `UserDefaults`. G and H lines are slices 2 and 3 (slice 2 adds a parse kind to `TessCapture`; slice 3 maps `.user` ops to phrases with the round-trip check).

Done when:
- A Swift Testing table parses the phrase in each of lines 1 to 19 with `TessGrammar` (or `CommandInterpreter` for 19) on a pinned clock and gets the case in the table, and runs all 20 lines through `TessVoice.violations` with no problems.
- Ledger tests: a hint retires after 2 committed uses of its kind, after 3 shown days without use, and on swipe; at most 3 shows a day; S lines stop on day 15.
- With `-demoTime 07:05 -resetDemo` the open panel shows "dentist thu 3pm" or "bench 80x8, or ask"; with a workout entry in focus it shows "same, 8, or 80x8"; tapping the ink word fills the field and writes nothing.
- No `RoundedRectangle` outline or capsule remains in the panel; hint text is Inter Tight, upright, 16pt or larger at the smallest Dynamic Type size; Reduce Motion shows no movement.
- `scripts/test.sh` ends "All green".
