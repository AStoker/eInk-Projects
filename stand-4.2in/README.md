# 4.2" e-Paper desk frame — minimal bezel, rotating kickstand, battery inside

A slim desk frame for the **Waveshare 4.2inch e-Paper Module (B)** driven by the
**Waveshare e-Paper ESP32 Driver Board**, with a LiPo, a power-path charger and a
quarter-size Perma-Proto inside, and a single rotating kickstand on the back that folds
flush and turns 90° for portrait or landscape.

One parametric OpenSCAD file: `src/epaper_stand.scad`.

```
  91.9 × 108.4 × 25.0 mm         ┌──────────────┐
  bezel 13.45 side / 10.5 top-bot│ ┌──────────┐ │
  1.3 mm of panel white showing  │ │          │ │  ╲
  ~116 g of filament, 4 parts    │ │   ink    │ │   ╲
  both orientations lean 20°     │ │          │ │    ╲
                                 │ └──────────┘ │  ───╲
                                 └──────────────┘
```

---

## Names

Two dimensions got read as the wrong axis while this was being built, both times because
"width" and "height" swap over when the frame is turned. So: **never width/height for
anything belonging to the display.**

| Axis | Glass | PCB | Model | In portrait (the default) |
|---|---|---|---|---|
| **short axis** | 76 | 78.5 | X | horizontal. **The ribbon leaves the glass on this axis.** |
| **long axis** | 90 | 103 | Z | vertical |
| **depth** | 1.05 | 1.6 | Y | 0 at the outer front face |

Depth is the axis that points *up* off the print bed, so "taller", "more room on top" and
"height off the glass" in slicer terms all mean **deeper** here.

### The three nested recesses

Front to back. Not interchangeable, and each has its own clearances:

| Name | What it holds | Size | Parameters |
|---|---|---|---|
| **window** | nothing — it's the through-opening the ink is seen through | 65.0 × 87.4 | `win_*` |
| **glass pocket** | the glass, in a shallow step | 77.5 × 91.5 × 1.26 | `pan_*` |
| **PCB cavity** | the module PCB, behind the glass | 79.5 × 104 | `cav_*` |

### Vocabulary

- **bezel** — the visible plastic between the window edge and the outer edge (13.45 on the
  short-axis sides, 10.5 on the long-axis ends). Never the pocket. Also not a *bevel* — a
  bevel is an angled edge, which here is a **chamfer** (`front_chf`, `win_chf`, `rear_chf`).
- **clearance** / **margin** — the gap between a part and the recess holding it. Always
  quoted as the **total across an axis**, not per side: "margin 1.5 on the short axis" is
  0.75 a side.
- **relief** — material taken away at a **corner**, so a sharp-cornered part can seat in a
  printed corner that carries a nozzle fillet. Always centred *on* the corner; that is the
  function, so it cannot be moved inboard. There are two, and they are different things:
  **pocket relief** (`pan_rel`, glass pocket corners) and **cavity relief** (`cav_rel`, PCB
  cavity corners).
- **ribbon relief** — the notch in the short-axis edge that the ribbon folds back through.
  Three independent sizes, deliberately *not* called width/height/depth:

  | | Parameter | Now | Meaning |
  |---|---|---|---|
  | **out** | `rib_clr` | 3.0 | outboard from the pocket edge, along the short axis |
  | **deep** | `rib_dep` | 3.0 | past the glass back face, along depth |
  | **long** | `rib_w` | 40.0 | along the pocket edge, on the long axis. `rib_off` pins the bottom end, so raising this extends the slot **upward only** — it does not recentre |

- **white show** — `white_show_short` / `white_show_long`, the strip of the panel's own white
  border left visible inside the window on purpose. **One per axis** (0.7 short, 1.3 long),
  because the window is specified on the short axis and one shared value cannot do both.
- **parts** — **frame** (front shell), **cover** (back), **disc** (rotating puck), **leg**
  (kickstand), and the **bezel test tile** (front-face-only print for checking fit).
- **tape pad** — `tape_*`, a shallow recess in the **ledge behind the glass** where tape holds
  the glass down from the rear. Two of them, one at each long-axis end. Not visible from the
  front.

### The glass is taped from behind, not press-fitted

A printed 91.0 pocket measured short on the long axis, so the pocket is now **77.5 × 91.5** —
1.5 mm of total margin on *both* axes, sized for print variance rather than for a press fit.
Loose enough to rattle, so the glass is taped: tape runs across the glass **back** face, over
the pocket edge, and onto the ledge at `pcb_face_y`.

That ledge — the step between the glass pocket and the larger PCB cavity — is the only frame
surface behind the glass, and it is the reason the pads go where they do:

| Edge | Ledge width | Usable |
|---|---|---|
| each long-axis end | **6.25 mm** | yes |
| short-axis sides | 1.00 mm | no — too narrow to stick to |

So two pads, one at each long-axis end, each **40 mm along the short axis × 5 mm into the
ledge × 0.3 mm deep**, starting at the pocket edge so tape runs off the glass without a step
to climb. Pad face lands at depth 2.35 against a glass back face at 2.45, so the tape dips
0.1 mm rather than standing proud.

