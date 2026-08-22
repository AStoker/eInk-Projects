#!/usr/bin/env python3
"""Generate dimensioned drawing sheets from the OpenSCAD model's own parameters.

Reads /tmp/params.txt (produced by `openscad -D 'part="params"'`) so the drawings
can never drift from the STLs.  Emits one SVG fragment per sheet.
"""
import math, os, json

P = {}
for line in open(os.environ.get("PARAMS", "/tmp/params.txt")):
    line = line.strip()
    if not line or "=" not in line:
        continue
    k, v = line.split("=", 1)
    try:
        P[k] = float(v)
    except ValueError:
        P[k] = v

# ----------------------------------------------------------------- svg utils
AR = 1.6           # arrowhead length
TS = 3.0           # default text size
out = []


def esc(s):
    return (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            .replace("\u00b7", "&#183;").replace("\u2264", "&#8804;")
            .replace("\u00b0", "&#176;").replace("\u00d7", "&#215;"))


def n(v):
    """format a number the way a drawing would"""
    if abs(v - round(v)) < 0.005:
        return f"{v:.0f}"
    return f"{v:.2f}".rstrip("0").rstrip(".")


class SVG:
    def __init__(self, w, h):
        self.w, self.h, self.b = w, h, []

    def add(self, s):
        self.b.append(s)

    def line(self, x1, y1, x2, y2, cls="edge"):
        self.add(f'<line class="{cls}" x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}"/>')

    def rect(self, x, y, w, h, cls="edge", r=0):
        self.add(f'<rect class="{cls}" x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" '
                 f'height="{h:.2f}" rx="{r:.2f}"/>')

    def circ(self, x, y, d, cls="edge"):
        self.add(f'<circle class="{cls}" cx="{x:.2f}" cy="{y:.2f}" r="{d/2:.2f}"/>')

    def path(self, d, cls="edge"):
        self.add(f'<path class="{cls}" d="{d}"/>')

    def txt(self, x, y, s, cls="lbl", anchor="middle", size=TS, rot=None):
        tr = f' transform="rotate({rot} {x:.2f} {y:.2f})"' if rot else ""
        self.add(f'<text class="{cls}" x="{x:.2f}" y="{y:.2f}" text-anchor="{anchor}" '
                 f'font-size="{size}"{tr}>{esc(s)}</text>')

    # --- dimensioning -----------------------------------------------------
    def _ah(self, x, y, dx, dy):
        """arrowhead at (x,y) pointing along (dx,dy)"""
        m = math.hypot(dx, dy) or 1
        dx, dy = dx / m, dy / m
        px, py = -dy, dx
        return (f'M{x:.2f},{y:.2f} L{x-dx*AR+px*AR*0.32:.2f},{y-dy*AR+py*AR*0.32:.2f} '
                f'L{x-dx*AR-px*AR*0.32:.2f},{y-dy*AR-py*AR*0.32:.2f} Z')

    def dimh(self, x1, x2, y, label=None, ext_from=None, flip=False):
        if label is None:
            label = n(abs(x2 - x1))
        if ext_from is not None:
            for x in (x1, x2):
                self.line(x, ext_from, x, y + (1.2 if y > ext_from else -1.2), "ext")
        self.line(x1, y, x2, y, "dim")
        inside = abs(x2 - x1) > 9
        if inside:
            self.path(self._ah(x1, y, x1 - x2, 0), "arrow")
            self.path(self._ah(x2, y, x2 - x1, 0), "arrow")
        else:
            self.line(x1 - 4, y, x1, y, "dim")
            self.line(x2, y, x2 + 4, y, "dim")
            self.path(self._ah(x1, y, 1, 0), "arrow")
            self.path(self._ah(x2, y, -1, 0), "arrow")
        tx = (x1 + x2) / 2
        if inside:
            self.txt(tx, y - 1.3, label, "dimtxt")
        else:
            self.txt(tx, y - 1.6 if not flip else y + 3.4, label, "dimtxt")

    def dimv(self, y1, y2, x, label=None, ext_from=None):
        if label is None:
            label = n(abs(y2 - y1))
        if ext_from is not None:
            for y in (y1, y2):
                self.line(ext_from, y, x + (1.2 if x > ext_from else -1.2), y, "ext")
        self.line(x, y1, x, y2, "dim")
        inside = abs(y2 - y1) > 9
        if inside:
            self.path(self._ah(x, y1, 0, y1 - y2), "arrow")
            self.path(self._ah(x, y2, 0, y2 - y1), "arrow")
        else:
            self.line(x, y1 - 4, x, y1, "dim")
            self.line(x, y2, x, y2 + 4, "dim")
            self.path(self._ah(x, y1, 0, 1), "arrow")
            self.path(self._ah(x, y2, 0, -1), "arrow")
        self.txt(x - 1.3, (y1 + y2) / 2, label, "dimtxt", rot=-90)

    def leader(self, x, y, tx, ty, label, anchor="start"):
        self.line(x, y, tx, ty, "dim")
        self.path(self._ah(x, y, x - tx, y - ty), "arrow")
        off = 1.2 if anchor == "start" else -1.2
        self.txt(tx + off, ty + 1.0, label, "note", anchor)

    def note(self, x, y, label, anchor="start", size=2.7):
        self.txt(x, y, label, "note", anchor, size)

    def hatch(self, x, y, w, h, step=1.6):
        self.add(f'<g class="hatch" clip-path="url(#c{abs(hash((x,y,w,h)))%99999})">')
        self.add(f'<clipPath id="c{abs(hash((x,y,w,h)))%99999}">'
                 f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}"/></clipPath>')
        k = -h
        while k < w:
            self.line(x + k, y + h, x + k + h, y, "hl")
            k += step
        self.add('</g>')

    def titleblock(self, x, y, w, h, name, sheet, of, scale, rev="E"):
        self.txt(x, y - 2.4, "STLs export flat-face-down and MIRRORED IN X "
                             "(print_mirror = true)", "note", "start", 2.35)
        self.rect(x, y, w, h, "tbframe")
        self.line(x, y + h * 0.5, x + w, y + h * 0.5, "tbrule")
        self.line(x + w * 0.55, y + h * 0.5, x + w * 0.55, y + h, "tbrule")
        self.line(x + w * 0.78, y + h * 0.5, x + w * 0.78, y + h, "tbrule")
        self.txt(x + 2, y + h * 0.34, name, "tbname", "start", 3.6)
        self.txt(x + 2, y + h * 0.85, f"UNITS mm · SCALE {scale}", "tbmeta", "start", 2.4)
        self.txt(x + w * 0.575, y + h * 0.85, f"SHEET {sheet}/{of}", "tbmeta", "start", 2.4)
        self.txt(x + w * 0.80, y + h * 0.85, f"REV {rev}", "tbmeta", "start", 2.4)


    def bal(self, x, y, num, tx, ty):
        self.line(x, y, tx, ty, "dim")
        self.path(self._ah(x, y, x - tx, y - ty), "arrow")
        self.circ(tx, ty, 5.6, "balloon")
        self.txt(tx, ty + 1.15, str(num), "baltxt", size=3.1)

    def notes(self, x, y, items, cw=46, title="NOTES"):
        import textwrap
        if title:
            self.txt(x, y, title, "vlabel", "start", 3.2)
            y += 6.5
        for num, text in items:
            self.circ(x + 2.8, y - 1.0, 5.6, "balloon")
            self.txt(x + 2.8, y + 0.15, str(num), "baltxt", size=3.1)
            lines = textwrap.wrap(text, cw) or [""]
            for j, ln in enumerate(lines):
                self.txt(x + 9, y + j * 3.7, ln, "note", "start", 2.7)
            y += max(1, len(lines)) * 3.7 + 2.8
        return y

    def render(self, ident):
        return (f'<svg class="dwg" id="{ident}" viewBox="0 0 {self.w} {self.h}" '
                f'xmlns="http://www.w3.org/2000/svg" role="img">'
                + "".join(self.b) + "</svg>")


# ------------------------------------------------------------------ geometry
W, H, D = P["W"], P["H"], P["depth"]
cav_x0, cav_x1 = P["cav_x0"], P["cav_x1"]
cav_z0, cav_z1 = P["cav_z0"], P["cav_z1"]
cav_w, cav_h = P["cav_w"], P["cav_h"]
Zc, hub_z = P["Zc"], P["hub_z"]
win_w, win_h = P["win_w"], P["win_h"]
SW, SH = 268, 190
TBX, TBY = SW - 96 - 6, SH - 18 - 5

