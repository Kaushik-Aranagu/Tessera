# Review #231: Looks tokens, soul wash, glass back (f4ab565, head 570ef7c)

Builder A. 6 files, +35/-14. Static review (no Swift toolchain here).

**Verdict: PASS.** Kaushik's rule holds: the soul only changes on Porcelain and Celadon. One flag against the pure-black workout (G1), two notes.

## The pale wash only reaches Porcelain and Celadon
- `pale = look.field == .pigmentBloom || look.field == .glaze` (TessSoul.swift:122).
- Looks.swift fields: Porcelain `.pigmentBloom` (:64), Celadon `.glaze` (:102), Obsidian `.emissive` (:74), Plein `.plein` (:83), Lacquer `.lacquer` (:93). Exactly two looks match.
- On Plein, Lacquer and Obsidian, `wash($0)` uses the old defaults (0.8 / 0.6), and the halo keeps 0.22/0.14 when dark and 0.16/0.10 on Plein. Byte-for-byte the same palette as before. ✓
- On the two pale looks: washes 0.58 / 0.42, halo 0.08 / 0.05, blend still multiply, ring unchanged.
- `SoulPalette.workout` is unchanged (`.map { wash($0) }` is the same call). So the soul in the workout is the same in every look. ✓

## Other changes
- **Workout ask refusal is said (L1 from review-228-229, closed):** `onRefuse` sets `askReply` to "That looks like a Claude key. It goes in Review, under Claude.", which LiveTessCorner shows. Same words as Ask. Clearing `draft` re-fires `onChange` with "", which doesn't refuse, so the line is said once. ✓
- **Shared guard (N2 from review-230, partly):** `LiveAskField.refuses` now calls Core's `looksLikeClaudeKey`; WorkoutParts imports TesseraCore. BottomChrome and PasteRecipe still have their own copies (PasteRecipe case-sensitive, C6).
- **W12 (closed):** the navigation veil is back on `.ultraThinMaterial` with `raised` at 82% over it, so the navigation layer has glass again, as CLAUDE.md asks.
- **`restTint` / `Motion.dry`:** match the coordinator's description (0.45 light / 0.55 dark from `paintLook`; 1.1 s spring after 0.4 s, nil under Reduce Motion). Nothing calls them yet. Fine as tokens; the colour-at-rest PR will use them.

## G1: flag for the pure-black workout
- `WorkoutGlass` (WorkoutPaint.swift:83) now fills `.ultraThinMaterial` under `WorkoutPaint.glass` (the workout ground at 82%).
- On a pure #000000 ground, the 18% of dark material that shows through renders as a faint charcoal lift on every glass panel and sheet, and it blurs whatever is behind. Panels would read slightly grey against true black.
- That's what material does and may be what Design wants for depth. But if the pure-black workout means "nothing but black and ink", this fights it.
- Options for whoever builds pure black: make `glass` the opaque ground in the workout (no material), or keep the material and push the overlay to ~0.92. Design should pick from a recording on the black ground.
- The ask sheet's `presentationBackground(Theme.Colors.Workout.ground)` is opaque and follows the ground, so it's fine.

## Note
- `restTint` reads `ThemeStore.shared.paintLook.isDark`: inside the workout that's the pinned look or night, so rest tints there use 0.55. Right for a dark workout ground, including a light pin.
