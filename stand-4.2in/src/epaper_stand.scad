// =====================================================================
//  4.2" e-Paper desk frame  -  v2  "minimal bezel + rotating kickstand"
//  Waveshare 4.2inch e-Paper Module (B) + e-Paper ESP32 Driver Board
//
//  Frame  : 17 mm deep, bezel = the panel's own dead border + ~2 mm plastic
//  Cover  : full back, carries the driver board + the stand pocket
//  Disc   : bayonets into the pocket, rotates in 90 deg detents (P <-> L)
//  Leg    : folds flush into the disc, swings out to a hard stop
//
//  ----------------------------------------------------------------- axes
//  X = short axis, Y = depth (0 = front face), Z = long axis (0 = bottom edge)
//
//  Say SHORT AXIS and LONG AXIS, never width/height, for anything belonging to
//  the display.  Width and height swap over when the frame is turned, so a
//  measurement called "width" is ambiguous unless the orientation is also
//  stated - which is how 91 and 77.5 both got read as the wrong dimension once.
//    short axis  glass 76, PCB 78.5.  The ribbon leaves the glass on this axis.
//                Model X.  Horizontal in portrait (the default).
//    long  axis  glass 90, PCB 103.  Model Z.  Vertical in portrait.
//    depth       normal to the glass, 0 at the outer front face.  Model Y.
//                This is the axis that points UP off the print bed, so "taller"
//                or "more room on top" in slicer terms means DEEPER here.
//
//  ------------------------------------------------- the three nested recesses
//  Front to back, each with its own name.  They are not interchangeable:
//    WINDOW       the through-opening the ink is seen through.  win_w x win_h.
//    GLASS POCKET the shallow step the glass sits in.  pan_* parameters.
//    PCB CAVITY   the deep recess behind it, for the module PCB.  cav_* .
//
//  ---------------------------------------------------------------- vocabulary
//  BEZEL      the visible plastic between the window edge and the outer edge.
//             Never the pocket, and not a "bevel" - a bevel is an angled edge.
//  CHAMFER    a 45 deg edge break: front_chf, win_chf, rear_chf.
//  CLEARANCE  the gap between a part and the recess holding it.  Quoted as the
//  (= MARGIN)  TOTAL across an axis, not per side: "margin 1.5 on the short
//             axis" means 0.75 a side.
//  RELIEF     material taken away at a CORNER so a sharp-cornered part can seat
//             in a printed corner.  Always centred on the corner - that is the
//             whole function, so it cannot be "moved inboard".  Two of them,
//             and they are different things:
//               pocket relief  pan_rel, at the glass pocket corners
//               cavity relief  cav_rel, at the PCB cavity corners
//  RIBBON RELIEF  the notch in the short-axis edge for the ribbon's 180 deg
//             fold.  Three independent sizes, deliberately not called w/h/d:
//               OUT   rib_clr, outboard from the pocket edge (short axis)
//               DEEP  rib_dep, past the glass back face (depth)
//               LONG  rib_w,  along the pocket edge (long axis)
//  WHITE SHOW white_show_short / white_show_long, the panel's own white border left
//             visible inside the window on purpose.  One per axis.
//
//  ------------------------------------------------------------------- parts
//  FRAME front shell | COVER back | DISC rotating puck | LEG kickstand |
//  BEZEL TEST TILE  the front-face-only print for checking fit before the frame
// =====================================================================

/* [What to build] */
// frame | cover | disc | leg | bezel_test | plate | standing_p | standing_l | exploded
part = "standing_p";

/* [Display module] */
pcb_w = 78.5; pcb_h = 103.0; pcb_t = 1.6;
// glass and ink, MEASURED on the actual module (Andy, rev E):
//   glass 76 x 90, sharp corners.  Dead border 3.0 on three sides,
//   9.4 on the ribbon side (that is the "10 mm" one, on the 76 axis).
pan_w = 76.0; pan_h = 90.0;  pan_t = 1.05;
act_w = 63.6; act_h = 84.8;
bez_thin = 3.0;                     // dead border, three sides
bez_thick = pan_w - act_w - bez_thin;   // ribbon side  -> 9.4
pan_off_x = 0.0; pan_off_z = 0.0;   // glass centre vs PCB centre  <- STILL TO MEASURE
act_off_x = (bez_thick - bez_thin)/2;   // ink centre vs glass centre -> 3.2
act_off_z = 0.0;
mod_clr = 0.5;
cav_rel = 0;                        // cavity corner relief: NOT NEEDED any more.  It only
                                    // ever existed because cav_r was 2.0, which is larger
                                    // than a sharp PCB corner can sit in - the corner poked
                                    // 0.121 mm past the arc, so a relief circle was added
                                    // to cut it away.  Shrinking cav_r below 1.707 fixes
                                    // the cause instead; frame_module is clear at cav_rel=0
                                    // with cav_r=1.5, with 0.086 mm to spare.
pan_clr_w = 0.75;                   // pocket clearance per side across the WIDTH (76 axis)
pan_clr_h = 0.75;                   //   ... and across the LONG axis.  Deliberately loose
                                    //   (1.5 mm total): a printed 91.0 measured short, so
                                    //   this is sized for print variance and the glass is
                                    //   taped rather than press-fitted.
pan_r   = 0.5;                      // pocket corner radius (relief handles sharp corners)
pan_rel = 1.4;                      // pocket corner relief, so sharp glass corners seat
rib_w   = 40.0;                     // ribbon relief LONG, along the long axis.  rib_off
                                    // pins the bottom end, so raising this extends the
                                    // slot upward (+Z) only - it does not recentre.
rib_off = 15.0;                     // glass -Z edge to the near edge of the slot.
                                    // Measured 15 from the top edge and 35 from the other,
                                    // and the model's -Z IS that top edge - do not "fix"
                                    // this to 35, that was the reversed reading.
                                    // 15 + 40 + 35 = 90, closing against the 90 glass.
                                    // Corroborated by conn_dz: the 8-pin header sits on
                                    // the -Z strip too, which is where the ribbon has to
                                    // fold back to.
rib_clr = 3.0;                      // lateral room it needs to bend back around (OUT)
rib_dep = 3.0;                      // ... and how far BEHIND the glass back face that
                                    // relief runs, so the 180 deg fold has somewhere to
                                    // go.  Measured off the glass, not off the front
                                    // face.  Without this the relief is only as deep as
                                    // the glass pocket and the fold hits solid frame.
