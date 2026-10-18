# 93. Settings, one packed screen

Product ask Oct 17 (4:10 PM PT). Spec only; no study. Nothing in the app changes. One screen, a plain line per thing, no cards, no switches in boxes: a row is a name on the left in `ink`, its current value on the right in `inkSecondary`, and a tap turns or opens it in place.

## The page (top to bottom, one scroll of 5 pages at most under sheet 90's rules; here 4 pages of 6 or fewer)
Page 1, **Tess**
- Tess asks Claude: "Off" or "On". Under it one line: "Sends only what Receipts lists." (Product ruling Oct 17: the switch also gates capture misses, plan wording, Home lines and recipe reads, so "what you ask her" overclaimed.) Key, This month and Receipts live inside this row and open in place, so page 1 stays 6 rows or fewer. Off is the default and stays off until the key is there.
- Quiet hours: "11 pm to 7 am". Tap opens two clocks in place.
- Page turn: "Turn, on". Tap opens the four words in place (Slide, Turn, Soften, Rotate), each previewing once on a mini page (R4: re-picking the same word does not replay).
Page 2, **Your day**
- Day starts: "4 am". Tap steps the hour; one line explains "A late night stays on the day before."
- Rest day: "Sunday" (or "Any").
- Units: "lb, mi" (US English; stepper on the right word).
Page 3, **Looks**
- Look: the five names in place. Tess colours: "Today".
- Haptics: "On".
Page 4, **Data**
- Back up: "Today, 9:02 am" and a tap to run one.
- Export Health, Delete everything (the last one is the only vermilion word, two taps, a held confirm).

## Rules
- A row never wraps; the value shortens, never the name.
- Plain value words, no "Enabled/Disabled". Clocks "11 pm".
- The page turn follows sheet 90: vertical swipe on a stepper row steps the stepper (sheet 90b), on a name turns the page.
- Rail on the right edge as in sheet 90; the section word at the top of each page is the only heading.
- Private: nothing on this screen shows anyone's words except their own settings.

## Where Settings lives, its entry word, the Claude page (Research HS35; Oct 17, 9:40 PM PT)
- **The way in is the SETTINGS word at Review's foot** (`settings-place.md`, a Label 16/700 word in `inkSecondary`; tap grows Settings out of the word, back closes into it). Home's side swipe is **not** the entry: Home's side is its own facts (sheet 77), and a Settings word there would put one screen behind two doors. A pinned one-line route is allowed on Home's side only as a link line "Settings" that does the same open; nothing else of Settings lives on Home.
- **One page per area is the packed screen above** (sheet 93, up to 4 pages of 6 rows or fewer). Page 1's section word is **CLAUDE** (was "Tess"): "Tess asks Claude" with Off/On, its one line, the key state ("Key kept" or "No key"), this month's spend ("$1.20"), and the receipts line one layer down with a ‹ SETTINGS back word. This is the page the capture-miss notice names: **"Turn this off in Settings: Claude."**
- **Quiet hours are not a row.** They stay fixed at 11 pm to 7 am (no setting). The page keeps one fact line on Your day, "Quiet from 11 pm to 7 am", in `inkSecondary`, with no value word to tap.
- **Haptics** stays a row on the Looks page: "Haptics, on" with Off as the only other word. Off silences every haptic except the one soft `.warning` for a write that didn't save; a failed save always plays it once.
- **Words that point at it** must agree. Until Settings ships, Claude's controls are on Review, so the key refusal reads "It goes in Review, under Claude." and the miss notice "Turn this off on Review: Claude." The same PR that ships Settings changes both to "It goes in Settings, under Claude." and "Turn this off in Settings: Claude." Builder B owns the swap; QA checks both strings.
