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

## Sheet 359: a built room looks like a designed one

- Board map entry "Chart room (experimental)", screen "After a dozen sentences". This is the plant room after twelve sentences, and it renders through `landingV3`, the same player every preset room uses. That is the R1 promise: a room built by talking has the same places, moves, type and rules as the Galley or the Watch, with nothing that marks it as generated
- The sentences that built it, in order:
  1. Make this my plant room
  2. Put them on the keystone by when I last watered
  3. Glow the thirstiest one
  4. Let me mark one watered (Allow)
  5. Under the title, show what's thirsty, what's due this week, and light
  6. Put the thirstiest plant in the widget with how to water it
  7. Then the monstera, then the basil, which needs repotting
  8. Use the watering can for the first two
  9. A door for each plant, with when I last watered it
  10. Say how often and where each one sits
  11. Keep a Say word to change things
  12. Make it teal
- What each part is: title (`title`), switcher with Thirsty, This week and Light (`line` with needs `lines`), keystone (`row` with `top`), caption (`line`), widget (`list` of three, glyphs from the vetted set: can, can, grove), doors (`doors`, four, each bound to a plant), action words Watered and Say (`actionWord`)
- Colors: teal for the room, wine for the thirstiest, ink, and the glyph's own green. That is four, inside the 3 to 4 rule
- Door summaries are last-time lines and steady facts ("Last watered Wednesday", "Water every 7 days"), never a run of days
- Probe: `docs/design/boards/r66/pcf.js` (no overlap between places, nothing clipped)

## Sheet 360: point, then say

- In the Chart room, a tap on a place that holds something picks it for 30 seconds. A solid 1.5 pt slate line comes up 6 pt outside the place's frame, so it never touches the words inside, with a light haptic tick
- The action word names the place: "Say" with "what to change about the keystone". Whatever he says next changes only that place. This is the "this" of the Tess frame (a touch within 30 s), made visible
- Example on the board: pick the keystone, then "Make this calmer". The keystone goes ghost with the drying line and sets with its breathing slowed from 3.6 s to 7 s (the motion trait, one step calmer). The receipt reads "Keystone, calmer" with Undo
- Tapping the same place again, or 30 s passing, lets it go. A ghost can't be picked
- Builder A: the pick is `RoomState`-level UI, not a patch (it writes nothing). Core: the job's context sends the picked place's part ids first, and the validator refuses a patch that touches other places while one is picked, with "That changes more than the keystone. Say it again without picking?"
- Reduce Motion: the line appears without the 220 ms fade
- Probe: `docs/design/boards/r66/ppt.js`

## Sheet 361: the two ways Tess says no

The board's Chart room now has six sentences. Two new ones come before "Let me mark one watered", one for each way a change can't happen as asked.

- **A rule says no.** "Put a box around each plant" breaks the house rule (no cards or boxes). Nothing changes and no ghost appears. After the heard line, Tess answers in her own voice in the widget place (Newsreader italic 20 pt, ink): "No boxes in this house. Bigger numbers instead?" The receipt reads "Boxes, not here" with the button "Bigger numbers". Tapping it runs the offer as a normal change: ghost, drying line, set ("Numbers, bigger", Undo; the keystone numerals go 64 to 80 pt)
- **The kit says not yet.** "Make the keystone a ring of pots I can spin" needs a part the kit doesn't have. Nothing changes now. Tess says "A ring that spins is a new kind of part. I'm building it on the Mac, and it comes with your next install". The receipt reads "Ring, queued for your next install" with Undo, which takes it off the queue
- Tess never says "can't" or "error". A refusal names the rule in plain words and, where one exists, offers the nearest thing the rules allow
- The action word's small line keeps his own capitals ("make the keystone a ring of pots I can spin")
- Core: a validator rejection that has a nearest allowed change returns it as `offer` (a patch) with the reason line, so the receipt's button can run it with no second model call. A kit miss returns `queue: <part name>` for R5's Mac part builder; until R5, the queue is a list in the room's settings that the install notes read
- Probe: `docs/design/boards/r66/pno.js` (no ghost on refusal, keystone unchanged, offer runs, queue set). `pch.js` now walks all six sentences

## Sheet 362: the room remembers every sentence

- Hold the room's title (450 ms, a soft double haptic) for its history. It opens in the widget place: every sentence said to this room, newest first, each with the time it was said in Outfit at the right edge. The current version is the line in ink 600; the rest are ink 2. Long sentences wrap; nothing is cut
- Tap a line to see the room as it was then. Every place shows that version as a ghost (38%), and the action word reads "Go back" with "to how it was at 1:18 pm"
- Go back sets that version. The receipt reads "Back to 1:18 pm" with Undo, which returns to now. Going back is itself a change in the history, so nothing is ever lost
- Close (the action word while the list is open) or holding the title again shuts it. Tapping the current line ends a preview
- Refusals and queued parts are in the list too, since they were said; going back past them changes nothing they didn't change
- Fix found on the way (amends 358): a ghost's dashed outline crossed the first letters of its words, because content starts at the place's left edge and the outline sat 2 pt inside it. The outline now comes down when the ghost lands, not when it sets. The drying line alone marks the place while it dries, and Undo still raises the outline back
- Core: the history is the room's op log filtered to its op groups, each with the sentence as its note. "Go back to" writes one op group that is the inverse of every group after the chosen one. Builder A: preview renders the chosen version without writing
- Probe: `docs/design/boards/r66/phi.js`
