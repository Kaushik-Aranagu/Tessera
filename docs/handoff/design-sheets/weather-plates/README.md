# Weather sky plates (first working set, Oct 25)

Portrait crops of the upper sky from Poly Haven HDRI panoramas (https://polyhaven.com, CC0: no attribution required,
any use). Each is a 1179 x 1600 strip centered on the panorama's sun, cropped from +80 degrees elevation to just below
the horizon, 1.6x wider than tall so the page can drift across it. Made by `scratchpad/crop_plates.py` from the
tonemapped JPGs. To add a plate: pick a `_puresky` slug (sky only, no ground), download its tonemapped JPG, run the
script, name it `<condition>-<time>.jpg`.

| file | source | use |
|---|---|---|
| clear-day-1.jpg | Poly Haven kloofendal_43d_clear_puresky | clear, day |
| broken-day-1.jpg | Poly Haven kloofendal_48d_partly_cloudy_puresky | cloudy and snow, day |
| broken-day-2.jpg | GENERATED (ChatGPT, Oct 25, from BRIEF) | cloudy, day; second variant |
| overcast-day-1.jpg | Poly Haven kloofendal_overcast_puresky | overcast, rain and storm (darkened), day |
| overcast-dusk-1.jpg | GENERATED (ChatGPT, Oct 25) | rain, storm and snow at dawn and dusk |
| clear-dusk-1.jpg | Poly Haven qwantani_dusk_2_puresky | clear, dawn and dusk |
| broken-dusk-1.jpg | Poly Haven belfast_sunset_puresky | cloudy, dawn and dusk |
| clear-night-1.jpg, clear-night-2.jpg | GENERATED (ChatGPT, Oct 25): moonless, Milky Way low | clear night; the drawn moon is added over them |
| cloudy-night-1.jpg | Poly Haven kloppenheim_07_puresky (moonlit, thin cloud) | cloudy, rain, storm, fog and snow at night; darkened |
| fog-day-1.jpg | Poly Haven kloofendal_misty_morning_puresky | fog, day and dusk |

Files are `<set>-<n>.jpg`; the page picks a variant at random per set. Generated plates passed the side-by-side test on Oct 25 (he sent them; they read as the same day as the photographs).
Still missing for a full set: an overcast night, a true storm sky, real rain and snow loops
(video; from Pexels or the NERC sky-camera time-lapses on Zenodo, see sheet 256).
