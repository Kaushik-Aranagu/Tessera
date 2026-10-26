# Sheet 288: the element template. Every element inherits its rules (Oct 26)

Kaushik, 12:55 PM PDT: "all these rules... added into the as a first class rules for the element itself... and it can
be inherited by other elements... whenever we define a new one, we now have a template to rely on... It's like proof
by induction... We start with one and show that it works... for any k if assumed true, k plus one is also true...
henceforward it is true for everything else... incorporate such language and such interfaces throughout not just
design, maybe all other layers too."

This sheet turns sheets 283 to 287 into one base class that every UI element inherits. A new element fills in a
short template, and an automatic conformance suite proves it keeps every rule.

## 1. The induction

- **Base case.** The base element, `Element`, carries every rule we have settled. One real element, the doors
  dial, fills the template and passes the conformance suite (section 5). That proves the template works.
- **Step (k to k+1).** A new element:
  1. inherits `Element`, or an element kind that inherits it;
  2. answers every required entry, or says "inherits";
  3. passes the same conformance suite.

  Because the suite checks the rules, not the element, every element that passes keeps the rules. Every element
  after that is proven the same way.
- **What keeps it true.** The conformance suite runs in `scripts/test.sh`. On the phone, the quiet stage (sheet 287,
  section 5) runs it before Tess applies a reshape. What happens on a failure depends on the check's tier
  (section 5): fix first, then block or warn.

## 2. The inheritance tree

```
Element                      (the base: every rule below)
  PlaceElement               (fills one shell place; frame from the shell contract)
    TypeElement              (title, nav word, needs, caption, door summary, action word)
    ListElement              (dial, page rows, widget stack)
      DialElement            (the doors: reel, index, sentence)
    KeystoneElement          (354 x 182 at 196; its material stays in its room)
      ChalkBoard, TicketRail, WordWall, Woods, Sky, IndexChart, Mosaic
    GlyphElement
  BodyElement                (level 2 bodies: checks, steps, sets, week, ledger, hours, text, tess)
  OverlayElement             (Tess's soul, the lens, the receipt and Undo line, shape mode)
```

A child overrides only what differs. Anything it doesn't name, it inherits.

## 3. The template (what every element answers)

