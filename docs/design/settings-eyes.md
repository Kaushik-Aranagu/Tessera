# 70. Tess has eyes: the setting for her face

**Kaushik's principle, in one line:** Tess's face is one plain sentence in Settings that he flips with a word, and the face answers on the soul itself.

This sheet is for Builder B (Settings, in the post-#366 batch), with Builder A reading the value. The decisions behind it are Product's 9:58 AM Oct 16 call: one setting for her face, eyes and mouth together, no mouth without eyes, default off. The setting is `tessEyes` (#407, now Catalog v10, merging after the pin).

- Board: `mockups/settings-eyes.png` (Porcelain and Obsidian, no and yes, each with a 6× loupe on the soul).
- Recording: `recordings/settings-eyes.mp4` (10 s, Porcelain): "no" flips to "yes", her eyes open on the soul, she blinks twice, then it flips back to "no" and the face goes.
- Study: `studies/settings-eyes.html`.

## The line
- It lives in **LOOK**, as the section's third sentence, under the hint line: "Tess has eyes: **no**." Her face is how she looks, so it sits with the looks, and Settings keeps its four labels (LOOK, CLAUDE, BACKUPS, UNITS).
- **"no" / "yes" is a value word** (600, `ink`) that cycles on a tap, like "Tess asks Claude". There is no toggle shape. The ink line draws under the word in 150 ms, the word crossfades in 60 + 60 ms, and the line undraws 200 ms later. One haptic: the value word's existing selection tick.
- The words stay "Tess has eyes", even though the mouth comes with them. "Eyes" is what he asked for, and the mouth is part of the same face. If he later wants eyes without a mouth, that becomes a second sentence under this one, not a rewording.

## Tess answers inline
Under the line, in cobalt Body 21, third person, as every Settings answer is (`settings-place.md`, "Where Tess speaks"):
- To yes: "Tess has a face now."
- To no: "Tess has no face. She still moves."
The answer grows in over 320 ms on the house curve and stays until the next change in LOOK. CLAUDE and the sections below slide down 36 pt with it, on the same curve.

## The face answers on the soul
The soul in Tess's band shows the change as it happens, so the flip is something he sees, not just reads.
- **To yes:** 220 ms after the tap, the eyes appear with the lids at 0.25, then open over 400 ms, ease-out (idea 2's open). The mouth fades in at rest (curve +0.2) over 200 ms with them. One blink follows 1.6 s later. After that she runs her normal blink clock (3 to 8 s).
- **To no:** the face fades in 120 ms (the eyes' fade out, `tess-motion.md` and #403). Her breath, drift and colour carry on unchanged.
- **Reduce Motion:** no lid opening. The face crossfades in 150 ms either way.
- Nothing else on the page moves for it, and Tess says nothing in her band. The answer is the inline line.

## For the builders
- **Builder B:** the sentence in `SettingsView`'s LOOK section, writing `tessEyes` through the settings object (it rides in backups like every setting). Add the inline answer lines and a UI test for the flip and the answer. This replaces the batch's placeholder "Tess has eyes: no." with this sheet.
- **Builder A:** read `showsTessEyes` from the setting instead of the LaunchFlags stub (after #407). On a change, play the open or the fade above through the soul router; the view doesn't animate the face itself. `SoulMouth` follows the same flag.
- **QA:** the default is no on a fresh install and after a restore from a backup made before v10. A backup made with yes restores yes.
