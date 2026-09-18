# TODO — 4.2" e-Paper desk frame

Open action items, in the order they block each other. Everything here was pulled out of
the [README](README.md), which now describes only what the build *is*.

Re-export and re-draw after any parameter change:

```bash
openscad -o /tmp/p.stl -D 'part="params"' src/epaper_stand.scad 2>&1 \
  | sed -n 's/^ECHO: "P|\(.*\)"$/\1/p' | tr '|' '=' > /tmp/params.txt
python3 tools/mkdrawings.py && python3 tools/mkpage.py

for p in frame cover leg bezel_test; do
  openscad -o stl/$p.stl -D "part=\"$p\"" src/epaper_stand.scad
done
sh tools/mkrenders.sh
sh tools/mkfusion.sh
```

The renders import `stl/*.stl`, so re-export the STLs before re-rendering or the pictures
will show the previous revision. `tools/mkfusion.sh` reads the model directly and rebuilds
everything in [`fusion/`](fusion/) — parameters, keep-outs, DXF sections and meshes.

---

## 1. Still to measure — blocks the print

Answered and now in the model: the driver stack (16.0), the USB-C body (14 × 4.5), the
adapter's depth (`adapt_env` 5.0), the carrier's mounting holes (Ø2.0 at 26 × 66 centres),
the ribbon's route — it leaves the **centre of the RIGHT side**, legs of 4 / 20 / 10 — and
which side that is. What is left:

- [ ] **The female header row spacing** on the driver board. Not modelled. The carrier's
      mounting holes are measured now, so this only decides where the *headers* are soldered,
      not where the board sits — but it still has to match the driver's pin rows.
- [ ] **The heat-set inserts you actually have** — the model assumes M2.5, Ø3.6 bore × 5.0
      deep. Set `ins_d` / `ins_l` and re-export if yours differ.
- [ ] **The second FPC**, adapter to driver board. Length and width, and whether it exists in
      the parts box. It has no geometric constraint — routed by hand — but it wants to be long
      enough for the cover to come off and sit beside the frame, not just span the closed gap.

## 2. The adapter — solved

It is **taped to the back of the glass**, at x −40.45 … −22.45, z 65.75 … 97.75. There is
14.8 mm of depth there against the 5 it needs, it clears the driver's parts by 2.0, and leg 3's
turn falls inside its span. `adapt_board` and `adapt_cover` are both empty. No bosses, no
screws, no layout move — and taped to the glass it stays with the frame, so only the long FPC
crosses the split.

Both numbers that were gating it are measured: `adapt_env` 5.0, and leg 3 at 10 mm, which
lands on the adapter (it ends between x −35.2 and −26.2 against a footprint of −40.45 … −22.45).
The tail folds over onto the adapter and the cable on to the driver is routed by hand, so
nothing downstream is constrained. Nothing to design; two things to do at assembly:

- [ ] Use **foam** double-sided tape, not a thin film, and route the tail so its spring-back
      loads the tape in shear. Shear is ~46 N against a 0.02 N part; peel is the failure mode.
- [ ] Order the second FPC once the loop length is known — long enough for the cover to come
      off and be set down beside the frame, not just to span the closed gap.

## 3. The ribbon hollow — one small decision left

- The 18 vs 24 mm disagreement over the tail length **no longer blocks anything**: the hollow
      is sized generously at 49 mm (14.5 below the exit, 34.5 above), which covers leg 2 at
      anything from 0 to 34. Oversize costs nothing here; undersize is the only failure. Worth
      re-measuring out of curiosity, not as a gate.
- [ ] Leg 1 wants 4 mm out from the glass edge and the relief gives 3.75 — 0.25 short.
      `rib_clr = 3.25` fixes it but grows the frame 0.5 mm on the short axis. The stance no
      longer rides on the frame width, so only the frame moves. Decide whether to spend it.

## 4. Still open from the relayout

