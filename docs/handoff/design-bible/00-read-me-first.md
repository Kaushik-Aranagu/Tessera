# Tessera design bible: read me first (Oct 24, 2026)

Latest consolidated design (Oct 25): [TESSERA-DESIGN.md](../TESSERA-DESIGN.md).

This is the whole design of Tessera as it stands on Oct 24, 2026, written so a design agent on another system or account (Codex or a fresh Claude) can pick it up and keep everything consistent. It covers every screen we designed, every effect and charm, the color, type and look rules, and what Kaushik liked and rejected.

Tessera is Kaushik's private iPhone app (SwiftUI, iOS 27), an "OS inside an app" built for an ADHD brain. Its assistant is Tess. The design lead was the Claude "Design studio" thread. Builders A and B and Core build from the sheets.

## How to use it
1. Read **01 System and learnings** before you touch anything. It holds the rules that apply on every page, plus the patterns behind his feedback.
2. Then read the room you are working on: **02 Home and Tess**, **03 Training**, **04 Kitchen, Lists, Notes**, **05 Routines, Money and the rest**.
3. Check **06 Open questions** before you present work. Those are real contradictions between sheets. Settle each one with Kaushik in one question with one recommendation, never by guessing.

## Which source wins
1. Kaushik's own latest words (thread messages, then his Codex chat digest `docs/handoff/codex-chat-oct24.md`).
2. The rules in 01 and the "Current hard rules" below.
3. The newest numbered sheet on the topic (`docs/handoff/design-sheets/`, full archive in the project design folder). A higher number is newer.
4. Older sheets, only for behavior they define that nothing newer replaced. Many early sheets describe a look that is gone (painterly grounds, Inter Tight, Fraunces, brushstrokes, dabs, cobalt Tess, pixel lintels, lens on swipe, rings, dots). The repo files `docs/DESIGN_MOTION.md`, the old themes.md sheet and the `tessera-design` skill still describe some of those old visuals. Don't copy them.

## The three newest rules from his Codex chat (2:45-8:35 AM PT Oct 24)
- **Keystone:** every app gets ONE expressive element, built from its own data, in the Home mosaic's slot. Home has the mosaic, Notes has the word wall, and Routines now has the habit woodland (248). It should be a small living world that reacts to what he does, adds and completes, does things by itself, and helps him navigate into the app. Static decoration doesn't count. Scenes must scale with the amount of data, so no per-item drawings. Studies for Training (live metal, a path with cairns), Kitchen, Recipes, Pantry, Lists, Weather and Money were "too basic" or unfinished, so those keystones are still open. He liked "pull apart to reveal a breakdown" as an interaction to reuse.
- **Every effect or reaction lasts 3 to 5 seconds at most.**
- **Density:** as much information in as little space as possible, without clutter. No long lists and no everything-on-one-screen: dials and swipes move between dimensions. No tabs, pills, filter rows or redundant buttons. The item itself is the control: tap opens, swipe or hold completes.

## Current hard rules (one line each; detail in 01)
- **Type:**
  - Figtree for words, Outfit for numbers, Newsreader only for Tess's own words.
  - Sentence case.
  - Units at about half the numeral's size, minimum 10 pt.
  - The 2-4 biggest words on a page never share a color.
- **Banned:** cards, pills, bars, rings, middle dots, filled dots, decorative underlines, lens or glass on swipes, fades on text, "...", "N of M" counters, foot menus and door rows.
  - Pixels and tiles appear only on the Home mosaic.
  - Two exceptions, both his own asks: the Notes areas glass pane, and the small note cards in the Notes Folio.
- **Color:**
  - 3-4 colors per page, chosen by meaning. Room color = title + action word.
  - Fixed state colors: done is green, late or needs care is wine, best or new is gold, planned or private is slate.
  - Nothing sits within ΔE00 10 of Tess's Ember (FF5A26 light / FF6B3D dark), except the room currently cueing her.
  - The word wall may use many colors.
