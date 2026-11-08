#!/usr/bin/env python3
"""Render the model to renders/*.png.  Needs pyvista (pip install pyvista).

    python3 tools/render.py              on a desktop
    xvfb-run -a python3 tools/render.py  on a headless Linux box

Everything is built from src/rodalm_frame.py, so the pictures cannot drift from
the 3MFs.
"""
import sys
from pathlib import Path

import numpy as np
import pyvista as pv
from build123d import Axis, Box, Pos

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))
import rodalm_frame as M  # noqa: E402

OUT = ROOT / "renders"
pv.global_theme.background = "white"
CAS, LID, WOOD, STRUT = "#9fb3c8", "#7f97b0", "#7a5536", "#5b4b8a"
BACK_ISO = [(140, 120, 260), (0, 0, 12), (0, 1, 0)]


def mesh(shape, tol=0.05):
    v, t = shape.tessellate(tol, 0.2)
    V = np.array([[p.X, p.Y, p.Z] for p in v])
    F = np.hstack([np.full((len(t), 1), 3), np.array(t)]).ravel()
    return pv.PolyData(V, F)


def shot(items, name, cam, title, parallel=False):
    pl = pv.Plotter(off_screen=True, window_size=(1400, 1000))
    for shape, color in items:
        pl.add_mesh(mesh(shape), color=color, specular=0.15, ambient=0.25, diffuse=0.8)
    pl.camera_position = cam
    if parallel:
        pl.enable_parallel_projection()
    pl.reset_camera()
    pl.add_text(title, font_size=12, color="black")
    pl.screenshot(str(OUT / name))
    pl.close()


def main():
    OUT.mkdir(exist_ok=True)
    p, m = M.build(), M.mocks()
    boards = [(p["cassette"], CAS), (m["carrier"], "#b9cf96"), (m["driver"], "#3d7a5a"),
              (m["charger"], "#2b2b2b"), (m["cell"], "#c4c6d6"), (m["adapter"], "#c9d6b6"),
              (m["tabs"], "#d4a017"), (m["glass"], "#444444"), (m["tail"], "#d4a017")]
    shot([(p["cassette"], CAS)], "01-cassette.png", BACK_ISO, "Cassette, from the back")
    shot(boards, "02-cassette-boards.png", BACK_ISO, "Cassette with the boards, lid off")
    shot([(m["moulding"], WOOD), (p["lid"], LID), (p["strut"], STRUT), (m["usb"], "#c0392b"),
          (m["pin"], "#cccccc")], "03-back-folded.png", BACK_ISO,
         "From the back, strut folded into its pocket: nothing stands proud, ready to hang")
    shot([(m["moulding"], WOOD), (p["lid"], LID), (M.make_strut(M.DEP_ANG), STRUT),
          (m["usb"], "#c0392b"), (m["pin"], "#cccccc")], "04-back-deployed.png", BACK_ISO,
         f"Strut swung out {M.DEP_ANG:g} deg to its stop")
    shot([(p["lid"], LID), (m["pin"], "#cccccc"), (m["usb"], "#c0392b")],
         "08-lid-inside.png", [(230, -90, -80), (10, -5, 20), (0, 1, 0)],
         "Lid from inside: the strut pocket's tub, the hinge walls and rod, the USB-C panel")
    edge = Axis((0, M.BOTTOM_EDGE, M.INSIDE_D), (1, 0, 0))
    stood = [(s.rotate(edge, M.LEAN), c) for s, c in
             [(m["moulding"], WOOD), (p["lid"], LID), (M.make_strut(M.DEP_ANG), STRUT)]]
    stood.append((Pos(0, M.BOTTOM_EDGE - 1, 20) * Box(160, 2, 140), "#dddddd"))
    shot(stood, "05-standing-side.png", [(400, 0, 12), (0, 0, 12), (0, 1, 0)],
         f"Standing: lean {M.LEAN:.1f} deg, footprint {M.FOOTPRINT:.0f} mm", parallel=True)
    shot([(m["moulding"], WOOD), (p["mat"], "#f4f2ec"), (m["glass"], "#d9d8d2")], "06-front.png",
         [(0, 0, -300), (0, 0, 0), (0, 1, 0)], "From the front (cover off)", parallel=True)
    cm, cc = M.make_coupons(p["mat"], p["cassette"])
    shot([(cc, CAS), (Pos(0, 0, -6) * cm, "#f4f2ec"), (Pos(0, -95, 0) * M.make_gauge(), "#c8a24a")],
         "07-coupons.png", [(150, 130, 230), (0, -10, 0), (0, 1, 0)],
         "Fit coupons, cut from the real parts, and the insert gauge")


if __name__ == "__main__":
    main()
