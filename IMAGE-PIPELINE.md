# Daily Dash image pipeline

How a picture becomes ink on the 4.2" panel, and the contracts between the four
pieces that make it happen.

```
  3am automation ──► RunPod Client app ──► /media/runpod/eink/*.png
       │                (generates 3)
       │
       └──────────────► e-ink app ──────► /media/eink/out/*.bin
                        (converts)              │
   /media/eink/photos/ ─┘                       │  HTTP
                                                ▼
                                       ESP32 ──► panel
```

Three display modes, chosen by `input_select.eink_daily_dash_mode` (created):

| Option | Shows |
|---|---|
| `Dash` | The agenda, drawn on-device. No images involved |
| `Photos` | The next picture from `/media/eink/photos/` |
| `AI` | Whichever of the three generated images matches the time of day |

---

## 1. The blob format

The ESP32 has ~130 KB of free heap and no PSRAM, and a JPEG or PNG decoder plus
its inflate window does not comfortably fit next to the WiFi stack and the
panel's own 30 KB frame buffer. So the panel is sent pixels that are already
dithered, already the right size, and already one bit deep. The device does no
image processing at all — it copies bits.

**One file, 30,413 bytes, same for every image.**

```
offset  size   field
------  -----  -------------------------------------------------------
     0      5  magic, ASCII "EINK1"
     5      2  width,  uint16 little-endian = 300
     7      2  height, uint16 little-endian = 400
     9      2  stride, uint16 little-endian = 38
    11      1  planes, uint8 = 2
    12      1  flags,  uint8 = 0
------  -----  header is 13 bytes -------------------------------------
    13     38  row 0, black plane
    51     38  row 0, red plane
    89     38  row 1, black plane
   127     38  row 1, red plane
              ... 400 rows, 76 bytes each
------  -----  30413 bytes total --------------------------------------
```

**The two planes are interleaved by row, not stored one after the other.** That
is the whole reason the firmware needs no image buffer: a pixel's colour takes
a bit from each plane, so a plane-major file would have to be held in full
before anything could be drawn. Row-major interleaving means 76 bytes in hand
is a complete, drawable row.

Each row is a bitmap, MSB first. The bit for pixel `(x, y)` is

```python
byte = 13 + y * 76 + plane * 38 + (x >> 3)
mask = 0x80 >> (x & 7)
```

**A set bit means that ink is present.**

| plane 0 | plane 1 | pixel |
|---|---|---|
| 0 | 0 | white |
| 1 | 0 | black |
| 0 | 1 | red |
| 1 | 1 | do not emit — the firmware paints it black |

`stride` is 38 rather than 37.5 because 300 px does not divide into whole bytes.
The last four bits of every row are padding and are ignored.

### Orientation is portrait, as seen

The blob is **300 wide × 400 tall — the picture the right way up, as the frame
stands on a desk.** The panel's own memory is 400 × 300 landscape and the
firmware is set to `rotation: 270°`, but that rotation is applied on the device.
Nothing upstream needs to know about it, and re-rotating the panel later is a
one-line firmware change that leaves the pipeline alone.

### Colour

The panel has three inks and no greys. Red is a real second ink, not a tint, so
it reads as a deliberate accent rather than as shading — and keeping it that way
is the whole job of this step.

Fit the source to 300 × 400 by centre-cropping to 3:4 and then resizing — a
letterboxed picture wastes a third of a panel that is only 300 px wide.

### Gate red on being red

**Do not let `quantize()` pick the colours.** Nearest-colour in RGB puts a warm
antialias pixel like `(167, 137, 112)` closer to pure red (39,057) than to black
(59,202), so every silhouette edge in the picture grows a red fringe. Measured
on the first render: only 81% of the red pixels were the actual red object; the
rest were edge fringe scattered across the image.

Neutral greys are safe — they resolve to black or white — so this is warm
edges specifically, which is exactly what black-on-cream artwork is full of.

Decide red on saturation and channel dominance instead, then decide everything
else on luminance alone:

