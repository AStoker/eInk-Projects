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

## 1. Measure these on the real hardware — blocks every print

The model assumes these. Each is a caliper measurement on the real hardware, and each
one moves geometry.

- [ ] **The driver board's stack: PCB plus its tallest part** → sets `drv_env`
      (**assumed 6.0**: 1.6 of PCB plus ~3.2 for the USB-C shell / WROOM module, plus
      margin). This is the single number the whole depth budget now rests on. There is
      14.8 mm where the board crosses the stand pocket and 19.35 mm off it.
- [ ] **The panel ribbon: length from the glass edge to the end of the tail, and how much
      of it the 180° fold at the pocket edge eats** → decides where the driver board can
      sit for the FPC to plug straight in with no adapter.
- [ ] **Which physical end of the panel `rib_off = 15` is measured from.** The model's −Z
      glass edge is one specific end; if it is the other, `rib_off` becomes 35 and the
      internal bands move with it.
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

## 2. Relayout — done, but the numbers under it are still assumptions

Built on 2026-08-24. The panel is bare glass and an FPC tail, so the 78.5 × 103 PCB the
model used to size everything around is gone (`bare_panel = true`), and with it the 2.2 mm
end walls that left nowhere to put a screw.

| | Before | Now |
|---|---|---|
| Interior | 79.5 × 104, sized by a phantom PCB | 82.1 × 80.9, sized by the electronics |
| End walls | 2.2 mm | 13.75 mm |
| Screws | 3, all down the +X side | **4, one near each corner** |
| Driver board | +X side, socket 46 mm from the ribbon | −X wall, socket at z 44.2, opposite the middle of the ribbon slot |
| Charger | on a quarter Perma-Proto | four standoff pads of its own |
| Perma-Proto | quarter-size, 43.2 × 50.8 | gone — divider on a scrap of perfboard |
| Real interferences | 2 | **0**, all 14 checks clear |

- [ ] Confirm the ribbon actually reaches with the socket at z 44.2 — that is item 1's tail
      measurement. If the tail is shorter than the route needs, the board slides along Z and
      the columns move with it.
- [ ] Confirm the charger's four standoff pads land on board, not on components. Its hole
      spacing is deliberately not modelled.
- [ ] Cut the **driver carrier: 30 × 70 mm** of double-sided 0.1″ prototype board, and
      solder two 19-pin female headers to match the driver's pin rows. **Measure the row
      spacing** — the model does not know it, and it decides where the holes go. The
      divider goes on the ~14 × 30 of spare board below the driver.
- [ ] Measure the **female header height** (`hdr_h`, assumed 8.5) and the **pigtail body**
      (`snap_w` / `snap_h` / `snap_d`, assumed 15 × 8 × 10). The header height and `drv_env`
      between them leave only 0.3 mm of margin in front of the driver.
- [ ] Test-print the **disc and leg** (10 g, ~25 min) and check both ends of the travel:
      the folded catch should take a firm push to close and a deliberate pull to open
      (`catch_p` tunes it), and the hinge clamp screw should hold the leg deployed against
      a shove without being hard to move (tighten to taste; `leg_slot_c` sets how much the
      walls have to close).
- [ ] Check your heat-set inserts against the model's assumption (M3, 4.6 OD × 5.7 long,
      Ø4.0 bore). Brands differ; set `ins_d` / `ins_l` and re-export if yours do.

## 2c. The glass could not be installed — twice

Worth recording because both were the same mistake in different clothes, and neither is the
kind of thing an interference check finds. Nothing intersects; the part simply has no path
in.

1. **Long axis.** The interior was sized by the electronics (80.9) and the glass is 90.
   Fixed by `glass_pass_h`.
2. **Short axis.** The interior was wide *enough* (81.6 against a 76 glass) but the glass is
   offset 3.2 mm to centre the ink, so it sat 0.4 mm outside on the −X side. Comparing sizes
   passes; comparing extents does not. Fixed by `glass_x0` / `glass_x1`, and the echo now
   prints extents.

Corner posts inside the interior were tried and abandoned: with 9 mm posts the glass is
blocked by 5.9–7.0 mm however deep the posts start, and tilting does not help — the interior
is 20.9 mm deep against a 90 mm glass, so the glass is flat long before its far end is low
enough to clear anything. The screws are in the end walls, which cost 2.1 mm of frame
length at M2.5.

## 2b. What this round changed, and what it left open

