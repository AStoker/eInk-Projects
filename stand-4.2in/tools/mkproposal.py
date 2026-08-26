#!/usr/bin/env python3
"""Proposal drawing for the kickstand redesign: a lever leg with a mechanical stop.

Standalone on purpose - it does NOT read the model's parameter dump, because the
parameters it draws do not exist in the model yet.  That is the point: this is the
drawing to agree BEFORE any geometry is cut.  Once agreed, these numbers move into
src/epaper_stand.scad and this script is deleted - the real sheets are generated
from the model's own dump by mkdrawings.py so they cannot drift from the STLs.

    python3 tools/mkproposal.py   ->  drawings/proposal-leg.svg
"""
import math, os

# ------------------------------------------------------------ existing, unchanged
H, DEPTH       = 110.5, 25.0
BODY_D         = 23.6          # frame/cover joint
CAV_Z0         = 9.0           # interior starts here; below it, solid frame behind
BACK_Z0, BACK_Z1 = 2.0, 108.5  # back face, after the 2.0 rear chamfer
BACK_W         = 87.9
SCR_X, SCR_Z   = 40.45, 5.5
UCB_X, UCB_Z   = 22.0, 11.75
SNAP_W, SNAP_H = 14.0, 4.5

# ------------------------------------------------------------------ the proposal
DEP_ANG = 35.0                       # swing from folded
LEG_LEN = 55.0                       # pivot to foot tip
FOOT_Z  = 3.0                        # folded foot tip stops here - CLEAR of the chamfer
PIV_Z   = LEG_LEN + FOOT_Z           # 58
PIV_H   = 2.5                        # pin above the recess floor
REC_DEP, REC_SHL = 4.5, 1.0          # recess: deep / shallow (over the frame end wall)
REC_W   = 16.0
LEG_T, LEG_TF = 4.0, 1.0             # leg thickness at the pivot / at the foot tip
LEG_W   = 14.0
PIN_D   = 2.0                        # the pin, kept
DET_D   = 0.25                       # detent pocket depth below the recess floor
STUB_A  = 90.0 - DEP_ANG/2           # 72.5 - the symmetry that gives TWO pockets
STUB_L  = (PIV_H + DET_D)/math.sin(math.radians(STUB_A))
HUMP    = STUB_L - PIV_H             # the dig between the pockets = the snap

FZ       = PIV_Z - LEG_LEN*math.cos(math.radians(DEP_ANG))
STANDOFF = LEG_LEN*math.sin(math.radians(DEP_ANG))
LEAN     = math.degrees(math.atan2(FZ, STANDOFF))
FOOTPR   = STANDOFF*math.cos(math.radians(LEAN)) + FZ*math.sin(math.radians(LEAN))
REC_TOP  = PIV_Z + STUB_L + 3.0

o=[]
def esc(s): return (str(s).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
                    .replace("°","&#176;").replace("Ø","&#216;").replace("−","&#8722;"))
def ln(a,b,c="part"): o.append(f'<line x1="{a[0]:.2f}" y1="{a[1]:.2f}" x2="{b[0]:.2f}" y2="{b[1]:.2f}" class="{c}"/>')
def pl(p,c="part",close=True):
    o.append('<path d="M'+" L".join(f"{x:.2f},{y:.2f}" for x,y in p)+(" Z" if close else "")+f'" class="{c}"/>')
def rc(a,w,h,c="part",r=0):
    o.append(f'<rect x="{a[0]:.2f}" y="{a[1]:.2f}" width="{w:.2f}" height="{h:.2f}" rx="{r}" class="{c}"/>')
def ci(a,d,c="part"): o.append(f'<circle cx="{a[0]:.2f}" cy="{a[1]:.2f}" r="{d/2:.2f}" class="{c}"/>')
def tx(a,s,c="note",sz=3.0,an="middle"):
    o.append(f'<text x="{a[0]:.2f}" y="{a[1]:.2f}" class="{c}" font-size="{sz}" text-anchor="{an}">{esc(s)}</text>')
