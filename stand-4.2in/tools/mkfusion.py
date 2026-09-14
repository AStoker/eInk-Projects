#!/usr/bin/env python3
"""Generate the Fusion hand-off files from the model's own parameter dump.

Reads /tmp/params.txt (the `part="params"` echo, same source mkdrawings.py uses)
and src/epaper_stand.scad, and writes:

    fusion/parameters.csv           user parameters - the INPUTS, one row each
    fusion/reference-dimensions.csv every value the model carries or derives
    fusion/keepouts.csv             component envelopes as min/max XYZ
    fusion/scripts/EinkStandSetup/    Fusion script: the parameters + the
                                      keep-out bodies, in one run

Run it through tools/mkfusion.sh, which produces params.txt first.

The split between the two CSVs is the point.  parameters.csv holds only values
that were measured or chosen - nothing in it is computed from anything else in
it, so every row is a number to type in and then own.  reference-dimensions.csv
holds what the OpenSCAD model works out from those: W and H, the cavity, the
board positions, the lean.  Those are answers, not inputs, and a Fusion rebuild
should arrive at them from its own sketches and constraints - the file is there
to check against, which is why it is named for reference and not for import.
"""

import os, re, sys

HERE  = os.path.dirname(os.path.abspath(__file__))
ROOT  = os.path.dirname(HERE)
SCAD  = os.path.join(ROOT, "src", "epaper_stand.scad")
OUT   = os.path.join(ROOT, "fusion")
PARAMS = sys.argv[1] if len(sys.argv) > 1 else "/tmp/params.txt"


# ----------------------------------------------------------------- the dump
def read_params(path):
    d = {}
    with open(path) as f:
        for line in f:
            if "=" not in line:
                continue
            k, v = line.rstrip("\n").split("=", 1)
            try:
                d[k] = float(v)
            except ValueError:
                d[k] = v
    return d


def read_scad_inputs(path):
    """Top-level `name = <bare number>;` assignments, with their comment.

    A bare number on the right-hand side is exactly what makes something an
    input: everything derived in this model is an expression.  So the filter is
    the definition, not a heuristic - and a value that stops being an input
    drops out of the CSV by itself.

    The comment is whichever the source actually attaches: a trailing // on the
    assignment line plus any indented // lines that continue it, or failing
    that the whole comment block immediately above.  Both matter - the model
    writes some notes one way and some the other, and half a sentence is worse
    than none.
    """
    lines = open(path).read().split("\n")
    inputs, depth, block = {}, 0, []
    ASSIGN = re.compile(r"(?:^|;)\s*([A-Za-z_]\w*)\s*=\s*"
                        r"(-?\d+(?:\.\d+)?)\s*(?=;)")

    def is_comment(s):
        return s.lstrip().startswith("//")

    for i, raw in enumerate(lines):
        code = raw.split("//")[0]
        top = depth == 0

        if top and is_comment(raw):
            txt = raw.lstrip().lstrip("/").strip()
            if txt and not txt.startswith("=="):
                block.append(txt)
        elif top and ASSIGN.search(code):
            note = raw.split("//", 1)[1].strip() if "//" in raw else ""
            if note:
                # ... plus the indented comment-only lines that continue it
                for nxt in lines[i + 1:]:
                    if is_comment(nxt) and nxt[:1] in " \t":
                        note += " " + nxt.lstrip().lstrip("/").strip()
                    else:
                        break
            else:
                note = " ".join(block)
            note = clean_note(note)
            for m in ASSIGN.finditer(code):
                inputs[m.group(1)] = (float(m.group(2)), note)
            block = []
        elif not is_comment(raw) and raw.strip():
            block = []

        depth += code.count("{") - code.count("}")
    return inputs


def clean_note(note, limit=200):
    note = re.sub(r"\s+", " ", note.replace('"', "'")).strip(" -")
    if len(note) <= limit:
        return note
    cut = note[:limit].rsplit(" ", 1)[0]
    return cut.rstrip(",.;") + " ..."


