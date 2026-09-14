# Fusion hand-off

Everything needed to rebuild this frame in Autodesk Fusion: the measured
numbers, the component envelopes, sketch profiles of every feature, and the
vendor solid models that exist.

Regenerate the whole folder from the OpenSCAD model with

```bash
sh tools/mkfusion.sh
```

Only [`README.md`](README.md) and [`vendor/`](vendor/) are written by hand.
Everything else comes out of `src/epaper_stand.scad`, so it cannot drift from
the model or from the drawings.

The CSVs and the DXF sketches come out byte-identical run to run. The meshes do
not: OpenSCAD writes the same triangles in a different order each time, so
`git diff` will report `mesh/*.stl` and `mesh/*.3mf` as changed after any
regeneration even when the model has not moved. The geometry is the same — it
was checked triangle-for-triangle — so that diff is noise, not a change.

---

## The origin, first

One coordinate system runs through all of it — the OpenSCAD model's, in
millimetres:

| | |
|---|---|
| **X** | short axis. 0 is the centre, so the frame runs −45.95 … +45.95 |
| **Y** | depth. **0 is the outer front face**, and +Y goes back into the part |
| **Z** | long axis. 0 is the bottom edge, so the frame runs 0 … 110.5 |

Portrait. Say *short axis* and *long axis*, never width and height, for
anything belonging to the display — the model's own header explains why, and it
is the mistake that has cost this build the most time.

Nothing in this folder is in print orientation. The meshes, the DXF sketches
and the keep-out bodies all land on that one origin, so anything imported sits
where it belongs without being moved.

## On the Personal licence

This hand-off is built for Fusion **Personal**, and everything in it works
there. Worth knowing before you start:

- **Scripts and the API are available.** The setup script below is the main
  route in, and Personal does not restrict it.
- **STEP imports and exports.** The vendor charger model opens directly.
- **DXF (2D) imports.** All eight sketch profiles open.
- **3MF is not on Personal's format list**, so every mesh here is written as
  **STL as well** — reach for the `.stl` first and treat the `.3mf` as a bonus
  where Insert Mesh accepts it.
- **Ten active documents.** Each vendor model you upload takes one of them, and
  so does each part you model. PDFs and images do not count. When the count gets
  tight, deactivate what you are not editing — read-only documents are
  unlimited and nothing is lost.

Nothing here needs DWG, sheet metal, simulation, generative design or CAM, all
of which Personal restricts.

## Start here: run the script

[`scripts/EinkStandSetup/`](scripts/EinkStandSetup/) is the fastest way in. In
Fusion: **Utilities → ADD-INS → Scripts and Add-Ins → Scripts → the green + →
pick the `EinkStandSetup` folder → Run.** The folder holds the script and its
manifest, which is the layout Fusion's script picker expects.

It creates 105 user parameters, each carrying its comment from the OpenSCAD
source, and builds the eight component envelopes as bodies named
`KEEPOUT_PANEL_GLASS`, `KEEPOUT_DRIVER_BOARD` and so on, in the root component.
Run it again after re-generating and it updates the parameters in place and
rebuilds the keep-outs.

They go in the root component rather than one of their own because a **Part
Design** document may hold only one component, and this has to work in a part as
much as in an assembly. The `KEEPOUT_` prefix is what groups them: it sorts them
together in the Browser, so you can click the first, shift-click the last and
press **V** to hide all eight at once.

If it stops on something, it names the stage it stopped on. Neither half of it
is load-bearing: [`parameters.csv`](parameters.csv) and
[`keepouts.csv`](keepouts.csv) hold exactly the same numbers, and eight boxes
placed by hand from the CSV take about five minutes.

## The keep-outs

Eight bodies, one per thing that occupies space inside the case. They are
reference geometry: model the frame and cover around them, and if plastic and a
keep-out ever share space, the plastic is wrong. Full extents are in
[`keepouts.csv`](keepouts.csv).

