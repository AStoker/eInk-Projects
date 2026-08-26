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
      `rib_clr = 3.25` fixes it but grows the frame 0.5 mm on the short axis, which moves
      `hub_z = W/2` and the stance with it. Decide whether to spend it.

## 4. Still open from the relayout

- [ ] Confirm the charger's four standoff pads land on board, not on components. Its hole
      spacing is deliberately not modelled.
- [ ] Solder two 19-pin female headers to the carrier to match the driver's pin rows. The
      board's own mounting holes are now modelled (Ø2.0 at 26 × 66 centres) and the cover has
      pegs for them, so it does not need cutting to size — the adapter is taped to the glass
      and never competes with it for board area.
- [ ] The stack over the puck has **0.4 mm of margin** (16.0 measured against 16.4). Check
      it for real before committing to the frame: if the stack is over 16.4, the depth has
      to grow or the board has to come off the pocket.

## 5. Test-print the disc and leg (10 g, ~25 min) — one print, two things to check

All four leg problems are fixed and in the STLs: the hub sweep relief, the clamp land and its
tongue, the firm stop at the deployed angle, and the snap detent. Print the pair before
committing to a frame. Parts, print orientation and the assembly order are in the README under
**The stand subassembly** — it needs one Ø2 × 43.5 pin and nothing else, no screws or inserts.

- [ ] **Before assembling, hold the disc up to the light**: the detent bridge must be a free
      island, air in front and behind, right across its span. Fused to the stop wall it is
      6.2× too stiff and past yield. No interference check can see this — nothing intersects.

**The travel.** Walk the *whole* stroke, not just the two ends — the heel corner that jammed
at 64° was clear at both ends, which is exactly why it went unnoticed.

- [ ] The leg should swing 0° → 122° without touching the pocket floor anywhere.
- [ ] The folded catch should take a firm push to close and a deliberate pull to open
      (`catch_p` tunes it).
- [ ] The leg should hold wherever it is put, and take a light thumb push to move — about
      0.31 N at the foot mid-travel (0.83 N once the detent has seated at the deployed end).
      **`clamp_pr` tunes it** (0.5 now: 0.4 removes the slot play, the remaining 0.1 is
      interference on the tongue). Too loose, raise it 0.05 at a time; won't go in, drop it.
- [ ] Deployed, it should take a shove without folding, and stop against the slot's rear wall
      rather than drifting.
- [ ] **Measure the lean angle with a protractor**, in both orientations, against the drawn
      20.5° / 31.9 mm footprint. If it reads flat, `stop_wall` is not being reached and wants
      to come in — not `stop_ang` changed.

**The detent.** Expect the last ~12° of opening to firm up progressively, then a distinct
click as it seats.

- [ ] **`det_fit` is the tuning number** (0.06) — the pocket's growth over the tooth, which
      sets how far the tooth must deflect to leave. No click, drop it to 0.03; too stiff to
      fold, raise it 0.03 at a time. It inherited 0.225 once and there was no detent at all.
- [ ] If the leg catches around **60°**, the tooth's tip is being clipped — `det_tooth` is 0.9
      because 1.2 put the tip inside the leg's mid-sweep envelope.

**After a few dozen cycles**, check the two printed springs and the one bearing edge:

- [ ] The detent bridge (1.1 mm at 25.7 MPa against ~50 yield) — the only printed spring
      taking repeated load. **Check it is actually free**: it should be an island with air
      in front and behind across its full 20 mm span. It was fused to the stop wall beyond
      x ±5.45 once, which made it 6.2× too stiff and put it past yield; that was invisible
      in every clash check and only showed up in a cross-section of the mesh.
- [ ] The clamp tongue (35 MPa) — should be fine, but it is preloaded permanently.
- [ ] The stop wall's contact patch. It is a corner landing near the wall's top edge; if it is
      visibly rounding over, the wall wants a small radius.

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

- [ ] Slide switch in the charger's LOAD line, so the thing can be parked without draining.
      `btn_n` already cuts holes in the +X wall if you want it there.
- [ ] Three side buttons: `btn_n = 3`, then `btn_d` / `btn_sp`, and re-export the frame.

## 11. Housekeeping

- [ ] `drawings/4.2in-frame-drawings.pdf` is stale — it predates the current sheets. It was
      printed from `drawings/index.html`, so regenerate it the same way (or drop it and
      treat the SVG sheets plus `index.html` as the only drawing deliverables).
- [ ] `slicer/assembly-test.3mf` predates every change since 2026-08-25 — it was saved from
      an older set of STLs and will open with stale geometry. Re-save it from the current
      exports or drop it.
- [ ] `src/` still carries `epaper_stand_v2/v3/v4.scad` alongside the live
      `epaper_stand.scad`. Decide which are worth keeping and move the rest next to
      `archive-v1-wedge/`.
</content>
