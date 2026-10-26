# 215: Tess in her corner, tap / hold / drag / swipe up / double tap (round 3, Oct 23 12:45 PM PT)

Board: https://claude.ai/artifact/7g8r4LzjRV6LeHDxMJ5yiZ
Promised to him at 11:46 AM ("the whole interface of Tess, when I click on it or hold on it... separately"). Builds on 212 (corner, 80 pt band, no standing line) and the 213 light-ground fix. She is TessSoul as built; every state below is a SoulParameters row or a frame offset, never a new drawing.

## Gestures (on her 84 pt hit area)
1. **Tap: ask.** Dabs spread +35% (SoulParameters "listen"), scale 1.06, eyes turn to her line (left, slightly up). In her band: three suggestions above, written as plain words underlined in Tess cobalt (her voice; cobalt stays hers), plus the text field "Ask Tess" (caret in cobalt). Keyboard up. Her eyes follow the caret as text grows (x offset grows with length, capped). Tap anywhere else: she settles. Haptic: soft.
2. **Hold (≥0.35 s): talk.** Scale 1.25, dabs rotate around her centre with the voice level (main dabs one way, satellites the other way, faster), eyes look up at him. The transcript lands word by word in the 200 departure letter flips in ink2. Release sends; slide left more than 60 pt arms cancel (she shrinks back to 1.05 and looks left), and release then drops it. Speech is on-device (SpeechAnalyzer); nothing leaves the phone unless asksClaude. Haptic: .made at hold start, soft on send.
3. **Drag her onto anything: ask about this.** Moving more than 10 pt before the hold fires starts a drag. She leaves the corner at 0.78 scale and sits 44 pt above the finger. Her eyes lead in the direction of travel. The named thing under her thickens its underline from 1 to 3 pt; a plain thing gets ink. Drop: she answers about that object in her band, waits 1.3 s beside it, then springs home. A drop on nothing: she springs home. Every linkable object can be asked about (notices, the date, the one thing, app words, room items). Haptic: light tick on each new target, soft on drop.
4. **Swipe up from her (fast, upward >40 pt in under 0.26 s): her room.** It opens as a circle growing from her corner (a clip, not a sheet). It holds a "Watching today" line, then today's log: time column (Outfit 300, ink3) and one line each, with names as doors and Undo as a word (it reads "Reversed" after use; one op-log Undo). Swipe down or "Back to Home" closes it.
5. **Double tap: quiet for an hour.** Her eyes close (two soft curves), her breathing slows (period 6.4 s to 14 s), and the top lines stop rolling (212). She says "Quiet until 1:30 pm." once for 3 s. A tap wakes her: she blinks twice. Haptic: two soft taps.

## When she speaks first
Only when something changes: one line in her band for 6 s, in letter flips, with every name a door. Her eyes glance at the line while it shows. There is no standing line ever (212).

## Answers
At most 2 lines in her band (left 24 pt, right 104 pt, bottom 26 pt), Figtree 17. Names are doors in their app accent. No "...". Private things are named by their shownLabel ("a private note"). No money amounts on Home. Money actions are never offered to Claude. Health, calendar and body text are never sent.

## Accessibility
- VoiceOver: Tess is one button with the actions Ask, Talk, Open her room and Quiet for an hour. Every named object gets the custom action "Ask Tess about this" in place of the drag.
- Reduce Motion: no flight. She is simply at the target, then back in the corner. No dab rotation; level shows as scale only. The room opens as a plain swap. Flips become plain text.
- Dynamic Type: her band grows upward. Content above already reserves 112 pt.

## Motion
All of it goes through MotionPolicy: position spring (response 0.35, damping 0.8), scale and spread springs, the room clip 0.55 s.

## Owners
A (Tess layer: gestures, states, room). Core (SpeechAnalyzer path, "Ask about this" router taking an ObjectRef, room log from the op log).

