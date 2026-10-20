# Class inspector (Design item 113)

Product rulings (huddle, Oct 19): a read-only page for a class: name, where it comes from (built in or yours), fields with types, links in and out, views, computed fields (formula text), object count. One key "Edit" opens the Remix editor (sheet 101); nothing is editable here.

## The page (one column, the class page grammar)
- Top word: the class name, hero type, stage-coloured. Under it, one line in `inkSecondary` 16: "Built in, 38 objects" or "Yours, 5 objects".
- FIELDS: one row per field: the name (21, ink) and its type as one word to the right in `inkSecondary` 16 ("number", "text", "date", "link to Exercise"). Computed fields show a second line under the name in `inkSecondary` 16, the formula text as written ("sets x reps x load"). A private field shows its name and "private"; values are never shown here.
- LINKS: "Exercise in", "Routine out": a name and a direction word, one per link; a tap opens the other class's inspector.
- VIEWS: the names of the class's views, one per row; a tap opens that view.
- Under a hairline at the foot: the key "Edit", `labelWord`, 44 pt, only for classes the user may remix (built-in classes open the Remix editor in its ghost-copy state, sheet 101).
- Hairlines between the four blocks; no cards, no pills, no icons.

## Where you get there
Long press on a class title on a class page, or "Inspect" in the object menu. The left edge goes back.

## Rules
- Read-only: no cursor, no edit affordance, no row swipe.
- Never shows object values or titles (private classes show counts only).
- A class with no links, views or computed fields omits that block (no "None" rows).
- Motion: the standard page turn. Reduce Motion: a 150 ms crossfade. One soft haptic on "Edit".
- VoiceOver: each row reads "name, type"; computed rows add "formula: ...".
- Switch: behind `classInspector`, Off, until Kaushik asks for it (a Settings > Review row on the Shown page).