def mk(w=SW, h=SH):
    return SVG(w, h)

def views(s, ox, oy):
    return (lambda x: ox + x + W/2), (lambda z: oy + (H - z))

# ============================================================ SHEET 1
def sheet1():
    s = mk()
    oy = 15
    fx, fz = views(s, 24, oy)

    s.rect(fx(-W/2), fz(H), W, H, "part", P["corner_r"])
    s.rect(fx(-win_w/2), fz(Zc + win_h/2), win_w, win_h, "edge", 3)
    s.rect(fx(-P["act_w"]/2), fz(Zc + P["act_h"]/2), P["act_w"], P["act_h"], "ink")
    s.rect(fx(P["pcb_px"]-P["pcb_w"]/2), fz(Zc+P["pcb_h"]/2), P["pcb_w"], P["pcb_h"], "hid")
    s.line(fx(0), fz(H)-4, fx(0), fz(0)+4, "cl")
    s.line(fx(-W/2)-4, fz(Zc), fx(W/2)+4, fz(Zc), "cl")
    s.txt(fx(0), fz(H)-8, "FRONT", "vlabel")
    s.dimh(fx(-W/2), fx(W/2), fz(0)+16, n(W), ext_from=fz(0))
    s.dimv(fz(H), fz(0), fx(-W/2)-13, n(H), ext_from=fx(-W/2))
    s.dimh(fx(-win_w/2), fx(win_w/2), fz(0)+8, n(win_w), ext_from=fz(Zc-win_h/2))
    s.dimv(fz(Zc+win_h/2), fz(Zc-win_h/2), fx(-W/2)-5, n(win_h), ext_from=fx(-win_w/2))
    s.dimh(fx(-W/2), fx(-win_w/2), fz(H)-5, n(W/2-win_w/2), ext_from=fz(Zc+win_h/2))
    s.dimh(fx(win_w/2), fx(W/2), fz(H)-5, n(W/2-win_w/2), ext_from=fz(Zc+win_h/2))
    s.dimv(fz(H), fz(Zc+win_h/2), fx(W/2)+6, n(H/2-win_h/2), ext_from=fx(win_w/2))
    s.dimv(fz(Zc-win_h/2), fz(0), fx(W/2)+6, n(H/2-win_h/2), ext_from=fx(win_w/2))
    s.bal(fx(-win_w/2+0.7), fz(Zc+win_h/2-4), 1, fx(-win_w/2-6), fz(Zc+win_h/2+7))
    s.bal(fx(-W/2+2.4), fz(2.4), 2, fx(-W/2+11), fz(11))

    # side
    sx = 124
    yx = lambda y: sx + y
    s.rect(yx(0), fz(H), D, H, "part")
    s.line(yx(P["body_d"]), fz(H), yx(P["body_d"]), fz(0), "hid")
    ch, rc = P["front_chf"], P["rear_chf"]
    s.line(yx(0), fz(H)+ch, yx(ch), fz(H), "edge")
    s.line(yx(0), fz(0)-ch, yx(ch), fz(0), "edge")
    s.line(yx(D-rc), fz(H), yx(D), fz(H)+rc, "edge")
    s.line(yx(D-rc), fz(0), yx(D), fz(0)-rc, "edge")
    s.rect(yx(P["flash_y0"]), fz(H), P["flash_y1"]-P["flash_y0"], 1.6, "cut")
    s.rect(yx(D-1.0), fz(P["ucb_z"]+P["port_h"]/2), 1.0, P["port_h"], "cut")
    s.txt(yx(D/2), fz(H)-8, "RIGHT", "vlabel")
    s.dimh(yx(0), yx(D), fz(0)+16, n(D), ext_from=fz(0))
    s.bal(yx(D-rc/2), fz(H)+rc/2, 3, yx(D)+9, fz(H)-6)
    s.bal(yx(ch/2), fz(0)-ch/2, 4, yx(D)+9, fz(0)+8)
    s.bal(yx((P["flash_y0"]+P["flash_y1"])/2), fz(H)+0.8, 5, yx(D)+9, fz(H)+9)
    s.bal(yx(D), fz(P["ucb_z"]), 6, yx(D)+9, fz(P["ucb_z"])+2)
    s.bal(yx(P["body_d"]), fz(30), 7, yx(D)+9, fz(30))

    # back
    bx = 156
    gx = lambda x: bx + x + W/2
    s.rect(gx(-W/2), fz(H), W, H, "part", P["corner_r"])
    s.circ(gx(0), fz(hub_z), P["disc_d"], "edge")
    s.circ(gx(0), fz(hub_z), P["pk_d"]+2*P["lug_out"], "hid")
    s.rect(gx(P["ucb_x"]-P["port_w"]/2), fz(P["ucb_z"]+P["port_h"]/2), P["port_w"], P["port_h"], "cut", 1.2)
    for z in (P["scr_z0"], P["scr_z1"], P["scr_z2"]):
        s.circ(gx(P["scr_x"]), fz(z), P["scr_head"], "cut")
    s.line(gx(0), fz(H)-4, gx(0), fz(0)+4, "cl")
    s.line(gx(-W/2)-4, fz(hub_z), gx(W/2)+4, fz(hub_z), "cl")
    s.txt(gx(0), fz(H)-8, "BACK", "vlabel")
    s.dimv(fz(hub_z), fz(0), gx(-W/2)-8, n(hub_z), ext_from=gx(-W/2))
    s.dimh(gx(0), gx(P["ucb_x"]), fz(0)+8, n(abs(P["ucb_x"])), ext_from=fz(P["ucb_z"]))
    s.dimv(fz(P["ucb_z"]), fz(0), gx(P["ucb_x"])-8, n(P["ucb_z"]), ext_from=gx(P["ucb_x"]))
    s.dimh(gx(P["scr_x"]), gx(W/2), fz(H)-5, n(W/2-P["scr_x"]), ext_from=fz(P["scr_z2"]))
    s.bal(gx(P["ucb_x"]+P["port_w"]/2), fz(P["ucb_z"]), 6, gx(P["ucb_x"]+16), fz(P["ucb_z"])-8)
    s.bal(gx(P["scr_x"]), fz(P["scr_z1"]), 8, gx(P["scr_x"])-11, fz(P["scr_z1"])+8)
    s.bal(gx(P["disc_d"]/2*0.71), fz(hub_z+P["disc_d"]/2*0.71), 9, gx(P["disc_d"]/2*0.71)+7, fz(hub_z+P["disc_d"]/2*0.71)-7)

    y = s.notes(22, 143, [
        (1, f"panel white border {n(P['white_show'])} visible all round the ink"),
        (2, f"outer corners R{n(P['corner_r'])}"),
        (3, f"{n(rc)} x 45 deg chamfer on all four back edges. It moves the contact edge forward - see sheet 7"),
        (4, f"{n(ch)} x 45 deg chamfer on the front face"),
    ], cw=44)
    s.notes(108, 143, [
        (5, f"USB-C flash port, {n(P['usb_w'])} wide, top wall (driver board)"),
        (6, f"USB-C charge port {n(P['port_w'])} x {n(P['port_h'])}, back face"),
        (7, "frame / cover seam"),
    ], cw=44, title=" ")
    s.notes(190, 143, [
        (8, f"3 x M2.5 cover screws, {n(P['scr_x'])} from the centreline"),
        (9, f"kickstand disc, dia {n(P['disc_d'])}, hub {n(hub_z)} up from the bottom"),
    ], cw=40, title=" ")
    s.titleblock(TBX, TBY, 96, 18, "ASSEMBLY / ENVELOPE", 1, 8, "1:1")
    return s.render("s1")


