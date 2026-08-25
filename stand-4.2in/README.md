# 4.2" e-Paper desk frame — minimal bezel, rotating kickstand, battery inside

A slim desk frame for the **Waveshare 4.2inch e-Paper panel (B)** driven by the
**Waveshare e-Paper ESP32 Driver Board (Rev 3)**, with a LiPo and a power-path charger
inside, and a single rotating kickstand on the back that folds flush and turns 90° for
portrait or landscape.

The panel is **bare glass and an FPC tail** — no PCB behind it. The tail plugs straight
into the driver board's 24-pin socket, and the board is positioned so it does that with no
adapter and no extension.

One parametric OpenSCAD file: `src/epaper_stand.scad`. Every dimension quoted here comes
out of it, and so does every drawing — `tools/mkdrawings.py` reads the model's own
parameter dump, so the sheets cannot drift from the STLs. **The renders are built from
`stl/*.stl` itself** (`tools/mkrenders.sh`), so what the pictures show is what the slicer
gets.

| | |
|---|---|
| Outer | 91.9 × 110.5 × 25.0 mm |
| Bezel | 13.45 mm short-axis sides, 11.55 mm long-axis ends |
| Panel white showing | 0.7 mm short axis, 1.3 mm long axis |
| Lean | 20.5°, 31.9 mm footprint — the same in both orientations |
| Interior | 81.6 × 92.5 × 21.0 mm, with 9 mm end walls |
| Fasteners | 4 × M2.5 countersunk into heat-set inserts, one near each corner |
| Print | 4 parts, ~107 g of filament, no supports |

<img src="renders/01-iso-portrait.png" width="46%" alt="Portrait"> <img src="renders/02-iso-landscape.png" width="46%" alt="Landscape">

![Sheet 1 — assembly and envelope](drawings/sheet1.svg)

Open [`drawings/index.html`](drawings/index.html) for all eight sheets on one page, and
[TODO.md](TODO.md) for what is still open.

---

## Names

Two dimensions got read as the wrong axis while this was being built, both times because
"width" and "height" swap over when the frame is turned. So: **never width/height for
anything belonging to the display.**

| Axis | Glass | Interior | Model | In portrait (the default) |
|---|---|---|---|---|
| **short axis** | 76 | 82.1 | X | horizontal |
| **long axis** | 90 | 80.9 | Z | vertical. **The ribbon leaves the glass on a long-axis edge, and runs along the long axis.** |
| **depth** | 1.05 | 21.0 | Y | 0 at the outer front face |

Depth is the axis that points *up* off the print bed, so "taller", "more room on top" and
"height off the glass" in slicer terms all mean **deeper** here.

### The ribbon route

Hold the module with the **e-ink face down**, so you are looking at the rear. The ribbon
leaves the glass on the **long-axis edge** — the one with the 9.4 mm dead border — folds
back behind the glass, then:

1. turns **90° to the left, running along the long axis**, and
2. turns **90° back to the right, away from the long axis**, to reach the driver board's
   24-pin FPC socket.

That middle leg is the whole reason for the shape of the cutout. The relief is a **40 mm
slot running along the long-axis edge**, not a local pocket where the ribbon exits: the
ribbon spends 40 mm travelling *parallel* to that edge before it turns back out. Sheet 4,
balloon 6, is the cutout itself.

The three sizes are deliberately *not* called width/height/depth:

| | Parameter | Now | Meaning |
|---|---|---|---|
| **out** | `rib_clr` | 3.0 | outboard from the pocket edge, along the short axis — the room the fold back on itself needs |
| **deep** | `rib_dep` | 3.0 | past the glass back face, along depth — so the fold has somewhere to go |
| **long** | `rib_w` | 40.0 | along the pocket edge, on the long axis — the run described above. `rib_off` pins one end, so raising this extends the slot in one direction only; it does not recentre |

The three long-axis numbers close exactly: **15 from one glass end, 40 of slot, 35 from the
other — 15 + 40 + 35 = 90** against a 90 mm glass, with `rib_far` reporting 35 rather than
absorbing an error. `rib_off = 15` is measured from the model's −Z glass edge; which
physical end of the panel that is has still to be pinned down — see [TODO.md](TODO.md).

**The ribbon's destination is the driver board itself.** The Waveshare e-Paper ESP32 Driver
Board (Rev 3, 48.25 × 29.46 mm) carries the panel's own DC-DC and a **24-pin FPC socket**
on one long edge — 16 mm of socket, centred 12.5 mm from one end. The panel plugs straight
in. There is no 8-pin header, no adapter board and no intermediate cable in this build, so
nothing stands off the back of the module: `mod_header = false`.

### The three nested recesses

Front to back. Not interchangeable, and each has its own clearances:

