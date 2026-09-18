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
it reads as a deliberate accent rather than as shading. Convert with a
Floyd–Steinberg dither against a three-entry palette:

```python
pal = Image.new("P", (1, 1))
pal.putpalette([255, 255, 255,  0, 0, 0,  255, 0, 0] + [0, 0, 0] * 253)
q = src.convert("RGB").quantize(palette=pal, dither=Image.FLOYDSTEINBERG)
```

Fit the source to 300 × 400 by centre-cropping to 3:4 and then resizing — a
letterboxed picture wastes a third of a panel that is only 300 px wide.

---

## 2. The e-ink app

A new app, separate from the RunPod client, because both modes need the same
conversion and photo mode has nothing to do with RunPod.

**Watches**

- `/media/eink/photos/` — drop any images in here; this is photo mode's source
- `/media/runpod/eink/` — where the 3am job writes its three generated images

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

## 3. What the RunPod client needs to expose

Today the app is driven over HTTP (`POST /enqueue`, then poll) behind ingress
auth. A 3am automation wants one blocking call, so add a Home Assistant action:

### `runpod_client.generate`

| Field | Type | Notes |
|---|---|---|
| `prompt` | string, required | |
| `endpoint` | string | Endpoint id from `src/endpoints.js`; defaults to the configured one |
| `width` / `height` | int | Default 1024 × 768. Generate large and let the e-ink app downscale — 300 × 400 is far off-grid for a diffusion model |
| `seed` | int | Omit for random |
| `steps` / `cfg` | int / float | Pass through to the worker |
| `output_dir` | string | Where to write. The 3am automation passes `/media/runpod/eink` |
| `filename` | string | Base name without extension, so the automation can write `morning`, `day`, `night` and overwrite yesterday's |
| `wait` | bool, default `false` | Block until the job finishes |
| `timeout` | int, default 300 | Seconds, only meaningful with `wait: true` |

**Returns** (via `response_variable`):

```yaml
{ ok: true, uid: "…", files: ["/media/runpod/eink/morning.png"] }
```

With `wait: false` the action returns as soon as the job is queued and `files`
is empty; the automation would then wait on the event below. With `wait: true`
it returns the finished paths directly, which is what makes the 3am automation a
single `action:` block per image.

Also fire an event on completion either way, so nothing has to poll:

```yaml
event_type: runpod_client_job_finished
data: { uid: "…", ok: true, files: [...], error: null }
```

`filename` and `output_dir` are the two fields that matter most here — without
them the automation has to go find whatever the job happened to name its output,
and the e-ink app has no stable three files to convert.

---

## 4. The 3am automation

Runs once a night, generates three images from the day's **forecast** rather
than current conditions — at 3am "current weather" describes the middle of the
night, not the day the pictures are for.

Weather comes from `weather.home_weatherkit`. WeatherKit exposes forecasts
through the `weather.get_forecasts` action rather than as a `forecast`
attribute, so the automation calls it and reads the response.

```yaml
triggers:
  - trigger: time
    at: "03:00:00"
actions:
  # WeatherKit does not put a forecast array on the entity; ask for it.
  - action: weather.get_forecasts
    target:
      entity_id: weather.home_weatherkit
    data:
      type: daily
    response_variable: wx
  - variables:
      fc: "{{ wx['weather.home_weatherkit'].forecast[0] }}"
  - repeat:
      for_each:
        - { slot: morning, light: "soft low sunrise light" }
        - { slot: day,     light: "bright midday light" }
        - { slot: night,   light: "deep blue evening light" }
      sequence:
        - action: runpod_client.generate
          data:
            prompt: >-
              {{ repeat.item.light }}, {{ fc.condition }},
              high contrast, bold shapes, flat colour, minimal detail,
              black and white with one red accent
            output_dir: /media/runpod/eink
            filename: "{{ repeat.item.slot }}"
            wait: true
          response_variable: gen
```

Prompt style matters more than usual: the panel is three colours, 300 × 400, and
dithered. Flat shapes and hard edges survive that; soft gradients and fine
detail turn to noise.

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