```python
r, g, b = x[:,:,0], x[:,:,1], x[:,:,2]
sat     = x.max(2) - x.min(2)
is_red  = (sat >= 90) & (r >= np.maximum(g, b) + 60)
```

A pixel becomes red only when it is convincingly red. Everything else is black
or white, so the red that survives is the red the artwork meant.

### Always dither. Clamp the flats first on generated art.

Both sources are error-diffused. What differs is a clamp applied beforehand:

| Source | Treatment |
|---|---|
| `/media/runpod/eink/` — generated art | clamp to the rails, then Floyd–Steinberg |
| `/media/eink/photos/` — photographs | Floyd–Steinberg, no clamp |

A generated print is not two tones. Measured on a real render, its luminance
histogram has two spikes — **31% at 0–15** (ink) and **27% at 224–239** (paper) —
with about **19% genuine mid-tone** in between, which is where a storm cloud
gets its depth.

Neither spike sits at the rail, and that is the whole problem. Floyd–Steinberg
reads a 230 background as a tone it must reproduce and scatters dots across the
entire sky. Clamping near-white to 255 and near-black to 0 first means those two
flats quantise with zero error, so the diffusion is spent only on the real
mid-tones:

```python
CLAMP_LO, CLAMP_HI = 40, 205
lum = np.where(lum >= CLAMP_HI, 255.0, lum)
lum = np.where(lum <= CLAMP_LO, 0.0, lum)
```

Hard-thresholding instead of dithering — the earlier fix for the speckle — cures
the background but throws that 19% away, and the result is a flat tri-tone with
no depth. The clamp fixes the actual cause rather than disabling the symptom.

A photograph is not clamped: it wants its full tonal range, and its highlights
and shadows are real content rather than a paper colour that missed the rail.

A reference implementation of all of the above — fit, gate, dither switch — is
`panelise.py` in the e-ink app.

---

## 2. The e-ink app

A new app, separate from the RunPod client, because both modes need the same
conversion and photo mode has nothing to do with RunPod.

**Watches** exactly two directories, neither of them recursively:

- `/media/eink/photos/` — drop any images in here; this is photo mode's source
- `/media/runpod/eink/` — the three stable files the 3am job writes

`/media/runpod/eink/` specifically, never its parent. The RunPod app's own
gallery lives at `/media/runpod/<endpoint>/<YYYY-MM>/`, a sibling — watching
`/media/runpod/` would sweep up every picture anyone generates in the app and
put it on the panel.

Files arrive atomically (temp file plus `os.replace`), so a size-settling delay
is unnecessary; a file that appears is complete.

**Writes** `/media/eink/out/`, one `.bin` per source image in the format above,
plus `index.json`:

```json
{
  "photo":   ["a1b2c3.bin", "d4e5f6.bin"],
  "ai":      {"morning": "m.bin", "day": "d.bin", "night": "n.bin"},
  "revision": 41
}
```

**Serves** over HTTP on its own port:

| Route | Returns |
|---|---|
| `GET /next?mode=photos` | The next blob in rotation, `application/octet-stream` |
| `GET /next?mode=ai` | The blob for the current time of day |
| `GET /revision` | A short string that changes only when the image would change |

`revision` is what keeps the panel from burning refreshes. The firmware wakes
every 15 minutes but the AI image changes three times a day, so the device
fetches `/revision` first — a few bytes — and only pulls the 30 KB blob and
spends a 17-second refresh when that string differs from the one it stored
before it went to sleep.

Rotation for photo mode advances on `/next`, so the panel steps one picture per
wake rather than the app keeping a clock of its own.

---

## 3. The RunPod client contract

Built. The app writes a second, stable copy of each image at a fixed path,
through a temp file and `os.replace`, so the e-ink app's watcher never catches a
half-written PNG. The job's own immutable copy still exists, so history keeps
pointing at the right picture.

### `rest_command.runpod_generate`

**Not a service.** Home Assistant registers services from integrations, and an
app cannot register one — so this is a `rest_command`, installed in
`/config/rest_command.yaml` (which `configuration.yaml` already `!include`s).
A `runpod_generate_raw` variant sits beside it whose payload is
`{{ body | to_json }}`, for passing a body through without maintaining a field
list.

