#!/usr/bin/env python3
"""
RÖDALM 4x6 frame insert for the 4.2" e-paper daily dash -- build123d.

    python3 src/rodalm_frame.py            build, check, export the 3MF project + STEP
    python3 src/rodalm_frame.py check      build and run the interference checks only
    python3 src/rodalm_frame.py params     print the derived numbers

Parts, all printed:
    mat       printed mat; the glass sits in a pocket in its back
    cassette  carries every board; the frame's tabs fold onto four ledges
    lid       screws into the cassette; carries the USB-C port and the strut hinge
    strut     easel strut, snaps onto a 2 mm pin
    coupon_*  fit coupons CUT from the real mat and cassette, plus an insert gauge

COORDINATES -- read this once, it is the source of most mistakes.
    Seen from the BACK, frame in portrait:
    X  across, increasing toward the RIBBON side (the panel's tail side)
    Y  up
    Z  depth, 0 at the inside face of the frame's front lip, increasing toward
       the back of the frame
    Origin at the frame's centre in X and Y.  From the FRONT, X is mirrored:
    the ribbon side is on the viewer's LEFT.

Every length is in mm.  Tags: (F) measured on the frame, (M) measured on the
stand build (../../stand-4.2in), (A) assumed.
"""
import json
import math
import re
import sys
import tempfile
import uuid
import zipfile
from pathlib import Path

from build123d import (Align, Axis, Box, Circle, Compound, Cone, Cylinder, Mesher, fillet,
                       Plane, Polygon, Pos, Rectangle, RectangleRounded, Rot,
                       SlotCenterToCenter, Text, export_step, extrude)

# ===========================================================================
# PARAMETERS
# ===========================================================================

# --- the frame (IKEA RÖDALM 4x6) --------------------------------------------
FR_W, FR_H, FR_D = 120.65, 171.45, 31.75   # outside, 4 3/4 x 6 3/4 x 1 1/4 in
REB_W, REB_H = 100.0, 150.0                # (F) M1 rebate
SIGHT_W, SIGHT_H = 85.0, 135.0             # (F) M2 sight opening
INSIDE_D = 25.0                            # (F) M9 lip's inside face -> back edge
COVER_T = 1.0                              # (F) M4 polystyrene cover
TAB_Z = 17.5                               # (F) M3 tab plane: the stock stack
                                           #   1 + 12 + 1.5 + 3 that the tabs are
                                           #   made to hold.  Measured ~16.
TAB_L = 8.0                                # (F) M5 tab length
# (F) M5/M10 tab positions, read from the back: fraction along that side,
# measured from the LEFT end (top, bottom) or the BOTTOM end (left, right).
TABS = {"top": 2 / 3, "bottom": 2 / 5, "left": 3 / 5, "right": 3 / 5}

# --- the panel (Waveshare 4.2" (B), bare glass) ------------------------------
PAN_W, PAN_H, PAN_T = 76.0, 90.0, 1.05     # (M) glass, sharp corners
ACT_W, ACT_H = 63.6, 84.8                  # active area
ACT_OFF = 3.2                              # (M) ink centre is this far off the glass
                                           #   centre, AWAY from the ribbon side
WHITE_SHORT, WHITE_LONG = 0.7, 1.3         # white line left showing in the window
PAN_CLR = 0.75                             # (M) pocket clearance per side
PAN_R, PAN_REL = 0.5, 1.4                  # (M) pocket corner radius, corner relief
# the tail route (M), from the stand
RIB_OUT, RIB_BAND, RIB_RUN, RIB_LEG3, RIB_MARG, RIB_DEP = 4.0, 9.0, 20.0, 10.0, 10.0, 3.0

# --- the mat --------------------------------------------------------------
MAT_SKIN = 1.2          # face thickness; the window bevel is 45 deg through it
FOAM = 0.3              # compressed foam between the glass and the cassette floor
FIT = 0.3               # mat and cassette, per side in the rebate

# --- the cassette -----------------------------------------------------------
WALL = 1.6
FLOOR = 1.4
CARRIER_LIFT = 1.5      # air under the carrier: FLUSH-CUT the header tails to fit
DRV_STACK = 16.0        # (M) carrier + female sockets + driver, front face to top
LID_GAP = 0.5
LID_T = 2.0
CORNER_R = 0.5          # outside corners of the mat and cassette

# boards and parts, as footprints seen from the back (x0, x1, y0, y1)
CARRIER = (-39.0, -9.0, -22.0, 48.0)       # 30 x 70 perfboard
CARRIER_T = 1.6
CARRIER_HOLES = (26.0, 66.0)               # (M) hole centres
CARRIER_HOLE_D, CARRIER_PAD_D, CARRIER_PEG_UNDER = 2.0, 4.0, 0.15
DRV_W, DRV_H = 29.46, 48.25                # driver board, on the carrier's top end
ADAPT_W, ADAPT_H, ADAPT_ENV = 18.0, 32.0, 5.0   # (M) FPC adapter
ADAPT_IN, ADAPT_Y0 = 2.0, 10.5             # 2 in from the glass's ribbon edge; Y start
CHG = (-46.0, -14.0, -62.0, -35.7)         # bq25185 envelope 32 x 26.3
CHG_T = 7.2                                # (M) board + tallest part
CHG_HOLES = (26.67, 20.32)                 # (M) off Adafruit's STEP
CHG_POST_D, CHG_POST_H = 6.5, 4.5
CELL = (-6.5, 37.5, -66.0, -17.0)          # 44 x 49
CELL_T, CELL_TAPE, CELL_CLR = 6.9, 0.5, 0.8
FENCE_T, FENCE_H, FENCE_LEG = 1.0, 3.0, 8.0

# heat-set inserts: bore, depth (insert length + 1.0 for displaced plastic).
# Bores are 0.3 under the insert's outside diameter, as on the stand.  The
# gauge (coupon_gauge) has 3.2 and 2.7 among its holes to confirm them.
M25_BORE, M25_DEPTH = 3.2, 5.0             # M2.5 x 4, 3.5 OD (F) -- lid bosses
M2_BORE, M2_DEPTH = 2.7, 5.0               # M2 x 4,   3.0 OD (F) -- charger posts
BOSS_D = 8.0
SCR_FREE, SCR_HEAD = 2.9, 5.0              # M2.5 countersunk, 90 deg