**They are recessed because the PCB front face lands on that same ledge** (depth 2.65). Tape
lying on top of it would push the whole module back by its own thickness. Recessed, tape
thickness stops mattering.

The cost is PCB seat: 5 mm of the 6.25 mm ledge is recessed over 40 mm of the 79.5 mm width,
leaving 1.25 mm of full-height seat at each end plus the full ledge outboard of that 40 mm,
and the 1.00 mm short-axis ledges untouched down both full sides. `frame_module` is clear.
`tape_pad = false` removes them.

---

## Power architecture

**Don't use the PowerBoost 1000C here.** Waveshare's own docs for the driver board say
the *5V pin supports 3.6V to 5.5V voltage input and can be powered by a lithium battery*
— so a 1S cell feeds the board directly and the boost stage is pure loss.

*Powered by*, note — not *charges*. The driver board has no charge circuit, no battery
connector and no charge LED; its 5V pin is an input only. Running from a cell and
refilling that cell are two different jobs, and the second one is why a charger is in
the build at all. (The board that would have done both is the FireBeetle 2 ESP32-E — JST
charging onboard — which is the swap you passed on.) Worse, the
PowerBoost draws **5mA whenever it's enabled**, which is 120mAh/day; on the 2000mAh cell
that's ~17 days of standby on the 2000mAh cell before the ESP32 draws anything.

The chain used here:

```
USB-C ─┐
       ├─ bq25185 ── LOAD (3.0–4.5V, power-path) ── 5V pin ── 3V3 LDO ── ESP32
LiPo ──┘
```

- **Adafruit bq25185** (#6091, $6.95): USB-C in, JST battery, JST load out regulated to
  ≤4.5V, real power-path so it runs from USB while charging instead of cycling the cell.
  Charge current is a solder jumper — set 1A, 0.5C for the 2000mAh cell.
- No boost stage, one conversion instead of two, and the charger's own idle draw is
  microamps rather than milliamps.

**The charge port is on the back**, not the charger's own USB-C. A small USB-C breakout
(one with the 5.1kΩ CC pulldowns) stands in printed guide rails behind the cover with its
receptacle flush in the back face; two wires run from it to the charger's **VBUS** and
**GND** pads. Charge only, no data — which is all this needs.

### One opening in the whole assembly

`flash_port = false`, so the **charge port in the back plate is the only hole in the
finished case.** The driver board's own USB-C — which is for *flashing*, not power — used to
break through the long-axis top end; that wall is now solid, with a **blind** pocket behind
it so the jack still has somewhere to sit (it stands 0.2 mm past the cavity wall, so the
pocket is not optional), leaving 1.5 mm of skin. `frame_board` is clear.

⚠ **Flash the ESP32 before final assembly.** With the port closed there is no wired access
to the driver board once the cover is on, and the charge port is deliberately charge-only —
two wires to VBUS and GND, no data lines. The first flash has to be wired, so OTA is the
only route to anything after that. Set `flash_port = true` to cut the opening back through.

Why not a flexible USB-C extension cable: they exist and they're good (panel-mount
male-to-female FPC ribbon extensions, IP67, 100W, 10–20cm), but the male end has to plug
into the charger's connector and a mated USB-C plug needs ~10mm of straight clearance
plus a bend radius. Wherever the charger sits on the Perma-Proto there's 1–3mm of gap
around it, so there's nowhere for the plug to go. Two wires to VBUS sidesteps the whole
problem and is thinner, cheaper and more robust. Keep the ribbon option in mind for a
future build where the charger sits at an edge.

### If it lives on battery and only gets plugged in to charge

That doesn't change the charger — power path is only one of the charger's virtues, and the
OUT clamp at 4.4V and the clean termination still earn it. But three things do change.

**Runtime becomes the headline number, and it's about five weeks.** Note the 3.6V floor:
the board browns out there, so you only get the cell down to 3.6V, which is roughly 85% of
its 2000mAh. Against ~49mAh/day that's **~35 days**, and about 95% of that budget is the
board sitting idle — a few refreshes a day cost barely 1mAh between them. Refresh as often
as you like; it is not what empties the cell.

**The low-voltage cutoff stops being optional.** Plugged in most of the time you'd almost
never reach the floor. On battery you reach it every cycle, and with nothing to stop it the
ESP32 brownouts, boot-loops and drags the cell down to its protection PCB at ~2.5V. Deep
discharge is what actually kills LiPo cells. Read the divider on every wake; below ~3.6V
call `esp_deep_sleep_start()` with no timer and leave it there.

**A power switch is worth its hole now.** A slide switch in the OUT line lets you park the
thing without draining it. `btn_n` already cuts holes in the +X wall if you want one there.

**And the board swap looks different than it did.** When this was going to live on USB,
sleep current barely mattered. On battery it is essentially the whole story: the same cell
behind a FireBeetle 2 ESP32-E (13µA) lasts several years on paper instead of five
weeks. That is a ~20× difference, and it deletes the charger and the Perma-Proto from the
build. The cost is rewiring the display's eight lines to a different pinout.