**Two levels.** Job fields go at the top; everything describing the render goes
under `params`. The `rest_command` template forwards exactly `endpoint`,
`prompt`, `label`, `wait`, `timeout`, `image_paths`, `output_dir`, `filename`
and `params` — a render setting sent flat is dropped by the template and never
reaches the app. The HTTP API itself accepts both forms, which is what makes
this easy to miss.

Job fields:

| Field | Type | Notes |
|---|---|---|
| `prompt` | string, required | |
| `endpoint` | string | The key (`krea2`), the display name, or the raw RunPod id — all three resolve |
| `output_dir` | string | The 3am automation passes `/media/runpod/eink`. Naming it also flips `save_to_media` off, so a year of nightly renders does not pile up in the media browser |
| `filename` | string | Base name, no extension — `morning`, `day`, `night`, overwriting yesterday's |
| `label` | string | Shows in the app's history |
| `wait` | bool, default `false` | Block until the job finishes. Ceiling 600 s; a wait that runs out returns `timedOut: true` and the job carries on |
| `timeout` | int, default 300 | Seconds, only with `wait: true` |

Under `params` — the endpoint's own schema, which `GET /api/endpoints` reports
authoritatively:

| Field | Notes |
|---|---|
| `width` / `height` | **768 × 1024.** Portrait, matching the panel's 3:4. Generate large and let the e-ink app downscale; 300 × 400 is far off-grid for a diffusion model |
| `negative` | Worth using — see the prompt pair in §4 |
| `seed` | Omit for random |
| `steps` / `cfg` | Pass through to the worker |

`save_base` is a **Z-Image-only** parameter, and `krea2` rejects it as unknown.
It does not apply here: `krea2` has exactly one save node, so it returns one
image and `day.png` is unambiguously the finished one. Confirmed against a real
render — one file, no `day_01.png`.

**Returns** via `response_variable` — and `rest_command` wraps the body, so the
payload is one level down:

```yaml
gen.status          # HTTP status
gen.content.ok      # true
gen.content.uid     # "…"
gen.content.files   # ["/media/runpod/eink/morning.png"]
```

`gen.content.files`, not `gen.files`. Reading the wrong one yields nothing and
raises no error.

With `wait: false` the action returns as soon as the job is queued and `files`
is empty; the automation then waits on the events below. With `wait: true` it
returns the finished paths directly, which is what makes the 3am automation a
single `action:` block per image.

Events fire either way, so nothing has to poll. There are two, and both carry
the same shape:

```yaml
event_type: runpod_image_ready     # or runpod_image_failed
data: { uid: "…", ok: true, files: [...], error: null }
```

One trigger block can take both by listing both event types.

---

## 4. The nightly automation

**It is installed and enabled**, as `automation.eink_daily_dash_generate_ai_images`,
under the **eInk Daily Dash** category. Everything below describes the thing
that is already running — it is not a snippet to paste.

At 03:00 it asks WeatherKit for the day's forecast, asks Claude for three
matched prompts, and renders each on RunPod into `/media/runpod/eink/`. The
e-ink app notices the new files within 20 seconds and converts them.

To watch it work, run it manually from its page. It takes about four minutes
and spends three GPU renders.

### Changing the look

`input_text.eink_daily_dash_theme` is the whole interface. Type a word, and
that night's set follows it:

| Theme | What you get |
|---|---|
| *(blank)* | Claude picks freely, favouring Columbia SC subjects |
| `fall` | Autumn scenes |
| `christmas` | Seasonal scenes |
| `snow`, `storms`, `the coast`, `city at night` | As described |

A non-empty theme **outranks the Columbia SC steer** — the automation swaps the
local-landmark paragraph for the theme instruction rather than stacking them,
so a theme does not fight a list of rivers and bridges it is supposed to
replace. Clear the box to go back.

The theme is read fresh at 03:00, so setting it any time before then applies
that night.

### The prompt rules, and why each exists

