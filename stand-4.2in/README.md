# 4.2" e-Paper desk frame — minimal bezel, rotating kickstand, battery inside

A slim desk frame for the **Waveshare 4.2inch e-Paper panel (B)** driven by the
**Waveshare e-Paper ESP32 Driver Board (Rev 3)**, with a LiPo and a power-path charger
inside, and a single rotating kickstand on the back that folds flush and turns 90° for
portrait or landscape.

The panel is **bare glass and an FPC tail** — no PCB behind it. The tail leaves the centre of
the **RIGHT** side and makes a shallow S, out and up towards the **TOP**, before turning
inboard. It reaches the driver board's socket — but it has no slack, so it cannot survive the
cover being lifted off. A **Waveshare FPC adapter** is fitted as a service loop.

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

### The four sides have names

Width/height are banned because they swap when the frame turns. So do "top" and "bottom"
unless you say which way up — so the datum is fixed once, here, and everything uses it:

**Hold the panel with the front face down, in portrait.** You are looking at the **rear
face**. Put 0,0 at the top-left, X increasing across, Y increasing down. Then:

| Side | Which edge | Length | Runs along |
|---|---|---|---|
| **TOP** | Y = 0, X sweeping across | 76 (glass) | the short axis |
| **BOTTOM** | Y = max, X sweeping across | 76 | the short axis |
| **LEFT** | X = 0, Y sweeping down | 90 | the long axis |
| **RIGHT** | X = max, Y sweeping down | 90 | the long axis — **the tail leaves this side** |

And the two faces are **front face** (the ink you look at) and **rear face** (the back, facing
you during assembly). Never "top face" for either.

### How those map into the model

The model does not use the build frame and is not going to be renamed, so here is the
mapping. It is worth reading once, because two separate bugs came out of getting it wrong:

| Build frame (front face down, 0,0 top-left) | Model |
|---|---|
| **TOP** | `+Z` end — `Z = 100.25` at the glass |
| **BOTTOM** | `−Z` end — `Z = 10.25` at the glass. **The kickstand hub is here**, at `Z = 45.95` |
| **LEFT** | `+X` side |
| **RIGHT** | `−X` side — the ribbon relief reaches `x = −44.95` |
| **front face** | `Y = 0` |
| **rear face** | `Y = 25` |
| X increasing (left → right) | `−X` direction |
| Y increasing (top → bottom) | `−Z` direction |

Two sign flips to keep hold of:

- **Build-Y and model-Z run opposite ways.** "18 mm down from the top" is `Z = 100.25 − 18`,
  not `Z = 18`.
- **Build-X and model-X also run opposite ways**, because looking at the *rear* face reverses
  the short axis. Derive it if you doubt it: looking along `−Y` with `+Z` up gives a view-right
  of `cross((0,−1,0),(0,0,1)) = (−1,0,0)`. That is why RIGHT is `−X`, and why the relief being
  at `x = −44.95` is correct rather than mirrored.

What fixes `−Z` as the BOTTOM, independently, is the kickstand: its hub sits at `Z = 45.95`,
half the frame's width up from `Z = 0`, and a stand's hub is at the bottom.

### The ribbon route

Front face down, portrait, so you are looking at the **rear face**. The tail leaves the
**CENTRE of the RIGHT side** — not an end — and makes a shallow S:

| Leg | Direction | Size | Parameter |
|---|---|---|---|
| 1 | straight out from the glass edge | 4 mm | `rib_out` |
| 2 | 90° turn towards the **TOP**, running parallel to the RIGHT edge | 9 mm wide × 20 mm long | `rib_band`, `rib_run` |
| 3 | 90° turn **away from the RIGHT side** — inboard, across the rear face | to the connector | — |

Leg 2 is the whole reason the relief is a slot rather than a local pocket at the exit: the
ribbon spends 20 mm travelling *parallel* to the RIGHT edge before it turns inboard. Leg 2 is
9 mm wide but only reaches 4 mm outboard of the glass — the other 5 mm of its width lies
*behind* the glass, which is open interior, so the frame only has to clear 4 mm.

The three relief sizes are deliberately *not* called width/height/depth:

| | Parameter | Now | Meaning |
|---|---|---|---|
| **out** | `rib_clr` | 3.0 | outboard from the pocket edge, along the short axis |
| **deep** | `rib_dep` | 3.0 | past the glass back face, along depth — so the fold has somewhere to go |
| **long** | `rib_w` | 33.0 | along the RIGHT edge, on the long axis |