wall_rib = 1.0;                     // minimum wall left outboard of the ribbon notch

/* [Internal layout] */
// Waveshare driver board, USB-C to +Z.  MEASURED ENVELOPE 30 x 50 x 15 - drv_env
// is the one that matters for fit; drv_t is just the bare PCB, used by the rails
// that grip its edge.  The model used to carry only drv_t, which made the board
// look 1.6 mm thick and hid the depth problem completely.
drv_w = 30.0; drv_h = 50.0; drv_t = 1.6;
drv_env = 15.0;                               // total depth, board + tallest part
drv_stand = 2.0; drv_clr = 0.4;
proto_w = 43.2; proto_h = 50.8; proto_t = 1.6; // Perma-Proto quarter-size
proto_hole_sp = 35.6; proto_stand = 3.0;
bat_w = 44.0; bat_h = 49.0; bat_t = 6.9;       // 2000 mAh LiPo, 694449 pouch
bat_clr = 0.8; bat_fence = 1.0;
// charger breakout: "bq25185" (Adafruit 6091) or "bq24074" (Adafruit 4755)
chg_part = "bq25185";
chg_w = (chg_part == "bq25185") ? 32.0 : 25.4;
chg_h = (chg_part == "bq25185") ? 26.3 : 20.3;
chg_t = 7.2;                                   // board + USB-C jack, off the proto face
// ---- module 8-pin header keep-out.  MEASURE ALL FOUR ON YOUR BOARD.
conn_h  = 9.0;   // how far it stands off the PCB back, mated, incl. wire bend
conn_w  = 20.0;  // envelope across X
conn_l  = 7.0;   // envelope across Z
conn_dx = 0.0;   // header centre, X, relative to the PCB centre
conn_dz = -44.5; // header centre, Z, relative to the PCB centre (bottom strip)
usb_w = 13.0;    // port opening width
btn_n = 0;       // side buttons: 0 = none, 3 = three on the +X edge
btn_d = 4.2; btn_sp = 12.0;

/* [Print orientation] */
// Every part is exported with its flattest face on the bed, so nothing needs
// supports and nothing needs rotating in the slicer.
// print_mirror mirrors every part in X at export time.  It changes the
// HANDEDNESS of the design: the ribbon relief, the screw spine and both ports
// all move to the opposite side.  Applied to ALL five parts, so they still
// mate with each other -- but the assembly only fits a module whose ribbon is
// on the mirrored side.  Set false to go back to the as-designed hand.
// (The interference checks run on the un-mirrored geometry and are unaffected.)
print_mirror = true;

/* [Body] */
depth = 25.0; front_t = 1.4; cover_t = 1.4; pk_floor_t = 1.8;
wall = 2.2;
// The panel's own white border left visible inside the window, per axis.  Split
// because the window is specified on the short axis (65.0) but the long axis was
// not: one shared value cannot do both.
white_show_short = 0.7;             // -> win_w = 63.6 + 1.4 = 65.0
white_show_long  = 1.3;             // -> win_h = 84.8 + 2.6 = 87.4
corner_r = 5.0; cav_r = 1.5; front_chf = 0.8; win_chf = 0.9; rear_chf = 2.0;

/* [Fixings] */
scr_pilot = 2.1; scr_free = 2.8; scr_head = 5.4; scr_cb = 1.6; scr_depth = 8.0;

/* [Glass retention] */
// The pocket is deliberately loose, so the glass is taped rather than press-
// fitted, and it is taped from BEHIND: tape runs across the glass back face,
// over the pocket edge, and onto the ledge at pcb_face_y.
// Two pads, one at each long-axis end, each running along the short axis.  That
// is the only place they can go - the ledge is 6.25 mm at the long-axis ends but
// only 1.0 mm on the short-axis sides, which is too narrow to stick to.
// The pads are RECESSED because the PCB front face lands on that same ledge, so
// tape lying on top of it would push the module back by its own thickness.
tape_pad   = true;
tape_len   = 40.0;                  // along the SHORT axis (the strip's length)
tape_reach = 5.0;                   // along the LONG axis, out from the pocket
                                    //   edge into the 6.25 mm ledge
tape_dep   = 0.3;                   // recessed into the ledge at pcb_face_y

/* [Module retention] */
rib_t = 2.5; rib_inset = 3.0; rib_gap = 0.25; rib_pad = 7.0;

/* [Kickstand] */
disc_d = 54.0; disc_t = 4.0; pocket_c = 0.35;
lug_out = 1.3; lug_t = 1.3; lug_ang = 26; gap_ang = 34;
groove_y0 = 1.4;                 // groove position, from the pocket floor
pivot_r = 16.0; pin_d = 2.0;
leg_len = 35.4; leg_w = 12.0; leg_t = 3.4; leg_slot_c = 0.5;
foot_r = 5.0; stop_ang = 58;     // deployed leg angle from straight down
detent_r = 22.0; detent_d = 3.0; // rotation detents

/* [Quality] */
$fa = 2; $fs = 0.4;

