# Theme names, the switch, and where the choice lives

For: Design (names, Settings copy), Builder A (ThemeStore, widgets, Live Activity), Core (backups). Research lab, board item 63, 2026-10-16.
Checked against `docs/design/themes.md` on `origin/claude/project-thread-b3tu3f` at **8ac2e99** (sheet plus both addenda), `theme-checks.md`, `themes-token-audit.md`, `tess-voice.md`, `settings-claude.md`, and master at **ee5a3e1** (`DesignSystem/Theme.swift`, `TesseraBackup.swift`, `BackupKeeper.swift`, `Shared/RestActivityAttributes.swift`, `project.yml`, `App/Tessera.entitlements`).

## What master has today

- `Theme.concept` is a static var hard-coded to `.plein` (Theme.swift:240). Only `-theme <name>` changes it. **No look is saved anywhere.**
- `UserDefaults.standard` holds only BackupKeeper's folder bookmark and failures, and TesseraSchema's launch note. There is no `@AppStorage`.
- No App Group: the entitlements file asks only for HealthKit. The widget extension (`com.kaushikaranagu.tessera.widgets`) holds only `RestLiveActivity`; there are no Home Screen widgets yet.
- A `.tessera` backup is a SQLite copy of the store plus a one-row `backupInfo` table (format, version, createdAt, appVersion). Nothing in UserDefaults rides along.
- There is no Settings screen on master yet (as `settings-claude.md` found), so LOOK needs a home there when Settings is built.

## The five names

Keep all five of Design's names. Each is a real material or a painter's word, says what the ground is, and reads as one bold value word in a sentence. They also sit well together: three are crafted surfaces (porcelain, celadon glaze, lacquer), one is natural glass, and one is how the app was first painted.

| Name | Mode | One line (VoiceOver hint, preview caption) |
|---|---|---|
| **Porcelain** | light, default by day | Pure white. Colour pools only behind what matters now. |
| **Obsidian** | dark, default by night | True black. Colour turns to light and glows. |
| **Plein** | light | Warm paper with soft washes and grain, painted outdoors. |
| **Lacquer** | dark | Plum black with one slow sheen that moves as you tilt. |
| **Celadon** | light | Pale green glaze that pools darker at the foot of the page. |