| Body | Size, X × Y × Z | What it is |
|---|---|---|
| `PANEL_GLASS` | 76 × 1.05 × 90 | the bare glass, sharp corners, offset −3.2 in X to centre the ink |
| `FPC_HOLLOW` | 3 × 4.05 × 49 | where the panel's tail folds back through 180° |
| `DRIVER_BOARD` | 29.46 × 6 × 48.25 | Waveshare ESP32 driver board, whole component envelope |
| `DRIVER_CARRIER` | 30 × 1.6 × 70 | the perfboard the driver plugs into |
| `FPC_ADAPTER` | 18 × 5 × 32 | the service loop, taped to the back of the glass |
| `CHARGER` | 32 × 7.2 × 26.3 | Adafruit bq25185, board and USB-C jack |
| `CELL` | 44 × 6.9 × 49 | 2000 mAh LiPo pouch |
| `USB_C_PIGTAIL` | 14 × 10 × 4.5 | the snap-in rear port |

Three of them are deliberately larger than the part:

- `DRIVER_BOARD` is the full 6.0 envelope over the tallest component, not the
  1.6 bare board. The cover's rails overlap the board's edge by 1.0 to grip it,
  so an envelope at board thickness would read those rails as a clash.
- `FPC_HOLLOW` is sized for the fold, not the ribbon. It spans 14.5 below the
  tail's exit and 34.5 above it, which covers the tail at anything from 18 to
  24 long.
- `CELL` is squared off at 44 × 49; the real pouch has roughly R2 corners.

The whole stack has one tight dimension and it is the depth budget: the driver
board, its female sockets and the carrier measure **16.0** back-face to tallest
point, against **17.45** available — the register face gives 19.95 and
`carrier_lift` takes 2.5 of it to clear the solder joints under the carrier.
Everything else has room.

## Parameters

The two CSVs are split on purpose.

**[`parameters.csv`](parameters.csv)** — 106 rows, and every one of them is a
number that was measured or chosen. Nothing in the file is computed from
anything else in it, so each row is a value to type in once and then own. Rows
beginning `#` are group headings; drop them if an importer objects.

**[`reference-dimensions.csv`](reference-dimensions.csv)** — 268 rows, every
value the OpenSCAD model carries or works out: the outer 91.9 × 110.5, the
cavity, the board positions, the 22.3° lean, the derived clearances. These are
answers, not inputs. A Fusion rebuild should reach them from its own sketches
and constraints — the file is here to check against, which is why it is named
for reference and has no import format.

The Fusion script carries the same 105 parameters inline, so running it needs
no CSV at all — `parameters.csv` is there for reading, and for importing without
running a script. To go through the CSV instead, the **Parameter I/O** add-in reads
`"name","unit","expression","comment"` with every field quoted, which is the
format the file is written in — the quoting matters, because unquoted fields
make the add-in drop the first parameter.

Parameters the OpenSCAD source carries but that drive no geometry in it — the
FPC socket's own width, the adapter's PCB thickness and screw holes, the
carrier's pads, the flash-port opening — are collected in the last
group, marked as such. They are real measurements of real parts and may well
drive geometry in a Fusion rebuild even though they no longer do here.

## Sketch profiles