- [x] **Measure the charger breakout's mounting holes.** Done, off Adafruit's own solid model
      rather than with calipers: `fusion/vendor/adafruit-6091-bq25185-charger.step` has four
      Ø2.5 holes at (2.54, 2.54), (2.54, 22.86), (29.21, 2.54) and (29.21, 22.86) on a
      31.75 × 25.40 PCB. `chg_hx` / `chg_hz` are now **26.67 × 20.32**, up from the assumed
      25 × 19.3 — the guess came off the 32 × 26.3 *product* envelope, which includes the
      USB-C jack's overhang, and it put every post ~1 mm inboard of its hole.
- [ ] **Check the posts land on board rather than on components** on the first dry fit, and
      that the charger's Ø2.5 holes take the M2 screws with room to spare.
- [ ] **Confirm the M2 inserts you have.** The posts are bored Ø2.9 × 5.0 for a 3.2 × 4.0
      insert. Set `chg_ins_d` / `chg_ins_l` if yours differ — the post height and `chg_back`
      follow from them, and so does whether the board still clears the glass in front of it.
- [ ] Solder two 19-pin female headers to the carrier to match the driver's pin rows. The
      board's own mounting holes are now modelled (Ø2.0 at 26 × 66 centres) and the cover has
      pegs for them, so it does not need cutting to size — the adapter is taped to the glass
      and never competes with it for board area.
- [ ] The driver stack has **1.45 mm of margin** (16.0 measured against 17.45) — the carrier
      misses the stand recess entirely, so it datums to the cover's register face at 22.6
      rather than to the recess floor's backing at 18.7, less the 2.5 `carrier_lift` holds it
      off that face for its solder joints. **Confirm the 16.0 before committing to the frame**,
      and measure how far the header joints actually stand proud of the carrier's underside: if
      they need less than 2.5, dropping `carrier_lift` hands the margin straight back.

## 5. Test-print the leg (~3.2 g, ~12 min) — the whole stand is one part

Push the Ø2 × 18 rod through the printed leg (2.5 proud each side), then press that subassembly
into the cover's pocket from the back so both rod ends snap into their ears. The rod cannot go
in afterwards. Parts, print orientation and the assembly order are in the README under **The
stand subassembly**. It needs one rod and nothing else — no screws, no inserts, no clips.

**Print it with supports.** The heel's stop flat is a 35° overhang. It is the only part in the
build that needs them.

**The travel.** Walk the *whole* stroke, not just the two ends.

- [ ] The leg should swing 0° → 35° without binding anywhere.
- [ ] **Deployed, it should take a firm shove without folding.** The heel's flat is the stop;
      if the leg keeps rotating past ~35° the flat is not landing — check the print for support
      material still stuck to it before changing any parameter.
- [ ] **Measure the lean with a protractor** against the drawn 22.3° / 34.1 mm footprint. If it
      reads more upright, the heel is not reaching the floor; if it reads flatter, something is
      holding the leg off the seat.
- [ ] Folded, the leg should sit **flush with the back face** and nothing should overhang the
      bottom edge.

**Folded, nothing holds it.** The pocket has no latch and no detent, so:

- [ ] **Decide whether the leg staying shut matters.** Pick the display up, tip it forward, and
      see whether the leg swings out on its own. If it does and that is annoying in use, a lip
      across the pocket mouth is the one-line answer (`lip_h`, in git at the commit before the
      pocket was cleaned out) — but it puts a bridge back in the pocket.
- [ ] **Check the finger access actually works.** Off the ears there is 2.5 open either side of
      the leg, the whole length, at the full 4.5 depth. If a nail won't go under the leg's edge,
      the pocket has to get wider — but `rec_w` is capped at ~18.9 by the driver carrier at
      x −11.45, and widening it also widens `leg_w`'s derivation.
- [ ] **Hold the cover up to the light before assembling.** The pocket must be blind everywhere:
      no daylight through its floor, none through either **end wall** (the step at z 11.3 and
      the far end at z 63.5 — that pair was open into the electronics bay until the boss was
      made to overrun the pocket), and the two ears solid with their C-mouths open into the
      pocket, not through the back face. `chk="rec_floor_gap"` covers all of it in the model,
      but a thin wall can still print through.
