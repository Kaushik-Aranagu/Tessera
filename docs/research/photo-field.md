# Photo field: storing pictures as objects

For: Core engine. Research lab, 2026-10-15.
Reads with: `capture-modes.md` (§5 privacy, "storing photos needs a file field kind"), `free-signing-survival.md` (§3 `.tessera` backup, §4 slice), `tess-model-layer.md` §6 (context pack), `context-packing.md` (Home, not Claude; nothing here changes it).

**Recommendation in one line.** Add a `photo` field kind whose value is a small reference (content hash, type, size, pixels), keep the bytes as content-addressed files in `Application Support/Tessera/media/`, never delete a file while anything (an object, a soft-deleted object, or the op log inside a 30-day grace) still points at it, and keep every photo out of every Claude context pack with a guard that throws.

**What exists on origin/master (`8863357`).** `FieldKind` (`TesseraCore/Sources/TesseraCore/Model/FieldValue.swift:4`) has text, number, bool, date, duration, mass, choice, ref, refList, classRef, computed, richText. `FieldValue` (`:32`) has 8 scalar cases. `FieldValues` keeps any value it can't decode verbatim, so an older build that meets a new case keeps it untouched. `Op.setValue(object:field:old:new:)` (`Actions/Op.swift:28`) already stores old and new values, so undo of a photo change is free once the value is a reference. `TesseraExport` (`Export/TesseraExport.swift`) is lossless JSON of classes, objects, links and ops; values travel as `FieldValue`. The store folder is set in `Model/TesseraSchema.swift:21`. There is no `TesseraBackup`, no media folder and no `TessContextPack` on master yet (the pack is planned in `tess-model-layer.md` §6).

## 1. The field and its value

- `FieldKind.photo`: one photo per field. A gallery is a `refList` to child `Photo` objects later, not a list value.
- `FieldValue.photo(PhotoRef)` with `PhotoRef { hash: String (SHA-256 hex of the stored bytes), type: String (UTType id, "public.heic"), bytes: Int, width: Int, height: Int, takenAt: Date? }`. About 150 bytes of JSON. No image data ever goes in the value or the database.
- Not a PhotoKit `localIdentifier`. Without library access `PhotosPickerItem.itemIdentifier` is nil, and the original can be deleted from Photos anyway. The hash is the id.
- `numericValue` and `stringValue` return nil for `.photo`, so formulas and text search skip it. `ClassResolver` validation: a `.photo` value only in a `.photo` field.
- Dedupe comes free: the same picture picked twice is one file, two references.

## 2. Storage beside the database

- Originals: `Application Support/Tessera/media/<first 2 hex>/<hash>.<ext>` (256 shard folders keep listings fast). Application Support is in the device backup, which is what we want for originals.
- Thumbnails: `Library/Caches/Tessera/thumbs/<hash>-s.jpg` and `-l.jpg`. They are derived, so they sit in Caches, out of backups, and are rebuilt on a miss.
- Write order: write to a temp file in `media/`, hash it, rename to the final name (atomic, same volume), then perform the op. A crash between the two leaves an orphan file, which the collector removes. A crash before the rename leaves only a temp file, cleared at launch.
- `MediaStore` (Core, no UI) owns the folder: `ingest(Data) throws -> PhotoRef`, `url(for:)`, `thumbnail(for:size:)`, `collect(...)`. Nothing else touches the folder, the same rule as `ObjectStore` for the database.

## 3. Thumbnails with ImageIO

- Two sizes: **small 240 px** long edge (an 80 pt row at 3x) and **large 1200 px** (a 400 pt object page at 3x). Full size only in the zoom view, loaded from the original.
- `CGImageSourceCreateThumbnailAtIndex` with `kCGImageSourceThumbnailMaxPixelSize` (240 or 1200), `kCGImageSourceCreateThumbnailFromImageAlways` true (so the small embedded HEIC thumbnail is never upscaled), `kCGImageSourceCreateThumbnailWithTransform` true (applies EXIF orientation), `kCGImageSourceShouldCacheImmediately` true (decode now, off the main actor). Open the source with `kCGImageSourceShouldCache` false so the full image is never decoded. Apple: without the max size key "thumbnails may be as big as the image itself".
- Encode thumbs as JPEG at quality 0.8 through `CGImageDestination`, with no metadata. Make both at ingest; rebuild lazily on a cache miss.

## 4. HEIC, re-encoding and GPS