**`rib_w` and `rib_off` are derived from the route now, not typed in.** `rib_w` is
`rib_run + rib_band + 2 × rib_marg` and `rib_off` puts the slot's near edge half a band below
the exit, so the slot straddles the exit and covers the run to the TOP. They come out at 33
long, **38.5 up from the BOTTOM, 18.5 short of the TOP** — and they cannot drift from the
route any more, which is how they went wrong twice:

- `rib_off = 15` put the slot at the **BOTTOM**, under a source comment insisting the model's
  −Z was the top and warning against "fixing" it. It was the reversed reading it warned about.
- `rib_off = 35` then put the slot 15 short of the **TOP**, from reading "the ribbon is towards
  the top" as the exit position. The exit is at the **centre**; it is the *run* that goes
  towards the top.

**One clearance is 0.25 mm short.** Leg 1 needs 4 mm out from the glass edge; the relief gives
3.75 (`rib_clr` 3.0 from the pocket edge, plus 0.75 of pocket clearance). `rib_clr = 3.25`
would fix it and grows the frame 0.5 mm on the short axis — which also moves `hub_z = W/2` and
with it the stance, so it is not a free change. The echo prints the shortfall on every run.

### The tail reaches the driver — but it cannot cross the split

The driver board faces **down**, so its socket edge is the one nearest the display, and the
tail can meet it. Leg 3 only has to travel about 4 mm inboard: the board's −X edge sits at
x −41.18 and the glass's RIGHT edge at −41.20.

Which way round the board is mounted decides whether it fits:

| Socket 12.5 mm from… | Board spans | |
|---|---|---|
| the **BOTTOM** end | z 62.75 … 111.0 | overruns the interior top by 9.5 mm |
| the **TOP** end — hangs downward from the socket | z 39.5 … 87.75 | **fits** (`fpc_end = "top"`) |

So a direct plug-in works geometrically. **The reason it still is not enough is service.**

The glass is on the **frame**. The driver is on the **cover**. Anything joining them crosses
the split, and the panel's tail cannot:

| | |
|---|---|
| Tail length | 18 mm, with no slack designed in |
| What its 180° fold gives back when it straightens | (π−2) × `rib_dep` = **3.4 mm** |
| Lift needed to get a fingernail on a ZIF lever | ~25 mm |
| Shortfall | **21.6 mm** |

Lift the cover and you are pulling on the glass. So the **adapter is a service loop, not a
reach fix**: the short tail plugs into it on the panel side, and a longer FPC crosses the
split with enough slack to open the case.

### What the service loop costs

Putting the adapter in front of the driver stacks 5 mm onto 16 mm against 16.4 mm of room —
**4.6 mm short.** Three ways out, and none is free:

| | Cost |
|---|---|
| `depth` 25 → 29.6 | the frame gets 4.6 mm thicker |
| Low-profile female headers, `hdr_h` 8.5 → 5.5 | buys back 3.0 mm; still 1.6 short |
| Both | 1.6 mm of depth plus a different header |

The alternative is to **not cross the split at all** — release the tail's ZIF before the cover
comes off. That needs only enough lift to reach the lever, and the tail's fold gives 3.4 mm of
it. Whether 3.4 mm is enough to get at the lever is a hands-on question, not a calculable one,
and it is the cheapest outcome by far if the answer is yes. It is the first item in
[TODO.md](TODO.md) §2.

Mounting the driver on the **frame** instead, so nothing crosses the split, does not work: the
glass drops in through the interior and needs the full 90 mm clear, so anything standing off
the frame's ledge blocks it — the same reason there are no corner posts.

As fitted, the adapter is:

| | |
|---|---|
| Outline | 18 × 32 × ~5 mm (depth with both connectors — **assumed**) |
| Holes | 4 corners, Ø2.2 at 2.0 mm inset — **both assumed, measure them** |
| Where it sits | at leg 3's turn: x −40.45 … −22.45, centred z 75.25 |
| Problem | it overlaps the carrier, needs 4.6 mm of depth nobody has, and has no mounting |