These live in the automation's `instructions:`. Every one came from a render
that failed on the glass; none is a preference.

| Rule | Learned from |
|---|---|
| **Ask for tone, not flat blocks** — hatching, texture, shadow, atmosphere | An earlier version banned shading and gradients outright. Correct while the converter hard-thresholded; wrong once it clamped the flats and diffused the mid-tones, and it then produced exactly the lifeless tri-tone it was written to prevent. What genuinely fails is *subtle* tone spread thinly over a large area — that comes out as noise, so aim for clearly separated light, mid and dark passages |
| **Form** — one flowing comma-separated phrase opening `Bold` + a print medium, varied daily | Clipped sentences with capitalised emphasis produce flat vector clip-art. Wood engraving, scraperboard, linocut with hatching, lithograph, halftone screen-print and ink wash all dither well |
| **Composition** — one dominant subject, a few large shapes, detail *inside* them | A harbour listing boats, masts, docks and warehouses came out 57% black and turned to mud at 300 px. The problem was never detail as such, it was detail with no large structure holding it together |
| **Light overall, ~two-thirds** | E-ink black is dark grey on light grey paper, so a dark picture loses most of its contrast in the flesh. A night scene came back 80% black and read as a slab. Night is shown through the scene and deep shadow in *part* of the frame |
| **No mirroring** | A cypress swamp reflected in still water doubled the ink and read as a mirror image rather than a picture |
| **One small red object**, named, solid, saturated | A red kettle handle came out at 5.8% of the panel and stopped being an accent. A red *glow* or *lit window* is worse — unsaturated red is dropped by the converter's gate, so it renders as nothing |
| **Full bleed** | Unsaid, the model produces a bordered print and a fifth of the panel is margin |

### If you change the prompt rules

Test before trusting. One render is enough to see whether a rule is working,
and the failure modes above are all visible at panel size. Convert a candidate
by hand:

```sh
cd eink-app
python3 -c "
from PIL import Image; import panelise as P
img = P.fit(Image.open('/path/to/render.png'))
rgb, black, red = P.panelise(img, dither=False)
rgb.save('preview.png')
t = P.W * P.H
print('white %.1f%%  black %.1f%%  red %.2f%%' % (
    100*(~black&~red).sum()/t, 100*black.sum()/t, 100*red.sum()/t))
"
```

## 5. Firmware side

Built, in `daily-dash/`. The YAML follows the sound machine's layout — one
substitutions block in the core file, one package per slice, cross-package
wiring by ESPHome id:

| File | Holds |
|---|---|
| `daily-dash.yaml` | Substitutions, wifi/api/ota, http_request, SPI, clock |
| `packages/display.yaml` | The panel, the fonts, and the one lambda that draws all three screens |
| `packages/agenda.yaml` | The agenda attribute sensor |
| `packages/image.yaml` | Mode select, the stored revision, the blob fetcher |
| `packages/sleep.yaml` | `deep_sleep`, the hold-awake toggle, `wake_cycle`, `sleep_or_stay` |
| `packages/battery.yaml` | The ADC and the two battery sensors |

`components/eink_blob/` does the fetch: it reads one interleaved row at a time
straight into `draw_pixel_at()`, so the largest image buffer on the device is
76 bytes and ESPHome applies the panel rotation on the way through.

### Two entry points, and why

`daily-dash.yaml` is not built directly. ESPHome resolves an
`external_components` path of `type: local` against the directory of the
**top-level** config, not the package that asked for it, so a package cannot
point at a component sitting beside it. Whatever file is the device has to
declare where the component comes from:

| Entry point | For |
|---|---|
| `dev.yaml` | Local builds. Component from `./components` |
| `example-device.yaml` | ESPHome Device Builder. Core and component both pulled from GitHub |

The wake cycle gains one branch before it draws:

```
wake ─► api up? ─► mode == dash ─► draw the agenda
                └─► mode != dash ─► GET /revision
                                     ├─ unchanged ─► sleep, no refresh
                                     └─ changed  ─► GET /next, blit, sleep
```
