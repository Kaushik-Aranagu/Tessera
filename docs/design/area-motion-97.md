# 97. Motion handoff for Builder A: the area-colour pass

For sheet 86 C (`areaLean`, see sheet 92). All motion goes through MotionPolicy.
- **Arrival**: on a page's first appearance the area colour does not pop. The caps label, key word and lead numeral mix from `ink` to `areaLean` over 320 ms (`Theme.Motion.house`); the section hairline fades to 34% over 420 ms, 60 ms later. Reduce Motion: a 150 ms crossfade, all together.
- **Between areas** (the side swipe, sheet 75): the colour travels with the name, rolling with the 420 ms word roll; nothing else recolours.
- **Key word**: the existing title progress effect still runs on top; the area colour is its resting stop, not its end.
- **Pantry states** are ink (weight tells OUT from LOW); `areaLean` is only on the Pantry's caps labels and index line. No second hue and no extra motion.
- **No haptic** on any colour change. Never animate on scroll; colour never changes with the page turn (sheet 90) because the area has not changed.
- Test: Obsidian and Porcelain, Reduce Motion on and off, Dynamic Type at the largest size.