**A measurement to re-check:** the route needs at least 4 + 20 = **24 mm** of developed tail
before leg 3 starts, against the **18 mm** measured flat. Those two do not agree. Whichever is
right decides whether leg 2 really runs 20 mm, and `rib_w` / `rib_off` are derived from it.

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
  function, so it cannot be moved inboard. One is fitted: **pocket relief** (`pan_rel` = 1.4,
  at the glass pocket corners). Because it is centred on the corner it bulges 1.4 mm
  *outboard* of the pocket — further out than the interior reaches on three sides — so the
  interior wall used to **overhang it by 0.9 mm**. The same four circles are now carried up
  through the wall as well (see `cavity()`), so the opening holds at x −43.32 from the pocket
  right through to the rear face instead of stepping back in. It costs nothing dimensionally:
  2.63 mm of wall is still left outboard of the worst corner.
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
| Carrier perfboard | 30 × 70 | −X column, z 14.5…84.5, on four standoff pads |
| Driver board | 29.46 × 48.25 | plugged into the carrier, **z 15.5…63.75 — low**, because the adapter frees it from the ribbon |
| 24-pin FPC socket | 16 wide, 12.5 from the board's near end | on the board's −X edge, centred at z 28.0 |
| FPC adapter | 18 × 32 × ~5 | at leg 3's turn, centred z 75.25 — **overlaps the carrier, no home yet, and may not be needed** |
| Cell | 44 × 49 × 6.9 | +X column, low |
| bq25185 charger | 32 × 26.3 × 7.2 | +X column, above the cell |
| USB-C pigtail | **14 × 4.5 body** (measured), 10 deep | snapped into the back cover, low and off the leg's centreline. The printed opening is 14.3 × 4.8 — `snap_c` per side, because a hole exactly the size of the part will not take it |


**The board used to be positioned by the ribbon, and is not any more.** It was placed so its
socket landed opposite the middle of the ribbon slot. The tail's own S means the connector has
to meet leg 3, at z 75.25 — and a board with its socket 12.5 from the *bottom* end then runs
9.5 mm off the top of the interior. With the adapter fitted the driver goes **low on the
carrier** (z 15.5…63.75) where it fits. Turned end-for-end it would fit at z 39.5…87.75 with
no adapter at all — see above.

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

Nothing is plugged into the back of the panel — it is bare glass and a tail — so the stack
that has to be watched is the **driver board on its carrier**, and that has now been
measured as a whole rather than guessed in three parts:

| | |
|---|---|
| Driver board + female sockets + carrier PCB | **16.0 mm**, measured, back face to tallest point |
| Room where it crosses the stand pocket | **16.4 mm** |
| Spare | **0.4 mm** |

`drv_stack = 16.0` is the number that decides fit, and it supersedes adding up `drv_env`,
`hdr_h` and `carrier_t` — those still exist for the features that need them individually,
but their sum is no longer the test. 0.4 mm is the entire margin in the build, and it is why
`disc_t` cannot grow.

### Mounting

- **Charger** — four standoff pads. No screw posts: the breakout's hole spacing is not a
  number this model has measured. Foam tape or a strap holds it.
- **Driver board** — plugs into female headers on the carrier perfboard; the case holds the
  carrier, not the board. (`drv_rail` still exists for the no-carrier fallback.)
- **FPC adapter** — nothing yet. It has four corner holes and needs four bosses, and first it
  needs a seat that is not already the carrier's — [TODO.md](TODO.md) §2.
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
rectangular hole and clear air behind it**: **14.3 × 4.8 for the measured 14 × 4.5 body**
(`snap_c` = 0.15 a side), with 20.95 mm of interior behind it against the 10 mm the body
needs. No printed rails, no
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
- **Leg** folds flush into the disc and swings 122° out to a hard stop at 58° from
  straight down, where a flat on its heel lands on the pocket floor, so the load goes into
  the cover skin rather than the hinge.
- **Hinge** a plain Ø2 pin. A clamp land on the slot wall is what holds the leg — see below.

### One number sets the whole hinge: the pivot is 2 mm off the floor

The pivot axis sits at `piv_h = disc_t/2` = **2.0 mm** above the pocket floor. The leg swings
122°, so every point on it passes through *straight down* somewhere in the stroke — and a
point `r` from the axis reaches `piv_h - r` at that moment. So **nothing on the leg may lie
more than 2.0 mm from the pivot axis** in the sector that swings under, or it drives itself
into the cover.

That is the constraint behind both of the following, and it is why the hub's rear is an arc
and the hinge is a pin rather than a screw.

### The hub's rear is an arc, not a corner

The heel flat is a plane 2.0 mm from the axis, tangent to the floor at the deployed angle.
But it crossed the leg's full 3.4 mm thickness, and its far corner stood **3.82 mm** from
the axis. Intersecting the leg against the cover through the stroke measures what that
costs:

