#!/usr/bin/env python3
import json, os

P = {}
for line in open("/tmp/params.txt"):
    if "=" in line:
        k, v = line.strip().split("=", 1)
        try: P[k] = float(v)
        except ValueError: P[k] = v

def n(v):
    return f"{v:.0f}" if abs(v - round(v)) < 0.005 else f"{v:.2f}".rstrip("0").rstrip(".")

sheets = json.load(open("drawings/_sheets.json"))

TITLES = [
    ("Assembly &amp; envelope", "Overall size, where the ink lands in the bezel, and every opening in the shell."),
    ("Internal layout", "What sits where inside the cavity, dimensioned from the cavity edges."),
    ("Depth stack-up", "The tight axis. Section A&ndash;A with the depth magnified &times;6.4."),
    ("Frame", "The printed front shell &mdash; cavity, screw pilots, and the stepped module pocket."),
    ("Back cover", "The printed back &mdash; stand pocket, board mounts, cell platform, port."),
    ("Disc &amp; leg", "The two kickstand parts, printed flat."),
    ("Stand kinematics", "How the deployed leg sets the lean, and why the hub sits low."),
    ("Power wiring", "Charging the cell and running the board from it, off one USB-C port."),
]

VERIFY = [
    ("act_off_x", n(P["act_off_x"]) + " mm",
     "Offset of the ink centre from the PCB centre across the short axis. Inferred from panel vs "
     "active sizes &mdash; Waveshare publishes no datum. Wrong here and the white line goes lopsided. "
     "This is what <code>bezel_test.stl</code> checks."),
    ("conn_h", n(P["conn_h"]) + " mm",
     "Assumed height of the module&rsquo;s mated 8-pin header off its back. Sheet 3 shows " +
     n(P["cov_in_pk"] - P["bat_t"] - P["mod_back"]) + " mm available over the cell. A stock vertical "
     "PH2.0 plug plus a wire bend is 8&ndash;9 mm &mdash; right-angle housing, direct-solder, or "
     "<code>depth = 25</code>."),
    ("pan_off_x / pan_off_z", "0",
     "Glass assumed centred on the PCB, leaving 6 mm of bare PCB at each end of the long axis. "
     "Worth a caliper check &mdash; it moves the panel recess on sheet 4."),
    ("proto_hole_sp", n(P["proto_hole_sp"]) + " mm",
     "Mounting-hole spacing on the quarter-size Perma-Proto (1.4&Prime;). The two M2.5 posts on "
     "sheet 5 sit on it."),
    ("USB-C positions", "centred",
     "Assumed centred on the driver board&rsquo;s short edge and on the bq25185. The top-end flash "
     "opening is now closed (<code>flash_port = false</code>), so this only shifts the blind pocket "
     "behind it &mdash; but the charge port in the back plate still depends on it."),
]

PARTS = [
    ("Frame", "frame.stl", "front face on the bed", "48.1 cm&sup3;", "~60 g"),
    ("Back cover", "cover.stl", "outer face on the bed", "38.2 cm&sup3;", "~47 g"),
    ("Disc", "disc.stl", "outer face on the bed", "6.7 cm&sup3;", "~8 g"),
    ("Leg", "leg.stl", "flat", "1.3 cm&sup3;", "~2 g"),
    ("Bezel test tile", "bezel_test.stl", "front face down &mdash; print first", "17.2 cm&sup3;", "~21 g"),
]

BOM = [
    ("Waveshare 4.2inch e-Paper Module (B)", f'{n(P["pcb_w"])} &times; {n(P["pcb_h"])} &times; {n(P["pcb_t"])} PCB, panel {n(P["pan_w"])} &times; {n(P["pan_h"])} &times; {n(P["pan_t"])}'),
    ("Waveshare e-Paper ESP32 Driver Board", f'{n(P["drv_w"])} &times; {n(P["drv_h"])} &mdash; runs from the cell via its 5V pin, but has no charger on it'),
    ("Adafruit Perma-Proto, quarter-size", f'{n(P["proto_w"])} &times; {n(P["proto_h"])}, holes {n(P["proto_hole_sp"])} apart'),
    ("Adafruit bq24074 charger (#4755)", f'{n(P["chg_w"])} &times; {n(P["chg_h"])}'),
    ("1S LiPo, 1200 mAh", f'{n(P["bat_w"])} &times; {n(P["bat_h"])} &times; {n(P["bat_t"])}'),
    ("USB-C breakout, 5.1 k&Omega; CC pulldowns", f'~{n(P["ucb_w"])} &times; {n(P["ucb_l"])}'),
    ("M2.5 &times; 8 self-tapping screws", "3 off &mdash; back cover"),
    ("M2.5 &times; 6 screws", "2 off &mdash; Perma-Proto"),
    ("&#8960;2 &times; 43 rod or 1.75 filament offcut", "1 off &mdash; kickstand pin"),
]