## Reviewer guards (12:35 PM, via coordinator): required
1. The ask is a transient surface. Home has no standing field. The hold-to-talk letters clear after release.
2. Everything runs on the phone first. A question goes to Claude only when asksClaude is on, and only with context that is already allowed.
3. A drag onto a walled, private, money, health, body, calorie or calendar item answers on the phone only. Private items are named by shownLabel. Money actions are never offered.
4. Speech is on-device and has nothing to do with Siri.
5. Her room is Tess's surface, so private titles show as shownLabel there. Each action has one op-log Undo.
6. She never speaks unprompted from 11 PM to 7 AM.
7. Speech uses the on-device model only, with no server fallback. Audio is never kept or logged. If the model is not downloaded, she says so in one line and the Ask field opens instead.
8. Drag-ask is gated by class as well as by label. Walled, private, money, health, body, calorie and calendar objects are answered on the phone, even when masked. When asksClaude is off, every drop is answered on the phone.
9. Cobalt ruling (coordinator): all of Tess's text is in ink. Only her suggestion words carry a cobalt underline, because they are her voice. The caret stays cobalt too.

## Rev 2, 12:50 PM PT Oct 23 (his 12:37 and 12:38 PM)
### A. Her own layer (build)
- Tap or hold opens Tess's layer over Home. Home is blurred under it: about 18 pt blur, saturation 1.15, and a 52% tint of the page colour. This is the one place blur is used, and it belongs to Tess. In and out take 0.38 s through MotionPolicy. With Reduce Transparency, Home is instead covered by the page colour at 92%.
- Tess moves to the bottom middle of the screen, 112 pt above the bottom edge, at 1.7x. Exception: during a hold she stays under the finger at 1.3x until release, then moves to the bottom middle.
- The layer has five parts, top to bottom:
  1. A state line in ink3, 15 pt: "Ask me, or hold me to talk", "Listening. Slide left to let it go", or "Let go to drop it".
  2. What he says or types, in Figtree Light 30, ink. Spoken words land word by word in departure flips.
  3. Her answer, Figtree 20, at most 3 lines, with names as doors.
  4. Her offers in three rows, each with a label in ink3 and plain words underlined in cobalt:
     - Now: What's next, Start Push day, Log a set
     - Add: To groceries, A task, A note
     - Ask about: up to 3 things on screen
     The rows hide while she answers and come back 1.6 s after.
  5. The "Type to Tess" field, with a hairline under it and a cobalt caret.
- To close: tap the blurred Home, swipe down, tap her, or press Escape.
- Drag, swipe up and double tap keep their rev 1 behavior. A drag answers in the corner band and does not open the layer.
- VoiceOver: the layer is a dialog that takes focus, and its first element is the state line.
- All reviewer guards 1-9 apply. When the layer closes, its text is cleared.

### B. Her colors (rev 3, 12:48 PM; the wet-paint body was REJECTED by him at 12:43 PM: "Ew... super ugly")
He wants her earlier soft, glowing look, but blended and continuous rather than made of blobs. Proposal, waiting on his OK:
- The same soft glowing body as built. The core is solid to 55% of the radius, then a wide feathered edge like her current blur. The outline breathes gently, with lobes of ±4%.
- There are no separate dabs. One continuous color ramp runs across her: cobalt, then violet, then vermilion, then orange, then gold. The ramp is built in OKLCh, and the hue takes the long way round through violet and red, so it never passes through green or grey. Chroma eases 20% in the violet stretch so it never turns hot pink.
- The ramp's direction turns slowly (0.16 rad/s, faster while she talks). A faint drift curves the bands.
- Paints by ground: light D2502F / 3561C8 / E0A21E; dark and black FF5B3A / 5E8BFF / FFC23D. One normal blend on every ground. Alpha is 0.88 on light and 0.92 on dark.
- The eyes and every SoulParameters mood are unchanged.
- Build: a SwiftUI shader (.colorEffect) or a precomputed ramp texture drawn through a radial mask. The reference is makeSoul() in the board source.