def lead(a,b,s,sz=2.6,an="start"):
    ln(a,b,"lead"); tx((b[0]+(1.5 if an=="start" else -1.5),b[1]+0.9),s,"note",sz,an)
def dh(x1,x2,y,s,sz=2.7):
    ln((x1,y),(x2,y),"dim"); ln((x1,y-1.6),(x1,y+1.6),"dim"); ln((x2,y-1.6),(x2,y+1.6),"dim")
    tx(((x1+x2)/2,y-1.3),s,"dim",sz)
def dv(y1,y2,x,s,sz=2.7):
    ln((x,y1),(x,y2),"dim"); ln((x-1.6,y1),(x+1.6,y1),"dim"); ln((x-1.6,y2),(x+1.6,y2),"dim")
    o.append(f'<text x="{x-1.5:.2f}" y="{(y1+y2)/2:.2f}" class="dim" font-size="{sz}" '
             f'text-anchor="middle" transform="rotate(-90 {x-1.5:.2f} {(y1+y2)/2:.2f})">{esc(s)}</text>')

# ==================================================== VIEW 1  BACK FACE, 1:1
BX, B0 = 66.0, 172.0
def V1(x,z): return (BX+x, B0-z)
tx((BX, 52.0), "1   BACK FACE", "vlabel", 5.0)
tx((BX, 58.0), "leg on the centreline, straight down the long axis", "sub", 3.0)
rc(V1(-BACK_W/2, BACK_Z1), BACK_W, BACK_Z1-BACK_Z0, "part", 3)
pl([V1(-REC_W/2,REC_TOP), V1(REC_W/2,REC_TOP), V1(REC_W/2,FOOT_Z-1.2),
    V1(-REC_W/2,FOOT_Z-1.2)], "cut")
ln(V1(-REC_W/2,CAV_Z0+0.5), V1(REC_W/2,CAV_Z0+0.5), "hid")
pl([V1(-LEG_W/2,PIV_Z+STUB_L), V1(LEG_W/2,PIV_Z+STUB_L), V1(LEG_W/2,FOOT_Z+5),
    V1(3.0,FOOT_Z), V1(-3.0,FOOT_Z), V1(-LEG_W/2,FOOT_Z+5)], "leg")
ci(V1(0,PIV_Z), PIN_D+0.6, "cut")
ln(V1(-REC_W/2-9,PIV_Z), V1(REC_W/2+9,PIV_Z), "cl")
ln(V1(0,FOOT_Z-6), V1(0,REC_TOP+7), "cl")
for sx in (-1,1):
    ci(V1(sx*SCR_X,SCR_Z), 5.0, "hid"); ci(V1(sx*SCR_X,H-SCR_Z), 5.0, "hid")
rc(V1(UCB_X-SNAP_W/2, UCB_Z+SNAP_H/2), SNAP_W, SNAP_H, "hid")
lead(V1(UCB_X-SNAP_W/2, UCB_Z), (BX+34, B0-30), "USB-C pigtail")
lead(V1(-SCR_X, SCR_Z), (BX-56, B0+4), "M2.5 corner screws")
lead(V1(REC_W/2, CAV_Z0+0.5), (BX+44, B0-14), "recess steps to 1.0 —")
tx((BX+45.5, B0-10.2), "solid frame behind", "note", 2.6, "start")
lead(V1(-3.0, FOOT_Z), (BX-40, B0+9), f"foot tip stops at z {FOOT_Z:.0f} —", 2.6, "end")
tx((BX-41.5, B0+12.8), "clear of the 2.0 chamfer,", "note", 2.6, "end")
tx((BX-41.5, B0+16.6), "nothing overhangs", "note", 2.6, "end")
dv(V1(0,FOOT_Z)[1], V1(0,PIV_Z)[1], BX-BACK_W/2-7, f"leg_len {LEG_LEN:.0f}")
dh(V1(-REC_W/2,0)[0], V1(REC_W/2,0)[0], B0+22, f"rec_w {REC_W:.0f}")
tx((BX+30, B0+27), f"piv_z {PIV_Z:.0f}   leg_w {LEG_W:.0f}", "note", 2.8)
tx((BX+30, B0+31.5), "clears the screws by 32.4", "note", 2.8)

