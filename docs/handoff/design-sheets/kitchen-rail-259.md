# 259 The Kitchen pass (v1, Oct 25; built from his spec, not yet reviewed)

Board: https://claude.ai/artifact/T1UHN2Rtak4TmZwbsfvHep (file `kitchen-rail-259/board.html`). The ticket rail (258 B) is the Kitchen
keystone, by his verdict. His spec is in `kitchen-training-258.md` (Verdict on Kitchen). This sheet is how it is built.

## The pass is permanent
- The band from 170 to 420 is the rail on EVERY Kitchen page. Below 450 is the page: the landing's doors, or
  Tonight, Pantry, Recipes, Groceries, Leftovers, or cook mode. Back is the edge swipe or the back word. The title,
  the day and the brief sentence stay above the rail. The rail never leaves.
- The rail is LIVE to the page below. Landing: the kitchen's asks (Tacos 2 pages, Get, Rice, Dishes). Tonight: one
  big Tacos ticket (ingredients front, the plan on the back). Recipes: two medium tickets (Tacos, Dal), each with its
  plan on page two. Groceries: one big Get ticket (nine a page, two pages) with Dishes small beside it. Pantry: a
  ticket per place with its count and the one thing to know. Leftovers: a ticket per thing with its day (wine when
  today) plus Dishes. Cook mode: the recipe ticket and the timer ticket.
- Changing page: tickets that stay keep their element and place (so a flipped page stays flipped); tickets that go
  slide up and fade (0.45 s); new ones slide in from beyond the right edge with a clip (0.55 s). Flex layout: a big
  ticket takes 2.4 shares, the others 1; so one big, two medium, or three or four small.

## Tickets
- Paper hung from a clip on the rail, torn edge at the foot, the kitchen hand (Caveat here; Reenie Beanie as the
  thin option), title in the thing's color (Tacos clay, Get lists olive, Rice wine, Dishes money teal, Pantry
  teal, Tess blue), a sub line, up to about nine lines on a big ticket and four on a small one.
- PAGES: swipe UP flips the ticket over on its clip (rotateX 180, 0.65 s) to the next page written on its back;
  swipe DOWN flips back. Page number bottom right ("1 / 2"). First and last page say so in the receipt line.
- Tap opens the ticket's thing below (Tacos to Tonight, Get to Groceries, Rice to Leftovers, a place to Pantry).
- A FAST swipe up (under 260 ms, more than 70 pt) spikes the ticket: it rises to the spike at the right and fades;
  the rest reflow. His "some other gesture" for finishing is still open: recommend HOLD-AND-TEAR (hold 0.5 s, the
  ticket loosens from the clip, let go and it tears onto the spike), keeping swipe up for pages.
- Life: each ticket flutters on its clip (slow sine, 3.4 to 5.4 s, random per ticket); harder while cooking.

## Cook mode (where the energy goes)
- Cook (foot word, or Cook Tacos): the rail becomes ONE BIG recipe ticket with the steps numbered, four a page,
  the current step bold, and the running tally bottom left ("2 of 5"); beside it a TIMER ticket counting down with
  a line on what is on ("chicken in the pan", "nearly there").
- Strike a step: tap it on the ticket, swipe right on the ticket, tap or swipe right the step in the page below,
  or the foot word "Next step". The step is struck on the ticket as it happens (strike line, hand ink) and the
  tally updates. When the visible steps are done the ticket FLIPS to its next page of steps by itself.
- Finishing (last step struck): the recipe ticket spikes, Dishes grows by five with a receipt and Undo, the rail
  returns to the landing set.
- Announcements: the timer ticket is where they land ("Rice, 2 min"); on the phone, the Live Activity mirrors it.

## Dishes
A ticket on the landing, Groceries and Leftovers, a word at the foot ("Dishes 7"), the count growing with meals
(dinner eaten +3, a cook +5). Done = fast swipe up on the ticket or the foot word; receipt with Undo.

## Open
- The finishing gesture (recommend hold-and-tear).
- Maximum tickets: four small is the comfortable limit; beyond that the rail itself should page sideways.
- The hand: Caveat vs Reenie Beanie, decide on a phone with the Training chalk.
- Haptics: a clip tick when a ticket lands; a paper flick on a flip; a tear on spike; a light tick per struck step.

## His correction (Oct 25): ONE SLOT SIZE EVERYWHERE
"Let's not increase the size. Whatever the size of the centerpiece is, it should be the same across all the apps,
Home and the others. That's why we flip." The keystone slot is fixed: 354 x 182 pt at top 196 (the Home mosaic's
slot, as in 248). The pass lives inside it on every Kitchen page; tickets never grow the band. More content means
more PAGES on a ticket (flip up / flip down), never a taller rail. The flip animation itself is to be designed later;
the behavior is the spec. v2 of the board fits the rail into the standard slot (tickets about 160 pt tall, a big
ticket holds about six lines, a small one three; the rest goes to the next page).