# ------------------------------------------------------------ what to export
# Inputs, grouped the way the .scad groups them.  Anything in the .scad that is
# not listed here is either derived, or belongs to a variant that is not fitted
# (the module-PCB panel, the Perma-Proto, the mated 8-pin header, side buttons,
# the flash port), or is a leftover from a superseded scheme.
GROUPS = [
    ("Panel - measured on the part", [
        "pan_w", "pan_h", "pan_t", "act_w", "act_h", "bez_thin",
    ]),
    ("Glass pocket", [
        "pan_clr_w", "pan_clr_h", "pan_r", "pan_rel",
    ]),
    ("Ribbon route - measured looking at the rear face", [
        "rib_exit", "rib_out", "rib_band", "rib_run", "rib_leg3", "rib_marg",
        "rib_clr", "rib_dep", "rib_tail", "wall_rib",
    ]),
    ("Body", [
        "depth", "front_t", "cover_t", "wall", "corner_r", "cav_r",
        "front_chf", "win_chf", "rear_chf",
        "white_show_short", "white_show_long", "reg_step",
    ]),
    ("Fixings - M2.5 countersunk into heat-set inserts", [
        "ins_d", "ins_l", "ins_relief", "scr_free", "scr_head",
    ]),
    ("Glass retention - tape pads and the cover's glass ribs", [
        "tape_len", "tape_reach", "tape_dep", "rib_gap",
        "rib_pocket_c", "rib_seg",
    ]),
    ("Electronics - driver board", [
        "drv_w", "drv_h", "drv_t", "drv_env", "drv_stack", "fpc_off", "drv_clr",
    ]),
    ("Electronics - driver carrier", [
        "carrier_w", "carrier_h", "carrier_t", "hdr_h",
        "carrier_hole", "carrier_hx", "carrier_hz", "carrier_peg", "carrier_pin",
    ]),
    ("Electronics - FPC adapter", [
        "adapt_w", "adapt_h", "adapt_env",
    ]),
    ("Electronics - charger, cell and port", [
        "chg_w", "chg_h", "chg_t",
        "bat_w", "bat_h", "bat_t", "bat_clr", "bat_fence",
        "elec_clr", "col_gap",
    ]),
    ("Kickstand", [
        "dep_ang", "leg_len", "foot_z", "leg_t", "leg_tf", "foot_r", "heel_z",
        "pin_d", "pin_fit", "rec_dep", "rec_shl", "rec_w", "rec_clr",
        "rec_wall", "rec_floor",
        "det_tot", "det_iw", "det_seat", "nub_pre", "nub_r", "nub_root",
        "lip_h", "lip_z", "lip_w", "ear_w", "ear_mouth", "ear_len",
    ]),
    ("Measured, but not driving geometry in the OpenSCAD model", [
        "fpc_w", "adapt_t", "adapt_hole", "adapt_inset", "carrier_pad", "usb_w",
    ]),
]

DEG      = {"dep_ang"}
UNITLESS = {"ear_mouth"}          # a fraction of the bore, not a length

# Notes for values the source states without a comment, or states in terms of a
# scheme that has since changed.  Written here rather than in the .scad so the
# model's own commentary stays the model's.
NOTES = {
    "act_w":   "active ink area across the SHORT axis, 400 x 300 px",
    "act_h":   "active ink area along the LONG axis",
    "depth":   "outer depth, front face to back face",
    "front_t": "front shell thickness, ahead of the glass pocket",
    "cover_t": "cover skin thickness",
    "wall":    "side wall around the PCB cavity",
    "corner_r": "outer corner radius, seen from the front",
    "cav_r":   "PCB cavity corner radius. Under 1.707 so a sharp corner seats "
               "without a relief",
    "front_chf": "45 deg edge break on the front face",
    "win_chf":   "45 deg edge break around the window",
    "rear_chf":  "45 deg edge break on the back face. foot_z has to clear it",
    "rib_gap":   "how far the cover's glass ribs stop short of the panel's back "
                 "face",
    "carrier_w": "driver carrier: a 30 x 70 cut of 0.1in double-sided prototype "
                 "board",
    "carrier_h": "driver carrier, along the long axis. ~14 mm of it is spare "
                 "board below the driver, for the battery divider",
    "carrier_t": "carrier board thickness",
    "adapt_w":   "Waveshare FPC adapter outline, measured",
    "adapt_h":   "Waveshare FPC adapter outline, measured",
    "adapt_t":   "adapter PCB alone. adapt_env is the figure that decides fit",
    "bat_clr":   "clearance around the cell, per side",
    "bat_fence": "fence rib thickness either side of the cell",
    "drv_clr":   "clearance between the driver board's edge and its rails",
    "fpc_w":     "the driver's 24-pin FPC socket body, along the board edge",
    "carrier_pad": "standoff pad diameter under each carrier corner - the pads "
                   "became locating pegs, so this no longer sets anything",
    "usb_w":     "flash-port opening width. flash_port = false, so the port is "
                 "not cut",
    "adapt_hole":  "ASSUMED M2 clearance. The adapter is taped to the glass, so "
                   "nothing is bored for it - measure only if that changes",
    "adapt_inset": "ASSUMED hole inset from each edge. Unused while the adapter "
                   "is taped",
}