**Measure before you commit.** Waveshare's `<2mA` is a spec, not your board. Put a
multimeter in series with the battery lead and read the real sleep current — a USB meter
won't resolve single milliamps. If there's a power LED on the board, cutting it is often
worth 1&ndash;2mA on its own.

**The number that actually sets your runtime** is the driver board itself. Waveshare
rates it at `<2mA` idle, and only if you switch **DIP switch 2 off** to unpower the
CP2102 — leave it on and a reviewer measured 10–13mA in "deep sleep". At 2mA:

| | Standby | With hourly refresh |
|---|---|---|
| 2000mAh cell | ~41 days | ~33 days |
| Same board + PowerBoost | ~14 days | ~13 days |

If you ever want months rather than weeks, no charger choice fixes it — that's a board
swap (a FireBeetle 2 ESP32-E is ~$9, sleeps at 13µA, and has the charger built in, which
would delete the charger and the Perma-Proto from this build entirely).

**Also add:** a resistor divider from the cell to an ADC pin so firmware can show the
state of charge and stop refreshing when the cell is low. The board browns out below
~3.6V, which is above a LiPo's damage threshold, but don't rely on that as protection.

### The salvaged cell: red, black, yellow

Three wires almost certainly means the pack carries an **NTC thermistor**: red = B+,
black = B−, yellow = the thermistor's other leg (its common leg is tied to black). That is
good news — both charger candidates have a thermistor input, brought out as **TH** on the
bq25185 (#6091) and **THERM** on the bq24074 (#4755). It ships jumpered (function
disabled); **cut that jumper** and wire yellow to the pad, and the charger will refuse to
charge outside roughly 0–45 °C instead of trusting a salvaged pouch to behave.

Before it goes anywhere near the charger:

1. **Verify polarity with a meter.** Do not trust wire colour on a teardown — someone
   else's harness convention is not yours. Red should read positive with respect to black,
   somewhere in 3.0–4.2V. Reversed onto the charger it is dead on contact.
2. **Confirm yellow is actually an NTC.** Measure yellow→black: a 10k NTC reads ~10kΩ at
   room temperature and *falls* as you warm it between your fingers — you should see it
   move a few hundred ohms within seconds. If it reads near 0Ω, near open, or doesn't move,
   it is not a thermistor (some packs use the third wire for an ID resistor or a
   thermal fuse) and it must not go to the TH pad. Leave the jumper intact instead.
3. **Check whether the pouch still has its protection PCB.** Look for the small board under
   the tape at the tab end. If Yoto did protection host-side and this pouch is bare, it has
   no overcurrent, overdischarge or short protection of its own — the charger protects
   against overcharge but not against a short at the load. Add a protection module, or
   don't use it.
4. **Check the resting voltage and its history.** Below ~3.0V after sitting, or any sign of
   swelling, and it goes in the recycling. A puffed cell in a sealed 25mm enclosure with a
   glass panel bonded to the front is not a risk worth 2000mAh.

If the NTC checks out, cut TH and wire it. Set the charge current to **1A** (0.5C for this
cell) — but read the warning about the conflicting default below.

### Charger choice

Both candidates are sold as *Universal USB / DC / Solar*, and the solar part is a feature
of a general-purpose charger, not a constraint: it's input-voltage regulation that backs
the charge current off rather than dragging a panel into voltage collapse. On a USB supply
it never engages.

**The build uses the bq25185 (Adafruit #6091).** It does everything the bq24074 does for
less than half the price:

| | bq25185 · #6091 | bq24074 · #4755 |
|---|---|---|
| Price | **$6.95** | $14.95 |
| Charge current | 250 mA / 500 mA / 1 A | 0.5 / 1 / 1.5 A |
| USB input | USB-C **with 5.1 kΩ CC resistors** | USB-C |
| DC / solar input | 5–18 V (25 V tolerant) | 5–10 V (28 V tolerant) |
| Power path | yes | yes |
| Regulated load output | 4.5 V max | 4.4 V max |
| Thermistor | **TH** pad, cut the TH jumper | **THERM** pad, cut the jumper |
| Battery sleep current | ~4 µA | 4.3 µA typ |
| Board | 32.0 × 26.3 × 7.2 | 25.4 × 20.3 |
| Status | PWR / CHRG / FAULT LEDs, S1 + S2 pads, /CE | CHG + PGOOD open-drain |

The bq24074's only real advantages are 1.5 A charging (irrelevant — 1 A is already 0.5C
for this cell) and a slightly higher input transient rating (irrelevant on USB). Sleep
current is a wash, ~4 µA either way; that was worth checking and it did not favour either
board.

⚠ **Adafruit's two pages disagree on the default charge current** — the product page says
1 A, the pinout guide says 500 mA with jumpers for 1 A and 250 mA. Check the board before
you assume. 1 A is what you want here.

The #6091 is the bigger board (32 × 26.3 against 25.4 × 20.3) but it still lands well
inside the quarter Perma-Proto and leaves 7.1 mm in front of it. `chg_part = "bq24074"`
switches the model back if you'd rather use the other one.