- **Plein is the only weak one**, and only by ear: VoiceOver may say it like "plain", which turns "Plein by day" into nonsense. Keep the name (it is Kaushik's approved look, and `PleinGround` already carries it). Give the word an accessibility pronunciation (`speechPhoneticRepresentation`, said "plen"). If that still sounds wrong on his phone, the fallback is **Vellum** (warm writing skin, same cream ground), not a two-word "Plein Air", which would break the one-word value pattern.
- The user-facing word is **look**, never "theme", to match the spec's `Look` and the label.

## The switch (Settings, LOOK)

The label is LOOK (Label 16/700, uppercase). Under it, one sentence with value words, as the rest of Settings. No buttons, no list of swatches.

| State | Sentence (bold = value word) | Line under it (Body, `inkSecondary`) |
|---|---|---|
| Following light and dark (default) | **Porcelain** by day, **Obsidian** by night. | Hold a name to keep it day and night. |
| Pinned | **Obsidian** always. | Hold it again to follow light and dark mode. |
| Existing install after this build | **Plein** by day, **Obsidian** by night. | Hold a name to keep it day and night. |

- **Tap a name:** it moves to the next look of its kind. Day: Porcelain, Plein, Celadon, then back. Night: Obsidian, Lacquer, then back. Each tap floods the new ground in from Tess's soul (PaintFlood 700 ms; 250 ms crossfade under Reduce Motion) with a selection haptic.
  - Tapping the night word in daytime changes the word only; the page doesn't flood, because the night look isn't showing. The word itself gets a dab in its ground so he sees what he picked.
- **The pin:** holding a name keeps that one look day and night, whatever the phone's appearance. The sentence folds to "**Obsidian** always." with a firmer haptic.
  - Holding the pinned name again unpins. The sentence unfolds with the pinned look back in its own slot and the other slot as it was before the pin.
  - Tapping the pinned name moves through all five looks (light and dark), because a pin isn't tied to day or night.
- **No Tess line and no UNDO.** A look isn't a record, tapping again goes back, and the flood is the answer. This fits the voice guide's "silence is fine" and the undo rule (UNDO only reverts a record its line names).
- **VoiceOver:** each name is adjustable (swipe up or down cycles). Label "Day look", value "Porcelain", hint is the one-liner above. Custom action "Keep Porcelain day and night", or when pinned "Follow light and dark mode", because a hold alone isn't reachable.
- `-theme <name>` (DEBUG) pins in memory only and never writes the saved choice, so a demo recording can't change his phone.

## Live Activity and widgets, per look

| Surface | Porcelain | Obsidian | Plein | Lacquer | Celadon |
|---|---|---|---|---|---|
| Lock Screen Live Activity ground (`activityBackgroundTint`) | #14111A | #000000 | #1C1828 | #0C0812 | #0E1C17 |
| Live Activity text | Workout `ink` and `inkSecondary` (72%), never `inkTertiary` | same | same | same | same |
| Timer, Finish/UNDO keyline | `rest` #F0A500, `signal` #FF5B3A | #FFC23D, #FF5B3A | #E8BD4C, #D9563F | #E8B54A, #F06A4C | #E2A93A, #EE7056 |
| Dynamic Island | Obsidian workout set, every look | same | same | same | same |
| Home Screen widget | white ground, ink, pigments, no bloom | black, no halo glow | cream, no washes or grain | plum, no band | celadon, no pool |
| Removable background (StandBy, clear or tinted) | night look's ink and pigments | same | same | same | same |
| Lock Screen accessory | opacity tiers only; done a filled dab, open a ring | same | same | same | same |

- The Live Activity is dark in every look, so the look only shifts its temperature. The rest sky is `Workout.tess` at 35% plus `context` at 45%, as the addendum says.
- It follows on its next update, and widgets on their next timeline, as the spec says. A look change calls `WidgetCenter.shared.reloadAllTimelines()` once, after the flood settles.

## Where the choice is stored, and backups

**Recommendation:**
1. **The live choice lives in App Group UserDefaults**: suite `group.com.kaushikaranagu.tessera`, keys `look.day`, `look.night`, `look.pinned` (a look name or nil). It is read synchronously before the first frame, so there's no flash of the wrong ground. Widgets read the same suite.
   - App Groups on the free Personal Team are UNVERIFIED. Confirm with one build, as `widget-states.md` C11 already asks. If Xcode refuses, use `UserDefaults.standard` and widgets draw Porcelain by day, Obsidian by night.
2. **Not the object store.** A look is a phone preference, not a thing he links or looks back on. As an object it would add op-log rows on every tap and need the store open before the first frame.
3. **It still rides in backups**, through `backupInfo`. Add nullable `lookDay`, `lookNight` and `lookPinned` columns, passed into `TesseraBackup.write` like `appVersion`, so TesseraCore stays free of UI. The copy a restore keeps (`write(fromStoreAt:)`) carries the current look too, so restoring that copy brings back the look as well. Older backups have no columns; read them as nil.
4. **On restore**, apply the backup's look only when this phone's look has never been changed (no saved keys). That covers a reinstall after free signing expires, which wipes UserDefaults and the App Group. If he has chosen a look on this phone since, his choice stays. The JSON export doesn't carry the look.
5. **The Live Activity** gets both names in `ContentState` (`lookDay` and `lookNight`, the same name twice when pinned) rather than one `look`. The extension then picks by the Lock Screen's colour scheme. It still needs no App Group.
6. **First launch default:** nothing saved, so Porcelain by day, Obsidian by night, not pinned. Keys are written only when he changes something.

## Contradictions, with a proposed default

| # | What disagrees | Sources | Default |
|---|---|---|---|
| T1 | "Persist the choice in `UserDefaults`", yet widgets draw the theme's ground, which the extension can't read from standard defaults | themes.md step 3 vs "Live Activities and widgets" | App Group suite (above). Standard defaults only if the free team refuses App Groups |
| T2 | "Anyone already on Plein keeps Plein by day", but master never saved a look | themes.md "Switching" vs Theme.swift:240 | Decided 7:20 PM PT (coordinator): no carry-over. Every install, his included, starts at Porcelain by day, Obsidian by night; he can pin Plein. No one-time migration rule |
| T3 | Removable backgrounds use "the night look's ink", but a pinned light look makes the night look Porcelain, which puts dark ink on black | second addendum vs the pin | Use the night look if it's dark, else Obsidian's ink and pigments |
| T4 | One `look` in `ContentState`, but with the auto pair the look depends on light and dark, which can change with no app update | themes.md step 6, addendum | Send `lookDay` and `lookNight`; the extension picks by colour scheme |
| T5 | The pin is a hold, but a hold isn't reachable with VoiceOver or Switch Control, and there's no on-screen hint | themes.md "Switching" | The hint line under the sentence, plus a custom accessibility action |
| T6 | What a tap on a pinned name cycles through is unstated | themes.md "Switching" | All five looks |
| T7 | Backups carry the whole store but not the look, so a restore after a reinstall loses it | TesseraBackup vs themes.md (silent) | `backupInfo` columns. A restore applies them only when this phone's look is untouched |
| T8 | `-theme <name>` "still pins one" could overwrite the saved choice | themes.md "Switching" | In memory only, never saved |

## Open, for Kaushik or Design

1. Plein's spoken name: keep "Plein" with a pronunciation, or rename to Vellum? Default: keep it.
2. Should a restore ever change a look he has picked on this phone? Default: no.
3. Closed (7:20 PM PT): his phone moves to Porcelain by day, Obsidian by night on update, since he asked for white as his likely default; Plein stays one hold away.