# tab wells
WELL_W = 14.0                              # along the wall: tab width + slop for
                                           #   "roughly 3/5 of the way"
WELL_D = TAB_L + 1.0 - FIT                 # in from the cassette's outer face
WELL_WALL = 1.2
LEDGE_FOAM = 0.0                           # set if the tab needs packing

# USB-C pigtail: the 6-wire part's panel hole (the stand's .scad, newer than its
# README).  Body 12.0 x 5.3 x 12 behind a 16.7 x 10.3 x 2.0 flange.
USB_HOLE = (13.6, 6.3, 1.3)
USB_AT = (-31.0, -29.25)
USB_BODY = (12.0, 5.3, 12.0)
USB_FLANGE = (16.7, 10.3, 2.0)

# keyholes, for hanging on a wall
KEY_AT = [(-32.0, 60.0), (32.0, 60.0)]
KEY_HEAD_D, KEY_SLOT_W, KEY_SLOT_L = 8.0, 4.2, 7.0

# --- the easel strut ---------------------------------------------------------
DEP_ANG = 35.0          # swing from folded
LEAN_TARGET = 20.0      # the pivot height is solved for this lean
ST_W, ST_T = 24.0, 4.0     # width at the hinge (sets the pin length), thickness
ST_FOOT_W = 44.0           # ... flaring to this at the foot, for side-to-side support.
                           #   Folded, it must clear the USB-C flange: see the check
ST_FOOT_R = 4.0
ST_LEN = 100.0          # pin to foot tip.  About 0.6 of the frame's height, like a
                        #   stock easel; the pivot height is solved from it
HEEL = 7.0              # heel length past the pin
PIN_D, PIN_FIT = 2.0, 0.10
EAR_W, EAR_LEN, EAR_CLR, EAR_TOP = 3.0, 10.0, 0.4, 1.6
EAR_MOUTH = 0.72        # C-socket mouth, as a fraction of the bore
COM_N = -15.0           # estimated centre of mass, mm IN FRONT of the back plane

# --- the printer and the slicer project ---------------------------------------
# FlashForge Adventurer 5M Pro, as set in the stand's OrcaSlicer projects: a
# 220 x 220 bed centred on the origin, 220 tall.  slicer/orca_project_settings.config
# is copied from those projects, so the 3MF opens with the same printer, filament
# and process presets.
BED_W, BED_D, BED_H = 220.0, 220.0, 220.0
BED_MARGIN = 4.0        # keep every part this far inside the bed edge
PART_GAP = 8.0          # between parts sharing a plate
# Plates, in order.  Each is a name and its rows, top row first; each row lists
# parts left to right.  Parts are placed print-side down (see on_bed()).
PLATES = [
    ("Mat + lid (smooth sheet)", [["mat", "lid"]]),
    ("Cassette + strut", [["cassette", "strut"]]),
    ("Fit test: coupons + insert gauge", [["coupon_mat", "coupon_cassette"], ["gauge"]]),
]
PART_NAMES = {"mat": "Mat", "lid": "Lid", "cassette": "Cassette", "strut": "Strut",
              "coupon_mat": "Coupon - mat", "coupon_cassette": "Coupon - cassette",
              "gauge": "Insert gauge"}

# ===========================================================================
# DERIVED
# ===========================================================================
OUT_W, OUT_H = REB_W - 2 * FIT, REB_H - 2 * FIT
IN_W, IN_H = OUT_W - 2 * WALL, OUT_H - 2 * WALL
WIN_W, WIN_H = ACT_W + 2 * WHITE_SHORT, ACT_H + 2 * WHITE_LONG
GX = ACT_OFF                                # glass centre X (ink centre is X = 0)
POCK_W, POCK_H = PAN_W + 2 * PAN_CLR, PAN_H + 2 * PAN_CLR
GLASS_EDGE = GX + PAN_W / 2                 # the glass's ribbon edge
POCK_EDGE = GX + POCK_W / 2
RIB_X1 = POCK_EDGE + RIB_OUT                # ribbon relief, outer edge
RIB_LEN = RIB_RUN + RIB_BAND + 2 * RIB_MARG
RIB_Y0 = -PAN_H / 2 + (PAN_H / 2 - RIB_BAND / 2 - RIB_MARG)
RIB_Y1 = RIB_Y0 + RIB_LEN

Z_MAT0 = COVER_T
Z_MAT1 = Z_MAT0 + MAT_SKIN + PAN_T          # mat back = glass back
Z_GLASS0 = Z_MAT0 + MAT_SKIN
Z_CAS0 = Z_MAT1 + FOAM                      # cassette front (floor front)
Z_FLOOR = Z_CAS0 + FLOOR                    # floor back
Z_CAR0 = Z_FLOOR + CARRIER_LIFT             # carrier front face
Z_CAR1 = Z_CAR0 + CARRIER_T
Z_DRV1 = Z_CAR0 + DRV_STACK                 # tallest point on the driver
Z_LID0 = Z_DRV1 + LID_GAP
Z_BACK = Z_LID0 + LID_T
LID_RECESS = INSIDE_D - Z_BACK              # + = lid inside the moulding

ADAPT = (GLASS_EDGE - ADAPT_IN - ADAPT_W, GLASS_EDGE - ADAPT_IN, ADAPT_Y0, ADAPT_Y0 + ADAPT_H)
CAR_CX, CAR_CY = (CARRIER[0] + CARRIER[1]) / 2, (CARRIER[2] + CARRIER[3]) / 2
DRV = (CAR_CX - DRV_W / 2, CAR_CX + DRV_W / 2, CARRIER[3] - DRV_H, CARRIER[3])
CHG_CX, CHG_CY = (CHG[0] + CHG[1]) / 2, (CHG[2] + CHG[3]) / 2
BOSS_X, BOSS_Y = IN_W / 2 - BOSS_D / 2, IN_H / 2 - BOSS_D / 2

