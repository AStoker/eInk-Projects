# eInk image server

Converts whatever is in two directories into panel-ready blobs and serves them
to the panel. Install it as a local Home Assistant app.

Format, contracts and the reasoning behind the conversion: [../IMAGE-PIPELINE.md](../IMAGE-PIPELINE.md)

## Install

Copy this directory to `/addons/eink_image_server` on the Home Assistant host
(the Samba share exposes `/addons`), then **Settings → Add-ons → Add-on Store →
⋮ → Check for updates**, and it appears under Local add-ons.

Then point the panel at it. In the ESPHome device file:

```yaml
substitutions:
  eink_host: "192.168.3.50:8100"    # the HA host's LAN address, not a hostname
```

The ESP32 is on the LAN and outside Docker's network, which is why the app
publishes port 8100 on the host and why this must be an IP the panel can reach.

## Directories

| Path | What |
|---|---|
| `/media/eink/photos/` | Drop photographs here. Photo mode rotates through them |
| `/media/runpod/eink/` | `morning.png`, `day.png`, `night.png` from the 3am job |
| `/media/eink/out/` | Converted blobs. Disposable — deleting them forces a rebuild |

Only those two source directories, never `/media/runpod/` itself: the RunPod
app's own gallery lives beside it and would otherwise end up on the panel.

## Routes

| Route | Returns |
|---|---|
| `GET /revision?mode=AI` | The id of the blob that `/next` would serve, or empty |
| `GET /next?mode=AI` | The blob, `application/octet-stream`, 30,413 bytes |
| `GET /index` | What it has found and which slot is current — for debugging |
| `GET /health` | `{"ok": true}` |

`mode` is the value of `input_select.eink_daily_dash_mode`, passed through
verbatim: anything starting with "photo" is photo mode, anything else is AI.

**`/revision` is the contract that protects the panel.** A refresh costs about
17 seconds of e-paper and the panel wakes every 15 minutes, so it asks for the
revision first and only downloads when that string has moved. An empty revision
means "nothing to show", which the firmware reads as unknown and leaves the
panel alone.

## Two things the revision has to get right

**It is a content hash, not a timestamp.** The 3am job rewrites all three files
every night through an atomic replace, so every file has a fresh mtime each
morning whether or not the picture changed. Hashing the bytes means an identical
render costs no refresh.

**It includes the dither mode.** The same image in the photo directory and the
AI directory converts to two different blobs — one error-diffused for a
photograph, one hard-thresholded for flat art. A cache keyed on content alone
serves whichever was converted first, so an AI image can come back speckled.

## Photo rotation

Rotation is driven by the clock, not by `/next`: the selected photo is
`int(now / rotate_seconds) % count`. That way `/revision` and `/next` always
agree, and asking what is current does not change what is current. Default is
one photo per 15 minutes, matching the panel's wake interval.