# ============================================================ SHEET 2
def sheet2():
    s = mk()
    ox, oy = 28, 14
    fx, fz = views(s, ox, oy)
    s.rect(fx(-W/2), fz(H), W, H, "ghost", P["corner_r"])
    s.rect(fx(cav_x0), fz(cav_z1), cav_w, cav_h, "part", P["cav_r"])
    s.circ(fx(0), fz(hub_z), P["pk_d"]+2*P["lug_out"]+6, "hid")

    # ---- the cell, bottom band, centred
    bx0, bz0 = P["bat_x0"], P["bat_cz"]-P["bat_h"]/2
    s.rect(fx(bx0), fz(bz0+P["bat_h"]), P["bat_w"], P["bat_h"], "cell", 2)
    s.txt(fx(P["bat_cx"]), fz(P["bat_cz"])-1.4, "LiPo 2000 mAh  ·  694449", "cmp", size=3.0)
    s.txt(fx(P["bat_cx"]), fz(P["bat_cz"])+2.6,
          f"{n(P['bat_w'])} x {n(P['bat_h'])} x {n(P['bat_t'])}", "cmpsub", size=2.6)
    s.txt(fx(P["bat_cx"]), fz(P["bat_cz"])+6.2, "red +  ·  black -  ·  yellow NTC", "cmpsub", size=2.25)
    for sx in (-1, 1):   # X fences
        s.rect(fx(P["bat_cx"]+sx*(P["bat_w"]/2+P["bat_clr"]) - (0 if sx>0 else P["bat_fence"])),
               fz(bz0+P["bat_h"]), P["bat_fence"], P["bat_h"], "boss")

    # ---- top band: Perma-Proto (-X) then driver board (+X)
    px0, pz0 = P["proto_x0"], P["proto_z0"]
    s.rect(fx(px0), fz(P["proto_z1"]), P["proto_w"], P["proto_h"], "pcb", 1.5)
    s.txt(fx(P["proto_cx"]), fz(P["proto_z1"]-13.5), "PERMA-PROTO", "cmp", size=3.0)
    s.txt(fx(P["proto_cx"]), fz(P["proto_z1"]-17.5),
          f"quarter {n(P['proto_w'])} x {n(P['proto_h'])}", "cmpsub", size=2.6)
    s.rect(fx(P["chg_x"]-P["chg_w"]/2), fz(P["chg_z"]+P["chg_h"]/2), P["chg_w"], P["chg_h"], "chg", 1)
    s.txt(fx(P["chg_x"]), fz(P["chg_z"])-0.6, P["chg_part"], "cmp", size=2.8)
    s.txt(fx(P["chg_x"]), fz(P["chg_z"])+3.0, f"{n(P['chg_w'])} x {n(P['chg_h'])}", "cmpsub", size=2.5)
    for sz in (-1, 1):
        s.circ(fx(P["proto_cx"]), fz(P["proto_cz"]+sz*P["proto_hole_sp"]/2), 3.2, "cut")

    s.rect(fx(P["drv_x0"]), fz(P["drv_z1"]), P["drv_w"], P["drv_h"], "pcb", 1.5)
    s.txt(fx(P["drv_cx"]), fz(P["drv_cz"])-3.4, "WAVESHARE", "cmp", size=2.9)
    s.txt(fx(P["drv_cx"]), fz(P["drv_cz"])+0.2, "ESP32 DRIVER", "cmp", size=2.9)
    s.txt(fx(P["drv_cx"]), fz(P["drv_cz"])+3.8, f"{n(P['drv_w'])} x {n(P['drv_h'])}", "cmpsub", size=2.6)
    s.rect(fx(P["flash_x"]-4.5), fz(P["drv_z1"]+2.6), 9, 1.4, "cut")   # flash port, top wall
    for sx in (-1, 1):   # driver rails
        rc = P["drv_cx"] + sx*(P["drv_w"]/2 + P["drv_clr"] + P["drv_rail"]/2 - 1.0)
        s.rect(fx(rc-P["drv_rail"]/2), fz(P["drv_cz"]+(P["drv_h"]-1)/2),
               P["drv_rail"], P["drv_h"]-1, "boss")

    # ---- module retention pads, in the strips either side of the cell
    for (px, pz) in ((P["pad_x0"], P["pad_z0"]), (P["pad_x1"], P["pad_z1"])):
        s.rect(fx(px-P["pad_w"]/2), fz(pz+P["pad_h"]/2), P["pad_w"], P["pad_h"], "pad", 0.8)
    s.rect(fx(P["ucb_x"]-P["ucb_w"]/2), fz(P["ucb_z"]+2.6), P["ucb_w"], 5.2, "chg", 0.8)
    # module 8-pin header keep-out - assumed position, MEASURE IT
    s.rect(fx(P["conn_x"]-P["conn_w"]/2), fz(P["conn_z"]+P["conn_l"]/2),
           P["conn_w"], P["conn_l"], "warn")
    s.hatch(fx(P["conn_x"]-P["conn_w"]/2), fz(P["conn_z"]+P["conn_l"]/2),
            P["conn_w"], P["conn_l"], step=2.0)

    # ---- dimensions ------------------------------------------------------
    y1, y2, y3 = 128, 136.5, 145
    s.dimh(fx(cav_x0), fx(bx0), y1, n(bx0-cav_x0), ext_from=fz(bz0))
    s.dimh(fx(bx0), fx(bx0+P["bat_w"]), y1, n(P["bat_w"]), ext_from=fz(bz0))
    s.dimh(fx(bx0+P["bat_w"]), fx(cav_x1), y1, n(cav_x1-bx0-P["bat_w"]), ext_from=fz(bz0))
    s.dimh(fx(px0), fx(P["proto_x1"]), y2, n(P["proto_w"]), ext_from=fz(pz0))
    s.dimh(fx(P["proto_x1"]), fx(P["drv_x0"]), y2, n(P["drv_x0"]-P["proto_x1"]), ext_from=fz(pz0))
    s.dimh(fx(P["drv_x0"]), fx(P["drv_x1"]), y2, n(P["drv_w"]), ext_from=fz(P["drv_z0"]))
    s.dimh(fx(cav_x0), fx(cav_x1), y3, n(cav_w), ext_from=fz(cav_z0))

    s.dimv(fz(P["proto_z1"]), fz(pz0), 22, n(P["proto_h"]), ext_from=fx(px0))
    s.dimv(fz(P["ucb_z"]), fz(0), 22, n(P["ucb_z"]), ext_from=fx(P["ucb_x"]))
    s.dimv(fz(P["drv_z1"]), fz(P["drv_z0"]), 114, n(P["drv_h"]), ext_from=fx(P["drv_x1"]))
    s.dimv(fz(bz0+P["bat_h"]), fz(bz0), 114, n(P["bat_h"]), ext_from=fx(bx0+P["bat_w"]))
    s.dimv(fz(cav_z1), fz(cav_z0), 124, n(cav_h), ext_from=fx(cav_x1))

    # ---- balloons --------------------------------------------------------
    s.bal(fx(P["ucb_x"]), fz(P["ucb_z"]), 1, 9, fz(P["ucb_z"])+9)
    s.bal(fx(P["pad_x1"]), fz(P["pad_z1"]), 2, 133, 100)
    s.bal(fx(0)+(P["pk_d"]/2)*0.60, fz(hub_z)+(P["pk_d"]/2)*0.80, 3, 132, 119)
    s.bal(fx(P["proto_cx"]), fz(P["proto_cz"]+P["proto_hole_sp"]/2), 4, 12, fz(P["proto_cz"]+P["proto_hole_sp"]/2)+3)
    s.bal(fx(P["chg_x"]-P["chg_w"]/2+2), fz(P["chg_z"]+P["chg_h"]/2-2), 5, 10, 46)
    s.bal(fx(P["drv_x1"]-P["drv_rail"]/2), fz(P["drv_cz"]+16), 6, 132, 40)
    s.bal(fx(P["conn_x"]+P["conn_w"]/2), fz(P["conn_z"]), 7, 133, 113)
    s.txt(fx(0), 9, "LOOKING INTO THE OPEN BACK", "vlabel")

    clash = P["conn_h"] - (P["cov_in_pk"] - P["bat_t"] - P["mod_back"])
    y = s.notes(150, 20, [
        (1, "USB-C charge breakout, on edge in printed rails, receptacle flush with the back cover. Two wires up the -X wall to the bq24074"),
        (2, f"module retention pads {n(P['pad_w'])} x {n(P['pad_h'])}, one each side of the cell. Foam tape on the faces takes up the tolerance stack"),
        (3, f"stand puck, dia {n(P['pk_d']+2*P['lug_out']+6)}, bulges {n(P['depth']-P['cov_in_pk'])} into the interior behind everything on this sheet"),
        (4, f"2 x M2.5 posts, {n(P['proto_hole_sp'])} apart, behind the Perma-Proto; the bq24074 rides on its front face"),
        (5, f"{P['chg_part']} charger breakout {n(P['chg_w'])} x {n(P['chg_h'])} x {n(P['chg_t'])}, low end of the Perma-Proto, nearest the charge port"),
        (6, f"driver-board rails {n(P['drv_rail'])} wide, overlapping the PCB {n(P['drv_rail']-1)} each side"),
        (7, f"MODULE 8-PIN HEADER KEEP-OUT {n(P['conn_w'])} x {n(P['conn_l'])} x {n(P['conn_h'])} deep, position ASSUMED. Clashes with the cell by {n(clash)} - DO NOT PRINT, see below"),
    ], cw=56)

    s.notes(150, y+2, [], title="MEASURE BEFORE YOU PRINT")
    ty = y + 8
    need = P["conn_h"] + P["bat_t"] + P["mod_back"] + 5.95 + 0.5
    s.txt(150, ty, "Three numbers on the module settle this sheet:", "note", "start", 2.65)
    for i, (lab, par) in enumerate([
        ("a   header edge, and where across X", "conn_dz, conn_dx"),
        ("b   header stand-off, mated, with the bend", f"conn_h  (assumed {n(P['conn_h'])})"),
        ("c   is the glass centred on the PCB in Z?", "pan_off_z, act_off_z"),
    ]):
        yy = ty + 6.5 + i*7.4
        s.txt(150, yy, lab, "note", "start", 2.65)
        s.txt(157, yy + 3.7, par, "val", "start", 2.65)
    for i, t in enumerate([
        f"The board band clears a {n(P['conn_h'])} mm header ({n(P['proto_face']-P['mod_back'])} available);",
        f"the cell band does not ({n(P['cov_in_pk']-P['bat_t']-P['mod_back'])}). If the header is on",
        "the cell's edge the two bands swap, which also",
        "moves the flash port to the opposite wall. Or",
        f"keep this layout and set depth = {n(need)}.",
    ]):
        s.txt(150, ty + 30 + i*3.8, t, "note", "start", 2.65)
    s.titleblock(TBX, TBY, 96, 18, "INTERNAL LAYOUT", 2, 8, "1:1")
    return s.render("s2")


