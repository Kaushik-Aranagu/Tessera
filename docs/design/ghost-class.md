# Build A4: the ghost class page (steer)

For the builder of A4 (`../product/ship-list-build.md`), after A1 to A3. It is drawn to `no-buttons.md` and the Tess capture. Recording: `recordings/ghost-class.mp4` (source `studies/ghost-class.html`).

**The idea:** "I want to track my plants" doesn't open a form or a summary card. It shows **the class's own future page, drawn as a wet cobalt ghost.** The person changes what they like on the page itself, and one tap makes it real.

## From the sentence to the ghost
- **The sentence** arrives through Tess (Write or Speak). On Return it lifts away, and Tess thinks: her three dabs pulse in turn, and her line says "Drawing what a plant has…".
- **The ghost page assembles top-down.** Each line paints in left to right (clip from the left, 8pt rise, 420ms, 70ms stagger), in cobalt at 62% with a slow wet breath (opacity 0.78 ↔ 1, 1.8s). The page sits where the class page will live, in the normal page layout.
  - **Breadcrumb label:** the parent path, "THING / PLANT".
  - **Hero:** the class name in the plural, "Plants", at 56.
  - **"WHAT A PLANT HAS"** (label), then one row per proposed field at 21, 40pt apart: the field name in 600, " · ", and its **kind word** as a value word ("text", "choice: low, bright, direct", "date", "number, cm"). Inherited fields aren't repeated.
  - **"SAMPLES, NOT SAVED"** (label), then 2 or 3 sample objects as single lines at 42% cobalt ("Monstera · kitchen · bright"). These are preview-only and never written.
  - **A routed object, when there is one,** as a sentence: "And a chore: **Water plants**, every **7** days."
- **The actions:** "Make Plants" is a stroke word on a cobalt brushstroke (one **tap**: schema is a bigger write, so there's no hold and no auto-commit). **NOT NOW** is a label word on the right and discards the whole proposal. Tess says "Here's Plants. Change anything, then make it."

## Changing the ghost before it's real
- **Tap a kind word** to cycle it (the add-a-field rule). Choices read their options off the samples ("text" becomes "choice: kitchen, hall, balcony"). It blurs out and in (120ms out, 220ms in), and nothing is committed.
- **Swipe a field left** to drop it from the pending record: it follows the finger and fades, and everything below closes up 40pt on the settle spring `cubic-bezier(.3,1.3,.5,1)`.
- **Tap the hero** to rename it in place (the writing line, as in Write).
- Saying more to Tess ("and when I bought it") re-proposes, and the new rows paint in where they belong.

## Make it
- **On the tap:** the stroke wets (scaleY 1.65, 420ms). The actions and the samples fade, with the samples blurring out because they were never saved.
- **The page dries from cobalt into ink top-down** (520ms per line, 60ms stagger): labels go to the subdued colour, and the hero, rows and chore sentence go to ink.
- **The empty state** fades in where the samples were: "No plants yet. Say "monstera, kitchen"." The chore sentence moves up under it.
- Tess's soul swells once (×1.25, 900ms), and she says "Made Plants, and a chore to water them." with UNDO. **UNDO removes the whole op group**: class, fields, view and chore.
- There's no `.success`. The page itself is the result.

## Rules
- No form, no cards, no list of checkboxes, no confirmation dialog. The preview is the real page in ghost ink.
- Cobalt is Tess's, so the ghost is cobalt and the made page is ink. Nothing on it is vermilion until something runs.
- When Tess picks `useExisting`, there's no ghost: the existing class page opens, and Tess says "You already have Plants."
- When she picks `proposeList`, the ghost is the List page in the same style.

## Accessibility and Reduce Motion
- The ghost page reads with a prefix: "Proposed class Plants, not saved yet". Each field reads "Spot, text, adjustable", with drop as a custom action. "Make Plants" and "Not now" are buttons.
- **Reduce Motion:** lines fade in whole instead of painting, the dry is a single cross-fade, and the close-up after a drop is immediate.
