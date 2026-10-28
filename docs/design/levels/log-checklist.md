# Log, Level 1 and Level 2: what still differs from the board

Checked on Oct 28 against master. This is for Builder B. The contract is sheet 284 (`docs/design/levels-284.md`). The board is https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp: open the Log, turn the dial, tap a door, then tap a row.

## Where it stands

- On his phone, a Log door still pushes the old pages: `NotesIndex` for All notes and `NotesDoorPage` for the others (`Features/Notes/NotesView.swift`). The shell version, `NotesShellHost` in `NotesRoomContent.swift`, only runs behind `-shell` on the simulator
- The shell version has level 1 only: a plain `.list` of titles and times. It has no level 2. Tapping a row opens the editor sheet
- **Update, later on Oct 28:** Builder A's `ios/deck-levels` (a08a8a3d) is further along than master:
  - the Log already sits in the root shell by default (`NotesRoomDriver`);
  - the five lines in point 2 have lost their full stop;
  - the root shell draws Tess at every level (point 4).

  Still open there: level 1 is a `.list`, the nav word reads "Log", there is no level 2, there are three doors, and private notes get a row each

## The move

1. **Put the Log on the shell for real, the way the Deck is going**
   - The doors open level 1 and the rows open level 2
   - Use Builder A's kit from `ios/deck-levels` (`RankedPage`, `ItemPage`, the page title with across, the level 2 route), not `.list`
   - The fixes in `docs/design/levels/deck-checklist.md` that are kit-wide apply here too (the foot per level, Tess at every level, captions per door, units, settle)
2. **No full stop at the end of any shown line.** These still have one:
   - "Nothing here yet."
   - "{n} notes, newest first."
   - "Tap a word to open its note."
   - "No notes today." (and the this-week and earlier forms)
   - "Write the first thing down."
   A note's own text keeps its full stops. The board's captions had the same slip, and they're fixed on the board now

## The frame

3. The nav word reads "Doors" at level 1 and the door's name at level 2. Today it reads "Log"
4. Tess stays bottom-right at every level. Every screen sets `.tess: nil`
5. The foot at level 1 is "Add" with "to {door}", then "Ask" with "Tess about {door}". At level 2 it is the note's own verbs (below). Today Write, Speak and List show everywhere

## The doors (level 1)

6. The board has eight doors; the app has three (All notes, Loose, Private). Add the ones the store can already answer, and leave out any it can't. "Loose" isn't on the board; keep it only if he uses it. Each door below gives its line, its caption, then its rows (a row is title, sub, value)
   - **All notes**: "16 notes, newest first", caption "Tap a word on the wall to jump to its note"
     - Rows, newest first. The value is when, said short: "noon" or "9:12" today, a weekday this week ("Mon"), then the date ("Oct 19")
     - The sub says what it is and why it matters ("A list, 8 left, due Friday", "From Tess, this morning", "Due by 6 today")
   - **Ideas**: "10 ideas, the newest on top", caption "Ideas glow on the wall until you use them"
   - **From Tess**: "2 kept for you", caption "Tess's notes sit in her blue". Its rows' titles are in Tess blue
   - **Voice memos**: "3 voice notes, typed by Tess", caption "Hold a word on the wall to hear it". The sub is the length and where it was recorded ("0:42, from the car")
   - **Pinned**: "2 pinned, they stay on top", caption "Pinned words sit at the top of the wall"
   - **Mentions**: "4 notes that name someone", caption "Names on the wall are the people you wrote about". One row per person, with how many notes name them as the value
   - **Private**: "Locked", caption "Private notes never leave the phone". **A count only:** one row, "3 private notes", with the sub "Unlock to read". The shell version today lists a "Private note" row with its time for each private note, which says when he wrote them. Show the count only
   - **Archive**: "24 put away", caption "Archived words leave the wall". The value is the month it was put away
7. Row colors follow sheet 284:
   - the first row is bold, in the Log's violet mixed 58% with ink;
   - due today or late is wine;
   - from Tess is Tess blue;
   - pinned until a date is gold.
   Values are Outfit Light and stay ink

## The note pages (level 2)

8. A row opens its item page, not the editor. The Item title is the note's title over one line ("A list, due Friday"), and across goes to the next note in the door. Editing starts from the foot
9. Facts are three columns. For a list: left, done and due ("8 left", "6 done", "Fri due"). For a note from Tess: what it holds ("5 k easy", "4 strides", "Sat long run"). For a plain note: whatever counts in it ("3 sketches", "2 beds")
10. The body depends on the note's kind. These are three new kinds next to `SetsBody` in the kit
    - **checks** (a list):
      - rows split the body evenly;
      - each row has an 18 pt tick drawn in green when done, and faint (18%) when not;
      - row text is Figtree 18 in ink, and done words are struck through in ink 2;
      - tapping a row draws the tick in one 0.16 s stroke, and the strike follows once the pen lifts (sheet 300);
      - unticking lets the ink fade back to the faint mark
    - **tess** (from Tess): Newsreader italic 21/31 in Tess blue. Only Tess's own words use Newsreader
    - **text** (a plain note): Figtree 18/28 in ink, with the note's own full stops
11. The foot's verbs, by kind:
    - a list: "Check" with "the next thing", then "Add" with "something to pack";
    - from Tess: "Keep" with "as a note", then "Ask" with "Tess to change it";
    - a plain note: "Write" with "more", then "Plan" with "make it a list".
    A private note never opens a page with its words; it stays a count