# floor opening: the adapter window plus the ribbon relief, one hole, so the tail
# lies on the glass back exactly as it did in the stand
OPEN_A = (ADAPT[0] - 0.5, ADAPT[1] + 0.5, ADAPT[2] - 0.5, ADAPT[3] + 0.5)
OPEN_B = (OPEN_A[1], RIB_X1, RIB_Y0, RIB_Y1)

# strut: the pin sits far enough off the lid that the strut's front edge clears it
# through the whole swing (needs (ST_T/2)/cos(DEP_ANG)), and far enough that the
# folded strut clears the moulding where it crosses the bottom rail
PIV_H = max(max(LID_RECESS, 0.0) + ST_T / 2, ST_T / 2 / math.cos(math.radians(DEP_ANG)) + 0.1)
Z_PIN = Z_BACK + PIV_H
BOTTOM_EDGE = -FR_H / 2


def stance(y_pin, L=ST_LEN):
    """Lean (deg), footprint and CoM margin for a pivot at y_pin.  2-D, in the frame's
    side view: s = height above the bottom edge, n = distance behind the back plane."""
    s_p, n_p = y_pin - BOTTOM_EDGE, Z_PIN - INSIDE_D
    th = math.radians(DEP_ANG)
    pts = []
    for zl in (-ST_T / 2, ST_T / 2):
        yl = -L
        pts.append((s_p + yl * math.cos(th) + zl * math.sin(th),
                    n_p - yl * math.sin(th) + zl * math.cos(th)))
    lam = min(math.atan2(s, n) for s, n in pts)
    foot = max(s * math.sin(lam) + n * math.cos(lam) for s, n in pts)
    s_c = FR_H / 2
    com = s_c * math.sin(lam) + COM_N * math.cos(lam)
    return math.degrees(lam), foot, com, L


def solve_pivot():
    # For a fixed strut, a higher pivot leans the frame further back:
    # tan(lean) = (pivot height - L cos(swing)) / (pin offset + L sin(swing))
    lo, hi = BOTTOM_EDGE + ST_LEN, FR_H / 2
    for _ in range(60):
        mid = (lo + hi) / 2
        if stance(mid)[0] > LEAN_TARGET:
            hi = mid
        else:
            lo = mid
    return (lo + hi) / 2


Y_PIN = solve_pivot()
LEAN, FOOTPRINT, COM_MARGIN, _ = stance(Y_PIN)
TIP_CLR = Y_PIN - ST_LEN - BOTTOM_EDGE      # folded tip, above the bottom edge

# ===========================================================================
# HELPERS
# ===========================================================================

