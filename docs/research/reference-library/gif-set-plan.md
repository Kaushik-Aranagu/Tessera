# GIF set plan: moving exercise pictures from the Gym visual set, mapped to our 72 seeds

Date: 2026-10-20. Status: PLAN for Product, Core and Builder A. Docs only; no media was added to the repo.
Decision: Kaushik chose this set on 2026-10-20 ("this is what I'm looking for") and said he handles the licensing.
Workout Guide (workout-guide-asset-plan.md) stays as the fallback for any seed this set lacks.

## The set
github.com/hasaneyldrm/exercises-dataset: 1,324 exercises, each with a 180x180 animation GIF (folder videos/), a
180x180 thumbnail, and metadata in data/exercises.json (name, body_part, equipment, target, muscle_group,
secondary_muscles, instructions in 10 languages). Code and data are MIT. The media is NOT MIT: it belongs to Gym
visual (gymvisual.com), redistributed with their permission at 180x180 only, and every use must carry
"(c) Gym visual - https://gymvisual.com/". Their terms are at gymvisual.com/content/3-terms-and-conditions-of-use
and the repo's NOTICE.md says cloning the repo is not a license and you may need your own from Gym visual.
Kaushik takes responsibility for the licensing. Each record in exercises.json carries the attribution field.

## Limits that stay (set by the terms, not by Research)
- 180x180 is the maximum size; never upscale. Display at 180 points or smaller.
- Keep the credit "(c) Gym visual - https://gymvisual.com/" wherever the pictures are credited; put it on the About
  page at the foot of Settings (Product ruling: no credits on exercise pages). Product should recheck, because the
  NOTICE says every use must carry the credit.
- Files stay OUT of the git repo until Kaushik says the license is sorted. Builder A downloads them on the Mac into a
  git-ignored folder and bundles them at build time. Bundled read-only, no runtime fetch, never to Claude, never in
  backups, export or the op log.
- No second-person build without the license and credit in place.

## Mapping: all 72 seeds
59 seeds use the same exercise, 12 use a sibling (same motion, different grip, equipment or angle), and 1 is a gap
that falls back to Workout Guide. Every GIF name was checked against data/exercises.json and every file downloaded
(71 GIFs, 6.9 MB total, measured). "id" is the dataset id and the file is videos/<file>.