// ------------------------------------------------------------- derived
body_d = depth - cover_t;
cav_w = pcb_w + 2*mod_clr;  cav_h = pcb_h + 2*mod_clr;
pcb_px = -act_off_x;  pan_px = pcb_px + pan_off_x;
half_cav = abs(pcb_px) + pcb_w/2 + mod_clr + wall;          // set by the PCB cavity
half_rib = abs(pcb_px + pan_off_x - pan_w/2 - pan_clr_w - rib_clr) + wall_rib;
W = 2*max(half_cav, half_rib);      // whichever the -X side actually needs
H = pcb_h + 2*(mod_clr + wall);
Zc = H/2;
win_w = act_w + 2*white_show_short;  win_h = act_h + 2*white_show_long;
pcb_face_y = front_t + pan_t + 0.2;
mod_back   = pcb_face_y + pcb_t;
pk_d   = disc_d + 2*pocket_c;
pk_dep = disc_t + 0.15;
pk_y0  = depth - pk_dep;               // pocket floor
cov_in_pk = pk_y0 - pk_floor_t;        // cover inner face over the pocket
cov_in    = depth - cover_t;
cav_x0 = pcb_px - cav_w/2; cav_x1 = pcb_px + cav_w/2;
cav_z0 = Zc - cav_h/2;     cav_z1 = Zc + cav_h/2;
// -Z band: the cell, centred and low (keeps the centre of mass down)
bat_cx = pcb_px;
bat_cz = cav_z0 + 0.7 + (bat_h + 2*bat_clr)/2;
bat_x0 = bat_cx - bat_w/2;
// +Z band: Perma-Proto (-X) and Waveshare driver board (+X), side by side
proto_x0 = cav_x0 + 0.5;  proto_x1 = proto_x0 + proto_w;
proto_z1 = cav_z1 - 1.0;  proto_z0 = proto_z1 - proto_h;
proto_cx = proto_x0 + proto_w/2;  proto_cz = (proto_z0 + proto_z1)/2;
proto_back = cov_in_pk - 0.5;                     // sits on the puck face
proto_face = proto_back - proto_t;
drv_rail = 3.0;                                   // rail width, overlaps the board 1.0
drv_x0 = proto_x1 + 0.7 + (drv_rail - 1.0);  drv_x1 = drv_x0 + drv_w;
drv_z1 = cav_z1 - 1.0;  drv_z0 = drv_z1 - drv_h;
drv_cx = drv_x0 + drv_w/2;  drv_cz = (drv_z0 + drv_z1)/2;
drv_back = cov_in_pk - 0.5;                       // PCB back face
// module retention pads, in the strips either side of the cell
pad_w = 13.0; pad_h = 22.0;
pad_x = [bat_cx - bat_w/2 - bat_clr - bat_fence - 1.0 - pad_w/2,
         bat_cx + bat_w/2 + bat_clr + bat_fence + 1.0 + pad_w/2];
pad_z = [bat_cz + 12.0, bat_cz - 2.0];
// module 8-pin header, absolute
conn_x = pcb_px + conn_dx;
conn_z = Zc + conn_dz;
conn_y0 = mod_back;                 // front face of the keep-out
conn_y1 = mod_back + conn_h;        // back face
// ribbon cutout centre, measured from the glass's -Z edge
rib_cz  = (Zc + pan_off_z) - pan_h/2 + rib_off + rib_w/2;
rib_far = pan_h - rib_off - rib_w;      // what is left on the other side
// ports
// rear-facing USB-C breakout: receptacle flush in the back cover
ucb_x = -34.4; ucb_z = 11.0;                      // port centre on the back
ucb_w = 13.0; ucb_l = 13.0; ucb_t = 1.6;          // breakout board
port_w = 9.5; port_h = 3.7;                       // receptacle opening
chg_z = proto_z0 + 3.0 + chg_h/2;                 // bq24074, low end of the Perma-Proto
flash_x = drv_cx;                                 // Waveshare USB-C, +Z wall
flash_y0 = 10.6; flash_y1 = 17.4;
// The driver board's own USB-C is for FLASHING, not power - power comes in at the
// charge port in the back plate.  false closes the long-axis top end: no opening
// anywhere but the back.  The pocket is still cut either way, because the jack
// stands 0.2 mm past the cavity wall and needs somewhere to sit.
// Flash the ESP32 BEFORE final assembly if this is false.
flash_port = false;
flash_wall = 1.5;                                 // skin left over the jack when closed
// Screw spine, centred in the material actually available at the BACK face - not
// between the cavity and W/2.  The cover's rear chamfer takes rear_chf off each
// side by the time it reaches y=depth, which is exactly where the screw-head
// counterbore is deepest.  Referencing W/2 put the counterbore edge at 43.95
// against a back face that also ends at 43.95 once W came down to 91.9: tangent,
// 0.05 mm of material.  Referencing (W/2 - rear_chf) keeps it centred at any W.
scr_x = (pcb_px + pcb_w/2 + mod_clr + (W/2 - rear_chf))/2;
scr_z = [14.0, Zc, H - 14.0];
hub_z = W/2;                           // = distance to the bottom edge in BOTH orientations
theta_dep = 180 - stop_ang;            // leg swing angle when deployed

// ================================================================ helpers
// rounded rect plus relief circles centred ON the theoretical sharp corners,
// so a sharp-cornered part drops straight in instead of riding the fillets
module relieved(w,h,r,rel){
    rrect(w,h,r);
    if(rel > 0) for(sx=[-1,1],sz=[-1,1])
        translate([sx*w/2, sz*h/2]) circle(r=rel);
}
module rrect(w,h,r){ hull() for(sx=[-1,1],sy=[-1,1]) translate([sx*(w/2-r),sy*(h/2-r)]) circle(r=r); }
module xzext(d){ rotate([90,0,0]) translate([0,0,-d]) linear_extrude(d) children(); }
module prism(w,h,r,d,cx=0,cz=0,y0=0){ translate([cx,y0,cz]) xzext(d) rrect(w,h,r); }
module cylY(dia,d,cx=0,cz=0,y0=0){ translate([cx,y0,cz]) xzext(d) circle(d=dia); }
module pie(r,a0,a1){ intersection(){ circle(r=r);
    polygon(concat([[0,0]],[for(t=[a0:(a1-a0)/12:a1]) [2*r*cos(t),2*r*sin(t)]])); } }

module outer(d,y0=0){ prism(W,H,corner_r,d,0,Zc,y0); }
module cavity(d,y0){
    translate([pcb_px,y0,Zc]) xzext(d) relieved(cav_w,cav_h,cav_r,cav_rel); }
// glass pocket: snug on all four sides, corner relief so the sharp
// glass corners seat, and a local notch where the ribbon folds back
module panel_pocket(d, y0){
    pw = pan_w + 2*pan_clr_w;  ph = pan_h + 2*pan_clr_h;
    cx = pan_px;               cz = Zc + pan_off_z;
    // the glass pocket proper - only as deep as the glass
    translate([cx, y0, cz]) xzext(d) relieved(pw, ph, pan_r, pan_rel);
    // the ribbon relief runs DEEPER than the pocket: rib_clr out from the pocket
    // edge, and on past the glass back face by rib_dep, so the ribbon can turn
    // through 180 deg and lie back against the PCB.  Cut to the same depth as the
    // pocket it would be a slot with a solid floor - 4 mm of width and nowhere to
    // fold into, which is what it was.
    translate([cx, y0, cz]) xzext(pan_t + rib_dep)
        translate([-(pw/2 + rib_clr/2), rib_cz - cz])
            square([rib_clr + 0.02, rib_w], center=true); }
