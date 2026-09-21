# eInk image server

Converts whatever is in two directories into panel-ready blobs and serves them
to the panel. Install it as a local Home Assistant app.

Format, contracts and the reasoning behind the conversion: [../IMAGE-PIPELINE.md](../IMAGE-PIPELINE.md)

## Install

This repo is a Home Assistant add-on repository (`repository.yaml` at the root),
so there is no copying and no SSH. Add it once:

**Settings → Add-ons → Add-on Store → ⋮ → Repositories →**
`https://github.com/AStoker/eInk-Projects`

"eInk Image Server" then appears in the store. Install it, and set the port
mapping if Home Assistant does not take 8100 by default.

Then point the panel at it. In the ESPHome device file:

```yaml
substitutions:
  eink_host: "192.168.3.50:8100"    # the HA host's LAN address, not a hostname
```

The ESP32 is on the LAN and outside Docker's network, which is why the app
publishes port 8100 on the host and why this must be an IP the panel can reach.

## Releasing a change

Supervisor decides an update exists by comparing `version:` in `config.yaml`
against what is installed. **A push with an unchanged version is invisible** —
the files move, the store shows nothing, and it looks like the push failed.

`./release.sh` does the three steps together so that cannot happen:

```sh
./release.sh          # patch bump, then confirm
./release.sh minor
./release.sh 2.0.0
./release.sh patch -y # no confirmation
```

Then in Home Assistant: **Add-on Store → ⋮ → Check for updates**, and press
Update on the add-on. Confirm what actually landed with `GET /health`, which
reports the running version — a store that says it updated is not the same as a
container that did.

## Directories

| Path | What |
|---|---|
| `/media/eink/photos/` | Drop photographs here. Subfolders are fine |
| `/media/runpod/eink/` | `morning.png`, `day.png`, `night.png` from the 3am job |
| `/media/eink/out/` | Converted blobs. Disposable — deleting them forces a rebuild |

Only those two source directories, never `/media/runpod/` itself: the RunPod
app's own gallery lives beside it and would otherwise end up on the panel.

## Dropping photos in

Copy anything into `/media/eink/photos/` — over Samba, the Media browser,
however. Within 20 seconds it is converted and in the rotation. No resizing, no
naming convention, no restart, and subfolders work so an album can go in whole.

Three things make that safe rather than merely convenient:

**A file still being copied is skipped, not half-converted.** A large photo
arriving over Samba is a series of writes, and a scan can land in the middle of
one. Each candidate is checked for a stable size before conversion, and Pillow
failing on a truncated file is caught and retried on the next scan rather than
killing the scan.

**Dotfiles and `.tmp` are ignored**, which is most of what a network share
leaves lying around.

**Deleting a photo removes it.** Converted blobs whose source is gone are
pruned on the next scan, so the panel stops showing it.

Formats: PNG, JPEG, WebP, BMP, GIF, TIFF. Any aspect ratio — the converter
centre-crops to 3:4 and resizes, so a landscape photo loses its sides rather
than being letterboxed.

**The EXIF rotation is applied first.** A phone stores every shot in the
sensor's landscape and records which way it was held in a tag; the converter
bakes that in before it measures the picture, so a portrait photo comes out
upright and the crop is taken from the frame as the eye saw it.

**Photographs are black and white.** Red is a second ink meant for the one
object a generated render was asked for. Spread through a photograph at
whatever saturation the light gave it, the converter's red gate catches part of
a jacket and not the rest, so photo mode turns it off and every pixel is
dithered on luminance alone.

## Routes

| Route | Returns |
|---|---|
| `GET /revision?mode=AI` | The id of the blob that `/next` would serve, or empty |
| `GET /next?mode=AI` | The blob, `application/octet-stream`, 30,413 bytes |
| `GET /index` | What it has found and which slot is current — for debugging |
| `GET /agenda` | The last agenda pushed, and which calendars were on — for debugging |
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

**It includes the conversion, not just the content.** The same image in the
photo directory and the AI directory converts to two different blobs — one
black and white for a photograph, one clamped and red-gated for flat art. A
cache keyed on content alone serves whichever was converted first, so an AI
image can come back as a photograph.

`PIPELINE_REV` in `server.py` covers the same thing across time. Bump it
whenever `panelise()` would turn the same source into different pixels: every
blob gets a new name, the cache on disk rebuilds instead of serving what the
old converter made, and the panel is told the picture moved.

## Photo rotation

Rotation is driven by the clock, not by `/next`: the selected photo is
`int(now / rotate_seconds) % count`. That way `/revision` and `/next` always
agree, and asking what is current does not change what is current. Default is
one photo per 15 minutes, matching the panel's wake interval.

## Today's agenda

The panel draws the day from `sensor.esp_day_agenda`, which this app assembles
and pushes to Core. `agenda.py` asks each configured calendar for today's
events, flattens them into the JSON shape `daily-dash/packages/agenda.yaml`
documents, and writes the result back — the count in the state, the events in
the `entries` attribute, because Core caps states at 255 characters.

Reaching Core needs `homeassistant_api: true` in the manifest, which is what
makes Supervisor's injected `SUPERVISOR_TOKEN` authorize the calls.

### Choosing calendars

`agenda_calendars` in the app options is the set the dash may draw. Nothing
joins on its own: a calendar appears on the panel only once it is listed here,
by entity id.

The options form has no autocomplete for this — Home Assistant's app options
schema has only scalar types (`str`, `int`, `list(a|b|c)`, `device`) and no
entity picker, so the ids are typed by hand. A typo reads as a calendar that
never has any events rather than as an error, so `GET /agenda` reports what was
actually resolved, which is the quickest way to catch one.

Each listed calendar is then gated at runtime by a switch:

    calendar.tricias_routine  ->  input_boolean.eink_dash_cal_tricias_routine

Turn that off and the calendar drops off the panel within one refresh, with no
restart and no options edit. A calendar whose switch does not exist counts as
on, so adding one to `agenda_calendars` puts it on the panel straight away and
the helper only has to exist for the ones you want to be able to turn off.

Note that a newly created `input_boolean` starts `off` — switch it on after
creating it, or the calendar it gates disappears.

### What it pushes

`POST /api/states` creates a state-only entity, so the sensor does not survive
a Core restart. The refresh loop publishes once at startup and then every
`agenda_refresh_minutes`, which is what puts it back without anyone
intervening. The panel wakes every 15 minutes, so the default of 5 means the
agenda on the glass is never more than one wake behind.

Events are clamped to the day and decided here rather than trusted from the
query: Core answers a one-day window with nearby multi-day events too, so an
all-day event starting tomorrow would otherwise land on today's panel.

A cycle in which no calendar answers publishes nothing rather than publishing
an empty day, because an empty day is indistinguishable on the glass from a
clear one. The last good agenda stays up until a cycle succeeds.