| Leg angle | Heel corner, vs the pocket floor |
|---|---|
| 0° (folded) | clear |
| 40° | 1.50 mm **inside the cover** |
| 64° | 1.80 mm **inside the cover** |
| 100° | 1.07 mm **inside the cover** |
| 122° (deployed) | clear |

Both ends of the travel were clear, which is why the two end-pose checks passed. The leg
could not get between them.

So the rear of the hub is cut back to an arc at `hub_r` = 1.75 mm — `piv_h` less
`sweep_clr` — over local angles **148° to 270°**, which is exactly the sector that passes
under the axis (`sweep_a = 270 - theta_dep`). The arc's near end lands on the heel flat's
tangent point, so the flat keeps its **short side, 0.75 × 12 mm** — the part that comes down
on the pocket floor at 58°. That is the hard stop, at 0.17 MPa on the cover skin.
`chk = "cover_legs"` with `chk_th` walks the stroke; all of it is clear now.

### The deployed stop is the slot's rear wall

Rounding the hub's rear to `hub_r` is the *retracted* reach. Measured off the leg mesh, how
far the leg reaches behind the pivot **while still inside the disc's 4 mm** climbs steeply at
the end of the stroke, because the leg's upper-forward corner swings round *behind* the
pivot as it opens:

| Swing | 0° | 60° | 90° | 110° | 118° | 120° | **122°** | 125° |
|---|---|---|---|---|---|---|---|---|
| Reach behind the pivot | 1.75 | 2.12 | 1.70 | 2.48 | 2.95 | 3.10 | **3.25** | 3.45 |

That is **0.77 mm of daylight** between anywhere-up-to-110° and fully deployed. The slot's
rear wall used to sit at `leg_w/2 + 1.2` = 7.2 mm, clearing all of it and doing nothing. It
now sits at `stop_wall` = **3.25 mm**, so the leg meets it only in the last degree or two —
verified clear at 121°, touching at 122° — and past that the interference grows about
**0.07 mm per degree**. The heel flat comes down on the pocket floor at the same moment, so
the two share the load.

That wall exists because **the heel flat on its own is a tangency, not a stop.** The flat is
a plane `piv_h` from the axis, so it can never cut the floor however far it turns; only its
finite edge can, and that edge is 2.14 mm out, so it saturates:

| Past the stop | Heel edge, into the floor |
|---|---|
| 126° | 0.048 mm |
| 132° | 0.101 mm |
| 143° | 0.138 mm — the deepest it ever gets |
| 150° | 0.120 mm, coming back out |

Twenty degrees of over-travel against 0.138 mm. The wall is what makes the lean angle
definite instead of a friction setting.

### What holds the leg: the clamp land

The leg is 12.0 mm in a 12.4 mm slot, so it had **0.4 mm of play** and nothing touching it.
The land removes the play: over `clamp_len` = 8 mm at the pivot the slot is **11.9 mm**, so
the leg goes in on 0.1 mm of interference, with 45° lead-ins along the slot so it presses in
rather than jamming on a step.

The land is carried on a **spring, not on the bulk of the disc**. A relief slot behind it
leaves a tongue fixed at both ends — 0.8 × 4 × 14.25 mm. Its rear root is wherever the leg
slot ends, so `stop_wall` sets that arm, not a free parameter; bringing the wall in from 7.2
to 3.25 stiffened the tongue 2.6×, which is why `clamp_pr` is 0.5 rather than 0.6:

| | |
|---|---|
| Tongue rate | 77.8 N/mm, loaded 3.25 mm from one root |
| At 0.1 mm interference | 7.78 N → **10.9 N·mm** of hinge torque |
| Gravity on the leg | 0.35 N·mm — so **31×** |
| To move it by hand | 0.31 N at the foot |
| Stress at the root | 35 MPa, against ~50 MPa yield |

That spread is the point. On a rigid wall, ±0.15 mm on 0.2 mm of interference is either
nothing or a leg that will not go in; on the tongue it is a hinge that is always firm and
always movable. `clamp_pr` is the **print-tuned number** here, the way `catch_p` is for the
catch — print the disc and leg together (10 g, ~25 min) and set it by feel.

**Folded, the catch lip holds it shut**: the foot passes 0.65 mm of overhang at the far end
of the slot, flexing about 0.3 mm on its 30 mm of leverage — roughly 5 N at the tip, a firm
but easy click. It will not fall open in a bag.

