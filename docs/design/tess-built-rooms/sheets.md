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

## Sheet 363: other ways

- Swipe across a set keystone to see the next way Tess would draw it. The glass lens sits under the finger for the swipe only. The keystone follows the finger held back (a third of the travel, never past 28 pt), and there is one light haptic tick at 40 pt, where letting go takes the next way
- The ways, in order: four numbers in a row (what he asked for), one big number for the thirstiest (112 pt, "days" at half size beside it, the other three listed small at the right), and a ladder (names on the left, numbers right-aligned, both stepping down in size from the thirstiest). Swiping right goes the other way round
- The way he swipes to shows as a ghost (38%) in the keystone place. Tess's line in the widget place says which one it is: "One big number, for the one that needs you" (sheet 371 took out the "2 of 3" it first opened with, a counter the house rules don't allow). The action word reads "Keep" with "one big number"
- Keep runs the 2-second drying line and sets it. The receipt reads "Keystone, one big number" with Undo. Swiping back to the way that is set drops the ghost. Nothing is written before Keep, and leaving the room drops a ghost
- The transition is the witty part: every number is the same element in every way, so it flies to its new spot and size (the orchid's 6 grows from 64 pt to 112 pt, the basil's 1 slides into the side list), while the names fade in after 200 ms. Reduce Motion: no follow, no flight; the ghost changes in place
- By voice: pick the keystone and say "Show me other ways". The same first ghost opens
- A short swipe (under 40 pt) springs back with a small overshoot and changes nothing. A swipe never picks the place, and a tap still does (sheet 360)
- Builder A: a way is a `look` trait value on the part (`way: row | one | ladder`), so each way is a renderer of the same `row` part, not a new part. Number views carry `matchedGeometryEffect` keyed by the bound object id, which gives the flight for free. Core: a "show me other ways" sentence returns up to three `look` patches as variants; the room keeps them as unwritten previews, and Keep writes the chosen one as a normal op group
- Probe: `docs/design/boards/r66/pvw.js` (three ways, nothing outside the keystone place and no overlap in any way, Keep and Undo, a short swipe changes nothing, the voice path)

## Sheet 364: the room stays live

- A room built by talking holds no copies of his data. Its parts are bound to his plants, so when one changes, the room re-ranks by itself, and that move is the proof
- Watered the orchid: its 6 rolls down to 0 (the whole roll takes about 400 ms, never faster than 40 ms a step), and it walks to the end of the row while the others close up. The wine glow hands over to the monstera only once the move has settled (the last 28% of the 520 ms), with one light haptic tick. The name in the line and in the caption ("the monstera is thirsty", "the monstera first") rises 0.4 em into place after 180 ms
- The action word moves on to "Watered the monstera". The receipt reads "Orchid, watered" with Undo, and Undo plays the same move backwards (the number rolls back up to 6 and the orchid takes the glow again)
- When all four are watered, the line reads "4 plants, all watered", the caption is just "Days since water", nothing glows, and the action word goes back to "Say anything else"
- It works the same in every way from sheet 363. In the one-number way the monstera's 4 grows out of the side list into the big spot, and the orchid's 0 shrinks into the list's end
- Reduce Motion: no roll, no walk, no rise. The room changes in place, and the haptic tick stays
- Builder A: the re-rank is `ForEach` keyed by the bound object id, inside `withTesseraAnimation`, with `contentTransition(.numericText(countsDown:))` for the roll. The glow is a separate state that follows the ranking after a short delay, so it never travels with the old leader. Core: no new work. A bind resolves at render time, which R1 already specifies
- Probe: `docs/design/boards/r66/plv.js` (order after watering, the glow and both sentences follow, Undo restores, all watered, nothing outside the keystone place)

## Sheet 365: where the room lives

