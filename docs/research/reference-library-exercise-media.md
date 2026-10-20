# Tessera exercise media and MET: candidate sources (DRAFT)

Date: 2026-10-19. Scope: bundled, offline "how it is done" clip or stills, equipment picture, and per-exercise
calories (MET) for a closed-source iPhone app. Docs only; nothing downloaded to the repo, nothing committed.

## Research limits (read first)
- Reachable: github.com pages and raw.githubusercontent.com only. api.github.com repo endpoints, github.com
  issues and search pages returned 403 (session allow-list), so repo total size, issue threads and GitHub search
  could not be read. pacompendium.com, gymvisual.com, wikimedia and kaggle failed DNS (getaddrinfo ENOTFOUND).
- Anything marked "search excerpt" came from a web search snippet, not a primary page. Rule applied: not read on a
  primary page -> UNVERIFIED -> not BUNDLE.
- Sizes below are measured from a 25-file random sample of raw HEAD content-length, extrapolated. Treat as +/-15%.

## Verdict rule
BUNDLE only for public domain/CC0, CC-BY, MIT/Unlicense-style where the licence demonstrably covers the media.
SKIP share-alike, GPL/AGPL, non-commercial, unclear provenance, paid API.

## 1. free-exercise-db (yuhonas)
- URL: https://github.com/yuhonas/free-exercise-db
- Licence (read from LICENSE.md in the repo, and README badge "License: Unlicense"): "This is free and
  unencumbered software released into the public domain. Anyone is free to copy, modify, publish, use, compile,
  sell, or distribute this software, either in source code form or as a compiled binary, for any purpose,
  commercial or non-commercial, and by any means." The README title line says "Open Public Domain Exercise Dataset".
- Data: dist/exercises.json (1.0 MB) has 876 exercises. Fields: id, name, force, level, mechanic, equipment,
  primaryMuscles, secondaryMuscles, instructions[], category, images[]. Equipment mix: barbell 170, dumbbell 123,
  other 122, body only 111, cable 81, machine 67, kettlebells 56, bands 20, none 77.
- Coverage of our list (name match in the JSON): Barbell_Bench_Press_-_Medium_Grip, Barbell_Squat, Barbell_Deadlift,
  Bent_Over_Barbell_Row, Pullups, Barbell_Curl, Close-Grip_Front_Lat_Pulldown (and Full_Range-Of-Motion_Lat_Pulldown),
  Leg_Press, Standing_Military_Press / Seated_Barbell_Military_Press (no entry named "overhead press"). All nine
  common lifts have a usable entry.
- Images: 1,746 JPEG stills (about 2 per exercise: 0.jpg start, 1.jpg end position; README: 2,620 files, 874
  folders). Sample average 58 KB each (62,771 B / 72,816 B / 72,823 B for Air_Bike, Barbell_Bench_Press, Barbell_Squat)
  -> about 100 MB total uncompressed in the repo. Not clips; two photo frames, which can be cross-faded in app.
- Provenance concern (the blocker): the README credits "Ollie Jennings for the original dataset at exercises.json
  (wrkout/exercises.json)" and says nothing about who shot or drew the photos. wrkout/exercises.json is itself
  Unlicense (LICENSE.md read) and its README points to a commercial dataset "wrkout.xyz" with "10,000+ images" and
  "3,500+ videos", which suggests the media is a commercial product's content. No CREDITS/ATTRIBUTION file exists in
  either repo (404). An Unlicense on a repo does not make it true for photos the owner may not have authored.
  Issue threads could not be read (403), so any image-licensing complaint is unchecked.
- Verdict: DATA = BUNDLE (Unlicense read on primary page; we already plan to write the library in our own words,
  so we only need taxonomy ideas). IMAGES = SKIP / UNVERIFIED provenance until the original photographer is
  identified. Do not ship them.

## 2. Other GitHub-hosted media candidates

### hasaneyldrm/exercises-dataset
- URL: https://github.com/hasaneyldrm/exercises-dataset
- Content: 1,324 exercises, each with an animation GIF and a 180x180 thumbnail, 10 languages, equipment/target/muscle.
  GIF sample: 124,389 B (barbell bench press) -> roughly 150-165 MB for all GIFs. data/exercises.json 17 MB.