// Tape pads BEHIND the glass, at both long-axis ends.  Each starts at the pocket
// edge and reaches tape_reach outward into the ledge, so tape can run off the
// glass back face and onto frame without a step to climb.  Recessed tape_dep
// into the ledge, which is also the PCB's seat.
module tape_pocket(){
    if (tape_pad) {
        ph = pan_h + 2*pan_clr_h;
        for (sz=[-1,1])
            translate([pan_px, pcb_face_y - tape_dep,
                       (Zc + pan_off_z) + sz*(ph/2 + tape_reach/2)])
                xzext(tape_dep + 0.01)
                    square([tape_len, tape_reach + 0.02], center=true);
    } }
module window_cut(){
    zw = Zc + act_off_z;
    prism(win_w,win_h,3,front_t+1,0,zw,-0.5);
    hull(){ prism(win_w+2*win_chf,win_h+2*win_chf,3+win_chf,0.01,0,zw,-0.5);
            prism(win_w,win_h,3,0.01,0,zw,win_chf); } }
module usb_cut(){
    // Waveshare board's USB-C.  Straight through the long-axis +Z wall when
    // flash_port, otherwise a BLIND pocket: same clearance for the jack, but
    // flash_wall of skin left so the outside stays unbroken.
    fz0 = cav_z1 - 1.2;
    fz1 = flash_port ? H + 2 : H - flash_wall;
    translate([flash_x-usb_w/2, flash_y0, fz0])
        cube([usb_w, flash_y1-flash_y0, fz1-fz0]);
    // optional side buttons through the +X wall
    if (btn_n > 0) for(i=[0:btn_n-1])
        translate([cav_x1-1.0, 9.0, Zc + (i-(btn_n-1)/2)*btn_sp])
            rotate([0,90,0]) cylinder(d=btn_d, h=W/2-cav_x1+2); }
// The hull must overhang the cutting box at BOTH ends, along the same 45 deg
// taper.  If it stops short the difference leaves a full-section slab a few
// microns thick, which slices the part clean in two.  (It did.)
module rear_chamfer(){
    e = 0.05;
    difference(){
        translate([-W, depth-rear_chf-e, -H]) cube([2*W, rear_chf+2*e, 3*H]);
        hull(){ prism(W+2*e, H+2*e, corner_r+e, 0.01, 0, Zc, depth-rear_chf-e);
                prism(W-2*rear_chf-2*e, H-2*rear_chf-2*e,
                      max(corner_r-rear_chf-e,0.5), 0.01, 0, Zc, depth+e); } } }
module rear_port_cut(){
    // slot for the breakout board through the register lip ...
    translate([ucb_x, cov_in-2.2, ucb_z]) xzext(2.5) rrect(ucb_w+1.0, port_h+0.8, 0.8);
    // ... and the receptacle opening through the skin
    translate([ucb_x, cov_in-0.3, ucb_z]) xzext(cover_t+0.6) rrect(port_w, port_h, 1.2); }
module front_chamfer(){
    difference(){
        translate([-W,-0.01,-H]) cube([2*W,front_chf+0.01,3*H]);
        hull(){ prism(W-2*front_chf,H-2*front_chf,max(corner_r-front_chf,0.5),0.01,0,Zc,-0.005);
                prism(W,H,corner_r,0.01,0,Zc,front_chf); } } }

// ================================================================== frame
module frame(){
    difference(){
        outer(body_d);
        window_cut();
        front_chamfer();
        panel_pocket(pcb_face_y-front_t+0.01, front_t);
        tape_pocket();
        cavity(body_d, pcb_face_y);
        usb_cut();
        rear_chamfer();
        for(z=scr_z) translate([scr_x,body_d+0.1,z]) rotate([90,0,0])
            cylinder(d=scr_pilot,h=scr_depth);
        prism(cav_w+2.0, cav_h+2.0, cav_r+1.0, 1.1, pcb_px, Zc, body_d-1.0);
        for(sz=[-1,1]) translate([pcb_px-cav_w/2-1.5, body_d-2.5, Zc+sz*32-5])
            cube([1.6, 2.1, 10]);
    } }

// ================================================================= cover
module cover(){
    difference(){
        union(){
            prism(cav_w+1.7, cav_h+1.7, cav_r+1.0, cover_t+1.0, pcb_px, Zc, body_d-1.0);
            outer(cover_t, body_d);
            // ---- module retention: full ribs top and bottom, two short
            //      segments on +X so the cell can use the middle of that edge
            for(i=[0,1])
                translate([pad_x[i], mod_back+rib_gap, pad_z[i]])
                    xzext(cov_in-mod_back-rib_gap) square([pad_w, pad_h],center=true);

            // ---- solid puck the stand pocket is bored into
            cylY(pk_d+2*lug_out+6, depth-cov_in_pk, 0, hub_z, cov_in_pk);
            // ---- Waveshare driver board: side rails, slides in from +Z
            for(sx=[-1,1])
                translate([drv_cx + sx*(drv_w/2+drv_clr+drv_rail/2-1.0), drv_back-2.6, drv_cz])
                    xzext(cov_in-drv_back+2.6) square([drv_rail, drv_h-1.0],center=true);
            translate([drv_cx, drv_back-2.6, drv_z0-1.4])
                xzext(cov_in-drv_back+2.6) square([drv_w-2, 2.0],center=true);
            // ---- Perma-Proto: two screw posts + four corner pads
            for(sz=[-1,1])
                translate([proto_cx, cov_in, proto_cz+sz*proto_hole_sp/2])
                    rotate([90,0,0]) cylinder(d=6.5, h=cov_in-proto_back);
            for(sx=[-1,1],sz=[-1,1])
                translate([proto_cx+sx*(proto_w/2-4), cov_in, proto_cz+sz*(proto_h/2-4)])
                    rotate([90,0,0]) cylinder(d=6.0, h=cov_in-proto_back);
            // ---- battery fence (cell is held by foam tape inside it)
            // flat platform so the cell doesn't straddle the puck's step
            translate([bat_cx, cov_in_pk, bat_cz])
                xzext(cov_in-cov_in_pk+0.01)
                    square([bat_w+2*bat_clr+2*bat_fence,
                            bat_h+2*bat_clr],center=true);
            for(sx=[-1,1])
                translate([bat_cx+sx*(bat_w/2+bat_clr+bat_fence/2), cov_in_pk-bat_t, bat_cz])
                    xzext(bat_t) square([bat_fence, bat_h-14],center=true);
            // ---- guide rails for the rear USB-C breakout board
            //   full depth to the skin, but split in X so they miss the receptacle
            for(sz=[-1,1], sx=[-1,1])
                translate([ucb_x + sx*(ucb_w/2-0.5), cov_in-ucb_l,
                           ucb_z + sz*(ucb_t/2+0.15+1.0)])
                    xzext(ucb_l) square([2.0, 2.0],center=true);
            // ---- cover tongues that hook under the -X wall
            for(sz=[-1,1]) translate([cav_x0-1.4, body_d-2.4, Zc+sz*32-4.5])
                cube([1.4,1.6,9]);   // 1.3 left them 0.1 short of the lip, floating
        }
        // board slot + a lip on each rail
        translate([drv_cx, drv_back-drv_t-0.15, (drv_z0+cav_z1+6)/2])
            xzext(drv_t+0.3) square([drv_w+2*drv_clr, cav_z1+6-drv_z0],center=true);
        // proto screw pilots
        for(sz=[-1,1])
            translate([proto_cx, cov_in+0.1, proto_cz+sz*proto_hole_sp/2])
                rotate([90,0,0]) cylinder(d=scr_pilot, h=cov_in-proto_back+cover_t);
        pocket_cut();
        rear_port_cut();
        rear_chamfer();
        for(z=scr_z){
            translate([scr_x, body_d-0.1, z]) rotate([-90,0,0]) cylinder(d=scr_free,h=cover_t+1.2);
            translate([scr_x, depth-scr_cb, z]) rotate([-90,0,0]) cylinder(d=scr_head,h=scr_cb+1); }
        usb_cut();
    } }