# ============================================================ SHEET 3
def sheet3():
    s = mk()
    SC = 5.2
    ox, oy = 24, 30
    ys = lambda y: ox + y*SC
    zs = lambda z: oy + (100 - z)*1.02
    top, bot = zs(100), zs(0)

    s.rect(ys(0), top, P["front_t"]*SC, bot-top, "part"); s.hatch(ys(0), top, P["front_t"]*SC, bot-top)
    s.rect(ys(P["cov_in"]), top, P["cover_t"]*SC, bot-top, "part"); s.hatch(ys(P["cov_in"]), top, P["cover_t"]*SC, bot-top)
    s.rect(ys(P["cov_in_pk"]), zs(78), (D-P["cov_in_pk"])*SC, zs(20)-zs(78), "part")
    s.hatch(ys(P["cov_in_pk"]), zs(78), (P["pk_y0"]-P["cov_in_pk"])*SC, zs(20)-zs(78))
    s.rect(ys(P["pk_y0"]), zs(74), P["pk_dep"]*SC, zs(24)-zs(74), "voidfill")
    s.txt(ys(P["pk_y0"]+P["pk_dep"]/2), zs(49), "stand", "note", size=2.5)
    s.txt(ys(P["pk_y0"]+P["pk_dep"]/2), zs(45.5), "pocket", "note", size=2.5)

    s.rect(ys(P["front_t"]), zs(96), P["pan_t"]*SC, zs(14)-zs(96), "glass")
    s.rect(ys(P["pcb_face_y"]), zs(98), P["pcb_t"]*SC, zs(12)-zs(98), "pcb")
    clr = P["cov_in_pk"] - P["bat_t"] - P["mod_back"]
    s.rect(ys(P["mod_back"]), zs(62), P["conn_h"]*SC, zs(44)-zs(62), "warn")
    s.txt(ys(P["mod_back"]+clr/2), zs(51.5), "8-pin", "cmp", size=2.6)
    s.txt(ys(P["mod_back"]+clr/2), zs(48), "header", "cmp", size=2.6)

    s.rect(ys(P["cov_in_pk"]-P["bat_t"]), zs(74), P["bat_t"]*SC, zs(38)-zs(74), "cell")
    s.txt(ys(P["cov_in_pk"]-P["bat_t"]/2), zs(55), "cell", "cmp", size=2.6, rot=-90)
    s.rect(ys(P["cov_in_pk"]-P["bat_t"]), zs(62), (P["conn_h"]-clr)*SC, zs(44)-zs(62), "clash")
    s.txt(ys(P["mod_back"]+P["conn_h"]/2), zs(66.5), f"CLASH {n(P['conn_h']-clr)}", "clashtxt", size=2.8)
    s.rect(ys(P["proto_face"]), zs(32), P["proto_t"]*SC, zs(10)-zs(32), "pcb")
    s.rect(ys(P["proto_face"]-P["chg_t"]+P["proto_t"]), zs(28), (P["chg_t"]-P["proto_t"])*SC, zs(14)-zs(28), "chg")
    s.txt(ys(P["proto_face"]-P["chg_t"]/2), zs(20), f"{P['chg_part']} stack {n(P['chg_t'])}", "cmp", size=2.6)

    lad = bot+9
    s.dimh(ys(0), ys(D), lad+17, n(D), ext_from=bot)
    s.dimh(ys(0), ys(P["front_t"]), lad, n(P["front_t"]), ext_from=bot, flip=True)
    s.dimh(ys(P["front_t"]), ys(P["mod_back"]), lad, n(P["mod_back"]-P["front_t"]), ext_from=bot)
    s.dimh(ys(P["mod_back"]), ys(P["cov_in_pk"]-P["bat_t"]), lad+8.5, n(P["cov_in_pk"]-P["bat_t"]-P["mod_back"]), ext_from=bot)
    s.dimh(ys(P["cov_in_pk"]), ys(D), lad, n(D-P["cov_in_pk"]), ext_from=bot)
    s.txt(ys(D/2), 16, "SECTION A-A  ·  depth axis magnified x5.2", "vlabel")

    cx = 158
    s.txt(cx, 24, "DEPTH BUDGET", "vlabel", "start", 3.2)
    rows = [
        ("front face to module back", P["mod_back"], False),
        ("clear in front of the cell", P["cov_in_pk"]-P["bat_t"]-P["mod_back"], True),
        ("clear in front of proto PCB", P["proto_face"]-P["mod_back"], False),
        (f"...less the {P['chg_part']} stack", P["proto_face"]-P["chg_t"]+P["proto_t"]-P["mod_back"], False),
        ("clear in front of driver PCB", P["drv_back"]-P["drv_t"]-P["mod_back"], False),
        ("interior, outside the pocket", P["cov_in"]-P["mod_back"], False),
        ("interior, over the pocket", P["cov_in_pk"]-P["mod_back"], False),
        ("total depth", D, False),
    ]
    for i, (lab, v, warn) in enumerate(rows):
        y = 30 + i*6.9
        s.txt(cx, y, lab, "note", "start", 2.75)
        s.txt(cx+86, y, n(v), "val"+(" warn" if warn else ""), "end", 3.3)
        s.line(cx, y+2.4, cx+86, y+2.4, "tbrule")
    y0 = 30+len(rows)*6.9+6
    s.txt(cx, y0, "THE TIGHT ONE", "vlabel", "start", 3.2)
    clr = P["cov_in_pk"] - P["bat_t"] - P["mod_back"]
    need = P["conn_h"] + P["bat_t"] + P["mod_back"] + 5.95 + 0.5
    for i, t in enumerate([
        f"A mated vertical PH2.0 plug plus a wire bend is",
        f"8-9 mm. Over the boards there is {n(P['proto_face']-P['mod_back'])} and it fits.",
        f"Over the cell there is {n(clr)} and it does not - the",
        f"keep-out overruns the cell face by {n(P['conn_h']-clr)}.",
        "",
        "Three ways out. Which is right depends on where",
        "the header actually is - measure it, see sheet 2:",
    ]):
        s.txt(cx, y0+7+i*3.9, t, "note", "start", 2.65)
    oy2 = y0 + 7 + 7*3.9 + 3
    for num, lines in [
        ("1", ["put the boards in whichever band the header",
               "lands in, cell in the other. No thickness cost,",
               "but it moves the flash port to the far wall and",
               "the charge port out of the board band."]),
        ("2", ["right-angle PH2.0 housing, or desolder the",
               f"header and lay the eight wires flat. Keeps",
               f"depth {n(D)}; needs conn_h <= {n(clr-0.5)}."]),
        ("3", [f"set depth = {n(need)} and re-export. Everything",
               f"downstream follows, at +{n(need-D)} mm thickness."]),
    ]:
        s.txt(cx, oy2, num, "val", "start", 2.65)
        for j, ln in enumerate(lines):
            s.txt(cx+5, oy2 + j*3.9, ln, "note", "start", 2.65)
        oy2 += len(lines)*3.9 + 2.6
    s.titleblock(TBX, TBY, 96, 18, "DEPTH STACK-UP", 3, 8, "SEE NOTE")
    return s.render("s3")


