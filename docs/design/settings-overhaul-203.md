# 203 Settings overhaul
Kaushik 8:47 AM PT Oct 23 (cmsg_01VTPva3JGXrfvetgUvAWE7M9ekdB2HcqRUMfvroQ2k5DR). Board: https://claude.ai/artifact/Sm2gKa3mJFAmaGoF356b9K. Replaces the Review facet pages and settingsV2.

## Rules
1. On by default: everything approved, asked for or recommended ships On. Builder B is already flipping the defaults.
2. The main page is one line per preference, written as a sentence, with its value right-aligned in ink 2. Tap a line and its choices open in place as words (the chosen one is underlined at 1 pt, 5 pt offset), with an optional ink 3 "why" line under them. Lines with no choices open their own page.
3. Conflicts are one choice, not two switches. Where two features do the same job: Home is Mosaic or Home v2; Pages turn by Slide, Turn, Rotate or Today; Reading layout (folded into Pages). Choosing one turns the other off.
4. Developer mode is only for turning things off. Hold the build line for 700 ms, or press Enter with VoiceOver or a keyboard. It lists every feature flag grouped by app, all On; one tap turns a flag Off and another brings it back. Tools: Sample data (simulator only, via LaunchFlags), Class inspector, Recent changes. It never adds features.
5. The way in: "Settings" at the top right of every page, in ink 2, beside a 16 pt knob made of 9 screen pixels (3x3 minus the centre ring) that turns 90° with a spring when pressed and once a minute on its own (none with Reduce Motion). On Home, a pull down from the top 40 pt edge also opens it. The page arrives with the pixel flip (sheet 202: a right-to-left sweep, 7 ms per column + 1.6 ms per row + hash × 60 ms, 300 ms per tile); Reduce Motion is a 150 ms crossfade.

## The main page (about 20 lines, from 65 switches)
- You: Weights in lb/kg; Week starts on Monday/Sunday; Quiet hours (page); The day turns over at (page).
- Home: The day on Home Lively/Calm/Still (Still = colors, no motion); Apps list under Next Off/On; Home is Mosaic/Home v2.
- Tess: Tess asks Claude Off/On (value in Tess cobalt; why line "Only with your key, and never your health, calendar, body, money or private words"; the key keeps its own page and is never shown or echoed); Tess has eyes; Tess names training days.
- Training: Rest timer; Swap an exercise with Two taps/One tap; Nudge if I forget Finish; Calories burned (stays on the phone).
- Kitchen: The cook timer speaks; Hands-free while cooking.
- Privacy: Words that stay private (page); Lock Screen shows Masked/Titles (Titles shows ordinary titles only; private and walled things stay masked whatever is chosen); Health (page, Not connected); Calendar (page).
- Look: Pages turn by; Font.
- Safe keeping: Backups (page, last time); Undo, everything you did (op-log page).
- About: "Tessera, build N. Hold for Developer mode."
- Every change gets the one Undo (Tess's line at the bottom).

## Developer mode groups
Home, Training, Kitchen, Notes and lists, Tasks and routines, Money, Everywhere: every ReviewChoices flag not on the main page, by app. Keep ids; ReviewChoices.facets becomes the Developer grouping.

## Lanes
- Builder B: the page, the line component, inline choices, the conflict rows, Developer mode, the entry with its knob, and the pull-down.
- Builder A: the pixel flip page transition (reusing 202's flip) and the knob's pixel drawing and spring.
- Core: a FeatureFlags map with all approved flags defaulting On, a migration that sets stored Off values left from defaults to On once (his rule), keeping any Off he set by hand after Oct 23 8:47 AM PT, and the conflict pairs as exclusive choices.
- Never: the Claude key, money values or health data on this page; no cards or pills; sentence case; 44 pt targets.
