# Item 220: Home gesture fixes for the final build (Oct 23, 3:52 PM PT)

Kaushik, 3:48 PM:
- In the apps list he wants to hold and scroll, and a swipe should still work, moving one row with the same effect.
- The one thing should swipe in all four directions.

Builds on 205 (apps scroller: 3 rows visible, 40 pt rows, snaps to the middle, wraps endlessly) and 213 section 4 (one thing).

## 1. Apps list: hold and scroll
- **Pick up:** touch and hold 180 ms without moving more than 6 pt. One soft haptic. The middle row eases to 1.06x over 120 ms, so he feels it is in his hand.
- **Scroll while held:** vertical drag tracks 1:1, so 40 pt of finger moves one row. Rows pass the middle continuously and the list wraps as before. Each time a row crosses the middle there is one selection tick, and the crossing row takes the pick style.
- **Release:** a spring snap to the nearest row (MotionPolicy firm, about 0.35 s, no overshoot past a row). No momentum: where the finger stops is where it lands.
- **Swipe (a flick with no hold):** moves exactly one row in the flick's direction, with the same snap and one tick. Swipe up shows the next row and swipe down the previous one. Flicks made during a snap queue, at most 3.
- **Tap:** a tap on the middle row opens the app, and a tap on another row moves it to the middle, as in 205.
- **No long press on this list.** Hold belongs to scrolling here, so this list has no detail sheet.
- **Reduce Motion:** the snap is a plain step and the 1.06x scale is dropped. Ticks stay.

## 2. One thing: swipe in four directions
- **Next:** swipe left or up. **Previous:** swipe right or down.
- The dominant axis wins. A swipe commits past 50 pt, or on a flick faster than 300 pt/s. Anything less springs back.
- Nothing moves during the drag (the 12:14 correction). The change happens in place with each kind's entrance, the same for all four directions.
- There is one light haptic per page.
- Hold to strike (Done) is unchanged.
- Vertical swipes work on the one-thing space only. The apps list keeps its own vertical gestures, and the mosaic keeps horizontal only.
- **Reduce Motion:** a plain swap.