### How the leg goes in

1. Slide the leg into the disc's slot **from the forward (open) end**, pressing it over the
   clamp land's 45° lead-ins. It is a 0.1 mm push fit there, not a drop-in.
2. Line the leg's axle hole up with the disc's pin bore.
3. Push a **Ø2 × 43.5 mm pin** in through the disc's rim. The bore runs the full width of the
   disc on the pivot axis — 15.55 mm of solid PLA each side of the slot — so the pin is
   nearly disc-diameter long. A 1.75 mm filament offcut with its ends flared works.
4. Bayonet the disc into the cover pocket. **The pocket bore is what traps the pin**: there
   is nowhere for it to go once the disc is in, so it needs no head, clip or glue.

To get the leg out again, twist the disc to 45° and lift it out, then push the pin back out
through the rim.

### Why the hinge is a pin

A clamp screw runs along the pivot axis, so **`disc_t` bounds both ends of it**: the head
seat and the insert bore are each limited to the disc's 4 mm thickness.

| | Needs | In a 4 mm disc |
|---|---|---|
| M2.5 head | 5.0 across | **−0.5 mm a side** |
| M2.5 insert bore | 3.6 across | 0.2 mm of wall a side |
| Ø2 pin | 2.1 across | 0.95 mm a side |

Only the pin fits, so `pivot_screw = false`. The `HINGE SCREW FITS` echo prints that
arithmetic for whatever `disc_t` and `insert_size` are set to; the geometry is guarded on
`clamp_ok`, so the access channel is only cut when it can be a channel rather than a trough
open on both faces.

`disc_t = 6` would make the screw fit — +0.5 a side on the head, +1.2 on the bore — and
**that is no longer available.** The measured 16.0 mm stack over the puck against 16.4 mm of
room leaves 0.4 mm; two more millimetres of disc leaves 14.4 against 16.0. So the hinge is a
pin, and stays one, unless the driver board comes off the pocket.

### Why there is no snap-out detent, and what one would cost

The leg is held out by the wall stop and 10.9 N·mm of clamp friction, and held shut by the
catch lip. It does not **click**, and the reason is a hard geometric bound, not a tuning
problem.