# Values the .scad picks with a conditional, so they are not bare numbers in the
# source but are still numbers you choose.  Taken from the dump.
FROM_DUMP = {
    "ins_d":     'heat-set insert bore. insert_size = "M2.5"; MEASURE YOURS',
    "ins_l":     "insert length",
    "scr_free":  "screw clearance hole",
    "scr_head":  "countersunk head diameter, 90 deg",
    "chg_w":     'charger breakout. chg_part = "bq25185" (Adafruit 6091)',
    "chg_h":     "charger breakout",
    "reg_step":  "cover register stands this far forward of the skin datum",
    "elec_clr":  "clearance between a board and the cavity wall",
    "col_gap":   "gap between the two board columns",
}


def csv_row(*fields):
    """Every field quoted.  Parameter I/O drops the first parameter if the
    fields are not quoted, so this is not cosmetic."""
    return ",".join('"%s"' % str(f).replace('"', "'") for f in fields)


def fmt(v):
    s = "%.4f" % v
    s = s.rstrip("0").rstrip(".")
    return s or "0"


def build_rows(inputs, P):
    rows, missing = [], []
    for title, names in GROUPS:
        rows.append(("#", title))
        for n in names:
            if n in inputs:
                val, note = inputs[n]
            elif n in P and isinstance(P[n], float):
                val, note = P[n], FROM_DUMP.get(n, "")
            else:
                missing.append(n)
                continue
            if n in FROM_DUMP:
                note = FROM_DUMP[n]
            if n in NOTES and not note:
                note = NOTES[n]
            elif n in NOTES and n in ("adapt_t", "carrier_pad", "usb_w",
                                      "adapt_hole", "adapt_inset", "fpc_w"):
                note = NOTES[n]
            unit = "deg" if n in DEG else ("" if n in UNITLESS else "mm")
            rows.append((n, unit, fmt(val), clean_note(note)))
    return rows, missing


