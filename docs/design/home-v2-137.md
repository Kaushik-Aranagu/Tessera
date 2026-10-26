# Item 137: Home v2 and the app edges, build sheet (Oct 22)

Builds sheet 136 A and B. Review switch "Home v2" (default Off; Off = Home as today,
REVIEW / TODAY / TRAINING). Depends on 135 part 1 (day sentence). Builder B owns Home;
Builder A owns the fan and edge motion. Keep every element feature (131 2b).

## 1. The page (one page, no x pager)
```
 Thursday, Oct 22                                  <- label, ink 2
 [Now block, only while a process runs: as today's Now, Resume / Pick up / Go on]
 Push A at 6:15, about 45 min. Tacos tonight,       <- day sentence (135 part 1),
 start at 6:05. Rent is due Friday.                    title role, accents on key words
 Next                                               <- label
 Call the dentist                                   <- HomeQueue rows, max 3, same swipes:
 Send the trip plan to Sam                             right finish, left not now
 Water the plants                                      third row ink 2
 Write or say anything                              <- the write line (135 part 5)
 ===== edges =====                                  <- 6 strokes, bottom edge
```
- Vertical scroll only if AX sizes need it; at default it fits one screen.
- REVIEW moves to a door word in the Now-less top line's right ("Review" ink 2) and the
  day stroke lives on the Review page. TRAINING page retires (Training is an app now).
- Tess's corner and band unchanged; the edges sit under the band, full width, edge to edge
  (they are the one thing allowed past the gutter, like a page edge).

## 2. The edges
- Six strokes, 3 pt each, 3 pt apart, in app order Training, Kitchen, Money, Notes, Lists,
  Routines (Tasks joins as an ink stroke when it ships), each Theme.Colors.restTint(accent).
- An app with something new or running: its stroke at full accent for 2 s on arrival,
  then dries back to rest (Theme.Motion.dry). No badges, no counts.
- Tap on the edges opens the app whose stroke is nearest the touch (the edge group
  gets a 44 pt tall hit area; each stroke owns the band of it nearest to it).
- Private: nothing about an app's contents shows on its stroke.

## 3. The fan (pull up the edges)
- Drag up from the edges past 24 pt: the page above dims to ink 3 and the six app titles
  rise from the edges in reverse stack order (Routines top), 30 pt title role, each with
  its live line on the right in ink 2 (AreaIndex live lines, 6 words / 32 chars, no stop).
- The title under the finger grows to 40 pt in its accent; others stay ink at 38%.
  Selection tick per change. Let go: that title flies to the landing title position
  (matched geometry, house spring) and the landing builds under it. Let go below the first
  title or drag back down: closes, nothing opens.
- Timing: each title rises 35 ms after the one below (Theme.Motion.stagger), house spring.
  Reduce Motion: the list appears at once, crossfade 150 ms.
- VoiceOver: the edges are one element "Apps", activate opens the area index list.
- AX sizes: titles at label size + live line under each title, scrolls if needed.

## 4. Swipe across apps
- Inside any app landing: a swipe from the right screen edge goes to the next app in edge
  order, the left edge to the previous (the system back swipe stays on the left edge when
  the page is deeper than a landing). It plays the target app's page turn (127 B) and
  shifts the ground tint (<3%), accent swaps. No loop past the last app.

## 5. Words
Next, Write or say anything, Review, Apps, Let go to open {App}. Sentence case.

## QA
Switch Off = today's Home. On: no x pager; queue swipes and Undo unchanged; Now unchanged;
the fan never opens on a vertical scroll that starts above the edges; AX5; Reduce Motion.
