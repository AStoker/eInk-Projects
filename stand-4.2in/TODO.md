# TODO — 4.2" e-Paper desk frame

Open action items, in the order they block each other. Everything here was pulled out of
the [README](README.md), which now describes only what the build *is*.

Re-export and re-draw after any parameter change:

```bash
openscad -o /tmp/p.stl -D 'part="params"' src/epaper_stand.scad 2>&1 \
  | sed -n 's/^ECHO: "P|\(.*\)"$/\1/p' | tr '|' '=' > /tmp/params.txt
python3 tools/mkdrawings.py && python3 tools/mkpage.py

for p in frame cover disc leg bezel_test; do
  openscad -o stl/$p.stl -D "part=\"$p\"" src/epaper_stand.scad
done
sh tools/mkrenders.sh
```

The renders import `stl/*.stl`, so re-export the STLs before re-rendering or the pictures
will show the previous revision.

---

## 1. Measure four numbers on the actual module — blocks every print

The model assumes these. Each one is a caliper measurement on the real
Waveshare 4.2" (B) module, and each one moves geometry.

- [ ] **Which long-axis edge the 8-pin header is on, and where it sits across the short
      axis** → sets `conn_dz` (assumed −44.5) and `conn_dx` (assumed 0, centred).
      This also settles which physical end `rib_off = 15` is measured from: the model's
      −Z edge is the same edge the header is on, because the ribbon folds back to it.
      If the header turns out to be on the other edge, `rib_off` becomes 35 **and** the
      cell/board bands swap — do not change one without the other.
- [ ] **How far the mated 8-pin header stands off the PCB back, including the wire bend**
      → sets `conn_h` (assumed 9.0). See item 2.
- [ ] **Whether the glass is centred on the PCB along the 103 mm axis** → sets `pan_off_z`
      and `act_off_z` (both assumed 0, i.e. 6.5 mm of bare PCB at each end). Waveshare
      publish 103 × 78.5 for the PCB and 91 × 77 for the glass but no datum between them.
      If the 12 mm of bare PCB is all at one end, the ink is 6 mm off where the window is
      cut.
- [ ] **The gap between the glass edge and the PCB edge on each side of the ribbon axis**
      → set `pan_off_x` to half the difference (assumed 0). Worth up to 1.6 mm of frame
      width and 0.8 mm of side bezel, all of it collected by the first 0.8 mm of offset,
      because the ribbon slot is what currently sets the width.

## 1b. Confirm which hand actually gets printed

`print_mirror = true`, so every exported STL is mirrored in X: the ribbon slot, the screw
spine and both ports come out on the **opposite side** to the drawing sheets. The flag was
set because the real module's ribbon is on the mirrored side — the same handedness
question the ribbon route just settled.

- [ ] With the module in front of you, e-ink face down, check which side the ribbon slot
      has to be on, and confirm `print_mirror = true` puts it there. The renders show the
      printed hand (`renders/01`–`06`, `11`); the sheets show the designed hand.
- [ ] If the model's hand was right all along, set `print_mirror = false`, re-export and
      re-render. Getting this wrong is a whole frame of wasted filament.

## 2. Resolve the 8-pin header vs cell clash — real interference, 1 of 2

```
HEADER vs CELL: needs 9, has 7.9 -> CLASH by 1.1 mm      (conn_cell, 154 mm³)
```

There is 7.9 mm clear over the cell and 12.7 mm over the boards, so the header has to end
up in the *board* band. Pick one, cheapest first:

- [ ] **Swap the bands** — boards into whichever band the header lands in, cell into the
      other. No thickness cost. Moves the driver board's USB-C to the opposite wall and
      pushes the charge port out of the board band, so `bat_cz` / `proto_z1` / `drv_z1`
      and `flash` all move together.
- [ ] **Right-angle PH2.0 housing**, or desolder the header and lay the eight wires flat
      off the pads. Keeps `depth = 25`; needs `conn_h ≤ 7.4`.
- [ ] **`depth = 26.6`** and re-export. Everything downstream follows, at +1.6 mm of
      thickness.

Whichever it is, re-run the checks and confirm `conn_cell` comes back empty.

## 3. Resolve the driver board's depth — real interference, 2 of 2

```
drv_module 1050 mm³   (30 × 50 footprint × 0.7 mm deep)
DRIVER BOARD envelope 30 x 50 x 15 | clear depth over the puck 14.8 -> SHORT by 0.2 mm
```