**If you want to go simpler:** Adafruit's Micro-Lipo USB-C (#4410, $5.95) is smaller and
cheaper still, but it has no thermistor input and tops out at 500 mA — over four hours for
2000 mAh. At the driver board's ~2 mA the missing power path barely matters; the missing
thermistor is what rules it out for a salvaged cell.

**The option that actually changes the outcome** is not a charger at all. A FireBeetle 2
ESP32-E (~$9) sleeps at 13 µA against the Waveshare board's ~2 mA and has charging
onboard — it would delete the charger *and* the Perma-Proto and turn five weeks of runtime
into years. The cost is rewiring the display's eight lines to a different pinout and
re-cutting the cavity. Noted, not taken.

## Buttons

Not fitted, but the frame is ready. The display uses **GPIO 13 (CLK), 14 (DIN), 15 (CS),
25 (BUSY), 26 (RST), 27 (DC)**; everything else on the headers is yours. For buttons that
also wake the ESP32 from deep sleep you need RTC-capable pins — **GPIO 32/33 are the
cleanest** if the headers bring them out, otherwise **GPIO 4**. Avoid 0, 2, 12 and 15 as
button pins; they're strapping pins and a button held at reset changes boot behaviour.

To add them later: set `btn_n = 3` in the SCAD file and re-export the frame. That cuts
three Ø4.2 plunger holes in the +X wall (9.6mm thick, the only wall with real meat in
it), 12mm apart, for switches mounted on a strip inside. There is no room for front
buttons — the bezel is 10.5mm and the module's PCB is directly behind it.

---

## What goes where

Cavity is 79.5 × 104 mm, split into two horizontal bands: the boards share one, the cell
takes the other.

```
        ┌─────────────────────┬───────────────┐
   ┌────┤  Perma-Proto        │  Waveshare    │ ← USB-C (flash) out the top edge
   │    │  quarter-size       │  driver board │
   │    │  43.2 × 50.8        │  29.5 × 48.3  │
   │    │  + bq25185          │               │
   │    ├─────────────────────┴───────────────┤
 104 mm │  ┌────┐                     ┌────┐  │
   │    │  │pad │   LiPo 2000mAh      │pad │  │
   │    │  └────┘   44 × 49 × 6.9     └────┘  │
   │    │  ┌────┐   694449 pouch              │
   └────┤  │USB │   ┌ ─ ─ ─ ─ ─ ─ ┐          │ ← ⚠ 8-pin header keep-out
        │  └────┘   └ ─ ─ ─ ─ ─ ─ ┘          │    assumed here — see below
        └─────────────────────────────────────┘
              ← 79.5 mm →
```

Why this way round: the two boards fit side by side across one band — 43.2 + 2.7 +
29.46 = **75.36mm in a 79.5mm cavity** — and the 2000mAh cell (44 × 49) takes the other.
No other split works: rotate the cell, or put one board beside it, and some board always
ends up short of width.

### ⚠ Second open item — the ribbon relief now sets the frame width

The measured ribbon requirement (16 mm wide, 4 mm of room to bend) punches a notch in the
glass pocket that reaches **1.80 mm further out than the PCB cavity does**. The frame's
width is no longer set by the boards — it's set by that notch:

```
SHORT AXIS driven by: THE RIBBON RELIEF  (cavity needs 45.15, ribbon needs 45.95)
OUTER: short axis 91.9 | long axis 108.4 | depth 25
```

The model grows `W` automatically to keep `wall_rib = 1.0` mm of material outboard of the
notch, so it is always valid — but it costs **3.60 mm of width** over what the electronics
need, and the side bezels went 12.05 → 13.45 mm. Note the notch sits just outboard of the
*pocket*, so widening `pan_clr_w` pushes it out and the frame grows with it — that is why
the 0.75 mm pocket clearance cost 0.5 mm of overall width.

✅ **The three ribbon numbers now close.** They used to not: `rib_off` was 17 and the measured
far side was irreconcilable with it (17 + 41 + 37 = 95 against a 90 mm glass). Measured
properly the slot is **15 from the top edge, 35 from the other, 40 long** — and 15 + 40 + 35
= 90 exactly, with `rib_far` reporting 35 rather than being forced to absorb an error.

⚠ **`rib_off` is measured from the model's −Z edge, and that edge is the *top*.** This is the
one number that has been got wrong twice in a row, in both directions. Two things corroborate
15: the sum closes, and `conn_dz = −44.5` puts the module's 8-pin header on the same −Z half,
which is where the ribbon has to fold back to. If a future measurement suggests 35, check the
header side before changing it — if the module is genuinely the other way up, `conn_dz` has to
move too, and so do the cell and board bands. Worth re-checking which edge the 17 is measured from — `rib_off` is the one number
to change if it's the other end.

**One measurement gets most of that back:** how far the glass sits from the PCB edge on the
ribbon side. The PCB is 78.5 wide and the glass is 76, so there is 2.5 mm to distribute. If
the glass is pushed toward the *thin*-border side, the notch starts further inboard:

