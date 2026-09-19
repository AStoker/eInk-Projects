# eInk Projects

A 4.2" three-colour e-paper panel in a printed desk frame that shows today's
agenda, your photos, or a picture generated overnight.

| Where | What |
|---|---|
| [stand-4.2in/](stand-4.2in/) | The printed frame, the wiring, the power budget |
| [daily-dash/](daily-dash/) | ESPHome firmware for the panel |
| [eink-app/](eink-app/) | Home Assistant app that converts images for the panel |
| [IMAGE-PIPELINE.md](IMAGE-PIPELINE.md) | How a picture becomes ink: blob format, prompts, contracts |

This repo is also a **Home Assistant add-on repository** (`repository.yaml`),
so the app installs from the store rather than by copying files.

## Using it day to day

Everything is grouped under the **eInk Daily Dash** label in Home Assistant.

| Control | Does |
|---|---|
| `input_select.eink_daily_dash_mode` | **Dash** (agenda), **Photos**, or **AI** |
| `input_text.eink_daily_dash_theme` | Theme for the generated pictures — `fall`, `christmas`, blank for free choice |
| `input_boolean.eink_daily_dash_disable_deep_sleep` | Hold the panel awake so it can be flashed |
| `button…refresh_display` | Redraw now — only works while the panel is awake |
| `automation.eink_daily_dash_generate_ai_images` | The 3am job. Run manually to preview |

**To show your own photos:** drop them in `/media/eink/photos/` and switch the
mode to Photos. Subfolders are fine. The app picks them up within 20 seconds,
converts them, and the panel rotates one photo per wake. Nothing else to do —
no resizing, no naming convention, no restart.

**To change the generated pictures:** type a word into the theme box. That
night's set follows it.

## How the panel behaves

It wakes every 15 minutes, draws once, and sleeps — about 25 seconds awake,
because a full e-paper refresh takes 17 of them. Two consequences worth
knowing:

- **A button press only lands while it is awake.** Mode and theme changes take
  effect on the next wake, up to 15 minutes later. To make a change land now,
  turn the hold-awake toggle on first — then the panel is listening.
- **It only refreshes when the picture actually changed.** The panel asks the
  app for a short revision string first and skips the refresh if it matches.
  **Pressing Refresh Display overrides that**, as does changing the mode, so a
  deliberate request always redraws.

## Flashing

`daily-dash/example-device.yaml` is the device file for ESPHome Device Builder;
it pulls the firmware from this repo. See [daily-dash/](daily-dash/) for the
package layout and the two entry points.

The case has no opening for the driver board's USB-C, so **OTA is the only way
in once it is assembled**. Turn the hold-awake toggle on before flashing. A
cold boot also stays up for two minutes regardless, which is the way back in if
the toggle is unreachable.

## State of things

| Working | Not done |
|---|---|
| Agenda rendering, deep sleep, OTA window | Battery divider not fitted — GPIO 35 floats, HA shows ~0 V |
| Nightly generation, theming, photo drop | Low-voltage cutoff, deliberately, until the divider reads true |
| Blob format, converter, image server | The app has not yet run inside Home Assistant |