| Our exercise | GIF set name | Match | id | Target muscle (their label) | File or fallback |
|---|---|---|---|---|---|
| Bench Press | barbell bench press | same | 0025 | pectorals | 0025-EIeI8Vf.gif |
| Incline Bench Press | barbell incline bench press | same | 0047 | pectorals | 0047-3TZduzM.gif |
| Close-Grip Bench Press | barbell close-grip bench press | same | 0030 | triceps | 0030-J6Dx1Mu.gif |
| Dumbbell Bench Press | dumbbell bench press | same | 0289 | pectorals | 0289-SpYC0Kp.gif |
| Incline Dumbbell Press | dumbbell incline bench press | same | 0314 | pectorals | 0314-ns0SIbU.gif |
| Machine Chest Press | lever chest press | same | 0576 | pectorals | 0576-DOoWcnA.gif |
| Push-Up | push-up | same | 0662 | pectorals | 0662-I4hDWkc.gif |
| Dip | chest dip | same | 0251 | pectorals | 0251-9WTm7dq.gif |
| Cable Fly | cable middle fly | sibling | 0188 | pectorals | 0188-xLYSdtg.gif |
| Pec Deck | lever seated fly | same | 0596 | pectorals | 0596-v3xmPAR.gif |
| Overhead Press | barbell seated overhead press | sibling | 0091 | delts | 0091-kTbSH9h.gif |
| Seated Dumbbell Shoulder Press | dumbbell seated shoulder press | same | 0405 | delts | 0405-znQUdHY.gif |
| Machine Shoulder Press | lever shoulder press | same | 0603 | delts | 0603-67n3r98.gif |
| Dumbbell Lateral Raise | dumbbell lateral raise | same | 0334 | delts | 0334-DsgkuIt.gif |
| Cable Lateral Raise | cable lateral raise | same | 0178 | delts | 0178-goJ6ezq.gif |
| Barbell Row | barbell bent over row | same | 0027 | upper back | 0027-eZyBC3j.gif |
| One-Arm Dumbbell Row | dumbbell one arm bent-over row | same | 0292 | upper back | 0292-C0MA9bC.gif |
| Seated Cable Row | cable seated row | same | 0861 | upper back | 0861-fUBheHs.gif |
| Chest-Supported Row | lever bent over row | sibling | 0574 | upper back | 0574-X3cqyXz.gif |
| T-Bar Row | lever t bar row | same | 0606 | upper back | 0606-aaXr7ld.gif |
| Face Pull | (none) | gap | - | - | Workout Guide: face-pull |
| Reverse Pec Deck | lever seated reverse fly | same | 0602 | delts | 0602-myfUsKf.gif |
| Pull-Up | pull-up | same | 0652 | lats | 0652-lBDjFxJ.gif |
| Chin-Up | chin-up | same | 1326 | lats | 1326-T2mxWqc.gif |
| Assisted Pull-Up | assisted pull-up | same | 0017 | lats | 0017-kiJ4Z2K.gif |
| Lat Pulldown | cable lat pulldown full range of motion | same | 2330 | lats | 2330-LEprlgG.gif |
| Close-Grip Pulldown | twin handle parallel grip lat pulldown | sibling | 0818 | lats | 0818-rkg41Fb.gif |
| Straight-Arm Pulldown | cable straight arm pulldown | same | 0238 | lats | 0238-x69MAlq.gif |
| Back Squat | barbell full squat | same | 0043 | glutes | 0043-qXTaZnJ.gif |
| Front Squat | barbell front squat | same | 0042 | glutes | 0042-zG0zs85.gif |
| Goblet Squat | dumbbell goblet squat | same | 1760 | quads | 1760-yn8yg1r.gif |
| Hack Squat | sled hack squat | same | 0743 | glutes | 0743-Qa55kX1.gif |
| Leg Press | sled 45 deg leg press (side pov) | same | 1463 | glutes | 1463-2Qh2J1e.gif |
| Smith Machine Squat | smith squat | same | 0770 | glutes | 0770-jFtipLl.gif |
| Bulgarian Split Squat | dumbbell single leg split squat | sibling | 0410 | quads | 0410-qx4fgX7.gif |
| Walking Lunge | walking lunge | same | 1460 | glutes | 1460-IZVHb27.gif |
| Reverse Lunge | barbell rear lunge | sibling | 0078 | glutes | 0078-VaP75jl.gif |
| Step-Up | dumbbell step-up | same | 0431 | glutes | 0431-aXtJhlg.gif |
| Deadlift | barbell deadlift | same | 0032 | glutes | 0032-ila4NZS.gif |
| Sumo Deadlift | barbell sumo deadlift | same | 0117 | glutes | 0117-KgI0tqW.gif |
| Romanian Deadlift | barbell romanian deadlift | same | 0085 | glutes | 0085-wQ2c4XD.gif |
| Dumbbell Romanian Deadlift | dumbbell romanian deadlift | same | 1459 | glutes | 1459-rR0LJzx.gif |
| Good Morning | barbell good morning | same | 0044 | hamstrings | 0044-XlZ4lAC.gif |
| Kettlebell Swing | kettlebell swing | same | 0549 | glutes | 0549-UHJlbu3.gif |
| Hip Thrust | barbell glute bridge | sibling | 1409 | glutes | 1409-qKBpF7I.gif |
| Back Extension | lever back extension | same | 0573 | spine | 0573-rUXfn3R.gif |
| Cable Pull-Through | cable pull through (with rope) | same | 0196 | glutes | 0196-OM46QHm.gif |
| Leg Extension | lever leg extension | same | 0585 | quads | 0585-my33uHU.gif |
| Lying Leg Curl | lever lying leg curl | same | 0586 | hamstrings | 0586-17lJ1kr.gif |
| Seated Leg Curl | lever seated leg curl | same | 0599 | hamstrings | 0599-Zg3XY7P.gif |
| Hip Adduction | lever seated hip adduction | same | 0598 | adductors | 0598-oHsrypV.gif |
| Hip Abduction | lever seated hip abduction | same | 0597 | abductors | 0597-CHpahtl.gif |
| Standing Calf Raise | barbell standing calf raise | sibling | 1372 | calves | 1372-8ozhUIZ.gif |
| Seated Calf Raise | barbell seated calf raise | sibling | 1371 | calves | 1371-ipvgBnC.gif |
| Barbell Curl | barbell curl | same | 0031 | biceps | 0031-25GPyDY.gif |
| Dumbbell Curl | dumbbell biceps curl | same | 0294 | biceps | 0294-NbVPDMW.gif |
| Hammer Curl | dumbbell hammer curl | same | 0313 | biceps | 0313-slDvUAU.gif |
| Incline Dumbbell Curl | dumbbell incline curl | same | 0318 | biceps | 0318-ae9UoXQ.gif |
| Preacher Curl | barbell preacher curl | same | 0070 | biceps | 0070-qOgPVf6.gif |
| Cable Curl | cable curl | same | 0868 | biceps | 0868-G08RZcQ.gif |
| Rope Pushdown | cable pushdown (with rope attachment) | same | 0200 | triceps | 0200-dU605di.gif |
| Overhead Cable Extension | cable overhead triceps extension (rope attachment) | same | 0194 | triceps | 0194-2IxROQ1.gif |
| Skull Crusher | barbell lying triceps extension skull crusher | same | 0060 | triceps | 0060-h8LFzo9.gif |
| Dumbbell Overhead Extension | dumbbell seated reverse grip one arm overhead tricep extension | sibling | 1738 | triceps | 1738-5fKX7wi.gif |
| Barbell Shrug | barbell shrug | same | 0095 | traps | 0095-dG7tG5y.gif |
| Dumbbell Shrug | dumbbell shrug | same | 0406 | traps | 0406-NJzBsGJ.gif |
| Plank | weighted front plank | sibling | 2135 | abs | 2135-VBAWRPG.gif |
| Ab Wheel Rollout | wheel rollerout | same | 0857 | abs | 0857-NAgVB3t.gif |
| Hanging Leg Raise | hanging leg raise | same | 0472 | abs | 0472-I3tsCnC.gif |
| Cable Crunch | cable kneeling crunch | same | 0175 | abs | 0175-WW95auq.gif |
| Pallof Press | band horizontal pallof press | sibling | 0979 | abs | 0979-9pa4H5m.gif |
| Farmer's Carry | farmers walk | same | 2133 | quads | 2133-qPEzJjA.gif |