| Name | What it holds | Size | Parameters |
|---|---|---|---|
| **window** | nothing — it's the through-opening the ink is seen through | 65.0 × 87.4 | `win_*` |
| **glass pocket** | the glass, in a shallow step | 77.5 × 91.5 × 1.26 | `pan_*` |
| **interior** | the electronics — driver board, cell, charger | 82.1 × 80.9 | `cav_*` |

**The interior is sized by two things: the electronics, and the glass getting in.** The
glass has no way into its pocket except from the back, through the interior — the front lip
is smaller than the glass. So the interior opening has to clear the glass on every side:

```
GLASS GOES IN: interior x -42.45 to 39.15, z 9 to 101.5
             | glass    x -42.45 to 36.05, z 10.25 to 100.25
             -> clears on every side, drops straight in
```

Note that it checks **extents, not sizes**. The glass is offset 3.2 mm to centre the ink, so
an interior that is wide *enough* can still be in the wrong place — comparing sizes left it
0.4 mm short on the −X side, which is a glass that does not go in.

### Why there are no screw posts inside the interior

Corner posts would be the obvious way to get four corner screws without growing the frame,
and they do not work. A post at each corner leaves a 74.5 mm gap for a 90 mm glass, so the
glass would have to go in at an angle — and the arithmetic says it cannot:

| To shorten the glass's span to | you must tilt | which stands it |
|---|---|---|
| 85 mm | 19.2° | 29.6 mm tall |
| 83 mm | 22.7° | 34.8 mm tall |
| 81 mm | 25.8° | 39.2 mm tall |

The interior is **20.9 mm deep**. The glass is flat long before its far end is low enough to
clear anything, and flat it needs a post-free path the full 90 mm. Working it the other way:
with 9 mm posts the glass is blocked by 5.9–7.0 mm no matter how deep the posts start, and
only a **3 mm** post ever clears — which will not hold an insert.

So the screws go in the end walls, and the end wall has to be thick enough to take one:
rear chamfer + margin + head + margin. That is what sets the frame's long axis now.

| Insert | Head | End wall | Frame length | End bezel |
|---|---|---|---|---|
| M2 | 4.0 | 8.0 | 108.5 | 10.55 |
| **M2.5** | **5.0** | **9.0** | **110.5** | **11.55** |
| M3 | 6.0 | 10.0 | 112.5 | 12.55 |

M2.5 is the default: 2.1 mm of extra length against today, and four screws that go where
they are wanted. `insert_size` moves the whole frame with it.

### Vocabulary

- **bezel** — the visible plastic between the window edge and the outer edge (13.45 on the
  short-axis sides, 10.5 on the long-axis ends). Never the pocket. Also not a *bevel* — a
  bevel is an angled edge, which here is a **chamfer** (`front_chf`, `win_chf`, `rear_chf`).
- **clearance** / **margin** — the gap between a part and the recess holding it. Always
  quoted as the **total across an axis**, not per side: "margin 1.5 on the short axis" is
  0.75 a side.
- **relief** — material taken away at a **corner**, so a sharp-cornered part can seat in a
  printed corner that carries a nozzle fillet. Always centred *on* the corner; that is the
  function, so it cannot be moved inboard. One is fitted: **pocket relief** (`pan_rel` =
  1.4, at the glass pocket corners).
- **ribbon relief** — the slot described above.
- **white show** — `white_show_short` / `white_show_long`, the strip of the panel's own white
  border left visible inside the window on purpose. **One per axis** (0.7 short, 1.3 long),
  because the window is specified on the short axis and one shared value cannot do both.
- **parts** — **frame** (front shell), **cover** (back), **disc** (rotating puck), **leg**
  (kickstand), and the **bezel test tile** (front-face-only print for checking fit).
- **tape pad** — `tape_*`, a shallow recess in the **ledge behind the glass** where tape holds
  the glass down from the rear. Two of them, one at each long-axis end. Not visible from the
  front.

### How the glass is held

A printed 91.0 pocket measured short on the long axis, so the pocket is **77.5 × 91.5** —
1.5 mm of total margin on *both* axes, sized for print variance rather than for a press
fit. The front lip stops it coming forward. Behind it the interior is open, because it has
to be, so something has to press it back against that lip: **two ribs on the cover**, one at
each long-axis end, over the glass's dead border — 36 mm and 20 mm wide × 3.5 mm, standing
the full 21 mm from the cover face to just behind the glass. Foam tape on their faces takes
up the tolerance stack.

The top rib is the short one because the charger runs up that side of the interior.

---

## Power

One cell, one charger, one conversion. USB-C in at the back face, the charger's power-path
output straight to the driver board's 5V pin, which Waveshare specify as a **3.6–5.5 V
input** — a 1S cell drives it directly.

![Sheet 8 — power wiring](drawings/sheet8.svg)