Eight DXF files, all in millimetres. **One sketch each, on its own plane** —
they are section cuts through the finished solid, not stages that combine into
it. See [Building the frame, step by step](#building-the-frame-step-by-step) for what each one is the
reference for. Check the extents against the table before building on anything:
a DXF that lands on the wrong plane or the wrong scale looks plausible until it
does not.

| File | Plane and cut | Sketch X | Sketch Y | Expected extents |
|---|---|---|---|---|
| [`dxf/front.dxf`](dxf/front.dxf) | frame silhouette from the front | model X | model Z | 91.90 × 110.50 |
| [`dxf/pocket.dxf`](dxf/pocket.dxf) | section at Y 1.925, through the glass pocket | model X | model Z | 91.90 × 110.50 |
| [`dxf/cavity.dxf`](dxf/cavity.dxf) | section at Y 6.65, inside the PCB cavity | model X | model Z | 91.90 × 110.50 |
| [`dxf/cover_in.dxf`](dxf/cover_in.dxf) | section at Y 23.1, just inside the cover | model X | model Z | 83.30 × 101.85 |
| [`dxf/cover_back.dxf`](dxf/cover_back.dxf) | cover silhouette from the back | model X | model Z | 90.72 × 109.41 |
| [`dxf/side.dxf`](dxf/side.dxf) | centreline section at X 0, frame and cover together | model Z | model Y | 110.50 × 25.00 |
| [`dxf/leg_side.dxf`](dxf/leg_side.dxf) | the leg's side profile, folded | model Z | model Y | 59.00 × 4.85 |
| [`dxf/layout.dxf`](dxf/layout.dxf) | the eight keep-out footprints in plan | model X | model Z | 83.10 × 90.00 |

Two of those extents are worth reading rather than skimming:

`cover_back.dxf` is 90.72 × 109.41, not 91.90 × 110.50. The cover's skin lives
entirely inside the 2.0 rear chamfer, so the chamfer trims its whole outline by
0.59 a side. The frame is the part that is 91.9 wide; the cover never is.

`layout.dxf` draws each footprint as a 0.1 mm outline rather than a filled
rectangle. The boxes overlap in plan — the cell sits behind the charger's
column — and a projection would union them into one silhouette, losing the
thing the sketch is for. It is a visual aid: two edges land within 0.02 mm of
each other (the driver board's −X edge against the glass's, at −41.18 and
−41.2) and merge into one line at that outline thickness, so take exact extents
from [`keepouts.csv`](keepouts.csv), not by measuring the imported sketch.

## Building the frame, step by step

**The DXFs do not combine into the part.** They are horizontal slices through a
solid that already exists, taken at four different depths, plus two vertical
sections and a layout. Lofting or joining them would produce nothing meaningful:
the features they show are pockets at different depths, not one cross-section
evolving through the part.

Build it from the numbers instead. **Every cut in this frame is a rounded
rectangle or a circle**, at a known centre, size and depth — so the whole part
is one extrude followed by twelve pocket cuts, each drawn from four numbers. The
DXFs are how you *check* a cut once it is made, not how you make it.

The numbers below are the model's own, from
[`reference-dimensions.csv`](reference-dimensions.csv). Parameter names are given
in brackets: type `65` now, and swap in `win_w` later when you want the sketch
to follow the parameter.

### Does this reproduce the STLs?

Yes, for all three printed parts. Every cut the OpenSCAD model makes is listed
here — the frame below, then [the cover](#building-the-cover) and
[the leg](#building-the-leg) — with the two features the model carries but
disables in this build called out so you do not model something that is not
there.

What you will not get is a byte-match, and you would not want one. The STLs are
faceted: a Ø2.1 bore in `frame.stl` is a 48-sided polygon. Fusion gives you a
true cylinder. Your solid will be **dimensionally identical and geometrically
better**, and re-exporting it will not produce the same triangles.

Two honest caveats:

- **`lip_h` 0.35 is a print-tuning knob, not fixed geometry.** It is expected to
  move once the leg has been printed and felt — see [TODO.md](../TODO.md).
  Reproduce it, then change it.
- **The cover is roughly three times the frame's work.** Twenty-odd features,
  and the pivot ears and their C-sockets are the hardest geometry in the build.
  Do the frame first.

### Before you start

1. **File → New Design.**
2. In the Browser (left panel), expand **Document Settings**, hover over the
   units, click the button that appears, and set **Millimeter**.
3. Run [`scripts/EinkStandSetup/`](scripts/EinkStandSetup/) — see
   [Start here](#start-here-run-the-script). You now have the parameters under
   **MODIFY → Change Parameters**, and eight translucent bodies named
   `KEEPOUT_*` sitting exactly where the electronics go.

Leave the keep-outs visible the whole way through. They are the check on every
cut you make: **plastic and a keep-out must never share space.**

### Make the offset planes first

Every cut starts at a known depth, so build all the planes up front and you will
not have to break out of sketching later. For each one:

**CONSTRUCT → Offset Plane** → click the **XZ plane** in the Browser (under
Origin) → type the distance → **OK**.

Make six: **1.4**, **2.65**, **4.65**, **21.1**, **22.45**, **22.6**.

Watch the preview. Y runs *back into the part*, away from the front face, and the
planes have to march back toward the keep-outs. If a plane jumps the wrong way,
put a minus sign in front of the number. Rename each one in the Browser to its
distance (double-click it) — you will be picking them by name.

### The repeating recipe

Steps 2 to 12 are all the same five moves. Once through it and the rest are
mechanical:

1. **CREATE → Create Sketch**, then click the plane the step names.
2. **CREATE → Rectangle → Center Rectangle.** Click anywhere near the right
   spot, then click again to make a rectangle. Do not try to be accurate — the
   dimensions come next.
3. Press **D** (Sketch Dimension) and add four dimensions: the rectangle's
   **width**, its **height**, and its centre point's **horizontal** and
   **vertical** distance from the origin point. Type the step's numbers in.
   Where a step gives **centre X of 0**, do not dimension it — select the
   rectangle's centre point and the origin point and apply a **Vertical
   constraint** instead. It is cleaner than a zero dimension and it cannot drift.
   The sketch turns black when it is fully constrained; that is the signal every
   dimension has landed.
4. If the step gives a corner radius: **CREATE → Sketch Fillet**, click the four
   corners, type the radius, Enter.
5. **FINISH SKETCH**, then **CREATE → Extrude** (shortcut **E**). Click inside
   the rectangle to select the profile, set **Distance**, and set **Operation**
   to **Cut**. If the preview cuts forward out of the part instead of back into
   it, put a minus in front of the distance.

The one thing to watch on every extrude is the **direction**. Y increases going
back into the part, so every cut but none of the chamfers travels that way.

### Step 1 — the outer body

Sketch on the **XZ plane** itself, not an offset plane.

| Centre X | Centre Z | Width | Height | Corner R |
|---|---|---|---|---|
| 0 | 55.25 | 91.9 (`W`) | 110.5 (`H`) | 5 (`corner_r`) |

Extrude **23.6** (`body_d`), Operation **New Body**. The result must sit with its
front face on Y 0 and its back face at Y 23.6, with the keep-outs inside it. If
it went the other way, flip the distance.

Check: the body should be 91.9 wide and 110.5 tall, with its bottom edge on Z 0
and the origin at the middle of that bottom edge.

### Steps 2 to 12 — the cuts, in order

Order matters: several of these rely on material a previous step left behind.

| # | Cut | Sketch on | Centre X | Centre Z | Width | Height | R | Distance |
|---|---|---|---|---|---|---|---|---|
| 2 | Window | XZ plane | 0 | 55.25 | 65.0 (`win_w`) | 87.4 (`win_h`) | 3 | 1.4 (`front_t`) |
| 3 | Glass pocket | Y 1.4 | −3.2 (`pan_px`) | 55.25 | 77.5 | 91.5 | 0.5 (`pan_r`) | 1.26 |
| 4 | Ribbon relief | Y 1.4 | −43.45 | 65.25 (`rib_cz`) | 3.0 (`rib_clr`) | 49.0 (`rib_w`) | — | 4.05 |
| 5 | PCB cavity | Y 2.65 | −1.65 (`cav_cx`) | 55.25 | 81.6 (`cav_w`) | 92.5 (`cav_h`) | 1.5 (`cav_r`) | 20.95 |
| 6a | Lightening, bottom −X | Y 4.65 | −25.05 | 4.75 | 24.8 | 4.5 | 1.5 | 18.95 |
| 6b | Lightening, bottom +X | Y 4.65 | 24.40 | 4.75 | 23.5 | 4.5 | 1.5 | 18.95 |
| 7 | Lightening, top | Y 4.65 | −1.65 | 105.75 | 73.6 | 4.5 | 1.5 | 18.95 |
| 8 | −X wall slot, lower | Y 21.1 | −43.15 | 23.25 | 1.6 | 10.0 | — | 2.1 |
| 9 | −X wall slot, upper | Y 21.1 | −43.15 | 87.25 | 1.6 | 10.0 | — | 2.1 |

**Step 6 is two pockets, not one, and the gap between them is the point.** The
bottom lightening pocket runs through the band the stand recess crosses, and the
recess's floor there is nothing but the cover's 1.0 mm register extension. Hollow
the frame out behind that plate and the plate is the only thing between an open
pocket on the outside of the case and the inside of the frame; leave x ±12.65
(`lgt_band`) solid and the frame backs it. Run it as one pocket and you have
deleted the backing.

**Step 10 must not reach the bottom edge.** It is the relief the cover's register
extension plugs, and it is `reg_fit` 0.15 larger than the plug all round, so a
0.15 gap runs round the plate. The rear chamfer has already taken 0.6
(`rear_chf − cover_t`) off this face at the bottom edge — so a relief that
reaches below z 0.6 puts that gap out in the chamfer, where it becomes a 21 mm
slot straight into the hollow end wall. It starts at z 1.75 and leaves 1.15 of
solid frame below it. Do not extend it "to be safe".

Steps 8 and 9 are what the **cover's two tongues hook into** — the cover carries
a 1.4 × 1.6 × 9 tongue at each of those positions, so the slot is 0.1 wider a
side and 0.5 longer at each end. Cut them undersize and the cover will not
close.
| 10 | Stand register relief | Y 22.45 | 0 | 5.73 | 21.3 | 7.95 | — | 1.15 |
| 11 | Cover register relief | Y 22.6 | −1.65 | 55.25 | 83.6 | 94.5 | 2.5 | 1.0 |
| 12 | Insert bores, ×4 | back face | ±40.45 (`scr_cx`) | 5.5 and 105.0 | Ø3.6 (`ins_d`) | — | — | 5.0 |

Steps 5, 6 and 7 all run to the back face, so instead of typing their distance
you can set the extrude's **Extent Type** to **All** and let it cut through
whatever is behind. It is the more robust choice — an exact-to-the-face distance
can leave a sliver if anything shifts later.

Four steps need something beyond the recipe:

**Step 3, the glass pocket, needs corner reliefs.** The glass has sharp corners
and a printed pocket cannot, so four circles of **R1.4** (`pan_rel`) sit centred
*on* the rectangle's corners — at X −41.95 and 35.55, Z 9.5 and 101.0. Draw them
in the same sketch with **CREATE → Circle → Center Diameter Circle**, then select
the rectangle *and* all four circles as the extrude profile. They cannot be moved
inboard; being centred on the corner is the whole function.

**Step 5, the cavity, carries the same four circles up.** Draw the same four
R1.4 circles at the same X and Z in the cavity's sketch too, or the interior wall
overhangs the pocket's reliefs by 0.9 mm.

**Step 12 uses the Hole tool, not an extrude.** **CREATE → Hole**, click the
**back face**, set **Simple**, diameter **3.6**, depth **5.0**
(`ins_l + ins_relief`), and place four of them at X ±40.45, Z 5.5 and 105.0. Then
put a **0.4** chamfer on each bore's mouth so the insert starts square.

**Steps 10 and 11 are shallow reliefs at the back**, not through-cuts. They make
room for the cover's register plate, which stands 1.0 (`reg_step`) proud of the
cover's skin.


### Step 13 — the three edge breaks, last

Chamfers go last, the way Fusion prefers. **MODIFY → Chamfer**, click the edge,
type the distance.

| Edge | Size |
|---|---|
| Outer edge of the **front** face | 0.8 (`front_chf`) |
| **Window** edge on the front face | 0.9 (`win_chf`) |
| Outer edge of the **back** face | **0.6** — see below |

**The rear chamfer is 0.6 on the frame, not `rear_chf` 2.0.** The 2.0 chamfer
belongs to the assembled device, and the frame only carries the first slice of
it: the cover sits behind the frame and finishes the rest. Measured off the
exported frame, the outer profile is full width at Y 23.0 and inset 0.59 at the
back face — a 0.6 chamfer. Put 2.0 in and you will eat 1.4 mm into walls that
are 2.2 mm thick.

### Three things the model documents but does not cut

Do not model these — they are described in the sources but disabled in this
build: the **tape pads** (`tape_r` works out to 0, so the ledge is too narrow for
them), the **USB pocket** (the driver's jack lands in the middle of the interior,
with no wall to cut), and the **side buttons** (`btn_n` is 0).

### The trap: the window and the pocket are not concentric

Step 2 centres the window at **X 0**. Step 3 centres the glass pocket at
**X −3.2**. That is deliberate and it is the single easiest thing to get wrong
here: the ink is off-centre on the glass by 3.2 (`act_off_x`), and it is the
*ink* that has to look centred in the window. Build them off the same centreline
and the white border comes out lopsided — 0.7 mm one side and 1.3 the other is
the target, and it is asymmetric on purpose.

### Checking the result

Three checks, cheapest first:

1. **The keep-outs.** Nothing you cut should ever leave plastic inside one. Hide
   your frame body and confirm all eight `KEEPOUT_*` bodies are still whole.
2. **A DXF overlay.** **INSERT → Insert DXF**, pick the plane, choose the file,
   set units to **millimeter**, and leave *Combine to a single sketch* checked.
   Put [`pocket.dxf`](dxf/pocket.dxf) on the Y 1.4 plane and
   [`cavity.dxf`](dxf/cavity.dxf) on the Y 2.65 plane; the imported outlines
   should land on your cut edges. Remember a section shows **material**, so your
   pockets appear as voids inside the outline.
3. **The mesh.** Insert [`mesh/frame.stl`](mesh/frame.stl) and look for
   daylight between it and your solid.

## Building the cover

Three times the frame's work, and the last three steps are the hardest geometry
in the build. Same origin, same recipe — sketch on an offset plane from XZ, then
extrude. The difference is that the cover **adds** as much as it cuts, so watch
the **Operation** field: it is **Join** for the first group and **Cut** for the
second.

Its outline is 90.7 × 109.3, not the frame's 91.9 × 110.5. The whole cover lives
inside the assembled device's 2.0 rear chamfer, so unlike the frame — which only
catches the first 0.6 of it — the chamfer trims the cover through its entire
1.4 thickness.

### What it adds — Operation: Join

Start with C1, then Join the rest onto it.

| # | Feature | Centre X | Centre Z | Width | Height | R | Y from | Y to |
|---|---|---|---|---|---|---|---|---|
| C1 | Register plate | −1.65 | 55.25 | 83.3 | 94.2 | 2.5 | 22.6 | 25.0 |
| C2 | Outer skin | 0 | 55.25 | 91.9 | 110.5 | 5 | 23.6 | 25.0 |
| C3 | Recess boss | 0 | 36.5 | 21.0 | 54.0 | — | 18.7 | 25.0 |
| C4 | Stand register extension | 0 | 5.73 | 21.0 | 7.65 | — | 22.6 | 23.6 |
| C5 | Glass rib, bottom, ×2 | ±17.5 | 11.75 | 15.0 | 3.5 | — | 2.90 | 23.6 |
| C6 | Glass rib, top | −11.0 | 98.75 | 20.0 | 3.5 | — | 2.90 | 23.6 |
| C7a | Carrier pads, ×4 | −39.45 and −13.45 | 16.5 and 82.5 | Ø4.0 | — | — | 20.1 | 22.6 |
| C7b | Carrier pegs, ×4 | −39.45 and −13.45 | 16.5 and 82.5 | Ø1.85 | — | — | 17.3 | 22.6 |
| C8 | Charger posts, ×4 | 9.65 and 34.65 | 73.35 and 92.65 | Ø6.5 | — | — | 18.8 | 23.6 |
| C9 | Battery platform | 14.35 | 42.55 | 47.6 | 50.6 | — | 18.7 | 23.6 |
| C10 | Battery fences, ×2 | −8.95 and 37.65 | 42.55 | 1.0 | 35.0 | — | 11.8 | 18.7 |
| C11 | Tongues, ×2 | −43.15 | 23.25 and 87.25 | 1.4 | 9.0 | — | 21.2 | 22.8 |

**C7 is a pad carrying a peg, and both matter.** The pad holds the carrier 2.5
(`carrier_lift`) off the register face, which is the air the header solder joints
on the board's underside need; the peg rises from the top of that pad, through
the board's hole, and locates it. The first header pin is only 2.0 from each
hole, so neither may exceed Ø4.0 across.

**C8 takes an M2 heat-set insert**, which is what makes it a post and not a pad:
bore each one **Ø2.9 × 5.0 deep** from its top face (Y 18.8) toward the back
face, so it stops at Y 23.8 and leaves 1.2 (`chg_skin`) of skin. It is a blind
bore — the back face carries no opening for the charger. The centres are
**assumed**: measure the breakout before you commit to them.

**C3 is the reason the stand pocket is a pocket.** The cover's own skin is only
1.4 thick and the pocket is 4.5 deep, so without this boss behind it the cut goes
straight through the back face. Build it before you cut the pocket.

**C5 splits into two segments and C6 does not.** The bottom glass rib crosses the
stand pocket. Run straight through, the pocket takes its root out and leaves the
middle cantilevered off one end — and it is the rib that holds the glass down.
So the bottom one is two 15 mm segments outboard of the pocket, and the top one,
clear of the pocket, is a single 20 mm pad.

**C11 are the tongues** that hook into the frame's steps 8 and 9.

### What it cuts — Operation: Cut

| # | Cut | Centre X | Centre Z | Width | Height | Y from | Y to |
|---|---|---|---|---|---|---|---|
| C12 | Stand pocket, deep | 0 | 36.5 | 18.0 | 54.0 | 20.5 | 25.0 |
| C13 | Stand pocket, shallow | 0 | 6.0 | 18.0 | 7.0 | 23.6 | 25.0 |
| C14 | Pigtail clearance | −5.0 | 92.0 | 15.5 | 6.0 | 13.6 | 23.8 |
| C15 | Port opening | −5.0 | 92.0 | 14.3 | 4.8, R0.6 | 23.5 | 25.0 |
| C16 | Screw holes, ×4 | ±40.45 | 5.5 and 105.0 | Ø2.9 | — | 23.5 | 25.0 |

**The pocket floor stays flat.** Nothing is cut into it: the leg swings free
between its two poses, so there is no seat and no track, and the floor is a plain
face 1.8 (`rec_floor`) thick the whole deep length.

Then three things that are not rectangles.

**The latch lip — put material back.** After C12 and C13, **Join** a block
spanning X ±9, Z 4.7 to 6.3, Y 24.65 to 25.0. It bridges the mouth of the pocket
near the foot; the leg's tip tucks under it, and releasing only asks the leg to
bow 0.35 (`lip_h`) over its whole length.

**The countersinks.** Each screw hole needs a 90° countersink opening at the
**back** face: Ø2.9 widening to Ø5.0 (`scr_head`) over 1.05 (`scr_csk`), so from
Y 23.95 to 25.0. The Hole tool will do the bore and the countersink in one go —
pick **Countersink**, and set the countersink diameter to 5.0.

**The rear chamfer** is **1.4** here, at 45° on the outer edge, running the
cover's full thickness. Not 0.6 like the frame, and not 2.0.

### The pivot ears and their sockets — last, and in this order

The ears stand **inside** the pocket, so they have to go back on **after** the
pocket is cut, and the sockets have to be bored **after** the ears exist. Get the
order wrong and the pocket erases the ears, or the socket bores fresh air.

1. **Join two ear blocks.** Each is 2.0 (`ear_w`) wide, from the pocket floor to
   the back face — Y 20.5 to 25.0 — and 8.0 (`ear_len`) long centred on the pin:
   Z 54 to 62. One at X 7 to 9, one at X −9 to −7.
2. **Cut a Ø2.1 bore** through each ear, along X, centred at Y 23, Z 58. That is
   `pin_d` 2.0 plus `pin_fit` 0.1.
3. **Cut the C-mouth.** A slot 1.51 wide (`ear_mouth` 0.72 of the bore) running
   from the bore straight out to the back face: through each ear in X, Y 22.24 to
   25.0, Z 57.24 to 58.76.

The mouth is narrower than the bore, so the pin presses past the lip and is then
retained. It opens **into the pocket**, not through the back face — which is what
keeps the back face unbroken. Bored outward through the pocket walls instead, each
socket could only be reached from outside, and that is two more openings in a face
that should have none.

## Building the leg

Small, and the only moving part. Work in **leg-local coordinates**: put the pin
at the origin, the body running along **−Z** toward the foot, thickness in **Y**,
width in **X**. At the folded angle this frame is the world frame, so it drops
straight into place with `translate([0, 23, 58])` — Y `piv_y`, Z `piv_z`.

Build it as its own component and position it last.

1. **The plan outline.** Sketch on the XZ plane: a 13 wide (`leg_w`) shape running
   from Z +5 down to Z −55 (`leg_len`), with the foot end rounded to R4
   (`foot_r`). Two circles of R4 at (±2.5, −51) hulled to a rectangle spanning
   Z 0 to 5 is how the model draws it; in Fusion, a 13 × 60 rectangle with the
   two bottom corners filleted R4 is the same shape.
2. **The body, with a one-sided taper.** This is the step
   [`leg_side.dxf`](dxf/leg_side.dxf) looks like it should give you and does not.
   **Loft** through three sections, all 13 wide:
   - at Z 0 and again at Z −41 (`piv_z − tap_z`): 4.0 thick (`leg_t`), Y −2 to +2
   - at Z −48.5 (`piv_z − shl_z0`): 1.0 thick (`leg_tf`), Y **+1 to +2**

   The back face stays at Y +2 the whole way; only the front face rises. That is
   what lets the folded leg sit flush while the thin end still fits the shallow
   part of the pocket. Then extrude the tip section — 13 × 1.0, Y +1 to +2 — from
   Z −48.5 down to Z −55.
3. **The heel.** Join a block 13 × 4.0 (`heel_z`), Y −2 to +2, from Z 0 to Z +4.
4. **The stop flat.** Cut everything below a plane that sits at **Y −2.5**
   (`−piv_h`) **when rotated −35° about X** (`dep_ang`). Make a construction plane
   at Y −2.5, rotate it −35° about the X axis through the origin, and cut
   everything on its far side.

   That flat is the whole stand. Deployed, the display's weight pushes the leg
   further open, the flat lands on the recess floor, and the load runs leg → heel
   → cover in compression. It is not friction and it is not a spring.
5. **The pin bore.** Ø2.1 through the width at the origin.

Print it with supports: the heel's stop flat is a 35° overhang. It is the only
part in the build that needs them.

## What the DXFs are for, then

Now that the parts are built from numbers, the sketch profiles have one job:
checking. [`side.dxf`](dxf/side.dxf) is a centreline section through frame and
cover together, so it is the fastest way to see whether your depths agree.
[`layout.dxf`](dxf/layout.dxf) shows where the electronics land.
[`pocket.dxf`](dxf/pocket.dxf), [`cavity.dxf`](dxf/cavity.dxf),
[`cover_in.dxf`](dxf/cover_in.dxf) and the two silhouettes each match a cut you
have already made.

## Reference meshes

[`mesh/`](mesh/) holds the current parts in model orientation, each written
twice: **`.stl`, which is on Personal's format list**, and `.3mf`, which is
smaller and keeps `keepouts` as eight separate volumes. Insert them to compare a
Fusion rebuild against what the slicer is getting today — and check the extents,
which are the fastest way to know an import landed right.

| File | X | Y | Z | Triangles |
|---|---|---|---|---|
| [`mesh/frame.stl`](mesh/frame.stl) | −45.95 … 45.95 | 0 … 23.60 | 0 … 110.50 | 4176 |
| [`mesh/cover.stl`](mesh/cover.stl) | −45.36 … 45.36 | 2.90 … 25.00 | 0.50 … 109.91 | 4268 |
| [`mesh/leg.stl`](mesh/leg.stl) | −6.50 … 6.50 | 20.15 … 25.00 | 3.00 … 62.00 | 626 |
| [`mesh/keepouts.stl`](mesh/keepouts.stl) | −44.95 … 38.15 | 1.40 … 23.60 | 10.25 … 100.25 | 96 |

The leg is folded, in its fitted position. The cover reaches forward to Y 2.90
because its glass ribs do, and stops 0.59 short of the frame's outline all
round because the rear chamfer trims it — the same reason `cover_back.dxf` is
90.72 wide.

**There is no STEP of the frame, cover or leg, and there cannot be.** OpenSCAD
exports meshes only, so nothing in this folder is a solid body to open and edit
— which is why the hand-off is parameters, keep-outs and sketch profiles rather
than a model to take over. The meshes are for looking at and measuring against;
the frame alone is 4176 facets, and Fusion's mesh-to-solid conversion will not
give anything worth modelling on.

The print-orientation exports the slicer uses stay in [`../stl/`](../stl/).

## Vendor CAD

[`vendor/SOURCES.md`](vendor/SOURCES.md) lists every component, its measured
size, and every drawing, datasheet and solid model published for it.

Checked in, ready to insert:

- `adafruit-6091-bq25185-charger.f3d` — the charger, as a Fusion archive. Use
  this in preference to the STEP; it comes in as a proper component tree.
- `adafruit-6091-bq25185-charger.step` — the same part. Upload whichever one
  you prefer, not both: on Personal each is an active document.
- `adafruit-1608-perma-proto-quarter.step` — the driver carrier is a 30 × 70
  cut of the same 0.1 inch double-sided stock, so this is the closest published
  model of that board.

`sh vendor/fetch-vendor.sh` pulls the rest into `vendor/downloaded/`: the
panel's specification with its mechanical drawing, the driver board's Rev 3
drawing, schematic and manual, the official Espressif ESP32-WROOM-32E STEP, and
the TI bq25185 datasheet. They are vendor documents, so they stay out of the
repo and `SOURCES.md` is the durable record of where they came from.

Two parts have no published model anywhere: the raw e-paper panel and the FPC
adapter. Their keep-outs are measured off the parts in hand.

## What the rebuild still needs measured

Carried over from [`../TODO.md`](../TODO.md), the open numbers that a Fusion
model will want:

- the female header row spacing on the driver board, which decides where the
  headers get soldered to the carrier
- the heat-set inserts actually in the parts box, against the assumed
  Ø3.6 × 5.0 bore
- the second FPC's length, adapter to driver board — long enough for the cover
  to come off and sit beside the frame
- confirmation of the 16.0 driver stack before the frame is committed