# ================================= VIEW 2  SECTION THROUGH THE PIVOT, 1.5:1
S=1.5; AX, A0 = 232.0, 172.0
def V2(y,z): return (AX-(y-DEPTH)*S, A0-z*S)
tx((AX-26, 52.0), "2   SECTION AT THE PIVOT   1.5:1", "vlabel", 5.0)
tx((AX-26, 58.0), f"swings {DEP_ANG:.0f}° — under 90°, so the stub cannot dive", "sub", 3.0)
pl([V2(DEPTH,BACK_Z0), V2(DEPTH,REC_TOP+12), V2(BODY_D,REC_TOP+12), V2(BODY_D,BACK_Z0)], "part")
pl([V2(BODY_D,BACK_Z0), V2(BODY_D,CAV_Z0), V2(BODY_D-8.0,CAV_Z0), V2(BODY_D-8.0,BACK_Z0)], "frame")
lead(V2(BODY_D-4.0, BACK_Z0+3.5), (AX-44, A0-5), "frame end wall")
fy = DEPTH-REC_DEP; py = fy+PIV_H
pl([V2(DEPTH,REC_TOP), V2(fy,REC_TOP), V2(fy,CAV_Z0+0.5),
    V2(DEPTH-REC_SHL,CAV_Z0+0.5), V2(DEPTH-REC_SHL,FOOT_Z-1.2), V2(DEPTH,FOOT_Z-1.2)], "cut")
ci(V2(py,PIV_Z), PIN_D*S, "cut")
pl([V2(DEPTH,PIV_Z+STUB_L), V2(DEPTH-LEG_T,PIV_Z+STUB_L), V2(DEPTH-LEG_T,FOOT_Z+6),
    V2(DEPTH-LEG_TF,FOOT_Z), V2(DEPTH,FOOT_Z)], "leg")
ca,sa = math.cos(math.radians(DEP_ANG)), math.sin(math.radians(DEP_ANG))
def R(dz,dn): return (py + dz*sa + dn*ca, PIV_Z - dz*ca + dn*sa)
pl([V2(*R(-1.2,0)), V2(*R(-1.2,-LEG_T)), V2(*R(LEG_LEN,-LEG_TF)), V2(*R(LEG_LEN,0))], "legd")
lead(V2(DEPTH-LEG_T/2, PIV_Z+STUB_L-1), (AX+6, A0-(PIV_Z+STUB_L)*S), "folded — flush")
lead(V2(*R(LEG_LEN*0.5,-LEG_T)), (AX-42, A0-26), f"deployed  {DEP_ANG:.0f}°")
tx((AX-40.5, A0-22.2), f"lean {LEAN:.1f}°   footprint {FOOTPR:.1f}", "note", 2.6, "start")
dh(V2(DEPTH,0)[0], V2(fy,0)[0], A0+10, f"rec_dep {REC_DEP}")
tx((AX-22, A0+20), f"leg_t {LEG_T} at the pivot, {LEG_TF} at the tip", "note", 2.8)
tx((AX-22, A0+25), "today: lean 20.5°, footprint 31.9", "note", 2.8)
ci(V2(py,PIV_Z), 20.0, "detmark")
lead(V2(py+6.5, PIV_Z+6.5), (AX-4, A0-PIV_Z*S-22), "see 3")

