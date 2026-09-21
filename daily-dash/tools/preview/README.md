# Dash preview

Draws the agenda layout to a PNG instead of to the glass, so a change can be
judged before it costs a flash and a 17-second refresh.

```sh
./render.py --sheets               # the three review sheets -- start here
./render.py -l b -s busy -t 14:30  # one frame
./render.py -l b --day             # one layout at six times across the day
```

`--sheets` empties `out/` first and writes exactly three files, numbered in the
order they are worth opening:

| File | Shows |
|---|---|
| `1-three-options.png` | The three layout directions, same busy afternoon |
| `2-hour-ruler-across-the-day.png` | The chosen layout at six times, so the scroll is visible |
| `3-hour-ruler-edge-cases.png` | A quiet day, long titles, and nothing left |
| `4-wednesday-strewn.png` | Events from 6am to 9:30pm: carried-over events, a collapsed run, an overnight tail |
| `5-overloaded-day.png` | 17 events, more than the hour view can hold, so the list takes over |

Single frames land in `out/frames/`, so the top of `out/` stays reviewable.
`-s` picks a sample agenda: `busy`, `light`, `wordy`, `empty`.

## Why it is faithful

| | Panel | Preview |
|---|---|---|
| Canvas | 300 x 400 portrait | same |
| Inks | white, black, red | same three, no others |
| Type | ESPHome 1-bit glyphs | `fontmode = "1"`, antialiasing off |
| Faces | Roboto via gfonts | the same TTFs, from `.esphome/font/` |

A layout that fits here fits on the panel, and text that is legible here is
legible there. What the preview does not show is the e-ink contrast itself --
black is a dark grey on light grey paper, so the real panel reads softer than
the PNG.

## Files

| File | Holds |
|---|---|
| `dashsim.py` | The `it` object: `print`, `line`, `filled_rectangle`, `circle`, `wrap`, and the contact sheet |
| `layouts.py` | The candidate layouts. `option_b` is the one in the firmware |
| `sample.py` | Sample agendas in the JSON shape `packages/agenda.yaml` documents |
| `render.py` | The CLI |

`option_a` (Now & Next) and `option_c` (Big cards) are kept as drawn
alternatives to compare against.

## Keeping it in step with the firmware

`layouts.option_b` and the lambda in `packages/display.yaml` are two copies of
the same layout, one in Python and one in C++, sharing constants and call
shapes so a change ports line for line. Iterate here first, then move the
change across and `esphome compile dev.yaml`.
