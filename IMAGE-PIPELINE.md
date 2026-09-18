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

### Dither photographs, not flat art

The remaining black/white decision depends on where the image came from:

| Source | Treatment |
|---|---|
| `/media/runpod/eink/` — generated flat art | threshold at luminance 128 |
| `/media/eink/photos/` — photographs | Floyd–Steinberg the non-red pixels |

The model's "white" paper comes back at **RGB 230, 227, 222** — about 10% grey,
not white. Error diffusion reads that as a tone it must reproduce and scatters
dots across the entire background, turning a clean screen-print into speckle.
A plain threshold snaps it to white and leaves the flats flat.

A photograph is the opposite case: three hard tones with no diffusion posterise
it into unreadable blobs, and the error diffusion is what buys back the illusion
of shading. Hence one switch, driven by the directory.

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

## 4. The 3am automation

Runs once a night and leaves three files behind. Three steps: ask WeatherKit
what the day looks like, ask Claude for three prompts, render them.

### Claude writes the prompts

`ai_task.generate_data` against `ai_task.claude_ai_task`, with a `structure` so
the answer arrives as named fields instead of prose to parse. Claude picks one
subject for the day and writes it three times, so the panel shows a set rather
than three unrelated pictures — verified live, which returned "Sunflower through
the day": a red sun at dawn, a red bee at noon, a red moon at night.

The panel's constraints live in those instructions, and four of them were each
learned by generating something that did not work:

**Form.** One continuous comma-separated phrase, opening `Bold graphic
screen-print poster of`. Never several short sentences, never capitalised
emphasis. This is the single biggest lever on quality: clipped sentences
produce flat vector clip-art, a flowing description produces a print. Give the
model this exact line to match —

```
Bold graphic screen-print poster of a misty valley at dawn with a lone tree on
a ridge, clear sky, one small red rising sun low on the horizon as the single
red element in the whole image, everything else flat solid black on white
paper, hard edges, thick black outlines, extremely high contrast, no shading,
no gradients, vertical composition
```

**Scene, not object.** A landscape, shoreline, skyline, harbour, weather, a
view through a window — something with depth. An isolated object on a plain
ground renders as clip-art however it is described.

**Full bleed, edge to edge, no border, no margin.** Left unsaid, the model
produces a *bordered print* — artwork floating in white space — and a fifth of
a 300 × 400 panel goes to margin.

**One small red object**, named, stated as the single red element. Two
failures to avoid: a *large* red object (a kettle handle came out at 5.8% of
the panel and stopped reading as an accent), and a red *glow* or *lit window* —
unsaturated red is dropped entirely by the converter's gate, so it renders as
nothing at all. A sun on the horizon, a buoy, a flag, a lantern.

Ink balance is the quick check on a finished panel: **roughly two-thirds white,
a third black, red well under 1%.** A composition that comes out 80% black is a
black slab on the wall.

```yaml
triggers:
  - trigger: time
    at: "03:00:00"

actions:
  # WeatherKit exposes no forecast attribute; ask for it.
  - action: weather.get_forecasts
    target:
      entity_id: weather.home_weatherkit
    data:
      type: daily
    response_variable: wx
  - variables:
      fc: "{{ wx['weather.home_weatherkit'].forecast[0] }}"

  - action: ai_task.generate_data
    data:
      entity_id: ai_task.claude_ai_task
      task_name: eink daily dash prompts
      instructions: >-
        You are writing image-generation prompts for a 4.2 inch three-colour
        e-paper panel: 300x400 portrait, and the ONLY inks are white, solid
        black, and one bright red. There are no greys and no shading.

        Pick ONE subject for today and write three prompts showing that same
        subject at morning, midday and night, so the three read as a set. Vary
        the subject creatively from day to day.

        Today's forecast: {{ fc.condition }}, high {{ fc.temperature }},
        low {{ fc.templow }}.

        Hard rules for every prompt: bold graphic screen-print poster style,
        flat blocks of solid colour, hard edges, thick black outlines, extremely
        high contrast. FULL BLEED - say explicitly that the artwork fills the
        entire frame edge to edge with no border and no margin; this matters
        more than anything else, because a bordered print wastes a fifth of the
        panel. Name exactly ONE small red OBJECT per prompt and state it is the
        single red element in the whole image - a solid object with a hard edge,
        never a glow, a lit window, a tint or an atmosphere, because unsaturated
        red renders as nothing. Everything else is solid black on white paper.
        Explicitly say: no shading, no gradients, vertical composition. Under 70
        words each.
      structure:
        subject:
          selector: {text: }
          description: The single shared subject chosen for today
          required: true
        morning:
          selector: {text: }
          description: Prompt for the morning image
          required: true
        day:
          selector: {text: }
          description: Prompt for the midday image
          required: true
        night:
          selector: {text: }
          description: Prompt for the night image
          required: true
    response_variable: prompts

  - repeat:
      for_each: [morning, day, night]
      sequence:
        - action: rest_command.runpod_generate
          data:
            endpoint: krea2
            label: "eInk daily dash - {{ repeat.item }}"
            output_dir: /media/runpod/eink
            filename: "{{ repeat.item }}"
            wait: true
            params:
              width: 768
              height: 1024
              prompt: "{{ prompts.data[repeat.item] }}"
              negative: >-
                border, frame, margin, white space around artwork, matted
                print, gradient, soft shading, blur, haze, glow, fine detail,
                intricate texture, noise, grain, photorealistic, photograph,
                muted colours, grey, pastel, brown, orange, warm tones, red
                tint, text, letters, watermark, signature
```

Three details are easy to get wrong and fail quietly:

- **`width`, `height`, `prompt` and `negative` sit under `params`.** Flat, the
  rest_command template drops them.
- **768 × 1024, portrait.** The panel is 3:4 the tall way. A landscape
  1024 × 768 source loses about 44% of its width to the centre crop.
- **`prompts.data[...]`** — `ai_task` nests its answer under `data`, the same
  way `rest_command` nests under `content`.

The forecast is the day's, not the moment's: at 3am "current weather" describes
the middle of the night, not the day the pictures are for.

Timing, measured: a warm `krea2` worker put the finished file on disk **80
seconds** after the call returned `QUEUED`.

---

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
