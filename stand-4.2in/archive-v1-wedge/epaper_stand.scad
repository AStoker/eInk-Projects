// =====================================================================
//  4.2" e-Paper desk frame + kickstand   (TRMNL-inspired)
//
//  Hardware:
//    - Waveshare 4.2inch e-Paper Module (B)   103.0 x 78.5 mm, 400x300
//    - Waveshare e-Paper ESP32 Driver Board    48.25 x 29.46 mm
//
//  Orientation: PORTRAIT (module long axis vertical)
//  Parts:  frame  +  back cover (carries the driver board)  +  kickstand
//
//  Coordinate system while modelling:
//    X = width, Y = depth (0 = front face, +Y toward the back), Z = height
//    (0 = the frame's front-bottom edge).  All dimensions in mm.
// =====================================================================

/* [What to build] */
// frame | cover | kickstand | bezel_test | plate | assembly | standing | section
part = "standing";

/* [Display module - VERIFY BY MEASURING] */
mod_w       = 78.5;   // PCB width  (short axis -> X in portrait)
mod_h       = 103.0;  // PCB height (long axis  -> Z in portrait)
mod_glass_t = 1.2;    // glass thickness in front of the PCB
mod_pcb_t   = 1.6;    // PCB thickness
act_w       = 63.6;   // active (ink) area width
act_h       = 84.8;   // active (ink) area height
// Offset of the ACTIVE-AREA centre from the PCB centre, +X = away from the
// ribbon/connector edge.   <<< THE ONE NUMBER MOST WORTH MEASURING >>>
act_off_x   = 3.7;
act_off_z   = 0.0;
mod_clr     = 0.6;    // clearance per side around the PCB

/* [Driver board] */
brd_w        = 48.25; // long axis  -> X (board lies on its side)
brd_h        = 29.46; // short axis -> Z
brd_t        = 1.6;
brd_standoff = 2.5;   // gap between the cover and the PCB back face
brd_clr      = 0.4;   // per-side clearance in the rails
brd_inset    = 3.5;   // gap between the USB-C end of the PCB and the cavity wall
usb_w        = 13.0;  // USB-C opening height (Z)
usb_y0       = 10.5;  // USB-C opening, front edge ...
usb_y1       = 20.6;  // ... rear edge (= inner face of the cover)

/* [Frame] */
bezel_t      = 2.4;   // front face thickness
back_t       = 2.4;   // back cover thickness
depth        = 23.0;  // total front-to-back, cover included
side_wall    = 8.0;   // minimum side wall thickness
bot_bezel    = 12.0;  // solid material below the module
top_bezel    = 9.0;   // solid material above the module
corner_r     = 5.0;   // outer corner radius
cav_r        = 2.0;   // cavity corner radius
win_margin   = 2.0;   // bezel opening = active area + this all round
win_r        = 2.5;   // window corner radius
win_chf      = 1.2;   // 45 deg chamfer around the window (front face)

/* [Fasteners] */
screw_pilot  = 2.1;   // M2.5 self-tapping pilot hole
screw_free   = 2.8;   // clearance hole in the cover
screw_head   = 5.4;   // counterbore dia
screw_cb     = 1.8;   // counterbore depth
screw_depth  = 8.0;   // boss depth
screw_dx     = 4.0;   // screw axis, in from the left/right outer edge
screw_z0     = 8.5;   // lower screws, above the bottom edge
screw_z1     = 6.0;   // upper screws, below the top edge

/* [Module retention] */
rib_t        = 3.0;   // retention rib thickness
rib_inset    = 2.5;   // rib, in from the cavity edge
rib_gap      = 0.2;   // clearance onto the module PCB (take up with foam tape)

/* [Stance] */
lean         = 12;    // degrees the frame leans back
ks_phi       = 35;    // kickstand leg angle, from straight-down
ks_y         = 13.0;  // socket centre, depth into the frame
ks_z         = 52.0;  // socket centre, height up the frame
ks_t         = 5.0;   // kickstand plate thickness
ks_bar       = 6.0;   // kickstand bar width
ks_gap       = 0.6;   // clearance between the arms and the frame sides
tab_len      = 10.0;  // socket / tab length along the leg
tab_depth    = 4.2;   // how far the tab reaches into the wall
tab_fit      = 0.25;  // per-side clearance on the tab

