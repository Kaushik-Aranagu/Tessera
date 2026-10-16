# Lists fixtures: pasted blocks and list phrases

For: Core engine (Lists slices 3 and 8), Kitchen lead
Date: 2026-10-15
Read with: `product/ship-list-lists.md`, `product/lists-acceptance.md` (the "Trip" paste there is not repeated), `product/kitchen-phrases.md` rows 41-48 (not repeated).

Names match origin/master where they exist: `ListContents.Item` (`text`, `quantity`, `section`, `isDone`, `checkedAt`), actions `CreateList`, `AddListItem`, `CheckListItem`, `MoveListItem`, `ClearDoneItems`, `AddGroceries`, `StartShop`, `RenameObject`, `DeleteObject`, and `TessGrammar.Parse` cases `.list`, `.groceries`, `.lift`, `.set`, `.task`, `.note`, `.timer`, `.cook`, `.shop`, `.recipe`. Names from the ship list that don't exist yet (`AddListItems`, `StartListRun`, `CopyList`, `pick(from:)`, uncheck all) are used as the ship list spells them. New parse cases are in the ASSUMED list.

## Parsing rules these fixtures pin down

1. **Title.** The first line is the list title when it is unmarked (no bullet, number, box or colon) and the next non-blank line is marked, a heading, or follows a blank line. `# Title` is the title when the block also has `##` headings. Otherwise there is no title and the preview asks for a name (`title: null`).
2. **Sections.** One level only. A section starts at: a `Heading:` line, a `#`/`##` line, an ALL CAPS unmarked line followed by items, a plain line whose following lines are indented, or the first line of a blank-line group of 2+ lines when the block has 2+ such groups. Section names keep their text but lose the colon and `#`; ALL CAPS becomes Title Case.
3. **Markers stripped.** `-`, `*`, `•`, `◦`, `–`, `1.`, `1)`, `a)`, `[ ]`, `[x]`, `[X]`, and emoji boxes `☐ ⬜ ☑ ✅ ✔`. Checked: `[x]`, `[X]`, `☑`, `✅`, `✔`.
4. **Quantities** read as in groceries (`IngredientLine`): "2 x adaptor", "adaptor x2", "adaptor (2)", "500g pasta". A number that is part of a name ("1984", "Ocean's 11") is not a quantity.
5. **Notes.** An indented unmarked prose line under an item becomes that item's `note`. A Markdown link's URL goes to the note.
6. **Duplicates** in one paste merge into the first one (same text, case-insensitive, same section). Open wins over checked. Quantities add when both have one.
7. **Not a list.** A block with an `Ingredients` / `You will need` heading is a recipe (`parsePastedRecipe` already catches it). Numbered cooking steps or one long prose line are flagged in the preview.

Item fields below: `text`, `checked` (`isDone`), `note`, and `quantity` / `date` only when set. `section title: null` means items with no section.

## Part 1: 40 pasted blocks