CSS = """
:root{
  --paper:#F1F3F0; --surface:#FAFBF9; --sunk:#E7EAE5;
  --ink:#171B18; --ink-2:#59635C; --rule:#D3D8D2;
  --accent:#0E6B57; --verify:#A8631A;
  --part-fill:#E4E8E3; --glass:#D9E4E6; --pcbf:#CBDCCF; --cellf:#D2D6D8;
  --chgf:#C7D8E4; --platf:#EDEFEA; --bossf:#DCE2DA; --padf:#D8DED6; --voidf:#E7EAE5;
}
@media (prefers-color-scheme: dark){
  :root:not([data-theme="light"]){
    --paper:#0F1211; --surface:#171B18; --sunk:#1D2320;
    --ink:#E8ECE7; --ink-2:#93A099; --rule:#2C332E;
    --accent:#57CFA9; --verify:#E0A64B;
    --part-fill:#232A26; --glass:#243233; --pcbf:#1F3327; --cellf:#2A3033;
    --chgf:#1E2E3A; --platf:#1C221E; --bossf:#28302B; --padf:#2A322C; --voidf:#101413;
  }
}
:root[data-theme="dark"]{
  --paper:#0F1211; --surface:#171B18; --sunk:#1D2320;
  --ink:#E8ECE7; --ink-2:#93A099; --rule:#2C332E;
  --accent:#57CFA9; --verify:#E0A64B;
  --part-fill:#232A26; --glass:#243233; --pcbf:#1F3327; --cellf:#2A3033;
  --chgf:#1E2E3A; --platf:#1C221E; --bossf:#28302B; --padf:#2A322C; --voidf:#101413;
}
*{box-sizing:border-box}
body{
  margin:0; background:var(--paper); color:var(--ink);
  font-family:"IBM Plex Sans","Helvetica Neue",Arial,sans-serif;
  font-size:15px; line-height:1.6; -webkit-font-smoothing:antialiased;
}
.wrap{max-width:1120px; margin:0 auto; padding:48px 24px 96px; display:flex; flex-direction:column; gap:40px}
h1,h2,h3{font-family:Archivo,"Helvetica Neue",Arial,sans-serif; margin:0; text-wrap:balance}
h1{font-size:clamp(30px,4.4vw,46px); font-weight:700; letter-spacing:-.015em; line-height:1.08}
h2{font-size:20px; font-weight:600; letter-spacing:-.005em}
h3{font-size:15px; font-weight:600}
p{margin:0}
code{font-family:"IBM Plex Mono",ui-monospace,monospace; font-size:.88em;
  background:var(--sunk); padding:.1em .34em; border-radius:3px}
.eyebrow{font-family:"IBM Plex Mono",monospace; font-size:11.5px; letter-spacing:.16em;
  text-transform:uppercase; color:var(--accent)}
.lede{color:var(--ink-2); max-width:64ch; font-size:16.5px}
header .meta{display:flex; flex-wrap:wrap; gap:8px 28px; font-family:"IBM Plex Mono",monospace;
  font-size:12.5px; color:var(--ink-2); border-top:1px solid var(--rule); padding-top:14px; margin-top:6px}
header .meta b{color:var(--ink); font-weight:600; font-variant-numeric:tabular-nums}

.sheet{display:flex; flex-direction:column; gap:12px}
.sheet-head{display:flex; align-items:baseline; gap:14px; flex-wrap:wrap}
.sheet-no{font-family:"IBM Plex Mono",monospace; font-size:12px; letter-spacing:.14em;
  color:var(--accent); border:1px solid var(--accent); border-radius:2px; padding:2px 7px}
.sheet-head p{color:var(--ink-2); font-size:14px; flex:1 1 320px}
.frame{background:var(--surface); border:1px solid var(--rule); border-radius:3px;
  padding:10px; overflow-x:auto}
.dwg{width:100%; height:auto; display:block; min-width:640px;
  font-family:"IBM Plex Mono",ui-monospace,monospace}

.part{fill:var(--part-fill); stroke:var(--ink); stroke-width:.55}
.edge{fill:none; stroke:var(--ink); stroke-width:.5}
.inkline{fill:none; stroke:var(--ink); stroke-width:1.1}
.ghost{fill:none; stroke:var(--rule); stroke-width:.45}
.hid{fill:none; stroke:var(--ink-2); stroke-width:.35; stroke-dasharray:2.2 1.4}
.cl{fill:none; stroke:var(--ink-2); stroke-width:.28; stroke-dasharray:6 1.6 1 1.6; opacity:.75}
.cut{fill:var(--paper); stroke:var(--ink); stroke-width:.45}
.ink{fill:var(--ink); opacity:.86; stroke:none}
.glass{fill:var(--glass); stroke:var(--ink); stroke-width:.4}
.pcb{fill:var(--pcbf); stroke:var(--ink); stroke-width:.45}
.cell{fill:var(--cellf); stroke:var(--ink); stroke-width:.45}
.chg{fill:var(--chgf); stroke:var(--ink); stroke-width:.4}
.plat{fill:var(--platf); stroke:var(--ink-2); stroke-width:.35}
.boss{fill:var(--bossf); stroke:var(--ink-2); stroke-width:.35}
.pad{fill:var(--padf); stroke:var(--ink-2); stroke-width:.35}
.voidfill{fill:var(--voidf); stroke:var(--ink-2); stroke-width:.35}
.warn{fill:none; stroke:var(--verify); stroke-width:.6; stroke-dasharray:2 1.2}
.wire.ntc{stroke:var(--verify)}
.clash{fill:var(--verify); fill-opacity:.30; stroke:var(--verify); stroke-width:.7}
.clashtxt{fill:var(--verify); font-family:var(--mono); font-weight:600; letter-spacing:.02em}
.wire{fill:none; stroke:var(--ink); stroke-width:.62; stroke-linejoin:round}
.res{fill:var(--surface); stroke:var(--ink); stroke-width:.5}
.leg{stroke:var(--ink); stroke-width:2.6; stroke-linecap:round; fill:none}
.table{stroke:var(--ink-2); stroke-width:.6}
.com{fill:var(--verify); stroke:var(--ink); stroke-width:.3}
.hl{stroke:var(--rule); stroke-width:.3; fill:none}
.hatch{opacity:.9}
.dim{fill:none; stroke:var(--accent); stroke-width:.32}
.ext{fill:none; stroke:var(--accent); stroke-width:.22; opacity:.55}
.arrow{fill:var(--accent); stroke:none}
.dimtxt{fill:var(--accent); font-size:3px; letter-spacing:.02em}
.note{fill:var(--ink-2)}
.val{fill:var(--ink); font-weight:600}
.val.warn{fill:var(--verify); stroke:none}
.balloon{fill:var(--surface); stroke:var(--accent); stroke-width:.45}
.baltxt{fill:var(--accent); font-weight:600; text-anchor:middle}
.vlabel{fill:var(--ink); font-family:Archivo,sans-serif; font-weight:600; letter-spacing:.09em}
.cmp{fill:var(--ink); font-weight:600}
.cmpsub{fill:var(--ink-2)}
.tbframe{fill:none; stroke:var(--ink); stroke-width:.5}
.tbrule{stroke:var(--rule); stroke-width:.35; fill:none}
.tbname{fill:var(--ink); font-family:Archivo,sans-serif; font-weight:700; letter-spacing:.03em}
.tbmeta{fill:var(--ink-2); letter-spacing:.09em}

.panel{border:1px solid var(--rule); border-radius:3px; background:var(--surface); padding:22px 24px;
  display:flex; flex-direction:column; gap:16px}
.panel.flag{border-color:var(--verify); border-left-width:3px}
.checks{display:flex; flex-direction:column; gap:14px; margin:0; padding:0; list-style:none}
.checks li{display:grid; grid-template-columns:minmax(150px,190px) 1fr; gap:6px 20px;
  padding-top:14px; border-top:1px solid var(--rule)}
.checks li:first-child{border-top:none; padding-top:0}
.checks .k{font-family:"IBM Plex Mono",monospace; font-size:13px; color:var(--ink); font-weight:500}
.checks .k span{display:block; color:var(--verify); font-size:15px; font-weight:600;
  font-variant-numeric:tabular-nums; margin-top:2px}
.checks .v{color:var(--ink-2); font-size:14px}
table{border-collapse:collapse; width:100%; font-size:14px}
th,td{text-align:left; padding:9px 14px 9px 0; border-bottom:1px solid var(--rule); vertical-align:top}
th{font-family:"IBM Plex Mono",monospace; font-size:11px; letter-spacing:.13em; text-transform:uppercase;
  color:var(--ink-2); font-weight:500}
td.num{font-family:"IBM Plex Mono",monospace; font-variant-numeric:tabular-nums; white-space:nowrap}
td.f{font-family:"IBM Plex Mono",monospace; color:var(--ink-2); white-space:nowrap}
footer{color:var(--ink-2); font-size:13px; border-top:1px solid var(--rule); padding-top:18px}
@media (max-width:640px){
  .checks li{grid-template-columns:1fr}
  .wrap{padding:32px 16px 64px; gap:32px}
}
"""