The glass could not be installed at all: the interior had been sized by the electronics
(80.9 on the long axis) and a 90 mm glass has no way into its pocket except through it.
The interior is now 81.6 × 92.5, set by `glass_pass_h`, and there is an echo line that says
so on every run.

| | Was | Now |
|---|---|---|
| Glass into the pocket | impossible — walled out by 9 mm | drops in from the back |
| Glass retention | a shelf that blocked it | two ribs on the cover |
| Corner screws | in 13.75 mm end walls | in 9 × 9 posts inside the interior, starting behind the glass |
| Driver mounting | printed side rails | plugs into female headers on a 30 × 70 carrier perfboard |
| Divider board | a separate 27.9 × 10.2 scrap | the spare ~14 × 30 of the carrier |
| Rear port | breakout board in printed rails | 15 × 8 snap-in pigtail, opening only |
| Folded leg | nothing held it | catch lip, ~5 N at the foot |
| Hinge pin | 0.15 / 0.25 clearance | 0.10 friction fit |

- [ ] **The header row spacing on the driver board** is not modelled — measure it before
      drilling the carrier. It decides where the female headers go, and everything about
      the driver's position follows from the carrier.
- [ ] **The pigtail's actual body size.** 15 × 8 × 10 came from the listing; a snap fit
      wants a caliper. `snap_w` / `snap_h` / `snap_c`.
- [ ] **Female header height** (`hdr_h`, assumed 8.5). With `drv_env` it leaves 0.3 mm in
      front of the driver — the tightest number in the build.

## 3. Print and check the bezel test tile before the frame

- [ ] Print `stl/bezel_test.stl`, front face down (~40 min, ~20 g).
- [ ] Drop the real module in. Check: glass seats in the 77.5 × 91.5 pocket, all four
      pocket corners clear on their R1.4 relief, the window lip sits flush, and the
      **ribbon folds back through the 40 mm slot without strain** — 3 mm out from the
      pocket edge and 3 mm past the glass back face.
- [ ] Check the white border shows evenly: 0.7 mm on the short axis, 1.3 mm on the long.
      Lopsided means `act_off_x` (3.2, derived from the measured 3.0 / 9.4 borders) is off.
- [ ] Melt four M3 inserts into the frame's corner bores, flush with the mating face, and
      check the countersunk heads finish level with the back face.

## 4. Electrical assembly

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
- [ ] Set the **DIP switch so the USB-UART is unpowered** when running (on only to
      program). Left powered, idle draw goes from ~2 mA to 10–13 mA. On the Rev 3 board
      that chip is a CH343, not the CP2102 the older product page quotes.
- [ ] Use **GPIO 4's panel-rail gate**: the schematic has it driving an S8050 that switches
      VDD5V → VDD5V′, so firmware can drop the panel supply in sleep. Keep GPIO 4 off the
      button list.

## 5. Firmware

- [ ] Read the divider on **every** wake. Below ~3.6 V, call `esp_deep_sleep_start()` with
      no timer and stay there. The board browns out at 3.6 V on its own, but a brownout
      loop drags the cell to its protection cut, and deep discharge is what kills cells.
- [ ] Show state of charge from the same reading, and stop refreshing when the cell is low.

## 6. Measurements worth taking once it runs

- [ ] Put a multimeter **in series with the battery lead** and read the real sleep current.
      Waveshare's `<2 mA` is a spec, not this board, and a USB meter won't resolve single
      milliamps. Everything in the runtime estimate hangs off this number.
- [ ] If there's a power LED on the driver board, measure what cutting it saves — often
      1–2 mA.

## 7. Optional, not started

- [ ] Slide switch in the charger's LOAD line, so the thing can be parked without draining.
      `btn_n` already cuts holes in the +X wall if you want it there.
- [ ] Three side buttons: `btn_n = 3`, then `btn_d` / `btn_sp`, and re-export the frame.

## 8. Housekeeping

- [ ] `drawings/4.2in-frame-drawings.pdf` is stale — it predates the current sheets. It was
      printed from `drawings/index.html`, so regenerate it the same way (or drop it and
      treat the SVG sheets plus `index.html` as the only drawing deliverables).
- [ ] `src/` still carries `epaper_stand_v2/v3/v4.scad` alongside the live
      `epaper_stand.scad`. Decide which are worth keeping and move the rest next to
      `archive-v1-wedge/`.
</content>