# ============================================= VIEW 3  PIVOT DETAIL, 6:1
D6=6.0; DX, DY = 344.0, 116.0
def V3(dz,dep): return (DX - dz*D6, DY + dep*D6)
tx((DX-6, 52.0), "3   PIVOT DETAIL   6:1", "vlabel", 5.0)
tx((DX-6, 58.0), "two indents, one stub", "sub", 3.0)
zc = STUB_L*math.cos(math.radians(STUB_A))
w  = 1.5
pl([V3(9.0,PIV_H), V3(zc+w/2,PIV_H), V3(zc+w/2,PIV_H+DET_D), V3(zc-w/2,PIV_H+DET_D),
    V3(zc-w/2,PIV_H), V3(-zc+w/2,PIV_H), V3(-zc+w/2,PIV_H+DET_D),
    V3(-zc-w/2,PIV_H+DET_D), V3(-zc-w/2,PIV_H), V3(-9.0,PIV_H),
    V3(-9.0,PIV_H+3.4), V3(9.0,PIV_H+3.4)], "part")
tx(V3(0.0, PIV_H+2.6), "recess floor", "note", 2.4)
arc=[V3(STUB_L*math.cos(math.radians(STUB_A+t)), STUB_L*math.sin(math.radians(STUB_A+t)))
     for t in [i*DEP_ANG/24.0 for i in range(25)]]
pl(arc,"arc",close=False)
for th,cl in ((0.0,"leg"),(DEP_ANG,"legd")):
    a1=math.radians(STUB_A+th); a2=math.radians(STUB_A+th-90)
    tip=(STUB_L*math.cos(a1), STUB_L*math.sin(a1))
    pl([V3(0,0), V3(tip[0]+1.4*math.cos(a2), tip[1]+1.4*math.sin(a2)),
        V3(tip[0]-1.4*math.cos(a2), tip[1]-1.4*math.sin(a2))], cl)
ci(V3(0,0), PIN_D*D6, "cut")
o.append(f'<path d="M{V3(-1.9,-1.9)[0]:.2f},{V3(-1.9,-1.9)[1]:.2f} '
         f'A{1.55*D6:.2f},{1.55*D6:.2f} 0 1 1 {V3(1.9,-1.9)[0]:.2f},{V3(1.9,-1.9)[1]:.2f}" class="socket"/>')
lead(V3(-2.3,-1.5), (DX+14, DY-24), "C socket in the ear —")
tx((DX+15.5, DY-20.2), f"the pin snaps in, and lifts", "note", 2.6, "start")
tx((DX+15.5, DY-16.4), f"{HUMP:.2f} to ride the hump", "note", 2.6, "start")
lead(V3(zc,PIV_H+DET_D), (DX-26, DY+30), "closed indent", 2.6, "end")
lead(V3(-zc,PIV_H+DET_D), (DX+12, DY+34), "deployed indent")
tx((DX+13.5, DY+37.8), "+ hard stop", "note", 2.6, "start")
lead(V3(0,STUB_L), (DX-24, DY+19), f"hump {HUMP:.2f}", 2.6, "end")
dv(V3(0,0)[1], V3(0,PIV_H)[1], DX+10, f"piv_h {PIV_H}")
tx((DX-2, DY+50), f"stub {STUB_L:.2f} at {STUB_A:.1f}°  ·  indent {DET_D}", "note", 2.7)
tx((DX-2, DY+55), f"{STUB_A:.1f}° = 90° − dep_ang/2, which is what puts", "note", 2.7)
tx((DX-2, DY+59.5), "the tip on the floor at BOTH ends", "note", 2.7)