The board's assumed envelope is 15 mm deep — PCB plus its tallest component and the mated
display header — and it does not fit where it currently sits.

- [ ] **Measure the driver board's real envelope depth**, mated, including the ribbon
      header and the DIP switch. `drv_env` is an assumption; if the real number is 14 the
      whole thing goes away.
- [ ] If it is genuinely 15, move the board off the puck (19.35 mm clear there) or take the
      same `depth = 26.6` that would fix item 2 — one depth change can settle both. Re-run and
      confirm `drv_module` comes back empty.

## 4. Print and check the bezel test tile before the frame

- [ ] Print `stl/bezel_test.stl`, front face down (~40 min, ~20 g).
- [ ] Drop the real module in. Check: glass seats in the 77.5 × 91.5 pocket, all four
      pocket corners clear on their R1.4 relief, the window lip sits flush, and the
      **ribbon folds back through the 40 mm slot without strain** — 3 mm out from the
      pocket edge and 3 mm past the glass back face.
- [ ] Check the white border shows evenly: 0.7 mm on the short axis, 1.3 mm on the long.
      Lopsided means `act_off_x` (3.2, derived from the measured 3.0 / 9.4 borders) is off.
- [ ] Check the Perma-Proto's mounting-hole spacing against the model's 35.6 mm before
      printing the cover.

## 5. Electrical assembly

- [ ] Set the bq25185's charge current to **1 A** with the solder jumper. Adafruit's
      product page and pinout guide disagree on the default (1 A vs 500 mA) — read the
      board, don't assume.
- [ ] **Cut the TH jumper** and wire the cell's yellow lead to the **TH** pad. The pack's
      NTC is confirmed (10 kΩ yellow→black at room temperature), so the charger should be
      using it: it then refuses to charge outside roughly 0–45 °C.
- [ ] Wire red → B+, black → B− on the JST battery pigtail (polarity verified on this
      pack).
- [ ] Wire the USB-C breakout's **VBUS** and **GND** to the charger's VBUS and GND pads.
      Confirm the breakout has the 5.1 kΩ CC1/CC2 pulldowns, or no USB-C source will turn
      its 5 V on.
- [ ] Build the battery divider: two 100 kΩ from the cell to an ADC pin on **ADC1
      (GPIO 32–39)**. ADC2 is unusable while WiFi is on.
- [ ] **Flash the ESP32 and confirm OTA works before the cover goes on.** The flash port
      is closed (`flash_port = false`) and the charge port is deliberately two wires, no
      data — after assembly there is no wired route in.
- [ ] Set **DIP switch 2 off** for running (on only to program). Left on, the CP2102 stays
      powered and idle draw goes from ~2 mA to 10–13 mA.

## 6. Firmware

- [ ] Read the divider on **every** wake. Below ~3.6 V, call `esp_deep_sleep_start()` with
      no timer and stay there. The board browns out at 3.6 V on its own, but a brownout
      loop drags the cell to its protection cut, and deep discharge is what kills cells.
- [ ] Show state of charge from the same reading, and stop refreshing when the cell is low.

## 7. Measurements worth taking once it runs

- [ ] Put a multimeter **in series with the battery lead** and read the real sleep current.
      Waveshare's `<2 mA` is a spec, not this board, and a USB meter won't resolve single
      milliamps. Everything in the runtime estimate hangs off this number.
- [ ] If there's a power LED on the driver board, measure what cutting it saves — often
      1–2 mA.

## 8. Optional, not started

- [ ] Slide switch in the charger's LOAD line, so the thing can be parked without draining.
      `btn_n` already cuts holes in the +X wall if you want it there.
- [ ] Three side buttons: `btn_n = 3`, then `btn_d` / `btn_sp`, and re-export the frame.

## 9. Housekeeping

- [ ] `drawings/4.2in-frame-drawings.pdf` is stale — it predates the current sheets. It was
      printed from `drawings/index.html`, so regenerate it the same way (or drop it and
      treat the SVG sheets plus `index.html` as the only drawing deliverables).
- [ ] `src/` still carries `epaper_stand_v2/v3/v4.scad` alongside the live
      `epaper_stand.scad`. Decide which are worth keeping and move the rest next to
      `archive-v1-wedge/`.
</content>
