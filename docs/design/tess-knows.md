# What Tess knows, redrawn for AI-9 (Design item 49)

**Kaushik's principle, in one line:** he should be able to see everything Tess remembers about him, where each thing came from, and take any of it away with one gesture.

Redraws `m4-steers.md` section 11 under today's rules (one base, no cards, the back word, ink actions, the fixed Tess band, no resting colour) on the AI thread's `TessMemory` store (`docs/ai/architecture.md` section 4: told, noticed and recent lines, each with `evidence`, `lastUsedAt` and `private`), for Builder B's AI-9 on the ship list. The old study (`studies/tess-knows.html`, `recordings/tess-knows.mp4`) is superseded by this sheet.
- Board: `mockups/tess-knows.png` (source `studies/tess-knows-v2.html`): the Settings door, the page, a swipe, the forget, a new fact, the end of the page on Obsidian with FORGET EVERYTHING held, and the empty page.
- Recording: `recordings/tess-knows-v2.mp4` (10s), Porcelain: swipe left on the shoulder line, FORGET, the line drifting into the soul and the rest closing up, Tess's line with UNDO; then "remember that I rest on Sundays" landing at the top of Training under the drying line.

## Two doors
- **Settings › TESS:** the first line reads "Tess remembers **12 things**." The number is the value word (600) and opens this page one layer down, ‹ SETTINGS. "Nothing yet." when there are none, and the words open the page the same.
- **Asking her** ("what do you know", "what do you remember"): she answers "12 things about you." with **WHAT I KNOW** as the ink-line word under her line; it opens the page with ‹ TODAY (`back-word.md`, by the way in).

## The page
| y | Element |
|---|---|
| 58 | ‹ SETTINGS or ‹ TODAY. It stays while the page scrolls |
| 84 | Title 44, two lines, in her voice: "What I know / about you". It scrolls with the page |
| 196 | Body 21 `inkSecondary`: "12 things. 4 you told me, 8 I noticed." Recent day lines aren't counted; they're the day log's |
| 250 on | **Group words** at Title 34 (ink 85%) in the margin: Training, Kitchen, People, then "The last 14 days". A group exists only when it has a line |
| under each | **The lines**, 50 under the group word, at Body 21/400 in her voice, second person: "You train **after work** on weekdays." Under each its **source** at 16 `inkSecondary`, from `evidence` and `lastUsedAt`: "you said so on Oct 9, used today", "from 14 workouts, used today", "from 6 weeks". A `private` line adds "stays on this phone". One-line facts sit 72 apart, two-line ones 100; 36 between the last line and the next group word |
| The last 14 days | The recent lines at 16, the day in 600 `inkSecondary` then the line, 26 apart: "Wed  Pull A done, 2 tasks, cooked chili." |
| the end | **FORGET EVERYTHING**, a label word with the ink line under it, 28 under the last line. It's the end of the scroll, never pinned |
| 736 to 820 | Tess's band, fixed, as everywhere. The page fades out over its last 50 pt above it |

- **Value words** (600) only on told lines, and they're his words: "after work", "left shoulder", "Tacos". Noticed lines have none, because he can't edit a count.
- **Nothing rests in colour.** The context colour isn't used here (there's no hero). Her voice is the one colour, and only in her line.
- **Never on the page:** a number from health, a weight, a sum of money, a merchant, a place, a note's words (architecture section 4's screen). A line that would need one doesn't exist.

## Taps
- **A value word** on a told line: `ValueWash` touch, and the sentence becomes a writing line in place (the Write grammar, `no-buttons.md`): he changes the words, returns, the 1.5 pt cobalt line dries under it over 2 s, and the source line reads "you said so just now". UNDO under Tess's line for 10 s.
- **A source line** on a noticed line ("from 14 workouts") opens those objects as rows one layer down, ‹ WHAT I KNOW. On a told line it does nothing.
- **A day line** opens that day's log (`day-log-page.md`), ‹ WHAT I KNOW.

