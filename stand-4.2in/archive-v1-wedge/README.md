# 4.2" e-Paper desk frame + kickstand

A TRMNL-style desk frame for the **Waveshare 4.2inch e-Paper Module (B)** driven by the
**Waveshare e-Paper ESP32 Driver Board**. Portrait orientation, driver board fully hidden
inside, separate snap-in kickstand.

Everything is generated from one parametric OpenSCAD file — `src/epaper_stand.scad`.

```
    ┌──────────────┐         103.1 × 125.2 × 23 mm
    │  ┌────────┐  │         leans back 12°
    │  │        │  │         ~44 mm total footprint depth
    │  │  ink   │  │  ╲      USB-C exits the left edge
    │  │        │  │   ╲     4 × M2.5 screws hold the back cover
    │  └────────┘  │    ╲
    └──────────────┘  ───╲
```

---

## Parts

| Part | STL | Print orientation | Material |
|---|---|---|---|
| Frame | `stl/frame.stl` | front face on the bed (as exported) | ~90 g |
| Back cover | `stl/cover.stl` | outer face on the bed (as exported) | ~55 g |
| Kickstand | `stl/kickstand.stl` | flat (as exported) | ~9 g |
| Bezel test tile | `stl/bezel_test.stl` | flat — **print this first** | ~30 g |

All four are exported already oriented; drop them straight onto the plate.

### Print settings

- PLA or PETG, 0.2 mm layers, 4 perimeters, 15–20 % infill
- **No supports needed.** The USB-C opening and the two kickstand sockets bridge
  over ≤ 13 mm; if your printer bridges badly, turn supports on for the frame only
  and set the overhang threshold to 40°.
- Print the frame front-face-down — that face is the visible bezel, so it gets the
  smooth plate finish.

### Also needed

- 4 × **M2.5 × 8 mm** self-tapping screws (pan or countersunk — the counterbores fit a
  Ø5.4 mm head)
- A strip of 0.5–1 mm foam tape or weatherstrip for the module retention ribs
  (takes up the tolerance stack so the panel can't rattle)

---

## Print the bezel test tile first

`bezel_test.stl` is just the front face plus a stub of the module pocket — about 25
minutes. It exists because **one dimension in this model is an estimate**: where the
active (ink) area sits on the module's PCB. Drop the module into the test tile:

- the ink area should be fully visible with a thin white border on all four sides
- the PCB should drop into the pocket without force

If the ink is clipped or noticeably off-centre, adjust `act_off_x` / `act_off_z`
(see *Tuning* below) and re-print the tile. Only then print the frame.

---

## Assembly

1. **Frame** — drop the e-paper module in from the back, glass toward the bezel. It
   seats against the inside of the front face. The ribbon/connector edge goes on the
   **left** (the side with the USB-C opening).
2. **Cover** — slide the ESP32 driver board into the rails on the inner face of the
   cover, component side facing away from the cover, USB-C toward the left end stop.
   It slides in from the right and butts against the two lugs on the left.
3. Stick foam tape along the three tall retention ribs on the cover.
4. Plug the module's 8-pin cable into the driver board. There is a wide open channel
   between the module and the board for the cable — route it however it wants to sit.
5. Drop the cover on (the register lip locates it) and drive the four M2.5 screws.
6. **Kickstand** — spring the arms apart slightly and push the two inward-facing tabs
   into the sockets on the left and right walls. It should be a firm friction fit.

To reflash the board or flip its DIP switches, remove the four screws — the board stays
attached to the cover.

---

## Key dimensions

| | |
|---|---|
| Overall | 103.1 W × 125.2 H × 23.0 D mm |
| Footprint (front edge to kickstand foot) | ~44 mm |
| Lean angle | 12° back |
| Bezel opening | 67.6 × 88.8 mm (active area + 2 mm all round) |
| Bezel width | 17.8 sides / 19.7 bottom / 16.7 top |
| Module pocket | 79.7 × 104.2 mm, 4.8 mm deep from the front face |
| Internal clearance behind the module | ~10 mm before the driver board |
| Wall thickness | 2.4 front, 8.0 sides, 2.4 cover |

---

## Verify these before you commit to a long print

The model is built from Waveshare's published figures plus a few reasonable
assumptions. In rough order of how much trouble a wrong value causes:

| Parameter | Model value | How to check |
|---|---|---|
| `act_off_x` | 3.7 mm | Offset of the ink area's centre from the PCB's centre, measured across the **short** (78.5 mm) axis, positive away from the ribbon edge. This is the estimate the bezel test tile is for. |
| `mod_glass_t` + `mod_pcb_t` | 1.2 + 1.6 mm | Total front-to-back thickness of the module at the glass, calipers on a corner. Sets the depth of the pocket. |
| Component height behind the PCB | assumed ≤ 10 mm | Tallest thing on the back of the module, including the mated 8-pin cable. If it's more, raise `depth`. |
| USB-C position on the driver board | centred on the short edge | If it isn't centred, shift `usb_w` / the board position. |
| Driver board thickness with components | assumed ≤ 4.5 mm on the front side | Nothing on the cover side should be taller than `brd_standoff` (2.5 mm) plus the 3 mm relief pocket. |

---

## Tuning

Open `src/epaper_stand.scad` — every number is a named parameter at the top, grouped
under Customizer headers. Change, then re-export:

```bash
openscad -o stl/frame.stl     -D 'part="frame"'     src/epaper_stand.scad
openscad -o stl/cover.stl     -D 'part="cover"'     src/epaper_stand.scad
openscad -o stl/kickstand.stl -D 'part="kickstand"' src/epaper_stand.scad
openscad -o stl/bezel_test.stl -D 'part="bezel_test"' src/epaper_stand.scad
```

Useful knobs:

| Want | Change |
|---|---|
| Different lean | `lean` (frame) — the bottom chamfer and kickstand length both follow automatically |
| Kickstand further back / more stable | `ks_phi` (leg angle) or `ks_z` (socket height) |
| Wider or narrower bezel | `side_wall`, `bot_bezel`, `top_bezel` |
| More/less white border showing | `win_margin` |
| Tighter or looser kickstand | `tab_fit` |
| Landscape instead of portrait | swap `mod_w`/`mod_h` and `act_w`/`act_h`, and swap `act_off_x`→`act_off_z` |
| Thicker body (taller components) | `depth` |

The file also has built-in interference checks. Set `chk` to one of `frame_module`,
`cover_module`, `cover_board`, `frame_board`, `frame_cover`, `frame_ks`, `cover_ks`
and render — anything with volume is a collision:

```bash
openscad -o /tmp/chk.stl -D 'part="none"' -D 'chk="cover_board"' src/epaper_stand.scad
```

Preview modes: `part="standing"` (assembled on a table), `"assembly"`, `"section"`,
`"plate"` (all parts laid out).

---

## Renders

`renders/` — iso, front, side, back, USB side, cover interior, kickstand, and the frame
in its print orientation.

## Sources

- [Waveshare 4.2inch e-Paper Module (B) — wiki](https://www.waveshare.com/wiki/4.2inch_e-Paper_Module_(B))
- [Waveshare 4.2inch e-Paper Module (B) — product page (103.0 × 78.5 mm, 84.8 × 63.6 mm active)](https://www.waveshare.com/4.2inch-e-paper-module-b.htm)
- [Waveshare e-Paper ESP32 Driver Board — wiki (29.46 × 48.25 mm)](https://www.waveshare.com/wiki/E-Paper_ESP32_Driver_Board)
- [TRMNL kickstand — arms into half-moon pockets](https://help.trmnl.com/en/articles/11360753-how-to-replace-your-kickstand)
