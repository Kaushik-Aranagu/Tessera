# 211 Every highlighted word is a door; Next set apart; no caption (Oct 23, 11:50 AM PT)

Board: https://claude.ai/artifact/1aLhfDtkLbG2dFYbjUFVmp (v20). Kaushik's 11:42 and 11:43 AM, from his phone (release 66): he wants the colour keyword lines in departure style at the top, each highlighted word opening its page, the day opening a Today summary or calendar ("functionality and cool effects"); no text at the mosaic's bottom-left edge; Next more clearly its own section, but subtle. On by default.

## 1 Words are doors
- The three lines stay 205 + 200 (departure-board letter flips, app words 600 at 1.12x in their accent, 1 pt underline at 5 pt). #1326 is not on his phone yet; release 66 shows the plain fallback sentence.
- Every highlighted word opens through the 206 pixel doorway, the wave starting from the word itself:
  - an app word (Push day, groceries) opens that app's room (Training room = 210);
  - the day phrase (Thursday afternoon, Friday, Golden hour...) is a highlighted word too, in ink (600, underline, no accent colour, never cobalt), and opens Today.
- Numbers (6:30 pm) open the thing they belong to.
- One soft haptic on the tap; the doorway carries the rest. Reduce Motion: plain push.
- VoiceOver: each word is a button, "Push day, opens Training".

## 2 Today
- Title "Today", fact line "Three things left, the next at 6:30 pm".
- The day in order, one plain line each at 40 pt: name left, time right (Outfit 300). His things in ink; sunrise and sunset in ink 3.
- Calendar events show here only on the phone (never Claude, backups, logs or widgets). Private items read by their shown label.
- "Home" top left goes back (doorway reversed).

## 3 No caption under the mosaic
- Remove the caption line under the mosaic entirely, including the 209 page captions. The mosaic speaks for itself; its accessibility label carries the words ("Weather, sample", "Push day in 2 hr 10 min", "This week, 3 of 5 training days").
- 209's weather sample label moves into that accessibility label and the Settings line; there is no visible text on the mosaic's edge.

## 4 Next, set apart
- 22 pt of clear page above Next; the mosaic's blend and shield end above it, no pixels under the label.
- The label "Next" (Figtree 15, ink 3, sentence case, never caps) is followed on the same baseline by one 1 pt hairline in the edge colour running to the trailing margin. One rule per section, never between rows.
- Rows unchanged (207). The times are Outfit 300 numbers in ink 2. His phone shows them in a heavy, widely spaced face; that is a bug in release 66 (the .data role), fix with this.
- The apps list label stays off (209); the apps fact uses the same Outfit numbers and Figtree words, never the heavy spaced face.

## Owners
- B: sections 1 (tap targets, VoiceOver), 3 and 4, and the font fix.
- A: the doorway starting from a word's frame, and the Today room.
- Core: Today's ordered day lines from the existing loaders.

## Reviewer guards
- The day word is ink, never cobalt or a new accent. No caps labels. One hairline per section only.
- Today never leaves the phone with calendar text.

## Ruling: no back word (coordinator, Oct 23, 4:16 PM)
Kaushik asked why there is a back word at all. Rooms and Today show no "< Home" or "Home" word at the top. To go back, swipe from the left edge, which plays the doorway in reverse; VoiceOver escape also works. The space the word used goes to the lintel.
