# Brief for ChatGPT / Sora: living sky plates for a weather app

Paste everything below the line into ChatGPT, attach the reference images listed at the end, and ask for the
samples described in "What to make first". Keep what comes back in `docs/handoff/design-sheets/weather-plates/`.

---

I am building a personal iPhone weather page. The whole page is the sky, like Apple's weather wallpaper: a real-looking
sky fills the screen, and the information sits on top of it. I have a first set of sky photographs I like (attached:
seven portrait sky plates cropped from photographs, plus two screenshots of the page as it stands). I want you to
make a matching set of MOVING skies in the same look, and more of them, so the page is never still and never the same
twice.

## What the page is
- Portrait, 9:19.5 (an iPhone screen), 1290 x 2796 pixels or taller. The camera looks up at the sky at about 60
  degrees. The horizon, if visible at all, is in the bottom tenth. No ground, trees, buildings, birds, people, text.
- The upper two thirds of the frame carry text (a big temperature, a few words), so that region must stay calm enough
  for dark or white text to read: no hard bright-dark edges there, no busy detail.
- The look is a real photograph: natural exposure, soft grain, no HDR, no oversaturation, no vignette, no drama. The
  attached plates are the reference for color and tone. Everything you make should sit beside them without looking
  different in kind.

## What I want from you
1. MOTION. The clouds should drift, the way they do when you lie on your back and watch: slow, continuous, with
   nearer clouds moving faster than far ones. Rain should fall toward the camera with weight, and come in gusts: a
   steady fall that thickens and leans for a few seconds, then eases. Snow should drift and swirl. Fog should breathe.
   A storm sky should roll, with light changing inside the cloud. Nothing cuts; everything is continuous.
2. CONTINUITY AND RANDOMNESS. Each clip must loop seamlessly (the last frame flows into the first) so it can play for
   an hour, and I want several different clips for the same weather so the page can pick one at random and never
   repeat the same minute twice. The clips for one condition must feel like the same day and the same camera.
3. UNIFORMITY. The whole set is one camera, one lens, one grade. Same grain, same white balance logic (warm at dawn
   and dusk, neutral by day, cool at night), same framing. If I put any two side by side they look like the same
   place an hour apart.
4. SCALE. I will eventually want about eight conditions (clear, thin cloud, broken cloud, overcast, rain, storm, fog,
   snow) at four times of day (dawn, day, dusk, night), with three variants each. Start small; see below.

## What to make first (samples)
- Three STILLS to prove the look matches the attached photographs: broken cloud at midday with the sun behind a
  cloud; an overcast dusk; a clear starry night. Portrait, as large as you can.
- Then three CLIPS, 20 to 30 seconds each, seamless loop, portrait, 24 fps: broken cloud drifting at midday; rain
  falling toward the camera under a dark overcast with two gusts in the loop; a storm sky rolling with the light
  changing inside it (no lightning bolt; I add lightning myself in the app).
- For each, give me two variants with the same look so I can check they read as the same day.

## Rules for the images
- Sky only. Nothing else in frame, ever.
- Keep the sun out of the top two thirds unless it is behind cloud; the text lives there.
- No lens flare, no rainbows, no aurora, no planets, no "epic" skies. Ordinary weather, photographed well.
- Night skies are dark: deep indigo to near black, stars pin-sharp and varied, never a bright blue night.
- Deliver as PNG or high-quality JPG for stills, MP4 (H.264 or HEVC) for clips, named condition-time-variant, e.g.
  broken-day-1.mp4, rain-day-2.mp4, clear-night-1.png.

## Negative list (if useful)
illustration, painting, 3D render, CGI, anime, oversaturated, HDR, dramatic, epic, fantasy, aurora, galaxy art,
planets, lens flare, vignette, ground, horizon, mountains, trees, buildings, city, people, birds, text, watermark

## Attachments to include
- The seven reference plates: clear-day.jpg, broken-day.jpg, overcast-day.jpg, clear-dusk.jpg, broken-dusk.jpg,
  clear-night.jpg, fog-day.jpg (from docs/handoff/design-sheets/weather-plates/).
- Two screenshots of the page as it stands, from board 255 (https://claude.ai/artifact/XDNb4wm84nHNguDhFMqesr):
  one with "Cloudy" and "Now" selected and the glass showing the numbers, one with "Rain starts" pressed so the
  water in the glass shows. They show where the text and the glass sit, so you can see which part of the sky must
  stay calm.