- **Gestures:**
  - Swipe right = Done; swipe left = Not now.
  - Single elements swipe on both axes unless the axes mean different things. A strip owns any drag that starts on it.
  - Undo lasts 10 s everywhere. Money undo reads "Reversed".
  - Numbers never step with − / +. They scroll, and a tap opens a wheel.
  - Every wheel has depth blur (Notes dial up to 1.8 pt).
- **Layout:**
  - Landings are a summary plus a keystone plus doors, never the full list.
  - Use the 3-place dial on landings only. Deeper pages use other forms: a focus wheel, the Folio, a dimension line.
  - Text sits in fixed slots and never wraps or moves the layout. Tess shortens it.
  - Each depth level has one fixed block that stays the same on every sibling page.
  - Bottom left holds one action word (tap, or drag left or right for options). Tess is bottom right.
- **Data rules that shape design:**
  - No money on Home. Weeks start Monday. Sample data until production.
  - Health, body, calendar, calories, location and money never reach widgets, backups or logs.
  - Private items show as "Private …" or as a count off the phone.
  - Money actions are never offered to Claude. (Superseded Oct 27, 12:28 PM, by Kaushik's card answer: Claude may propose money changes, each pending with a 10 s Undo worded "Reversed"; see docs/product/decisions.md. Room agents still have no money tools.)
  - Free APIs only.
- **Motion:**
  - Everything goes through MotionPolicy (springs, haptics).
  - Reduce Motion and Low Power: no blur, no drift, cross-fades only.
  - No effect longer than 5 s.

## Status of every screen (Oct 24, 4:50 PM PT)
| Area | State | Sheet / board |
|---|---|---|
| Home | v2.2 approved; v2.3 vertical one-thing swipe and v2.4-2.8 weather word effects specified | 236; board DygjFLo442RxyE1kmn4rJM |
| Tess (corner, cloud, conversation) | specified | 215 final |
| Weather room | first cut, open | 243; board NyeaiLgka6cPQX3vqWZ1jj |
| Training | plan page, live workout and library specified (v20 not yet reviewed); landing needs a keystone | 230; board PFDdUde9cLtYA1G6Qjrpwp |
| Kitchen | cook mode, pantry and recipes specified; landing open (needs a keystone) | 231-234 |
| Lists | kinds v9 not yet reviewed; landing open | 237; board 9JBnr8TytGTnKtnnyXjdik |
| Notes landing | APPROVED Oct 24, 1:54 AM | 246; board 1mSPKcxhvQB4pFU2tmQZkx |
| Notes door pages | draft; must be reconciled with his Codex-era Folio and areas decisions | 247 v2 + codex digest; board S4dqsoynjdQMRQsV9EPW5z |
| Routines | woodland landing v1, awaiting his verdict; inner pages 238 | 248; board KZkqPY2U6VxDMBETRu3CML |
| Money | rules settled; look not redrawn in the current language | 223, 133 |
| Settings | sentence settings | 203; board Sm2gKa3mJFAmaGoF356b9K |
| Day log, Review, Shutdown, Plan my day, Upkeep, People, Reading | behavior kept; look needs a round | older sheets |
| Widgets, Lock Screen, Live Activities, Watch, app icon | no confirmed current look | see 02, 03, 05 |

Boards are claude.ai artifact pages, private to Kaushik: https://claude.ai/artifact/<id>. The sheets are the spec. Boards are only references.

## How the design work ran (keep doing it this way)
- One numbered sheet per round, plus a board he can open on his phone. He can't open file paths, so always give him a link to a page.
- Ask one question at a time, each with one recommendation. Never re-ask a settled pick; it frustrated him. Record every verdict with its time.
- He reviews fast and by voice. Short fragments like "too basic", "gaps", "monotonic" are full verdicts (see 01 §8).
- Sheets go to the repo as docs PRs, which merge without review. Builders build only from sheets, and only after his yes.