- [ ] **Check the bottom of the pocket once frame and cover are screwed together.** The floor
      plate stops 1.15 mm clear of the rear chamfer so its fit gap cannot surface there — look
      along the bottom edge and there should be no slot into the frame. The model is sealed
      (`POCKET FLOOR PLATE` echo); what a print does with a 0.15 mm fit gap and a 1.15 mm
      ledge is the thing to confirm. Behind that plate the frame is now solid, so even a bad
      print there opens into material rather than into the case.

**The pin socket.** This is the one feature that could fail on the first assembly:

- [ ] The rod should **snap past the socket mouth** (1.51 across a 2.1 bore) and then be
      retained. If the lip shears instead of flexing, raise `ear_mouth` toward 0.8 so there is
      less to deflect, and check the cover printed the mouth open rather than bridged over.
- [ ] **This is the only way the rod goes in.** Nothing can be threaded along the pivot axis
      from inside the cover: at depth 23.0 the register plate fills the depth either side of
      the recess boss, so there is no straight run for an 18 mm rod. Tension from the back
      face is the route, which is why the sockets keep their C-mouths.

**After a few dozen cycles:**

- [ ] Check the pin and its two sockets for wear — they are the only sliding contact left in
      the stand.
- [ ] Check the heel's contact patch. It is a 3.07 × 14 face, so bearing stress is negligible;
      if it is visibly rounding over, the flat is not seating square.

## 5b. Fridge magnets

`mag_fit = false`: the discs are **glued onto** the back face, not sunk into it. The pigtail
flange stands 2.00 mm proud and is the rearmost thing on the case, so a sunk disc sat 2.2 mm
off the door and gripped nothing; a 2 mm disc on the surface is exactly as proud as the flange
and reaches the steel. The positions are still derived and still printed by the `FRIDGE
MAGNETS` echo — glue to those, not by eye.

- [ ] **Test the fridge door with any magnet.** A lot of "stainless" doors are austenitic and
      hold nothing at all.
- [ ] **Mark x ±27.6 before gluing** — z 83.65 on the +X side, z 92.1 on the −X side. Equal x
      is the whole rule: it puts the pair's centroid on the centreline. Offset, it hangs
      crooked. Re-read the echo first if you changed `mag_d`, because `mag_x` moves with it.
- [ ] **Measure the discs you actually have.** The model assumes Ø8 × 2. `mag_t` is what makes
      the surface mount work — a disc thinner than the flange's 2.00 mm will not reach the
      door, and the fix for that is a spacer under it, not a thinner flange.
- [ ] **Glue with epoxy, not CA.** A surface-glued disc is held by the bond alone, and CA is
      brittle in peel — which is the load a disc sees when you pull the case off the door.
      Scuff both faces, and let it cure before hanging anything on it.
- [ ] **Hang it and leave it a week before trusting it.** ~3.3x shear margin is calculated, not
      measured. If the door is thin-skinned and it slips, the fix is bigger discs — check the
      echo's positions again afterwards, because both move with `mag_d`.

## 6. Print and check the bezel test tile before the frame

- [ ] Print `stl/bezel_test.stl`, front face down (~40 min, ~20 g).
- [ ] Drop the real module in. Check: glass seats in the 77.5 × 91.5 pocket, all four
      pocket corners clear on their R1.4 relief, the window lip sits flush, and the
      **ribbon folds back through the 49 mm hollow without strain** — 3 mm out from the
      pocket edge and 3 mm past the glass back face. The hollow straddles the **centre of
      the RIGHT side** and runs towards the TOP (30.5 up from the BOTTOM, 49 long, 10.5
      short of the TOP). Check the side and the position before anything else — both were
      wrong until 2026-08-25, and the hollow is deliberately oversized because too big
      costs nothing and too small does not.
- [ ] Check the white border shows evenly: 0.7 mm on the short axis, 1.3 mm on the long.
      Lopsided means `act_off_x` (3.2, derived from the measured 3.0 / 9.4 borders) is off.
