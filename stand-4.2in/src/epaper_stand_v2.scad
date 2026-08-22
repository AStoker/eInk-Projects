// =====================================================================
//  4.2" e-Paper desk frame  -  v2  "minimal bezel + rotating kickstand"
//  Waveshare 4.2inch e-Paper Module (B) + e-Paper ESP32 Driver Board
//
//  Frame  : 17 mm deep, bezel = the panel's own dead border + ~2 mm plastic
//  Cover  : full back, carries the driver board + the stand pocket
//  Disc   : bayonets into the pocket, rotates in 90 deg detents (P <-> L)
//  Leg    : folds flush into the disc, swings out to a hard stop
//
//  X = width, Y = depth (0 = front face), Z = height (0 = bottom edge)
// =====================================================================

/* [What to build] */
// frame | cover | disc | leg | bezel_test | plate | standing_p | standing_l | exploded
part = "standing_p";

/* [Display module] */
pcb_w = 78.5; pcb_h = 103.0; pcb_t = 1.6;
pan_w = 77.0; pan_h = 91.0;  pan_t = 1.05;
act_w = 63.6; act_h = 84.8;
pan_off_x = 0.0; pan_off_z = 0.0;   // panel centre vs PCB centre
act_off_x = 3.7; act_off_z = 0.0;   // ink centre vs PCB centre
mod_clr = 0.5;

/* [Driver board] */
brd_w = 48.25; brd_h = 29.46; brd_t = 1.6;
brd_stand = 2.0; brd_clr = 0.4;
usb_w = 13.0; usb_y0 = 6.6; usb_y1 = 14.2;

/* [Body] */
depth = 18.0; front_t = 1.4; cover_t = 1.4; pk_floor_t = 1.8;
wall = 2.2; white_show = 1.3;
corner_r = 5.0; cav_r = 2.0; front_chf = 0.8; win_chf = 0.9;

/* [Fixings] */
scr_pilot = 2.1; scr_free = 2.8; scr_head = 5.4; scr_cb = 1.6; scr_depth = 8.0;

/* [Module retention] */
rib_t = 2.5; rib_inset = 3.0; rib_gap = 0.25;

/* [Kickstand] */
disc_d = 58.0; disc_t = 4.0; pocket_c = 0.35;
lug_out = 1.3; lug_t = 1.3; lug_ang = 26; gap_ang = 34;
groove_y0 = 1.4;                 // groove position, from the pocket floor
pivot_r = 18.0; pin_d = 2.0;   // pivot_r 9.45 => identical lean both ways
leg_len = 35.7; leg_w = 14.0; leg_t = 3.4; leg_slot_c = 0.5;
foot_r = 5.0; stop_ang = 62;     // deployed leg angle from straight down
detent_r = 22.0; detent_d = 3.0; // rotation detents

/* [Quality] */
$fa = 2; $fs = 0.4;

// ------------------------------------------------------------- derived
body_d = depth - cover_t;
cav_w = pcb_w + 2*mod_clr;  cav_h = pcb_h + 2*mod_clr;
pcb_px = -act_off_x;  pan_px = pcb_px + pan_off_x;
W = 2*(abs(pcb_px) + pcb_w/2 + mod_clr + wall);
H = pcb_h + 2*(mod_clr + wall);
Zc = H/2;
win_w = act_w + 2*white_show;  win_h = act_h + 2*white_show;
pcb_face_y = front_t + pan_t + 0.2;
mod_back   = pcb_face_y + pcb_t;
pk_d   = disc_d + 2*pocket_c;
pk_dep = disc_t + 0.15;
pk_y0  = depth - pk_dep;               // pocket floor
cov_in_pk = pk_y0 - pk_floor_t;        // cover inner face over the pocket
cov_in    = depth - cover_t;
brd_x0 = pcb_px - cav_w/2 + 1.5;
brd_xc = brd_x0 + brd_w/2;  brd_zc = Zc;
brd_back = cov_in_pk - brd_stand;      // PCB back face (toward the cover)
scr_x = (pcb_px + pcb_w/2 + mod_clr + W/2)/2;
scr_z = [14.0, Zc, H - 14.0];
theta_dep = 180 - stop_ang;            // leg swing angle when deployed

// ================================================================ helpers
module rrect(w,h,r){ hull() for(sx=[-1,1],sy=[-1,1]) translate([sx*(w/2-r),sy*(h/2-r)]) circle(r=r); }
module xzext(d){ rotate([90,0,0]) translate([0,0,-d]) linear_extrude(d) children(); }
module prism(w,h,r,d,cx=0,cz=0,y0=0){ translate([cx,y0,cz]) xzext(d) rrect(w,h,r); }
module cylY(dia,d,cx=0,cz=0,y0=0){ translate([cx,y0,cz]) xzext(d) circle(d=dia); }
module pie(r,a0,a1){ intersection(){ circle(r=r);
    polygon(concat([[0,0]],[for(t=[a0:(a1-a0)/12:a1]) [2*r*cos(t),2*r*sin(t)]])); } }