## Rev 4, 1:00 PM PT Oct 23 (his 12:47 and 12:48 PM)
### A. Offers (build; replaces the rev 2 offer rows and guard 9's underline)
He didn't like the underlined rows and asked for something better organized and more elegant.
- Each group has its label in ink3 at 14 pt, in a 76 pt column.
- The offers form a vertical list. Each line is the offer in ink at 19 pt, with a hint beside it in ink3 at 14 pt (for example, "Log a set" with "bench, set 4"). If the hint doesn't fit, it wraps under the offer. Nothing is ever truncated.
- There are no underlines anywhere. Groups are 22 pt apart and lines 9 pt apart.
- Cobalt shows up only as the caret and for a moment when he picks an offer: the word turns cobalt for 0.22 s before she acts. This replaces the "cobalt underline on suggestions" part of guard 9. Everything else of hers stays in ink.
- The Type to Tess field stays at the bottom of the layer even while the offers are hidden.
- Her focus size drops from 1.7x to 1.35x. During a hold she is 1.2x, and 1.5x when she is already in focus.
### B. Her colors (rev 4; still waiting on his OK, do not build)
He said rev 3 had too much blending, was too round, and had a circle around it. The size range was also too big.
- **The circle.** It came from her glow being clipped at the edge of her canvas. Her alpha now reaches zero well inside the canvas. Build note: the alpha must reach 0 inside the drawn bounds.
- **Colors.**
  - Vermilion sits near her middle.
  - Cobalt and gold drift around it as wide soft fields (sigma 0.42R).
  - The colors mix as straight OKLab overlaps with chroma held up to 1.3x, so you see three colors, not a rainbow.
- **Shape.**
  - The outline has a ±9% oval term and slow noise.
  - Three reaches stretch out in different directions by 2-22% and come back, each on its own clock.
- **Breathing.** It now runs 0.88-1.04 (was about 0.94-1.06 plus a bigger focus size). A voice adds up to 8%.
- **Reference.** makeSoul() in board v4.

## Rev 5, 1:05 PM PT Oct 23 (his 12:53 and 12:55 PM)
### A. Her layer is one running conversation (build; replaces the rev 4 offer list)
He said there were too many presets. When he opens Tess, it should always be a contextual conversation between the two of them, keeping context over time.
- **Layout.** Top to bottom: the state line, then the conversation, then at most 3 replies, then the Type to Tess field.
- **The conversation.**
  - The earlier turns from today stay above, with quiet time markers ("Earlier, 11:08 am" in Outfit 300, 13 pt, ink3).
  - His older lines are ink3 and hers are ink2, both at 16 pt.
  - The newest exchange is large: her line at 22 pt in ink, his at 17 pt in ink2.
  - While he holds to talk, his live words land at 28 pt Light in letter flips, then settle to 17 pt.
  - Up to 9 items are shown; older ones scroll away above.
