# How a design sheet and its board are made

This is how the Design studio produced every round for Tessera. Keep doing it this way so the next agent's work fits next to ours. Read the design bible (`../handoff/design-bible/00-read-me-first.md`) first: it has the rules every round must follow.

## The loop
1. **Take the ask.** Copy Kaushik's words into your notes with their time (PT). His fragments ("too basic", "gaps", "monotonic") are full verdicts. Check the bible and the newest sheet on the topic so you don't re-offer anything he rejected or re-ask anything he settled.
2. **Build a board.** A board is one HTML page that shows the screens at true phone size in both looks. The details are under "Board anatomy" below.
3. **Test it in a headless browser.** Use Playwright with Chromium:
   - check for page errors, and check that nothing scrolls sideways at 400 px;
   - take screenshots of every state;
   - look at the screenshots yourself before he sees anything.
   Test scripts live next to the board (`t.js`, `e.js`), and the parts are concatenated into `index.html`.
4. **Publish the board** as a private claude.ai artifact page and give him the link. He can't open file paths. When you revise it, publish to the same page so the link stays the same.
5. **Write the sheet.** It's a numbered markdown file (`<topic>-<number>.md`, the next free number), using the template below. Add a row to `README.md`, then mirror the sheet into `docs/handoff/design-sheets/` once builders need it.
6. **Ship it as a docs PR** to master. Docs PRs merge without review. Never put secrets, health values or real private titles in a sheet or a board.
7. **Get his verdict.** Ask one question with one recommendation. Work continues on the recommended option while he decides. Write his verdict and its time into the sheet ("APPROVED Oct 24, 1:54 AM").
8. **Hand it to the builders.** Builders A and B and Core build from the sheet only, and only after his yes. A rejected round stays in its sheet, marked REJECTED with his reason, so nobody re-offers it.

## Sheet template
```
# <number> <Screen>: <what changes> (<state: draft / APPROVED date time / REJECTED date time>)
Board: https://claude.ai/artifact/<id> (v<n>). Owner: <builder>. Supersedes <sheets>.

## His rules (<times>)
- one line per rule, in his meaning, with the time

## Page (402 x 874 pt frame, 24 pt gutters)
- top to bottom: each element with x/y or slot, font (family, weight, size), color role and hex, tap target

## <Element or algorithm>
- exact behavior, numbers, formulas, timings

## Motion
- every effect with duration, easing or spring, haptic, what Reduce Motion and Low Power do (≤ 5 s each)

## States
- empty, loading, error, private, long text (Tess shortens it; text never wraps a fixed slot)

## Rejected
- what he turned down, one line each with his words

## Open
- what still needs his call, each with your recommendation
```

## Board anatomy
- **Header:** a small-caps label ("Round 247, Oct 24"), an H1 naming the round, and one paragraph quoting what he asked for. Below that, tool rows of plain words (no pills): "Open" chooses the screen and "List" chooses the variant. The picked variant is marked "(pick)".
- **Phones:** two frames side by side at 402 x 874 pt, scaled to fit. The first is Paper (light, F7F5F1) and the second is Pure black (000). Each frame takes a class (`.lite`, `.blk`) that sets its color tokens (`--t`, `--t2`, `--room`, `--c0`…`--c11`). Both run the same code, and every interaction mirrors to both.
- **Notes under the phones:** plain paragraphs that explain each rule in words, so the board reads on its own.
- **Fonts:** Figtree (words), Outfit (numbers) and Newsreader (Tess's words), loaded from Google Fonts. Nothing else external except pinned CDN scripts.
- **Real behavior, not pictures.** Wheels turn, swipes work, moments run on their timers, Reduce Motion is honored (`matchMedia('(prefers-reduced-motion: reduce)')`). He judges motion, spacing and gaps from the board, so fake nothing he would judge.
- **Sample data only**, in US words, never a city name. Private items show as counts ("3 private notes").
- **Source layout for large boards:** `head.html` holds the styles, header and phone frames. `eng.js` is the engine, for example the word wall packer. `tail.js` holds the data and the page logic. Extras such as `folio.js` come after. Build with `{ cat head.html; echo '<svg id="ms" …><text id="mt"/></svg>'; cat eng.js tail.js; } > index.html`. The boards in `boards/` are exactly these files.

## Checks before you show him anything
- No cards, pills, bars, rings, dots, decorative underlines, lens or glass, text fades, "...", "N of M" counters, or foot menus. The exceptions he asked for are listed in the bible.
- 3-4 colors per page by meaning. The biggest words never share a color. Nothing sits within ΔE00 10 of Ember (FF5A26 / FF6B3D). Small text is 4.5:1 or better.
- Units at half the numeral's size, minimum 10 pt. Hit targets are 44 pt. Text fits its slot.
- Gestures: swipe right means Done and swipe left means Not now. Undo lasts 10 s. Numbers scroll, never step.
- Effects last 5 s or less. Every app's landing has a keystone in the mosaic slot.
- Compare screenshots of both looks, and phone width, before publishing.

## Where things are
- Sheets: this folder (`docs/design/*.md`). The newest are mirrored in `docs/handoff/design-sheets/`.
- Boards: `docs/design/boards/` (source HTML) and the claude.ai pages listed in `boards/README.md`.
- Recordings and stills: `recordings/`, `clips/`, `shots/`, `studies/`, `mockups/`, `motion/`, `icon/`.
- Index of everything: `INDEX.md`.
