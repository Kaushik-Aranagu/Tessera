# Empty states: six pages, one shape (Design item 23)

The pages with nothing in them yet: the Day log, Habits, Settings on a fresh install, Upkeep, Money and Reading. It answers Research's `empty-states.md` question 4 (text only, no breathing symbol) and follows its baseline rules: one plain line under 12 words, one way forward, nothing counted before it existed. Every line here is already in a sheet or a Research pack. Where this sheet moves or splits a line, it's marked, and it wins over the older sheet.
- Board: `mockups/empty-states.png` (source `studies/empty-states.html`). Porcelain on top (Day log, Habits, Settings), Obsidian below (Upkeep, Money, Reading).
- Recording: `recordings/empty-states.mp4` (`?play`). Money's first spend takes the quiet line's place.

## One shape
1. **The page keeps its own frame.** The back word, the title or hero, and the context line if the page has one, all where they'll be with data. Nothing that only makes sense with data shows: no NEXT or TREND labels, no ledger, no week row, no scrub, no stroke.
2. **One quiet line** in Body 21/400 `inkSecondary`, at the y where the first record will land. It says what's true now ("No books yet."). It's never a count, never "0", and never in `context` (`sweep-19.md`: empty-state lines rest in `inkSecondary`).
3. **One way in, at most:**
   - **The page's own writing line,** where the page has one (Habits). It's a 0.5pt hairline with Tess's cobalt nib, as in Notes, and its placeholder is the example.
   - **Otherwise, Tess's Try line** at the foot by the soul (y 734, left 22, right 80, Body 21 `tess`). It reads "{ask} Try: **{example}**." The example is 600, and "Try: {example}." never breaks across lines.
     - It writes itself in, left to right, 700ms after the page lands (house curve), once per open. Reduce Motion: it's just there.
     - **Tap the example:** the ink line draws under it (150ms), then Tess's capture opens on Write with an **empty** line and the example as its placeholder. Nothing is typed for him, so he never has to delete "Dune".
   - Pages that fill themselves, and Settings, have no Try line.
4. **The first record takes the quiet line's place.** The quiet line fades (220ms). The record rises 10pt into its y with a 3pt blur clearing (settle spring, 420ms, 180ms later). It lands wet in its area's colour and dries, as every record does (`no-dots.md`). Tess's answer replaces her Try line, with UNDO. The page's labels set in only now. After this, the empty state never shows again unless the page empties.
5. **Never:** an icon, an illustration, an SF Symbol, a "Get started", a button shape, a counted zero ("0 of 0", "0 spends"), an empty label, or a second line saying the same thing. The only thing breathing on an empty page is Tess's soul, which is already there.

## The six pages
| Page | Frame | Quiet line | Way in | Source and changes |
|---|---|---|---|---|
| **Day log**, the first day | ‹ HOME, "October" (Title 44). **TODAY** in `ink` at y 676, above the 64pt foot | "Your days write themselves here." at y 704 | None: the page fills itself | `day-log-v1.md` (DL50, DL67). **Changed:** the line is `inkSecondary`, not 55% (55% isn't a token) |
| **Habits**, none yet | ‹ TODAY, "This week", "Saturday, 1 day to go" in `context` | "No habits yet." at y 200, where the first name lands | The writing line at y 248, placeholder "new habit read 5 a week". Tess says nothing (H1) | Research `m3-lines.md` H1 and H2. Creating one says "Read added, 5 times a week.", and Read's block sets in at y 200 (`body-weight-and-habits.md` §2a) |
| **Settings**, fresh install | ‹ REVIEW, "Settings" | None: Settings is never empty. Each section shows its first-use line | Its own offers: **Add a Claude key** and **a folder you choose** (600 `ink`) | `settings-place.md`: "Tess thinks on this phone only.", "The first copy is made when you leave the app today.", "Also keep them in **a folder you choose**.", the reinstall line, SAVE A COPY · RESTORE, UNITS. No RECEIPTS word with no rows |
| **Upkeep**, after SKIP | ‹ REVIEW, UPKEEP | "No chores yet." at y 170 | "Tell me what you just did. Try: **watered plants**." | `upkeep-people-first.md`. The pick shows first; this is what's left after SKIP. **New:** the quiet line. From 1 Oct to 30 Nov the radiators ask takes the foot first, and the Try line comes back once it's answered |
| **Money**, October | ‹ REVIEW, MONEY, then the hero **"October"** (Title 44) | "Nothing logged yet." at y 230, where the month sentence lands | "Tell me what you spent. Try: **spent 4.50 coffee**." | **Changed** from `money-reading-first.md`'s hero "October: nothing logged yet": the month stays the hero, and the nothing moves to the quiet line. The first spend reads "**1** spend, coffee, **4.50**." with the `now` wash on the amount (proposed copy, for Research to check against `fixtures/money.md`) |
| **Reading**, no books | ‹ REVIEW, READING | "No books yet." at y 170, where the first title lands | "Tell me what you're reading. Try: **reading Dune**." | `money-reading-first.md` had only the Tess line. **New:** the quiet line, and Research's "Try: reading Dune." (`fixtures/reading.md` row 7) |

People follows the same shape: "No one yet." with "Tell me who you talked to. Try: **met Sam**." (`upkeep-people-first.md`).

## VoiceOver
- The quiet line reads as written.
- The Try line reads "Tess: Tell me what you spent. Try: spent 4.50 coffee." Its action is "Write it", which opens Write.
- No "empty" or "no items" is added.

## Owners
- **Builder B:** the Day log, Habits, Settings and Upkeep empty pages, and the Try line's tap into Write (`Features/Command/`). This shape also suits the other screens in Research's `empty-states.md` (Notes, Groceries, Review).
- **Builder A:** Money and Reading, when those pages are built.
- **Core:** Habits' "new habit {name} {n} a week" grammar row (`m3-lines.md` D10). Nothing here needs a new field.
- **Research:** check the two new lines ("No chores yet.", "No books yet.") and Money's first-spend sentence against the voice rules.
