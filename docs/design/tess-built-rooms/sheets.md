# Tess-built rooms: board sheets

The design and its reasons are on the Tess-built rooms page (`index.html` here; research in `research.md`). These sheets draw it in the app's real frame on the board (`docs/design/boards/r66/index.html`, map entry "Chart room (experimental)").

## Sheet 357: the Chart room, blank, built by talking

- The room opens as the bare frame. Title, Line, Keystone, Caption, Widget and Doors are each drawn at their exact shell frame as a dashed outline, inset 2 pt, with the place's name in 11 pt ink 2 at its top left. Nothing else is on the screen except the action word and Tess
- Action word bottom left: "Say", in slate. Its small line shows the next thing to say on the board; on the phone it reads "what to build"
- What he said shows in the Widget place in Newsreader italic 20 pt, ink 2, in quotes, while Tess works. It leaves when the change sets
- A change lands as a ghost: its parts at 38% ink in their own places, and that place's label hides so nothing overlaps. The 2-second drying line, 1 pt in the room color, runs along the foot of each filled place. When it reaches the end, the ghost sets to full ink, the outline lets go, and the receipt reads "Plants, set" with Undo
- Reach: a change that lets the room write his data ("Let me mark one watered") shows its own wine line, "This room can now mark plants watered", with Allow. Nothing writes until he taps it. Undo takes the permission back with the change
- After Allow, the action word becomes "Watered" with "the orchid" (the thirstiest plant). Tapping it marks the plant, the glow and the line move to the next thirstiest, and the receipt "Orchid, watered" carries Undo
- The keystone here is four Outfit numerals (days since water) over the plant names; the thirstiest one is wine and breathes slowly. It is a last-time number, not a streak
- Reduce Motion: the drying line is drawn whole and nothing breathes; the change still waits 2 s before it sets
- Probe: `docs/design/boards/r66/pch.js` (4 sentences, ghosts then set, every part inside its place, Allow, Watered, Undo)

## Sheet 358: the scaffolding comes down

- When a place sets, its dashed outline doesn't just vanish. It drops 6 pt, shrinks to 98.5% and fades out over 380 ms (cubic-bezier .4,0,.6,1), like scaffolding lowered off a finished wall
- Places that set together go top to bottom, 1 ms of delay for every 4 pt down the screen (the title first, the keystone about 36 ms later), so a two-place change reads as one motion
- Undo runs the same move in reverse: the outline rises back into place as the part leaves
- Reduce Motion: the outline only fades, 200 ms
- Builder A: the same transition on `SlotKind.parts` places, through `MotionPolicy`
- Probe: `docs/design/boards/r66/psc.js`