def bx(x0, x1, y0, y1, z0, z1):
    return Pos((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2) * Box(x1 - x0, y1 - y0, z1 - z0)


def rbox(w, h, r, z0, z1, cx=0.0, cy=0.0):
    return Pos(cx, cy, z0) * extrude(RectangleRounded(w, h, r), z1 - z0)


def cyl(d, z0, z1, x=0.0, y=0.0):
    return Pos(x, y, z0) * Cylinder(d / 2, z1 - z0, align=(Align.CENTER, Align.CENTER, Align.MIN))


def relieved(w, h, r, rel, z0, z1, cx=0.0, cy=0.0):
    s = rbox(w, h, r, z0, z1, cx, cy)
    for sx in (-1, 1):
        for sy in (-1, 1):
            s += cyl(2 * rel, z0, z1, cx + sx * w / 2, cy + sy * h / 2)
    return s


def side_place(side, frac):
    """Transform for a feature built in WALL-LOCAL coords -- local x inward from the
    cassette's outer face, local y along the wall, z unchanged -- at a tab."""
    if side == "left":
        return Pos(-OUT_W / 2, -REB_H / 2 + frac * REB_H, 0)
    if side == "right":
        return Pos(OUT_W / 2, -REB_H / 2 + frac * REB_H, 0) * Rot(0, 0, 180)
    if side == "bottom":
        return Pos(-REB_W / 2 + frac * REB_W, -OUT_H / 2, 0) * Rot(0, 0, 90)
    return Pos(-REB_W / 2 + frac * REB_W, OUT_H / 2, 0) * Rot(0, 0, -90)


def vol(shape):
    try:
        return shape.volume
    except Exception:
        return 0.0


# ===========================================================================
# PARTS
# ===========================================================================

def make_mat():
    mat = rbox(OUT_W, OUT_H, CORNER_R, Z_MAT0, Z_MAT1)
    # window, bevelled 45 deg: WIN at the back of the skin, wider at the front
    bevel = extrude(Plane(origin=(0, 0, Z_GLASS0 + 0.01), z_dir=(0, 0, -1)) *
                    Rectangle(WIN_W, WIN_H), amount=MAT_SKIN + 0.02, taper=-45)
    mat -= bevel
    # glass pocket in the back, offset so the ink is centred on the window
    mat -= relieved(POCK_W, POCK_H, PAN_R, PAN_REL, Z_GLASS0, Z_MAT1 + 0.1, GX, 0)
    # ribbon side: open the pocket out RIB_OUT so the tail leaves the glass flat
    mat -= bx(POCK_EDGE - 0.5, RIB_X1, RIB_Y0, RIB_Y1, Z_GLASS0, Z_MAT1 + 0.1)
    return mat


def well_block():
    """Block that carries one tab's ledge, in wall-local coords.  Its underside is a
    45 deg chamfer up from the floor at the wall, so it prints without support and
    leaves the space near the floor (the tail, the cell) free."""
    bd = WELL_D + WELL_WALL
    bw = WELL_W + 2 * WELL_WALL
    prof = [(0, Z_FLOOR - 0.01), (bd, Z_FLOOR - 0.01 + bd), (bd, Z_LID0), (0, Z_LID0)]
    return extrude(Plane.XZ * Polygon(*prof, align=None), amount=bw / 2, both=True)


def well_cut(grow=0.0):
    return bx(-2.0, WELL_D + grow, -WELL_W / 2 - grow, WELL_W / 2 + grow,
              TAB_Z + LEDGE_FOAM, Z_BACK + 5)


def make_cassette():
    shell = rbox(OUT_W, OUT_H, CORNER_R, Z_CAS0, Z_BACK)
    shell -= bx(-IN_W / 2, IN_W / 2, -IN_H / 2, IN_H / 2, Z_FLOOR, Z_BACK + 1)
    c = shell
    # corner bosses for the lid
    for sx in (-1, 1):
        for sy in (-1, 1):
            c += cyl(BOSS_D, Z_FLOOR - 0.01, Z_LID0, sx * BOSS_X, sy * BOSS_Y)
            # fill the corner behind the boss so it merges into both walls
            x0, x1 = sorted((sx * BOSS_X, sx * IN_W / 2))
            y0, y1 = sorted((sy * BOSS_Y, sy * IN_H / 2))
            c += bx(x0, x1, y0, y1, Z_FLOOR - 0.01, Z_LID0)
    # tab wells: block, then the well itself
    for side, frac in TABS.items():
        c += side_place(side, frac) * well_block()
    for side, frac in TABS.items():
        c -= side_place(side, frac) * well_cut()
    # carrier pads and pegs
    hx, hy = CARRIER_HOLES[0] / 2, CARRIER_HOLES[1] / 2
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = CAR_CX + sx * hx, CAR_CY + sy * hy
            c += cyl(CARRIER_PAD_D, Z_FLOOR - 0.01, Z_CAR0, x, y)
            # flush with the board's top: the first header pin is 2.0 from each
            # hole, so a peg standing proud would meet a header body
            c += cyl(CARRIER_HOLE_D - CARRIER_PEG_UNDER, Z_CAR0 - 0.01, Z_CAR1, x, y)
    # charger posts
    px, py = CHG_HOLES[0] / 2, CHG_HOLES[1] / 2
    for sx in (-1, 1):
        for sy in (-1, 1):
            c += cyl(CHG_POST_D, Z_FLOOR - 0.01, Z_FLOOR + CHG_POST_H, CHG_CX + sx * px, CHG_CY + sy * py)
    # cell fences: four L corners
    fx0, fx1 = CELL[0] - CELL_CLR, CELL[1] + CELL_CLR
    fy0, fy1 = CELL[2] - CELL_CLR, CELL[3] + CELL_CLR
    for x, dx in ((fx0, -1), (fx1, 1)):
        for y, dy in ((fy0, -1), (fy1, 1)):
            xa, xb = sorted((x, x + dx * FENCE_T))
            ya, yb = sorted((y, y + dy * FENCE_T))
            xl0, xl1 = sorted((x + dx * FENCE_T, x - dx * FENCE_LEG))
            yl0, yl1 = sorted((y + dy * FENCE_T, y - dy * FENCE_LEG))
            c += bx(xl0, xl1, ya, yb, Z_FLOOR - 0.01, Z_FLOOR + FENCE_H)
            c += bx(xa, xb, yl0, yl1, Z_FLOOR - 0.01, Z_FLOOR + FENCE_H)
    # --- cuts ---
    c -= bx(*OPEN_A, Z_CAS0 - 1, Z_FLOOR + 0.5)
    c -= bx(*OPEN_B, Z_CAS0 - 1, Z_FLOOR + 0.5)
    for sx in (-1, 1):
        for sy in (-1, 1):
            c -= cyl(M25_BORE, Z_LID0 - M25_DEPTH, Z_LID0 + 1, sx * BOSS_X, sy * BOSS_Y)
            c -= cyl(M2_BORE, Z_FLOOR + CHG_POST_H - M2_DEPTH, Z_FLOOR + CHG_POST_H + 1,
                     CHG_CX + sx * px, CHG_CY + sy * py)
    return c


def make_lid():
    w, h = IN_W - 0.4, IN_H - 0.4
    lid = bx(-w / 2, w / 2, -h / 2, h / 2, Z_LID0, Z_BACK)
    # notches over the tab wells, so a screwdriver reaches the tabs
    for side, frac in TABS.items():
        lid -= side_place(side, frac) * well_cut(grow=0.3)
    # countersunk screws into the corner bosses
    csk = (SCR_HEAD - SCR_FREE) / 2
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * BOSS_X, sy * BOSS_Y
            lid -= cyl(SCR_FREE, Z_LID0 - 1, Z_BACK + 1, x, y)
            lid -= Pos(x, y, Z_BACK - csk) * Cone(SCR_FREE / 2, SCR_HEAD / 2 + 0.01, csk + 0.01,
                                                  align=(Align.CENTER, Align.CENTER, Align.MIN))
    # USB-C pigtail
    uw, uh, ur = USB_HOLE
    lid -= rbox(uw, uh, ur, Z_LID0 - 1, Z_BACK + 1, *USB_AT)
    # keyholes: the head goes in through the round hole, the frame drops, the shank
    # rides up the slot.  The head ends up inside the cassette, in clear space.
    for x, y in KEY_AT:
        lid -= cyl(KEY_HEAD_D, Z_LID0 - 1, Z_BACK + 1, x, y)
        lid -= Pos(x, y + KEY_SLOT_L / 2, Z_LID0 - 1) * extrude(
            SlotCenterToCenter(KEY_SLOT_L, KEY_SLOT_W, rotation=90), LID_T + 2)
    # strut hinge ears, with C-sockets opening away from the lid
    bore = PIN_D + PIN_FIT
    ear_top = Z_PIN + bore / 2 + EAR_TOP
    for sx in (-1, 1):
        xa = sx * (ST_W / 2 + EAR_CLR)
        x0, x1 = sorted((xa, xa + sx * EAR_W))
        lid += bx(x0, x1, Y_PIN - EAR_LEN / 2, Y_PIN + EAR_LEN / 2, Z_BACK - 0.01, ear_top)
    pin_len = ST_W + 2 * (EAR_CLR + EAR_W)
    lid -= Pos(0, Y_PIN, Z_PIN) * Rot(0, 90, 0) * Cylinder(bore / 2, pin_len + 2)
    lid -= bx(-pin_len / 2 - 1, pin_len / 2 + 1, Y_PIN - bore * EAR_MOUTH / 2,
              Y_PIN + bore * EAR_MOUTH / 2, Z_PIN, ear_top + 1)
    return lid


def make_strut(theta=0.0):
    """The strut, folded (theta = 0) or swung out by theta degrees."""
    yt = Y_PIN - ST_LEN
    z0, z1 = Z_PIN - ST_T / 2, Z_PIN + ST_T / 2
    # straight at the hinge, flaring from the pin to the foot
    # Straight between the ears, then flaring to the foot.  Counter-clockwise seen
    # from +Z, so the face's normal is +Z and it extrudes toward the back.
    y_flare = Y_PIN - EAR_LEN / 2 - 1.0
    outline = [(-ST_W / 2, Y_PIN + HEEL), (-ST_W / 2, y_flare), (-ST_FOOT_W / 2, yt),
               (ST_FOOT_W / 2, yt), (ST_W / 2, y_flare), (ST_W / 2, Y_PIN + HEEL)]
    body = Pos(0, 0, z0) * extrude(Polygon(*outline, align=None), ST_T)
    assert abs(body.bounding_box().min.Z - z0) < 1e-6, "strut extruded the wrong way"
    feet = body.edges().filter_by(Axis.Z).filter_by_position(Axis.Y, yt - 0.01, yt + 0.01)
    body = fillet(feet, ST_FOOT_R)
    # THE STOP: the lid's face, pulled back through the deployed rotation.  What is
    # left of the heel is a flat that lands on the lid at exactly DEP_ANG.
    pin_axis = Axis((0, Y_PIN, Z_PIN), (1, 0, 0))
    lidside = bx(-ST_FOOT_W, ST_FOOT_W, Y_PIN - 60, Y_PIN + 60, Z_BACK - 60, Z_BACK)
    body -= lidside.rotate(pin_axis, DEP_ANG)
    body -= Pos(0, Y_PIN, Z_PIN) * Rot(0, 90, 0) * Cylinder((PIN_D + PIN_FIT) / 2, ST_W + 2)
    if theta:
        body = body.rotate(pin_axis, -theta)
    return body


# --- mocks, for the interference checks --------------------------------------

def mocks():
    m = {}
    mould = bx(-FR_W / 2, FR_W / 2, -FR_H / 2, FR_H / 2, -(FR_D - INSIDE_D), INSIDE_D)
    mould -= bx(-REB_W / 2, REB_W / 2, -REB_H / 2, REB_H / 2, 0, INSIDE_D + 1)
    mould -= bx(-SIGHT_W / 2, SIGHT_W / 2, -SIGHT_H / 2, SIGHT_H / 2, -FR_D, 1)
    m["moulding"] = mould
    m["cover"] = bx(-REB_W / 2 + 0.1, REB_W / 2 - 0.1, -REB_H / 2 + 0.1, REB_H / 2 - 0.1, 0, COVER_T)
    m["glass"] = bx(GX - PAN_W / 2, GX + PAN_W / 2, -PAN_H / 2, PAN_H / 2, Z_GLASS0, Z_MAT1)
    # the tail: out RIB_OUT, folded back past the glass by RIB_DEP, up RIB_RUN, in RIB_LEG3
    m["tail"] = (bx(GLASS_EDGE, GLASS_EDGE + RIB_OUT, -RIB_BAND / 2, RIB_RUN + RIB_BAND / 2,
                    Z_MAT1 - 0.3, Z_MAT1 + RIB_DEP)
                 + bx(GLASS_EDGE + RIB_OUT - RIB_LEG3, GLASS_EDGE + RIB_OUT,
                      RIB_RUN - RIB_BAND / 2, RIB_RUN + RIB_BAND / 2, Z_MAT1, Z_MAT1 + RIB_DEP))
    m["adapter"] = bx(*ADAPT, Z_MAT1, Z_MAT1 + ADAPT_ENV)
    car = bx(*CARRIER, Z_CAR0, Z_CAR1)
    hx, hy = CARRIER_HOLES[0] / 2, CARRIER_HOLES[1] / 2
    for sx in (-1, 1):
        for sy in (-1, 1):
            car -= cyl(CARRIER_HOLE_D, Z_CAR0 - 1, Z_CAR1 + 1, CAR_CX + sx * hx, CAR_CY + sy * hy)
    m["carrier"] = car
    m["driver"] = bx(*DRV, Z_CAR1, Z_DRV1)
    chg = bx(*CHG, Z_FLOOR + CHG_POST_H, Z_FLOOR + CHG_POST_H + CHG_T)
    px, py = CHG_HOLES[0] / 2, CHG_HOLES[1] / 2
    m["charger"] = chg
    m["cell"] = bx(*CELL, Z_FLOOR, Z_FLOOR + CELL_TAPE + CELL_T)
    bw, bh, bd = USB_BODY
    fw, fh, ft = USB_FLANGE
    m["usb"] = (bx(USB_AT[0] - bw / 2, USB_AT[0] + bw / 2, USB_AT[1] - bh / 2, USB_AT[1] + bh / 2,
                   Z_BACK - bd, Z_BACK)
                + bx(USB_AT[0] - fw / 2, USB_AT[0] + fw / 2, USB_AT[1] - fh / 2, USB_AT[1] + fh / 2,
                     Z_BACK, Z_BACK + ft))
    tabs = None
    for side, frac in TABS.items():
        t = side_place(side, frac) * bx(-FIT, -FIT + TAB_L, -3, 3, TAB_Z + LEDGE_FOAM, TAB_Z + LEDGE_FOAM + 0.4)
        tabs = t if tabs is None else tabs + t
    m["tabs"] = tabs
    m["pin"] = Pos(0, Y_PIN, Z_PIN) * Rot(0, 90, 0) * Cylinder(PIN_D / 2, ST_W + 2 * (EAR_CLR + EAR_W))
    return m


# --- fit coupons and the insert gauge ------------------------------------------

def ring(width, z0, z1):
    return (bx(-OUT_W / 2 - 1, OUT_W / 2 + 1, -OUT_H / 2 - 1, OUT_H / 2 + 1, z0, z1)
            - bx(-OUT_W / 2 + width, OUT_W / 2 - width, -OUT_H / 2 + width, OUT_H / 2 - width, z0 - 1, z1 + 1))


def make_coupons(mat, cassette):
    rib_box = bx(OPEN_A[0] + 6, OUT_W / 2 + 1, RIB_Y0 - 6, max(RIB_Y1, OPEN_A[3]) + 6, -1, 0)
    keep_mat = ring(6.0, Z_MAT0 - 1, Z_MAT1 + 1) + \
        bx(OPEN_A[0] + 6, OUT_W / 2 + 1, RIB_Y0 - 6, max(RIB_Y1, OPEN_A[3]) + 6, Z_MAT0 - 1, Z_MAT1 + 1)
    cmat = mat & keep_mat
    zc = Z_FLOOR + 1.6
    keep_cas = ring(6.0, Z_CAS0 - 1, zc) + \
        bx(OPEN_A[0] + 6, OUT_W / 2 + 1, RIB_Y0 - 6, max(RIB_Y1, OPEN_A[3]) + 6, Z_CAS0 - 1, zc)
    for side, frac in TABS.items():
        keep_cas += side_place(side, frac) * bx(-1, WELL_D + WELL_WALL + 1,
                                                -WELL_W / 2 - WELL_WALL - 1, WELL_W / 2 + WELL_WALL + 1,
                                                Z_CAS0 - 1, TAB_Z + LEDGE_FOAM + 1.0)
    ccas = cassette & keep_cas
    return cmat, ccas


GAUGE_M25 = (3.2, 3.4, 3.6, 3.8)
GAUGE_M2 = (2.5, 2.7, 2.9, 3.1)


def make_gauge():
    n = len(GAUGE_M25) + len(GAUGE_M2)
    pitch, h, t = 9.0, 16.0, 7.0
    w = n * pitch + 6
    g = bx(-w / 2, w / 2, -h / 2, h / 2, 0, t)
    for i, d in enumerate(GAUGE_M25 + GAUGE_M2):
        x = -w / 2 + 3 + pitch / 2 + i * pitch
        g -= cyl(d, t - 5.5, t + 1, x, 2.5)
        label = Pos(x, -4.3, t - 0.4) * extrude(Text(f"{d:.1f}", font_size=3.2), 0.5)
        g -= label
    for i, label in enumerate(("M2.5", "M2")):
        x = -w / 2 + 3 + (2 + 4 * i) * pitch
        g -= Pos(x, 6.2, t - 0.4) * extrude(Text(label, font_size=2.8), 0.5)
    return g


# ===========================================================================
# CHECKS
# ===========================================================================

def run_checks(p, m):
    rows = []

    def chk(name, a, b, expect="empty"):
        v = vol(a & b)
        ok = v < 1e-3 if expect == "empty" else v > 1e-3
        rows.append((name, v, ok, expect))

    # parts against each other
    chk("mat x cassette", p["mat"], p["cassette"])
    chk("cassette x lid", p["cassette"], p["lid"])
    chk("mat x lid", p["mat"], p["lid"])
    chk("strut(folded) x lid", p["strut"], p["lid"])
    # parts against the frame
    for k in ("mat", "cassette", "lid"):
        chk(f"{k} x moulding", p[k], m["moulding"])
        chk(f"{k} x cover", p[k], m["cover"])
    chk("strut(folded) x moulding", p["strut"], m["moulding"])
    # hardware against the parts
    for hw in ("glass", "tail", "adapter", "carrier", "driver", "charger", "cell", "usb", "tabs", "pin"):
        for k in ("mat", "cassette", "lid"):
            if hw == "pin" and k == "lid":
                continue
            chk(f"{hw} x {k}", m[hw], p[k])
    # hardware against hardware that shares space
    chk("driver x adapter", m["driver"], m["adapter"])
    chk("driver x usb", m["driver"], m["usb"])
    chk("charger x usb", m["charger"], m["usb"])
    chk("cell x usb", m["cell"], m["usb"])
    chk("cell x carrier", m["cell"], m["carrier"])
    chk("strut(folded) x usb flange", p["strut"], m["usb"])
    # the strut through its whole swing: empty up to DEP_ANG, then the heel lands
    for th in (5, 10, 15, 20, 25, 30, DEP_ANG):
        s = make_strut(th)
        chk(f"strut @{th:g} x lid+moulding", s, p["lid"] + m["moulding"])
    chk(f"strut @{DEP_ANG + 1:g} x lid (heel lands)", make_strut(DEP_ANG + 1), p["lid"], expect="contact")
    return rows


# ===========================================================================
# MAIN
# ===========================================================================

def params_text():
    lines = [
        f"cassette outside {OUT_W:.1f} x {OUT_H:.1f}, inside {IN_W:.1f} x {IN_H:.1f}",
        f"depth stack (from the lip's inside face): cover {COVER_T}, mat {Z_MAT0:.2f}-{Z_MAT1:.2f}, "
        f"floor {Z_CAS0:.2f}-{Z_FLOOR:.2f}, carrier {Z_CAR0:.2f}, driver top {Z_DRV1:.2f}, "
        f"lid {Z_LID0:.2f}-{Z_BACK:.2f}",
        f"frame inside depth {INSIDE_D} -> lid {'recessed' if LID_RECESS >= 0 else 'proud'} by {abs(LID_RECESS):.2f}",
        f"tab ledge at {TAB_Z + LEDGE_FOAM:.2f}; wells {WELL_W} wide x {WELL_D:.1f} deep",
        f"window {WIN_W:.1f} x {WIN_H:.1f}; mat shows {(SIGHT_W - WIN_W) / 2:.1f} at the sides, "
        f"{(SIGHT_H - WIN_H) / 2:.1f} top and bottom",
        f"glass centre X {GX:.2f}; ribbon edge {GLASS_EDGE:.2f}; relief to {RIB_X1:.2f}, Y {RIB_Y0:.1f}..{RIB_Y1:.1f}",
        f"strut: pivot {Y_PIN - BOTTOM_EDGE:.1f} above the bottom edge (Y {Y_PIN:.2f}), "
        f"{PIV_H:.2f} off the lid; length {ST_LEN:.1f}, {ST_W:g} wide at the hinge to {ST_FOOT_W:g} at the foot, "
        f"folded tip {TIP_CLR:.1f} above the bottom edge; "
        f"pin {PIN_D} x {ST_W + 2 * (EAR_CLR + EAR_W):.1f}",
        f"stance: lean {LEAN:.1f} deg, footprint {FOOTPRINT:.1f}, CoM {COM_MARGIN:.1f} behind the contact edge",
        f"inserts: M2.5 bore {M25_BORE} x {M25_DEPTH}, M2 bore {M2_BORE} x {M2_DEPTH}",
    ]
    return "\n".join(lines)


def build():
    p = {"mat": make_mat(), "cassette": make_cassette(), "lid": make_lid(), "strut": make_strut()}
    return p


def on_bed(shape, flip=False):
    """The part as it prints: rotated if it needs to be, lowest face on z = 0,
    centred on the origin in X and Y."""
    s = shape.rotate(Axis.Y, 180) if flip else shape
    bb = s.bounding_box()
    return Pos(-(bb.min.X + bb.max.X) / 2, -(bb.min.Y + bb.max.Y) / 2, -bb.min.Z) * s


def print_parts(p, coupons, gauge):
    return {
        "mat": on_bed(p["mat"]),                 # face down, on the smooth sheet
        "cassette": on_bed(p["cassette"]),       # floor down
        "lid": on_bed(p["lid"]),                 # inner face down, ears up
        "strut": on_bed(p["strut"], flip=True),  # back face down: the heel needs no support
        "coupon_mat": on_bed(coupons[0]),
        "coupon_cassette": on_bed(coupons[1]),
        "gauge": on_bed(gauge),
    }


def mesh_of(shape):
    """Vertices and triangles, welded, via build123d's own 3MF writer."""
    with tempfile.TemporaryDirectory() as tmp:
        f = Path(tmp) / "m.3mf"
        mesher = Mesher()
        mesher.add_shape(shape, linear_deflection=0.01, angular_deflection=0.15)
        mesher.write(str(f))
        xml = zipfile.ZipFile(f).read("3D/3dmodel.model").decode()
    v = [tuple(map(float, m)) for m in
         re.findall(r'<vertex x="([^"]+)" y="([^"]+)" z="([^"]+)"', xml)]
    t = [tuple(map(int, m)) for m in
         re.findall(r'<triangle v1="(\d+)" v2="(\d+)" v3="(\d+)"', xml)]
    return v, t


def plate_origin(i, n):
    """Where OrcaSlicer puts plate i of n: a grid of ceil-ish(sqrt(n)) columns, one bed
    plus a fifth apart (its LOGICAL_PART_PLATE_GAP), rows running toward -Y."""
    root = math.sqrt(n)
    cols = int(round(root)) + (1 if root > round(root) else 0)
    return (i % cols) * BED_W * 1.2, -(i // cols) * BED_D * 1.2


def layout(parts):
    """Place each plate's rows inside the bed.  Returns {plate: [(key, x, y)]} in
    bed coordinates, and raises if anything lands outside the margin."""
    placed = []
    for name, rows in PLATES:
        sizes = [[parts[k].bounding_box().size for k in row] for row in rows]
        heights = [max(sz.Y for sz in row) for row in sizes]
        total_h = sum(heights) + PART_GAP * (len(rows) - 1)
        y = total_h / 2
        items = []
        for row, row_sz, h in zip(rows, sizes, heights):
            total_w = sum(sz.X for sz in row_sz) + PART_GAP * (len(row) - 1)
            x = -total_w / 2
            for k, sz in zip(row, row_sz):
                items.append((k, x + sz.X / 2, y - h / 2))
                x += sz.X + PART_GAP
            y -= h + PART_GAP
        for k, x, y in items:
            sz = parts[k].bounding_box().size
            lim_x, lim_y = BED_W / 2 - BED_MARGIN, BED_D / 2 - BED_MARGIN
            if abs(x) + sz.X / 2 > lim_x or abs(y) + sz.Y / 2 > lim_y or sz.Z > BED_H:
                raise ValueError(f"{k} does not fit on plate '{name}'")
        placed.append((name, items))
    return placed


def write_orca_project(parts, path, settings_path):
    """One OrcaSlicer project: every part, on named plates.  Written the way Orca
    2.x writes its own: each object's mesh in 3D/Objects/, the plates in
    Metadata/model_settings.config, the presets in Metadata/project_settings.config."""
    ns = ('xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
          'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" '
          'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" '
          'requiredextensions="p"')
    plates = layout(parts)
    n = len(plates)
    objects, items, rels, cfg_objects, cfg_plates = [], [], [], [], []
    files = {}
    oid = 0
    for pi, (pname, pitems) in enumerate(plates):
        ox, oy = plate_origin(pi, n)
        instances = []
        for k, x, y in pitems:
            oid += 2
            mesh_id, obj_id = oid - 1, oid
            v, t = mesh_of(parts[k])
            bb = parts[k].bounding_box()
            cx, cy, cz = (bb.min.X + bb.max.X) / 2, (bb.min.Y + bb.max.Y) / 2, (bb.min.Z + bb.max.Z) / 2
            fname = f"3D/Objects/{k}_{mesh_id}.model"
            body = "\n".join(f'     <vertex x="{a - cx:.6f}" y="{b - cy:.6f}" z="{c - cz:.6f}"/>' for a, b, c in v)
            tris = "\n".join(f'     <triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in t)
            files[fname] = (f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {ns}>\n'
                            f' <metadata name="BambuStudio:3mfVersion">1</metadata>\n <resources>\n'
                            f'  <object id="{mesh_id}" p:UUID="{uuid.uuid4()}" type="model">\n   <mesh>\n'
                            f'    <vertices>\n{body}\n    </vertices>\n    <triangles>\n{tris}\n    </triangles>\n'
                            f'   </mesh>\n  </object>\n </resources>\n <build/>\n</model>\n')
            rels.append(f' <Relationship Target="/{fname}" Id="rel-{mesh_id}" '
                        f'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>')
            objects.append(f'  <object id="{obj_id}" p:UUID="{uuid.uuid4()}" type="model">\n   <components>\n'
                           f'    <component p:path="/{fname}" objectid="{mesh_id}" p:UUID="{uuid.uuid4()}" '
                           f'transform="1 0 0 0 1 0 0 0 1 0 0 0"/>\n   </components>\n  </object>')
            items.append(f'  <item objectid="{obj_id}" p:UUID="{uuid.uuid4()}" transform="1 0 0 0 1 0 0 0 1 '
                         f'{ox + x:.6f} {oy + y:.6f} {bb.size.Z / 2:.6f}" printable="1"/>')
            label = PART_NAMES.get(k, k)
            cfg_objects.append(
                f'  <object id="{obj_id}">\n    <metadata key="name" value="{label}"/>\n'
                f'    <metadata key="extruder" value="1"/>\n    <part id="{mesh_id}" subtype="normal_part">\n'
                f'      <metadata key="name" value="{label}"/>\n'
                f'      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>\n'
                f'      <metadata key="source_file" value="rodalm_frame.py"/>\n'
                f'      <metadata key="source_object_id" value="0"/>\n      <metadata key="source_volume_id" value="0"/>\n'
                f'      <mesh_stat edges_fixed="0" degenerate_facets="0" facets_removed="0" facets_reversed="0" backwards_edges="0"/>\n'
                f'    </part>\n  </object>')
            instances.append(f'    <model_instance>\n      <metadata key="object_id" value="{obj_id}"/>\n'
                             f'      <metadata key="instance_id" value="0"/>\n'
                             f'      <metadata key="identify_id" value="{1000 + obj_id}"/>\n    </model_instance>')
        cfg_plates.append(f'  <plate>\n    <metadata key="plater_id" value="{pi + 1}"/>\n'
                          f'    <metadata key="plater_name" value="{pname}"/>\n'
                          f'    <metadata key="locked" value="false"/>\n'
                          f'    <metadata key="filament_map_mode" value="Auto For Flush"/>\n'
                          f'    <metadata key="filament_maps" value="1"/>\n' + "\n".join(instances) + '\n  </plate>')
    files["3D/3dmodel.model"] = (
        f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {ns}>\n'
        ' <metadata name="Application">BambuStudio-02.06.00.51</metadata>\n'
        ' <metadata name="OrcaSlicer">2.4.2</metadata>\n'
        ' <metadata name="BambuStudio:3mfVersion">1</metadata>\n'
        ' <metadata name="Title">RÖDALM 4x6 daily dash</metadata>\n'
        ' <metadata name="Description">Generated by daily-dash/rodalm-frame/src/rodalm_frame.py</metadata>\n'
        ' <resources>\n' + "\n".join(objects) + '\n </resources>\n'
        f' <build p:UUID="{uuid.uuid4()}">\n' + "\n".join(items) + '\n </build>\n</model>\n')
    files["3D/_rels/3dmodel.model.rels"] = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        + "\n".join(rels) + '\n</Relationships>\n')
    files["_rels/.rels"] = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        ' <Relationship Target="/3D/3dmodel.model" Id="rel-1" '
        'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>\n</Relationships>\n')
    files["[Content_Types].xml"] = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
        ' <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
        ' <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>\n'
        ' <Default Extension="png" ContentType="image/png"/>\n'
        ' <Default Extension="gcode" ContentType="text/x.gcode"/>\n</Types>\n')
    files["Metadata/model_settings.config"] = (
        '<?xml version="1.0" encoding="UTF-8"?>\n<config>\n' + "\n".join(cfg_objects) + "\n"
        + "\n".join(cfg_plates) + '\n</config>\n')
    files["Metadata/slice_info.config"] = (
        '<?xml version="1.0" encoding="UTF-8"?>\n<config>\n  <header>\n'
        '    <header_item key="X-BBL-Client-Type" value="slicer"/>\n'
        '    <header_item key="X-BBL-Client-Version" value="02.06.00.51"/>\n'
        '    <header_item key="OrcaSlicer-Version" value="2.4.2"/>\n  </header>\n</config>\n')
    if settings_path.exists():
        files["Metadata/project_settings.config"] = settings_path.read_text()
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        order = ["[Content_Types].xml", "_rels/.rels", "3D/3dmodel.model", "3D/_rels/3dmodel.model.rels"]
        for name in order + sorted(k for k in files if k not in order):
            z.writestr(name, files[name])
    return plates