- [ ] Melt four **M2.5** inserts into the frame's corner bores, flush with the mating face,
      and check the countersunk heads finish level with the back face.

## 7. Electrical assembly

- [ ] Set the bq25185's charge current to **1 A** with the solder jumper. Adafruit's
      product page and pinout guide disagree on the default (1 A vs 500 mA) — read the
      board, don't assume.
- [ ] **Cut the TH jumper** and wire the cell's yellow lead to the **TH** pad. The pack's
      NTC is confirmed (10 kΩ yellow→black at room temperature), so the charger should be
      using it: it then refuses to charge outside roughly 0–45 °C.
- [ ] Wire red → B+, black → B− on the JST battery pigtail (polarity verified on this
      pack).
- [ ] Wire the USB-C pigtail's **VBUS** and **GND** to the charger's VBUS and GND pads.
      Confirm the pigtail has the 5.1 kΩ CC1/CC2 pulldowns, or no USB-C source will turn
      its 5 V on. The port now sits at x −5, z 92, immediately left of the charger, so this
      is a ~4 mm run — leave a little slack so the cover can still lift off.
- [ ] Build the battery divider: 100 kΩ from cell + to **GPIO 35**, 100 kΩ from that
      same tap to the driver board's GND. Full wiring and why GPIO 35 is in the README's
      "Wiring the battery sense". The firmware already reads it; until it is fitted the
      pin floats and Home Assistant shows ~0 V.
- [ ] Once the divider reads true, add the low-voltage cutoff (~3.6 V, sleep with no wake
      source). Left out on purpose while the pin floats — a floating read looks like a
      flat cell, and that path has no way back inside a sealed case.
- [ ] **Flash the ESP32 and confirm OTA works before the cover goes on.** The flash port
      is closed (`flash_port = false`) and the charge port is deliberately two wires, no
      data — after assembly there is no wired route in.
- [ ] Set the **DIP switch so the USB-UART is unpowered** when running (on only to
      program). Left powered, idle draw goes from ~2 mA to 10–13 mA. On the Rev 3 board
      that chip is a CH343, not the CP2102 the older product page quotes.
- [ ] Use **GPIO 4's panel-rail gate**: the schematic has it driving an S8050 that switches
      VDD5V → VDD5V′, so firmware can drop the panel supply in sleep. Keep GPIO 4 off the
      button list.

## 8. Firmware

- [ ] Read the divider on **every** wake. Below ~3.6 V, call `esp_deep_sleep_start()` with
      no timer and stay there. The board browns out at 3.6 V on its own, but a brownout
      loop drags the cell to its protection cut, and deep discharge is what kills cells.
- [ ] Show state of charge from the same reading, and stop refreshing when the cell is low.

## 9. Measurements worth taking once it runs

- [ ] Put a multimeter **in series with the battery lead** and read the real sleep current.
      Waveshare's `<2 mA` is a spec, not this board, and a USB meter won't resolve single
      milliamps. Everything in the runtime estimate hangs off this number.
- [ ] If there's a power LED on the driver board, measure what cutting it saves — often
      1–2 mA.

## 10. Optional, not started

- [ ] Three side buttons: `btn_n = 3`, then `btn_d` / `btn_sp`, and re-export the frame.

## 11. Housekeeping

- [ ] `drawings/4.2in-frame-drawings.pdf` is stale — it predates the current sheets. It was
      printed from `drawings/index.html`, so regenerate it the same way (or drop it and
      treat the SVG sheets plus `index.html` as the only drawing deliverables).
- [ ] `slicer/assembly-test.3mf` and `slicer/leg-test.3mf` predate the stand redesign — they
      were saved from an older set of STLs (including the deleted `disc.stl`) and will open
      with stale geometry. Re-save them from the current exports or drop them.
- [ ] `src/` still carries `epaper_stand_v2/v3/v4.scad` alongside the live
      `epaper_stand.scad`. Decide which are worth keeping and move the rest next to
      `archive-v1-wedge/`.
</content>