module pocket_cut(){
    cylY(pk_d, pk_dep+0.02, 0, hub_z, pk_y0);                       // main bore
    // bayonet groove, with a 45 deg lead-in on the outer side so it prints
    cylY(pk_d+2*lug_out, 1.6, 0, hub_z, pk_y0+1.2);
    translate([0, pk_y0+2.8-0.01, hub_z]) rotate([-90,0,0])
        cylinder(d1=pk_d+2*lug_out, d2=pk_d, h=lug_out+0.02);
    // entry gaps
    for(a=[45,165,285])
        translate([0, pk_y0+groove_y0, hub_z]) rotate([-90,0,0]) rotate([0,0,a])
            linear_extrude(pk_dep) pie(pk_d/2+lug_out+0.2, -gap_ang/2, gap_ang/2);
    // radial rotation detents at 0/90/180/270
    for(a=[0,90,180,270])
        translate([(pk_d/2+0.35)*sin(a), pk_y0+disc_t/2, hub_z+(pk_d/2+0.35)*cos(a)])
            rotate([90,0,0]) sphere(d=2.9);
}

// ================================================================== disc
// modelled in its own frame: plane = XZ, extruded +Y, y=0 at the pocket floor
module disc(){
    slot_w = leg_w + 2*leg_slot_c;
    slot_z0 = -(pivot_r + leg_w/2 + 1.2);
    slot_z1 = leg_len - pivot_r + 3.5;
    difference(){
        union(){
            cylY(disc_d, disc_t, 0,0,0);
            for(a=[0,120,240])                                    // bayonet lugs
                translate([0, 1.45, 0]) rotate([-90,0,0]) rotate([0,0,a])
                    linear_extrude(1.1) difference(){
                        pie(disc_d/2+lug_out-0.3, -lug_ang/2, lug_ang/2);
                        circle(d=disc_d-0.2); }
            for(a=[90,270])                                       // radial detent bumps
                translate([(disc_d/2-0.25)*sin(a), disc_t/2, (disc_d/2-0.25)*cos(a)])
                    rotate([90,0,0]) sphere(d=2.4);
        }
        translate([-slot_w/2, -0.01, slot_z0])
            cube([slot_w, disc_t+0.02, slot_z1-slot_z0]);
        translate([-disc_d, disc_t/2, -pivot_r]) rotate([0,90,0])
            cylinder(d=pin_d+0.25, h=2*disc_d);
        // soften the outer edge
        translate([0, disc_t-0.6, 0]) rotate([-90,0,0])
            difference(){ cylinder(d=disc_d+2,h=0.7);
                          cylinder(d1=disc_d-1.2,d2=disc_d+0.1,h=0.65); }
    } }

// =================================================================== leg
// leg-local: pin at the origin, leg along +Z, thickness in Y centred on 0
module leg_shape(){
    difference(){
        rotate([90,0,0]) translate([0,0,-leg_t/2]) linear_extrude(leg_t)
            hull(){ circle(d=leg_w); translate([0,leg_len-foot_r]) circle(r=foot_r); }
        // heel flat: the pocket floor, seen from the leg at the deployed angle
        rotate([theta_dep,0,0]) translate([-50,-60-disc_t/2,-200]) cube([100,60,400]);
        // axle
        translate([-leg_w,0,0]) rotate([0,90,0]) cylinder(d=pin_d+0.15,h=2*leg_w);
        // nail chamfer on the tip
        translate([0,leg_t/2,leg_len]) rotate([0,90,0])
            translate([0,0,-leg_w]) cylinder(r=2.2,h=2*leg_w,$fn=4);
    } }

module leg_placed(theta){
    translate([0, disc_t/2, -pivot_r]) rotate([-theta,0,0]) leg_shape(); }

module leg(){ rotate([90,0,0]) leg_shape(); }

// ============================================================== hardware
module mod_conn(){
    translate([conn_x, conn_y0, conn_z]) xzext(conn_h)
        square([conn_w, conn_l], center=true); }
module mock_module(){
    // SHARP corners, as measured - this is what the relief has to swallow
    color("#dcdcd4") translate([pcb_px,pcb_face_y,Zc]) xzext(pcb_t) square([pcb_w,pcb_h],center=true);
    color("#f6f6f1") translate([pan_px,front_t+0.15,Zc+pan_off_z]) xzext(pan_t) square([pan_w,pan_h],center=true);
    color("#23262b") translate([0,front_t-0.3,Zc+act_off_z]) xzext(pan_t+0.3) rrect(act_w,act_h,0.5);
    color("#b5651d") mod_conn(); }
