# Exercise pictures and the About page (Design item 109)

Kaushik, Oct 19 5:30 PM PT (Product ruling, decisions.md): the free Workout Guide line art (Everkinetic, CC BY-SA 4.0) replaces our drawn animations. He allowed colour depth and size to change. Research's mapping: 72 seeds, 57 same name, 15 siblings (#1139). Built in #1140.

## The picture
- Frames: three per exercise, played 1, 2, 3, 2. Each frame holds 0.55 s; a 150 ms ease between frames, through MotionPolicy. A loop is 2.2 s.
- Colour: one flat ink colour (the theme's `ink`), drawn as a template image so the files stay untouched. No gradient, no tint per muscle, no shadow, nothing soft. On a dark look the same token turns light.
- Size: 240 pt high in the long-press sheet, centred, scaled to fit, never cropped. At accessibility text sizes it stays 240 pt and the sheet scrolls.
- Reduce Motion: the middle frame holds still. Low Power: 2 frames (1 and 3) with the same 150 ms ease; no other change.
- VoiceOver: the picture is hidden (the title and the figure pair carry the meaning).
- A sibling motion (15 of 72, marked in the manifest) shows one quiet line "Similar motion" in `inkSecondary`, 16, under the picture. Never a different name.
- Private workout: the picture shows as normal (it is a movement, not a value); only the figure is the plain outline.
- If a richer picture set goes in front later (the Gym visual GIFs, at no more than their 180 px source until the smoother set lands), it follows the same size, colour and Reduce Motion rules; a GIF that cannot take the ink colour sits on a flat ink-tinted ground with a hard edge, not a card.
- Never: our own drawn figures, a second style on the same screen, a caption of the source on the exercise page.

## About page (foot of Settings)
- Position: the last row of Settings, the word "About" in `inkSecondary`, 44 pt high. It opens a plain page: the title "About" in the page title role, then one line per source, 21 pt body, ink, with a `labelWord` link row (16, `inkSecondary`) under each line.
- One line per source:
  - Exercise pictures: "Exercise pictures: Workout Guide by Bryl Lim (bryllim.com), CC BY-SA 4.0. Artwork by Everkinetic / Greg Priday, CC BY-SA 4.0. Changes: recolored and resized." Links: Workout Guide, Everkinetic, CC BY-SA 4.0.
  - Calorie estimates: the Compendium 2024 line (Research owns the wording).
  - Reference library: one line per dataset (Product owns the list).
- No cards, no pills, no icons. The back word "Settings" at the top left, 44 pt, as on other pages. VoiceOver: each line is one element; links read as links.
- Gate (Product): a build never ships without the licence kept on the pictures and both credits on this page.