| `pan_off_x` | Frame width | Side bezel | Notes |
|---|---|---|---|
| 0 (glass centred, assumed) | **91.9** | 13.45 | current |
| 0.625 | 92.65 | 13.23 | |
| 1.25 | 91.40 | 12.60 | |
| 1.8 (glass flush to the thin-border PCB edge) | **90.3** | 12.05 | notch free — the PCB cavity takes over as the limit, so nothing past 1.8 buys width |

Measure the gap between the glass edge and the PCB edge on *each* side of the ribbon axis,
set `pan_off_x` to half the difference, and re-export.

### ⚠ Open item — measure this before you print

The depth budget is set **over the cell**, not over the boards: **7.9mm** clear there
against **12.7mm** over the PCBs. So whichever band the module's 8-pin header lands in
has to be the *board* band — the boards clear a 9mm mated PH2.0 plug, the cell does not.

The model now carries that header as real geometry (`mod_conn()`) and checks it, and with
the **assumed** position it fails:

```
HEADER vs CELL: needs 9, has 7.9 -> CLASH by 1.1 mm
```

Three numbers on the actual module settle it. Measure them:

| Measure | Sets | Assumed |
|---|---|---|
| Which Z edge the 8-pin header is on, and where across X | `conn_dz`, `conn_dx` | bottom edge, centred |
| How far it stands off the PCB back, mated, including the wire bend | `conn_h` | 9.0 mm |
| Whether the glass is centred on the PCB along the 103mm axis | `pan_off_z`, `act_off_z` | centred |

That last one matters as much as the first: Waveshare publishes 103 × 78.5 for the PCB and
91 × 77 for the glass but no datum between them. If the 12mm of bare PCB is all at one end
rather than split 6/6, the ink is 6mm off where the window is cut. The model is plumbed for
it — `act_off_z` moves the window with the ink — but the default assumes centred.

Three ways out of the header clash, cheapest first:

1. **Swap the bands** — boards into whichever band the header lands in, cell into the
   other. No thickness cost, but it moves the flash port to the opposite wall and pushes
   the charge port out of the board band.
2. **Right-angle PH2.0 housing**, or desolder the header and lay the eight wires flat off
   the pads. Keeps `depth = 25`; needs `conn_h ≤ 7.4`.
3. **`depth = 26.6`** and re-export. Everything downstream follows, at +1.6mm thickness.

The half-size Perma-Proto doesn't work here — at 50.8mm wide it leaves only 28.9mm beside
it, which is narrower than any sensible cell, and it forces the driver board onto a second
layer. The quarter-size fits with 2.5mm to spare.

### Mounting

- **Perma-Proto** — two M2.5 screw posts on the board's 1.4″ hole spacing plus four
  corner pads. Verify the hole positions against your board before printing.
- **Driver board** — slides down into two printed rails, no holes needed, with a stop at
  the bottom and the USB-C facing the top edge.