```yaml
- id: L01
  shape: markdown-checkbox
  raw: |
    Lisbon
    - [ ] passport
    - [x] euros
    - [ ] plug adapter
    - [X] boarding pass
  title: Lisbon
  sections:
    - title: null
      items:
        - {text: "passport", checked: false, note: null}
        - {text: "euros", checked: true, note: null}
        - {text: "plug adapter", checked: false, note: null}
        - {text: "boarding pass", checked: true, note: null}
  notes: >-
    Capital X counts as checked. Checked items come in with checkedAt set to the paste time.

- id: L02
  shape: markdown-checkbox, star bullets, no title
  raw: |
    * [ ] call landlord
    * [x] pay council tax
    * [ ] book MOT
  title: null
  sections:
    - title: null
      items:
        - {text: "call landlord", checked: false, note: null}
        - {text: "pay council tax", checked: true, note: null}
        - {text: "book MOT", checked: false, note: null}
  notes: >-
    Reads like tasks, but a paste on the Lists shelf is always a list. Preview asks for a name.

- id: L03
  shape: markdown-headings
  raw: |
    # Camping
    ## Sleep
    - [ ] tent
    - [ ] sleeping bag
    ## Cook
    - [ ] stove
    - [ ] gas canister
    - [x] lighter
  title: Camping
  sections:
    - title: Sleep
      items:
        - {text: "tent", checked: false, note: null}
        - {text: "sleeping bag", checked: false, note: null}
    - title: Cook
      items:
        - {text: "stove", checked: false, note: null}
        - {text: "gas canister", checked: false, note: null}
        - {text: "lighter", checked: true, note: null}
  notes: >-
    "# Camping" is the title (not a section) because the block also has ## headings.

- id: L04
  shape: markdown-checkbox, nested
  raw: |
    - [ ] Bathroom
      - [ ] descale shower
      - [x] new bath mat
    - [ ] hoover stairs
  title: null
  sections:
    - title: Bathroom
      items:
        - {text: "descale shower", checked: false, note: null}
        - {text: "new bath mat", checked: true, note: null}
    - title: null
      items:
        - {text: "hoover stairs", checked: false, note: null}
  notes: >-
    A checkbox parent with marked children becomes a section; its own box is dropped. hoover stairs has no section even though it comes after.

- id: L05
  shape: apple-notes-checklist, plain-text flavour
  raw: |
    Weekend
    Pick up parcel
    Return library books
    Fix bike light
  title: null
  sections:
    - title: null
      items:
        - {text: "Weekend", checked: false, note: null}
        - {text: "Pick up parcel", checked: false, note: null}
        - {text: "Return library books", checked: false, note: null}
        - {text: "Fix bike light", checked: false, note: null}
  notes: >-
    ASSUMED clipboard format (checklist lines lose their circles and checked state as plain text). Rule 1 gives no title, so "Weekend" is an item; the preview's name field is where the user fixes it. Known limitation, keep the test so it stays visible.

- id: L06
  shape: apple-notes-checklist, title then blank line
  raw: |
    Gift ideas

    Mom - silk scarf
    Dad - bird feeder
    Priya - pasta maker
  title: Gift ideas
  sections:
    - title: null
      items:
        - {text: "Mom - silk scarf", checked: false, note: null}
        - {text: "Dad - bird feeder", checked: false, note: null}
        - {text: "Priya - pasta maker", checked: false, note: null}
  notes: >-
    ASSUMED Notes format. A blank line after the first line makes it the title. An inner " - " is text, not a bullet and not a note split.

- id: L07
  shape: apple-notes-checklist, hollow bullet variant
  raw: |
    Bike service
    ◦ chain oil
    ◦ inner tube 700x28
    ◦ brake pads
  title: Bike service
  sections:
    - title: null
      items:
        - {text: "chain oil", checked: false, note: null}
        - {text: "inner tube 700x28", checked: false, note: null}
        - {text: "brake pads", checked: false, note: null}
  notes: >-
    ASSUMED variant (some apps paste Notes checklists with ◦). "700x28" is a tyre size, not a quantity and not a set.

- id: L08
  shape: bullet-dot
  raw: |
    Hospital bag
    • phone charger (long cable)
    • dressing gown
    • snacks 🍫
  title: Hospital bag
  sections:
    - title: null
      items:
        - {text: "phone charger (long cable)", checked: false, note: null}
        - {text: "dressing gown", checked: false, note: null}
        - {text: "snacks 🍫", checked: false, note: null}
  notes: >-
    A non-numeric parenthesis stays in the text. Trailing emoji stays.

- id: L09
  shape: mixed bullets
  raw: |
    Desk
    - monitor arm
    * cable tray
    • lamp
    – footrest
  title: Desk
  sections:
    - title: null
      items:
        - {text: "monitor arm", checked: false, note: null}
        - {text: "cable tray", checked: false, note: null}
        - {text: "lamp", checked: false, note: null}
        - {text: "footrest", checked: false, note: null}
  notes: >-
    Four bullet styles in one block, including an en dash from autocorrect.

- id: L10
  shape: numbered-dot, quantities
  raw: |
    Party
    1. 2 x bags of ice
    2. lemonade x6
    3. candles (12)
    4. 500g crisps
  title: Party
  sections:
    - title: null
      items:
        - {text: "bags of ice", quantity: "2", checked: false, note: null}
        - {text: "lemonade", quantity: "6", checked: false, note: null}
        - {text: "candles", quantity: "12", checked: false, note: null}
        - {text: "crisps", quantity: "500 g", checked: false, note: null}
  notes: >-
    The list number is stripped before the quantity is read. Quantity spelling follows IngredientLine.

- id: L11
  shape: numbered-paren, numbers in names
  raw: |
    Books
    1) 1984
    2) Ocean's 11 (film tie-in)
    10) 3 Body Problem
  title: Books
  sections:
    - title: null
      items:
        - {text: "1984", checked: false, note: null}
        - {text: "Ocean's 11 (film tie-in)", checked: false, note: null}
        - {text: "3 Body Problem", checked: false, note: null}
  notes: >-
    Trap. "1984" and "3 Body Problem" are not quantities. ASSUMED rule - a leading number is a quantity only when the list is Groceries or the number has a unit or "x".

- id: L12
  shape: numbered, no space, two digits
  raw: |
    Chores
    1.bins out
    2.change sheets
    ...
    11.defrost freezer
  title: Chores
  sections:
    - title: null
      items:
        - {text: "bins out", checked: false, note: null}
        - {text: "change sheets", checked: false, note: null}
        - {text: "defrost freezer", checked: false, note: null}
  notes: >-
    "1." with no space still strips. A lone "..." line is dropped. Gaps in numbering are ignored; order is paste order.

- id: L13
  shape: heading-colon
  raw: |
    Festival
    Wear:
    wellies
    rain poncho
    Bring:
    cash
    power bank
  title: Festival
  sections:
    - title: Wear
      items:
        - {text: "wellies", checked: false, note: null}
        - {text: "rain poncho", checked: false, note: null}
    - title: Bring
      items:
        - {text: "cash", checked: false, note: null}
        - {text: "power bank", checked: false, note: null}
  notes: >-
    Unmarked items under colon headings.

- id: L14
  shape: heading-colon with inline items
  raw: |
    Trip prep
    Tech: charger, cable, adapter
    Docs: passport
  title: Trip prep
  sections:
    - title: Tech
      items:
        - {text: "charger", checked: false, note: null}
        - {text: "cable", checked: false, note: null}
        - {text: "adapter", checked: false, note: null}
    - title: Docs
      items:
        - {text: "passport", checked: false, note: null}
  notes: >-
    ASSUMED. "Heading: a, b" splits into items of that section, with the same splitter as TessGrammar.splitItems.

- id: L15
  shape: all-caps headings
  raw: |
    SATURDAY
    - farmers market
    - haircut
    SUNDAY
    - long run
    - meal prep
  title: null
  sections:
    - title: Saturday
      items:
        - {text: "farmers market", checked: false, note: null}
        - {text: "haircut", checked: false, note: null}
    - title: Sunday
      items:
        - {text: "long run", checked: false, note: null}
        - {text: "meal prep", checked: false, note: null}
  notes: >-
    Day-name sections do not date their items. "long run" is an item, not a training session.

- id: L16
  shape: all-caps items, not headings
  raw: |
    Admin
    - DVLA form
    - TV LICENCE
    BBQ
  title: Admin
  sections:
    - title: null
      items:
        - {text: "DVLA form", checked: false, note: null}
        - {text: "TV LICENCE", checked: false, note: null}
        - {text: "BBQ", checked: false, note: null}
  notes: >-
    Marked caps are items. Unmarked "BBQ" has nothing after it, so it is an item, not an empty section.

- id: L17
  shape: blank-line sections
  raw: |
    Bathroom
    bleach
    sponges

    Kitchen
    bin bags
    dish soap
  title: null
  sections:
    - title: Bathroom
      items:
        - {text: "bleach", checked: false, note: null}
        - {text: "sponges", checked: false, note: null}
    - title: Kitchen
      items:
        - {text: "bin bags", checked: false, note: null}
        - {text: "dish soap", checked: false, note: null}
  notes: >-
    Two blank-separated groups, so each group's first line is a section.

- id: L18
  shape: blank lines as spacing only
  raw: |
    Films
    - Heat

    - Past Lives

    - Dune
  title: Films
  sections:
    - title: null
      items:
        - {text: "Heat", checked: false, note: null}
        - {text: "Past Lives", checked: false, note: null}
        - {text: "Dune", checked: false, note: null}
  notes: >-
    Groups of one marked line make no sections. If a "Films" list exists the paste merges into it (research rec 4), see L39.

- id: L19
  shape: indented sub-items under plain lines
  raw: |
    Move flat
    Before
        book van
        cancel broadband
    On the day
        meter readings
        keys to agent
  title: Move flat
  sections:
    - title: Before
      items:
        - {text: "book van", checked: false, note: null}
        - {text: "cancel broadband", checked: false, note: null}
    - title: On the day
      items:
        - {text: "meter readings", checked: false, note: null}
        - {text: "keys to agent", checked: false, note: null}
  notes: >-
    Matches lists-templates.md rec 2.

- id: L20
  shape: tab-indented, three levels
  raw: |
    Wedding
    - Venue
    	- deposit
    	- Catering
    		- tasting
    		- menu card
  title: Wedding
  sections:
    - title: Venue
      items:
        - {text: "deposit", checked: false, note: null}
        - {text: "Catering", checked: false, note: null}
        - {text: "tasting", checked: false, note: null}
        - {text: "menu card", checked: false, note: null}
  notes: >-
    Tabs count as indent. One level of sections, so the level-2 parent "Catering" becomes an ordinary item and its children follow it. Preview says "Flattened 1 level".

- id: L21
  shape: emoji check marks
  raw: |
    Visa
    ✅ passport photos
    ☑ bank statements
    ⬜ employer letter
    ☐ flight booking
    ✔ application form
  title: Visa
  sections:
    - title: null
      items:
        - {text: "passport photos", checked: true, note: null}
        - {text: "bank statements", checked: true, note: null}
        - {text: "employer letter", checked: false, note: null}
        - {text: "flight booking", checked: false, note: null}
        - {text: "application form", checked: true, note: null}
  notes: >-
    ASSUMED emoji box set. Leading box emoji only; "✅" elsewhere in a line is text.

- id: L22
  shape: emoji headings and items
  raw: |
    🏖️ Goa
    🧳 Bags:
    - 🩴 flip flops
    - 🕶️ sunglasses
    💊 Meds:
    - antihistamine
  title: 🏖️ Goa
  sections:
    - title: 🧳 Bags
      items:
        - {text: "🩴 flip flops", checked: false, note: null}
        - {text: "🕶️ sunglasses", checked: false, note: null}
    - title: 💊 Meds
      items:
        - {text: "antihistamine", checked: false, note: null}
  notes: >-
    Emoji are kept in titles, sections and items (variation selectors intact). Tess's line counts grapheme-safe text.

- id: L23
  shape: very long items
  raw: |
    Renovation
    - get three quotes for the back wall damp, ask each one whether they'd tank it or use a breathable lime render, and get it in writing with the guarantee period, because the last lot vanished after the deposit
    - skip hire
  title: Renovation
  sections:
    - title: null
      items:
        - {text: "get three quotes for the back wall damp, ask each one whether they'd tank it or use a breathable lime render, and get it in writing with the guarantee period, because the last lot vanished after the deposit", checked: false, note: null}
        - {text: "skip hire", checked: false, note: null}
  notes: >-
    214 characters, one item, never split on its commas, never truncated in storage. The row truncates visually only.

- id: L24
  shape: duplicates in one paste
  raw: |
    Packing
    - socks
    - Socks
    - 2 t-shirts
    - t-shirts x3
    - [x] charger
    - [ ] charger
  title: Packing
  sections:
    - title: null
      items:
        - {text: "socks", checked: false, note: null}
        - {text: "t-shirts", quantity: "5", checked: false, note: null}
        - {text: "charger", checked: false, note: null}
  notes: >-
    Case-insensitive merge keeps the first spelling. Quantities add (2 + 3). Open beats checked. Preview says "3 duplicates merged". If Packing already exists, this merges into it instead.

- id: L25
  shape: same item in two sections
  raw: |
    Gig
    Bag:
    - earplugs
    - charger
    Car:
    - charger
  title: Gig
  sections:
    - title: Bag
      items:
        - {text: "earplugs", checked: false, note: null}
        - {text: "charger", checked: false, note: null}
    - title: Car
      items:
        - {text: "charger", checked: false, note: null}
  notes: >-
    Different sections, so not a duplicate. Both kept.

- id: L26
  shape: single line, commas
  raw: |
    eggs, milk, bread
  title: null
  sections:
    - title: null
      items:
        - {text: "eggs", checked: false, note: null}
        - {text: "milk", checked: false, note: null}
        - {text: "bread", checked: false, note: null}
  notes: >-
    On the Lists shelf this is a new list of 3. Typed in the ghost row it is groceries (kitchen phrase row 4). The surface decides, not the text.

- id: L27
  shape: single line, commas and "and"
  raw: |
    socks, pants and t-shirts
  title: null
  sections:
    - title: null
      items:
        - {text: "socks", checked: false, note: null}
        - {text: "pants", checked: false, note: null}
        - {text: "t-shirts", checked: false, note: null}
  notes: >-
    Same splitter as TessGrammar.splitItems (" and " splits, "&" doesn't).

- id: L28
  shape: single line, quoted item with a comma
  raw: |
    "Paris, Texas", Heat, "Crouching Tiger, Hidden Dragon"
  title: null
  sections:
    - title: null
      items:
        - {text: "Paris, Texas", checked: false, note: null}
        - {text: "Heat", checked: false, note: null}
        - {text: "Crouching Tiger, Hidden Dragon", checked: false, note: null}
  notes: >-
    ASSUMED. Straight or curly quotes protect commas. Without quotes, "Paris, Texas" becomes two items; that is accepted.

- id: L29
  shape: recipe with Ingredients heading
  raw: |
    Lemon pasta
    Ingredients
    200g spaghetti
    1 lemon
    50g parmesan
    Method
    1. Boil the pasta.
    2. Toss with zest, juice and cheese.
  title: null
  sections: []
  notes: >-
    Flag, not a list. parsePastedRecipe matches the "Ingredients" line, so the result is the recipe ghost ("3 ingredients, 2 steps."), and no List is written.

- id: L30
  shape: recipe without a heading
  raw: |
    Serves 4
    1. Preheat the oven to 200C.
    2. Chop 2 onions and fry for 10 minutes.
    3. Add the beans and simmer for 20 minutes.
    4. Bake for 25 minutes.
  title: null
  sections:
    - title: null
      items:
        - {text: "Preheat the oven to 200C.", checked: false, note: null}
        - {text: "Chop 2 onions and fry for 10 minutes.", checked: false, note: null}
        - {text: "Add the beans and simmer for 20 minutes.", checked: false, note: null}
        - {text: "Bake for 25 minutes.", checked: false, note: null}
  notes: >-
    Flag in the preview ("Looks like a recipe. Make it a recipe?") because of "Serves", oven temperature and cooking verbs with minutes. ASSUMED heuristic. If kept as a list, "Serves 4" is dropped as a header line and step numbers are not quantities.

- id: L31
  shape: list mentioning ingredients
  raw: |
    Sunday
    - ingredients for dal
    - you will need to call Sam
  title: Sunday
  sections:
    - title: null
      items:
        - {text: "ingredients for dal", checked: false, note: null}
        - {text: "you will need to call Sam", checked: false, note: null}
  notes: >-
    Trap for the recipe regex. It needs a whole line of "Ingredients" or "You will need", so this stays a list.

- id: L32
  shape: markdown inline formatting and link
  raw: |
    Reading
    - [ ] **Piranesi**
    - [ ] _The Overstory_
    - [ ] [Stolen Focus](https://example.com/stolen-focus)
  title: Reading
  sections:
    - title: null
      items:
        - {text: "Piranesi", checked: false, note: null}
        - {text: "The Overstory", checked: false, note: null}
        - {text: "Stolen Focus", checked: false, note: "https://example.com/stolen-focus"}
  notes: >-
    Bold and italic markers stripped. The link URL becomes the item's note (slice 2). ASSUMED.

- id: L33
  shape: markdown rules, quotes and code
  raw: |
    Launch
    ---
    > - [ ] write post
    > - [ ] schedule tweet
    ---
    `npm publish`
  title: Launch
  sections:
    - title: null
      items:
        - {text: "write post", checked: false, note: null}
        - {text: "schedule tweet", checked: false, note: null}
        - {text: "npm publish", checked: false, note: null}
  notes: >-
    "---" lines dropped (not a heading underline here, since the next line is not text). "> " and backticks stripped.

- id: L34
  shape: numbered with checkboxes
  raw: |
    October
    1. [x] pay rent
    2. [ ] renew railcard
    3. [x] meter reading
  title: October
  sections:
    - title: null
      items:
        - {text: "pay rent", checked: true, note: null}
        - {text: "renew railcard", checked: false, note: null}
        - {text: "meter reading", checked: true, note: null}
  notes: >-
    Number then box, both stripped. Title "October" is not a date.

- id: L35
  shape: CRLF, trailing spaces, non-breaking spaces
  raw: |
    Gym bag
    - shorts
    - towel
    -  lock
  title: Gym bag
  sections:
    - title: null
      items:
        - {text: "shorts", checked: false, note: null}
        - {text: "towel", checked: false, note: null}
        - {text: "lock", checked: false, note: null}
  notes: >-
    The test feeds this with \r\n line ends, trailing spaces and a U+00A0 after the last dash. Same result as LF. "Gym bag" exists as a starter list, so this merges into it with no new items (all already there).

- id: L36
  shape: prose, not a list
  raw: |
    I need to sort out the car this week, call the bank about the card, and maybe fit in the gym if Thursday is quiet.
  title: null
  sections:
    - title: null
      items:
        - {text: "I need to sort out the car this week, call the bank about the card, and maybe fit in the gym if Thursday is quiet.", checked: false, note: null}
  notes: >-
    Flag ("Reads like a note. Keep as a note?"). ASSUMED rule - one line over 80 characters ending in a full stop is prose, so it is not comma-split. No task or date is made from "Thursday".

- id: L37
  shape: heading with no items
  raw: |
    Christmas
    Food:
    - turkey
    - sprouts
    Presents:
  title: Christmas
  sections:
    - title: Food
      items:
        - {text: "turkey", checked: false, note: null}
        - {text: "sprouts", checked: false, note: null}
  notes: >-
    The empty "Presents" section is dropped (sections live on items, so an empty one cannot be stored). Preview says nothing about it. ASSUMED.

- id: L38
  shape: items with dates
  raw: |
    Admin
    - [ ] renew passport 📅 2026-11-02
    - [ ] dentist form thu
  title: Admin
  sections:
    - title: null
      items:
        - {text: "renew passport", checked: false, note: null, date: "2026-11-02"}
        - {text: "dentist form thu", checked: false, note: null}
  notes: >-
    ASSUMED. Only an explicit ISO date (Obsidian Tasks "📅 YYYY-MM-DD" or a bare ISO at the end) becomes the item date (slice 2, reaches Today in slice 6). A spoken day like "thu" stays text, so a paste never guesses dates.

- id: L39
  shape: item with an indented note, into an existing list
  raw: |
    Packing
    - [ ] passport
        expires March, check before booking
    - [ ] sunscreen
  title: Packing
  sections:
    - title: null
      items:
        - {text: "passport", checked: false, note: "expires March, check before booking"}
        - {text: "sunscreen", checked: false, note: null}
  notes: >-
    The indented prose line is a note, not an item or section (rule 5). Packing exists, so this is AddListItems into it. passport already exists and is checked there, so it is unchecked and gains the note; sunscreen is added. One undo reverts both.

- id: L40
  shape: groceries title
  raw: |
    Groceries
    - oat milk
    - 2 lemons
    - [x] bread
  title: Groceries
  sections:
    - title: null
      items:
        - {text: "oat milk", checked: false, note: null}
        - {text: "lemons", quantity: "2", checked: false, note: null}
        - {text: "bread", checked: true, note: null}
  notes: >-
    Trap. Never a second "Groceries" list. Goes through AddGroceries, so items get aisles as sections (not shown above). A checked line on a grocery paste is skipped rather than added done. ASSUMED.
```