module mock_board(){
    // Waveshare driver board
    color("#12481c") translate([drv_cx, drv_back-drv_t, drv_cz])
        xzext(drv_t) square([drv_w,drv_h],center=true);
    color("#2b2b2b") translate([drv_cx, drv_back-drv_t-3.1, drv_cz-4])
        xzext(3.1) square([drv_w*0.7, drv_h*0.45],center=true);
    color("#c9ccd1") translate([drv_cx, drv_back-drv_t-3.2, drv_z1+0.6])
        xzext(3.2) square([9, 1.2],center=true);
    // Perma-Proto quarter + bq24074 riding on it
    color("#1b5e20") translate([proto_cx, proto_face, proto_cz])
        xzext(proto_t) square([proto_w, proto_h],center=true);
    color("#155799") translate([proto_x0+chg_w/2+1, proto_face-chg_t+proto_t, chg_z])
        xzext(chg_t-proto_t) square([chg_w, chg_h],center=true);
    // rear USB-C breakout, standing perpendicular in its guide rails
    color("#155799") translate([ucb_x, cov_in-ucb_l/2, ucb_z])
        rotate([0,0,0]) translate([-ucb_w/2,-ucb_l/2,-ucb_t/2]) cube([ucb_w,ucb_l,ucb_t]);
    color("#c9ccd1") translate([ucb_x, cov_in-4.0, ucb_z])
        xzext(3.9) rrect(port_w-0.4, port_h-0.4, 1.0);
    mock_cell(); }
// The driver board's FULL measured envelope (drv_env deep), for clearance checks.
// Deliberately NOT part of mock_board(): the cover's rails overlap the PCB edge by
// 1.0 mm on purpose to grip it, so an envelope inside mock_board() makes those
// rails read as clashes while they are doing their job.
module drv_envelope(){
    translate([drv_cx, drv_back-drv_env, drv_cz])
        xzext(drv_env) square([drv_w, drv_h], center=true); }
module mock_cell(){
    color("#3b3b46") translate([bat_cx, cov_in_pk-bat_t, bat_cz])
        xzext(bat_t) rrect(bat_w, bat_h, 2); }
module mock_pcbs(){
    translate([drv_cx, drv_back-drv_t, drv_cz]) xzext(drv_t) square([drv_w,drv_h],center=true);
    translate([proto_cx, proto_face, proto_cz]) xzext(proto_t) square([proto_w,proto_h],center=true);
    translate([proto_x0+chg_w/2+1, proto_face-chg_t+proto_t, chg_z])
        xzext(chg_t-proto_t) square([chg_w,chg_h],center=true); }

// ============================================================== assembly
module stand(rot=0, theta=0){
    translate([0, pk_y0, hub_z]) rotate([0,rot,0]) {
        color("#3a3d44") disc();
        color("#2e3138") leg_placed(theta);
    } }

module device(rot=0, theta=0){
    color("#4c4f57") frame();
    color("#54575f") cover();
    mock_module(); mock_board();
    stand(rot, theta); }

module standing(land=false){
    zp = hub_z - pivot_r;                // identical in both orientations
    yp = pk_y0 + disc_t/2;
    py = depth - rear_chf;               // contact edge of the flat bottom face
    fy = yp + leg_len*sin(stop_ang);
    fz = zp - leg_len*cos(stop_ang);
    a  = atan2(fz, fy - py);
    yc = 11.0;  zc = land ? W/2 : Zc;    // centre of mass estimate
    com = -(py-yc)*cos(a) + zc*sin(a);
    echo(str(land?"LANDSCAPE":"PORTRAIT"," lean ",a," deg | footprint ",
             (fy-py)*cos(a)+fz*sin(a)," mm | CoM ",com," mm behind the contact edge"));
    translate([0,0,py*sin(a)])
    rotate([-a,0,0])
        if (land) translate([-H/2,0,W/2]) rotate([0,90,0]) device(-90, theta_dep);
        else device(0, theta_dep);
}

// ================================================================ output
// A true slice of the real frame - the WHOLE front bezel: full width, full
// height, and only the front bt_y of the depth.  Because it is cut from
// frame() itself it cannot drift from the part you are going to print.
// Full height on purpose: the point of the tile is to drop the real module in
// and check it sits flush, and that needs all four pocket corners, the whole
// window lip and the full ribbon relief - a bottom-band slice cannot show them.
// Set bt_h = 34 for the old bottom-band-only tile (faster, corners only).
// The tile has to be deeper than the ribbon relief, or the relief bottoms out
// 0.2 mm short of the tile's back face and prints as a slot with a membrane
// across it - which is exactly the thing being tested.
rib_y1 = front_t + pan_t + rib_dep;              // deepest point of the relief
bt_h = H;  bt_y = max(pcb_face_y + 3.0, rib_y1 + 1.4);
module bezel_test(){
    intersection(){
        frame();
        translate([-W, -1, -1]) cube([2*W, bt_y+1, bt_h+1]);
    } }

// flat face down: frame and bezel tile sit on their FRONT face, so the big
// flat plate is the first layer and the cavity opens upward.  Printed the
// other way up the 1.4 front plate has to bridge the whole cavity.
module oriented(){ if(print_mirror) mirror([1,0,0]) children(); else children(); }
if (part=="bezel_test") oriented() translate([0,H,0]) rotate([90,0,0]) bezel_test();
else if (part=="frame")   oriented() translate([0,H,0]) rotate([90,0,0]) frame();
else if (part=="cover")   oriented() translate([0,0,depth]) rotate([-90,0,0]) cover();
else if (part=="disc")    oriented() rotate([-90,0,0]) disc();
else if (part=="leg")     oriented() leg();
else if (part=="standing_p") standing(false);
else if (part=="standing_l") standing(true);
else if (part=="exploded"){
    frame(); translate([0,14,0]) cover();
    translate([0,30,Zc]) rotate([-90,0,0]) disc(); }
else if (part=="plate"){
    oriented() translate([-60,H,0]) rotate([90,0,0]) frame();
    oriented() translate([60,0,depth]) rotate([-90,0,0]) cover();
    translate([60,-70,0]) rotate([-90,0,0]) disc();
    translate([0,-70,0]) leg(); }
