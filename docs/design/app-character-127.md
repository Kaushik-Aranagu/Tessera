# Item 127: App character, what stays fixed and what each app may change
Kaushik, Oct 22: "all the apps look exactly the same. I want customization and uniqueness to
each app but still all of them coherent and compliant to the base principles".
Board: mockups/app-character-127.png (Training, Kitchen, Money, Notes).

## A. Fixed in every app (the grammar; never changes)
1. Type pair: Figtree words, Outfit numbers (sheet 116), one type scale, sentence case.
2. Ink actions: actions are words with a coloured underline; no cards, pills, button
   shapes, coloured dots, lines between rows, "..." truncation, or stock iOS controls.
3. Page frame: "< Back" word top left, title 44 pt at the 22 pt gutter, one subtitle line,
   one primary action word at the bottom, nothing past the page edge.
4. Tess: same soul, same corner, same voice; never faded.
5. Motion only through MotionPolicy; Reduce Motion = crossfade; one haptic per moment.
6. Privacy walls, "best" not "record", time as "1 hr 35 min", US words and dollars.
7. The look (Porcelain, Obsidian, ...) sets the base for the whole app; no app overrides it.
8. Link carve-out (Kaushik, Oct 22 4:21 PM PDT, sheet 134 concept 3): a link to a thing that
   lives in another app may carry that app's accent on its underline only, hairline (1 pt),
   never on the text. Private or walled things: "Private", plain ink, no colour.

## B. What each app owns (its character; pick one value per row)
| Lever          | Allowed range                                                    |
| Accent         | one hue from the area colours (sheet 86 C); subtitle, the action  |
|                | underline and the one lit thing per page use it; nothing else     |
| Ground tint    | the look's base, or a tint within 3% of it (Kitchen warm, Notes   |
|                | paper); never a gradient or texture                               |
| Lead form      | what leads the page: a big number, two halves, a ledger, a reading|
|                | column, a dial rail, a strand; one per app                        |
| Number voice   | Outfit 200 hero, or Outfit 300 tabular columns (Money)            |
| Signature      | one element only this app draws (set marks, the stove, the total  |
|                | rule, the link underline, the day strand)                         |
| Motion feel    | a named MotionPolicy preset: firm, soft, precise, drift, calm      |
| Haptic texture | rigid tap, soft tap, selection tick, or none                      |
| Page turn      | the Settings page turn, or the app's own (e.g. Notes = paper)     |
| Allowed line   | at most one kind of line the app may draw for meaning (Money's    |
|                | total rule, Notes' link underline); never a separator             |

## C. The five apps as first set
- Training: accent hot red, base ground, lead = one big number, signature = set marks,
  motion firm, haptic rigid tap per set.
- Kitchen: accent ochre, ground warm tint, lead = the amount column (amounts first, Outfit
  200, names beside), signature = the amount column plus the level line (its one allowed
  line); the cook runner's face is "on the stove | to hand"; motion soft (settles with
  weight), haptic soft. Heat colour only on running countdown digits; no page-edge glow.
- Money: accent sea green, base ground, lead = ledger with aligned decimals, signature =
  the total rule, motion precise (no bounce), haptic selection tick.
- Notes and Reading: accent violet, ground paper tint, lead = reading column, signature =
  the link underline, motion drift, haptic none except on save.
- Daily (routines, habits, body, people): accent calm blue, lead = the Thread (one line
  down the left edge, steps hang from it, dashed ahead, solid done, one hot stitch for now),
  signature = the Thread (its one allowed line; it replaces the progress strip in Daily
  runners), motion calm (one spring pull per step), haptic soft. Night is a dimmer tone of
  the same accent, not a second accent.

## D. How a new app is designed
Fill section B with one value per row, draw its home page at default and AX5, and check
section A line by line. Two apps may not share the same signature or lead form.

## E. Accent table (Oct 22, set after the five app pages; no two apps share an accent)
| App       | Accent (Obsidian / Porcelain) | Ground                         |
| Training  | hot red #EE6A4C / #C4472A     | the look's base, no tint       |
| Kitchen   | ochre #E0A458 / #A8701F       | base + about 2% warm           |
| Money     | sage #8DBFA7 / #3F7A62        | base + about 1% green-grey     |
| Notes     | violet #B9A9E0 / #5B3FB8      | base + about 2% paper          |
| Lists     | olive #B5BE7A / #5E6B1F       | base + about 2% cool           |
| Routines  | dusk rose #D79AA6 / #A4505F   | the look's base; Night dims it |
Cobalt stays Tess's voice only. Signatures may not repeat: Training set marks, Kitchen
amount column + level line, Money total rule, Notes link underline, Lists the strike and
count, Routines the Thread.

## F. The landing page of every app (Kaushik, Oct 22 08:22)
Every app opens on an overview where the app talks to him. Contents, shown only when there
is something (an empty band is left out, never "nothing here"):
1. The app's sentence: one or two short sentences in plain words, the one key word in the
   accent ("Rent is due Friday. October is calm so far.").
2. Running: a routine already going, with one ink word into its focus mode on the same
   step (Pick up, Go on, Read).
3. Waiting on you: what needs his hand, at most three lines, never shaming.
4. New: what changed since he last looked, at most three lines.
5. The doors: the ways into the app's sections, services and libraries.
The ORDER and the FORM of these are the app's own (its lead form), and no two apps may
share a form. First sketches (mockups/app-landing-130.png, input for the app threads):
- Training: running routine with its set marks leads; doors are a 2 x 2 of big numbers.
- Kitchen: the evening as a meal clock line leads; amounts-first rows; doors are warm
  words with counts.
- Money: Due on the decimal line leads; doors are ledger lines, each a total, closed by the
  one total rule.
- Notes: the overview is a paragraph; every door is an underlined link in the sentence;
  Reading sits under it with Read.
- Routines: the running routine on its Thread is the page; Pick up or Done for today.
The sentence is computed on the phone; walled, money, health and body facts never go to
Claude to write it.