## Part 2: 60 list phrases

Context for every row unless noted: lists Groceries, Packing (reusable; open: charger, socks, sunscreen; checked: passport), Films, Books, Gym bag (reusable), Leaving the house (reusable), and a user list called **Bench**. Recipes: Spaghetti carbonara, Chilli con carne, Weeknight dal. Exercises: Bench Press, Back Squat, Deadlift. No workout entry in focus and the ghost row is on the shelf, unless the row says otherwise. Traps are marked **T**.

| # | Phrase | Domain | Action | Arguments | Trap |
|---|---|---|---|---|---|
| 1 | films: dune, past lives | lists | AddListItems | list Films, ["dune", "past lives"] | |
| 2 | books: piranesi | lists | AddListItem | Books, "piranesi" | |
| 3 | packing: sunscreen, 2 swimsuits | lists | AddListItems | Packing, ["sunscreen" (already open, no-op), "swimsuits" qty 2] | Merge rule: an open duplicate adds nothing |
| 4 | Packing - towel | lists | AddListItem | Packing, "towel" | ASSUMED: "Name - item" works like "Name: item" |
| 5 | add charger and adaptor to packing | lists | AddListItems | Packing, ["charger" (exists), "adaptor"] | |
| 6 | add passport to packing list | lists | CheckListItem | passport on Packing, done false | Already there, checked: re-adding unchecks it. Trailing "list" stripped |
| 7 | put towel on gym bag | lists | AddListItem | Gym bag, "towel" | ASSUMED "put X on/in Y" synonym |
| 8 | add "Dune: Part Two" to films | lists | AddListItem | Films, "Dune: Part Two" | Quotes keep the colon from reading as "Dune:" list |
| 9 | add sunscreen to goa | lists | none | Tess: "No list called Goa." | No list made silently |
| 10 | list: goa packing | lists | CreateList | "Goa packing" | |
| 11 | new list: books to read | lists | CreateList | "Books to read" | |
| 12 | run gym bag | lists | StartListRun | Gym bag | |
| 13 | start packing | lists | StartListRun | Packing | |
| 14 | run groceries | kitchen | StartShop | | Groceries' run is the shop |
| 15 | finish packing | lists | finish run | Packing (reusable, so reset) | |
| 16 | reset gym bag | lists | uncheck all | Gym bag | |
| 17 | reset films | lists | uncheck all | Films | Not reusable: reset is still slice 1 "uncheck everything" |
| 18 | clear done packing | lists | uncheck all | Packing | ClearDoneItems on a reusable list resets, never deletes |
| 19 | clear films | lists | ClearDoneItems | Films | |
| 20 | pick a film | lists | pick(from:) | Films | Singular "film" matches list "Films" |
| 21 | pick one from books | lists | pick(from:) | Books | |
| 22 | pick from packing | lists | pick(from:) | Packing | Never checks the picked item |
| 23 | copy packing for lisbon | lists | CopyList | Packing, name "Packing, Lisbon" | |
| 24 | copy gym bag | lists | CopyList | Gym bag, name "Gym bag, copy" | ASSUMED default name |
| 25 | check charger | lists | CheckListItem | charger on Packing, done true | Only one open "charger" across lists; ask if several |
| 26 | uncheck passport | lists | CheckListItem | passport on Packing, done false | |
| 27 | remove socks from packing | lists | DeleteObject | socks item on Packing | |
| 28 | rename films to watchlist | lists | RenameObject | Films → "Watchlist" | |
| 29 | archive books | lists | archive (slice 1) | Books | |
| 30 | what's left on packing | lists | read only | Tess: "Packing, 3 left." | No write |
| 31 | packing | lists | open list | Packing | **T** Bare name opens it; only the verb "pack" runs it (kitchen row 45) |
| 32 | lists | lists | open shelf | | |
| 33 | add squat to list | none | ask | Tess: "Which list?" | **T** Not a lift (no numbers), not a list named "list", no new list |
| 34 | add squat to gym bag | lists | AddListItem | Gym bag, "squat" | **T** Exercise name as plain text, no exercise link |
| 35 | pack list for goa | lists | CopyList | Packing, name "Packing, Goa" | **T** Starts with "pack" but is not a run (row 45); not a task (no day). ASSUMED reading |
| 36 | pack for goa sat | tasks | .task | "Pack for goa", Saturday | **T** A day makes it a task, not a run |
| 37 | milk | none | nothing | | **T** Grammar-only Tess makes nothing on the shelf; never guesses Packing |
| 38 | milk (ghost row on the Packing page) | lists | AddListItem | Packing, "milk" | **T** On a list page a bare item goes to that list, not groceries. ASSUMED |
| 39 | eggs, milk, bread (on the Packing page) | lists | AddListItems | Packing, 3 items | **T** Comma groceries rule yields to the open list page. ASSUMED |
| 40 | done 3 | none | nothing | Tess: "Done with what?" | **T** Not "check item 3", not 3 reps, not finish a run |
| 41 | 3 (Bench Press entry in focus) | training | .set | repsOnly, last weight | **T** On a list page with no entry: nothing, never item 3 |
| 42 | done (Packing running) | lists | finish run | Packing | **T** Only while a run is the Now process. ASSUMED |
| 43 | bench 80 x5 | training | .lift | Bench Press, 1 x 5 at 80 kg | **T** A list called Bench exists; lifts parse before lists |
| 44 | bench: 80kg plates, collars | lists | AddListItems | Bench, ["80 kg plates", "collars"] | **T** "Name:" prefix wins; no reps so not a lift |
| 45 | bench | lists | open list | Bench | **T** No numbers, so not a lift; opens the list, not the exercise |
| 46 | add bench press to push day | training | AddSlot | routine Push Day, Bench Press | **T** No list "Push day"; a routine of that name exists. ASSUMED routing |
| 47 | squat 100 5, deadlift 140 3 | training | .lift x2 | Back Squat 100x5, Deadlift 140x3 | **T** Risk on master: looksLikeGroceries sees "100" and "140" as amounts, so the comma rule may read this as groceries. Should be lifts or nothing |
| 48 | buy charger | kitchen | .groceries | ["charger"] | **T** "buy" always shops on master; Packing has charger but buy wins |
| 49 | get charger | none | nothing | | **T** "get" needs grocery-looking items; charger isn't, so no groceries and no list |
| 50 | add milk to packing | lists | AddListItem | Packing, "milk" | **T** A named list beats grocery-ness |
| 51 | add eggs and bread to groceries | kitchen | .groceries | ["eggs", "bread"] | Kitchen priority, AddGroceries not AddListItems |
| 52 | socks, charger, adaptor | none | nothing | | **T** Comma list that isn't groceries and names no list. Not a list either |
| 53 | run 5k thu | tasks | .task | "Run 5k", Thursday | **T** "run" with a day is a task, not StartListRun |
| 54 | run | lists | StartListRun | the list on screen; nothing on the shelf | **T** Never a training run. ASSUMED |
| 55 | pick up dry cleaning thu | tasks | .task | "Pick up dry cleaning", Thursday | **T** "pick up" is not pick(from:) |
| 56 | reset timer | none | nothing | | **T** No number so no timer; no list called Timer |
| 57 | list the bike on ebay sat | tasks | .task | "List the bike on ebay", Saturday | **T** "list" verb (code comment in TessGrammar+Kitchen) |
| 58 | note: add sunscreen to packing | notes | .note | "add sunscreen to packing" | **T** note: wins over everything |
| 59 | todo add charger to packing | tasks | .task | "Add charger to packing", Later | **T** todo prefix wins over list phrases |
| 60 | films: dune thu | lists | AddListItem | Films, "dune", date Thursday | **T** Day word with a "Name:" prefix dates the item (slice 2), not a task. ASSUMED |