def export(p, coupons, gauge, root):
    out3 = root / "3mf"
    outs = root / "step"
    out3.mkdir(exist_ok=True)
    outs.mkdir(exist_ok=True)
    parts = print_parts(p, coupons, gauge)
    plates = write_orca_project(parts, out3 / "rodalm-frame.3mf",
                                root / "slicer" / "orca_project_settings.config")
    for name in ("mat", "cassette", "lid", "strut"):
        export_step(p[name], str(outs / f"rodalm-{name}.step"))
    m = mocks()
    asm = Compound(children=[p["mat"], p["cassette"], p["lid"], p["strut"], m["glass"], m["carrier"],
                             m["driver"], m["charger"], m["cell"], m["usb"], m["adapter"], m["moulding"],
                             m["cover"]])
    export_step(asm, str(outs / "rodalm-assembly.step"))
    return plates


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    print(params_text())
    if mode == "params":
        return 0
    p = build()
    bodies = {k: len(v.solids()) for k, v in p.items()}
    m = mocks()
    rows = run_checks(p, m)
    print("\nbodies:", ", ".join(f"{k} {n}" for k, n in bodies.items()))
    bad = [r for r in rows if not r[2]] + [(k, n, False, "1 body") for k, n in bodies.items() if n != 1]
    print(f"\n{len(rows)} interference checks:")
    for name, v, ok, expect in rows:
        print(f"  {'ok ' if ok else 'BAD'} {name:<34} {v:9.3f} mm3   (expect {expect})")
    if mode == "check":
        return 1 if bad else 0
    coupons = make_coupons(p["mat"], p["cassette"])
    gauge = make_gauge()
    for name, s in (("coupon_mat", coupons[0]), ("coupon_cassette", coupons[1]), ("gauge", gauge)):
        n = len(s.solids())
        print(f"  {name}: {n} body" + ("" if n == 1 else "  <-- BAD"))
        if n != 1:
            bad.append((name, n, False, "1 body"))
    root = Path(__file__).resolve().parent.parent
    plates = export(p, coupons, gauge, root)
    print("\n3mf/rodalm-frame.3mf, one OrcaSlicer project:")
    for i, (name, items) in enumerate(plates, 1):
        print(f"  plate {i}: {name:<34} " + ", ".join(f"{k} ({x:+.0f}, {y:+.0f})" for k, x, y in items))
    print("exported 3MF + STEP to", root)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