- **Her opening.** Every opening starts with one line from her about what matters now, from on-device context. Example: "Push day is at 6:30. Stretch at 8 may run into it. Move it to 9?"
- **Replies.** Her line comes with at most 3 short replies: plain ink words at 17 pt, no underlines, no hints, no groups. A tapped reply flashes cobalt for 0.22 s, becomes his line, and she answers. "That's all" closes the layer.
- **Size.** Her focus size stays at 1.35x.
- **Privacy (his ask, 12:55 PM, overrides guard 1's "clears on close"; reviewer to confirm the rules).**
  - The conversation persists on the phone as Tess's conversation, under the TessMemory rules.
  - Private things are stored and shown by shownLabel only.
  - Money, health, body, calorie and calendar text is never stored in it.
  - It is never sent to Claude except as context allowed under asksClaude.
  - It is excluded from widgets, the Lock Screen and notices.
  - It is kept for 7 days by default, and he can clear it in her room.
  - Typed or spoken drafts that were never sent still clear on close.
### B. Her colors (rev 5; still waiting on his OK, do not build)
He said she still looked like a sun with a glow, sometimes flattened or squished; he wants an aura flowing around her.
- **No solid core and no rim.** Density falls off smoothly from her middle on a saturating curve (alpha = 1 − e^(−2.6·density)), so there is no plateau. A slow inner flow thickens and thins her.
- **Aura.** Faint wisps circle her near her edge, each drifting on its own. The aura flows around her and never deforms her body. Her body stays round and is never squished.
- **Colors.** The same three soft fields: vermilion in the middle, with cobalt and gold drifting around it.
- **Canvas.** All alpha reaches 0 well inside her canvas, so there is no ring.
- Reference: makeSoul() in board v5.

## Rev 6, 1:10 PM PT Oct 23 (his 12:58 PM: "Tess itself doesn't feel very lifelike")
### C. Life (build with the layer; it applies to whichever body ships)
- **Glances, not sine wander.** Her eyes jump to a new target every 0.7-2.8 s with a fast spring (k 0.34) and then hold.
  - 55% of glances are small looks around her.
  - 27% are a look toward something on the page (the date, the one thing, the mosaic, her line).
  - 18% are a look back at him, held for 2.6 s.
- **Blinks.** A blink lasts 130 ms and comes every 2.4-6.6 s; 18% are doubles. A gaze shift carries a blink 30% of the time.
- **Lean.** Her body leans after her eyes (0.45x of the eye offset), so her eyes lead.
- **Breath.** Uneven: 1 + 0.022 sin(1.05t) + 0.014 sin(0.37t + 2). She also floats 1.1 pt up and down.
- **Attention.** While a finger hovers or drags nearby, her eyes follow it (on a pointer device; on the phone, during a drag).
- **Reactions.**
  - Touch: her eyes widen 1.2x for 320 ms and she takes a small breath (+6%).
  - Before each line: an inhale (+6%, decaying).
  - After she completes something for him: her eyes become soft smiling arcs for 1.1 s.
- **Eyes.** 1.3x larger than before, in proportion to her body.
- **Reduce Motion.** No glances, breath or float. Blinks and reactions show as plain state swaps.

### B. Her form (rev 7, 1:12 PM; his 1:05 PM: "color is okay, the shape or form still needs work, something is missing")
The colors stay as rev 5. The form changes:
- She is a soft but readable body with a little weight. She is slightly fuller below (+5% at the bottom) and a touch narrower at the sides. Her outline moves on two slow low modes (2θ at ±3.5% and 3θ at ±2.8%) plus faint noise, so she is never a perfect circle and never squished.
- Her edge is a short soft feather: a sine ramp over 16% of her radius, replacing the wide blur.
- Her aura is separate from her body. It is a faint glow just outside her (0.2) with wisps drifting around it (0.4 at peak, at 1.18R). Alpha reaches 0 well inside her bounds.
- A hint of volume: L is +0.04 above and −0.03 below inside her body. There is never a highlight or a specular point.
- Reference: makeSoul() in board v8. This is still waiting on his OK before any build.

### B. Her form (rev 8, 1:15 PM; his 1:08 PM: "something like a cloud, but still kind of spherical... edges moving around... a whole gaseous thing... no boundary, it fades into the whole")
This replaces rev 7's readable body and feather edge.
- She is a cloud of colored gas, spherical overall, with no boundary. Density is exp(−0.95 r²).
- Turbulence grows from 0.25R outward and is modulated ±105% at her outside. It comes from three octaves of value noise (0.6, 0.32, 0.08) on coordinates that turn slowly (0.05 rad/s) and drift outward, warped once. So her edges drift, curl and fade into the page.
- Alpha is 1 − e^(−3.1·density), minus 0.02. It reaches 0 well inside her bounds.
- The colors are as in rev 5, with a faint vertical shade. Life (§C) and the eyes are unchanged.
- In the app this wants a Metal shader (layerEffect), about 112² at 30 fps, or precomputed noise textures that scroll. Reference: makeSoul() in board v9.
- Still a proposal: wait for his OK before building.

### B. Her form (rev 9, 1:18 PM; his 1:10 PM: the texture must be uniform, with no patches; replaces rev 8's turbulence)
- She is a cloud with one smooth, even texture and no noise inside. Density is exp(−0.95·r^2.2), and alpha is 1 − e^(−3.1·density), minus 0.02. She has no boundary.
- Only her edge moves: her fade distance changes with direction on smooth low waves, 1 + 0.045 sin(2θ + 0.42t) + 0.03 sin(3θ − 0.33t) + 0.035 sin(θ − 0.19t). She stays round and is never squished.
- Colors: vermilion near her middle (weight 1.15), with cobalt and gold at 0.78R drifting around it. The fields have sigma 0.62R and mix in OKLab, holding chroma up to 1.3x.
- Reference: makeSoul() in board v10. Still waiting on his OK.

## Rev 10 (Oct 23, 1:35 PM PT, Design round 5): how the conversation opens

Board: https://claude.ai/artifact/7g8r4LzjRV6LeHDxMJ5yiZ (v11). This extends §A and is part of the build. It does not depend on the §B form proposal.

**D1. Her opening line picks up from what changed.**
- When the layer opens, Tess compares the objects named in her last turn against the op log since that turn.
- If one of those objects changed, she opens with that change, saying "Since then, …". For example: "Since then, Push day moved to 6:30. Stretch at 8 may run into it. Move it to 9?"
- If nothing she last named has changed, she opens with the newest thing that needs him today. Today's notices source decides what that is.
- She never repeats a line she already said in this conversation, and never contradicts one. If an earlier line no longer holds, she says what changed; she never says it as if it were new.
- Privacy is unchanged: the comparison runs on-device, using shownLabel names only.

**D2. Time markers are quiet.**
- A marker uses Outfit ExtraLight (200) at 12 pt in ink3, with 0.06 em tracking. It has 10 pt extra space above it, and none when it is the first item.
- It shows only the clock time, such as "12:31 pm", with no "Earlier" before it.
- A marker appears only when 20 min or more pass between turns.
- When she opens after a gap like that, the marker reads "Now, 1:31 pm". It is the only marker that carries a word.

**D3. A small detail: the echo.**
- When her new line names a thing already named higher up in the conversation, the latest earlier mention of that word does one departure letter flip after her line has finished.
- The flip runs at 38 ms per letter, and each further word starts 160 ms after the one before it.
- It ties the new line to the old one without any line or arrow.
- With Reduce Motion on, there is no flip. Instead, the earlier word brightens to ink for 0.9 s.
- It runs once per line and only in the layer: never on Home, the band, widgets or the Lock Screen.

## Rev 11 (Oct 23, 1:45 PM PT): the cloud form OK'd, with color spread evenly

At 1:35 PM Kaushik OK'd the §B rev 9 cloud ("yeah, now I need color to be a little bit better spread"). The form is now part of the build. Board: https://claude.ai/artifact/7g8r4LzjRV6LeHDxMJ5yiZ (v12).

The color change replaces the rev 9 color points:
- She has three color fields, placed a third of a turn apart (2.094 rad). They turn together at the body angle (0.6 + 0.16·t), and each also sways ±0.35 rad on its own slow sine.
- Vermilion sits at 0.40R and has weight 1.08, so she stays warm. Cobalt and gold sit at 0.56R with weight 1.
- Each radius breathes ±0.08R.
- Every field uses sigma 0.63R, with straight OKLab mixing. The chroma kept from the paints rises from 1.3x to 1.5x so the overlaps don't go muddy.
- No color owns her middle, and every color reaches the center region at some point in the turn.
- Form, alpha and the edge waves are unchanged from rev 9.

## Rev 12 (Oct 23, 1:50 PM PT): a little abstraction

At 1:45 PM Kaushik said "getting there, a little bit of abstraction maybe". This replaces how the Rev 11 colors meet; everything else is unchanged. Board v13.

Her color is now looked up at warped coordinates rather than at the pixel itself:
- wu = u + 0.55R·sin(2·v/R + 0.21t) + 0.18R·sin(1.4·(u+v)/R − 0.13t)
- wv = v + 0.55R·sin(1.8·u/R − 0.17t + 2)

The color fields are evaluated at (wu, wv), so the lines where her colors meet curve and drift like slow brush sweeps rather than straight slices.

The warp applies to color only. Alpha, form and the edge waves still use the true radius, and the waves are wider than she is, so her texture stays uniform. There is no new detail at small scale.

## Rev 13 (Oct 23, 1:57 PM PT): a slightly softer blend

At 1:54 PM Kaushik said "better but a slightly better blend maybe".
- Each color field's sigma goes from 0.63R to 0.70R.
- The chroma kept rises from 1.5x to 1.6x, so the softer overlaps stay clean rather than muddy.
- Everything else is as in Rev 12. Board v14.

## Rev 14 (Oct 23, 2:02 PM PT): slightly smaller, more blend, random bursts

At 1:56 PM Kaushik asked for "a slightly smaller one and a little more with the blend and burst of colors randomly". Board v15.

- **Size:** R goes from 0.19 to 0.175, about 8% smaller. The breathing range is unchanged.
- **Blend:** field sigma goes from 0.70R to 0.76R, and the chroma kept from 1.6x to 1.7x.
- **Bursts:**
  - At a random moment, one of her three colors (chosen at random) swells out from a random point inside her, within 0.45R of her middle, then eases back.
  - Its center moves 55% of the way toward that point, its weight rises by up to 2.3x, and its sigma grows by 0.18R. The envelope is sin²(π·u) over 1.4 to 2.2 s.
  - The gap between bursts is 2.2 to 5.7 s at random; while she is quiet, it is 5 to 11 s.
  - Reduce Motion: no bursts.
  - Alpha and form are untouched, so her texture stays uniform.

## Rev 15 (Oct 23, 1:58 PM PT): smaller still

At 1:57 PM Kaushik said "getting better, now a little smaller still". R goes from 0.175 to 0.16, about 9% smaller. Everything else is as in Rev 14. Board v16.

## Rev 16 (Oct 23, 2:10 PM PT): her opening, her reactions, and her voice

At 1:58 PM Kaushik asked for "opening animation and reactions and so on from Tess". At 1:59 PM he added: "I don't need departure style text always. For conversation we can remove that, and the text beside Tess too can be in a different font." Board v17.

**E1. Reactions are made of her cloud.** Each one is a short envelope on her reach, her position, or one color burst. None of them changes her texture. Reduce Motion turns them all off; her eyes still react.
- **Opening** (tap):
  - A gather first: her reach shrinks 13% over 140 ms, like an inhale.
  - Then a bloom: her reach grows by up to 26% with a smoothstep rise, decaying as exp(−3.2·s).
  - Vermilion bursts from her middle for 1.8 s while she travels to her spot.
- **Closing:** a small exhale, with a bloom of 0.45 shaped sin(π·u) over 320 ms, as she glides home.
- **Thinking** (between his reply and her line): her colors turn faster, adding 0.045 rad per frame.
- **Done** (she completed something): a 4 pt hop over 420 ms, a 0.35 bloom, a gold burst from her middle, and her happy eyes.
- **No** ("Keep it at 8"): a 2.4 pt nod down and back over 360 ms.
- **Touch:**
  - She draws in a little, a 0.6 gather over 220 ms.
  - Gold swells from the side his finger is on.
  - Her eyes widen, as in §C.

**E2. No letter flips in conversation.** Departure flips stay on Home's top lines only.
- Her words, in both the layer and the line beside her on Home, arrive one word at a time: 62 ms per word, plus 40 ms after punctuation.
- Each word settles with a 3 pt rise over 180 ms. There is no fade and no blur.
- Live speech shows each heard word at once.
- The echo (Rev 10 D3) no longer flips. The earlier word brightens to ink for 0.9 s.

**E3. Her voice has its own typeface.**
- Tess speaks in Newsreader: a gentle text serif, regular weight, with optical size on. In the app this is New York, Apple's system serif. If Newsreader can't be bundled, use New York.
- Her line beside her on Home is 18 pt. In the layer, her older lines are 17 pt and her newest is 23 pt. Linked words are weight 500 and never break.
- His words stay in Figtree, so the two voices read apart at a glance.
- Numbers and times stay in Outfit.
- This applies only to Tess. Every other line in the app is unchanged.

## Rev 17 (Oct 23, 2:08 PM PT): her mouth

At 2:03 PM Kaushik asked for "a mouth too, like a line, which would be more expressive. Not always visible necessarily but sometimes depending on the situation." This overrides the motion lab's "mouth default off" setting; "never a frown" still holds. Board v18.

**The line**
- One fine line, 1.05 pt at her 1.3x face scale, in the same ink as her eyes.
- It sits 2.6 pt below her center and follows her gaze at 0.5x.
- It draws out from its middle and back in, with a spring of 0.22 and no fade.
- It changes shape only once it is almost fully drawn back in, so two expressions never morph into each other.

**Its shapes**
- **Speaking** (while her words arrive): a small filled curve that opens and closes, driven by |sin(11.5t)·sin(4.3t+1)|, 2.6 pt half-width.
- **Done:** a smile curve, 3.4 pt half-width, together with her happy eyes.
- **Thinking:** a short line, 1.7 pt half-width, pulled 1.2 pt to one side and tilted slightly.
- **Touch:** a small round "oh" for 320 ms, together with her wide eyes.
- **No** (nod): a short flat line for 0.5 s.

**When it hides**
- At rest, while listening, and while quiet, she has no mouth.
- It never shows a frown.
- With Reduce Motion on, it snaps in and out and holds still while she speaks.

## Rev 18 (Oct 23, 2:12 PM PT): richer colors on light grounds (for his review)

At 2:06 PM Kaushik said "in case of lighter backgrounds, Tess should look in better colors". This applies to the light looks only (White, Paper, and System in light); dark grounds are unchanged. Board v19: flip to White or Paper to review. Status: proposed, waiting on his OK.
- **Light paints:** vermilion E8461F (was D2502F), cobalt 2D5BE3 (was 3561C8), gold F2A00F (was E0A21E).
- **Density:** her alpha curve on light grounds is 1 − exp(−3.7·dens) (was 3.1), so her middle reads as solid color rather than a pastel wash.
- **Peak alpha:** 242 out of 255 (was 225).
- **Chroma:** up to 1.9x on light (dark stays 1.7x).
- **Result:** her colors read clearly on white, with no muddy pink-brown. Her edge still fades to nothing.

## Rev 19 (Oct 23, 2:25 PM PT): close palettes, tone by moment, hearing, a meaningful mouth, Shift-Enter

These answer Kaushik's 2:12 to 2:18 PM messages. Board v20; the new board rows are "Her colors" and "Her tone".

**F1. Close palettes** (PROPOSAL, he picks). At 2:16 PM he said red and blue fight, and that two or three close tones are better. Each palette is [her middle, one side, the other side], light / dark:
- **Lagoon** (recommended, since it keeps her cobalt identity):
  - Light: 1F78F0, 2E4FE6, 10B2AE.
  - Dark: 4F9CFF, 5E7FFF, 33BFC0.
- **Dusk:**
  - Light: 4A4FE2, 2E5CFF, 7B48DC.
  - Dark: 7A7CFF, 5E8BFF, A580FF.
- **Ember:**
  - Light: FF5A26, E5341C, FFA90F.
  - Dark: FF6B3D, FF4A33, FFC23D.
- **Before:** the old three tones, kept for comparison.

Close tones mix in plain OKLab, with chroma kept up to 1.25x. "Before" mixes along a path through deep violet and amber (cobalt, violet, vermilion, amber, gold) so it never goes pink or grey.

**F2. Richer on light grounds** (2:06 and 2:12 PM).
- On light grounds her alpha curve is 1 − exp(−4.6·dens), with peak alpha 242.
- Where she thins out over white, her chroma rises to 1.45x and her lightness drops 0.025, so faint parts stay colored instead of pastel.

**F3. Tone by moment** (2:18 PM: decide when to be brighter, lighter or duller). Each tone is a lightness shift and a chroma scale, applied after mixing:

| Tone | Lightness | Chroma | When |
|---|---|---|---|
| Bright | +0.02 | 1.12x | Answering or thinking: she has something for you |
| Light | +0.05 | 0.90x | Listening, and mornings before 10 AM |
| Full | 0 | 1.00x | The day, 10 AM to 5 PM |
| Evening | −0.02 | 0.85x | 5 to 9 PM |
| Night | −0.06 | 0.62x | After 9 PM |
| Quiet | −0.05 | 0.55x | When he has asked her to be quiet |

Tones ease over the same spring as her body.

**F4. Hearing** (2:15 PM), while he holds to talk:
- His voice level runs round her edge as small travelling waves: reach + level × (0.05·sin(3θ − 6.2t) + 0.028·sin(5θ + 4.4t + 1)).
- She catches each heard word with a small gather of 0.28 over 140 ms.
- She leans 1.6 pt toward him.
- She has no mouth while listening.
- Reduce Motion: no waves and no lean.

**F5. A mouth that means something** (replaces Rev 17; at 2:12 PM he said the moving mouth was not useful). It has three meanings and is gone otherwise:
- **Smile:** she did what you asked. It lasts as long as her happy eyes.
- **Slant:** she is waiting on you. Her last line is a question and its replies are showing.
- **"Oh":** something new arrived beside her on Home, shown for 1.4 s.

There is no lip sync, no mouth while she speaks or listens, and never a frown.

**F6. Typing:** the field is multi-line. Enter sends, Shift-Enter adds a new line, and the field grows to 120 pt, then scrolls. On the phone, the keyboard's return key adds a line and a send arrow sends.

### Rev 19 reviewer conditions (coordinator relay, 2:20 PM): passed, and the reviewer also recommends Lagoon
- **ΔE rule:** if Lagoon is picked, nothing else in the app may sit within ΔE 10 of its cobalt, azure or teal. Before build, re-check the 214 beach, lake and night-sky tiles and the app accents (AppAccents.swift), and shift any that collide.
- **Bursts:** they are already palette-relative. Open bursts her middle color (index 0); Done and Touch burst her far side (index 2). With Lagoon, that means azure on Open and teal on Done and Touch. No vermilion or gold remains in any palette except Ember.
- **The slant** (waiting on him) is a straight line rising 0.5 pt to the right. It never curves down at the ends, so it never reads as a frown.
- **Contrast:** her eyes and mouth must reach 3:1 against her color beneath them in all six tones on White and on Black. The board's eye ink measures at least 4:1 on her darkest Night tone. Builder A must check this in the build and darken the eye ink to #111 if any pair fails.

## Rev 20 (Oct 23, 2:28 PM PT): Ember, cued by the page, decided by TessDirector (BUILD)

Kaushik's messages, 2:21 to 2:22 PM:
- "Ember is so far the best", because it goes with the accent on the page.
- She is allowed to mix two colors, and sometimes to transition between them.
- The tone is too subtle and not needed.
- "Take a few cues from those things... if there is nothing, I don't want you to take a mix of everything."
- Build it as if Tess takes these calls, not at random or by fixed rules.

Board v21. The new board row "Page accent (her cue)" previews the cues.

- **G1. Ember is her base.**
  - Light: FF5A26, E5341C, FFA90F.
  - Dark: FF6B3D, FF4A33, FFC23D.
  - Lagoon, Dusk and Before are dropped as defaults. F3 tone (Rev 19) is REMOVED.
- **G2. The page cue.** When a screen has one clear accent (an app's room uses its AppAccents color), she takes a close palette made from it:
  - Her middle is the accent at L 0.64 on light grounds or L 0.74 on dark, with chroma at least 0.15.
  - Her sides are ±18° of hue, at L −0.05 and +0.05.
  - Home, or any screen with several accents, keeps Ember. She never averages accents.
- **G3. The glide.** Changing palettes takes 1.2 s with a smoothstep. Hue turns the short way in OKLCH and chroma is interpolated, so she never passes through grey. A small catch (gather 0.28) marks the change. Reduce Motion: an instant switch.
- **G4. Decided by TessDirector.**
  - Her palette is `TessDirector.decide(.tessPalette(pageAccent), context)`, which returns the cue (or none) and a why. Her bursts are `.tessBurst` through the same seam.
  - RuleDirector implements G2 today; a ModelDirector can replace it later. The walls and clamps apply after the decision, as in Core.
  - The decision sees only the screen kind, its accent and her state, never screen text or private content.
- Rev 19 F2 light-ground richness, F4 hearing, F5 mouth and F6 Shift-Enter stand.
- Reviewer ΔE: no app accent may sit within ΔE 10 of her Ember middle unless that app's room cues her. Training (C4472A) is close to Ember by design, which is fine because Training cues her anyway.

## Rev 21 (Oct 23, 2:26 PM PT): 30% smaller (BUILD)
At 2:25 PM Kaushik asked for Tess to be "maybe 30% smaller, on the phone or as seen on the design page. Otherwise everything as close to the design sheets as possible."
- Her whole drawing is scaled by 0.7, including her cloud, eyes and mouth. Her breathing, bloom and hop ranges scale with it.
- Her touch target stays 84 pt, so she is still easy to hit.
- Board v22.
