# 258 Training blackboard in the page; Kitchen sink and ticket rail, with Dishes (v1, Oct 25; not yet reviewed)

Board: https://claude.ai/artifact/RTMonbdXvyVWjQWnYcYXeP (file `kitchen-training-258/board.html`). From his verdicts on 257: the
chalkboard idea stays but must look like a blackboard and be integrated into the background, writings included; the
window is out; add Dishes as a frequent thing.

## Training: the blackboard, integrated
- No slab in a slot. A canvas under the page type: between y 180 and 420 the page's own ground goes to slate, and
  the edge is a FEATHER OF CHALK DUST about 36 pt deep built from two octaves of noise (not a gradient), plus loose
  dust grains along it. No rounded rect, hairline or shadow. On Black the slate is a shade above the page and the
  dust is what shows; on Paper it is a dark band with a soft, dusty edge.
- Everything the landing says there is in chalk (Caveat, soft wide stroke under a crisp one, grain knocked out).
  The two facts that were type (5 weeks on plan, +10 on bench) are now on the board. Chalk is masked to the slate.
- Three ways to fill it, a switch under the phone ("What it says"):
  Plan: "Push A at 6:30, bench first" large, the detail line, the week's days M to S with chalk ticks on done
  days, the two facts, the bests small along the bottom.
  Record: the bests large with lift names, the streak as five tally strokes, today's tally, the bench gain.
  Coach: one sentence in Tess's hand ("Bench opens at 185 tonight. Last time, three fives. Go for 190 on the last
  set."), the week ticked, "Tess" signed small.
- Life and reactions as 257: a set leaves a handprint and dust and ticks today; a best strikes the old number and
  writes the new one larger; marks fade (90 s = a week on the board); "New week" wipes a band. Tap the board to open
  the lift under the finger.
- Open: how dark on Paper (recommend keeping it dark with the deeper feather); which fill (recommend Plan by
  default, Coach when Tess has something, Record on the This week page).

## Kitchen A: the sink
- The keystone is the kitchen sink set into the counter (the page), with the approved soft light and shadow as its
  rim. Brushed steel, a drain, a tap.
- Dishes pile up as you cook and eat: plates, bowls, mugs, a pot (crockery only, nothing edible), stacked with a
  little tilt. Breakfast adds two, dinner five. Tess keeps the count in the brief sentence ("Seven dishes since
  lunch.") and the foot word reads "Dishes 7".
- Idle life: the tap drips every 4 to 7 s with a ring; a bubble pops now and then.
- Do the dishes: swipe right across the sink, or the Dishes word: the tap runs 6 s, water rises with 60 suds, the
  dishes leave one by one (0.35 s apart) to the rack at the right, the water drains. Receipt "Dishes, done." with
  Undo 10 s. The count resets and grows again with meals.

## Kitchen B: the ticket rail (the pass)
- A steel rail across the top of the slot with paper tickets clipped to it, in Tess's hand, each the kitchen's own
  ask: Tacos, 25 min, tonight (clay). Get limes, cilantro, tortillas (lists olive). Rice goes out today (wine).
  Dishes, seven waiting (money teal, as the chore color). Tess's notes (blue).
- Tickets flutter in the hood's draft, harder while cooking (faint draft lines cross the slot). Spike: swipe a
  ticket up and it rises onto the spike at the right and fades; the rest slide left on a spring. New: a ticket
  slides in from beyond the right edge. Tap a ticket to open its thing.
- Dishes is a ticket; it spikes when the dishes are done.

## Dishes, everywhere in Kitchen
A first-class frequent thing: a word at the foot beside Cook, a swipe on the sink, a ticket on the rail, a count in
the brief. Done = receipt with Undo; the count grows again with meals.

## Recommendation
The sink as the Kitchen keystone (the one living thing you look at every day, and it carries Dishes by nature); the
rail's tickets as the grammar for Tess's kitchen notes on the Tonight page.

## Verdict (Kaushik, Oct 25): TRAINING BLACKBOARD LOCKED as the direction
"I'm liking the idea of this. I'm down with this." Needs a lot of work later: haptics, how we interact with it,
texture, integration into the page, the font itself, what we present, how it reacts to different things, and colors.
He is looking at the two Kitchen keystones meanwhile. v2 below makes a first pass at texture, integration, font and
interaction.

## v2 of the blackboard (Oct 25, after the lock; same board link; v1 kept as `kitchen-training-258/board-v1.html`)
First pass at what he named:
- Texture: the slate is a precomputed texture: uneven darkness from three octaves of noise, fine grain, a soft light
  from the top-left, and seven faint ghosts of wiped chalk (wide blurred smears). Rebuilt per look.
- Integration: the dust feather is 44 pt deep (three octaves of noise, not a gradient), with loose dust grains along
  both edges and a sprinkle that has settled on the page below the board.
- Hand: five chalk hands to compare under the phone (Caveat, Reenie Beanie, Gloria Hallelujah, Shadows Into Light,
  Architects Daughter). Chalk is drawn in two passes with a hair of jitter, a soft wide stroke under, grain knocked
  out, so it sits in the slate rather than on it. Recommendation: Reenie Beanie for chalk (thin, uneven, honest) with
  Caveat as the fallback; decide after seeing them on a phone.
- Interaction: drag on the board writes in chalk (your strokes fade like everything else); a fast swipe left is the
  towel and wipes that band with a puff of dust; a still tap on a number wobbles it and opens the lift; tap the top
  line to open today's workout. Scroll of the page must start outside the board (the board owns drags that start on
  it, like the mosaic).
- Haptics spec (for the build): writing = continuous soft texture every 6 pt of travel; tally stroke = one light
  tick; handprint = a soft thud; new best = a rigid tap then three quick ticks with the dust; towel = a long soft sweep;
  tap a number = a selection tick; Monday wipe = none. Reduce Motion keeps the taps, drops the texture.
- Still later: colors (chalk is near-white; colored chalk for splits, Push clay, Pull teal, Legs plum, is the obvious
  next step and would follow sheet 241), what exactly is written (Plan by default is the recommendation), and the
  reactions to everything else in Training (a skipped day, a rest week, a program change).

## Verdict on Kitchen (Kaushik, Oct 25): THE TICKET RAIL (the pass) is the Kitchen keystone. Sink rejected ("stupid").
His spec, kept close to his words; continued and built in sheet 259:
- "It's a brilliant one, and we're going to make a lot of changes on top of this, but the idea is there."
- The number of tickets is DYNAMIC: four, three, two, one, depending on how many we want to show and how many fit.
- For Recipes and Groceries the rail can show ONE BIG ticket, or two big ones: the ingredients a dish needs, the
  recipe itself. In COOKING MODE the rail runs the steps: it keeps a tally as they go, each step gets cut off (struck)
  as it is done, with announcements. "That's where we'll put the energy: how to render dynamically and very smoothly
  based on what is happening live. That's the beauty."
- MULTI-PAGE TICKETS: when one ticket has more than fits (Tacos, Get), swipe it UP and it flips over to the next
  page, a continuation; swipe DOWN pulls the page back. Finishing (done) needs some other gesture, to be decided.
- THE RAIL STAYS: this top part of the screen is always there in the Kitchen app. Opening Tonight, Pantry, Recipes or
  anything else uses only the bottom part of the screen; the top part stays LIVE to whatever the bottom is showing.