module outer(d,y0=0){ prism(W,H,corner_r,d,0,Zc,y0); }
module cavity(d,y0){ prism(cav_w,cav_h,cav_r,d,pcb_px,Zc,y0); }
module window_cut(){
    prism(win_w,win_h,3,front_t+1,0,Zc,-0.5);
    hull(){ prism(win_w+2*win_chf,win_h+2*win_chf,3+win_chf,0.01,0,Zc,-0.5);
            prism(win_w,win_h,3,0.01,0,Zc,win_chf); } }
module usb_cut(){
    translate([-W/2-1,usb_y0,brd_zc-usb_w/2])
        cube([W/2+pcb_px-cav_w/2+1.2, usb_y1-usb_y0, usb_w]); }
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
        prism(pan_w+2*mod_clr, pan_h+2*mod_clr, 1.5,
              pcb_face_y-front_t+0.01, pan_px, Zc+pan_off_z, front_t);
        cavity(body_d, pcb_face_y);
        usb_cut();
        for(z=scr_z) translate([scr_x,body_d+0.1,z]) rotate([90,0,0])
            cylinder(d=scr_pilot,h=scr_depth);
        prism(cav_w+2.0, cav_h+2.0, cav_r+1.0, 1.1, pcb_px, Zc, body_d-1.0);
        for(sz=[-1,1]) translate([pcb_px-cav_w/2-1.5, body_d-2.5, Zc+sz*32-5])
            cube([1.6, 1.5, 10]);
    } }

// ================================================================= cover
module cover(){
    difference(){
        union(){
            prism(cav_w+1.7, cav_h+1.7, cav_r+1.0, cover_t+1.0, pcb_px, Zc, body_d-1.0);
            outer(cover_t, body_d);
            for(sz=[-1,1])
                translate([pcb_px, mod_back+rib_gap, Zc+sz*(cav_h/2-rib_inset-rib_t/2)])
                    xzext(cov_in-mod_back-rib_gap) square([cav_w-2*rib_inset,rib_t],center=true);
            translate([pcb_px+cav_w/2-rib_inset-rib_t/2, mod_back+rib_gap, Zc])
                xzext(cov_in-mod_back-rib_gap) square([rib_t, cav_h-2*rib_inset],center=true);
            // solid puck that the stand pocket is bored into
            cylY(pk_d+2*lug_out+6, depth-cov_in_pk, 0, Zc, cov_in_pk);
            // platform under the driver board, level with the puck's inner face
            translate([brd_xc+0.8, cov_in_pk, brd_zc])
                xzext(cov_in-cov_in_pk+0.01) square([brd_w+3, brd_h+9],center=true);
            // board rails (overlap the PCB edge by 1.2 to form a retaining lip)
            for(sz=[-1,1])
                translate([brd_xc+0.8, brd_back-2.6, brd_zc+sz*(brd_h/2+brd_clr+1.0)])
                    xzext(cov_in_pk-brd_back+2.6) square([brd_w+3,4.4],center=true);
            translate([brd_x0+brd_w+brd_clr+1.5, brd_back-2.6, brd_zc])
                xzext(cov_in_pk-brd_back+2.6) square([3, brd_h-2],center=true);
            for(sz=[-1,1]) translate([pcb_px-cav_w/2-1.4, body_d-2.4, Zc+sz*32-4.5])
                cube([1.4,1.3,9]);
        }
        translate([brd_xc, brd_back-brd_t-0.15, brd_zc])
            xzext(brd_t+0.3) square([brd_w+30, brd_h+2*brd_clr],center=true);
        translate([brd_xc, brd_back-0.05, brd_zc])
            xzext(brd_stand+0.1) square([brd_w-8, brd_h-8],center=true);
        pocket_cut();
        for(z=scr_z){
            translate([scr_x, body_d-0.1, z]) rotate([-90,0,0]) cylinder(d=scr_free,h=cover_t+1.2);
            translate([scr_x, depth-scr_cb, z]) rotate([-90,0,0]) cylinder(d=scr_head,h=scr_cb+1); }
        usb_cut();
    } }

