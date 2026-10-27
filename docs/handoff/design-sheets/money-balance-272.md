# 272 Money keystone: the balance (v1, Oct 25; not yet reviewed)

## Why (his words on 271, the tiles)
"Not opposed... two major problems: there's no easy way to tell if I'm spending more or earning more, or what is taking
more, where things are going. And it's very close to the Mosaic home screen. I want things to be unique. Otherwise I
like the idea: these are the kind of animations and elements we want to build with."

## The idea
One hairline beam on a point. Left: what came in, as words (Salary, Side job). Right: where it went, one word per kind
(Home, Japan, Food, Going out, Body, Subscriptions), each set at the size of its amount (font size ~ sqrt, so area
follows money), stacked on the beam with the biggest at the bottom and the exact amount beside each word. The beam
tilts toward the heavier side (up to 18 degrees, on a damped spring), so "am I spending more than I earn" is the first
thing you see; the biggest word on the right is where most of it went.
- IN and OUT totals sit under the ends of the beam; STILL YOURS (or OVER BY) under the pivot.
- A payment falls onto the right as a small word, lands on its kind, the kind swells (spring), the beam dips. Pay
  falls onto the left. A new kind of spending (a laptop) arrives as a new word in the stack.
- Tap a kind: the others dim and its things hang under the beam on threads, each sized by amount.
- Last month: a dashed line at the angle last month ended on; "last N" under a kind when asked.
- Colours (sheet 241): in sage, Home clay, Food ochre, Body blue, Subscriptions teal, Going out slate, saving gold.
  The tilt and the sizes carry the judgement; no amount is coloured good or bad.

## Open
- The pile on the right gets tall when many kinds are active: cap at six words, the rest as "and 3 more" (small).
- Haptic: a soft tick when a drop lands, a heavier one when the beam crosses level.
- Tiles (271) kept as an inner page idea (the month in time order), not the keystone.