# ============================================================ SHEET 4
def sheet4():
    s = mk()
    ox, oy = 16, 24
    fx, fz = views(s, ox, oy)
    s.rect(fx(-W/2), fz(H), W, H, "part", P["corner_r"])
    s.rect(fx(-win_w/2), fz(Zc+win_h/2), win_w, win_h, "cut", 3)
    s.rect(fx(cav_x0), fz(cav_z1), cav_w, cav_h, "hid", P["cav_r"])
    for sx in (-1, 1):
        for sz in (-1, 1):
            s.circ(fx(P["pcb_px"]+sx*cav_w/2), fz(Zc+sz*cav_h/2), 2*P["cav_rel"], "hid")
    pw = P["pan_w"] + 2*P["pan_clr_w"];  ph = P["pan_h"] + 2*P["pan_clr_h"]
    px0 = P["pan_px"] - pw/2;  pz1 = Zc + ph/2
    s.rect(fx(px0), fz(pz1), pw, ph, "hid", P["pan_r"])
    for sx in (-1, 1):
        for sz in (-1, 1):
            s.circ(fx(P["pan_px"]+sx*pw/2), fz(Zc+sz*ph/2), 2*P["pan_rel"], "hid")
    s.rect(fx(px0-P["rib_clr"]), fz(P["rib_cz"]+P["rib_w"]/2), P["rib_clr"], P["rib_w"], "cut")
    s.dimv(fz(Zc-ph/2), fz(P["rib_cz"]-P["rib_w"]/2), fx(px0)-6, n(P["rib_off"]), ext_from=fx(px0))
    s.dimv(fz(P["rib_cz"]+P["rib_w"]/2), fz(P["rib_cz"]-P["rib_w"]/2), fx(px0)-14, n(P["rib_w"]), ext_from=fx(px0-P["rib_clr"]))
    s.dimv(fz(Zc+ph/2), fz(P["rib_cz"]+P["rib_w"]/2), fx(px0)-6, n(P["rib_far"]), ext_from=fx(px0))
    for z in (P["scr_z0"], P["scr_z1"], P["scr_z2"]):
        s.circ(fx(P["scr_x"]), fz(z), P["scr_pilot"], "cut")
    s.rect(fx(P["flash_x"]-P["usb_w"]/2), fz(H), P["usb_w"], H-cav_z1, "cut")
    s.txt(fx(0), fz(H)-14, "FRAME  ·  view on the open back", "vlabel")
    s.dimh(fx(-W/2), fx(W/2), fz(0)+15, n(W), ext_from=fz(0))
    s.dimv(fz(H), fz(0), fx(-W/2)-12, n(H), ext_from=fx(-W/2))
    s.dimh(fx(cav_x0), fx(cav_x1), fz(cav_z1)-4, n(cav_w), ext_from=fz(cav_z1))
    s.dimv(fz(cav_z1), fz(cav_z0), fx(cav_x1)+13, n(cav_h), ext_from=fx(cav_x1))
    s.dimh(fx(-W/2), fx(cav_x0), fz(0)+7, n(cav_x0+W/2), ext_from=fz(cav_z0))
    s.dimh(fx(cav_x1), fx(W/2), fz(0)+7, n(W/2-cav_x1), ext_from=fz(cav_z0))
    s.dimv(fz(P["scr_z2"]), fz(P["scr_z1"]), fx(W/2)+13, n(P["scr_z2"]-P["scr_z1"]), ext_from=fx(P["scr_x"]))
    s.dimv(fz(P["scr_z1"]), fz(P["scr_z0"]), fx(W/2)+13, n(P["scr_z1"]-P["scr_z0"]), ext_from=fx(P["scr_x"]))
    s.dimv(fz(P["scr_z0"]), fz(0), fx(W/2)+13, n(P["scr_z0"]), ext_from=fx(P["scr_x"]))
    s.bal(fx(P["scr_x"]), fz(P["scr_z2"]), 1, fx(P["scr_x"])-9, fz(P["scr_z2"])-7)
    s.bal(fx(P["flash_x"]), fz(H-1), 2, fx(P["flash_x"])+18, fz(H)-6)
    s.bal(fx(cav_x0-1.1), fz(Zc+30), 3, fx(cav_x0)-9, fz(Zc+38))

    SC = 7.2
    sx, sy = 130, 34
    ys = lambda y: sx + y*SC
    zz = lambda z: sy + (60-z)*1.45
    s.rect(ys(0), zz(60), P["front_t"]*SC, zz(0)-zz(60), "part"); s.hatch(ys(0), zz(60), P["front_t"]*SC, zz(0)-zz(60))
    s.rect(ys(0), zz(60), P["pcb_face_y"]*SC, zz(46)-zz(60), "part"); s.hatch(ys(0), zz(60), P["pcb_face_y"]*SC, zz(46)-zz(60))
    s.rect(ys(0), zz(14), P["pcb_face_y"]*SC, zz(0)-zz(14), "part"); s.hatch(ys(0), zz(14), P["pcb_face_y"]*SC, zz(0)-zz(14))
    s.rect(ys(P["front_t"]), zz(44), P["pan_t"]*SC, zz(16)-zz(44), "glass")
    s.rect(ys(P["pcb_face_y"]), zz(50), P["pcb_t"]*SC, zz(10)-zz(50), "pcb")
    s.txt(ys(0), zz(60)-9, "SECTION B-B  ·  front lip", "vlabel", "start", 3.0)
    s.dimh(ys(0), ys(P["front_t"]), zz(0)+10, n(P["front_t"]), ext_from=zz(0), flip=True)
    s.dimh(ys(P["front_t"]), ys(P["pcb_face_y"]), zz(0)+10, n(P["pcb_face_y"]-P["front_t"]), ext_from=zz(0))
    s.dimh(ys(P["pcb_face_y"]), ys(P["mod_back"]), zz(0)+10, n(P["pcb_t"]), ext_from=zz(0))
    s.bal(ys(P["front_t"]/2), zz(47), 4, ys(P["front_t"]/2)-9, zz(53))
    s.bal(ys(P["pcb_face_y"]/2), zz(11), 5, ys(P["pcb_face_y"]/2)-9, zz(5))
    s.bal(fx(P["pan_px"]-(P["pan_w"]+2*P["pan_clr_w"])/2-P["rib_clr"]/2), fz(P["rib_cz"]), 6, fx(-W/2)-9, fz(P["rib_cz"]))
    s.bal(fx(P["pan_px"]-(P["pan_w"]+2*P["pan_clr_w"])/2), fz(Zc+(P["pan_h"]+2*P["pan_clr_h"])/2), 7,
          fx(-W/2)-9, fz(Zc+(P["pan_h"]+2*P["pan_clr_h"])/2)+8)

    s.notes(192, 24, [
        (1, f"3 x dia {n(P['scr_pilot'])} pilot holes, 8 deep, drilled from the back face"),
        (2, f"flash port, {n(P['usb_w'])} wide, through the {n(P['wall'])} top wall"),
        (3, f"cavity {n(cav_w)} x {n(cav_h)}, corners R{n(P['cav_r'])} with R{n(P['cav_rel'])} relief. Without it the fillet fouls the PCB's sharp corner by ~0.33 and the module cannot seat square"),
        (4, "panel recess - the glass stands 1.05 proud of the PCB, so the seat is stepped"),
        (5, "PCB pocket"),
        (6, f"ribbon relief {n(P['rib_clr'])} x {n(P['rib_w'])} on the thick-bezel edge, {n(P['rib_off'])} from one end and {n(P['rib_far'])} from the other, through the pocket depth only. Sets the frame width - see below"),
        (7, f"corner relief R{n(P['pan_rel'])} at all four GLASS pocket corners, and R{n(P['cav_rel'])} at all four PCB cavity corners. Both parts have sharp corners"),
    ], cw=38)
    s.notes(192, 134, [], title="LIP OVERLAP ON THE GLASS")
    for i, t in enumerate([
        f"top / bottom   {n((P['pan_h']-win_h)/2)}",
        f"ribbon side    {n(P['pan_w']/2-P['pan_px']-win_w/2)}",
        f"opposite side  {n(P['pan_w']/2+P['pan_px']-win_w/2)}",
    ]):
        s.txt(192, 141 + i*4.0, t, "note", "start", 2.7)

    s.notes(16, 150, [], title="MEASURED ON THE MODULE")
    for i, t in enumerate([
        f"glass {n(P['pan_w'])} x {n(P['pan_h'])}, sharp corners.",
        f"Dead border {n(P['bez_thin'])} on three sides,",
        f"{n(P['bez_thick'])} on the ribbon side. Ribbon",
        f"{n(P['rib_w'])} wide, {n(P['rib_off'])} from one end,",
        f"needing {n(P['rib_clr'])} to bend back around.",
        f"Pocket margin {n(2*P['pan_clr_w'])} on the width,",
        f"{n(2*P['pan_clr_h'])} on the height.",
    ]):
        s.txt(16, 157 + i*4.0, t, "note", "start", 2.7)

    # ---- DETAIL C : one pocket corner, 6:1
    DC = 6.0
    ox0, oy0 = 106.0, 166.0
    cu = lambda u: ox0 + u*DC
    cv = lambda v: oy0 - v*DC
    U0, U1, V0, V1 = -2.2, 1.4, -2.2, 1.4
    s.txt(88, 152, "DETAIL C  ·  pocket corner  ·  6:1", "vlabel", "start", 3.2)
    s.rect(cu(0), cv(V1), (U1-0)*DC, (V1-V0)*DC, "part")
    s.rect(cu(U0), cv(V1), (0-U0)*DC, (V1-0)*DC, "part")
    r = P["pan_r"]
    s.path(f"M{cu(U0):.2f},{cv(0):.2f} L{cu(-r):.2f},{cv(0):.2f} "
           f"A{r*DC:.2f},{r*DC:.2f} 0 0 0 {cu(0):.2f},{cv(-r):.2f} "
           f"L{cu(0):.2f},{cv(V0):.2f}", "cut")
    s.circ(cu(0), cv(0), 2*P["pan_rel"]*DC, "cut")
    gw, gh = P["pan_clr_w"], P["pan_clr_h"]
    s.rect(cu(U0), cv(-gh), (-gw-U0)*DC, (-gh-V0)*DC, "glass")
    s.txt(cu(U0*0.60), cv(V0*0.60), "glass", "cmp", size=2.5)
    s.leader(cu(P["pan_rel"]*0.72), cv(P["pan_rel"]*0.72), cu(U1)+1, cv(V1)-2.5,
             f"R{n(P['pan_rel'])}", "start")
    import textwrap as _tw
    _lines = []
    for para in [
        "Relief is centred ON the theoretical sharp corner, so it "
        "undercuts equally in both axes.",
        "All four corners are identical.",
    ]:
        _lines += _tw.wrap(para, 22) + [""]
    for i, t in enumerate(_lines):
        s.txt(124, 158 + i*3.8, t, "note", "start", 2.6)
    s.titleblock(TBX, TBY, 96, 18, "FRAME", 4, 8, "1:1")
    return s.render("s4")