# --------------------------------------------------------------- keep-outs
def build_keepouts(P):
    """Every envelope the electronics claim, as (name, x0,x1, y0,y1, z0,z1).

    Axes are the model's: X short (0 = centre), Y depth (0 = outer front face),
    Z long (0 = bottom edge).  Same origin as the meshes and the DXF sketches.
    """
    p = P
    def box(name, cx, sx, y0, dy, cz, sz, note):
        return (name, cx - sx / 2, cx + sx / 2, y0, y0 + dy, cz - sz / 2,
                cz + sz / 2, note)

    k = [
        box("PANEL_GLASS", p["pan_px"], p["pan_w"], p["front_t"] + 0.15,
            p["pan_t"], p["Zc"] + p["pan_off_z"], p["pan_h"],
            "bare glass, 76 x 90 sharp corners, measured"),
        box("FPC_HOLLOW",
            p["pan_px"] - (p["pan_w"] + 2 * p["pan_clr_w"]) / 2 - p["rib_clr"] / 2,
            p["rib_clr"], p["front_t"], p["pan_t"] + p["rib_dep"],
            p["rib_cz"], p["rib_w"],
            "the ribbon's 180 deg fold. Oversized on purpose"),
        box("DRIVER_BOARD", p["drv_cx"], p["drv_w"], p["drv_back"] - p["drv_env"],
            p["drv_env"], p["drv_cz"], p["drv_h"],
            "Waveshare e-Paper ESP32 Driver Board Rev 3, full component envelope"),
        box("DRIVER_CARRIER", p["carrier_cx"], p["carrier_w"], p["carrier_face"],
            p["carrier_t"], p["carrier_cz"], p["carrier_h"],
            "0.1in perfboard, 30 x 70, four dia 2.0 holes at 26 x 66 centres"),
        box("FPC_ADAPTER", p["adapt_cx"], p["adapt_w"], p["mod_back"],
            p["adapt_env"], p["adapt_cz"], p["adapt_h"],
            "Waveshare FPC adapter, taped to the back of the glass"),
        box("CHARGER", p["chg_x_c"], p["chg_w"], p["chg_back"] - p["chg_t"],
            p["chg_t"], p["chg_z"], p["chg_h"],
            "Adafruit bq25185 (6091), board + USB-C jack"),
        box("CELL", p["bat_cx"], p["bat_w"], p["rec_back"] - p["bat_t"],
            p["bat_t"], p["bat_cz"], p["bat_h"],
            "2000 mAh LiPo, 694449 pouch. Squared off - the real pouch has R2 corners"),
        box("USB_C_PIGTAIL", p["ucb_x"], p["snap_w"], p["cov_in"] - p["snap_d"],
            p["snap_d"], p["ucb_z"], p["snap_h"],
            "snap-in rear port, two wires, no data"),
    ]
    if not p.get("carrier_fit"):
        k = [b for b in k if b[0] != "DRIVER_CARRIER"]
    if not p.get("adapt_fit"):
        k = [b for b in k if b[0] != "FPC_ADAPTER"]
    if not p.get("port_snap"):
        k = [b for b in k if b[0] != "USB_C_PIGTAIL"]
    return k


# ------------------------------------------------------------------- output
def main():
    P = read_params(PARAMS)
    inputs = read_scad_inputs(SCAD)
    rows, missing = build_rows(inputs, P)
    keep = build_keepouts(P)

    script_dir = os.path.join(OUT, "scripts", "EinkStandSetup")
    os.makedirs(script_dir, exist_ok=True)

    # ---- parameters.csv
    with open(os.path.join(OUT, "parameters.csv"), "w") as f:
        f.write('"# 4.2in e-Paper desk frame - model inputs","","",'
                '"generated by tools/mkfusion.py from src/epaper_stand.scad'
                ' - do not hand-edit"\n')
        for r in rows:
            if r[0] == "#":
                f.write(csv_row("# " + r[1], "", "", "") + "\n")
            else:
                f.write(csv_row(*r) + "\n")

    # ---- reference-dimensions.csv
    with open(os.path.join(OUT, "reference-dimensions.csv"), "w") as f:
        f.write("name,value,unit\n")
        for k in sorted(P):
            v = P[k]
            unit = "" if isinstance(v, str) else (
                "deg" if k in ("dep_ang", "lean") else "mm")
            f.write("%s,%s,%s\n" % (k, fmt(v) if isinstance(v, float) else v, unit))

    # ---- keepouts.csv
    with open(os.path.join(OUT, "keepouts.csv"), "w") as f:
        f.write("name,x_min,x_max,y_min,y_max,z_min,z_max,"
                "x_size,y_size,z_size,note\n")
        for n, x0, x1, y0, y1, z0, z1, note in keep:
            f.write(",".join([n] + [fmt(v) for v in
                    (x0, x1, y0, y1, z0, z1, x1 - x0, y1 - y0, z1 - z0)] +
                    ['"%s"' % note]) + "\n")

    # ---- the Fusion script
    write_fusion_script(os.path.join(script_dir, "EinkStandSetup.py"),
                        rows, keep, P)
    # Fusion finds a script by folder: <name>/<name>.py alongside <name>.manifest
    with open(os.path.join(script_dir, "EinkStandSetup.manifest"), "w") as f:
        f.write(MANIFEST)

    print("fusion/parameters.csv          %d parameters"
          % len([r for r in rows if r[0] != "#"]))
    print("fusion/reference-dimensions.csv %d values" % len(P))
    print("fusion/keepouts.csv            %d envelopes" % len(keep))
    print("fusion/scripts/EinkStandSetup/")
    if missing:
        print("NOT FOUND in the model, left out: " + ", ".join(missing))