- Pick with `preferredItemEncoding: .current` so Photos hands over its HEIC as is, not a transcoded JPEG. Load with `loadTransferable(type: Data.self)` (SwiftUI `Image` only reads PNG and JPEG, per the PhotosPicker docs).
- **Keep the original bytes** when the type is HEIC, JPEG or PNG and it is under the limits in §5. Only the metadata is rewritten: `CGImageDestinationCopyImageSource` copies the image without re-encoding, with `kCGImageMetadataShouldExcludeGPS` true. Hash after stripping, so the same picture always hashes the same.
- **Re-encode to HEIC** (`kCGImageDestinationLossyCompressionQuality` 0.8, `kCGImageDestinationImageMaxPixelSize` 4096, GPS excluded) for anything else: ProRAW or DNG, TIFF, GIF stills, WebP, and anything over the limits.
- **Strip GPS by default.** A per-field switch "Keep location" (off) for a class where place matters (a hike). Apple notes the GPS flag "doesn't filter any proprietary location data in the manufacturer's EXIF MakerNote or in custom XMP properties", so with the switch off also pass `kCGImageMetadataShouldExcludeXMP` and drop `{MakerApple}`; test it on a real iPhone HEIC.
- Live Photos: the still only. Depth and gain map: keep the gain map (`kCGImageDestinationPreserveGainMap`) when copying, drop depth.

## 5. Size limits

- Per photo: **12 MB and 48 MP** for a kept original (a 48 MP iPhone HEIC is about 5 to 8 MB, measure). Over either: re-encode as in §4 to 4096 px, which lands near 1 to 3 MB. If the result is still over 12 MB (a corrupt or hostile file), refuse with "That photo is too large to keep." and change nothing.
- Undecodable data (not an image, zero pixels): refuse with "That file isn't a photo." before any op.
- Whole library: no hard cap. Object page footer and the backup screen show "212 photos, 640 MB". Above 2 GB the backup screen suggests the "without photos" copy (§7).

## 6. Delete with undo and the grace period

- Removing a photo is `setValue(old: .photo(ref), new: nil)`; deleting the object is `softDelete`. Neither touches files. Undo replays the inverse op, the value comes back, the file is still there.
- **Collector** (`MediaStore.collect(context:now:grace:)`, at launch, off the main actor, at most once a day): live set = every `.photo` ref in any object's values (soft-deleted objects included, since they can be restored) plus every ref in `old` or `new` of a `setValue` op newer than `now - grace`. A file not in the live set is first marked (an `unreferencedSince` date in a small `media.json` index, or the file's own date), and deleted only when it has been unreferenced for **30 days**. Temp files older than a day go at once.
- After the grace an old op may still name a hash with no file. Undo then restores the reference and the UI shows "Photo no longer on this phone" in place of the image. Never crash, never drop the value.
- Purging soft-deleted objects (a later trash feature) only removes rows; the collector takes the files 30 days later.

## 7. Export, backup and restore

- **JSON `TesseraExport`:** carries refs only (`FieldValue.photo` encodes as data, not bytes). Add a top-level `media: [{hash, type, bytes}]` list so a reader knows what is missing. Bump `currentVersion` to 2; version 1 files still read.
- **`.tessera` backup** (the SQLite snapshot from `free-signing-survival.md` §3) stays a plain SQLite file. Its `backupInfo` row gains `mediaIncluded`, `mediaCount`, `mediaBytes`.
- **Rolling daily copies:** database only, plus an incremental mirror of `media/` into the same picked folder (`Backups/media/`). Content-addressed names mean a file is copied once and never rewritten, so a daily run copies only new photos.
- **Manual "Save a copy":** `Tessera-YYYY-MM-DD.tesseraarchive`, an Apple Archive (`ArchiveStream.encodeStream`, `writeDirectoryContents`) holding `tessera.sqlite` and `media/`. Use no compression (HEIC and JPEG are already compressed). iOS has no public zip API; Apple Archive is Apple's own format and framework. When media is over 2 GB, the default is the plain `.tessera` file with the note "Photos not included: 212 photos, 2.4 GB. Use the backup folder for those."
- **Restore:** inspect as today, stage the database, and stage each media file into `media/` only if its SHA-256 matches its name (a bad file is skipped, not trusted). Refs with no file show the placeholder. Launch note: "Restored. 209 of 212 photos; 3 were not in the copy." A later restore of the same backup folder fills the gaps, because names are hashes.

## 8. Keeping photos out of every Claude context pack

- **Rule:** no photo bytes, thumbnails, file paths or hashes ever enter a `TessContextPack`, for every use (plan my day, question, paste, capture). The pack may say a field exists ("Meal has a photo field") but never a value. The same pack feeds on-device Foundation Models in v1, so the rule covers both.
- **Guard, layer 1 (types):** the pack builder turns values into `PackValue`, whose init returns nil for `.photo`. There is no other path from `FieldValue` into a pack.
- **Guard, layer 2 (bytes):** `ContextPackGuard.check(_ data: Data)` runs on the final encoded request just before the network client sends it. It throws `photoLeak` if it finds the string `media/`, `data:image`, a base64 image start (`/9j/` JPEG, `iVBOR` PNG, `AAAAGGZ0eXBoZWlj` HEIC), or any 64-hex string that is a hash in `MediaStore`. On throw: nothing is sent, Tess falls back to the on-device or grammar path, and a debug log line names the use.
- **Image to Claude** (the later opt-in in `capture-modes.md` §5) would need a separate, explicit per-image call that bypasses the pack. Not in scope.

## 9. Picking: PhotosPicker and the camera