/* [Render quality] */
$fa = 2; $fs = 0.4;

// ---------------------------------------------------------------- derived
body_d = depth - back_t;             // frame body depth, cover sits behind it

cav_w  = mod_w + 2*mod_clr;
cav_h  = mod_h + 2*mod_clr;
cav_x  = -act_off_x;                 // shift module so the ink lands centred
cav_z0 = bot_bezel;
cav_z1 = cav_z0 + cav_h;
cav_zc = (cav_z0 + cav_z1)/2;
cav_x0 = cav_x - cav_w/2;
cav_x1 = cav_x + cav_w/2;

W = 2*(abs(cav_x) + cav_w/2 + side_wall);
H = cav_z0 + cav_h + top_bezel;

win_w  = act_w + 2*win_margin;
win_h  = act_h + 2*win_margin;
win_zc = cav_zc + act_off_z;

mod_back = bezel_t + mod_glass_t + mod_pcb_t;   // y of the module's back face

// driver board: low in the cavity, USB-C poking out the -X wall
brd_x0 = cav_x0 + brd_inset;
brd_xc = brd_x0 + brd_w/2;
brd_z0 = cav_z0 + rib_inset + rib_t + 1.5;
brd_zc = brd_z0 + brd_h/2;
brd_back = body_d - brd_standoff;               // y of the PCB back face
rail_h   = brd_standoff + brd_t + 1.2;

// kickstand: leg length from the socket down to the table
ks_L = (ks_z - ks_y*tan(lean)) / (cos(ks_phi) + sin(ks_phi)*tan(lean));
ks_arm_x = W/2 + ks_gap + ks_bar/2;

screw_pos = [ for (sx=[-1,1], sz=[0,1])
                [sx*(W/2 - screw_dx), sz==0 ? screw_z0 : H - screw_z1] ];

// ================================================================ helpers
module rrect(w,h,r) {
    hull() for (sx=[-1,1], sy=[-1,1])
        translate([sx*(w/2-r), sy*(h/2-r)]) circle(r=r);
}

// extrude a 2D (x,z) profile along +Y by d
module xzext(d) { rotate([90,0,0]) translate([0,0,-d]) linear_extrude(d) children(); }

// rounded-rect prism: front face at y0, extending +Y
module prism(w,h,r,d,cx=0,cz=0,y0=0) {
    translate([cx,y0,cz]) xzext(d) rrect(w,h,r);
}

// everything below the table once the frame is leaned back by `lean`
module floor_cut() {
    rotate([lean,0,0]) translate([-400,-400,-800]) cube([800,800,800]);
}

module outer_profile(d, y0=0) { prism(W, H, corner_r, d, 0, H/2, y0); }
module cavity(d, y0)          { prism(cav_w, cav_h, cav_r, d, cav_x, cav_zc, y0); }

module window_cut() {
    prism(win_w, win_h, win_r, bezel_t + 1, 0, win_zc, -0.5);
    hull() {
        prism(win_w + 2*win_chf, win_h + 2*win_chf, win_r + win_chf,
              0.01, 0, win_zc, -0.5);
        prism(win_w, win_h, win_r, 0.01, 0, win_zc, win_chf);
    }
}

module usb_cut() {
    translate([-W/2 - 1, usb_y0, brd_zc - usb_w/2])
        cube([W/2 + cav_x0 + 1.5, usb_y1 - usb_y0, usb_w]);
}

module socket(sx) {
    translate([sx*(W/2 - tab_depth/2 + 0.3), ks_y, ks_z])
        rotate([ks_phi,0,0])
            cube([tab_depth + 0.6, ks_t + 2*tab_fit, tab_len + 2*tab_fit],
                 center=true);
}

// ================================================================== frame
module frame() {
    difference() {
        outer_profile(body_d);
        window_cut();
        cavity(body_d, bezel_t);
        usb_cut();
        for (sx=[-1,1]) socket(sx);
        // screw bosses (blind, drilled from the rear face)
        for (p = screw_pos)
            translate([p[0], body_d + 0.1, p[1]]) rotate([90,0,0])
                cylinder(d=screw_pilot, h=screw_depth);
        // cover register recess: 0.8 deep, 0.6 bigger than the cavity all round
        prism(cav_w + 1.2, cav_h + 1.2, cav_r + 0.6, 1.0,
              cav_x, cav_zc, body_d - 0.8);
        floor_cut();
    }
}