- **Adafruit bq25185** (#6091, $6.95): USB-C in, JST battery, JST load out regulated to
  ≤4.5 V, real power path so the board runs from USB while the cell charges instead of
  cycling it. Charge current is a solder jumper — **set 1 A**, which is 0.5C for this cell.
  Adafruit's own two pages disagree on what it ships at (product page says 1 A, the pinout
  guide says 500 mA), so check the board.
- The board's 5V pin is an input only: no charge circuit, no battery connector, no charge
  LED. Running from a cell and refilling that cell are two separate jobs, which is why the
  charger is in the build.
- **Charge port is on the back face**, not the charger's own USB-C. A small USB-C breakout
  with the 5.1 kΩ CC pulldowns stands in printed guide rails behind the cover with its
  receptacle flush in the back face; two wires run from it to the charger's **VBUS** and
  **GND** pads. Charge only, no data — which is all this needs.
- **Battery divider:** two 100 kΩ from the cell to an ADC pin on **ADC1 (GPIO 32–39)** —
  ADC2 is unusable while WiFi is on. Firmware reads it on every wake and, below ~3.6 V,
  calls `esp_deep_sleep_start()` with no timer and stays there. The board browns out at
  3.6 V on its own, but a brownout loop drags the cell down to its protection cut, and deep
  discharge is what kills LiPo cells.

### One opening in the whole assembly

The **charge port in the back plate is the only hole in the finished case.** The driver
board's own USB-C — which is for *flashing*, not power — used to sit against the top wall
behind a blind pocket. Now that the board is stood on the −X side to meet the ribbon, its
jack ends up in the middle of the interior instead, so there is nothing to cut and nothing
to seal: the pocket is skipped entirely and the top wall is solid material.

⚠ **Flash the ESP32 before final assembly**, and leave OTA working. With the port closed
there is no wired access to the driver board once the cover is on. Set `flash_port = true`
to cut the opening back through.

### Runtime

The driver board sets it: Waveshare rate it at `<2 mA` idle, and only with the **DIP switch
set so the USB-UART is unpowered** — left powered, a reviewer measured 10–13 mA in "deep
sleep". So: **switch on to program, off to run.** (On the Rev 3 schematic that chip is a
**CH343**, not the CP2102 quoted on the older product page; SW1 gates its supply from
VBUS.)

The same schematic shows **GPIO 4 driving an S8050 that gates the panel's supply rail**
(VDD5V → VDD5V′, feeding the EPD 3.3 V regulator). That is a real power saving — the panel
rail can be switched off in sleep — and it means **GPIO 4 is not free for anything else.**

At 2 mA and ~49 mAh/day, against the 3.6 V floor (which leaves about 85% of the cell's
2000 mAh usable), runtime is **roughly five weeks** — about 35 days on battery, ~41 days
standby, ~33 days with an hourly refresh. About 95% of that budget is the board sitting
idle; a few refreshes a day cost barely 1 mAh between them. Refresh as often as you like,
it is not what empties the cell.

`<2 mA` is a spec, not this board — put a meter in series with the battery lead and read
the real number. If there is a power LED, cutting it is often worth 1–2 mA on its own.

### The cell

A salvaged 1S pouch, **2000 mAh, 694449, 44 × 49 × 6.9 mm**, three wires, all three
checked on this pack:

| Wire | Is | Goes to |
|---|---|---|
| red | **positive** (verified against black) | JST B+ |
| black | **negative** | JST B− |
| yellow | the other leg of a **10 kΩ NTC** (measured yellow→black at room temperature; its common leg is tied to black) | the charger's **TH** pad |

So the thermistor gets used: **cut the TH jumper** on the #6091 (it ships jumpered, which
disables the function) and wire yellow to the pad. The charger then refuses to charge
outside roughly 0–45 °C instead of trusting a salvaged pouch to behave.

The pack also carries **its own protection PCB** under the tape at the tab end, so it has
overcurrent, overdischarge and short protection independent of the charger.

## Buttons

Not fitted, but the frame is ready. The display uses **GPIO 13 (CLK), 14 (DIN), 15 (CS),
25 (BUSY), 26 (RST), 27 (DC)**; everything else on the headers is yours. For buttons that
also wake the ESP32 from deep sleep you need RTC-capable pins — **GPIO 32/33 are the
cleanest** if the headers bring them out. **Not GPIO 4** — on this board it gates the
panel's supply rail. Keep off 0, 2, 12 and 15 as well: they are strapping pins, and a
button held at reset changes boot behaviour.

To add them later: set `btn_n = 3` in the SCAD file and re-export the frame. That cuts
three Ø4.2 plunger holes in the +X wall (9.4 mm thick, the only wall with real meat in
it), 12 mm apart, for switches mounted on a strip inside. There is no room for front
buttons — the bezel is 10.5 mm and the module's PCB is directly behind it.

---

## What goes where