- **PhotosPicker** (`matching: .images`, `preferredItemEncoding: .current`, no `photoLibrary:` argument). It runs out of process and needs **no photo library permission and no Info.plist key**. Apple, WWDC20 session 10652: the picker "doesn't need direct access to the photos library to show the picker and the picker won't prompt for access on behalf of the app", and "please don't prompt for photo library access before showing the picker". Only what he selects reaches the app. If the picked photo is in iCloud only, loading can fail offline (the docs name this case): "That photo is still in iCloud. Try again online."
- **Camera:** `UIImagePickerController` with `sourceType = .camera`, wrapped for SwiftUI, after `isSourceTypeAvailable(.camera)` (false in the simulator). Needs `NSCameraUsageDescription` in `project.yml` ("Tessera uses the camera to add photos to your objects."). No entitlement. The shot is not saved to Photos, so no add-only permission either. The `UIImage` from the camera is encoded to HEIC by `MediaStore.ingest`. Receipts and pages keep VisionKit's document camera (capture-modes slice 2).
- The view part (field cell, zoom, picker glyph) is Builder B's, through `tessera-design`; this note is Core only.

## 10. Smallest Core slice

`TesseraCore/Sources/TesseraCore/Media/MediaStore.swift` and `PhotoRef.swift` (about 250 lines), plus the `FieldKind.photo` and `FieldValue.photo` cases. Export media list, archive and the pack guard follow as slices 2 and 3. Done when these Swift Testing cases pass in `swift test`:

1. `photoValueRoundTrips`: an object with a `.photo` field saves, reloads and exports to JSON with the same `PhotoRef`; the database row holds no image bytes (row size under 1 KB).
2. `ingestIsContentAddressed`: the same HEIC ingested twice gives one file, one hash, two refs; the file name equals the SHA-256 of its bytes.
3. `ingestStripsGPS`: a fixture HEIC with GPS comes out with no `{GPS}` dictionary, with pixels unchanged (not re-encoded) and the type still HEIC.
4. `oversizeIsReencodedOrRefused`: a 60 MP fixture comes out at 4096 px HEIC under 12 MB; a non-image throws `notAPhoto` and logs no op.
5. `thumbnailsHaveTwoSizes`: small is 240 px and large 1200 px on the long edge, orientation applied (a rotated EXIF fixture comes out upright).
6. `undoAfterDeleteRestoresPhoto`: remove the photo, run the collector, undo; the value and the file are both back.
7. `collectorHonoursGrace`: an unreferenced file survives `collect` at day 29 and is gone at day 31; a file referenced by a soft-deleted object is never collected.
8. `olderBuildKeepsPhotoValue`: a `FieldValues` blob with a `.photo` entry decoded by the old decoder lands in `unreadable` and is written back unchanged.
9. (Slice 3) `contextPackHasNoPhotos`: a store seeded with photo fields builds every pack use, and `ContextPackGuard.check` passes with no hash, path or image bytes inside; feeding the guard a pack with `/9j/` or a known hash throws `photoLeak`.

## Verification (developer.apple.com, 2026-10-15)

- Verified: `PhotosPicker` and `PhotosPickerItem` (iOS 16+): `preferredItemEncoding`, `loadTransferable(type:)`, `itemIdentifier`, iCloud download failure; SwiftUI `Image` reads only PNG and JPEG. No-permission behaviour verified from the WWDC20 10652 transcript (auto-generated).
- Verified: `kCGImageSourceThumbnailMaxPixelSize` and `CGImageSourceCreateThumbnailAtIndex`; `CGImageDestination` keys `kCGImageDestinationLossyCompressionQuality`, `kCGImageDestinationImageMaxPixelSize`, `kCGImageDestinationPreserveGainMap`, `kCGImageMetadataShouldExcludeGPS` (default false, MakerNote not filtered), `kCGImageMetadataShouldExcludeXMP`.
- Verified: `UIImagePickerController` `.camera` source and `isSourceTypeAvailable`; Apple Archive directory compression (`writeDirectoryContents`, `.aar`).
- Unverified: that `CGImageDestinationCopyImageSource` honours the GPS key without re-encoding HEIC (check in Xcode and test 3); the `NSCameraUsageDescription` page did not render; HEIC sizes and timings above are estimates to measure on the phone.

Sources: [PhotosPicker](https://developer.apple.com/documentation/photosui/photospicker), [PhotosPickerItem](https://developer.apple.com/documentation/photosui/photospickeritem), [WWDC20 10652 Meet the new Photos picker](https://developer.apple.com/wwdc20/10652), [kCGImageSourceThumbnailMaxPixelSize](https://developer.apple.com/documentation/imageio/kcgimagesourcethumbnailmaxpixelsize), [CGImageDestination](https://developer.apple.com/documentation/imageio/cgimagedestination), [kCGImageMetadataShouldExcludeGPS](https://developer.apple.com/documentation/imageio/kcgimagemetadatashouldexcludegps), [UIImagePickerController](https://developer.apple.com/documentation/uikit/uiimagepickercontroller), [Compressing file system directories](https://developer.apple.com/documentation/accelerate/compressing-file-system-directories).