else if (part=="assembly") device(0, theta_dep);
else if (part=="folded") device(0, 0);
else if (part=="folded_l") device(-90, 0);
else if (part=="guts"){ color("#5a5e67") cover(); mock_board(); }

echo(str("OUTER: short axis ",W," | long axis ",H," | depth ",depth));
echo(str("BEZEL: short-axis sides ",W/2-win_w/2,"  long-axis ends ",H/2-win_h/2,
         " | white shown: short ",white_show_short," long ",white_show_long));
echo(str("walls: +X ",W/2-(pcb_px+pcb_w/2+mod_clr),"  -X ",W/2+(pcb_px-pcb_w/2-mod_clr)));
echo(str("interior behind PCB ",cov_in-mod_back,"  over stand pocket ",cov_in_pk-mod_back));
echo(str("DRIVER BOARD envelope ",drv_w," x ",drv_h," x ",drv_env,
         " | clear depth over the puck ",cov_in_pk-mod_back," -> ",
         (drv_env <= cov_in_pk-mod_back) ? "fits"
           : str("SHORT by ",drv_env-(cov_in_pk-mod_back)," mm"),
         " | off the puck ",cov_in-mod_back));
echo(str("CLEARANCE in front of: cell ",cov_in_pk-bat_t-mod_back,
         " | proto pcb ",proto_face-mod_back," | driver pcb ",drv_back-drv_t-mod_back));
echo(str("module 8-pin header allowance assumed ",conn_h," mm"));
rib_x = pan_px - (pan_w/2 + pan_clr_w) - rib_clr;   // outermost point of the notch
echo(str("RIBBON RELIEF reaches x ",rib_x," | frame outer face ",-W/2,
         " | wall left ",rib_x-(-W/2)));
echo(str("SHORT AXIS driven by: ", (half_rib > half_cav) ? "THE RIBBON RELIEF" : "the PCB cavity",
         "  (cavity needs ",half_cav,", ribbon needs ",half_rib,")"));
echo(str("bezel from ink: thin side ",bez_thin," thick/ribbon side ",bez_thick,
         " | lip on glass (short axis): thin ",bez_thin-white_show_short,
         " thick ",bez_thick-white_show_short));
echo(str("RIBBON RELIEF: out ",rib_clr," (from the pocket edge) | deep ",rib_dep,
         " (past the glass back face) | long ",rib_w,
         " | slot spans depth ",front_t," to ",rib_y1," | test tile is ",bt_y," deep"));
echo(str("RIBBON RELIEF along the long axis: ",rib_w," long | ",rib_off,
         " from the -Z glass edge, ",rib_far," from the +Z edge | they sum to ",
         rib_off+rib_w+rib_far," against a ",pan_h," glass"));
echo(str("TAPE PADS: ", tape_pad
         ? str("2 (both long-axis ends), ",tape_len," along the short axis x ",
               tape_reach," into the ledge x ",tape_dep," deep | ledge is ",
               cav_h/2-(pan_h+2*pan_clr_h)/2," so ",
               cav_h/2-(pan_h+2*pan_clr_h)/2-tape_reach,
               " of full-height PCB seat left at each end | pad face at depth ",
               pcb_face_y-tape_dep," vs glass back ",front_t+pan_t)
         : "none"));
echo(str("FLASH PORT: ", flash_port ? "OPEN through the long-axis +Z wall"
         : str("CLOSED - blind pocket to z ",H-flash_wall,", ",flash_wall,
               " skin left; jack reaches ",drv_z1+1.2)));
echo(str("RELIEFS: pocket relief R",pan_rel," | cavity relief R",cav_rel,
         " (cav_r ",cav_r,", limit 1.707 for a sharp PCB corner)",
         " | wall left at a cavity corner ",wall-cav_rel));
echo(str("GLASS POCKET ",pan_w+2*pan_clr_w," x ",pan_h+2*pan_clr_h,
         "  (margin ",2*pan_clr_w," on the short axis, ",2*pan_clr_h,
         " on the long axis) | pocket relief R",pan_rel));
echo(str("charger ",chg_part," ",chg_w," x ",chg_h," x ",chg_t,
         " | fits proto: ", (chg_w <= proto_w-2 && chg_h <= proto_h-2) ? "yes" : "NO",
         " | clear in front: ", proto_face - chg_t + proto_t - mod_back));
echo(str("HEADER vs CELL: needs ",conn_h,", has ",cov_in_pk-bat_t-mod_back,
         " -> ", (conn_h > cov_in_pk-bat_t-mod_back)
                 ? str("CLASH by ",conn_h-(cov_in_pk-bat_t-mod_back)," mm")
                 : "clear"));
echo(str("depth needed for a ",conn_h," mm header over the cell: ",
         conn_h + bat_t + mod_back + 5.95 + 0.5));

// ---------------------------------------------------------------- checks
// Render one of these and look for solid geometry.  READ THIS FIRST: the test is
// POSITIVE VOLUME, not "is the result empty".  Two of these pairs share a face by
// design, and intersection() returns that shared face as a zero-thickness sheet -
// real geometry in the STL, real vertices, zero volume, no interference:
//   frame_cover  - frame rear face and cover front face are both at y = body_d
//   cover_board  - the board sits exactly on its standoffs
// Chasing either as a clash is a dead end (it cost a while once).
// SECOND TRAP: when an intersection is empty OpenSCAD writes NO FILE, so a script
// that reuses output paths silently re-reads the PREVIOUS check's result.  Delete
// the output before every run or you will chase a clash that is not there.
// Measured state of all 14, by volume:
//   10 genuinely empty | frame_cover + cover_board zero-volume touches (by design)
//   conn_cell  154 mm3 REAL - 8-pin header vs cell, wants depth 26.1
//   drv_module 1050 mm3 REAL - the driver board's 15 mm envelope vs the module PCB
chk = "";
module disc_f(rot=0){ translate([0,pk_y0,hub_z]) rotate([0,rot,0]) disc(); }
module leg_f(rot=0,th=0){ translate([0,pk_y0,hub_z]) rotate([0,rot,0]) leg_placed(th); }
if(chk=="frame_cover")  intersection(){ frame(); cover(); }
if(chk=="frame_module") intersection(){ frame(); mock_module(); }
if(chk=="cover_module") intersection(){ cover(); mock_module(); }
if(chk=="cover_board")  intersection(){ cover(); mock_board(); }
if(chk=="frame_board")  intersection(){ frame(); mock_board(); }
if(chk=="drv_module")   intersection(){ mock_module(); drv_envelope(); }
if(chk=="conn_cell")    intersection(){ mod_conn(); mock_cell(); }
if(chk=="conn_board")   intersection(){ mod_conn(); mock_pcbs(); }
if(chk=="conn_cover")   intersection(){ mod_conn(); cover(); }
if(chk=="cover_disc")   intersection(){ cover(); disc_f(0); }
if(chk=="disc_legf")    intersection(){ disc(); leg_placed(0); }
if(chk=="disc_legd")    intersection(){ disc(); leg_placed(theta_dep); }
if(chk=="cover_legd")   intersection(){ cover(); leg_f(0,theta_dep); }
if(chk=="cover_legf")   intersection(){ cover(); leg_f(0,0); }