Interior is 82.1 × 80.9 mm in two columns: the driver board against the −X wall — the wall
the ribbon arrives at — and the cell with the charger above it on the +X side.

![Sheet 2 — internal layout](drawings/sheet2.svg)

<img src="renders/08-internal-layout.png" width="46%" alt="Boards and cell in the cover"> <img src="renders/07-cover-inside.png" width="46%" alt="Cover inner face">

| | Size | Where |
|---|---|---|
| Carrier perfboard | 30 × 70 | −X column, z 18…88, on four standoff pads |
| Driver board | 29.46 × 48.25 × ~6 | plugged into the carrier, z 31.7…80.0 |
| 24-pin FPC socket | 16 wide, 12.5 from the board's near end | on the board's −X edge, centred at **z 44.2** |
| Cell | 44 × 49 × 6.9 | +X column, low |
| bq25185 charger | 32 × 26.3 × 7.2 | +X column, above the cell |
| USB-C pigtail | 15 × 8 body, 10 deep | snapped into the back cover, low and off the leg's centreline |


**The board's position along Z is the whole point of it.** The ribbon slot runs z 24.2 to
64.2 and its centre is 44.2; the socket is 12.5 from the board's near end, so the board
starts at 31.7 and the socket lands at 44.2 — opposite the middle of the slot. The ribbon
comes around the glass edge, turns along the long axis, turns back out, and plugs in. No
adapter, no extension.

### The driver board plugs into a carrier, it is not held by the case

The Waveshare board has **no mounting holes** — but it does have its two 19-pin male headers
soldered on. So it plugs into female headers on a **carrier perfboard**, and the carrier is
what the case holds, on four standoff pads. Nothing printed touches the driver board itself.

A 30 × 70 cut of double-sided 0.1″ prototype board does it. The driver takes 48.25 of the
70, which leaves **about 14 mm × 30 of spare board below it** — that is where the battery
divider goes, so there is no separate scrap of perfboard any more.

The stack is the number to watch: carrier 1.6 + female header 8.5 + driver PCB 1.6 leaves
**4.7 mm** in front of the driver for parts that stand about 4.4 proud. That is 0.3 mm of
margin on two assumptions (`hdr_h`, `drv_env`), and low-profile sockets buy 3 mm of it back.

### Why not the half-size Perma-Proto

It fits the interior (81.3 × 50.8) and both boards do fit on it — the driver turned 90° is
50 along its length, the charger 26.3, against 81.3 available. What it leaves for the cell
is a 28.7 mm-wide column and a 79.5 × 22.7 strip, and the cell is 44 × 49. So it only works
with a much narrower cell (roughly 28 × 90 × 7, ~1500–1800 mAh) or a bigger frame.

The quarter-size board is gone too, for the same reason the corners needed: it was the
widest thing in the box. The charger now sits on four standoff pads of its own.

### The ribbon relief sets the frame width

The ribbon slot still reaches further out than the interior does, so the frame's short axis
is set by the notch rather than by the electronics:

```
SHORT AXIS driven by: THE RIBBON RELIEF  (cavity needs 44.03, ribbon needs 45.95)
OUTER: short axis 91.9 | long axis 108.4 | depth 25
```

The model grows `W` automatically to keep `wall_rib = 1.0` mm of material outboard of the
notch, so it is always valid — but it costs **3.60 mm of width** over what the electronics
need, and put the side bezels at 13.45 mm. The notch sits just outboard of the *pocket*, so
widening `pan_clr_w` pushes it out and the frame grows with it; that is why the 0.75 mm
pocket clearance cost 0.5 mm of overall width.

One measurement gets most of it back: how far the glass sits from the PCB edge on the
ribbon side. The PCB is 78.5 wide and the glass is 76, so there is 2.5 mm to distribute.

| `pan_off_x` | Frame width | Side bezel | Short axis driven by |
|---|---|---|---|
| 0 — glass centred (assumed) | **91.9** | 13.45 | the ribbon relief, needing 45.95 |
| 0.625 | 90.65 | 12.83 | the ribbon relief, needing 45.33 |
| 0.8 | 90.3 | 12.65 | crossover — ribbon and cavity both need 45.15 |
| 1.25 and beyond | **90.3** | 12.65 | the PCB cavity. Nothing past 0.8 buys any width |

So the whole prize is **1.6 mm of width and 0.8 mm of side bezel**, and it is all collected
by the first 0.8 mm. Measure the gap between glass edge and PCB edge on *each* side of the
ribbon axis, set `pan_off_x` to half the difference, and re-export. It is on the
[TODO](TODO.md).

### Depth is the tight axis

![Sheet 3 — depth stack-up](drawings/sheet3.svg)

With no PCB in front of it, the interior starts right behind the glass and the budget got
easier: **20.95 mm** deep off the stand pocket, **16.4 mm** over it, and **9.5 mm** clear in
front of the cell. The cell needs 6.9 of that 9.5.

