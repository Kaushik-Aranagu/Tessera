# The shell and the content (sheet 283 v5, Oct 25)

Kaushik, 4:21 PM PDT: "The UI bubbles or layout elements themselves stay on the page. It's the content inside
it that is changing... I want the whole screen to stay there, and the whole rendering part of the things should
take care of what kind of stuff is going to next come and where in what app we are in and maintain all the
status. So the UI part of it should be its own thing, and the contract or the communication between them should
be taken care of or we should define it." 4:22 PM: bubbles merge and change between layouts, with nice
animations.

Board: https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp (version 5). Places and frames: `landings-283.md` v4.

## Three layers

1. **Shell (UI).** One persistent view per place: Masthead (Title, Nav word, Switcher, Needs), Keystone,
   Caption, Widget (with Glyph), Dial, Door summary, Action word, Tess. Places are created once at launch and
   never torn down. A place knows its frame, its own transition, and how it takes touches. It knows nothing
   about rooms or data.
2. **Content.** Each room (and each door page) answers one question: for this route and this state, what goes
   in each place? It returns `SlotContent` per place, or `nil`. `nil` means the place is empty but kept: it
   stays in the layout, shows nothing and takes no touches.
3. **Navigator.** Owns the route stack and each room's state: switcher index, widget index, dial focus,
   keystone page, scroll offset. Back pops the route and restores that state exactly, so every place returns
   to what it showed before.

The shell never asks the content anything except through this contract; content never reaches into a view.

## The contract

```swift
enum Place: CaseIterable { case title, navWord, switcher, needs, doorTitle,
  keystone, caption, widget, glyph, dial, doorSummary, page, actionWord, tess }

enum LayoutKind { case landing, door }          // level 0 and level 1 (more later)

struct SlotContent: Identifiable, Equatable {
  let id: ContentID       // identity: same id on both sides means "nothing changed"
  let kind: SlotKind      // .text, .wall, .pass, .board, .sky, .woods, .indices, .list, .dial, .glyph ...
  let payload: SlotPayload
}

struct Screen { let layout: LayoutKind; let slots: [Place: SlotContent?] }

protocol RoomContent { func screen(for route: Route, state: RoomState) -> Screen }
```

The shell holds the current `Screen`. On every route change it receives the next one and diffs it place by
place.

## Diff rules, per place

| Old vs new | What the place does |
|---|---|
| Same `id` | Nothing. This is how the keystone stays put when a door opens (the Galley rail keeps its tickets). |
| Same `kind`, new `id` | The place's own move: masthead flap, caption unroll, widget up and out then up and in, dial reel (fast through both lists, slows onto the new doors), summary off right and in from right, action word letters stream. |
| Different `kind` | The old content collapses to a point (or dissolves with blur for a keystone) and the new one forms from it. Never a hard cut. |
| `nil` to content, or content to `nil` | Only the half that exists plays. |

## Layout to layout: merges and splits

When `layout` changes, places themselves move before content does. The board's table:

| Level 1 place | Made from (level 0) |
|---|---|
| Door title | Switcher + Needs |
| Page | Widget + Glyph + the breath at 612 + Dial + Door summary + the breath at 760 |

- Places that exist in both layouts glide from the old frame to the new one (frame and corner radius together).
- A merge: each source place flows into the target's rect and fades as the target appears.
- A split: the sources start from the merged place's rect and spread to their own frames.
- A place with no partner fades in or out where it stands.
- Content leaves before a merge starts and arrives after a split ends, so text is never stretched.

## Timing and input

- One clock per change. The whole change ends within 1 s (the dial reel is the longest at 980 ms).
- Reduce Motion: every place does a 150 ms crossfade; merges and splits jump to the end frame.
- Animate only through `MotionPolicy` (`withTesseraAnimation`).
- A place takes touches once its own entry finishes. A new route during a change wins: the shell retargets
  from the current presentation values, it does not queue.

## SwiftUI sketch

- The root is a `ZStack` of fixed-frame `PlaceHost` views, one per `Place`, positioned from the layout table.
  No `NavigationStack` push for landings or door pages.
- `PlaceHost` renders `SlotContent` with `.id(content.id)` and a per-place `.transition`, so SwiftUI's own
  insertion and removal drive the swaps.
- Layout changes animate the frames with `matchedGeometryEffect` (namespace per merge group) so merging
  places share geometry.
- The navigator is an `@Observable` object; rooms conform to `RoomContent` and stay free of view code.