// ============================================================= back cover
module cover() {
    difference() {
        union() {
            outer_profile(back_t, body_d);
            // register lip that drops into the recess in the frame
            prism(cav_w + 0.6, cav_h + 0.6, cav_r + 0.3, 0.8,
                  cav_x, cav_zc, body_d - 0.8);
            // ---- module retention ribs (top, bottom, +X side; -X left open
            //      for the module's ribbon/connector and the board)
            rib_len_z = cav_h - 2*rib_inset;
            rib_len_x = cav_w - 2*rib_inset;
            for (sz=[-1,1])
                translate([cav_x, mod_back + rib_gap,
                           cav_zc + sz*(cav_h/2 - rib_inset - rib_t/2)])
                    xzext(body_d - mod_back - rib_gap)
                        square([rib_len_x, rib_t], center=true);
            translate([cav_x1 - rib_inset - rib_t/2, mod_back + rib_gap, cav_zc])
                xzext(body_d - mod_back - rib_gap)
                    square([rib_t, rib_len_z], center=true);

            // ---- driver-board rails (top + bottom edges of the board)
            for (sz=[-1,1])
                translate([brd_xc, body_d - rail_h,
                           brd_zc + sz*(brd_h/2 + brd_clr + 1.4)])
                    xzext(rail_h) square([brd_w + 5, 4.0], center=true);
            // end stops: +X edge, and two short lugs on the -X edge
            translate([brd_x0 + brd_w + brd_clr + 1.5, body_d - rail_h, brd_zc])
                xzext(rail_h) square([3, brd_h - 1], center=true);
            for (sz=[-1,1])
                translate([brd_x0 - brd_clr - 1.6, body_d - rail_h,
                           brd_zc + sz*(brd_h/2 - 3)])
                    xzext(rail_h) square([3, 6], center=true);
        }
        // slot the board slides into (leaves a 1.2 lip on the rails)
        translate([brd_xc, body_d - brd_standoff - brd_t, brd_zc])
            xzext(brd_t + 0.3) square([brd_w + 30, brd_h + 2*brd_clr], center=true);
        // and the pocket its components sit in
        translate([brd_xc, body_d - brd_standoff, brd_zc])
            xzext(brd_standoff + 0.1)
                square([brd_w - 6, brd_h - 6], center=true);

        // screw holes + counterbores
        for (p = screw_pos) {
            translate([p[0], body_d - 0.1, p[1]]) rotate([-90,0,0])
                cylinder(d=screw_free, h=back_t + 1);
            translate([p[0], depth - screw_cb, p[1]]) rotate([-90,0,0])
                cylinder(d=screw_head, h=screw_cb + 1);
        }
        usb_cut();
        floor_cut();
    }
}

// ============================================================== kickstand
module kickstand_2d() {
    r = ks_bar/2;
    v_top  = -7;              // small stub above the socket line
    v_foot = ks_L - r;        // bar centreline, so the bar just kisses the floor
    union() {
        for (sx=[-1,1]) hull() {
            translate([sx*ks_arm_x, v_top])  circle(r=r);
            translate([sx*ks_arm_x, v_foot]) circle(r=r);
        }
        hull() for (sx=[-1,1]) translate([sx*ks_arm_x, v_foot]) circle(r=r);
        for (sx=[-1,1]) {                    // tabs, pointing inward
            x_out = sx*(W/2 + ks_gap);
            x_in  = sx*(W/2 - tab_depth);
            translate([(x_out + x_in)/2, 0])
                square([abs(x_out - x_in), tab_len], center=true);
        }
    }
}

module kickstand_placed() {
    difference() {
        translate([0, ks_y, ks_z]) rotate([ks_phi - 90, 0, 0])
            linear_extrude(ks_t, center=true) kickstand_2d();
        floor_cut();
    }
}