- The Chart room sits in Bridge's apps dial right after Purse. Until it is named, the row reads "Chart room" in slate, and the line on the right reads "Say what it's for"
- Once he names it ("Make this my plant room"), the row carries the name he gave it and the room's color, and the line on the right is the room's own top fact, live: "Orchid, 6 days", then "Monstera, 4 days" after he waters the orchid, then "All watered". Bridge reads a room built by talking the same way it reads a preset room
- The dial keeps the old name until he turns to that row. There, once, the old name in slate lifts 0.6 em and fades (400 ms, after the dial's own 380 ms settle), and the new name rises into its place in the room's color. After that it is plain text. Reduce Motion: the new name appears, no move
- Colors, found on the way: teal, which the board gave the plant room in 357 and 359, sits ΔE76 6.8 from the Purse's 2A7878, and the two are neighbors in the dial. A room's color is how he tells rooms apart as he moves between them (the dial's focus row, the room's title, Tess's tint), so two rooms can't share one. The plant room is now olive (5E6B1F / B5BE7A), the Lists color the Log freed in sheet 280. It sits 31 or more from every room in light and 24 or more in dark. Sheet 359's twelfth sentence, "Make it teal", now gets the refusal from 361: "Teal is the Purse's. Olive, like the leaves?", and the offer runs
- New validator rule in `r1-spec.md` section 4: a room's own color sits ΔE76 20 or more from every other room's color, in both themes
- Open, for Kaushik: the same check finds the Watch (8E4A78 / D59AC4) and the Log (8A4570 / E3A3CB) only ΔE00 2.0 apart in light and 3.1 in dark, neighbors in the dial. Turning from one to the other, the color doesn't change, so they read as one plum. The design bible already lists this as open (`docs/handoff/design-bible/01-system-learnings.md`, item 3 near line 365). It needs his pick before anything changes on the phone
- Builder A: the dial reads `name`, `color` and the top fact from the Room object, so nothing about the Chart room is hard-coded in Bridge. The once-only relabel keys on the last name the dial showed, stored on the room
- Probe: `docs/design/boards/r66/prl.js` (row after Purse, slate and "Say what it's for" before naming, relabel once on focus, olive and the live fact after, opens the room)

## Sheet 366: the frame sketches itself

- A blank room doesn't appear all at once. 300 ms after it arrives (so the move in is over first), each place's dashed outline unrolls from its top left corner, where its name sits: the top edge runs right while the left edge runs down, over 440 ms, like a frame pencilled in. The places go one after the next down the screen, 70 ms apart, title first and doors last. The whole frame is drawn by about 1.1 s
- Each place's name slides in 4 pt from the left once its corner is drawn (240 ms, 140 ms after the outline starts)
- It plays only for a place that is still empty. A place that already holds something never shows its outline (sheet 358), so a half-built room sketches only what is left to fill
- It is the opposite of sheet 358, where a set place's outline drops 6 pt and lets go: the frame is drawn in when the room is new, and taken down piece by piece as it fills
- Reduce Motion: the outlines are simply there
- Builder A: a `trim(from:to:)` on each place's rounded-rectangle stroke, started from the top left corner, staggered by place order inside `withTesseraAnimation`; the name uses the same stagger plus 140 ms. No haptic
- Probe: `docs/design/boards/r66/psk.js` (staggered progress down the screen, done by 1.3 s, no animation with Reduce Motion)

## Sheet 367: a wish, and a look at tomorrow

The board's Chart room now has seven sentences. The new one comes before "Let me mark one watered".

- "Tell me when one goes a week without water" is a wish: a sentence about the future that the room keeps as a rule. It lands like any change (ghost, drying line, set) as its own line at the foot of the widget place, in ink 2: "Tess tells you when one goes a week dry". The receipt reads "Wish, set" with Undo
- Tess answers in her line: "The orchid gets there tomorrow. Tap the wish to see it"
- Tapping the wish shows tomorrow. Every number steps one day on and rises a little as it changes (320 ms, 40 ms apart). The line, keystone and caption go ghost, since none of it is true yet. The caption reads "Tomorrow, the orchid has gone a week", and Tess's line is the notice she would send: "Tomorrow morning I'd tell you: the orchid has gone a week without water". The action word reads "Back" with "to today"
- Nothing is written in the preview, and watering waits until he is back. Back, or tapping the wish again, returns to today
- History (362) goes back and the wish goes forward, and both show the room as a ghost, so the room has one way of showing a time that isn't now
- When the wish fires on the phone, it is a notice on Bridge's top lines ("Orchid, a week without water") and a notification. It never counts a run of days (the no-streaks rule): it names one plant and one fact
- Layout: in the widget place, Tess's line sits at the top, the reach line ("This room can now mark plants watered") below it, and the wish at the foot. The probe checks they never overlap
- Core (R3 preview, not in R1): a wish is a `wish` part with a condition over a bind (`daysSince(lastWatered) >= 7`), an action (`notify`, with the text built from the bound object), and a check time (morning). The validator treats `notify` as a reach widening, so it waits for Allow the first time, like a write. The tomorrow preview evaluates the condition at now + 1 day without writing. Builder A: the wish line is a `line` part in the widget place, and tapping it toggles a `RoomState.preview(.tomorrow)`
- Probe: `docs/design/boards/r66/pwi.js`. `pch.js`, `phi.js` and `plv.js` now walk seven sentences

## Sheet 368: Undo un-dries

- Undo on a change Tess made plays the change backwards. The parts go back to ghost (38%). The drying line comes back at full length along the foot of each place they filled, then runs back from right to left, faster than it came (600 ms, easing in). Then the parts let go, and the place's outline comes back up (sheet 358)
- So a change arrives and leaves the same way, and he can see exactly which places it touched as it goes
- A new sentence takes the last receipt down as it starts drying. An Undo tap can't land on the wrong change while the next one dries. The earlier change can still be taken back from the history (sheet 362)
- Undo during the tomorrow preview (367) first returns to today, then un-dries
- Reduce Motion: the change goes at once, with no line
- Builder A: the reverse drying line is the same view with its trim end animated from 1 to 0, inside `withTesseraAnimation` with an ease-in curve. The op group is marked `undone` when the line reaches 0, not when Undo is tapped, so the store and the screen agree. No haptic on the way out
- Probe: `docs/design/boards/r66/pdu.js` (ghost with the line running back, then gone and the outline back; no Undo while the next sentence dries)

## Sheet 370: Allow waits

- A change that widens what the room can do now waits for him. When "Let me mark one watered" has dried, the receipt no longer says "Watered, set". It reads "Waiting for your Allow" with "Not now", and the reach line above it, "This room can now mark plants watered" with Allow, is the only way forward
- Until he taps Allow, nothing in the room can write, and the action word stays on "Say anything else" instead of "Watered the orchid"
- Not now plays the change backwards (sheet 368) and the room is as it was before the sentence
- Allow sets it. The outline lets go, the action word turns to "Watered the orchid", and the receipt then reads "Watered, set" with Undo. Undo takes back the change and the grant together, so the room can't keep a reach he has taken back
- Before this, the receipt said "set" while the room still waited for Allow, so the screen claimed something the store hadn't done. The receipt now only ever names what is true
- Core: a patch whose validator result is `needsAllow` lands as a pending op group. It is committed (and the receipt says "set") only on Allow; Not now drops it. Undo of a committed reach patch reverts the grant in the same op group. Builder A: the receipt takes its word ("Not now" or "Undo") from that state
- Probe: `docs/design/boards/r66/pal2.js` (waiting, Not now back to six sentences, Allow then "Watered, set", Undo back with no reach)

## Ruling: the Log is violet

- Kaushik's pick, 5:39 PM PDT Oct 27, on the card from sheet 365: the Log gets its own color, deep violet 5B2277 light / BB70E1 dark. The Watch keeps its plum 8E4A78 / D59AC4, which is in the locked woodland
- Watch to Log is now ΔE00 16.5 in both themes (it was 2.0 and 3.1). Violet sits ΔE76 29 or more from every room in light and 40 or more in dark, and ΔE00 16 or more from every Ember color
- It replaces the plum 8A4570 / E3A3CB the 246 landing proposed. The Legs plum in the Deck and the word wall's twelve brick colors are kind colors, not the room's, and stay as they are
- Phone (Builder B): `Features/LayoutMode/LayoutRooms.swift` `.log` to (0x5B2277, 0xBB70E1); `Features/Notes/NotesWallLanding.swift` `plum(_:)` to violet, with its comment; `Features/Tess/SoulRoomTint.swift` `.notes, .lists` to violet. Nothing else changes
- Board: `--notes` is 5B2277 / BB70E1. Probe: `docs/design/boards/r66/plg.js` (the Log's title in violet in both looks)

## Sheet 371: taking a room down

A room Tess built is a view over his things, so taking it down is the end of the view and never of the things. The board's Chart room now ends on "Take this room down", which the action word offers once nothing waits for Allow.

- In the room: his words come up in his line as usual. Every part goes back to ghost (38%). Then each place's outline comes back up, doors first and 50 ms apart, so for a moment the room is the frame it started as. Then the outlines fold back into their top left corners, where their names sit, the same order, each 340 ms and easing in. The parts in each place fade with it. The title goes last. It is sheet 366 played backwards: the frame came in from the corners and goes out to them. Done by about 1.3 s
- The room is empty by then, so nothing slides off the screen. What is left of it dissolves (240 ms) and Bridge is under it
- On Bridge: the dial is on the room's row, which is gone. The rows from that place down close up into the gap. The one sliding into focus, the Lookout, starts as the neighbor it was (small, gray, soft) and grows into focus, and the row under it fades in from below the dial, with a small overshoot (460 ms, 40 ms apart). The summary line on the left reads the Lookout's fact
- The foot reads "Room taken down, not the plants" with Undo for 10 s. The second half is the point: his plants and their watering days are all still his, and Tess can still answer about them
- Undo opens the gap again: the row under it drops back down and the room's row comes back into focus, fading and growing in. On the board, if the room has never been seen in the dial under its new name, the relabel from sheet 365 plays then
- While a change waits for Allow (sheet 370), the action word stays on "Say anything else", so a pending grant can't be taken down with the room by accident
- Reduce Motion: Bridge simply appears with the row gone and the foot line; Undo simply puts it back
- Core: taking a room down archives the Room object and its patch history in one op group (`archivedAt`), and deletes nothing it binds to. Undo is that op group's revert. An archived room keeps its sentences, so "Bring back my plant room" later restores it exactly. Taking a room down also ends its wishes (no notices from a room he can't see) and its grants. Builder A: the dial's rows are a `ForEach` over Room objects with stable ids, so removing one moves the rows below with the dial's spring; the fold is the 366 `trim` run from 1 to 0, staggered from the last place to the first
- Probe: `docs/design/boards/r66/pdn.js` (outlines up doors first, the room gone, Bridge on the Lookout with the row closed up, the foot line and Undo, Undo puts the row back; no overlap with the foot; Reduce Motion)

## Sheet 372: a room comes back the way it was made

- A room keeps itself while he is away. Leaving and coming back shows it as he left it, with every sentence and grant in place. Before this, the board's Chart room started blank each time
- A room he took down (sheet 371) and brought back, by Undo or later by saying "Bring back my plant room", rebuilds itself the first time he opens it, the way he made it. The frame sketches in as for a new room (sheet 366). Then his own sentences go by in his line, softer (55%) and quick, and each sets its places with a short drying line (240 ms, then 80 ms to the next), in the order he said them. It is a time-lapse of his own building, about 2.2 s from the door
- Sentences that changed nothing are skipped: the box Tess refused and the ring still queued for the next install. So the replay is the room's real recipe and not a transcript
- The numbers land on today's values, not the ones from when it was built, because the plants kept going while the room was away. The grant comes back with the sentence that asked for it. If he never tapped Allow, it comes back still waiting
- Tess ends it in her line: "Back the way you made it"
- While it plays, the action word reads "Skip" with "to the room as you left it". A tap anywhere does the same: the room is there whole at once, and that tap does nothing else, so it can't water a plant by accident
- It plays once. After that the room is simply there
- Reduce Motion: the room is simply there whole
- Core: an archived room keeps its patch history in order. Restoring it replays the patches that set parts (`changed: true`), skipping refused and queued ones, against today's data. The replay is display only and writes nothing new. The room's `restoredAt` marks that the replay is owed, and the first open clears it. Builder A: the replay runs the R1 player's own patch animation at 0.12× duration, under one `withTesseraAnimation` task that a tap cancels by jumping to the final document. No haptic until the last step, then one soft one with Tess's line
- Probe: `docs/design/boards/r66/prb.js` (kept on a quick return; the replay plays, skips the refused and queued sentences and ends whole with the grant; once only; a tap finishes it and does nothing else; Reduce Motion)

## Sheet 373: touch your words to stop a change

The 2-second drying line was only a wait. Now it is the window for him to change his mind, which voice needs most, since Tess can mishear.

- While a change dries, his words in his line are a touch target (the line plus 8 pt above and below). Touching them stops it. On the phone, saying "wait" or "stop" does the same
- The drying line holds where it got to for a breath (120 ms), then runs back from there to its start, at Undo's pace (600 ms for a whole line, so less when he caught it early, never under 140 ms), easing in. Then the ghost lets go and each place's outline comes back up (sheet 358)
- Nothing was written, so there is no receipt and nothing to undo. Tess says "Stopped, nothing changed" in her line, and the action word offers the same sentence again, so trying it another way is one tap
- A refusal or a queued part (sheet 361) waits 1.2 s with his words up and no line. Touching them then stops it the same way, and the ring is not queued
- A take-down stopped half way (sheet 371) plays its fold backwards from where it got to. The outlines unfold out of their corners and the parts come back, and the room stays in the dial
- One light tick at the touch. Reduce Motion: it stops at once
- Undo (sheet 368) is for a change that has set. Stop is for one that hasn't. The two never overlap: the receipt with Undo only appears once a change has set
- Core: a patch is applied to the store only when its drying ends. Until then it is a staged op group, and stop discards it. The 2 s is the same window the validator already uses. Builder A: the drying line is the view whose trim end runs from 0 to 1. Stop pauses that animation, reads its presentation value, and animates back to 0 from there inside `withTesseraAnimation`. A tap on the heard line calls the player's `cancelPending()`
- Probe: `docs/design/boards/r66/pst.js` (stop at 1 s: the line holds, runs back, the ghost lets go, no receipt, Tess's line, same sentence offered; say it again and it sets; stop a refusal while it waits; stop a take-down half way and the room stays; Reduce Motion)

## Sheet 374: one lifecycle

- No new screen this round. Sheets 358 to 373 each added one state to how a change or a room behaves. They are now in one place, `r1-spec.md` section 9: two tables, one for a change (staged, stopped, waiting for Allow, set, un-dried, refused, queued) and one for the room (blank, live, archiving, archived, restored), each with what he sees, the way in and the ways out
- The point is that every state has exactly one look, wherever it happens. A ghost is always 38%, a line always runs left to right to set and right to left to leave, and Tess's line always says what happened in words. So the room never needs a new convention for a new sentence
- Three rules hold in every state: nothing is written before a change sets; taking a room down never deletes what it shows; every state's Reduce Motion form is its end state at once
- Core's tests get one case per arrow, and the round trips (stop, un-dry, archive then restore) must leave the store byte-identical
- Board: the Chart room's map note now lists 371 to 373

## Sheet 375: each plant gets a door

The doors place was the one place the Chart room never filled. The board's room now has eight sentences, and the new one comes before the wish: "Give each plant a door".

- It fills the doors place the way every room's doors look (sheet 283): the room's own dial on the right, under his right thumb, and the summary on the left. The rows are the plants in the keystone's order, thirstiest first, each with its days in small numbers. The focused row takes its plant's color: wine for the one that needs water, olive for the rest. The summary is where the plant lives ("By the east window")
- Taps in the dial turn it or open the focused door. They never point at the place (sheet 363), so choosing a plant and asking Tess to change the doors can't get mixed up. Pointing still works on the summary
- A door opens the plant itself. Nobody designed a page for a plant, so it gets the class's plain page, the one every object has until he says how it should look. It has a back word ("Plants"), the name in olive and one line ("Watered 6 days ago, by the east window"). The keystone slot holds its one number, with the unit at half size ("6 days", or "Today"). Below that come the caption, the care note and Tess's line: "Every plant gets this plain page until you say how it should look"
- Watering on the plant's page needs no Allow. Allow is for what a room Tess built may do. Here he is marking his own plant on its own page. The action word reads "Watered today", the number rises into "Today", and the receipt reads "Monstera, watered" with Undo. Once it is watered, the action word reads "Back to Plants"
- Back in the room, the keystone and the doors already show it ("6 2 1 0", the Monstera last). Nothing was copied, because the room only ever showed the plants. The dial stays on the plant he opened, now at its new place in the order
- Core: the doors part is a `doors` part bound to the room's list (`bind: Plant`, the list's sort), so it re-orders with the keystone. Each row's object id is the door's destination. The plain page is the class's default `ViewDef` (title, one line from the two most recent fields, the first number field in the keystone slot, notes, Tess's line), generated, not stored, until he changes it. A write from the object's own page is his own op and goes through no room grant. Builder A: the doors place uses the same door dial view as every landing. The plain page is `ObjectPage` with the generated view
- Probe: `docs/design/boards/r66/pdr.js` (doors ghost while drying, then set; keystone order, wine focus, summary; turning doesn't select the place; the plant page and its line and number; watering there with Undo; back in the room, re-ordered and still focused; no overlap with the wish, the reach line, the receipt or Tess, in paper and black). The other Chart room probes now walk eight sentences

## Sheet 376: change one plant's page, every plant gets it

A plant's plain page (sheet 375) belongs to the Plant class, not to one plant. So a change said on one plant's page reaches every plant's page, and Tess says so. This is the object model showing through in one sentence.

- Once the plant is watered, the page's action word offers "Say show when I watered it". His words come up in his line, and the new part arrives in ghost under the care note: "Last three times: Oct 25, Oct 21 and Oct 15". The 2 s drying line runs along its foot, as for any change (sheet 357)
- When it sets, Tess says what it reached: "Every plant's page has it now, not just the monstera's". The receipt reads "Every plant's page, set" with Undo. The scope is in the receipt because it is the surprising part
- Open any other plant and the part is there with that plant's dates ("Oct 23, Oct 20 and Oct 17" for the fern). Tess's line on every plant's page now reads "This page is every plant's. Say a change and they all get it"
- Undo un-dries it (sheet 368), and touching his words while it dries stops it (sheet 373), the same as in a room. One look for a change, wherever it is said
- Just one plant: "just for the orchid" makes the change on that plant alone. Sheet 378 draws it
- Reduce Motion: the line is drawn whole and the change still waits its 2 s
- Core: a patch said on an object's page targets the class's `ViewDef` (here Plant's generated page becomes a stored one at its first change). The patch result carries its scope (`class` with a count of objects, or `object` with an id), and Tess's line and the receipt are built from it. "Only for the orchid" writes an object-level `ViewDef` override that wins over the class's. Builder A: `ObjectPage` reads the override first, then the class view, then the generated default. The receipt's text comes from the patch's scope, never from a fixed string
- Probe: `docs/design/boards/r66/pcv.js` (the offer after watering, ghost and line, set with the scope in Tess's line and the receipt, Undo un-dries, a touch stops it, the fern's page has it with its own dates; no overlap or cut words in paper and black; Reduce Motion)

## Sheet 377: through a door, the name and number travel

Opening a plant's door (sheet 375) used to cut from the room to the plant's page. Now the two things he was looking at travel with him, so the page reads as the same plant seen closer, not a new screen.

- Going in: the plant's name leaves the focused dial row and grows into the page's title. Its number leaves its keystone column and grows into the page's big number. The rest of the room fades under them. Both move together over about half a second, fast at first and settling at the end, and take their new color on the way
- Coming back: the title flies back into the dial row, and the big number shrinks home into the plant's column. If he watered it, that column has moved to the end of the row (sheet 375), and the number goes there
- When the words differ, the old word never makes the trip. "Today" on the page fades where it stands in 0.1 s, and a "0" in the page's size takes its place and flies. A wide word in flight sweeps across the other columns and reads as a broken word ("Todc" at the edge), so only the word that will land is ever in motion
- The number goes first and the name a beat later (40 ms), so the name never crosses the big number. The other plants' numbers come in only after his plant's number has passed, so it travels along an empty row and nothing in flight overlaps anything at rest
- Nothing else moves. The caption, care note and Tess's line crossfade as before, and the dial keeps its place on the plant he opened
- Reduce Motion: no flight. The page and the room crossfade, and the name and number are simply there
- Core: nothing new. The flight is view-only and reads the same objects on both screens. Builder A: this is a shared-element transition keyed by the object id. The dial row's label and the page title share one `matchedGeometryEffect` id (`"\(id).name"`), and the keystone column's number and the page's number share another (`"\(id).number"`). When the two strings differ, the source fades out in place and the destination text animates from the source frame, rather than morphing the text. Neighbor columns get a delayed opacity transition on return. Run it all inside `withTesseraAnimation`, and use no flight when `MotionPolicy` reports Reduce Motion
- Probe: `docs/design/boards/r66/ptv.js` (going in: two clones in flight and the destination hidden; landed: no clones and the title and number shown; going back after watering: the name, "Today" fading in place and "0" starting at the same spot; home: the keystone reads "6 2 1 0" with the Monstera focused and nothing hidden; Reduce Motion: no clones)

## Sheet 378: one plant's own page

Sheet 376 made a change said on a plant's page reach every plant's page, because the page is the class's. Sheet 378 is the other half: "just for the orchid" puts a change on the orchid alone. The orchid gets its own layer over the class's page, and the other plants never see it.

- On the orchid's page, once every plant's page shows when it was watered, the action word offers "Say just for the orchid, show its misting". Only the orchid has a misting step, so only its page offers it
- His words come up and the part arrives in ghost under the dates: "Last misted Thursday, in Water houseplants". The 2 s drying line runs along its foot (sheet 357), and Tess's line moves down one line to make room
- When it sets, Tess says what it reached and why: "Only the orchid's page, the others don't get misted". The receipt reads "The orchid's page, set" with Undo
- "Water houseplants" is in the Watch's plum, because the misting lives in that routine (its third step, "Mist the orchid"). Tap it and the routine opens. Its back word reads "Orchid", in olive, so the way back names where he came from
- The orchid's page then says how it is built: "The misting is the orchid's own, the rest is every plant's". The fern's page is unchanged, with its dates and "This page is every plant's. Say a change and they all get it"
- The parts stack from the care note down. If the dates are ever taken off, the misting moves up into their place and leaves no gap
- Undo un-dries it (sheet 368), and touching his words while it dries stops it (sheet 373). Reduce Motion: the line is drawn whole and the change still waits its 2 s
- Core: "just for the orchid" writes an object-level `ViewDef` override on the orchid (sheet 376), holding one part. The part is bound through a link, not copied: `Plant.orchid -> Routine.plants.steps[2]`, and its line reads that step's last done date. The patch result's scope is `object` with the orchid's id, and Tess's line and the receipt come from it. Undo removes the override. When an override holds no parts, it is deleted, so the orchid falls back to the class page. Builder A: `ObjectPage` lays its parts out from the override, then the class view, then the generated default, stacked with no fixed slots. A part bound to another object renders that object's name as a link in the other room's color. Opening it pushes that object's page with `from` set, and the back word reads `from`'s name in its color
- Probe: `docs/design/boards/r66/pob.js` (the offer after the dates set, ghost and line at the part's foot, Tess and the receipt name the orchid, the link in plum in paper and black, the routine opens with "Orchid" as its back word and returns to the orchid, the fern's page has no misting, Undo un-dries, a touch stops it, no overlap or cut words; Reduce Motion)

## Sheet 379: misted in the routine, the orchid knows

Sheet 378 bound the orchid's misting line to the Water houseplants routine through a link. This sheet shows why it is a link and not a copy: check the step off in the routine, and the orchid's page already says so.

- From the orchid's page, "Water houseplants" opens the routine with "Orchid" as its back word (sheet 378). In the step list, the word "orchid" in "Mist the orchid" is in olive, the orchid's color, so he sees where he came in. The word is not a link: a tap on the row still checks the step off, as on every routine
- He checks "Mist the orchid" off (tap or swipe right). The receipt reads "Mist the orchid, done" with Undo, as for any step
- Back on the orchid's page, the line reads "Last misted today, in Water houseplants". The word "today" lifts into place once, a beat after the page arrives, and Tess says where it came from: "Misted in Water houseplants, so this page already knows". On the next visit Tess's line is back to "The misting is the orchid's own, the rest is every plant's"
- There is one value, not two. Opened again, the routine shows the step done because the orchid was misted today, whichever page did it. Unchecking it there, or Undo, puts "Thursday" back on the orchid's page
- Opened from the Watch instead, the routine is as it always was: its grove for the back word and no colored word
- Reduce Motion: the day doesn't lift. The line and Tess's words are the same
- Core: the part reads the step's last done date through the link, and the step's check op is the only write. No new op type and no sync between the two pages. Builder B: in `RoutineView`, when it is pushed with `from`, the step label that names `from` gets `from`'s color, and only that word. Builder A: `ObjectPage` compares a bound part's value with the one it last showed, and when it changed while he was away it plays the lift once inside `withTesseraAnimation`. Tess's line comes from the op's source (the routine's name)
- Probe: `docs/design/boards/r66/pmi.js` (the routine opens with "Orchid" and an olive "orchid" in paper and black; checking it off makes the page read "today", with the lift and Tess's line; the next visit has neither; the routine shows the step done when opened again; unchecking and Undo put Thursday back; opened from the Watch nothing is marked; no overlap; Reduce Motion)
