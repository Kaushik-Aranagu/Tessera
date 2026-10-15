# People: the names, the person page and @ in the editors (M5 screens 7, 6 and 8, steer)

For Builder B, after Core's People slices (ship-list-m5-people). It is drawn to `no-buttons.md`. Recording: `recordings/people.mp4` (source `studies/people.html`).

Shared: people never run, so there's no vermilion, and cobalt is only for Tess. There are no avatars or circles, no red, no "overdue", and no counts of who you haven't seen.

## 7 · The People page (names as running text)
- **Label:** PEOPLE.
- **One paragraph of names** at Title 34/500, 48pt lines, with a 16pt gap between names (no commas or dots), most recently talked first. Each name taps through to its page.
- **People never mentioned** sit at the end at 400 weight and 50% ink. **Nobody fades for being quiet**: a name is full ink however long ago you talked.
- **A birthday within 14 days** hangs in the right margin beside the line holding that name, in Body ("Mum, Sun").
- **Arrival:** names set in one by one, like a sentence being written (12pt rise, 380ms, 40ms per name).
- **New person:** say it ("@Priya"). **Empty:** Tess says "Tell me who you talked to. Try: met Sam."

## 6 · The person page (tap a name)
- **The name grows in place into the hero:** from 34 at its spot in the paragraph to 56 at (20, 100) over 480ms (ease-out cubic), while the paragraph blurs back.
- **Context line in Body:** "talked Tue · birthday **12 Mar**". The birthday is a value word.
- **Mentions as one margin timeline:**
  - A month label ("OCTOBER"), then day numerals at 34 Light in the left margin and the line at 21 from x 84, 64pt apart.
  - The person's name is set in weight (650) inside the line.
  - Contact lines ("Call Sam about the flat", "Called Sam", "Lunch with Sam") are full ink. Plain mentions are a step lighter (62%).
  - Tapping a line opens its note or task (z).
- **The birthday drum:** tap the date, and the timeline moves down 160pt as a day drum and a month drum (56 Light, 60pt rows, masked) open in place under the context line. The date in the context line follows live. On release the drums fold back into the words (`SetBirthday`), and Tess says "Sam's birthday, 14 Mar."
- **One level deeper** (swipe up): aliases as value words, and delete as a swipe with UNDO.
- **Empty timeline:** "Mention @Sam in a note or task and it shows here." in Body at 62%.

## 8 · @ in the editors
- **Typing @ lifts one line of names** above the keyboard (21, 10pt rise, 260ms), with a hairline under it. There's no sheet and no list.
  - People come first, then other objects, by recent use. The best match is ink at 600 and the rest are subdued. The line fades out at the right edge where it runs off.
  - It filters as you type ("@Pr" gives "Priya · Pasta night · Piranesi").
  - An unknown name shows "Priyanka (new person)" in the same line.
- **Tap a name:** the line fades, and the mention sets inline in weight (650) with a short focus-in (blur 2pt to 0, 260ms). It stays ink, never cobalt.
- **Long-press a mention** to show which object it is, which settles ties like Rosemary the herb and Rosemary the person.

## Accessibility and Reduce Motion
- The names paragraph reads as a list of links: "Sam, talked Tuesday". A margin birthday is read with its name: "Mum, birthday Sunday".
- The birthday drums are adjustable elements: "Day 14", "Month March".
- **Reduce Motion:** the hero cross-fades instead of growing, names and lines fade in place, and the drums open without the timeline sliding.