module pocket_cut(){
    cylY(pk_d, pk_dep+0.02, 0, Zc, pk_y0);                       // main bore
    // bayonet groove, with a 45 deg lead-in on the outer side so it prints
    cylY(pk_d+2*lug_out, 1.6, 0, Zc, pk_y0+1.2);
    translate([0, pk_y0+2.8-0.01, Zc]) rotate([-90,0,0])
        cylinder(d1=pk_d+2*lug_out, d2=pk_d, h=lug_out+0.02);
    // entry gaps
    for(a=[45,165,285])
        translate([0, pk_y0+groove_y0, Zc]) rotate([-90,0,0]) rotate([0,0,a])
            linear_extrude(pk_dep) pie(pk_d/2+lug_out+0.2, -gap_ang/2, gap_ang/2);
    // radial rotation detents at 0/90/180/270
    for(a=[0,90,180,270])
        translate([(pk_d/2+0.35)*sin(a), pk_y0+disc_t/2, Zc+(pk_d/2+0.35)*cos(a)])
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
module mock_module(){
    color("#dcdcd4") translate([pcb_px,pcb_face_y,Zc]) xzext(pcb_t) rrect(pcb_w,pcb_h,1);
    color("#f6f6f1") translate([pan_px,front_t+0.15,Zc+pan_off_z]) xzext(pan_t) rrect(pan_w,pan_h,1);
    color("#23262b") translate([0,front_t-0.3,Zc+act_off_z]) xzext(pan_t+0.3) rrect(act_w,act_h,0.5); }
module mock_board(){
    color("#12481c") translate([brd_xc,brd_back-brd_t,brd_zc]) xzext(brd_t) square([brd_w,brd_h],center=true);
    color("#2b2b2b") translate([brd_xc+6,brd_back-brd_t-3.0,brd_zc]) xzext(3.0) square([brd_w*0.5,brd_h*0.6],center=true);
    color("#c9ccd1") translate([brd_x0-0.5,brd_back-brd_t-3.2,brd_zc]) xzext(3.2) square([1.0,9],center=true); }

// ============================================================== assembly
module stand(rot=0, theta=0){
    translate([0, pk_y0, Zc]) rotate([0,rot,0]) {
        color("#3a3d44") disc();
        color("#2e3138") leg_placed(theta);
    } }

module device(rot=0, theta=0){
    color("#4c4f57") frame();
    color("#54575f") cover();
    mock_module(); mock_board();
    stand(rot, theta); }

module standing(land=false){
    zp = land ? W/2 - pivot_r : Zc - pivot_r;
    yp = pk_y0 + disc_t/2;
    fy = yp + leg_len*sin(stop_ang);
    fz = zp - leg_len*cos(stop_ang);
    a  = atan2(fz, fy);
    echo(str(land?"LANDSCAPE":"PORTRAIT"," lean ",a," deg, footprint ",
             fy*cos(a)+fz*sin(a)," mm"));
    rotate([-a,0,0])
        if (land) translate([-H/2,0,W/2]) rotate([0,90,0]) device(-90, theta_dep);
        else device(0, theta_dep);
}

// ================================================================ output
module bezel_test(){
    difference(){
        union(){
            outer(front_t);
            difference(){
                outer(pcb_face_y+3.0);
                prism(pan_w+2*mod_clr,pan_h+2*mod_clr,1.5,20,pan_px,Zc+pan_off_z,front_t);
                cavity(20, pcb_face_y);
                prism(W-14, H-14, corner_r, 20, 0, Zc, front_t);
            }
        }
        window_cut(); front_chamfer();
    } }

if (part=="bezel_test") translate([0,0,pcb_face_y+3.0]) rotate([-90,0,0]) bezel_test();
else if (part=="frame")   translate([0,0,body_d]) rotate([-90,0,0]) frame();
else if (part=="cover")   translate([0,0,depth]) rotate([-90,0,0]) cover();
else if (part=="disc")    rotate([-90,0,0]) disc();
else if (part=="leg")     leg();
else if (part=="standing_p") standing(false);
else if (part=="standing_l") standing(true);
else if (part=="exploded"){
    frame(); translate([0,14,0]) cover();
    translate([0,30,Zc]) rotate([-90,0,0]) disc(); }
else if (part=="plate"){
    translate([-60,0,body_d]) rotate([-90,0,0]) frame();
    translate([60,0,depth]) rotate([-90,0,0]) cover();
    translate([60,-70,0]) rotate([-90,0,0]) disc();
    translate([0,-70,0]) leg(); }
else if (part=="assembly") device(0, theta_dep);
else if (part=="folded") device(0, 0);
else if (part=="folded_l") device(-90, 0);

echo(str("W x H x D = ",W," x ",H," x ",depth));
echo(str("bezel: side ",W/2-win_w/2,"  top/bot ",H/2-win_h/2,
         "   white shown ",white_show));
echo(str("walls: +X ",W/2-(pcb_px+pcb_w/2+mod_clr),"  -X ",W/2+(pcb_px-pcb_w/2-mod_clr)));
echo(str("interior behind PCB ",cov_in-mod_back,"  over pocket ",cov_in_pk-mod_back));

// ---------------------------------------------------------------- checks
chk = "";
module disc_f(rot=0){ translate([0,pk_y0,Zc]) rotate([0,rot,0]) disc(); }
module leg_f(rot=0,th=0){ translate([0,pk_y0,Zc]) rotate([0,rot,0]) leg_placed(th); }
if(chk=="frame_cover")  intersection(){ frame(); cover(); }
if(chk=="frame_module") intersection(){ frame(); mock_module(); }
if(chk=="cover_module") intersection(){ cover(); mock_module(); }
if(chk=="cover_board")  intersection(){ cover(); mock_board(); }
if(chk=="frame_board")  intersection(){ frame(); mock_board(); }
if(chk=="cover_disc")   intersection(){ cover(); disc_f(0); }
if(chk=="disc_legf")    intersection(){ disc(); leg_placed(0); }
if(chk=="disc_legd")    intersection(){ disc(); leg_placed(theta_dep); }
if(chk=="cover_legd")   intersection(){ cover(); leg_f(0,theta_dep); }
if(chk=="cover_legf")   intersection(){ cover(); leg_f(0,0); }