Note: "Hack Squat" and "Leg Press" use sled-machine GIFs; the leg press one is the side-pov take. Cable Fly uses the
middle-fly GIF. Plank uses the weighted front plank GIF. Check the siblings by eye on the phone; Core or Design may
swap a pick for another entry of the same name family in exercises.json.

## Cutout steps (white to clear, ink swap, 180 max)
Tested on the bench press GIF (12 frames, 1 s per frame, pure white ground, black figure with red muscle shading):
1. Read each frame as RGB. Alpha = 255 minus the lowest of red, green and blue. Pixels with alpha under 6 become
   fully clear. Un-premultiply the color against white so edges keep their color: c = (c - 255*(1-k)) / k, with
   k = alpha/255.
2. Save as an animated PNG, loop forever, disposal 2 (clear before the next frame), original frame time.
3. Light-ink version for dark grounds: any pixel whose red, green and blue are within 25 of each other (the black
   and gray body lines) becomes (236, 236, 232) with its alpha kept; the red shading stays red.
4. Keep the output at 180x180. Use the cream or pale-blue ground for the black version.
Sample: the published cutout page for the bench press. Size note: the cutout PNG for one GIF was 212 KB against
124 KB for the GIF, so 71 cutouts would be about 15 MB; an animated WebP would be smaller. Builder A decides the
format and may do the keying at build time on the Mac rather than commit the result.

## Gap
Face Pull has no GIF in this set; use Workout Guide face-pull (see workout-guide-asset-plan.md).
