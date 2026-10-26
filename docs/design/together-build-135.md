# Item 135: Build sheet for sheet 134 (Oct 22)

Kaushik, Oct 22 4:21 PM PDT: "Yeah, sounds good. Do this and ask other teams..." He
approved all six concepts of sheet 134 in the order 1, 3, 5, 2, 4, 6, and the link
carve-out (127 A8). Every piece rides a Review switch, default Off, in Settings > Review
"Together". Privacy walls exactly as before. Keep every element feature (131 2b).

## 1. Day sentence (switch: daySentence)
Core: HomeSentence.compose(day) -> [Clause], each {app, text, keyWord range, opens}.
 - Source: each app's existing landing sentence (LandingSentences, KitchenLanding, Money
   trend, RoutineUsual, Notes and Lists facts). No new templates.
 - Order: by the clause's clock time (cook start, workout usual start, due date at 9:00,
   routine usual start); untimed clauses last. Max 4 clauses; drop the oldest-untimed first.
 - An app with nothing to say gives no clause. No clause at all: "A quiet day."
 - Money clause only "Rent is due Friday."-style due words; never an amount on Home.
 - Private things: "Private workout" / "Private recipe"; walled titles never.
Builder B (Home): the clauses as one paragraph, .title role at default (wraps, no
 truncation), key words in the app accent, rest ink. It replaces the hero on the TODAY
 page only when the switch is On; Now (a running process) still leads above it.
Builder A (motion): word-to-title. Tap a key word: the word grows on the house spring to
 the landing title size and position (matched geometry), the rest of the paragraph drops
 to ink 3 and fades; the landing assembles under the title in reading order (stagger
 Theme.Motion.stagger). Back reverses it. Reduce Motion: 150 ms crossfade. One soft
 haptic at landing. The landing's own title takes the word's text until it settles, then
 crossfades to the app name over 200 ms ("Tacos" -> "Kitchen").

## 3. Words remember (switch: linkColours)
Core: ClassResolver.app(for class) -> AppID? (Training, Kitchen, Money, Notes, Lists,
 Routines, nil). ObjectStore.mentions(of object) -> [(app, count, opens)] from backlinks.
Builder B (Notes, Lists): any @link word or linked item renders with a 1 pt underline in
 its home app's accent (127 A8), text in ink. Same app: the app's normal link underline.
 Long press: the object's side (sides-77) as a sheet over the page; tap: its page.
Builder A (Training) and B (others): every object page gets "Mentioned in" above the
 doors: one line per app, "{n} workouts" / "3 notes" / a single title, app name small on
 the right in ink 3. Hidden when only the home app mentions it.
Private or walled: "Private", plain ink, no underline colour, no Mentioned in.

## 5. Write anywhere (switch: writeAnywhere)
Core: WriteRouter.route(text) -> [Candidate{app, action, receipt, confidence}] trying
 each app's existing write grammar on the phone. One candidate: do it. Two or more with
 the same score: return a Tie. Lines that touch money, health, body or calories are never
 sent to any model; ties among them ask him.
AI arch: on-device Foundation Models tie-break only for non-walled lines, never Claude.
Builder B: the write line on Home (and in Tess's capture) uses the router. The typed line
 shows wet cobalt in the Tess corner, then travels (house spring, 420 ms) toward the
 bottom edge and dries; the receipt names thing first and where, with NO amount (coordinator
 privacy ruling Oct 22: the amount shows only inside Money): "Lemons, from
 US checking." with "Money, Spending" in ink 2 and Undo for 10 s. A tie: Tess asks with
 the two app words as ink actions ("Money or Kitchen?").

## 2, 4, 6: Core first, screens after (switches: oneHands, occasions, makeAKind)
2 Core: lift CookPlanner's handsCap into ProcessTable.collisions(day) -> [Collision{a, b,
  at, fix: Shift}] using workout usual start + length, cook plan, routine usual start.
4 Core: class Occasion (Thing > Occasion): start, end, links: refList(any). Asks each
  linked app for its signature fact: Lists left of total, Training place and sessions
  in range, Kitchen use-soon before start, Money pool balance (ink, phone only),
  Routines by name. The pool balance shows only on the Occasion page in the app (never
  Home, widgets, Live Activities, notifications or Siri).
6 Core: KindOffer.today() -> one offer: a things-field word with >= 4 notes in 30 days,
  not private, not already a class; MakeKind(word, fields) creates the ClassDef and
  offers each note as an object (Keep per note, Keep all).
Design writes the screen sheets for 2, 4, 6 once Core's facts exist.

## QA
Each switch Off = the app exactly as before. On: the rules above, privacy rows from
131 section 1, AX5 (sentence wraps, no truncation), Reduce Motion crossfades.