Nothing is plugged into the back of the module — the panel's ribbon goes to the driver
board's own socket — so the only stack that has to be watched is the **driver board**
itself: PCB 1.6 plus its tallest part (the USB-C shell and the WROOM module are both about
3.2), which the model carries as `drv_env = 6.0`. There is 16.4 mm of interior where the
board crosses the stand pocket and 20.95 mm off it, so 6 fits either way.

**`drv_env` is an estimate, not a measurement**, and it is the number holding the depth
budget up — it is the first item in [TODO.md](TODO.md). It used to be 15, which is about
what a mated 8-pin cable would have added; with no such cable, both of the model's real
interferences went away.

### Mounting

- **Charger** — four standoff pads. No screw posts: the breakout's hole spacing is not a
  number this model has measured. Foam tape or a strap holds it.
- **Driver board** — slides into printed rails, no holes needed, with a stop at the bottom.
  The −X rail is split so it clears the FPC socket.
- **Cell** — drops into a fenced pocket on a flat platform (the platform exists so the
  cell doesn't straddle the step where the stand pocket bulges into the interior).
  Foam tape holds it.
- **Panel** — bezel lip in front, 5.3 mm of solid frame behind each end. Tape in the
  recesses if you want it; nothing else is needed.

### Ports

| Port | Where | Purpose |
|---|---|---|
| USB-C pigtail | **back face**, 22 mm off centre, 12.5 mm up | Charging and running from the wall. Wired to the charger's VBUS + GND |
| USB-C (Waveshare) | on the driver board, mid-interior | Flashing, **before assembly**. Switch on to program, off to run |

The pigtail has its own snap-in catch, so the case owes it nothing but a **precise
rectangular hole and clear air behind it**: 15.3 × 8.3 for a 15 × 8 body (0.15 a side), with
20.95 mm of interior behind it against the 10 mm the body needs. No printed rails, no
breakout board, no guide posts.

**Measure the part before printing.** A snap fit lives or dies on a tenth of a millimetre,
and `snap_w` / `snap_h` / `snap_c` are the three numbers that decide it.

The port sits below the stand pocket and off the leg's centreline, and the back edge carries
a 2 mm chamfer, so the cable clears the desk with the frame leaning back.

---

## The kickstand

![Sheet 7 — stand kinematics](drawings/sheet7.svg)

<img src="renders/06-back-folded.png" width="31%" alt="Leg folded"> <img src="renders/05-back-deployed.png" width="31%" alt="Leg deployed"> <img src="renders/04-side.png" width="31%" alt="Side, leaning">

- **Disc** Ø54 × 4 mm — bayonets into the pocket (three lugs, twist ~45°), four radial
  detents at 0/90/180/270°. Turn it to 45° to lift it out.
- **Leg** folds flush into the disc, swings out to a hard stop at 58° where a flat heel
  lands on the pocket floor, so the load goes into the cover skin rather than the hinge.
- **Hinge** M2.5 clamp screw into an insert in the far slot wall — see below.

### What locks the leg open

**The hinge is a clamp screw, not a pin.** An M2.5 screw goes through the near slot wall,
through the leg, and into a heat-set insert in the far wall. Tighten it and the walls close
onto the leg; the friction holds it at any angle, including fully deployed, and you set how
hard with a screwdriver. That is the lock.

For the clamp to have anything to close on, the leg is a **close fit in the slot** — 12.0 mm
in a 12.4 mm slot, so each wall only has to move 0.2 mm. A loose slot just rattles, which is
why `leg_slot_c` came down from 0.5.

**Folded, a catch lip holds it shut**: the foot passes 0.65 mm of overhang at the far end of
the slot, flexing about 0.3 mm on its 30 mm of leverage — roughly 5 N at the tip, a firm but
easy click. It will not fall open in a bag.

**A printed detent at the deployed angle is not available at this size**, and it is worth
saying why rather than shipping something that does not click. The obvious place is the
hub's arc against the closed end of the slot — but the heel flat, which *is* the hard stop,
cuts the hub away exactly there: the leg reaches only 3.42 mm behind the pivot instead of
6 mm, so there is nothing left to carry a groove. Two attempts at it cut air. The clamp
screw does the same job and can be adjusted after printing, which a moulded detent cannot.

`pivot_screw = false` goes back to a plain Ø2 pin — a steel rod, or a 1.75 mm filament
offcut with its ends flared. That still works; it just gives you whatever friction the print
happens to produce, and no way to change it.

`catch_snap = false` removes the lip. Test-print the disc and leg together (10 g, about
25 minutes) before committing to a frame: the snap force is the one number here that a
drawing cannot tell you.

**The hub is deliberately 8.25 mm below the frame's centre**, at exactly half the frame's
*width* above the bottom edge. Rotate the frame 90° and the pivot ends up the same distance
above whichever edge is now the bottom — so portrait and landscape get an identical stance
(**20.5°, 31.9 mm footprint**) instead of the ~9° difference a centred hub forces.

The frame rests on the **rear** edge of its flat bottom — a slab leaning backwards contacts
at the back of its base. The 2 mm rear chamfer moves that contact edge forward, and with the
equal-stance hub the centre of mass sits 9 mm (portrait) and 6 mm (landscape) behind it.

A single hard stop, not a ratchet: the hinge axis lies *in* a 4 mm disc, so the knuckle
can't exceed ~3 mm, which puts 15° teeth at 0.4 mm — under what a 0.4 mm nozzle resolves.

---

## Parts and printing

![Sheet 4 — frame](drawings/sheet4.svg)

![Sheet 5 — back cover](drawings/sheet5.svg)

![Sheet 6 — disc and leg](drawings/sheet6.svg)

The STLs export ready to slice — **no rotating in Orca, no supports**. This is the four
printed parts exactly as the exporter leaves them, which is how they land on the bed:

![The four parts as exported](renders/11-print-plate.png)


| Part | STL | On the bed | Why | Filament |
|---|---|---|---|---|
| Frame | `stl/frame.stl` | front face down | big flat first layer, and the interior opens upward. The other way up, the 1.4 mm front plate has to bridge the whole interior | ~63 g |
| Back cover | `stl/cover.stl` | outer back face down | big flat first layer, standoffs and ribs build upward | ~35 g |
| Disc | `stl/disc.stl` | outer face down | symmetric | ~8 g |
| Leg | `stl/leg.stl` | flat | symmetric | ~2 g |
| Bezel test tile | `stl/bezel_test.stl` | front face down — **print this first** | same as the frame | ~23 g |

PLA or PETG, 0.2 mm layers, 4 perimeters, 15–20% infill. The bayonet groove and window
chamfer are both cut at 45°, and only the 0.8 mm front chamfer overhangs — at 45°, on the
first layer. Put the visible face on the bed; that surface finish is most of the look.

The end walls are hollowed from the cover side (`lightening()`), leaving 2 mm of floor
behind the glass shelf, a rim, and the screw bosses. Without it the two ends are solid
frame and the part is 24 cm³ heavier for nothing.

### ⚠ The STLs are mirrored in X

`print_mirror = true` mirrors all five parts at export. They still mate with each other, but
the assembly is the **opposite hand** to the drawings: the ribbon relief, the screw spine
and the charge port are on the other side. On the bed the ribbon relief sits at
**x ≈ +45.95** (right of centre); un-mirrored it sits at −45.95.

**The drawing sheets show the as-designed hand; the renders show the printed hand.** The
renders import the STLs and assemble them exactly as they come out of the exporter, so
they are the object you will hold — which reads left-right reversed against every sheet.
`renders/11-print-plate.png` is the rawest of them: the four STLs untouched, in the
orientation the slicer will open them in.

Set `print_mirror = false` to go back to the drawn hand — the renders and the note in
every title block follow the flag, and the sheets themselves are always drawn as designed.
The interference checks run on un-mirrored geometry and are unaffected either way.

### Hardware

- 5 × **M2.5 heat-set inserts**, 4.0 OD × 4.0 long (four in the frame's end walls, one in the disc)
- 4 × **M2.5 countersunk screws**, 8 mm (cover) + 1 × M2.5 × 10 (hinge clamp)
- **Double-sided 0.1″ prototype board**, cut to 30 × 70 (driver carrier + divider)
- 2 × **19-pin 2.54 female headers** for the driver to plug into
- **Panel-mount USB-C pigtail**, 15 × 8 snap-in body
- Adafruit **bq25185 (#6091)**; 1S LiPo **2000 mAh, 694449, 44 × 49 × 6.9 mm** (the
  salvaged cell above)
- JST-PH pigtails, foam tape

---

## Verification

**Print `bezel_test.stl` first.** It is an `intersection()` of the actual `frame()` with a
box — the front 6.85 mm of the full 91.9 × 108.4 face — so it cannot drift from the part it
stands in for. ~40 minutes, ~20 g. It shows all four glass-pocket corners with their relief,
all four cavity corners, all four bezels, the complete window lip and chamfer, and the full
ribbon slot, and you can drop the real module into it. Its depth tracks the ribbon relief
(`rib_y1 + 1.4`) rather than being a round number, because a fixed 5.65 left a 0.2 mm
membrane across the relief floor — a slot that printed closed. `bt_h = 34` gives the old
bottom-band tile if you only want the corners.

**Geometry checks that pass now:**

| Check | State |
|---|---|
| Bodies per part | 1 each, all five |
| Watertight | yes, all five |
| `frame_module` at `cav_rel = 0`, `cav_r = 1.5`, `pan_rel = 1.4` | clear, 0.086 mm to spare on the sharp PCB corner |
| Interference set (14) | 12 empty, 2 zero-volume (coincident faces), **0 real** |
| Screws | 4, one near each corner, each in 13.75 mm of end wall |

The two zero-volume results are `frame_cover` (the frame's rear face and the cover's front
face are both at `y = body_d`) and `cover_board` (the board sits exactly on its standoffs);
`intersection()` returns coincident faces as zero-thickness sheets, so measure volume, not
emptiness. The other trap: when an intersection *is* empty, OpenSCAD writes no file at all,
so a script that reuses output paths silently re-reads the previous check's result — delete
the output before every run.

Both of the interferences this model used to carry are gone, and both went for the same
reason — they were consequences of hardware this build does not have:

| Check | Was | Now |
|---|---|---|
| `conn_cell` | 154 mm³ — a mated header against the cell | empty; `mod_header = false`, nothing stands off the panel |
| `drv_module` | 1050 mm³ — a 15 mm driver stack against a module PCB | empty at `drv_env = 6.0`, the board with no cable mated to it, and no PCB to hit |

`disc_legf` now reports geometry **on purpose**: it is the catch lip overlapping the folded
leg's foot, which is the interference the leg flexes past to snap shut. `disc_legd` stays
empty, so the catch does not foul the deployed leg.

Two problems caught during the rebuilds:

- the cover's −X driver rail sat 1.4 mm outside the interior wall and buried itself in the
  frame — 459 mm³ of `frame_cover`. That rail is gone now with the carrier.
- **the interior was walled shorter than the glass**, so the panel could not be installed at
  all. No interference check catches that, because nothing intersects: the glass simply has
  no path in. It is now a stated constraint (`glass_pass_h`) with its own echo line.

`mock_module()` draws the glass as a **sharp-cornered square**, matching the real part,
which is what makes `frame_module` able to catch a corner-fillet problem at all.

### Thin, but deliberate: the −X wall

Because the ribbon relief sets `W`, everything on the −X edge is tight, and the features
there are cavity-referenced:

| | Wall left |
|---|---|
| outboard of the ribbon relief | 1.00 mm |
| −X and +X walls generally | 4.92 mm |
| each long-axis end wall | 13.75 mm — this is where the screws go |

All printable at a 0.4 mm nozzle. The register slot is the one to watch if `W` ever comes
down further — it thins 1:1 with the outer face.

**The screws are in the end walls, not the side walls.** 38.03 mm from the centreline and
7 mm from each end, so each is near a corner and each sits in 13.75 mm of material — about
4 mm clear of the outer edge and 4 mm clear of the interior. The side walls are 4.92 mm and
could not have taken them, which is exactly the trap the old design was in: a single spine
of three screws down the +X side, and the whole −X edge unfastened.

### Heat-set inserts, and why the screws are countersunk

The frame takes **M2.5 heat-set inserts**: a Ø3.6 bore, 5.0 mm deep, with a lead-in chamfer
so the insert starts square. Melt them in flush with the mating face.

The screws are **countersunk, not socket cap**, because the cover is 1.4 mm thick. A 90°
head sinks `(head Ø − clearance Ø) / 2` deep, which for M2.5 is **1.05 mm** — it disappears
into a 1.4 mm plate. A socket cap head is 2.5–3 mm tall and would stand proud of the back
face, and there is nowhere to put a boss to swallow it: the cover meets solid frame there,
not open interior.

| Size | Insert OD × L | Bore | Screw head, 90° | Cone depth |
|---|---|---|---|---|
| M2 | 3.2 × 4.0 | Ø2.9 × 5.0 | 4.0 | 0.8 |
| M3 | 4.6 × 5.7 | Ø4.0 × 6.7 | 6.0 | 1.3 |
| **M2.5** | **4.0 × 4.0** | **Ø3.6 × 5.0** | **5.0** | **1.05** |

Insert dimensions vary by brand — measure yours and set `ins_d` / `ins_l`. Everything
downstream follows, including the cover's clearance hole and countersink.
`insert_fit = false` goes back to self-tapping screws into a Ø2.1 pilot.

### One known cosmetic defect

The cover exports with **10 non-manifold edges** — edges used by four facets instead of two,
where two surface patches meet along a line. They are not holes: CGAL rates the result
`Simple: yes / Volumes: 2`, the solid is closed, and slicers take it. They sit in the
`rear_chamfer()` hull region at the outer back face (a 0.04 mm sliver at y 24.96–25.00, plus
one at y 22.05–22.25), and they are **not** parameter-dependent. The frame uses the same
chamfer code and is clean, so it is the interaction with the cover's rear-face features.
Left alone deliberately — `rear_chamfer()` is delicate code, and a cosmetically nicer mesh
is not worth reopening it.

---

## Exporting and tuning

```bash
openscad -o stl/frame.stl      -D 'part="frame"'      src/epaper_stand.scad
openscad -o stl/cover.stl      -D 'part="cover"'      src/epaper_stand.scad
openscad -o stl/disc.stl       -D 'part="disc"'       src/epaper_stand.scad
openscad -o stl/leg.stl        -D 'part="leg"'        src/epaper_stand.scad
openscad -o stl/bezel_test.stl -D 'part="bezel_test"' src/epaper_stand.scad
```

Regenerate the drawings from the model after any parameter change:

```bash
openscad -o /tmp/p.stl -D 'part="params"' src/epaper_stand.scad 2>&1 \
  | sed -n 's/^ECHO: "P|\(.*\)"$/\1/p' | tr '|' '=' > /tmp/params.txt
python3 tools/mkdrawings.py     # drawings/sheet*.svg + _sheets.json
python3 tools/mkpage.py         # drawings/index.html
```

And the renders, which import the STLs rather than the model — re-export the STLs first,
or the pictures will show the previous revision:

```bash
sh tools/mkrenders.sh           # renders/*.png, all of it from stl/
```

| Want | Change |
|---|---|
| A panel with a PCB behind it is used after all | `bare_panel = false` — the interior goes back to being sized by `pcb_w` / `pcb_h` |
| A module with a mated header is used after all | `mod_header = true`, then `conn_h` / `conn_dx` / `conn_dz` |
| Screws further from / closer to the corners | `scr_cx` / `scr_cz` |
| A different insert size | `insert_size` = `"M2"` / `"M2.5"` / `"M3"`, or `ins_d` / `ins_l` directly |
| Self-tapping screws instead of inserts | `insert_fit = false` |
| A different perfboard | `perf_w` / `perf_h`, or `perf_fit = false` |
| The electronics box needs to grow | `elec_clr`, `col_gap`; the interior follows, and so does the frame if it has to |
| The driver board measures deeper than 6 mm | `drv_env`, and re-run `chk="drv_module"` |
| Bigger cell | `bat_w` / `bat_h` / `bat_t` — the band is 79.5 wide × ~51 tall |
| Three side buttons | `btn_n = 3`, then `btn_d` / `btn_sp` |
| More/less white line | `white_show_short` / `white_show_long` |
| Different lean | `stop_ang`, or `pivot_r` |
| Rear port position | `ucb_x` / `ucb_z`; `port_w` / `port_h` for the opening |
| Deeper/shallower back bevel | `rear_chf` — 2.0 is the ceiling before it eats the 2.2 mm walls |
| Looser/tighter disc | `pocket_c` |
| Open the flash port again | `flash_port = true` |
| Print the drawing hand instead of the mirrored one | `print_mirror = false` |

Preview modes: `standing_p`, `standing_l`, `folded`, `guts` (cover populated with mock
electronics), `assembly`, `plate`.

Interference checks are built in — `chk` = `frame_cover`, `frame_module`, `cover_module`,
`cover_board`, `frame_board`, `drv_module`, `conn_cell`, `conn_board`, `conn_cover`,
`cover_disc`, `disc_legf`, `disc_legd`, `cover_legd`, `cover_legf`:

```bash
openscad -o /tmp/chk.stl -D 'part="none"' -D 'chk="cover_board"' src/epaper_stand.scad
```

## Sources

- [4.2inch e-Paper Module (B) manual — 91 × 77 × 1.05 mm panel, 84.8 × 63.6 active](https://www.waveshare.com/wiki/4.2inch_e-Paper_Module_(B)_Manual)
- [e-Paper ESP32 Driver Board pinout and "5V pin supports 3.6V to 5.5V… can be powered by a lithium battery"](https://spotpear.com/index/study/detail/id/375.html)
- [e-Paper ESP32 Driver Board product page — `<2mA` low-power current with the CP2102 unpowered](https://www.waveshare.com/e-paper-esp32-driver-board.htm)
- [Fasani — measured 10–13 mA "deep sleep" on this board](https://fasani.de/2020/04/19/waveshare-eink-esp32-driver-board/)
- [e-Paper ESP32 Driver Board V3 schematic](https://files.waveshare.com/wiki/E-Paper-ESP32-Driver-Board/E-Paper_ESP32_Driver_Board_V3.pdf) — 24-pin FPC panel interface with the panel DC-DC on board, CH343 USB-UART behind SW1, GPIO 4 gating the panel rail
- [Adafruit bq25185 charger, #6091](https://www.adafruit.com/product/6091) · [pinouts](https://learn.adafruit.com/adafruit-bq25185-usb-dc-solar-lithium-ion-polymer-charger/pinouts) · [TI BQ25185](https://www.ti.com/product/BQ25185)
- [Perma-Proto quarter-size — 1.7″ × 2.0″, holes 1.4″ apart](https://www.pololu.com/product/2765)
</content>