// ------------------------------------------------- parameter dump for docs
if (part=="params") {
  vals = [
   ["W",W],["H",H],["depth",depth],["body_d",body_d],["front_t",front_t],
   ["cover_t",cover_t],["wall",wall],["corner_r",corner_r],["cav_r",cav_r],["cav_rel",cav_rel],["bt_h",bt_h],
   ["front_chf",front_chf],["rear_chf",rear_chf],["win_chf",win_chf],
   ["pcb_w",pcb_w],["pcb_h",pcb_h],["pcb_t",pcb_t],["pan_w",pan_w],["pan_h",pan_h],
   ["pan_t",pan_t],["pan_clr_w",pan_clr_w],["pan_clr_h",pan_clr_h],["rib_off",rib_off],["rib_cz",rib_cz],["rib_far",rib_far],["pan_r",pan_r],["pan_rel",pan_rel],
   ["rib_w",rib_w],["rib_clr",rib_clr],["wall_rib",wall_rib],
   ["bez_thin",bez_thin],["bez_thick",bez_thick],["half_cav",half_cav],["half_rib",half_rib],["act_w",act_w],["act_h",act_h],["act_off_x",act_off_x],["act_off_z",act_off_z],["pan_off_z",pan_off_z],
   ["mod_clr",mod_clr],["pcb_px",pcb_px],["pan_px",pan_px],
   ["cav_w",cav_w],["cav_h",cav_h],["cav_x0",cav_x0],["cav_x1",cav_x1],
   ["cav_z0",cav_z0],["cav_z1",cav_z1],["Zc",Zc],["hub_z",hub_z],
   ["win_w",win_w],["win_h",win_h],
   ["white_show_short",white_show_short],["white_show_long",white_show_long],
   ["tape_pad",tape_pad?1:0],["tape_len",tape_len],["tape_reach",tape_reach],["tape_dep",tape_dep],
   ["pcb_face_y",pcb_face_y],["mod_back",mod_back],
   ["cov_in",cov_in],["cov_in_pk",cov_in_pk],["pk_y0",pk_y0],["pk_d",pk_d],
   ["pk_dep",pk_dep],["pk_floor_t",pk_floor_t],["lug_out",lug_out],["lug_t",lug_t],
   ["lug_ang",lug_ang],["gap_ang",gap_ang],
   ["disc_d",disc_d],["disc_t",disc_t],["pocket_c",pocket_c],
   ["pivot_r",pivot_r],["pin_d",pin_d],["leg_len",leg_len],["leg_w",leg_w],
   ["leg_t",leg_t],["foot_r",foot_r],["stop_ang",stop_ang],["theta_dep",theta_dep],
   ["leg_slot_c",leg_slot_c],["detent_d",detent_d],
   ["bat_w",bat_w],["bat_h",bat_h],["bat_t",bat_t],["bat_x0",bat_x0],
   ["bat_cx",bat_cx],["bat_cz",bat_cz],["bat_clr",bat_clr],["bat_fence",bat_fence],["pad_w",pad_w],["pad_h",pad_h],
   ["pad_x0",pad_x[0]],["pad_x1",pad_x[1]],["pad_z0",pad_z[0]],["pad_z1",pad_z[1]],
   ["proto_w",proto_w],["proto_h",proto_h],["proto_t",proto_t],["proto_x0",proto_x0],
   ["proto_x1",proto_x1],["proto_cx",proto_cx],["proto_cz",proto_cz],
   ["proto_z0",proto_z0],["proto_z1",proto_z1],["proto_back",proto_back],["proto_face",proto_face],
   ["proto_hole_sp",proto_hole_sp],
   ["drv_w",drv_w],["drv_h",drv_h],["drv_t",drv_t],["drv_x0",drv_x0],["drv_x1",drv_x1],
   ["drv_cx",drv_cx],["drv_cz",drv_cz],["drv_z0",drv_z0],["drv_z1",drv_z1],
   ["drv_back",drv_back],["drv_clr",drv_clr],["drv_rail",drv_rail],
   ["ucb_x",ucb_x],["ucb_z",ucb_z],["ucb_w",ucb_w],["ucb_l",ucb_l],["ucb_t",ucb_t],
   ["port_w",port_w],["port_h",port_h],
   ["chg_part",chg_part],["chg_w",chg_w],["chg_h",chg_h],["chg_t",chg_t],["chg_z",chg_z],["chg_x",proto_x0+chg_w/2+1],
   ["flash_x",flash_x],["flash_y0",flash_y0],["flash_y1",flash_y1],["usb_w",usb_w],
   ["scr_x",scr_x],["scr_z0",scr_z[0]],["scr_z1",scr_z[1]],["scr_z2",scr_z[2]],
   ["scr_pilot",scr_pilot],["scr_free",scr_free],["scr_head",scr_head],
   ["rib_t",rib_t],["rib_inset",rib_inset],["rib_pad",rib_pad],["rib_gap",rib_gap],
   ["conn_h",conn_h],["conn_w",conn_w],["conn_l",conn_l],["conn_x",conn_x],["conn_z",conn_z],["btn_n",btn_n],["btn_d",btn_d],["btn_sp",btn_sp]
  ];
  for (v = vals) echo(str("P|", v[0], "|", v[1]));
}