The mechanism would be the one in
[US5865128A](https://patents.google.com/patent/US5865128A/en) — a slot with a **channel →
ramp → locking opening**, a spring holding the pin in the opening, released by pushing the leg
along the slot. That needs a lug on the leg that projects past the hub arc. **A projecting lug
has to survive the whole 122° sweep inside the disc's thickness**, and its worst excursion is
`r × max|sin|` over the 122° arc it traces. The best case centres that arc on straight-back,
which caps the projection at:

| `disc_t` | Lug may reach | Hub arc | **Projection available** |
|---|---|---|---|
| 4.0 | 2.00 | 1.75 | **0.25 mm** |
| 6.0 | 3.14 | 2.75 | **0.39 mm** |
| 8.0 | 4.29 | 3.75 | 0.54 mm |

A 0.4 mm nozzle resolves about 0.4 mm. The folded catch that *does* work is 0.65 mm proud with
0.35 mm of flex. So a detent is below printable resolution at `disc_t = 4` and marginal even at
8 — **thickening the disc does not rescue it**, which is the opposite of what an earlier version
of this section said. Nor does friction: the clamp tongue is already near its stress limit at
0.10 mm of interference (35 MPa of 50), and 0.14 mm is the most it will take.

**Flush folding and a printable detent are mutually exclusive here.** The bound comes entirely
from the lug having to stay inside the disc while the leg sweeps. Let the leg stand slightly
proud of the rear face when folded and the bound disappears — a lug at leg-local 58° points
straight back at the stop wall at exactly the deployed angle, and sits at mid-thickness there:

| Lug radius | Bite past the wall | Proud when folded | Max proud mid-sweep |
|---|---|---|---|
| 3.0 | none | 0.54 | 1.00 |
| 3.5 | 0.25 | 0.97 | 1.50 |
| **4.0** | **0.75** | **1.39** | 2.00 |

0.75 mm of positive engagement for a tab standing 1.39 mm off the back next to the hub. That is
the trade, and it is a decision about the product, not the geometry — [TODO.md](TODO.md) §2c.

**The hub is deliberately 8.25 mm below the frame's centre**, at exactly half the frame's
*width* above the bottom edge. Rotate the frame 90° and the pivot ends up the same distance
above whichever edge is now the bottom — so portrait and landscape get an identical stance
(**20.5°, 31.9 mm footprint**) instead of the ~9° difference a centred hub forces.

The frame rests on the **rear** edge of its flat bottom — a slab leaning backwards contacts
at the back of its base. The 2 mm rear chamfer moves that contact edge forward, and with the
equal-stance hub the centre of mass sits 9 mm (portrait) and 6 mm (landscape) behind it.

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

### Hardware

- 4 × **M2.5 heat-set inserts**, 4.0 OD × 4.0 long, in the frame's end walls
- 4 × **M2.5 countersunk screws**, 8 mm, for the cover
- 1 × **Ø2 × 43.5 mm pin** for the hinge — steel rod, or a flared 1.75 mm filament offcut
- 1 × **Waveshare FPC adapter**, 18 × 32, plus a second FPC to the driver board
- 4 × screws for the adapter — size not yet measured
- **Double-sided 0.1″ prototype board**, cut to 30 × 70 (driver carrier + divider)
- 2 × **19-pin 2.54 female headers** for the driver to plug into
- **Panel-mount USB-C pigtail**, 14 × 4.5 snap-in body (measured)
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
| `drv_module` | 1050 mm³ — a 15 mm driver stack against a module PCB | empty: no module PCB to hit |

`disc_legf` reports geometry **on purpose**: it is the catch lip overlapping the folded
leg's foot, which is the interference the leg flexes past to snap shut.

`disc_legd` reports geometry now too, where it used to be empty, and also on purpose — two
things touch there. The clamp land is at the pivot, so it is in contact at every leg angle;
and at the deployed angle the leg also lands on the slot's rear wall, which is the hard stop
doing its job. `disc_legs` reports the same thing at whatever angle `chk_th` asks for. It reads **0.4 mm** rather than the designed 0.2, because the check draws the leg
centred in its slot while the land pushes it 0.2 mm over onto the far wall. Read it as
`clamp_pr` (0.6) less one side of `leg_slot_c`.

`cover_legs` is the one that must stay empty, and it must stay empty **through the whole
stroke**, not just at the two ends — that is what caught the heel corner.

`adapt_board` is the one genuine conflict in the build: the adapter overlaps the carrier for
31.25 mm. It is not a by-design touch and it does not have a fix yet. `adapt_cover` comes
back zero-thickness, which is the adapter's back face sitting flush on the pocket face.

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
| The driver stack measures deeper than 16 mm | `drv_stack` — and then the depth has to grow or the board has to come off the pocket |
| Bigger cell | `bat_w` / `bat_h` / `bat_t` — the band is 79.5 wide × ~51 tall |
| Three side buttons | `btn_n = 3`, then `btn_d` / `btn_sp` |
| More/less white line | `white_show_short` / `white_show_long` |
| Different lean | `stop_ang`, or `pivot_r` |
| Rear port position | `ucb_x` / `ucb_z`; `port_w` / `port_h` for the opening |
| Deeper/shallower back bevel | `rear_chf` — 2.0 is the ceiling before it eats the 2.2 mm walls |
| Looser/tighter disc | `pocket_c` |
| Open the flash port again | `flash_port = true` |

Preview modes: `standing_p`, `standing_l`, `folded`, `guts` (cover populated with mock
electronics), `assembly`, `plate`.

Interference checks are built in — `chk` = `frame_cover`, `frame_module`, `cover_module`,
`cover_board`, `frame_board`, `drv_module`, `conn_cell`, `conn_board`, `conn_cover`,
`cover_disc`, `disc_legf`, `disc_legd`, `cover_legd`, `cover_legf`, `adapt_board`,
`adapt_cover`, and the swept ones — `cover_legs` and `disc_legs` take `chk_th` and walk the
leg's whole travel, and `wall_leg` takes `chk_th` and `chk_d` and asks how far behind the
pivot the leg reaches at a given angle, which is what `stop_wall` was set from:

```bash
openscad -o /tmp/chk.stl -D 'part="none"' -D 'chk="cover_board"' src/epaper_stand.scad

# the leg's whole stroke against the cover -- every angle must write NO FILE
for t in 0 20 40 60 80 100 122; do
  rm -f /tmp/chk.stl
  openscad -o /tmp/chk.stl -D 'part="none"' -D 'chk="cover_legs"' -D "chk_th=$t" \
    src/epaper_stand.scad 2>/dev/null
  [ -f /tmp/chk.stl ] && echo "theta $t CLASHES"
done
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