- **Cell** — drops into a fenced pocket on a flat platform (the platform exists so the
  cell doesn't straddle the step where the stand pocket bulges into the interior).
  Foam tape holds it.
- **Module** — bezel lip in front, two printed pads above and below the cell behind. Foam
  tape on the pads takes up the tolerance stack.

### Ports

| Port | Where | Purpose |
|---|---|---|
| USB-C breakout | **back face**, 25mm left of centre, 15.5mm up | Charging and running from the wall. Wired to the charger's VBUS + GND |
| USB-C (Waveshare) | top wall | Flashing. DIP switch 2 on to program, **off** to run |

The rear port sits below the stand pocket and off the leg's centreline, and the back edge
carries a 2mm chamfer, so a plug clears the desk with the frame leaning back. A
right-angle cable is tidier but not required.

---

## The kickstand

- **Disc** Ø54 × 4 mm — bayonets into the pocket (three lugs, twist ~45°), four radial
  detents at 0/90/180/270°. Turn it to 45° to lift it out.
- **Leg** folds flush into the disc, swings out to a hard stop at 58° where a flat heel
  lands on the pocket floor, so the load goes into the cover skin rather than the hinge.
- **Pin** Ø2 × 43 mm steel rod, or a cut length of 1.75 mm filament. Trapped by the pocket
  wall once the disc is in.

**The hub is deliberately 8.55mm below the frame's centre**, at exactly half the frame's
*width* above the bottom edge. Rotate the frame 90° and the pivot ends up the same
distance above whichever edge is now the bottom — so portrait and landscape get an
identical stance instead of the ~9° difference a centred hub forces.

| | Lean | Footprint |
|---|---|---|
| Portrait | 20.0° | 32 mm |
| Landscape | 20.0° | 32 mm |

Two corrections worth recording, because both were wrong in the earlier revision:

- **The frame rests on the rear edge of its flat bottom, not the front edge.** A slab
  leaning backwards contacts at the back of its base. Getting this backwards made the
  earlier lean figures ~10° too shallow and hid a stability problem: at the real angles the
  centre of mass sat almost directly over the contact edge in landscape, so a nudge would
  have flopped the frame flat on its face. The 2mm rear chamfer moves the contact edge
  forward and the equal-stance hub fixes the rest — the CoM now sits 9mm (portrait) and
  6mm (landscape) behind the contact edge.
- **A 3-position ratchet isn't buildable at this thickness.** The hinge axis lies *in* a
  4mm disc so the knuckle can't exceed ~3mm, putting 15° teeth at 0.4mm — under what a
  0.4mm nozzle resolves. And the load wants the leg to *open*, at ~30 N·mm about the
  hinge, which no printed detent that size holds. A single stop, plus the equal-stance
  hub, does the job.

---

## Parts and printing

| Part | STL | Orientation | Filament |
|---|---|---|---|
| Frame | `stl/frame.stl` | front face on the bed | ~54 g |
| Back cover | `stl/cover.stl` | outer face on the bed | ~47 g |
| Disc | `stl/disc.stl` | outer face on the bed | ~8 g |
| Leg | `stl/leg.stl` | flat | ~2 g |
| Bezel test tile | `stl/bezel_test.stl` | front face down — **print this first** | ~20 g |

PLA or PETG, 0.2mm layers, 4 perimeters, 15–20% infill, **no supports** — the bayonet
groove and window chamfer are both cut at 45°, and the only bridge left is the 1.9 mm ceiling
over the closed flash pocket. Put the
visible face on the bed; that surface finish is most of the look.

### Hardware

- 3 × M2.5 × 8mm self-tapping screws (cover)
- 2 × M2.5 × 6mm (Perma-Proto)
- Ø2 × 43mm rod or filament offcut (kickstand pin)
- Adafruit **bq25185 (#6091)**; 1S LiPo **2000mAh, 694449 pouch, 44 × 49 × 6.9mm** (the Yoto teardown cell)
- USB-C breakout board with 5.1kΩ CC pulldowns, ~13 × 13mm
- JST-PH pigtails, foam tape

---

## Verify before printing the frame

`bezel_test.stl` is the full front face plus a stub of the module pocket — 91.9 × 108.4 × 6.85 mm, ~40 minutes. Glass pocket **77.5 × 91.5** (1.5 mm of total margin on both axes — deliberately loose; the glass is taped, not press-fitted), window **65.0 × 87.4**, and the ribbon relief runs **3 mm past the glass back face** so the ribbon can fold back on itself.

| Parameter | Model | Check |
|---|---|---|
| `act_off_x` | 3.2 mm | Ink centre vs glass centre. Now **derived from the measured 3.0 / 9.4 borders**, not inferred. |
| `pan_off_x` | 0 | Glass centre vs **PCB** centre. **Still to measure** — see below; it is worth up to 2.5 mm of frame width. |
| `conn_h` | 9.0 mm | Height of the module's 8-pin header off its back, mated. **7.9mm available over the cell — currently clashes by 1.1mm.** |
| `conn_dz` / `conn_dx` | −44.5 / 0 | Which edge that header is on. Assumed, not measured. |
| `pan_off_z`, `act_off_z` | 0 | Glass assumed centred on the PCB along the 103mm axis (6.5mm of bare PCB at each end). **Unverified.** |
| Proto hole spacing | 35.6 mm | Check against your actual quarter-size board. |
| USB-C position | centred | On both the driver board's short edge and the charger's. |

---

### The bezel test tile is now a slice of the real frame

It used to be hand-built from the same primitives, and it had drifted: its middle cut
(`W-14 × H-14`, R5) was **larger than the glass pocket on the +X side**, so it deleted two
of the four pocket corners and replaced them with a plain R5 radius. What you were looking
at genuinely had rounded corners — the frame did not, but the test tile did.

It is now an `intersection()` of the actual `frame()` with a box — the front 6.85 mm of the
full 91.9 × 108.4 face — so it *cannot* drift from the part you are going to print. The
depth is no longer a round number: it tracks the ribbon relief (`rib_y1 + 1.4`), because a
fixed 5.65 left a 0.2 mm membrane across the relief floor — a slot that printed closed.

**It is the whole front bezel, not a band of it.** A bottom-34 mm slice was tried and it is
the wrong test: it shows two of the four pocket corners and no top edge, so the module has
nothing to seat against and flush-fit is exactly what you cannot judge. Full height costs
~20 g and ~40 minutes and lets you drop the real module in.

What it shows: all four glass-pocket corners with their relief, all four cavity corners with
theirs, all four bezels, the complete window lip and chamfer, and the full ribbon cutout.
Set `bt_h = 34` in the source for the old bottom-band tile if you only want the corners.

### The interference checks test volume, not emptiness

`intersection()` returns coincident faces as zero-thickness sheets, so two of the 13 checks
have always come back with geometry in them and no interference at all: `frame_cover` (the
frame's rear face and the cover's front face are both at `y = body_d`) and `cover_board`
(the board sits exactly on its standoffs). Measure the volume. Current state: 10 empty, those
2 zero-volume, and `conn_cell` a real 154 mm³ — the known 8-pin header vs cell clash that
wants `depth = 26.6`.

### Verifying the relief actually works

`mock_module()` used to draw the PCB and the glass with R1 corners, which meant the
`frame_module` interference check could never have caught a corner-fillet problem. Both are
now **sharp-cornered squares**, matching the real parts. With that in place:

| Setting | `frame_module` |
|---|---|
| `cav_rel = 0`, `cav_r = 1.5`, `pan_rel = 1.4` (as shipped) | clear |
| `cav_rel = 0`, `cav_r = 2.0` | **CLASH** 0.1045 mm³ — the PCB corner fouls the cavity arc |
| `cav_rel = 0`, `cav_r = 1.75` | **CLASH** 0.0053 mm³ — still just too round |
| `pan_rel = 0` | clear, but kept anyway — cheap insurance on the glass corners |

### The cavity relief is gone, because the corner radius was the real problem

`cav_rel` was never doing its own job. The cavity corner was rounded to `cav_r = 2.0`, and a
**sharp** PCB corner sitting in a 0.5 mm-clearance pocket needs the arc centre within `r` of
it — at R2.0 the corner pokes **0.121 mm** past the arc. So a relief circle had been added to
cut that material away, which meant paying for an over-large radius twice: once in the clash,
once in the R1.2 bite it took out of the cavity wall.

The condition is `cav_r ≤ 0.5·√2/(√2−1) = 1.707`. At **`cav_r = 1.5`** the PCB corner sits
0.086 mm inside the arc, `frame_module` is clear with **`cav_rel = 0`**, and the wall left at
a cavity corner goes from 1.0 mm to **2.2 mm** — the relief had been eating half of it.

`pan_rel` stays at 1.4. The clearance alone would carry it, but nothing is bought by removing
it and sharp glass corners are the ones that actually have to seat.

### Three modelling bugs found by counting bodies

Checking `mesh.split()` per part — not just `is_watertight` — turned up three defects that
had survived every previous check, because a part can be perfectly watertight and still be
in pieces:

1. **`rear_chamfer()` sliced both parts clean in two.** The cutting box ran from
   `depth-rear_chf-0.01`, but the hull it subtracted started at `depth-rear_chf-0.005`.
   That 0.005 mm mismatch left a *full-cross-section* slab in the cut, severing the frame
   and the cover. Fixed by extending the hull past the box at both ends along the same 45°
   taper.
2. **The USB-C guide rails floated.** `xzext(ucb_l-5.0)` stopped them 5 mm short of the
   cover skin — they were suspended in mid-air. Now full depth, split in X so they miss the
   receptacle, and narrow enough to stay inside the cavity wall.
3. **The cover's register tongues missed the lip by 0.1 mm** — `cube([1.4,1.3,9])` ended at
   y 22.5 where the lip starts at 22.6. Two more loose crumbs. Now 1.6 deep, with the
   frame's matching slot deepened to suit.

All five parts are now one body each. `bodies=1` is part of the verification.

### The screw spine is referenced to the chamfered back face, not to W/2

`scr_x` used to be the midpoint between the cavity edge and `W/2`. That is wrong in a way
that only shows up when `W` moves: the cover's rear chamfer takes `rear_chf` off each side by
the time it reaches `y = depth`, which is precisely where the screw-head counterbore is
deepest. At `W = 93.9` there was 0.55 mm of margin and nobody noticed. At `W = 91.9` the
counterbore edge landed at 43.95 against a back face that also ends at 43.95 — **tangent,
0.05 mm of material**, thinner than one extrusion, so the head recess would have broken out
onto the chamfer.

It is now `(cavity edge + (W/2 − rear_chf))/2`, which centres the spine in the material
actually there: 1.00 mm to the cavity and 1.00 mm to the back-face edge, self-correcting at
any width. The screws moved 1 mm inboard, in the frame and cover together.

### Thin, but deliberate: the −X wall

Because the ribbon relief sets `W`, everything on the −X edge is tight, and the features there
are cavity-referenced so they did *not* move when `W` came in 2 mm:

| | wall left |
|---|---|
| outboard of the ribbon relief | 1.00 mm |
| outboard of the register slot | 1.50 mm (was 2.50 at `W` 93.9) |
| −X wall generally | 3.00 mm |

All printable at 0.4 mm nozzle, but the register slot is the one to watch if `W` ever comes
down further — it thins 1:1 with the outer face.

### One thing counting bodies does *not* catch

The cover exports with **10 non-manifold edges** — edges used by four facets instead of
two, where two surface patches meet along a line. They are not holes: CGAL rates the
result `Simple: yes / Volumes: 2`, the solid is closed, and slicers take it. They sit in
the `rear_chamfer()` hull region at the outer back face (a 0.04 mm sliver at y 24.96–25.00,
plus one at y 22.05–22.25), and they are **not** parameter-dependent — the same 10 appear
with the original clearances. The frame uses the same chamfer code and is clean, so it is
the interaction with the cover's rear-face features.

Left alone deliberately: `rear_chamfer()` is the code whose last epsilon adjustment sliced
both parts in two, and a cosmetically nicer mesh is not worth reopening it. If it ever does
need fixing, fix it there, and re-run all five parts.

## Print orientation

The STLs export ready to slice — **no rotating in Orca, no supports**:

| Part | On the bed | Why |
|---|---|---|
| frame | front face down | 3835 mm² of first layer, and the cavity opens upward. Printed the other way up the 1.4 mm front plate has to bridge the whole 79.5 × 104 cavity |
| bezel_test | front face down | same |
| cover | outer back face down | 6802 mm² of first layer, posts and rails build upward |
| disc, leg | flat | symmetric |

Only the 0.8 mm front chamfer overhangs, at 45°, on the first layer.

### ⚠ The STLs are MIRRORED IN X

`print_mirror = true` mirrors all five parts at export. They still mate with each other, but
the assembly is the **opposite hand** to the drawings: the ribbon relief, the screw spine
and the charge port are on the other side. On the bed the ribbon relief sits at **x ≈ +45.95**
(right of centre); un-mirrored it sits at −45.95.

The drawings show the **as-designed** hand, so a mirrored print reads left-right reversed
against every sheet. Set `print_mirror = false` to go back.

The interference checks run on the un-mirrored geometry, so they are unaffected either way.

## Tuning

```bash
openscad -o stl/frame.stl      -D 'part="frame"'      src/epaper_stand.scad
openscad -o stl/cover.stl      -D 'part="cover"'      src/epaper_stand.scad
openscad -o stl/disc.stl       -D 'part="disc"'       src/epaper_stand.scad
openscad -o stl/leg.stl        -D 'part="leg"'        src/epaper_stand.scad
openscad -o stl/bezel_test.stl -D 'part="bezel_test"' src/epaper_stand.scad
```

| Want | Change |
|---|---|
| Keep the stock PH2.0 cable over the cell | `depth = 26.6` |
| Header turns out to be on the other Z edge | swap the `bat_cz` / `proto_z1` / `drv_z1` bands, and move `flash` to the other wall |
| Bigger cell | `bat_w` / `bat_h` / `bat_t` — the band is 79.5 wide × ~51 tall |
| Three side buttons | `btn_n = 3`, then `btn_d` / `btn_sp` |
| More/less white line | `white_show` |
| Different lean | `stop_ang`, or `pivot_r` |
| Rear port position | `ucb_x` / `ucb_z`; `port_w` / `port_h` for the opening |
| Deeper/shallower back bevel | `rear_chf` — 2.0 is the ceiling before it eats the 2.2mm walls |
| Looser/tighter disc | `pocket_c` |

Preview modes: `standing_p`, `standing_l`, `folded`, `guts` (cover populated with mock
electronics), `assembly`, `plate`.

Interference checks are built in — `chk` = `frame_cover`, `frame_module`, `cover_module`,
`cover_board`, `frame_board`, `cover_disc`, `disc_legf`, `disc_legd`, `cover_legf`,
`cover_legd`. All ten come back empty.

```bash
openscad -o /tmp/chk.stl -D 'part="none"' -D 'chk="cover_board"' src/epaper_stand.scad
```

## Sources

- [4.2inch e-Paper Module (B) manual — 91 × 77 × 1.05 mm panel, 84.8 × 63.6 active](https://www.waveshare.com/wiki/4.2inch_e-Paper_Module_(B)_Manual)
- [e-Paper ESP32 Driver Board pinout and "5V pin supports 3.6V to 5.5V… can be powered by a lithium battery"](https://spotpear.com/index/study/detail/id/375.html)
- [e-Paper ESP32 Driver Board product page — `<2mA` low-power current with the CP2102 unpowered](https://www.waveshare.com/e-paper-esp32-driver-board.htm)
- [Fasani — measured 10–13 mA "deep sleep" on this board](https://fasani.de/2020/04/19/waveshare-eink-esp32-driver-board/)
- [Adafruit PowerBoost 1000C FAQ — 5 mA enabled, 20 µA disabled](https://learn.adafruit.com/adafruit-powerboost-1000c-load-share-usb-charge-boost/faq?view=all)
- [Adafruit bq25185 charger, #6091](https://www.adafruit.com/product/6091) · [pinouts](https://learn.adafruit.com/adafruit-bq25185-usb-dc-solar-lithium-ion-polymer-charger/pinouts) · [TI BQ25185](https://www.ti.com/product/BQ25185)
- [Adafruit bq24074 charger, #4755](https://www.adafruit.com/product/4755) · [pinouts](https://learn.adafruit.com/adafruit-bq24074-universal-usb-dc-solar-charger-breakout/pinouts) · [TI BQ2407x datasheet](https://www.ti.com/lit/ds/symlink/bq24074.pdf)
- [Adafruit Micro-Lipo USB-C, #4410](https://www.adafruit.com/product/4410)
- [USB-C panel-mount FPC ribbon extension (the option that didn't fit)](https://www.amazon.com/Elecbee-Female-Panel-Mount-Receptacle/dp/B0FWQ43QF2)
- [Perma-Proto quarter-size — 1.7″ × 2.0″, holes 1.4″ apart](https://www.pololu.com/product/2765) · [half-size — 3.2″ × 2.0″](https://www.pololu.com/product/2766)
- [FireBeetle 2 ESP32-E — 13 µA deep sleep, onboard charging](https://www.espboards.dev/esp32/dfrobot-firebeetle2-esp32e/)