## Swipe left to forget
- The line slides with the finger; at 60 pt **FORGET** rises at the right edge in `live` (Label 16/700, on the sentence's first baseline), with `.selection` once. Let go past 96 pt and it commits; before that it springs back (`.settle`).
- **The forget:** the sentence breaks into 24 to 28 flecks of 3 pt in her three pigments that drift to the soul on the hand-off arc reversed (760 ms, house curve, 16 ms apart, fading in the last third). The soul takes one slow breath (1 → 1.09 → 1 over 1.3 s). The source line fades (200 ms). The lines under it close up (320 ms, house) and the count line rolls.
- **Tess:** "Left shoulder, forgotten." (the thing, then what happened) with **UNDO** under her line for 10 s. UNDO brings the line back the same way reversed. After the 10 s Core removes the object and redacts its text from earlier ops (ship list AI-9).
- No haptic on the commit beyond the `.selection` at the threshold: one haptic per moment (`task-reward.md`).
- Recent day lines forget the same way; forgetting one never touches the day log itself.

## A new fact arriving
"remember that I rest on Sundays" (AI-8) lands here when the page is open, and is simply there when it isn't:
- Tess's line changes first ("Kept. You rest on Sundays." with UNDO). The lines of its group and everything under make room (72 pt, 320 ms, house).
- The sentence arrives at the top of its group **glyph by glyph** (24 ms each) with the 1.5 pt cobalt line drawing under it over 2 s (the ghost's dry, `no-buttons.md`). When the line is dry it fades out (400 ms) and the source fades in: "you said so just now". The count line rolls.
- Claude's `remember` on a miss lands the same way, with the source "from what you said on Oct 16".

## Forget everything
- A **hold** (600 ms) on FORGET EVERYTHING: the ink line under it fills left to right in `live` over the hold (the Finish grammar). Let go early and it drains back.
- On commit every line drifts into the soul top to bottom, 40 ms apart, the group words fade, the count line reads "Nothing yet.", and Tess: "Everything forgotten, 12 things." with UNDO for 10 s.
- **The empty page:** the title, "Nothing yet." at 196, and at 250 Body 21 `inkSecondary`: "Say "remember that…" and I'll keep it here." No group words, no FORGET EVERYTHING.

## The 40th told line
When a told line is dropped at the 04:00 turnover to make room (architecture section 4: the oldest not used in 90 days), the page says so once, on its next open, as Tess's line: "I let one go to make room: Tacos means the sheet-pan tacos." No UNDO (it went at the turnover); "remember that" brings it back. Default for Product.

## Reduce Motion
No flecks and no glyphs: the line crossfades out (200 ms) and the rest closes up without motion; a new line crossfades in with its source. UNDO and the haptic stay.

## Accessibility
- Each line is one element: "You train after work on weekdays. You said so on October 9, used today. Actions: Forget." Value words are custom actions ("Change after work").
- FORGET EVERYTHING is one element with a confirm action; VoiceOver never needs the hold.

## For Builder B and Core
- Builder B: `TessKnowsPage` (new), reached from the Settings TESS line and from her WHAT I KNOW key; the swipe, the flecks (the `SoulTravel` arc reversed, 28 points), the glyph arrival on the `remember` write, the hold at the end, the empty page.
- Core: `TessMemory` reads grouped by area with `evidence` and `lastUsedAt` read into the source line; forget (object removed, text redacted) and forget everything behind the 10 s UNDO; the 40-cap note; the "what do you know" phrase answering with the count.
- AI thread: nothing on this page is sent anywhere; `private` lines show "stays on this phone".

## Owners
- **Builder B:** the page and its four moments.
- **Core:** the store, the writes and the phrase.
- **AI architecture:** the memory rules this page shows.

## Addendum, Oct 16: Research's trace (board 117)
Answers to `research/tess-knows-trace.md`, one line each. Rows not named here are Core's or AI's and change nothing drawn.
- **F4, Claude's `remember` on a miss:** taken. It never dries in on its own. It lands as a **ghost row** at the top of its group in wet cobalt with **KEEP / NOT NOW** as the one ask (`one-ask.md` grammar: the cobalt line and two ink words), and only KEEP runs the glyph arrival and the drying line, with the source "from what you said on Oct 16". NOT NOW fades it (200 ms), nothing written. His own "remember that…" keeps after the dry, as drawn.
- **S1, week lines:** no. Week lines have no place on this page; if AI keeps them in the store they're `derivedFrom` day lines and go when the day lines go. The page shows only "The last 14 days". AI's call to keep or drop them.
- **S2, week one:** taken. The empty page is only for a store with nothing of any kind. With day lines alone, the count line reads **"Nothing kept yet."** at 196 and "The last 14 days" follows at 250 as the one group. FORGET EVERYTHING shows then too.
- **S3, a told fact outside the three areas:** taken. A last group word **About you** (after People, before The last 14 days) for told lines with no area: "You work **9 to 5**." A place is refused by the screen, Tess: "I don't keep places."
- **S6, an edit that trips the screen:** a health word keeps the edit as `private`; the source line gains "stays on this phone" and Tess says "Kept, on this phone only." Money or a place: the words spring back to what they were (`.settle`, 260 ms) and Tess says "I don't keep sums of money." / "I don't keep places." No UNDO either way.
- **S7, the 41st line with nothing old enough:** not kept. The ghost row for it drains (the drying line runs backwards, 400 ms) and Tess says "I keep 40 things. Forget one and say it again." No UNDO.
- **S8, her answer at zero:** "Nothing yet. Say "remember that…" and I'll keep it." with no WHAT I KNOW word under it; the Settings line reads "Nothing yet." and still opens the page (its empty state).
- **S9, Siri and Shortcuts:** "Say that in Tessera and I'll keep it." Nothing written. Not drawn; it's a spoken line.
- S4, S5, S10 to S12 and F1 to F3 are Core's and AI's. On S5: the value words are the capture's own words at write time (`valueRanges`), which is what the sheet already bolds.

## Addendum, Oct 16: forgetting by voice, and three refusals (Research 122, V3, V9, V-R9)

The swipe and the hold stay the two gestures on the page. Saying it is a third way to the same place, with the same line, the same UNDO and the same redaction. Every match is made on the phone; nothing is sent. The lines, all in Tess's voice, Body 21 in `tess`, in her band:

| He says | What happens | Tess |
|---|---|---|
| "forget that I rest on Sundays" (one line holds every word) | that line goes, with UNDO for 10 s, then the redaction, as the swipe | "Rest on Sundays, forgotten." + **UNDO** |
| "forget the shoulder thing" (one line, private) | the same; private lines match the same way | "Left shoulder, forgotten." + **UNDO** |
| "forget what I said about tacos" | "what I said about", "the … thing", "that", "about" don't count toward the match | "Tacos means the sheet-pan tacos, forgotten." + **UNDO** |
| "forget about mom" (two lines match) | nothing written; the page opens on the matching lines | "Two things match. Swipe the one to forget." + **WHAT I KNOW** |
| "forget my gym" (no line matches) | nothing written | "I don't have that." + **WHAT I KNOW** |
| "forget that I usually train 6 to 8" (a noticed line) | forgotten and its rule suppressed (M3), as the swipe | "Train 6 to 8, forgotten." + **UNDO** |
| "forget everything" | never by voice; it is the hold on the page | "That takes a hold, on the page." + **WHAT I KNOW** |
| "never mind" / "forget it" within 10 s of "Kept." | the same as UNDO | "Rest on Sundays, taken back." |
| "remember this" | nothing written. A statement, not a question, and no ink word under it | "Say what to keep, like "remember that I rest on Sundays"." |
| "remember my squat best is 140" | not kept; the ledger has it | "Training keeps your bests." |

- **The name in her line** is the line's value words (the bold words on the page), never the whole line: "Rest on Sundays", "Left shoulder", "Train 6 to 8". A kept line that has no value words yet (a fresh told line) uses its first four words.
- **Her words never carry a label word.** "Hold FORGET EVERYTHING on WHAT I KNOW" would put two ink words inside a sentence; she says it plainly and the one ink word sits under her line, as everywhere.
- **The page opening on a match** is the ordinary WHAT I KNOW page with the matching lines at the top, not a filtered page: the count line and groups are all there, and the two matches sit first in their groups. Nothing is highlighted; the swipe finds them.
- **Motion:** "forgotten" by voice uses the swipe's exit (the flecks into the soul), from the band, since the page may not be open. Reduce Motion: a fade.
- Core: the match rule; the AI thread: nothing here is a Claude tool.

## Addendum, Oct 16: receipts and bests (Design 62, `copy-pass.md`)
Receipts thing first: "Rest on Sundays, kept.", "12 things, forgotten.", "Tacos, forgotten.", "Train 6 to 8 pm, forgotten."; no "…" in the two "remember that" lines; "Tacos means your sheet-pan tacos, let go to make room."; "I keep 40 things. Forget one to make room."; "2 things match. Swipe the one to forget."; the stop inside the quote. The full table is in `copy-pass.md`; where a clip still says the old words, the sheet wins.