module kickstand() {   // print orientation: flat on the bed
    translate([0,0,ks_t/2])
        rotate([90 - ks_phi, 0, 0]) translate([0, -ks_y, -ks_z])
            kickstand_placed();
}

// ======================================================== bezel test tile
module bezel_test() {
    difference() {
        union() {
            outer_profile(bezel_t);
            // a stub of the cavity wall so the module fit can be checked too
            difference() {
                outer_profile(bezel_t + 4);
                cavity(6, bezel_t);
                prism(win_w + 26, win_h + 26, win_r + 13, 6, 0, win_zc, bezel_t);
            }
        }
        window_cut();
    }
}

// =========================================================== mock hardware
module mock_module() {
    color("#f4f4ef") translate([cav_x, bezel_t, cav_zc])
        xzext(mod_glass_t) rrect(mod_w - 1.5, mod_h - 12, 1);
    color("#22252b") translate([cav_x + act_off_x, bezel_t - 0.3, cav_zc + act_off_z])
        xzext(mod_glass_t + 0.3) rrect(act_w, act_h, 0.5);
    color("#d8d8d0") translate([cav_x, bezel_t + mod_glass_t, cav_zc])
        xzext(mod_pcb_t) rrect(mod_w, mod_h, 1);
}
module mock_board() {
    color("#12481c") translate([brd_xc, brd_back - brd_t, brd_zc])
        xzext(brd_t) square([brd_w, brd_h], center=true);
    color("#2b2b2b") translate([brd_xc + 6, brd_back - brd_t - 3.0, brd_zc])
        xzext(3.0) square([brd_w*0.5, brd_h*0.62], center=true);
    color("#c9ccd1") translate([brd_x0 - 1.0, brd_back - brd_t - 3.2, brd_zc])
        xzext(3.2) square([2.4, 9], center=true);
}

// ================================================================ outputs
module print_orient() { translate([0,0,body_d]) rotate([-90,0,0]) children(); }
module assembly() {
    color("#4c4f57") frame();
    color("#5a5e67") cover();
    color("#3a3d44") kickstand_placed();
    mock_module();
    mock_board();
}

if (part == "frame")            print_orient() frame();
else if (part == "cover")       translate([0,0,depth]) rotate([-90,0,0]) cover();
else if (part == "kickstand")   kickstand();
else if (part == "bezel_test")  print_orient() bezel_test();
else if (part == "assembly")    assembly();
else if (part == "standing")    rotate([-lean,0,0]) assembly();
else if (part == "section")
    difference() { assembly(); translate([-300,-300,-300]) cube([300,600,600]); }
else if (part == "plate") {
    translate([-70,   0, 0]) print_orient() frame();
    translate([ 40,   0, 0]) translate([0,0,depth]) rotate([-90,0,0]) cover();
    translate([ 40,-100, 0]) kickstand();
}

echo(str("Frame outer  W x H x D = ", W, " x ", H, " x ", depth));
echo(str("Window opening         = ", win_w, " x ", win_h));
echo(str("Bezel: side ", (W-win_w)/2, "  bottom ", win_zc-win_h/2,
         "  top ", H-(win_zc+win_h/2)));
echo(str("Lip over module: left ", (cav_x1) - win_w/2 - mod_clr,
         "  right ", 0));
echo(str("Kickstand leg length   = ", ks_L));
echo(str("Footprint depth        = ",
     (ks_y + ks_L*sin(ks_phi))*cos(lean) + (ks_z - ks_L*cos(ks_phi))*sin(lean)));

// ---------------------------------------------------------------- checks
// interference checks: render each pair and measure the resulting volume.
// Anything non-zero (beyond rounding) is a collision.
chk = "";
if (chk == "frame_module")   intersection(){ frame(); mock_module(); }
if (chk == "cover_module")   intersection(){ cover(); mock_module(); }
if (chk == "cover_board")    intersection(){ cover(); mock_board(); }
if (chk == "frame_board")    intersection(){ frame(); mock_board(); }
if (chk == "frame_cover")    intersection(){ frame(); cover(); }
if (chk == "frame_ks")       intersection(){ frame(); kickstand_placed(); }
if (chk == "cover_ks")       intersection(){ cover(); kickstand_placed(); }
