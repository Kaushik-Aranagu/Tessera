# 215 final: Tess as built (Oct 23, 2:45 PM PT)

This is one page of final values. Where a revision in `tess-corner-interface-215.md` was superseded, this page wins.
Board v22: https://claude.ai/artifact/7g8r4LzjRV6LeHDxMJ5yiZ (source r36). Build to these numbers, and attach a side-by-side with the board frame to each PR.

## Form (rev 9 plus Revs 11 to 15, scaled by Rev 21)
- **Field:** a per-pixel cloud (112² at 140 pt), with the whole drawing scaled by 0.7. R = 0.16 · breath · (1 + 0.1·spread) · (1 + 0.26·bloom − 0.13·gather).
- **Edge reach:** 1 + 0.045·sin(2θ + 0.42t) + 0.03·sin(3θ − 0.33t + 1.1) + 0.035·sin(θ − 0.19t), plus the hearing term while he talks: level × (0.05·sin(3θ − 6.2t) + 0.028·sin(5θ + 4.4t + 1)).
- **Density and alpha:**
  - Density: dens = exp(−r^2.2 · 0.95).
  - Alpha on dark grounds: 1 − exp(−3.1·dens), then −0.02, with peak alpha 235.
  - Alpha on light grounds: 1 − exp(−4.6·dens), then −0.02, with peak alpha 242.
  - Alpha reaches 0 inside her bounds, with no ring.
- **Breath:** 0.96 + 0.08·sin(0.98t) + 0.08·voice level. While quiet, it uses 0.03 in place of the 0.08 and runs at 0.35x speed.
- **Texture:** uniform. No noise, streaks or patches.

## Color (Rev 20; Rev 19 F2; the tone is REMOVED)
- **Base Ember**, as [middle, side, side]:
  - Light: FF5A26, E5341C, FFA90F.
  - Dark: FF6B3D, FF4A33, FFC23D.
- **Fields:** three fields a third of a turn apart, turning at 0.6 + 0.16t, each swaying ±0.35 rad. The middle field sits at 0.40R with weight 1.08; the sides sit at 0.56R with weight 1. Each radius breathes ±0.08R.
- **Spread:** each field is a gaussian with sigma 0.76R.
- **Mixing:** plain OKLab, keeping chroma up to 1.25x.
- **Warped lookup** (applies to color only):
  - wu = u + 0.55R·sin(2v/R + 0.21t) + 0.18R·sin(1.4(u+v)/R − 0.13t)
  - wv = v + 0.55R·sin(1.8u/R − 0.17t + 2)
- **Light grounds, thin parts:** chroma × (1 + 0.45·(1 − a)), lightness − 0.025·(1 − a).
- **Bursts:** one random field at a time.
  - It swells from a random point within 0.45R: center moves 55% of the way there, weight ×(1 + 1.3·e), sigma +0.18R, with e = sin² over 1.4 to 2.2 s.
  - The gap between bursts is 2.2 to 5.7 s, or 5 to 11 s while quiet. Off under Reduce Motion.
- **Page cue:** decided by TessDirector .tessPalette(pageAccent).
  - With one clear accent, the middle is the accent at L 0.64 (light) or 0.74 (dark), with chroma at least 0.15. The sides are ±18° of hue, at L −0.05 and +0.05.
  - With none, she stays Ember.
  - Changing palette is a 1.2 s glide with smoothstep, turning hue the short way in OKLCH, plus a 0.28 catch.
- **Color rule:** nothing within ΔE 10 of Ember. The accents moved for it are Training A8203F, 9E1C3A, CC4478 dark (was D04A6A); Kitchen dark C49A5E; sunset sky1 dark E8A06A.

## Face
- **Eyes:** drawn at 1.3x scale; ink rgba(30,24,30,.86) on light and rgba(21,21,23,.82) on dark; 3:1 contrast or better, else #111.
- **Blinks:** 130 ms long, every 2.4 to 6.6 s. 18% are double blinks, and 30% of glances bring a blink.
- **Glances:** a new glance every 0.7 to 2.8 s, on a spring of 0.34. 55% are small glances, 27% go to a point of interest on the page, and 18% go to him, held 2.6 s. Her eyes follow the finger.
- **Mouth** (Rev 19 F5 only): one 1.05 pt line, 2.6 pt below her middle, drawn out from its middle and back in with no fade.
  - Smile: she did what was asked.
  - Slant: rising 0.5 pt to the right; she is waiting on his answer.
  - "Oh": something new arrived beside her on Home, for 1.4 s.
  - There is no mouth otherwise, and never a frown.

## Life and reactions (§C plus Rev 16 E1)
- **Body:** she leans after her eyes at 0.45x, bobs ±1.1 pt, and breathes 1 + 0.022·sin(1.05t) + 0.014·sin(0.37t + 2) + 0.06·pulse.
- **Open:** a gather of 13% over 140 ms, then a bloom of up to 26% decaying as exp(−3.2s), with a burst from her middle.
- **Close:** a bloom of 0.45 over 320 ms.
- **Think:** spin + 0.045 per frame.
- **Done:** a 4 pt hop over 420 ms, a 0.35 bloom, a burst of her third (gold) color from her center over 1.6 s, and happy eyes for 1.1 s.
- **No:** a 2.4 pt nod over 360 ms.
- **Touch:** a 0.6 gather over 220 ms, a burst toward the finger, and eyes 1.2x for 320 ms.
- **Hearing:** the edge waves above, a 0.28 catch on each heard word, and a 1.6 pt lean.
- **Reduce Motion:** all reactions are off; her eyes and blinks stay.

## Layer and words (§A plus Revs 10 and 16)
- **The layer:** a tap opens it over Home blurred at 18 pt, with saturation 1.15 and a 52% tint. She sits at (W/2, H − 112) at 1.35x scale, or 1.2x while he holds.
- **Conversation:** one running conversation (TessMemory, on-device, 7 days). Only the newest exchange is large.
- **Her opener:** picks up from what changed since her last turn ("Since then, …"), and never repeats or contradicts an earlier line.
- **Replies:** at most 3 plain replies, with no underline.
- **Time markers:** Outfit 200 at 12 pt in ink3, with 0.06 em tracking, shown only after a gap of 20 min or more. After a gap, she opens under "Now, 1:31 pm".
- **Her voice:** Newsreader in the board, New York in the app. Sizes are 18 pt for the band beside her, 17 pt for older lines in the layer and 23 pt for her newest. Linked words are weight 500 and never break.
- **His words:** Figtree, 17 pt.
- **Live speech:** Figtree Light 28 pt; each heard word shows at once.
- **Word reveal:** her words appear one at a time at 62 ms each, plus 40 ms after punctuation, each settling with a 3 pt rise over 180 ms. No fade and no letter flips; flips stay on Home's top lines only.
- **The echo:** an earlier mention of a word she names again brightens to ink for 0.9 s.
- **Typing:** a multi-line field that grows to 120 pt. Enter sends and Shift-Enter adds a new line; on the phone, return adds a line and a send arrow sends.
- **Touch target:** 84 pt.