MANIFEST = """{
    "autodeskProduct": "Fusion",
    "type": "script",
    "author": "generated by tools/mkfusion.py",
    "description": {
        "": "Create the 4.2in e-Paper desk frame's model parameters and its component keep-out bodies."
    },
    "supportedOS": "windows|mac",
    "editEnabled": true
}
"""

FUSION_TEMPLATE = '''"""Set up an Autodesk Fusion design for the 4.2" e-Paper desk frame.

GENERATED by tools/mkfusion.py from src/epaper_stand.scad.  Re-run
tools/mkfusion.sh after any parameter change rather than editing this file.

Run it from Fusion: Utilities > ADD-INS > Scripts and Add-Ins > Scripts > the
green + > pick this EinkStandSetup folder > Run.  Scripts are available on the
Personal licence, and nothing here needs a capability Personal restricts.  It
is safe to run twice: a parameter that already exists is updated, and the
keep-out component is rebuilt from scratch.

If it stops, it says which of the two stages it stopped on.  Neither is
load-bearing - fusion/parameters.csv and fusion/keepouts.csv carry the same
numbers, and eight boxes placed by hand from the CSV take about five minutes.

It does two things.

1. Creates the model's INPUT parameters as Fusion user parameters, with the
   comment each one carries in the OpenSCAD source.  These are the measured
   and chosen numbers; everything else in the OpenSCAD model is worked out
   from them, and fusion/reference-dimensions.csv has those answers to check a
   rebuild against.

2. Builds one body per component envelope, named KEEPOUT_<part>, in the
   root component, at the position the layout puts it.  Axes are the model's:
   X = short axis (0 = centre), Y = depth (0 = outer front face), Z = long
   axis (0 = bottom edge).  Those are the same axes the DXF sketches and the
   reference meshes in fusion/ use, so everything lands on one origin.

   The bodies are reference geometry, not parts.  Model the frame and cover
   around them; if plastic and a keep-out ever share space, the plastic is
   wrong.  Two are deliberately generous rather than tight: DRIVER_BOARD is
   the whole %(drv_stack)s mm measured stack - board, sockets and carrier - and
   FPC_HOLLOW is sized for a 180 degree fold that has to have somewhere to go,
   not for the ribbon's own width.
"""

import adsk.core, adsk.fusion, traceback

# name, unit, expression, comment
PARAMETERS = [
%(parameters)s]

# name, x_min, x_max, y_min, y_max, z_min, z_max, note   (millimetres)
KEEPOUTS = [
%(keepouts)s]

KEEPOUT_PREFIX = "KEEPOUT_"          # what groups them, and what a re-run finds
BASE_FEATURE_NAME = "KEEPOUT_bodies"
MM = 0.1   # Fusion's internal length unit is the centimetre


def set_parameters(design):
    params = design.userParameters
    made = updated = 0
    for name, unit, expression, comment in PARAMETERS:
        existing = params.itemByName(name)
        if existing:
            existing.expression = expression
            existing.comment = comment
            updated += 1
        else:
            params.add(name, adsk.core.ValueInput.createByString(expression),
                       unit, comment)
            made += 1
    return made, updated


def snapshot(collection):
    """A plain list, so deleting as we go cannot disturb the iteration."""
    return [collection.item(i) for i in range(collection.count)]


def clear_keepouts(root):
    """Take out whatever a previous run left.

    Deleting the base feature takes its bodies with it; the loop over loose
    bodies afterwards catches a run that was interrupted part way through, and
    the occurrence loop catches designs set up by an earlier version of this
    script, which put the keep-outs in a component of their own.
    """
    for feature in snapshot(root.features.baseFeatures):
        if feature.name.startswith(BASE_FEATURE_NAME):
            feature.deleteMe()
    for body in snapshot(root.bRepBodies):
        if body.name.startswith(KEEPOUT_PREFIX):
            body.deleteMe()
    for occurrence in snapshot(root.occurrences):
        if occurrence.component.name.startswith("KEEPOUT"):
            occurrence.deleteMe()


def build_keepouts(design, root):
    """One body per component envelope, in the ROOT component.

    Not in a component of their own, which is what this script used to do: a
    Part Design document may hold only one component, so addNewComponent fails
    outright there, and these have to work in a part as much as in an assembly.
    The KEEPOUT_ prefix does the grouping instead - it sorts them together in
    the Browser, and it is what clear_keepouts looks for on a re-run.
    """
    clear_keepouts(root)

    temp = adsk.fusion.TemporaryBRepManager.get()
    # A parametric design needs the bodies wrapped in a base feature; a direct
    # modelling design takes them straight.
    direct = design.designType == adsk.fusion.DesignTypes.DirectDesignType
    base = None if direct else root.features.baseFeatures.add()
    if base:
        base.name = BASE_FEATURE_NAME
        base.startEdit()
    try:
        for name, x0, x1, y0, y1, z0, z1, note in KEEPOUTS:
            centre = adsk.core.Point3D.create((x0 + x1) / 2 * MM,
                                              (y0 + y1) / 2 * MM,
                                              (z0 + z1) / 2 * MM)
            obb = adsk.core.OrientedBoundingBox3D.create(
                centre,
                adsk.core.Vector3D.create(1, 0, 0),
                adsk.core.Vector3D.create(0, 1, 0),
                (x1 - x0) * MM, (y1 - y0) * MM, (z1 - z0) * MM)
            solid = temp.createBox(obb)
            if base:
                body = root.bRepBodies.add(solid, base)
            else:
                body = root.bRepBodies.add(solid)
            body.name = KEEPOUT_PREFIX + name
    finally:
        if base:
            base.finishEdit()

    # Opacity after the edit is closed, so it survives it.
    for body in snapshot(root.bRepBodies):
        if body.name.startswith(KEEPOUT_PREFIX):
            try:
                body.opacity = 0.45
            except Exception:
                pass
    return len(KEEPOUTS)


def run(context):
    ui = None
    stage = "starting up"
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface
        design = adsk.fusion.Design.cast(app.activeProduct)
        if not design:
            ui.messageBox("Open a Fusion design first, then run this again.")
            return

        stage = "setting the document to millimetres"
        if design.unitsManager.defaultLengthUnits != "mm":
            design.unitsManager.defaultLengthUnits = "mm"

        stage = "creating the user parameters"
        made, updated = set_parameters(design)

        stage = "building the keep-out bodies"
        bodies = build_keepouts(design, design.rootComponent)

        ui.messageBox(
            "4.2in e-Paper desk frame\\n\\n"
            "%%d parameters created, %%d updated\\n"
            "%%d keep-out bodies, named %%s*\\n\\n"
            "Origin: X = short axis (0 = centre), Y = depth (0 = outer front "
            "face), Z = long axis (0 = bottom edge)."
            %% (made, updated, bodies, KEEPOUT_PREFIX))
    except Exception:
        message = ("Stopped while %%s.\\n\\n%%s\\n"
                   "The same numbers are in fusion/parameters.csv and "
                   "fusion/keepouts.csv, so nothing is lost - the keep-outs "
                   "are eight boxes and the CSV gives their min and max on "
                   "every axis." %% (stage, traceback.format_exc()))
        if ui:
            ui.messageBox(message)
        else:
            print(message)
'''


def write_fusion_script(path, rows, keep, P):
    plist = []
    for r in rows:
        if r[0] == "#":
            plist.append("    # ---- %s\n" % r[1])
        else:
            n, unit, val, note = r
            plist.append('    (%-22s %-7s %-10s %s),\n'
                         % ('"%s",' % n, '"%s",' % unit, '"%s",' % val,
                            '"%s"' % note.replace('"', "'")))
    klist = []
    for n, x0, x1, y0, y1, z0, z1, note in keep:
        klist.append('    (%-17s %9s, %9s, %8s, %8s, %8s, %8s, %s),\n'
                     % ('"%s",' % n, fmt(x0), fmt(x1), fmt(y0), fmt(y1),
                        fmt(z0), fmt(z1), '"%s"' % note.replace('"', "'")))
    body = FUSION_TEMPLATE % {
        "parameters": "".join(plist),
        "keepouts": "".join(klist),
        "drv_stack": "%g" % P.get("drv_stack", 16.0),
    }
    open(path, "w").write(body)


if __name__ == "__main__":
    main()