# ============================================================ SHEET 5
def sheet5():
    s = mk()
    ox, oy = 22, 14
    fx, fz = views(s, ox, oy)
    s.rect(fx(-W/2), fz(H), W, H, "part", P["corner_r"])
    s.rect(fx(cav_x0+0.85), fz(cav_z1-0.85), cav_w, cav_h, "hid", P["cav_r"])
    s.circ(fx(0), fz(hub_z), P["pk_d"]+2*P["lug_out"]+6, "edge")
    s.circ(fx(0), fz(hub_z), P["pk_d"], "cut")
    s.circ(fx(0), fz(hub_z), P["pk_d"]+2*P["lug_out"], "hid")
    for z in (P["scr_z0"], P["scr_z1"], P["scr_z2"]):
        s.circ(fx(P["scr_x"]), fz(z), P["scr_head"], "cut")
    s.rect(fx(cav_x0+0.3), fz(P["bat_cz"]+P["bat_h"]/2+P["bat_clr"]+P["bat_fence"]),
           P["bat_cx"]+P["bat_w"]/2+P["bat_clr"]+P["bat_fence"]-(cav_x0+0.3),
           P["bat_h"]+2*P["bat_clr"]+2*P["bat_fence"], "plat", 1)
    for sz in (-1, 1):
        s.circ(fx(P["proto_cx"]), fz(P["proto_cz"]+sz*P["proto_hole_sp"]/2), 6.5, "boss")
    for sx_ in (-1, 1):
        for sz in (-1, 1):
            s.circ(fx(P["proto_cx"]+sx_*(P["proto_w"]/2-4)), fz(P["proto_cz"]+sz*(P["proto_h"]/2-4)), 6.0, "boss")
    for sx_ in (-1, 1):
        s.rect(fx(P["drv_cx"]+sx_*(P["drv_w"]/2+P["drv_clr"]+0.3)-1.5), fz(P["drv_cz"]+(P["drv_h"]-1)/2), 3.0, P["drv_h"]-1, "boss")
    for sz in (-1, 1):
        s.rect(fx(P["ucb_x"]-(P["ucb_w"]+4)/2), fz(P["ucb_z"]+sz*(P["ucb_t"]/2+0.15+1.0)+1.0), P["ucb_w"]+4, 2.0, "boss")
    s.rect(fx(P["ucb_x"]-P["port_w"]/2), fz(P["ucb_z"]+P["port_h"]/2), P["port_w"], P["port_h"], "cut", 1.2)
    for sz in (-1, 1):
        z = Zc+sz*(cav_h/2-P["rib_inset"]-P["rib_pad"]/2)
        s.rect(fx(P["bat_cx"]-(P["bat_w"]-2)/2), fz(z+P["rib_pad"]/2), P["bat_w"]-2, P["rib_pad"], "pad", 0.8)

    s.txt(fx(0), fz(H)-8, "BACK COVER  ·  inner face", "vlabel")
    s.dimv(fz(hub_z), fz(0), fx(-W/2)-12, n(hub_z), ext_from=fx(-W/2))
    s.dimh(fx(-W/2), fx(W/2), fz(0)+15, n(W), ext_from=fz(0))
    s.dimh(fx(P["proto_cx"]), fx(W/2), fz(0)+8, n(W/2-P["proto_cx"]), ext_from=fz(P["proto_cz"]))
    s.dimv(fz(P["proto_cz"]), fz(0), fx(W/2)+7, n(P["proto_cz"]), ext_from=fx(P["proto_cx"]))
    s.bal(fx(P["pk_d"]/2*0.71), fz(hub_z+P["pk_d"]/2*0.71), 1, fx(P["pk_d"]/2*0.71)+8, fz(hub_z+P["pk_d"]/2*0.71)-7)
    s.bal(fx(P["proto_cx"]), fz(P["proto_cz"]+P["proto_hole_sp"]/2), 2, fx(P["proto_cx"])+12, fz(P["proto_cz"]+P["proto_hole_sp"]/2)+6)
    s.bal(fx(P["drv_cx"]+P["drv_w"]/2+2), fz(P["drv_cz"]), 3, fx(P["drv_cx"]+P["drv_w"]/2+2)+9, fz(P["drv_cz"])-6)
    s.bal(fx(P["ucb_x"]), fz(P["ucb_z"]+3), 4, fx(P["ucb_x"])-11, fz(P["ucb_z"])-7)
    s.bal(fx(P["bat_cx"]-8), fz(P["bat_cz"]+P["bat_h"]/2+1), 5, fx(P["bat_cx"]-8)-9, fz(P["bat_cz"]+P["bat_h"]/2+9))
    s.bal(fx(P["bat_cx"]), fz(cav_z0+4), 6, fx(P["bat_cx"])+13, fz(cav_z0+4)-6)

    s.notes(150, 22, [
        (1, f"pocket bore dia {n(P['pk_d'])} x {n(P['pk_dep'])} deep. Bayonet groove dia {n(P['pk_d']+2*P['lug_out'])} with three {n(P['gap_ang'])} deg entry gaps at 45 / 165 / 285 deg"),
        (2, f"2 x M2.5 posts, {n(P['proto_hole_sp'])} apart, plus four corner pads"),
        (3, "driver-board rails - the board slides down from the top, stop at the bottom"),
        (4, "USB-C breakout rails; the port opening is through the skin below them"),
        (5, f"cell platform, level with the puck face so the cell does not straddle the step, with a {n(P['bat_fence'])} fence"),
        (6, "module retention pad"),
    ], cw=44)
    s.titleblock(TBX, TBY, 96, 18, "BACK COVER", 5, 8, "1:1")
    return s.render("s5")


