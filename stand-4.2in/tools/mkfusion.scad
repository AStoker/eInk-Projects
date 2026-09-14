// =====================================================================
//  Fusion hand-off exports.
//
//  Everything here is produced from src/epaper_stand.scad itself, in the
//  MODEL's own coordinate system - X short axis, Y depth (0 = outer front
//  face), Z long axis (0 = bottom edge) - not in print orientation.  That is
//  the whole point: the meshes, the DXF sketches, the keep-out bodies and
//  fusion/parameters.csv all land on the same origin, so anything imported
//  into Fusion lines up with everything else without being moved.
//
//  part="none" is passed on the command line so the model's own output
//  dispatch renders nothing and only the target below is emitted.
//
//  Driven by tools/mkfusion.sh - see that file for the full export list.
// =====================================================================
include <../src/epaper_stand.scad>

// mesh: frame | cover | leg | keepouts
// dxf : front | pocket | cavity | cover_in | cover_back | side | leg_side | layout
target = "frame";

// ---------------------------------------------------------- section planes
// A section normal to Y (a front view at depth y0) lands the model's XZ plane
// on the sketch plane: sketch X = model X, sketch Y = model Z.
module sec_y(y0) projection(cut=true) translate([0,0,y0]) rotate([-90,0,0]) children();
// A section normal to X (a side view at x0): sketch X = model Z, sketch Y = model Y.
module sec_x(x0) projection(cut=true) translate([0,0,x0]) rotate([0,90,0]) children();
// The silhouette seen from the front, no cut.
module plan()   projection(cut=false) rotate([-90,0,0]) children();

// ------------------------------------------------------------- keep-outs
// Every envelope the electronics claim: name, X centre, X size, Y start, Y
// depth, Z centre, Z size.  ALL BOXES, including the cell - the real pouch has
// R2 corners, and a keep-out that ignores them is the conservative way round.
//
// tools/mkfusion.py builds the same list from the same parameter dump for
// fusion/keepouts.csv and for the Fusion script, so the two cannot disagree
// unless one of them is edited by hand.  Don't.
ko = [
  ["PANEL_GLASS",    pan_px, pan_w, front_t+0.15, pan_t, Zc+pan_off_z, pan_h],
  ["FPC_HOLLOW",     pan_px - (pan_w + 2*pan_clr_w)/2 - rib_clr/2, rib_clr,
                     front_t, pan_t + rib_dep, rib_cz, rib_w],
  ["DRIVER_BOARD",   drv_cx, drv_w, drv_back - drv_env, drv_env, drv_cz, drv_h],
  ["DRIVER_CARRIER", carrier_cx, carrier_w, carrier_face, carrier_t, carrier_cz, carrier_h],
  ["FPC_ADAPTER",    adapt_cx, adapt_w, mod_back, adapt_env, adapt_cz, adapt_h],
  ["CHARGER",        chg_x_c, chg_w, chg_back - chg_t, chg_t, chg_z, chg_h],
  ["CELL",           bat_cx, bat_w, rec_back - bat_t, bat_t, bat_cz, bat_h],
  ["USB_C_PIGTAIL",  ucb_x, snap_w, cov_in - snap_d, snap_d, ucb_z, snap_h],
];
fitted = [ for (b = ko)
             if (!(b[0]=="DRIVER_CARRIER" && !carrier_fit) &&
                 !(b[0]=="FPC_ADAPTER"    && !adapt_fit)   &&
                 !(b[0]=="USB_C_PIGTAIL"  && !port_snap)) b ];

module keepouts(){
    for (b = fitted)
        translate([b[1], b[3], b[5]]) xzext(b[4]) square([b[2], b[6]], center=true);
}
// The same footprints in plan, as OUTLINES.  Drawn in 2D rather than projected:
// the boxes overlap in plan (the cell sits behind the charger's column), and a
// projection unions them into one silhouette, which loses the very thing the
// sketch is for.
lay_t = 0.1;                        // outline thickness
module keepouts_plan(){
    for (b = fitted)
        translate([b[1], b[5]]) difference(){
            square([b[2], b[6]], center=true);
            square([b[2] - 2*lay_t, b[6] - 2*lay_t], center=true);
        }
}

// ------------------------------------------------------------------ mesh
if      (target=="frame")      frame();
else if (target=="cover")      cover();
else if (target=="leg")        leg_placed(0);      // as fitted, folded
else if (target=="keepouts")   keepouts();
// ------------------------------------------------------------------- dxf
else if (target=="front")      plan() frame();
else if (target=="pocket")     sec_y(front_t + pan_t/2) frame();
else if (target=="cavity")     sec_y(mod_back + 4) frame();
else if (target=="cover_in")   sec_y(cov_in - 0.5) cover();
else if (target=="cover_back") plan() cover();
else if (target=="side")       sec_x(0) union(){ frame(); cover(); }
else if (target=="leg_side")   sec_x(0) leg_placed(0);
else if (target=="layout")     keepouts_plan();
