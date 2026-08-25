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

Answered on 2026-08-25 and now in the model: the driver stack (16.0), the USB-C body
(14 × 4.5), the ribbon tail (18 flat), and which end the ribbon leaves from (the **ribbon
end** — the top in portrait, so `rib_off = 35`). What is left:

- [ ] **The FPC adapter's screw holes** — diameter and inset from each edge. The model
      assumes Ø2.2 at 2.0 mm, which is a guess, and it decides the mounting bosses.
- [ ] **The adapter's connector positions** — which edge each FPC socket is on, and how far
      along. Leg 3 only turns inboard about 4 mm, so a socket on the wrong edge of the
      adapter moves the whole board.
- [ ] **The adapter's depth with both FPCs seated** (`adapt_env`, assumed 5.0).
- [ ] **The second FPC** — the one from the adapter to the driver board. Length and width,
      and whether it exists in the parts box or needs ordering.
- [ ] **The female header row spacing** on the driver board. Not modelled, and it decides
      where the carrier's holes go — everything about the driver's position follows.
- [ ] **The heat-set inserts you actually have** — the model assumes M2.5, Ø3.6 bore × 5.0
      deep. Set `ins_d` / `ins_l` and re-export if yours differ.

## 2. The adapter is a service loop — decide how to pay for it

The tail *does* reach the driver: the board faces down so its socket edge is nearest the
display, and turned end-for-end (`fpc_end = "top"`) it fits at z 39.5 … 87.75. The problem is
that the glass is on the frame and the driver is on the cover, so the joint crosses the split,
and the tail has **3.4 mm** of give against the **~25 mm** a ZIF release needs.

- [ ] **Try the cheap way first: can you release the tail's ZIF with the cover barely open?**
      The fold gives about 3.4 mm of lift. If a fingernail or a spudger gets on the lever in
      that, nothing crosses the split, `adapt_fit = false`, and everything below goes away.
      This is a hands-on check, not a calculation.
- [ ] If not, the adapter needs **4.6 mm of depth that does not exist** (16 stack + 5 adapter
      against 16.4). Pick:
      - `depth` 25 → 29.6 — the frame gets thicker;
      - low-profile female headers, `hdr_h` 8.5 → 5.5 — buys 3.0, still 1.6 short;
      - both — 1.6 mm of depth plus a different header.
- [ ] And it still needs a home: where leg 3 puts it overlaps the carrier. Shorten the carrier
      and re-home the battery divider, or move the driver column.
- [ ] Then four mounting bosses at its hole positions, off the cover or the carrier.
- [ ] Re-run `adapt_board` and `adapt_cover`; both should be empty once it has a home.
- [ ] Order the second FPC once the loop length is known — long enough for the cover to come
      off and the connector to be reached, not just to span the gap.

## 2z. The ribbon's two length figures disagree

- [ ] The route needs at least **24 mm** of developed tail before leg 3 starts (4 out + 20 up),
      against the **18 mm** measured flat. Re-measure. Whichever is right decides whether leg 2
      really runs 20 mm, and `rib_w` / `rib_off` are derived from it, so the slot moves with it.
- [ ] Leg 1 wants 4 mm out from the glass edge and the relief gives 3.75 — 0.25 short.
      `rib_clr = 3.25` fixes it but grows the frame 0.5 mm on the short axis, which moves
      `hub_z = W/2` and the stance with it. Decide whether to spend it.

## 2a. Still open from the relayout

- [ ] Confirm the charger's four standoff pads land on board, not on components. Its hole
      spacing is deliberately not modelled.
- [ ] Cut the **driver carrier** — size depends on §2 — from double-sided 0.1″ prototype
      board, and solder two 19-pin female headers to match the driver's pin rows.
- [ ] The stack over the puck has **0.4 mm of margin** (16.0 measured against 16.4). Check
      it for real before committing to the frame: if the stack is over 16.4, the depth has
      to grow or the board has to come off the pocket.

## 2b. Test-print the disc and leg (10 g, ~25 min)

Walk the **whole** travel, not just the two ends — the heel corner that jammed at 64° was
clear at both ends.

- [ ] The leg should swing 0° → 122° without touching the pocket floor anywhere.
- [ ] The folded catch should take a firm push to close and a deliberate pull to open
      (`catch_p` tunes it).
- [ ] The leg should hold wherever it is put, and take a light thumb push to move — about
      0.31 N at the foot. **`clamp_pr` is the number to tune** (0.5 now: 0.4 of it removes
      the slot play, the remaining 0.1 is interference on the clamp tongue). Too loose,
      raise it 0.05 at a time; won't go in, drop it.
- [ ] Deployed, it should take a shove without folding, and stop against the slot's rear
      wall rather than drifting.
- [ ] **Measure the lean angle with a protractor**, in both orientations, against the drawn
      20.5° / 31.9 mm footprint. If it reads flat, `stop_wall` is not being reached and
      wants to come in — not `stop_ang` changed.
- [ ] Check the wall's contact patch after a few dozen cycles. It is a corner landing near
      the wall's top edge; if it is visibly rounding over, the wall wants a small radius.

## 2c. The snap-out detent — a product decision, not a geometry one

Three of the four leg problems are fixed and in the STLs: the hub sweep relief (it used to jam
1.80 mm into the pocket floor at 64°), the clamp land and its flexure tongue (10.9 N·mm, 31×
gravity), and a firm stop at the deployed angle. The **click** is not built, and cannot be
built while the leg folds flush — a projecting lug is capped at **0.25 mm** at `disc_t = 4` and
only **0.39 mm** at 6, both at or below what a 0.4 mm nozzle resolves. Thickening the disc does
not fix it. (An earlier note here claimed `disc_t = 6` made it workable with a 0.69 mm pocket.
That used the wrong constraint and is wrong.)

- [ ] **Decide whether the leg may stand proud of the rear face when folded.** A lug at
      leg-local 58°, radius 4.0, bites 0.75 mm into the stop wall at the deployed angle and
      stands 1.39 mm off the back next to the hub when folded. That buys a real click. Say yes
      and I build it; say no and the leg stays as it is — which holds fine, it just does not
      snap.
- [ ] Either way the friction is at its ceiling: `clamp_pr` 0.5 gives 0.10 mm of interference
      and 35 MPa at the tongue root, against ~50 MPa yield. 0.14 mm is the most it will take
      (15.3 N·mm). Do not raise it past that expecting more hold.

## 3. Print and check the bezel test tile before the frame

- [ ] Print `stl/bezel_test.stl`, front face down (~40 min, ~20 g).
- [ ] Drop the real module in. Check: glass seats in the 77.5 × 91.5 pocket, all four
      pocket corners clear on their R1.4 relief, the window lip sits flush, and the
      **ribbon folds back through the 40 mm slot without strain** — 3 mm out from the
      pocket edge and 3 mm past the glass back face. The slot straddles the **centre of
      the RIGHT side** and runs towards the TOP (38.5 up from the BOTTOM, 33 long, 18.5
      short of the TOP). Check the side and the position before anything else — both were
      wrong until 2026-08-25.
- [ ] Check the white border shows evenly: 0.7 mm on the short axis, 1.3 mm on the long.
      Lopsided means `act_off_x` (3.2, derived from the measured 3.0 / 9.4 borders) is off.
- [ ] Melt four **M2.5** inserts into the frame's corner bores, flush with the mating face,
      and check the countersunk heads finish level with the back face.

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