# ============================================================ SHEET 6
def sheet6():
    s = mk()
    R = P["disc_d"]/2
    cx, cy = 60, 76
    s.circ(cx, cy, P["disc_d"], "part")
    s.circ(cx, cy, P["disc_d"]-2*P["lug_out"]+0.6, "hid")
    slot_w = P["leg_w"]+2*P["leg_slot_c"]
    z0 = -(P["pivot_r"]+P["leg_w"]/2+1.2)
    z1 = P["leg_len"]-P["pivot_r"]+3.5
    s.rect(cx-slot_w/2, cy-z1, slot_w, z1-z0, "cut", 1)
    s.circ(cx, cy+P["pivot_r"], P["pin_d"], "cut")
    s.line(cx-R-4, cy+P["pivot_r"], cx+R+4, cy+P["pivot_r"], "cl")
    s.line(cx, cy-R-6, cx, cy+R+6, "cl")
    s.line(cx-R-6, cy, cx+R+6, cy, "cl")
    for a in (0, 120, 240):
        for k in (-1, 1):
            th = math.radians(a+k*P["lug_ang"]/2-90)
            s.line(cx+R*math.cos(th), cy+R*math.sin(th), cx+(R+P["lug_out"])*math.cos(th), cy+(R+P["lug_out"])*math.sin(th), "edge")
    s.txt(cx, cy-R-12, "DISC  ·  outer face", "vlabel")
    s.dimh(cx-R, cx+R, cy+R+14, f"dia {n(P['disc_d'])}", ext_from=cy+R)
    s.dimv(cy, cy+P["pivot_r"], cx-R-9, n(P["pivot_r"]), ext_from=cx)
    s.bal(cx+P["pin_d"]/2, cy+P["pivot_r"], 1, cx+R-4, cy+R+2)
    s.bal(cx+slot_w/2, cy-12, 2, cx+R+2, cy-16)
    s.bal(cx+(R+P["lug_out"]/2)*math.cos(math.radians(-90)), cy+(R+P["lug_out"]/2)*math.sin(math.radians(-90)), 3, cx+14, cy-R-4)
    s.txt(cx, cy+R+22, f"thickness {n(P['disc_t'])}", "note", size=2.8)

    lx, ly = 138, 34
    hub = P["leg_w"]/2
    s.txt(lx, ly-14, "LEG  ·  printed flat", "vlabel")
    s.path(f'M{lx-hub:.2f},{ly:.2f} A{hub},{hub} 0 0 1 {lx+hub:.2f},{ly:.2f} '
           f'L{lx+P["foot_r"]:.2f},{ly+P["leg_len"]-P["foot_r"]:.2f} '
           f'A{P["foot_r"]},{P["foot_r"]} 0 0 1 {lx-P["foot_r"]:.2f},{ly+P["leg_len"]-P["foot_r"]:.2f} Z', "part")
    s.circ(lx, ly, P["pin_d"], "cut")
    s.line(lx, ly-10, lx, ly+P["leg_len"]+8, "cl")
    s.dimv(ly, ly+P["leg_len"], lx-hub-10, n(P["leg_len"]), ext_from=lx)
    s.dimh(lx-hub, lx+hub, ly-8, n(P["leg_w"]), ext_from=ly)
    s.bal(lx+P["pin_d"]/2, ly, 4, lx+hub+9, ly-5)
    s.bal(lx, ly+P["leg_len"]-1, 5, lx+hub+9, ly+P["leg_len"]-2)
    s.txt(lx, ly+P["leg_len"]+14, f"thickness {n(P['leg_t'])}", "note", size=2.8)

    s.notes(178, 22, [
        (1, f"dia {n(P['pin_d']+0.25)} pin hole, straight through the disc. Pin is trapped by the pocket wall once the disc is fitted"),
        (2, f"leg slot {n(slot_w)} wide, from {n(-z0)} below the centre to {n(z1)} above"),
        (3, f"three bayonet lugs, {n(P['lug_ang'])} deg wide x {n(P['lug_out'])} proud, on the inner face"),
        (4, f"dia {n(P['pin_d']+0.15)} axle hole. Use a {n(P['pin_d'])} rod or a 1.75 filament offcut"),
        (5, f"foot R{n(P['foot_r'])}. The heel behind the pin is cut by the pocket floor at the {n(P['stop_ang'])} deg stop, which is what takes the load"),
    ], cw=42)
    s.titleblock(TBX, TBY, 96, 18, "DISC & LEG", 6, 8, "1:1")
    return s.render("s6")


# ============================================================ SHEET 7
def sheet7():
    s = mk()
    lean = math.degrees(math.atan2(
        (hub_z-P["pivot_r"])-P["leg_len"]*math.cos(math.radians(P["stop_ang"])),
        (P["pk_y0"]+P["disc_t"]/2)+P["leg_len"]*math.sin(math.radians(P["stop_ang"]))-(D-P["rear_chf"])))
    a = math.radians(lean)
    py = D-P["rear_chf"]
    SC = 1.05
    gx, gy = 46, 140

    def wf(y, z):
        dy, dz = y-py, z
        return gx+(dy*math.cos(a)+dz*math.sin(a))*SC, gy-(-dy*math.sin(a)+dz*math.cos(a))*SC

    s.line(gx-34, gy, gx+112, gy, "table")
    for k in range(-32, 112, 5):
        s.line(gx+k, gy, gx+k-3.4, gy+3.4, "hl")
    pts = [wf(0, 0), wf(0, H), wf(D, H), wf(D, 0)]
    s.path("M"+" L".join(f"{x:.2f},{y:.2f}" for x, y in pts)+" Z", "part")
    p0, p1 = wf(0, cav_z0), wf(0, cav_z1)
    s.line(p0[0], p0[1], p1[0], p1[1], "inkline")
    pv = wf(P["pk_y0"]+P["disc_t"]/2, hub_z-P["pivot_r"])
    ft = wf(P["pk_y0"]+P["disc_t"]/2+P["leg_len"]*math.sin(math.radians(P["stop_ang"])),
            hub_z-P["pivot_r"]-P["leg_len"]*math.cos(math.radians(P["stop_ang"])))
    hb = wf(P["pk_y0"]+P["disc_t"]/2, hub_z)
    s.circ(hb[0], hb[1], P["disc_d"]*SC, "hid")
    s.line(pv[0], pv[1], ft[0], ft[1], "leg")
    s.circ(pv[0], pv[1], 3, "cut")
    ce = wf(py, 0)
    yc, zc = 11.0, Zc
    cm = wf(yc, zc)
    s.circ(cm[0], cm[1], 3.6, "com")
    s.line(cm[0], cm[1], cm[0], gy, "cl")

    s.bal(pv[0], pv[1], 1, pv[0]+10, pv[1]-8)
    s.bal(hb[0], hb[1], 2, hb[0]+11, hb[1]+2)
    s.bal(ft[0]-2, ft[1]-2, 3, ft[0]+2, ft[1]-11)
    s.bal(ce[0], ce[1]-1.5, 4, ce[0]-12, ce[1]-11)
    s.bal(cm[0], cm[1], 5, cm[0]-15, cm[1]+9)

    s.line(gx, gy, gx, gy-72, "cl")
    s.path(f'M{gx:.2f},{gy-64:.2f} A64,64 0 0 1 {gx+64*math.sin(a):.2f},{gy-64*math.cos(a):.2f}', "dim")
    s.txt(gx+70*math.sin(a/2)+2, gy-70*math.cos(a/2)-2, f"{lean:.1f} deg", "dimtxt", "start", 3.4)
    s.dimh(gx, ft[0], gy+13, n((ft[0]-gx)/SC), ext_from=gy)
    s.dimh(gx, cm[0], gy+23, n((cm[0]-gx)/SC), ext_from=gy)
    s.txt(gx+3, gy+31, "footprint / CoM offset, both behind the contact edge", "note", "start", 2.6)
    s.txt(gx+20, 16, "SIDE ELEVATION  ·  leg deployed", "vlabel", "start", 3.2)

    s.notes(168, 22, [
        (1, f"hinge pin, {n(P['pivot_r'])} from the hub centre"),
        (2, f"disc hub, {n(hub_z)} above the bottom edge"),
        (3, f"foot. Leg {n(P['leg_len'])} long, hard stop at {n(P['stop_ang'])} deg from straight down"),
        (4, "contact edge - the rear edge of the flat bottom, brought forward 2 by the back chamfer. This, not the front edge, is what the frame leans on"),
        (5, "estimated centre of mass. It must sit behind the contact edge or the frame simply falls flat onto its face"),
    ], cw=42)
    y = 108
    s.txt(168, y, "WHY THE HUB SITS LOW", "vlabel", "start", 3.2)
    for i, t in enumerate([
        f"The frame is {n(W)} x {n(H)}. A hub on the frame's",
        f"centre would sit {n(H/2)} above the bottom edge in",
        f"portrait but only {n(W/2)} in landscape, so the leg",
        "over-reaches and landscape stands about 9 deg",
        "more upright - close to tipping forward.",
        "",
        f"Putting the hub at z = {n(hub_z)} = W/2 makes the",
        "pivot the same height above whichever edge is",
        "down. Both orientations then give:",
    ]):
        s.txt(168, y+7+i*4.0, t, "note", "start", 2.7)
    s.txt(168, y+7+9*4.0+5, f"lean {lean:.1f} deg   ·   footprint {n((ft[0]-gx)/SC)}", "val", "start", 4.2)
    s.titleblock(TBX, TBY, 96, 18, "STAND KINEMATICS", 7, 8, "1:1.05")
    return s.render("s7")


