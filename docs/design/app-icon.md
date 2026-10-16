# The app icon (Design item 39)

Kaushik asked for a real icon with "Tess" on it (11:23 PM PT). **A, recommended: Tess's soul is the icon,** drawn exactly as the app draws her, with the same three pigments in the same places and the same blur, scaled 14 times. It has no letter, badge or glyph. B is the one strong alternative: the page.
- Board: `mockups/app-icon.png` (source `studies/app-icon.html`). It shows A and B by day, by night and tinted, each on a Home Screen, and A and B at every size from 180px to 29px. The other icons on the Home Screens are neutral blanks, so the board borrows no other app's mark.
- Masters: `docs/design/icon/` (copies in `/mnt/project-files/tessera/design/icon/`).

## A: the soul
- **By day (Any):** Porcelain ground, a vertical gradient from `#FFFFFF` to `#F5F1EA`. Tess in her Porcelain pigments: cobalt `#2450D8`, vermilion `#E2432A` and cadmium `#F0A500`.
- **By night (Dark):** Obsidian black `#000`, with her Obsidian pigments: `#86B4FF`, `#FF5B3A` and `#FFC23D`.
- **Her glow:** one wide wash of each pigment sits behind her at 13% (day) or 22% (night). It's how she lights when she speaks, so the icon reads as light, not as three dots.
- **Tinted:** grayscale on black, with no glow, so iOS's tint carries it.
- **Geometry:** her 46 × 40 box at 14× (644 × 560 on the 1024 canvas). It's centred on the blobs' own extent, 28px right of the box centre, and stays inside the system's safe circle. The blur is 1.2pt × 14 = 17px.
- **Why A:**
  - She is the one thing on every screen, and the one thing he's said he likes and must never change.
  - It's distinctive at 29px: three warm points of light read on any wallpaper, light or dark.
  - It carries no text, so it never fights the label under it.

## B: the page (the alternative)
The icon is a small Tessera screen: one ink line (the ink-line lens, 520 wide), with Tess in her corner at 8.4×, on Porcelain or Obsidian. It tells the story of the app's language (ink actions, the soul in the corner), but the line thins out below 60px. That's why A leads.

## Files for Builder A
| File | Use |
|---|---|
| `icon/tessera-icon-1024.png` | Any (light), 1024 × 1024, opaque RGB, full bleed. The system rounds the corners |
| `icon/tessera-icon-dark-1024.png` | Dark, opaque on Obsidian black |
| `icon/tessera-icon-tinted-1024.png` | Tinted, grayscale, opaque on black |
| `icon/tessera-icon-dark-clear-1024.png`, `icon/tessera-icon-tinted-clear-1024.png` | The same on transparent, for when Xcode's dark or tinted slot wants the system's own background (use these if the build warns about the opaque ones) |
| `icon/layers/` | For Icon Composer: `bg-light.png`, `bg-dark.png`, and each blob on its own transparent layer (`cobalt`, `vermilion`, `cadmium`, plus `-dark`). Three foreground layers let the system's glass give her depth between the pigments |
| `icon/alt-page/` | B's three masters, only if Kaushik picks B |

**Wiring (Builder A):**
1. Add `Resources/Assets.xcassets/AppIcon.appiconset/` with the three PNGs and this `Contents.json`:
   ```json
   {"images":[
     {"filename":"tessera-icon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"},
     {"appearances":[{"appearance":"luminosity","value":"dark"}],"filename":"tessera-icon-dark-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"},
     {"appearances":[{"appearance":"luminosity","value":"tinted"}],"filename":"tessera-icon-tinted-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],
    "info":{"author":"xcode","version":1}}
   ```
2. Set `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` in `project.yml` (it's `""` today, line 68), then run `xcodegen generate`.
3. If Kaushik wants the Liquid Glass layering, build an Icon Composer file from `icon/layers/` on the Mac: background, then cobalt, vermilion and cadmium as three layers, with default, dark and tinted appearances. The asset catalog stays as the fallback.
4. The bundle id and team don't change, so this installs over the app like any re-sign.

## Never
- A letter "T", the word "Tess", a badge or a glyph on the icon.
- Changing her shape, colours or blur to suit the icon.
- A gradient sky behind her: Cobalt sky belongs to the Live Activity.
- A different icon per look. The icon follows the system's light and dark only.

## Owners
- **Builder A:** the asset catalog, `project.yml` and the Icon Composer file.
- **Kaushik:** A or B. A is the default unless he says otherwise.
