# UI/UX lane: lessons

Scope: screens, motion, looks, copy, accessibility. Read CLAUDE.md, docs/DESIGN_MOTION.md and the `tessera-design` skill.

- Words and numbers go through `.textRole(...)`; never `.system(size:)`. Colours are Theme tokens; each app's accent is
  `Theme.Colors.Accent.<app>`. `live` is for fills and strokes, `liveInk` for words, and Undo stays `liveInk`.
- Animate only through MotionPolicy (`.tesseraAnimation`, `withTesseraAnimation`). No raw `.animation` or `withAnimation`;
  a later raw modifier silently wins over MotionPolicy. `Theme.Motion.dry(reduceMotion:)` is optional (nil under Reduce
  Motion): drying is a colour change at full opacity, never an opacity fade.
- Nothing is ever cut with an ellipsis. At accessibility sizes text wraps (no `minimumScaleFactor`, no `lineLimit` that
  cuts) and side-by-side rows stack. Check AX5 with the knob under its word, never squeezed beside it.
- No dots, cards, pills or lines between rows. A "done" mark is a set-mark brush ring (`SetMarkCircle`), not a filled
  circle. A lanes list that has to scroll clips to whole rows with a hard edge: no fades or blur at its edge.
- Every Review tab holds at most six rows (a test enforces it). A new tab changes the tab test: count, "next:" words and
  the nil index. Switch lists conflict often; when two branches add to the same facet line, keep both.
- Sentence case everywhere (no caps kickers or actions); a no-break space joins a number and its unit.
- Stills: `-demo` does not read Review switches; to see a switch On in the simulator, build once with its default flipped,
  shoot, and revert the edit (commit your real edits first, because `git checkout <file>` also reverts them). Kitchen
  dinners come from the Sample data switch, not `-demo`. At AX5 the UI automation snapshot never settles unless Reduce
  Motion is on.
- After switching branches, run `xcodegen generate` before building: a stale project fails with "Build input file cannot
  be found".