# ============================================================ SHEET 8
def sheet8():
    s = mk(268, 232)

    def box(x, y, w, h, title, sub=None):
        s.rect(x, y, w, h, "part", 1.5)
        s.txt(x + w/2, y + 7.0, title, "cmp", size=3.3)
        if sub:
            s.txt(x + w/2, y + 11.4, sub, "cmpsub", size=2.6)

    def pin(x, y, label, anchor="start", dx=2.0, up=False):
        s.circ(x, y, 1.6, "cut")
        s.txt(x + (dx if anchor == "start" else -dx), y + (-2.6 if up else 1.0),
              label, "note", anchor, 2.6)

    def wire(pts):
        s.path("M" + " L".join(f"{a:.2f},{b:.2f}" for a, b in pts), "wire")

    box(14, 38, 40, 28, "USB-C", "breakout")
    box(80, 30, 58, 54, P["chg_part"], "charger + power path")
    box(80, 108, 58, 26, "1S LiPo  ·  694449", "2000 mAh, salvaged")
    box(170, 38, 58, 46, "Waveshare", "ESP32 driver board")

    pin(54, 48, "VBUS");            pin(80, 48, "VBUS", "end")
    pin(54, 58, "GND");             pin(80, 58, "GND", "end")
    pin(80, 70, "BATT", "end")
    pin(138, 48, "LOAD");            pin(170, 48, "5V", "end")
    pin(138, 70, "GND");            pin(170, 60, "GND", "end")
    pin(170, 72, "GPIO 32-39", "end")
    pin(80, 80, "TH", "end")
    pin(98, 108, "+ red", up=True);  pin(114, 134, "- black", "start", 2.4)
    pin(126, 108, "NTC", "start", 2.4, up=True)

    wire([(54, 48), (80, 48)]);     s.txt(67, 45.6, "5 V", "dimtxt", "middle", 2.7)
    wire([(54, 58), (80, 58)])
    wire([(80, 70), (66, 70), (66, 98), (98, 98), (98, 108)])
    # yellow NTC leg back to the charger's TS pin
    s.path("M126,108 L126,94 L60,94 L60,80 L80,80", "wire ntc")
    s.txt(93, 92.4, "yellow  ·  10k NTC", "dimtxt", "middle", 2.6)
    wire([(138, 48), (170, 48)]);   s.txt(152, 45.6, "3.0-4.5 V", "dimtxt", "middle", 2.7)
    wire([(138, 70), (150, 70), (150, 60), (170, 60)])
    # divider off the 5 V net
    s.rect(159, 88, 6, 11, "res");  s.txt(168, 94.6, "100k", "note", "start", 2.6)
    s.rect(159, 107, 6, 11, "res"); s.txt(168, 113.6, "100k", "note", "start", 2.6)
    wire([(162, 48), (162, 88)])
    wire([(162, 99), (162, 107)])
    wire([(162, 103), (166, 103), (166, 72), (170, 72)])
    wire([(162, 118), (162, 142)])
    # ground bus
    wire([(80, 58), (56, 58), (56, 142), (162, 142)])
    wire([(114, 134), (114, 142)])
    s.line(108, 142, 120, 142, "wire")
    s.line(110.5, 145, 117.5, 145, "edge")
    s.line(113, 148, 115, 148, "edge")
    s.txt(114, 153, "GND", "note", "middle", 2.6)

    s.bal(67, 48, 1, 40, 24)
    s.bal(109, 30, 2, 109, 18)
    s.bal(152, 48, 3, 152, 22)
    s.bal(162, 103, 4, 144, 103)
    s.bal(80, 80, 6, 40, 80)
    s.bal(170, 48, 5, 200, 22)

    s.txt(120, 12, "POWER WIRING  ·  charge and run from one cell", "vlabel")

    s.notes(14, 164, [
        (1, "USB-C breakout needs 5.1k from CC1 and CC2 to GND or a USB-C source will never turn its 5 V on. VBUS and GND only, no data"),
        (2, "charge current: Adafruit's pinout page says it ships at 500 mA, the product page says 1 A - CHECK THE BOARD. 1 A is 0.5C for this cell and is what you want. Solar capability is input voltage regulation and is inert on USB"),
        (6, "THREE WIRES = the pack has an NTC. Cut the TH jumper before wiring yellow here (THERM on the 4755). Verify first: red positive to black at 3.0-4.2 V, and yellow-to-black ~10k falling as you warm it. If it does not move it is not a thermistor: leave the jumper intact. Check for a protection PCB at the tab end; without one there is no short or overdischarge protection"),
    ], cw=62)
    s.notes(142, 164, [
        (3, "LOAD is 4.5 V max - from the input when plugged in, from the cell otherwise. The 5V pin takes 3.6-5.5 V and browns out near 3.6 V"),
        (4, "divider must land on ADC1 (GPIO 32-39) - ADC2 is dead while WiFi is on. Below 3.6 V firmware MUST deep-sleep for good, or the cell gets dragged to its protection cut"),
        (5, "PWR / CHRG / FAULT LEDs onboard; S1 and S2 pads mirror them. /CE pulled high disables charging"),
    ], cw=58, title=" ")
    s.titleblock(268 - 96 - 6, 232 - 23, 96, 18, "POWER WIRING", 8, 8, "N.T.S.")
    return s.render("s8")


if __name__ == "__main__":
    sheets = [sheet1(), sheet2(), sheet3(), sheet4(), sheet5(), sheet6(), sheet7(), sheet8()]
    os.makedirs("drawings", exist_ok=True)
    for i, sv in enumerate(sheets, 1):
        open(f"drawings/sheet{i}.svg", "w").write(
            '<?xml version="1.0" encoding="UTF-8"?>\n'+sv.replace('class="dwg"', 'class="dwg" width="1072" height="760"'))
    open("drawings/_sheets.json", "w").write(json.dumps(sheets))
    print("wrote", len(sheets), "sheets")