# ==================================================================== notes
NX, NY = 20.0, 208.0
for i,s in enumerate([
 "1   The leg is a LEVER.  Beyond the pin sits a stub; at dep_ang it bottoms in the deployed indent, so the load path is",
 "     leg → stub → cover, in COMPRESSION.  Nothing is held out by friction or by a spring, which is what the disc design",
 "     had been reduced to — and why it did not hold.",
 "2   The swing is 35°, under 90° on purpose.  Past 90° the stub dives below the floor — that is exactly the 1.80 mm jam",
 "     at 64° the old 122° swing produced.  Under 90° it cannot recur; it is not merely avoided.",
 "3   TWO INDENTS FROM ONE STUB.  Set the stub at 90° − dep_ang/2 and its tip reaches the floor at BOTH ends of the",
 "     stroke, digging 0.38 into the floor plane in between.  That dig is the snap: one indent holds it closed, one holds",
 "     it deployed, and the deployed indent's far wall is the hard stop.  Under load the stub is pushed INTO its indent.",
 "4   The Ø2 pin is kept — pressed through the leg, snapped into C sockets in the cover's ears.  Those sockets are also",
 "     the spring: the pin lifts 0.38 to ride the hump.  No screw, no insert, and the leg pops out for service.",
 "5   The folded foot tip stops at z 3.0, clear of the 2.0 rear chamfer, so NOTHING overhangs the bottom edge.  Below",
 "     z 9 the cover is backed by solid frame, so the recess steps to 1.0 and the leg tapers to 1.0 at the tip.",
 "6   PORTRAIT ONLY.  The rotating disc, bayonet, four rotation detents, clamp land, flexure tongue and detent bridge",
 "     are all deleted.  The recess misses the driver carrier entirely, so removing the puck keeps its full 4.55 mm.",
 "7   TO CHECK: the recess ceiling is a 16 mm bridge in the cover's current print orientation.  May want the cover",
 "     printed the other way up, or a bridging rib across the recess.",
]): tx((NX, NY+i*4.85), s, "note", 2.85, "start")

rc((8,8), 404, 281, "border")
ln((8,32),(412,32), "border"); ln((8,202),(412,202), "border")
tx((210, 17.5), "PROPOSAL — kickstand redesign:  lever leg, mechanical stop, two indents, no rotating disc",
   "vlabel", 5.4)
tx((210, 25.0), "4.2\" e-Paper desk frame   ·   for review before any geometry is cut   ·   2026-08-26",
   "sub", 3.0)

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 420 297" width="1680" height="1188">
<style>
 text {{ font-family:"Helvetica Neue",Helvetica,Arial,sans-serif; fill:#16181c; }}
 .vlabel {{ font-weight:600; }} .sub {{ fill:#5b636c; }} .note {{ fill:#2f353c; }}
 .dim {{ fill:#0a6ea6; stroke:#0a6ea6; stroke-width:0.2; }} line.dim {{ fill:none; }}
 .part {{ fill:#f6f7f9; stroke:#16181c; stroke-width:0.5; }}
 .frame {{ fill:#e6e9ec; stroke:#16181c; stroke-width:0.4; }}
 .cut  {{ fill:#ffffff; stroke:#16181c; stroke-width:0.4; }}
 .hid  {{ fill:none; stroke:#9aa1a9; stroke-width:0.32; stroke-dasharray:1.8 1.2; }}
 .cl   {{ fill:none; stroke:#c4652f; stroke-width:0.25; stroke-dasharray:5 1.4 1.2 1.4; }}
 .lead {{ fill:none; stroke:#5b636c; stroke-width:0.22; }}
 .leg  {{ fill:#e2e7ed; stroke:#16181c; stroke-width:0.5; }}
 .legd {{ fill:#b9c5d2; stroke:#16181c; stroke-width:0.55; }}
 .arc  {{ fill:none; stroke:#b3261e; stroke-width:0.45; stroke-dasharray:2.2 1.4; }}
 .socket {{ fill:none; stroke:#16181c; stroke-width:0.8; }}
 .detmark {{ fill:none; stroke:#0a6ea6; stroke-width:0.35; stroke-dasharray:3 1.6; }}
 .border {{ fill:none; stroke:#16181c; stroke-width:0.6; }}
</style>
{chr(10).join(o)}
</svg>
'''
os.makedirs("drawings", exist_ok=True)
open("drawings/proposal-leg.svg","w").write(svg)
print("wrote drawings/proposal-leg.svg")
print(f"  dep_ang {DEP_ANG:.0f}  leg_len {LEG_LEN:.0f}  piv_z {PIV_Z:.0f}  foot tip z {FOOT_Z:.0f}")
print(f"  lean {LEAN:.1f}  footprint {FOOTPR:.1f}   (today 20.5 / 31.9)")
print(f"  stub {STUB_L:.2f} at {STUB_A:.1f} deg   indent {DET_D}   hump {HUMP:.2f}")