def build():
    o = []
    o.append('<meta charset="utf-8">')
    o.append('<title>e-Paper Frame Drawings</title>')
    o.append('<link rel="preconnect" href="https://fonts.googleapis.com">')
    o.append('<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>')
    o.append('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?'
             'family=Archivo:wght@600;700&family=IBM+Plex+Mono:wght@400;500;600&'
             'family=IBM+Plex+Sans:wght@400;500;600&display=swap">')
    o.append(f"<style>{CSS}</style>")
    o.append('<div class="wrap">')

    o.append('<header style="display:flex;flex-direction:column;gap:14px">')
    o.append('<span class="eyebrow">Sheet set &middot; 8 sheets</span>')
    o.append('<h1>4.2&Prime; e-Paper desk frame</h1>')
    o.append('<p class="lede">Every dimension on these sheets is generated from the OpenSCAD '
             'model&rsquo;s own parameters, so the drawings cannot drift from the exported STLs. '
             'Re-run <code>tools/mkdrawings.py</code> after any parameter change and the sheets '
             'follow.</p>')
    o.append('<div class="meta">'
             f'<span>Envelope <b>{n(P["W"])} &times; {n(P["H"])} &times; {n(P["depth"])}</b> mm</span>'
             f'<span>Ink area <b>{n(P["act_w"])} &times; {n(P["act_h"])}</b> mm</span>'
             f'<span>Lean <b>20.0&deg;</b> both orientations</span>'
             f'<span>Filament <b>~104 g</b></span>'
             '<span>Units <b>mm</b></span></div>')
    o.append('</header>')

    for i, (svg, (title, sub)) in enumerate(zip(sheets, TITLES), 1):
        o.append('<section class="sheet">')
        o.append('<div class="sheet-head">'
                 f'<span class="sheet-no">SHEET {i}</span><h2>{title}</h2><p>{sub}</p></div>')
        o.append(f'<div class="frame">{svg}</div>')
        o.append('</section>')

    o.append('<section class="panel flag">')
    o.append('<div><span class="eyebrow" style="color:var(--verify)">Before you print</span>'
             '<h2 style="margin-top:6px">Five numbers the model assumes rather than knows</h2></div>')
    o.append('<p class="lede" style="font-size:15px">Everything else on these sheets is either a '
             'published spec or falls out of the geometry. These five came from inference, so they '
             'are the ones to check with calipers.</p>')
    o.append('<ul class="checks">')
    for k, v, why in VERIFY:
        o.append(f'<li><div class="k">{k}<span>{v}</span></div><div class="v">{why}</div></li>')
    o.append('</ul></section>')

    o.append('<section class="panel">')
    o.append('<h2>Printed parts</h2>')
    o.append('<table><thead><tr><th>Part</th><th>File</th><th>On the bed</th>'
             '<th>Volume</th><th>Filament</th></tr></thead><tbody>')
    for a, b, c, d, e in PARTS:
        o.append(f'<tr><td>{a}</td><td class="f">{b}</td><td>{c}</td>'
                 f'<td class="num">{d}</td><td class="num">{e}</td></tr>')
    o.append('</tbody></table>')
    o.append('<p class="v" style="color:var(--ink-2);font-size:14px">PLA or PETG, 0.2 mm layers, '
             '4 perimeters, 15&ndash;20&thinsp;% infill, no supports. The bayonet groove and the '
             'window chamfer are both cut at 45&deg;, and the only bridge left is the '
             '1.9 mm ceiling over the closed flash pocket.</p>')
    o.append('</section>')

    o.append('<section class="panel">')
    o.append('<h2>Everything that goes inside</h2>')
    o.append('<table><thead><tr><th>Item</th><th>Size / note</th></tr></thead><tbody>')
    for a, b in BOM:
        o.append(f'<tr><td>{a}</td><td class="f">{b}</td></tr>')
    o.append('</tbody></table></section>')

    o.append('<footer>Generated from <code>src/epaper_stand.scad</code> rev D &middot; '
             'of the 13 pairwise interference checks, 10 are empty, 2 are zero-volume '
             'coincident faces by design, and conn_cell is a known 154 mm&sup3; clash &middot; '
             'all five parts one body; four watertight, the cover carrying 10 '
             'zero-volume pinch edges CGAL still rates Simple.</footer>')
    o.append('</div>')
    return "\n".join(o)


if __name__ == "__main__":
    open("drawings/index.html", "w").write(build())
    print("wrote drawings/index.html")