- Coverage: README thumbnails show barbell bench press, full squat, deadlift, pull-up, biceps curl, so the common
  nine are likely present (not individually checked).
- Licence (quoted from LICENSE): "MIT License ... The MIT license above covers ONLY the code, tooling, dataset
  structure, and instruction text/translations in this repository. It DOES NOT cover the exercise media in the
  images/ and videos/ directories. That media is (c) Gym visual (https://gymvisual.com/) and is included here with
  the rights holder's written permission, at 180x180 resolution, and must retain the attribution ... Its use and
  reuse are governed by Gym visual's Terms & Conditions ... NOT by the MIT license above. Cloning this repository
  does not grant you any license to the media; obtain your own from Gym visual." NOTICE.md repeats this.
- Verdict: media SKIP (proprietary, permission applies to this repo only; Gym visual terms page unreachable, so
  UNVERIFIED). Instruction text is MIT, but we write our own cues. If Kaushik wants this look, the legal path is
  buying a licence from Gym visual, which is a paid source and outside the brief.

### omercotkd/exercises-gifs
- URL: https://github.com/omercotkd/exercises-gifs
- Licence: LICENSE is MIT (c) omercotkd, but README says "I do not own any of the content in this repository. All
  rights belong to the original creators and dataset owner." It is a backup host of GIFs from a Kaggle dataset
  (edoardoba/fitness-exercises-with-animations), i.e. the ExerciseDB-style GIFs.
- Verdict: SKIP (unclear provenance; the MIT file does not cover content the owner says he does not own).

### Already in sources-draft.md, unchanged
- wger (data per-entry Creative Commons, may be share-alike): SKIP. ExerciseDB API (AGPL, media terms unclear):
  SKIP. Liftosaur: SKIP.

### Search result
A web search for open exercise GIF/animation sets with CC0/MIT/Unlicense found only the three above plus
commercial products (ExerciseDB on Gumroad, RepDB, WorkoutLabs, ProTrainUp: all paid or custom terms). No
licence-clean GIF/clip set was found. GitHub search itself was blocked, so a networked pass may still find one.

## 3. Equipment images
- Nothing licence-clean was found or readable. The free-exercise-db photos double as equipment pictures but are
  SKIP above.
- Wikimedia Commons (no GitHub mirror known): UNVERIFIED. Check from a networked Mac: Category:Exercise equipment
  and Category:Weight training equipment on commons.wikimedia.org; keep only files tagged CC0 or Public domain
  (CC-BY needs an in-app credit; CC-BY-SA is out). Record file page URL and licence per image.
- Our own option: the catalog has 9 equipment kinds (barbell, dumbbell, ezBar, cable, machine, smith, kettlebell,
  bodyweight, band). Drawing nine SVG/SF-Symbol-style pictures in the Tessera look costs no licence risk, matches
  the "no stock screens" principle, and is the lowest-risk pick for the equipment picture.

## 4. MET values
**Update (Core read the Compendium page on a networked Mac, Oct 19; plain reading, not legal advice):** free to use
commercially on three conditions: do not change MET values, do not combine activities with different MET levels,
and cite the Compendium. There is no app-specific terms page. Consequences (Product to rule): drop the two-tier
3.5 / 6.0 table below, because one table for many exercises would combine levels; use the unchanged Compendium
value for each activity, mapped per exercise (a code per exercise or movement), with the citation in the library's
notes and an About line. We do not email the Compendium for now (outside messages need Kaushik). The notes below
were written before this read and are kept for history; where they say UNVERIFIED or two-tier, this update wins.
- Compendium of Physical Activities (Arizona State University), site pacompendium.com. Licence/terms: NOT read
  (DNS failure). No GitHub-hosted copy or repo citing it with a licence was found. A search excerpt mentions a
  CC BY-NC-ND licence on a repository page for the Older Adult Compendium paper only; that is a different
  work and not confirmed for the main data. Treat the Compendium table as UNVERIFIED, copyright status unknown.
- What can be quoted (search excerpts of the 2024 adult compendium PDF and tracking guide, not primary reads):
  code 02054 "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" = 3.5 METs;
  code 02050 (vigorous-effort weight lifting, power lifting, body building) = 6.0 METs. The excerpt cut the 02050
  description; recalled from the 2011 edition, not verified here, it reads "weight lifting, free weight, nautilus
  or universal, power lifting or body building, vigorous effort" = 6.0, and 02052 light/moderate = 3.5.
  So 3.5 (light/moderate) and 6.0 (vigorous) match the brief.
- Method note: kcal = MET x body-mass-kg x hours. A single resistance code makes every exercise the same
  intensity, so per-exercise calories differ only by duration and bodyweight. Per-exercise METs would need us to
  invent a mapping from the 3.5 / 6.0 tiers (heavy compound sets -> 6.0, isolation/machine -> 3.5), which is our
  own heuristic, to be labelled "estimate".
- Licence-clean fallback: facts (MET numbers) are generally not copyrightable, but the Compendium compilation
  and its terms are unread. Safest path: ship a tiny table of our own (two tiers plus cardio rows) with a
  "based on the Compendium of Physical Activities (Ainsworth et al.)" citation, after Core confirms the terms.
  Citations (from memory/excerpts, unverified): Ainsworth et al., Med Sci Sports Exerc 2000 (PubMed 10993420);
  Herrmann et al., J Sport Health Sci 2024 (2024 update).

## 5. Our catalog (read-only grep of the repo)
- Note: "catalog v9" is the SystemCatalog package (SystemCatalog.swift: CatalogPackage id "system", version 9).
  The exercise library is a separate package, ExerciseLibraryInstaller: id "library", version 1.
- Exercise seeds in ExerciseLibrary.swift: 72 (grep of top-level ExerciseSeed( entries). Each seed has: id, name,
  aliases, movement pattern (10 patterns), family, equipment (EquipmentKind, 9 kinds), mechanic, primary and
  secondary muscles (18 muscles in MuscleSeed), rep range, rest seconds, a one-line cue. Installed as objects
  with links to Muscle and Equipment objects. So yes: equipment and muscles are both listed.
- Coverage: free-exercise-db (876) would cover all 72 in principle, but we need media for only 72 exercises
  (about 144 stills, roughly 8 MB, if it were licence-clean) - small enough that commissioning or drawing our
  own is realistic.

## Recommendation
1. Data: keep our own library (72 seeds, own words). Optionally mine free-exercise-db JSON (Unlicense) for
   missing exercises/muscle tags, never copy its images.
2. Clip/animation: no licence-clean set found. Do not bundle any third-party GIF or photo today. Best path: an
   in-app generated animation per movement pattern (10 patterns, 9 equipment kinds), drawn in SwiftUI/Canvas as a
   simple figure-and-bar motion with muscles highlighted. It is original work, tiny, scales on any device, and fits
   the UI-invention principle. Ship text cue + muscle highlight first, animation per pattern second.
3. Equipment picture: draw 9 own icons/illustrations. Commons CC0 images only after a manual check.
4. MET: the unchanged Compendium value for each activity, mapped per exercise (never a combined two-tier table), with the
   Compendium cited in the library's notes and an About line (see the update at the top of section 4).

## Open checks (from a networked Mac)
1. Done 2026-10-20 (Core, Mac): terms and the 2024 rows for all 9 codes used are read and confirmed (see
   reference-library-met-mapping.md). Still open for later seeds: cardio codes (rowing, running, cycling).
2. Read https://gymvisual.com/content/3-terms-and-conditions-of-use, and decide if a paid licence is wanted (out of
   brief).
3. Identify the original author of the wrkout / free-exercise-db photos; read open issues on both repos about image
   rights (github.com/yuhonas/free-exercise-db/issues, github.com/wrkout/exercises.json/issues). Until a
   photographer with a free licence is named, images stay SKIP.
4. GitHub search for CC0/CC-BY exercise illustration repos (queries: exercise illustrations svg, exercise
   animation lottie, workout pictograms) and Wikimedia Commons categories in section 3.
5. Get real total repo size for free-exercise-db (GitHub repo page "Size", or git clone --depth 1 once) if images
   ever become eligible; my estimate is about 100 MB.