| Entry | What it says | Base default (from sheets 283 to 287) |
|---|---|---|
| `identity` | name, kind, the place it fills | (required) |
| `frame` | its frame per level, and how it insets in Layout mode | the shell contract's frame; panes inset to an even 4 pt seam |
| `shape` | what content it draws (#1449: one, few, many, words, doors, measure, lines) | (required) |
| `forms` | the forms it can take, the designed one first, and their traits | the designed form only |
| `touch` | gestures it owns, and which belong to the shell | tap opens; across goes to the next item; the edge pull is the shell's; holding the Nav word is the shell's |
| `meaning` | `ElementMeaning`: items, focus, calls, `isShown` (#1434) | no calls; items by shown name |
| `moves` | the move for each change kind (sheet 287, section 2) | the catalog's default for its kind |
| `control` | how `.hand`, `.tess`, `.system` and `.stage` change the move (sheet 287, section 3) | the catalog's tempos and marks; never overridden by a leaf |
| `pending` | how its material shows Tess's blue until it dries (sheet 285) | type never carries blue; strikes do |
| `return` | what it shows coming back into view (sheet 286, section 4) | show now, then only the differences, once |
| `live` | its `LiveFeature` mode and its idle loop, if any (live-visibility.md) | `uiRead`, no idle loop |
| `reduceMotion` | its Reduce Motion version | a 150 ms crossfade; nothing travels |
| `look` | its colours and type steps, drawn from the room's palette | the room's palette and type scale; no colour trait |
| `privacy` | which of its facts are `deviceOnly` (money, body, calendar, location) | none |
| `layer` | its surface layer (section 5b) and what it does to what is underneath | layer 1, places: flat, and never over another element |
| `stage` | extra checks beyond the suite | none |

Rules no element may override, because they are the walls:
- the look rules (no cards, pills, bars, rings, middle dots, filled dots or decorative underlines; 3 to 4 colours;
  money always "about", never red or green);
- privacy taints;
- his finger always wins;
- every move ends within 1 s.

## 4. The base case, filled in: the doors dial

| Entry | DialElement |
|---|---|
| identity | Doors, a `ListElement`, the `dial` place |
| frame | 218,640 160 x 120 on every landing (on the right, sheet 289); the Page takes it at level 1 |
| shape | doors |
| forms | reel (designed), index, sentence. Index's density trait: more than 5 doors become two columns of 4. |
| touch | Reel: up and down turns it, and tapping the focus opens it. Index and Sentence: tap a door to open it. |
| meaning | items are the doors (kind `door`), the focus is the reel's centre, and the call is `openDoor` |
| moves | `replace` (the room changed): Reel spins the reel; Index and Sentence fade the old doors and their words rise in order. `form`: door words travel (520 ms). `value` (a count): digits roll. |
| control | inherits |
| pending | inherits (type, so no blue) |
| return | inherits; a changed count rolls once |
| live | `uiRead`, no idle loop |
| reduceMotion | inherits |
| look | the focus is 26 pt 700 in the room colour, the neighbours 20 pt ink2 with a 1.6 pt blur; Index uses 20 pt (14 pt in two columns) |
| privacy | inherits (door names only; the Private door shows a count, never names) |
| stage | the focus is always readable: it is never blurred and never under 20 pt |

The board draws all three forms of the dial, its swap, and the Nav word hold to reshape it.

## 5. The conformance suite (what every element must pass)

Kaushik, 1:00 PM PDT: "see if it can be fixed... some few of them are mandatory and will break the functionality...
and some of them are just good to have... depending on it, we should block or warn."

**On a failure: fix first, then block or warn.**
1. **Fix.** The suite (or the quiet stage on the phone) tries the element's own fixes, in order. Each fix is a step
   it already knows how to take, never an invention:
   - step the size trait down (never below the floor);
   - step density down;
   - fewer facts;
   - the next form in its list;
   - the designed form.

   If a fix passes, the build or Tess's change goes ahead with it, and the fix is reported ("index was too tight
   for 8 doors; used two columns").
2. **Must, so block.** If no fix passes a must check, the build fails and Tess does not apply the change.
3. **Should, so warn.** A should check that still fails is listed in the test report (and in Tess's line when she
   made the change). Nothing is held back.

These checks run for each element, each of its forms, both looks and Reduce Motion on and off. Must checks are
the ones whose failure breaks something, loses or hides a thing, or breaks a wall:

| Check | Tier | What it checks | Fixable |
|---|---|---|---|
| Renders | **must** | Each form draws its shape from sample data, with nothing clipped or hidden. | yes: size, density, facts, form |
| Lands | **must** | Every move ends on the same end frame as a still render of the after state. | no |
| Meaning | **must** | The same screen gives the same `ElementMeaning` in every form (#1449). | no |
| Unseen | **must** | With `isShown` false, a change draws no frames and the element arrives at its end state. | no |
| Walls | **must** | No `deviceOnly` fact reaches a frame that leaves the phone; no colour trait exists; the look rules hold (no cards, pills, bars, rings, middle dots; money "about", never red or green). | no |
| Floor | **must** | No type is below its floor (10 pt units, 13 pt lines). | yes: size, form |
| Touch | **must** | Every target is at least 44 pt. | yes: density, form |
| Contrast | **must** | Text against its ground is AA or better, in both looks. | yes: the designed form |
| Registered | **must** | The element is listed in `ElementRegistry.all`. | no |
| Bounds | **must** | No text of this element crosses another element's frame, in any form, either look, any Dynamic Type size, or at the 50% frame of a move. | yes: size, density, facts, form |
| Layers | **must** | It declares a layer from section 5b. Text over other text always has its layer's ground under it, and a shared slot has one owner at a time. | no |
| Timing | should | Each move ends within 1 s; the dial reel is allowed 980 ms. | yes: Reduce Motion's crossfade for that move |
| Return | should | Coming back into view plays only the differences, at most six. | yes: show now |
| Colours | should | At most 4 colours on the page; the three biggest words don't share a colour. | yes: the designed form |
| Reduce Motion | should | A Reduce Motion version exists (inherited counts). | inherits the base crossfade |
| Template | should | Every entry is answered or says "inherits". | no |

"Lands" is the core of the induction step: a move is only a path to a state the
element already draws correctly when still.

## 5b. Boundaries and layers (sheet 291)

Kaushik, 2:58 PM PDT: "make sure the text... doesn't overlap between two elements... maintain the boundaries so that you
don't need to deal with all of that problem. But yeah, surfaces, I think that's unavoidable, so let's just do that."

**First, boundaries.** Places tile the screen and never overlap (the shell contract's frames, with the 4 pt seam).
That is what keeps text from overlapping, so most screens never need the layering rule at all. Inside its frame an
element fits its words with its own fixes (size, density, facts, form), never by spilling over. Two things may want
the same slot, like the action word and the Undo line. Then the slot has **one owner at a time**, and the other steps
aside (hidden, not faded under).

**Then, layers.** Only these surfaces may sit over the places, from the bottom up:

| Layer | Surface | What happens to what is underneath |
|---|---|---|
| 0 | Ground | nothing is under it |
| 1 | Places (type, lists, widget, glyph, keystone) | never over another element |
| 2 | Shape mode outlines | they sit on the seams and have no fill, so nothing is covered |
| 3 | The glass lens | only under a finger, over the strip being swiped. It bends what is under it and never holds text of its own |
| 4 | Tess's wash | it lasts 600 ms and is never under his finger. Behind a keystone it tints the material; over type it is a 55% screen blend, and the type stays readable |
| 5 | Tess's soul | a fixed 96 pt square at the bottom right. No place may enter it, so it is a boundary, not a cover |
| 6 | Tess's words and receipts | a fixed band above the foot with its own frosted ground (blur 16, 88% ground). What's underneath is dimmed to 35% and can't be touched while the words show |
| 7 | Sheets (a level 2 item, a picker, settings) | an opaque ground. What's above the sheet dims to 60% and blurs 6 pt; a tap there closes the sheet. Nothing shows through the sheet |
| 8 | System (alerts, keyboard) | iOS's own treatment |

The rules:
- **Text never shows through text.** If a surface carries text over other text, it has its layer's ground: frosted
  for 6, opaque for 7. A bare glass or a fade is never enough.
- **The top surface takes the touch.** What's underneath is dimmed, and blurred if it would compete, but never hidden
  outright. He should always see where he is.
- **One cover at a time.** A new sheet replaces the one before it, and is never stacked on top of it. Tess's words
  wait while a sheet is up.
- **Reduce Transparency:** frosted grounds become opaque, and dims become the opaque ground at 92%.

**Things in flight (sheet 296).** A move can carry a copy across other places: a word flying from the Log wall to
the widget, or a ticket tearing off the Galley rail into the glyph. While it flies, it is on its own layer, and every
other place its path crosses (with a 48 pt margin) steps back to 28% within the first 4% of the move. It returns over
the last 20%. The place it lands in doesn't step back, because it is arriving there. A copy with a ground (a ticket
is paper) stays opaque until it is clear of where it came from, then fades. The mid-move check (`t35.js`) runs nine
routes, sampling 80 to 760 ms. Text of two places never crosses while both are above 40%. The only overlaps it allows
are a copy leaving its own source, and the same word handing off in place.

The board's boundary check (`t30.js`) finds no text crossing between places on all 7 landings and 6 door pages, in
paper and black.

## 6. The same pattern in other layers (proposed, for each lane to adopt)

| Layer | Base | Template entries | Suite |
|---|---|---|---|
| Core | `ClassDef` (already inherits fields) | fields, formulas, links, privacy, ops | an op round-trips; the op log replays to the same state |
| Tess tools | `ElementCall` | inputs and where they come from, reaction, reach | a bound call fills every input from the frame; a `deviceOnly` call never reaches Claude |
| Rooms | `RoomContent` | shape and form per place, keystone, doors, calls | each place's meaning matches what is drawn |

## 7. Interface (for Builder A, with Core)

- **The base:** `protocol TesseraElement` with default implementations for every entry in section 3, and a
  `struct ElementSpec` that holds the filled template as data, so the stage, Tess and the tests can read it.
- **The walls:** wall rules live in the protocol extension only. They are `final` helpers, not requirements, so no
  conformer can override them.
- **The suite:** `ElementConformance.run(spec:)` in the test target, called for every registered element. Each
  `Check` has a `tier` (`.must` or `.should`) and an ordered list of `fixes: [ElementFix]`. A result is `.pass`,
  `.fixed(by:)`, `.warn` or `.block`. `scripts/test.sh` fails only on `.block`, and lists `.fixed` and `.warn`
  results. On the phone, `ShellStage` runs the same checks.
- **Layers:** `enum SurfaceLayer: Int` with the cases in section 5b. `ElementSpec.layer` defaults to `.places`. The
  stage's `fits` flag becomes the Bounds check: it intersects every text run's rect with the other elements' frames.
- **Registration:** `ElementRegistry.all` lists every element. A new element that isn't registered fails a test, so
  nothing escapes the induction.
