# 103. Settings Review, pages 5 and 6: the stretch switches

Extends sheet 100 (same row, same grammar). Spec only; nothing ships until Builder B takes it. Not yet okayed by Kaushik. Product's list for these is the stretch batch (Tess reads the screen, Tess experts, Build with Tess, Automations, Watch, Pantry state, Can cook shelf, Hands-free cook).

## What does not change from 100
- Row: name left in `ink` (21, never wraps), value right in `inkSecondary` (21) in plain words, the matching-master-today value marked with the 16 word **Today**.
- One 16 before/after line, only under the row he last touched. A flip is live in the house spring (0.42 s; 150 ms crossfade under Reduce Motion and Low Power), one haptic, no toast.
- Default is today's behavior: with a row at Today the app looks and acts exactly like master. "Everything as before" at the top of the section covers these rows too.
- Section words: page 5 **TESS MORE**, page 6 **KITCHEN AND WRIST**. Six rows at most a page; the rail on the right edge now shows pages 1 to 6.

## Page 5, TESS MORE (4)
| Row | Values (Today first) | Before / after line | State rule |
|---|---|---|---|
| Tess reads the screen | Off, On | "On: Tess can read what is on this screen when you ask her about it. She never reads on her own." | **Needs Claude** when Tess asks Claude is off. Private titles reach her only as "Private ...", the same mask as everywhere. |
| Tess experts | Off, On | "On: ask for a trainer, a cook or a planner and she answers in that voice. The looks and words stay Tess's." | **Needs Claude**. No new face: an expert is a line of Tess's, never a second character. |
| Build with Tess | Off, On | "On: say one sentence and she draws a ghost of the app piece. You accept or skip it." | **Needs Claude**. Off hides the entry in the ask slot and the Remix editor's Build word (sheets 101 and 102). |
| Automations | Off, On | "On: a rule you made runs by itself and says so in one line. Off: rules wait for your tap." | No Claude needed. Each run shows as a receipt naming the thing first ("Milk, added.") with UNDO. |
- The Claude-sending rows (reads the screen, experts, Build) never turn Tess asks Claude on. With it off the value reads **Needs Claude** and a tap goes to that row, nothing flips silently. The walls from sheet 80 still hold: money, body and Private note content never leave the phone.

## Page 6, KITCHEN AND WRIST (4)
| Row | Values | Before / after line | State rule |
|---|---|---|---|
| Watch | Off (Today), On | "On: the Watch logs sets and shows rest. Off: the phone only." | **Later** until a Watch target exists; the tap says so in one line. |
| Pantry state | Hidden (Today), Shown | "Shown: Pantry says what is out and what is low, in Kitchen and in a recipe's ingredient peek." | Nothing is deleted when hidden. |
| Can cook shelf | Off (Today), On | "On: a shelf on Recipes of what you can cook with what is in the pantry." | Needs Pantry state Shown; the value reads **Needs Pantry** and a tap goes to that row. |
| Hands-free cook | Off (Today), On | "On: in cook mode say Next, Back or Repeat and the timer speaks when it ends. Off: tap the word." | **Needs Claude** is not required (on-device speech); the value reads **Needs Mic** only if the system says no, once. |

## Side (sheet 75)
Pages 5 and 6 share sheet 100's side, THE FLIPS. Nothing new is drawn; these flips show in it like the rest ("Hands-free cook, On, 6:10 pm"). VoiceOver: each row reads "Name, value", actions Flip.

## States
- **Empty:** every value Today, side "No flips yet."
- **Long:** 8 rows here over pages 5 and 6; total 27 over six pages.
- **AX1 and up:** name above value; the before/after line under the touched row.
- **Reduce Motion / Low Power:** 150 ms crossfade.
- **Obsidian:** values `inkSecondary`, the touched value in the area colour at 72%.

## Never
Pills, cards, boxes around a switch, "Enabled/Disabled", a toast per flip, turning Claude or the microphone on by flipping a row, a second character for an expert, italics, a faded Tess, a fourth size.

## For Builder B
Add the eight rows to the same table and `ReviewChoices` store as sheet 100 (name, values, default, line, needs). A row whose need is unmet shows its Needs word and never writes its value.