30 rows are traps (marked **T**: 31, 33-50, 52-60), more than the 15 asked; about 15 of them cross domains (training, tasks, notes, kitchen).

## Proposed precedence for slice 8

Matches today's `TessGrammar.parse` order with list phrases slotted in:
note → pasted recipe → set in focus → lift → **"Name:" prefix for an existing non-grocery list** → kitchen (groceries, shop, timer, cook, `list:`) → **list verbs (add to, run, pick from, reset, copy, check)** → task → nothing.
"Name:" goes after lifts so "bench 80 x5" stays a lift, and before kitchen so "films: a, b" never turns into groceries. A list verb only fires when the named list exists; otherwise Tess says "No list called X."

## ASSUMED

- Apple Notes plain-text clipboard: checklist lines arrive with no marker (L05, L06) or with "◦" (L07), and checked state is lost. Not verified on device; check with `UIPasteboard.general.string` and the `public.html` flavour on iOS 27 and update L05 to L07. Tessera reads the plain-text flavour only.
- Title and section rules 1, 2, 5 and the blank-group rule; ALL CAPS sections become Title Case.
- New `TessGrammar.Parse` cases for slice 8: `.listItems(list:lines:)`, `.runList(list:)`, `.finishRun`, `.pick(list:)`, `.resetList(list:)`, `.copyList(list:name:)`, `.openList(list:)`, `.checkListItem(item:done:)`, `.renameList`, `.archiveList`, `.removeListItem`, `.listProgress(list:)`, `.askWhichList`. The engine action for reset is "uncheck all" from slice 1 (no name on master yet); finish-run follows `FinishShop`.
- Leading number is a quantity only with a unit, "x", or on Groceries (L11).
- Inline "Heading: a, b" splits (L14); quoted items keep commas (L28); emoji check boxes (L21); Markdown link URL goes to the note (L32); only ISO dates are read from a paste (L38).
- Duplicates merge with summed quantities; open beats checked (L24, L39, rows 3, 6).
- A grocery-titled paste goes through `AddGroceries` and skips checked lines (L40).
- Recipe and prose flags without an Ingredients heading (L30, L36) are preview heuristics, not hard rules.
- On a list page, a bare item or comma list goes to that list (rows 38, 39); "run" and "done" act on the list on screen or the running list (rows 42, 54).
- "pack list for X" means copy Packing (row 35); copy default name "Name, copy" (row 24); "Name - item" equals "Name: item" (row 4); "add X to push day" goes to a routine when no such list exists (row 46).
