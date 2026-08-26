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
//    short axis  glass 76, PCB 78.5.  Model X.  Horizontal in portrait (the
//                default).
//    long  axis  glass 90, PCB 103.  Model Z.  Vertical in portrait.  THE RIBBON
//                LEAVES THE GLASS ON A LONG-AXIS EDGE and runs ALONG the long
//                axis before it turns back out - see RIBBON RELIEF below.
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
//  RIBBON RELIEF  the notch outboard of the glass pocket's thick-bezel edge -
//             a LONG-AXIS edge - that carries the ribbon.  Seen from the rear,
//             the ribbon leaves that edge, turns 90 deg to run ALONG the long
//             axis, then turns 90 deg back out to the header, which is why the
//             notch is a 40 mm slot along the edge and not a local pocket.
//             Three independent sizes, deliberately not called w/h/d:
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
// BARE PANEL: glass plus its FPC tail, and nothing else.  The tail plugs
// straight into the 24-pin socket on the driver board, which carries the
// panel's own DC-DC (VCOM / VSH / VSL / PREVGH / PREVGL) - that socket is the
// bare-panel interface, which is why there is no PCB behind the glass and no
// 8-pin header anywhere in the build.
//
// The 78.5 x 103 PCB below belongs to the *module* version of this panel.  It
// is not fitted here.  It used to set the cavity, and through it the frame's
// long axis and its 2.2 mm end walls - which is why there was nowhere to put a
// corner screw.  With bare_panel the interior is sized by the electronics
// instead, and the walls come back.
bare_panel = true;
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
// ---- THE RIBBON ROUTE, measured looking at the REAR FACE, panel in portrait.
// Sides are TOP / RIGHT / BOTTOM / LEFT (see the README): TOP and BOTTOM are the
// short-axis edges, LEFT and RIGHT the long-axis ones, and the tail leaves the
// RIGHT side.  In model terms RIGHT is -X and TOP is +Z.
//
// The tail leaves the CENTRE of the RIGHT side and makes an S:
//   leg 1  out rib_out from the glass edge
//   leg 2  90 deg turn toward the TOP, rib_band wide, rib_run long
//   leg 3  90 deg turn away from the RIGHT side, i.e. inboard across the rear
//
// It used to be an input pair, rib_off + rib_w, set from "the ribbon is towards
// the top".  It is not towards the top - it EXITS at the centre and TRAVELS
// toward the top - so both are derived from the route now and cannot drift.
rib_exit = 0.0;                     // exit centre, along the long axis, from the
                                    //   glass centre.  0 = dead centre.
rib_out  = 4.0;                     // leg 1, out from the glass edge
rib_band = 9.0;                     // ribbon width through the turn
rib_run  = 20.0;                    // leg 2, toward the TOP
rib_leg3 = 10.0;                    // leg 3, inboard across the rear face.  It
                                    //   only has to LAND on the adapter, not hit
                                    //   a socket - the tail folds over onto it,
                                    //   and the cable on from the adapter to the
                                    //   driver is routed by hand, so nothing
                                    //   downstream of the adapter is constrained.
rib_clr_out = rib_out;              // leg 1's reach, named for the echo
rib_marg = 10.0;                    // relief margin around the route, along the
                                    //   long axis.  OVERSIZE IS FREE HERE - the hollow
                                    //   is only ever a problem when it is too SMALL -
                                    //   so this is set generously rather than to the
                                    //   route.  At 10 the hollow spans 14.5 below the
                                    //   exit and 34.5 above, which covers leg 2 running
                                    //   anywhere from nothing to 34, and so covers both
                                    //   the 18 and the 24 readings of the tail length.
                                    //   What stops it growing further is the CORNER
                                    //   SCREWS, not the route - see the echo.
rib_w   = rib_run + rib_band + 2*rib_marg;              // slot LONG, along RIGHT
rib_off = pan_h/2 + rib_exit - rib_band/2 - rib_marg;   // from the BOTTOM edge
rib_clr = 3.0;                      // lateral room it needs to bend back around (OUT)
rib_dep = 3.0;                      // ... and how far BEHIND the glass back face that
                                    // relief runs, so the 180 deg fold has somewhere to
                                    // go.  Measured off the glass, not off the front
                                    // face.  Without this the relief is only as deep as
                                    // the glass pocket and the fold hits solid frame.
wall_rib = 1.0;                     // minimum wall left outboard of the ribbon notch
rib_tail = 18.0;                    // MEASURED: tail length, glass edge to the end of the
                                    // ribbon, laid flat.  The 180 deg fold back on itself
                                    // at the pocket edge eats about 2*rib_dep of that, so
                                    // what is left to reach a socket is rib_reach.

/* [Internal layout] */
// Waveshare e-Paper ESP32 Driver Board Rev 3.  Outline 48.25 x 29.46, off the
// vendor's mechanical drawing.  drv_t is just the bare PCB, used by the rails
// that grip its edge; drv_env is the whole stack and is what decides fit.
//
// drv_env was 15, which is about what an 8-pin cable mated onto the board would
// have added.  There is no such cable: the panel plugs into the board's own
// 24-pin FPC socket.  6.0 is PCB 1.6 + the tallest part on it (USB-C shell and
// the WROOM module are both ~3.2) + margin.  STILL AN ESTIMATE - put a caliper
// on it, because it sets the whole depth budget.
drv_w = 29.46; drv_h = 48.25; drv_t = 1.6;
drv_env = 6.0;                                // total depth, board + tallest part
// MEASURED, and this is the number that decides the depth budget: driver board
// + female pin sockets + carrier PCB is 16.0 max, back face to tallest point.
// It is the whole stack in one figure, so it does not depend on splitting the
// guess between drv_env, hdr_h and carrier_t - drv_stack overrides their sum.
drv_stack = 16.0;
// the 24-pin FPC socket sits on one long edge - the panel ribbon has to reach it
fpc_w = 16.0;                                 // socket body, along the board edge
fpc_off = 12.5;                               // socket centre, from the near end
drv_stand = 2.0; drv_clr = 0.4;
// ---- Waveshare e-Paper FPC adapter.  FITTED, and not optional: the panel's
// ribbon leaves at the RIBBON END (the top in portrait) while the driver's
// 24-pin socket is fpc_off from the near end of a board that has to sit low
// enough to fit.  Nothing lines up, so the tail cannot reach the driver direct.
// The adapter takes the panel's tail and a second FPC carries on to the driver.
// MEASURED: 18 x 32 outline, four corner screw holes.
// WHY it is fitted is service, not reach.  The socket end of the driver faces
// the display, so the tail CAN meet it - turned end-for-end the board even fits
// (see the DIRECT PLUG-IN echo).  The problem is that the glass is on the FRAME
// and the driver is on the COVER, so whatever joins them crosses the split, and
// the panel's tail cannot: it is rib_tail long with no slack, and its 180 deg
// fold only gives back about (pi-2)*rib_dep when it straightens.  Lift the cover
// and you are pulling on the glass.
//
// So the adapter is a SERVICE LOOP: the tail plugs into it on the panel side,
// and a longer FPC crosses the split with enough slack to open the case.
adapt_fit = true;
fpc_end = "top";       // which end of the driver the socket is fpc_off from.
                       //   "top" hangs the board downward from the socket, which
                       //   is the orientation that fits; "bottom" runs it off
                       //   the top of the interior by 9.5.
serv_lift = 25.0;      // ASSUMED: cover lift needed to get at a ZIF lever
adapt_w = 18.0; adapt_h = 32.0; adapt_t = 1.6;
adapt_hole   = 2.2;    // ASSUMED M2 clearance - measure the holes
adapt_inset  = 2.0;    // ASSUMED hole inset from each edge - measure it
adapt_env    = 5.0;    // board + its two FPC connectors, total depth - CONFIRMED
proto_w = 43.2; proto_h = 50.8; proto_t = 1.6; // Perma-Proto quarter-size
proto_hole_sp = 35.6; proto_stand = 3.0;
bat_w = 44.0; bat_h = 49.0; bat_t = 6.9;       // 2000 mAh LiPo, 694449 pouch
bat_clr = 0.8; bat_fence = 1.0;
// charger breakout: "bq25185" (Adafruit 6091) or "bq24074" (Adafruit 4755)
chg_part = "bq25185";
chg_w = (chg_part == "bq25185") ? 32.0 : 25.4;
chg_h = (chg_part == "bq25185") ? 26.3 : 20.3;
chg_t = 7.2;                                   // board + USB-C jack, off the proto face
// ---- module 8-pin header keep-out.  NOT FITTED on this build (confirmed by
// Andy and by the Rev 3 schematic): the panel's own 24-pin FPC goes straight
// into the socket on the driver board, so nothing stands off the back of the
// module waiting to be plugged into.  The keep-out that used to live here was
// an assumption, and it was the only thing producing the cell clash and the
// depth = 26.6 recommendation.  Set true and fill in the numbers if a module
// with a mated header is ever used instead.
mod_header = false;
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
// supports and nothing needs rotating in the slicer.  There is no mirroring:
// the parts export in the hand they are designed in.

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
// FASTENERS.  Heat-set inserts melted into the frame, countersunk screws down
// through the cover.  Countersunk because the cover is only 1.4 mm thick: a
// 90 deg head sinks (head_d - free_d)/2 deep, which for M3 is 1.3 mm and fits;
// a socket cap head is 3 mm tall and would stand proud of the back face.
//
// Insert dimensions vary by brand - these are the common "CNC Kitchen" sizes.
// MEASURE YOURS and set ins_d / ins_l to suit; the bore is deliberately a touch
// under the insert's outside diameter, which is what the knurl bites into.
//
//   size   insert OD x L    bore        screw head (90 deg csk)
//   M2     3.2 x 4.0        2.9 x 5.0   4.0
//   M2.5   4.0 x 4.0        3.6 x 5.0   5.0
//   M3     4.6 x 5.7        4.0 x 6.7   6.0     <- default
insert_size = "M2.5";
insert_fit  = true;             // false = self-tapping screws into a pilot hole
ins_d = (insert_size == "M2") ? 2.9 : (insert_size == "M2.5") ? 3.6 : 4.0;
ins_l = (insert_size == "M3") ? 5.7 : 4.0;
ins_relief = 1.0;               // extra bore past the insert for displaced plastic
scr_free = (insert_size == "M2") ? 2.4 : (insert_size == "M2.5") ? 2.9 : 3.4;
scr_head = (insert_size == "M2") ? 4.0 : (insert_size == "M2.5") ? 5.0 : 6.0;
scr_csk  = (scr_head - scr_free)/2;              // 90 deg head, so cone depth = radius step
scr_pilot = 2.1; scr_cb = 1.6; scr_depth = 8.0;  // the self-tapping alternative

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
// HINGE.  A plain pin gives you whatever friction the print happens to produce,
// which is not a lock.  pivot_screw makes the pin an M2.5 screw into a heat-set
// insert in the far slot wall: tighten it and the walls clamp the leg, so the
// leg holds any angle including fully deployed, and you can set how hard with a
// screwdriver.  That is the lock - not a detent, which this size of part cannot
// carry (see the README).
//
// For it to clamp, the leg has to be a close fit in the slot: leg_slot_c is
// 0.2, so each wall only has to close 0.2 mm.  A loose slot just rattles.
// ...but only if the screw fits, and at disc_t = 4 it does not.  The screw runs
// along X, so disc_t bounds BOTH ends of it: an M2.5 head is 5.0 across in a
// 4.0 plate (0.5 a side short of existing) and its insert bore is 3.6 in that
// same 4.0 plate (0.2 a side of wall, which an expanding insert splits).  That
// is why the old countersink was parked at x -33.2, outside the part, cutting
// nothing: there was nowhere for it to go.  clamp_ok reports it, and the
// HINGE echo prints the arithmetic.
//
// So the buildable hinge at disc_t = 4 is the plain pin, and the friction comes
// from clamp_pr instead of a screwdriver.  disc_t 6 makes the screw fit (+0.5 a
// side on the head, +1.2 on the bore) and is the change to make if the hinge
// wants to be adjustable - see TODO.md.
pivot_screw = false;
pin_fit = 0.10;                  // plain-pin fallback when pivot_screw = false
leg_len = 35.4; leg_w = 12.0; leg_t = 3.4;
leg_slot_c = 0.2;                // close, so the clamp screw has something to do
foot_r = 5.0; stop_ang = 58;     // deployed leg angle from straight down

// THE DEPLOYED STOP.  Rounding the hub's rear left the leg reaching only hub_r
// backwards - but that is the RETRACTED reach.  Measured off the leg mesh, how
// far the leg reaches behind the pivot while still inside the disc's thickness
// climbs steeply at the end of the stroke, because its upper-forward corner
// swings round BEHIND the pivot as it opens:
//
//     deg    0    60    90   110   118   120   122   125
//     mm  1.75  2.12  1.70  2.48  2.95  3.10  3.25  3.45
//
// 0.77 mm of clean daylight between anywhere-up-to-110 and fully deployed.  The
// slot's rear wall used to sit leg_w/2 + 1.2 = 7.2 back, clearing all of it and
// doing nothing.  Bringing it to stop_wall = the reach at theta_dep makes it a
// REAL hard stop: the leg meets it only in the last couple of degrees, and past
// that the interference grows 0.07 mm/deg.  The heel flat still lands on the
// pocket floor at the same moment, so both share the load.
//
// The stop the heel flat gives on its own is a tangency - the flat is a plane
// piv_h from the axis, so it can never cut the floor, and only its edge gets
// 0.138 mm under, saturating about 20 deg past the stop.  This wall replaces
// that with something that bites.
stop_wall = 3.25;                // rear wall, behind the pivot

// CLAMP LAND.  The clamp screw could not clamp anything.  The leg sits in the
// slot with 2*leg_slot_c = 0.4 of play, and closing that play needs the slot
// wall to travel 0.4 mm - but the wall is disc_t of plate loaded in its OWN
// plane over 15.5 mm of depth, which is stiff enough that tightening crushes
// the boss instead of moving the wall.  Nothing ever touched the leg, so the
// hinge ran on whatever the print gave it: a leg that swings freely.
//
// The land is the fix, and it works whether or not there is a screw.  It takes
// the slot to line-to-line with the leg over clamp_len at the pivot, so there
// is no dead travel left.  With the plain pin, clamp_pr's interference IS the
// friction.  With a screw (disc_t >= 6), tension then runs straight down a
// solid column of plastic into extra normal force on the leg's side face, and a
// wave washer under the head meters it - without one a rigid stack goes from
// nothing to crushed inside a few degrees of the screwdriver.
clamp_land = true;
clamp_pr  = 0.5;                 // land height.  2*leg_slot_c of that is the play
                                 //   it removes; the rest is interference.
                                 //   PRINT-TUNE THIS - it is the catch_p of the
                                 //   hinge, the one number a drawing cannot give.
clamp_len = 8.0;                 // along the long axis, centred on the pivot
// ...backed by a spring, not by the bulk of the disc.  A land on a rigid wall
// makes the fit a lottery: +/-0.15 of print variance on 0.2 of interference is
// either nothing or a leg that will not go in.  A relief slot behind the land
// leaves a fixed-fixed tongue carrying it - flex_t thick over flex_z0+flex_z1
// long, about 30 N/mm - so the same +/-0.15 moves the clamp force between 2 and
// 15 N.mm of hinge torque instead of between zero and jammed.  Gravity on the
// leg is 0.35 N.mm, so even the loose end of that range holds it.
clamp_flex = true;
flex_t    = 0.8;                 // tongue: slot face to relief slot, along X
flex_gap  = 0.8;                 // relief slot width
flex_z1   = 11.0;                // relief slot, in front of the pivot
// The tongue's REAR root is wherever the leg slot ends, because behind that the
// tongue is fused to the wall - so stop_wall sets it, not a free parameter.
// Moving the wall in from 7.2 to 3.25 shortens that arm and stiffens the tongue
// about 2.6x, which is why clamp_pr came down from 0.6: same interference on a
// stiffer spring would put the root past PLA's yield.
flex_z0   = stop_wall;           // = the rear root, behind the pivot
head_seat = 4.0;                 // head seat, out from the slot wall along X.
                                 //   The screw enters through the disc's RIM,
                                 //   so it needs a flat at the bottom of an
                                 //   access channel - the old countersink was
                                 //   placed at x -33.2, outside the part, and
                                 //   cut nothing at all.
wash_t    = 0.5;                 // wave washer free height, under the head

// SWEEP CLEARANCE.  The pivot axis sits piv_h = disc_t/2 above the pocket
// floor, so ANY leg material further than piv_h from the axis orbits below the
// floor part way through the stroke.  The heel flat left a corner 3.82 from the
// axis: measured against the cover it buries itself 1.80 mm into the floor at
// 64 deg, so the leg could not complete its travel at all.
//
// hub_sweep rounds the rear of the hub to hub_r over the exact sector that
// passes straight down - sweep_a to 270 deg in leg-local angle - and stops
// there, which leaves the SHORT side of the heel flat untouched.  That short
// side is the 0.75 x 12 land that comes down on the pocket floor at stop_ang,
// so the hard stop survives; only the corner that could not clear is gone.
hub_sweep = true;
sweep_clr = 0.25;

// SNAP DETENT.  The projecting part is on the DISC and the receiving part is a
// POCKET in the leg's top face.  That inversion is what makes it possible while
// the leg still folds flush:
//   - a LUG ON THE LEG is capped at 0.25 mm, because it has to sweep 122 deg
//     inside disc_t and its worst excursion is r*max|sin| over that arc;
//   - a BUMP ON THE LEG breaks the flush fold, because it has to stand proud of
//     the leg's own thickness to reach anything;
//   - a POCKET in the leg cannot break flush - it is material removed - and the
//     DISC does not sweep, so its tooth can be any size at all.
// The tooth hangs from a sprung tab in the disc's solid rear region, flexing in
// depth out through the back face where there is open air.  It rides clear of
// the leg for the whole stroke and only meets it in the last 3.7 deg, because
// the leg's top face does not reach that far back until then.
snap_det  = true;
det_at    = 3.0;    // engagement point, along the leg from the pivot
det_lift  = 0.325;   // how far the tooth stands past the leg's top face, in depth
                    //   - this is the deflection the leg has to climb to fold
// The tooth has to flex REARWARD, not in depth: at the deployed angle the leg's
// top face points down-and-back, so its normal is mostly -Z.  That puts the
// spring in the same place as the hard stop, so the two are decoupled - the stop
// wall stays SOLID and takes the load, the tooth pokes through a WINDOW in it,
// and the spring is a bridge behind the wall, flexing in Z.  The bridge is
// rooted in the disc's bulk well outboard of the slot, which is what makes it
// soft enough: a bridge spanning only the 12.4 slot is too stiff to survive the
// deflection, and a tab rooted at the rear would be a column, not a spring.
det_span  = 20.0;   // bridge span in X, rooted in the disc's bulk either side
det_tt    = 1.1;    // bridge thickness, along the long axis - it flexes this way
det_h     = 2.6;    // bridge height, in depth
det_wall  = 1.0;    // stop wall left SOLID in front of the bridge.  Without it the
                    //   bridge, the stem's window and the wall all shared one z
                    //   band: the bridge fused to the wall beyond the window and
                    //   came out 6.2x too stiff (87 MPa, past yield), and the
                    //   window ate the stop's bearing land down to two strips.
det_gapf  = 0.6;    // gap in front of the bridge, so it can flex forward too
det_w     = 5.0;    // tooth and stem width.  10 cut the stop wall down to 0.75 a
                    //   side; 5 leaves 3.25 a side to bear on.
det_tooth = 0.9;    // how far the tooth projects forward past the wall.  1.2 put
                    //   the tip at r 2.09 and the leg's mid-sweep envelope reaches
                    //   2.12, so the tip was clipped at 60 deg.
det_gap   = 1.0;    // relief behind the bridge, so it has somewhere to flex
// The tooth has to sit LOW in the slot, not up by the back face.  At the deployed
// angle the leg's top face has swept down past the wall, leaving a wedge of leg
// material that grows DOWNWARD from the back face - so a high tooth is caught
// early and rides for 20 deg, while a low one is caught late and clicks.  These
// two put the catch at about 111 deg: 11 deg of ramp, then the pocket.
// MEASURED against the leg, not derived: the leg's deep reach behind the pivot
// happens only in a thin sliver hard against the BACK FACE, not down at
// mid-thickness.  A tooth at y 1.2..2.6 was never touched at any angle at all.
// Up in the sliver it gives a proper ramp: first contact at 110 deg, deflected
// 0.071 / 0.233 / 0.325 at 110 / 116 / 120, then CLEAR at 122 as the pocket
// swallows it.  That is the channel -> ramp -> locking opening.
det_y0    = 3.2;    // tooth and stem, bottom in depth
det_y1    = 4.0;    // ... and top, flush with the disc's back face
det_clr   = 0.45;   // clearance around the stem where it passes the wall
det_fit   = 0.06;   // pocket growth over the tooth.  This is the DETENT: it sets
                    //   how much angular slack the tooth has once seated, and so
                    //   how far it must deflect to climb out.  0.225 (half of
                    //   det_clr, which it used to inherit) let the tooth float
                    //   +/-5 deg and there was no engagement at all.
det_pkt   = 0.60;   // pocket depth in the leg's top face
det_pkt_l = 1.50;   // pocket length along the leg                // how far the hub's rear arc stays off the floor


// HOLDING THE LEG.  Two different jobs, and they do not want the same mechanism.
//
// FOLDED, the leg has to resist being knocked open while the frame is carried.
// A catch lip at the far end of the slot does that: the foot snaps under it, and
// the leg flexes the 0.35 mm needed because the foot is 30 mm from the pivot and
// has all the leverage in the world.
//
// DEPLOYED, the frame's own weight already holds the leg into its hard stop -
// it cannot fold while it is carrying anything.  What it needs is enough hinge
// friction not to swing shut while the frame is picked up, which is a pin fit,
// not a detent.
//
// A detent on the hub was tried and does not work at this size: the heel flat -
// the surface that makes the hard stop - eats exactly the part of the hub that
// would have to carry it.
catch_snap = true;
catch_p = 0.65;    // how far the lip overhangs the slot -> ~0.3 mm of flex,
                   //   about 5 N at the foot, which is a firm but easy click
catch_t = 1.2;     // lip thickness
catch_c = 0.35;    // interference the foot has to flex past
detent_r = 22.0; detent_d = 3.0; // rotation detents

/* [Driver carrier] */
// The Waveshare board has no mounting holes, but it does have its two 19-pin
// male headers soldered on.  So it plugs into female headers on a carrier
// perfboard, and the carrier is what gets held down.  Any double-sided 0.1"
// prototype board does; this is sized for a 30 x 70 cut, which leaves ~14 mm of
// spare board below the driver for the battery divider.
carrier_fit = true;
carrier_w = 30.0; carrier_h = 70.0; carrier_t = 1.6;
hdr_h = 8.5;        // female header body: driver's underside to the carrier face
carrier_pad = 4.5;  // standoff pad diameter under each carrier corner
// MEASURED off the board: four dia 2.0 mounting holes, 24 x 64 edge-to-edge,
// which is 26 x 66 CENTRE to centre and lands 2.0 in from each edge of the
// 30 x 70 board - so the board the model already assumed is the board in hand.
// The pads become pegs: the holes drop straight onto them and locate the board
// instead of it floating on four blank pads.
carrier_hole  = 2.0;      // hole diameter
carrier_hx    = 26.0;     // hole centres, across the short axis
carrier_hz    = 66.0;     // hole centres, along the long axis
carrier_peg   = 0.15;     // peg undersize, so the board drops on rather than presses
carrier_pin   = 2.0;      // hole centre to the first header pin - a keep-out, so
                          //   nothing on the peg may be wider than 2*carrier_pin

/* [Rear USB-C pigtail] */
// Panel-mount pigtail with its own snap-in catch, so the cover just needs a
// precise rectangular hole and clear space behind it - no printed rails.
// MEASURE THE ACTUAL PART: snap fits live or die on a tenth of a millimetre.
port_snap = true;
// MEASURED: the receptacle body is 14.0 wide x 4.5 high.  snap_c is added per
// side on top of that, so the printed opening is 14.3 x 4.8 - a hole exactly the
// size of the part will not take the part.
snap_w = 14.0; snap_h = 4.5;   // the part, not the hole
snap_d = 10.0;                 // how far the body reaches into the interior
snap_c = 0.15;                 // per-side clearance on the opening

/* [Perfboard] */
// The divider and any wiring junctions live on a scrap of 0.1" perfboard in the
// band above the driver board.  11 x 4 holes: two 100k resistors and the ADC
// wire need about four holes between them, so 44 is generous, and it leaves
// 2.25 mm of slack top and bottom - worth having, because perfboard cut by
// scoring and snapping does not come out to the millimetre.  11 x 5 (12.7)
// also fits the band if you cut accurately.
perf_fit = false;    // folded into the driver carrier - see carrier_* above
perf_w = 27.9;   // 11 holes at 2.54
perf_h = 10.16;  //  4 holes at 2.54
perf_t = 1.6;

/* [Interior] */
elec_clr = 1.0;      // slack around the electronics box, all round
col_gap  = 2.0;      // between the driver column and the cell column
end_wall = 7.95;     // frame material beyond the interior, each long-axis end
side_wall = 3.0;     // minimum material outboard of the interior, each side

/* [Quality] */
$fa = 2; $fs = 0.4;

// ------------------------------------------------------------- derived
body_d = depth - cover_t;
pcb_px = -act_off_x;  pan_px = pcb_px + pan_off_x;

// ---- the interior, and what it has to hold ---------------------------------
// -X column: the driver board, hard against the wall the ribbon arrives at.
// +X column: the cell, with the charger above it.
bat_col_w = bat_w + 2*bat_clr + 2*bat_fence;
// the driver sits one rail-width off the -X wall: the rail has to stand inboard
// of the board's edge, and it has to stay inside the cavity
drv_inset = 3.0 - 1.0;                  // = drv_rail - 1.0, spelled out early
elec_w = (carrier_fit ? carrier_w : drv_inset + drv_w)
         + col_gap + max(bat_col_w, chg_w);
elec_h = max(carrier_fit ? carrier_h : drv_h, bat_h + 2*bat_clr + col_gap + chg_h);
// THE GLASS HAS TO GET IN.  It goes into its pocket from the back, so the
// interior opening has to be bigger than the glass in both directions - there
// is no other way in, because the front lip is smaller than the glass.  An
// interior sized only by the electronics comes out 80.9 on the long axis and
// walls a 90 mm glass out by 9 mm: a case that cannot be assembled.
// The glass is OFFSET (pan_px, to centre the ink), so comparing sizes is not
// enough - the interior has to cover where the glass actually is.  Comparing
// sizes left it 0.4 mm short on the -X side: another glass that cannot go in.
glass_x0 = pan_px - pan_w/2 - pan_clr_w - 0.5;
glass_x1 = pan_px + pan_w/2 + pan_clr_w + 0.5;
glass_pass_h = pan_h + 2*pan_clr_h + 1.0;
cav_w = bare_panel ? max(elec_w + 2*elec_clr, glass_x1 - glass_x0) : pcb_w + 2*mod_clr;
cav_h = bare_panel ? max(elec_h + 2*elec_clr, glass_pass_h) : pcb_h + 2*mod_clr;

half_cav = bare_panel ? cav_w/2 + side_wall
                      : abs(pcb_px) + pcb_w/2 + mod_clr + wall;
half_rib = abs(pcb_px + pan_off_x - pan_w/2 - pan_clr_w - rib_clr) + wall_rib;
W = 2*max(half_cav, half_rib);      // whichever the -X side actually needs
// with no PCB the long axis is set by the glass and by leaving enough material
// at each end to put a screw through
// End wall thick enough for a screw near each corner: rear chamfer, a margin,
// the head, a margin to the interior.  This sets the frame's long axis now.
// A post inside the interior cannot work - the glass has to pass through that
// interior on its way to the pocket, and at 90 mm long against a 21 mm deep
// interior it is flat by the time it clears anything, so tilting buys nothing.
scr_wall = rear_chf + 1.0 + scr_head + 1.0;
H = bare_panel ? cav_h + 2*scr_wall : pcb_h + 2*(mod_clr + wall);
Zc = H/2;
win_w = act_w + 2*white_show_short;  win_h = act_h + 2*white_show_long;
pcb_face_y = front_t + pan_t + 0.2;                  // the ledge behind the glass
mod_back   = pcb_face_y + (bare_panel ? 0 : pcb_t);  // where the interior starts
pk_d   = disc_d + 2*pocket_c;
pk_dep = disc_t + 0.15;
pk_y0  = depth - pk_dep;               // pocket floor
cov_in_pk = pk_y0 - pk_floor_t;        // cover inner face over the pocket
cov_in    = depth - cover_t;
// the interior is centred in the frame; only the GLASS is offset (to centre the
// ink), and with no PCB the two no longer have to share a datum
cav_cx = bare_panel
  ? min(max(0, glass_x1 - cav_w/2), glass_x0 + cav_w/2)
  : pcb_px;
cav_x0 = cav_cx - cav_w/2; cav_x1 = cav_cx + cav_w/2;
cav_z0 = Zc - cav_h/2;     cav_z1 = Zc + cav_h/2;
// ribbon cutout centre, measured from the glass's -Z edge
rib_cz  = (Zc + pan_off_z) - pan_h/2 + rib_off + rib_w/2;
rib_far = pan_h - rib_off - rib_w;      // what is left on the other side
// corner screw posts, sized here because the interior layout works around them
post_s  = 0;                             // no posts: see scr_wall above
post_y0 = front_t + pan_t + 1.0;
// ---- carrier board: -X column.  The driver plugs into female headers on it,
// so the carrier is what the case holds and the driver just pushes down into
// place.  The carrier runs past the driver at the bottom, and that spare board
// is where the battery divider goes.
carrier_cx = cav_x0 + elec_clr + carrier_w/2;
// Glass retention pads on the cover.  With the interior open behind the glass -
// which it has to be, or the glass cannot get in - these are what press it
// against the front lip.  One at each long-axis end, over the glass's dead
// border, sized and placed to miss the electronics: the top one is short
// because the charger runs up that side.
pad_h = 3.5;      // a rib, not a slab: it only has to touch the glass
pad_w = bare_panel ? [26.0, 20.0] : [13.0, 13.0];
// The TOP rib is shifted toward +X to clear the FPC adapter taped behind the
// glass: the adapter needs x -40.45..-22.45 and the rib used to start at -25.2.
// It still lands well inside the glass's dead border either way.
pad_off1 = 7.8;
pad_x = bare_panel
  ? [pan_px, pan_px - pad_off1]
  : [bat_cx - bat_w/2 - bat_clr - bat_fence - 1.0 - 6.5,
     bat_cx + bat_w/2 + bat_clr + bat_fence + 1.0 + 6.5];
pad_z = bare_panel
  ? [cav_z0 + pad_h/2 + 1.0, cav_z1 - pad_h/2 - 1.0]
  : [bat_cz + 12.0, bat_cz - 2.0];
// the bottom of the interior is spoken for: the glass rib sits against the end,
// and the rear pigtail sits beside it.  Everything else starts above them.
elec_z0 = cav_z0 + pad_h + 2.0;
carrier_z0 = elec_z0;
carrier_z1 = carrier_z0 + carrier_h;
carrier_cz = (carrier_z0 + carrier_z1)/2;
carrier_back = cov_in_pk;                         // sits at the puck face
carrier_face = carrier_back - carrier_t;
// ---- driver board, on the carrier, positioned so the 24-pin socket on its -X
// edge lines up with the middle of the ribbon slot.  Then the tail plugs
// straight in and no FPC extension is needed.
drv_rail = 3.0;                                   // only used without a carrier
drv_cx = carrier_fit ? carrier_cx : cav_x0 + drv_inset + drv_w/2;
drv_x0 = drv_cx - drv_w/2;  drv_x1 = drv_cx + drv_w/2;
// With the adapter fitted the driver no longer has to line up with the ribbon -
// that is the whole reason it is there - so the board goes low on the carrier
// instead of being dragged up to the ribbon end.
drv_z0 = !bare_panel  ? cav_z1 - 1.0 - drv_h
       : adapt_fit    ? carrier_z0 + 1.0
       : (fpc_end == "top") ? rib_end_z + fpc_off - drv_h   // hangs downward
       :                      rib_end_z - fpc_off;          // runs upward
drv_z1 = drv_z0 + drv_h;
drv_cz = (drv_z0 + drv_z1)/2;
drv_back = carrier_fit ? carrier_face - hdr_h : cov_in_pk - 0.5;
fpc_z = drv_z0 + fpc_off;                         // socket centre, on the -X edge
// ---- what the tail can actually reach.  rib_tail is the flat length; the 180
// deg fold back on itself at the pocket edge spends about 2*rib_dep of it, and
// what is left has to get from the glass edge to the adapter's own connector.
rib_reach = rib_tail - 2*rib_dep;
// What the tail gives up when its 180 deg fold straightens - a half-turn of
// radius rib_dep releases (pi-2)*r of length, and that is all the slack there is.
tail_give = (PI - 2) * rib_dep;
tail_crosses_split = tail_give >= serv_lift;
// The adapter therefore cannot be placed for convenience - it has to sit within
// rib_reach of the ribbon exit.  That puts it hard against the -X wall, at the
// ribbon end, which is where the carrier currently is.
// leg 3 turns inboard at the top of the run, so that is where the adapter's
// socket has to be - not hard against the RIGHT wall.
rib_end_z = (Zc + pan_off_z) + rib_exit + rib_run;   // where leg 3 starts
adapt_gap = 2.0;                                    // clear of the driver's parts.
                                                    //   1.0 still caught them by 0.2 mm.
adapt_cx = cav_x0 + elec_clr + adapt_w/2 + 1.0;
// Taped to the glass, the adapter sits in FRONT of everything - so the only
// thing it has to clear is the driver board's own tall parts, which stand
// drv_env-drv_t proud toward the glass.  Sitting it just above drv_z1 does that,
// and leg 3's turn still falls inside its span so the tail can reach a socket.
adapt_cz = drv_z1 + adapt_gap + adapt_h/2;
adapt_z0 = adapt_cz - adapt_h/2;  adapt_z1 = adapt_cz + adapt_h/2;
adapt_x0 = adapt_cx - adapt_w/2;  adapt_x1 = adapt_cx + adapt_w/2;
// plan-view overlap with the carrier - kept only because it is NOT a clash, and
// saying so stops it being rediscovered as one.  Taped to the glass the adapter
// sits at mod_back and the carrier's face is at carrier_face; adapt_clear is the
// gap that actually matters.
adapt_foul  = min(adapt_z1, carrier_z1) - max(adapt_z0, carrier_z0);
adapt_clear = carrier_face - (mod_back + adapt_env);
// ---- the perfboard, in the band between the driver board and the +Z wall
perf_cx = cav_x0 + elec_clr + perf_w/2 + 1.0;
perf_cz = (drv_z1 + cav_z1)/2;
perf_back = cov_in_pk - 0.5;
// ---- +X column: the cell low (keeps the centre of mass down), charger above it
bat_cx = bare_panel ? (carrier_fit ? carrier_cx + carrier_w/2 : drv_x1)
                      + col_gap + bat_col_w/2 : pcb_px;
bat_cz = elec_z0 + snap_h/2 + 0.5 + bat_clr + bat_h/2;  // clear of the port band
bat_x0 = bat_cx - bat_w/2;
// ---- charger breakout, on its own standoffs.  The quarter Perma-Proto it used
// to ride on is gone: it was the widest thing in the box and it took a corner
// the screws needed.  Divider and wiring go on a scrap of perfboard or straight
// onto the charger's pads.
// the charger is narrow enough to sit inboard of the corner posts, so it can
// run past them in Z
chg_x_c = cav_x1 - chg_w/2 - 1.0;
chg_back = cov_in_pk - 0.5;
proto_x0 = chg_x_c - chg_w/2;  proto_x1 = chg_x_c + chg_w/2;   // kept for the docs
proto_z0 = bat_cz + bat_h/2 + bat_clr + col_gap;
proto_z1 = proto_z0 + chg_h;
proto_cx = chg_x_c;  proto_cz = (proto_z0 + proto_z1)/2;
proto_back = chg_back;
proto_face = proto_back - proto_t;
// module retention pads, in the strips either side of the cell
// module 8-pin header, absolute
conn_x = pcb_px + conn_dx;
conn_z = Zc + conn_dz;
conn_y0 = mod_back;                 // front face of the keep-out
conn_y1 = mod_back + conn_h;        // back face
// ports
// rear-facing USB-C breakout: receptacle flush in the back cover
ucb_x = bare_panel ?  22.0 : -34.4;               // port centre on the back
ucb_z = bare_panel ? cav_z0 + snap_h/2 + 0.5 : 11.0;   // low, beside the bottom rib
ucb_w = 13.0; ucb_l = 13.0; ucb_t = 1.6;          // breakout board
port_w = 9.5; port_h = 3.7;                       // receptacle opening
chg_z = bare_panel ? proto_cz : proto_z0 + 3.0 + chg_h/2;
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
// Screws.  With a bare panel the end walls are ~14 mm of solid material, so a
// screw goes near each corner THROUGH THE END WALL - no post inside the box,
// nothing stolen from the electronics, and no corner left unfastened.  The old
// single spine of three, all on the +X side, left the whole -X edge unscrewed;
// there was nowhere else for them to go while a phantom PCB set the cavity.
scr_x = (cav_x1 + (W/2 - rear_chf))/2;   // legacy spine position, kept for reference
// Corner screws sit on POSTS inside the interior corners, not in the end walls.
// The walls cannot take them: the interior has to be big enough for the glass
// to drop through, which leaves about 8 mm at each end - not enough for a M3
// head once the rear chamfer has taken its 2 mm.  The posts start behind the
// glass plane so the glass still passes.
scr_cx = W/2 - rear_chf - 1.0 - scr_head/2;
scr_cz = rear_chf + 1.0 + scr_head/2;    // in from each long-axis end
scr_pos = bare_panel
  ? [[-scr_cx, scr_cz], [scr_cx, scr_cz], [-scr_cx, H-scr_cz], [scr_cx, H-scr_cz]]
  : [[scr_x, 14.0], [scr_x, Zc], [scr_x, H-14.0]];
scr_z = [14.0, Zc, H - 14.0];            // legacy, still used by the drawings
hub_z = W/2;                           // = distance to the bottom edge in BOTH orientations
theta_dep = 180 - stop_ang;            // leg swing angle when deployed
slot_w  = leg_w + 2*leg_slot_c;        // the leg's slot in the disc
// Where the leg's top face is, at the deployed angle, det_at along the leg.
// That point is what the tooth has to meet, so the tab's thickness follows from
// it rather than being chosen: tab = (disc_t - face) + det_lift.
det_fy  = disc_t/2 + ( leg_t/2*cos(theta_dep) + det_at*sin(theta_dep));
det_fz  = -pivot_r + (-leg_t/2*sin(theta_dep) + det_at*cos(theta_dep));
det_zw1 = -(pivot_r + stop_wall);      // stop wall, front face
det_zw0 = det_zw1 - det_wall;          //   ... back face
det_zb1 = det_zw0 - det_gapf;          // bridge, front face
det_zb0 = det_zb1 - det_tt;            //   ... back face
det_zr0 = det_zb0 - det_gap;           // rear relief
det_arm = sqrt(pow(det_fy - disc_t/2,2) + pow(det_fz + pivot_r,2));  // moment arm
det_I   = det_h*pow(det_tt,3)/12;
det_k   = 192*2400*det_I/pow(det_span,3);    // fixed-fixed bridge, N/mm
det_F   = det_k*det_lift;   // det_lift is the MEASURED peak deflection
det_T   = det_F*det_arm;                     // detent torque about the pivot
det_sig = (det_F*det_span/8)*(det_tt/2)/det_I;   // mid-span stress
piv_h   = disc_t/2;                    // pivot axis height above the pocket floor
hub_r   = piv_h - sweep_clr;           // rear of the hub: what can orbit and clear
sweep_a = 270 - theta_dep;             // local angle of the heel flat's tangent line
disc_rim_x = sqrt(pow(disc_d/2,2) - pow(pivot_r,2));   // rim, on the screw's axis
seat_x  = -(slot_w/2 + head_seat);     // where the screw head seats
scr_reach = (seat_x*-1) + slot_w/2 + ins_l;            // screw length needed
// Can the clamp screw physically exist in a disc this thin?  The screw runs
// along X, so its head seat and its insert bore are both bounded by disc_t.
flex_len = flex_z0 + flex_z1;           // clamp tongue, fixed at both ends
flex_I   = disc_t*pow(flex_t,3)/12;    // bending about X, in the layer plane
flex_k   = 3*2400*flex_I*pow(flex_len,3)
           / (pow(flex_z0,3)*pow(flex_z1,3));   // N/mm, load off-centre at the pivot
head_wall = (disc_t - scr_head)/2;     // PLA either side of the head seat
ins_wall  = (disc_t - ins_d)/2;        //   ditto, the insert bore
clamp_ok  = head_wall >= 0.4 && ins_wall >= 0.6;

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
    translate([cav_cx,y0,Zc]) xzext(d) relieved(cav_w,cav_h,cav_r,cav_rel);
    // The glass pocket's corner reliefs are centred ON the pocket's sharp
    // corners, so they bulge pan_rel outboard of the pocket - and that is
    // further out than the interior reaches on three sides.  The interior wall
    // was left hanging over them by 0.9 mm.  Carrying the same four circles up
    // through the wall takes the overhang away; it costs nothing dimensionally,
    // because the frame still has 2.6 mm of wall outboard of the worst one.
    if (pan_rel > 0)
        translate([pan_px, y0, Zc + pan_off_z]) xzext(d)
            for(sx=[-1,1], sz=[-1,1])
                translate([sx*(pan_w/2 + pan_clr_w), sz*(pan_h/2 + pan_clr_h)])
                    circle(r=pan_rel); }
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
// The ledge behind the glass, at each long-axis end, and the tape pads recessed
// into it.  Which side of the glass pocket that ledge sits on flips with
// bare_panel: with a module PCB the cavity is LONGER than the pocket and the
// ledge is outboard of it; with a bare panel the interior is SHORTER, so the
// ledge is inboard - solid frame directly behind the ends of the glass, which
// is also what traps the glass in place.
ledge_end = bare_panel ? (pan_h + 2*pan_clr_h)/2 - cav_h/2
                       : cav_h/2 - (pan_h + 2*pan_clr_h)/2;
tape_r    = min(tape_reach, max(0, ledge_end - 0.8));
tape_at   = bare_panel ? cav_h/2 + tape_r/2
                       : (pan_h + 2*pan_clr_h)/2 + tape_r/2;

module tape_pocket(){
    if (tape_pad && tape_r > 0.5)
        for (sz=[-1,1])
            translate([pan_px, pcb_face_y - tape_dep, (Zc + pan_off_z) + sz*tape_at])
                xzext(tape_dep + 0.01)
                    square([tape_len, tape_r + 0.02], center=true);
    }
module window_cut(){
    zw = Zc + act_off_z;
    prism(win_w,win_h,3,front_t+1,0,zw,-0.5);
    hull(){ prism(win_w+2*win_chf,win_h+2*win_chf,3+win_chf,0.01,0,zw,-0.5);
            prism(win_w,win_h,3,0.01,0,zw,win_chf); } }
module usb_cut(){
    // Waveshare board's USB-C.  Straight through the long-axis +Z wall when
    // flash_port, otherwise a BLIND pocket: same clearance for the jack, but
    // flash_wall of skin left so the outside stays unbroken.
    //
    // With the board stood on the -X side to meet the ribbon, its jack ends up
    // in the middle of the interior instead of against the top wall, so there
    // is nothing to cut and nothing to seal: the pocket is skipped entirely.
    // The jack is then reachable only before the cover goes on - flash first.
    fz0 = cav_z1 - 1.2;
    fz1 = flash_port ? H + 2 : H - flash_wall;
    if (drv_z1 + 1.2 >= cav_z1)
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
    if (port_snap) {
        // the pigtail's own catch holds it; all the case owes it is a precise
        // hole and snap_d of clear space behind
        translate([ucb_x, cov_in-0.1, ucb_z]) rotate([-90,0,0])
            linear_extrude(cover_t+0.2)
                offset(r=0.6) offset(delta=-0.6)
                    square([snap_w+2*snap_c, snap_h+2*snap_c], center=true);
    } else {
        // slot for the breakout board through the register lip ...
        translate([ucb_x, cov_in-2.2, ucb_z]) xzext(2.5) rrect(ucb_w+1.0, port_h+0.8, 0.8);
        // ... and the receptacle opening through the skin
        translate([ucb_x, cov_in-0.3, ucb_z]) xzext(cover_t+0.6) rrect(port_w, port_h, 1.2);
    } }
module front_chamfer(){
    difference(){
        translate([-W,-0.01,-H]) cube([2*W,front_chf+0.01,3*H]);
        hull(){ prism(W-2*front_chf,H-2*front_chf,max(corner_r-front_chf,0.5),0.01,0,Zc,-0.005);
                prism(W,H,corner_r,0.01,0,Zc,front_chf); } } }

// ================================================================== frame
module frame(){
    difference(){
        // the shell, then the corner posts put back INSIDE the interior the
        // cavity just carved out - they have to be added after the cut, or the
        // cavity erases them
        union(){
            difference(){
                outer(body_d);
                window_cut();
                front_chamfer();
                panel_pocket(pcb_face_y-front_t+0.01, front_t);
                tape_pocket();
                cavity(body_d, pcb_face_y);
                usb_cut();
                rear_chamfer();
                for(sz=[-1,1]) translate([cav_cx-cav_w/2-1.5, body_d-2.5, Zc+sz*32-5])
                    cube([1.6, 2.1, 10]);
                lightening();
            }
        }
        prism(cav_w+2.0, cav_h+2.0, cav_r+1.0, 1.1, cav_cx, Zc, body_d-1.0);
        // and the fastener holes last, so they go through the posts
        for(sp=scr_pos) translate([sp[0],body_d+0.1,sp[1]]) rotate([90,0,0])
            if (insert_fit) {
                cylinder(d=ins_d, h=ins_l+ins_relief);          // insert bore
                cylinder(d1=ins_d+0.8, d2=ins_d, h=0.4);        // lead-in, so the
            } else                                              //   insert starts square
                cylinder(d=scr_pilot, h=scr_depth);
        rear_chamfer();
    } }

// A post in each interior corner, from behind the glass plane back to the cover
// face, tied into both walls.  This is what the corner screws thread into.
module corner_posts(){
    if (false)
        for (sx=[-1,1], sz=[-1,1])
            translate([sx*(cav_w/2 - post_s/2), post_y0,
                       Zc + sz*(cav_h/2 - post_s/2)])
                xzext(body_d - post_y0)
                    offset(r=1.0) offset(delta=-1.0)
                        square([post_s, post_s], center=true);
}

// The end walls carry the corner screws, so they are 13.75 mm of solid frame -
// about 24 cm3 of filament doing nothing between the screw bosses.  This takes
// the middle of each one back out from the cover side, leaving 2 mm of floor
// behind the glass ledge, a rim all round, and the bosses untouched.
// The two end walls are solid frame doing nothing but joining the sides.  This
// takes the middle out of each from the cover side, leaving a 2 mm floor and a
// 2 mm rim.  The corner screws are inboard on their posts now, so nothing here
// has to dodge them.
lgt_w  = cav_w - 8.0;
lgt_y0 = mod_back + 2.0;
module lightening(){
    if (bare_panel)
        for (sz=[-1,1]) {
            z0 = sz > 0 ? cav_z1 + 2.0 : 2.5;
            z1 = sz > 0 ? H - 2.5      : cav_z0 - 2.0;
            if (z1 - z0 > 3.0)
                translate([cav_cx, lgt_y0, (z0+z1)/2]) xzext(body_d - lgt_y0 + 0.1)
                    rrect(lgt_w, z1 - z0, 1.5);
        } }

// ================================================================= cover
module cover(){
    difference(){
        union(){
            prism(cav_w+1.7, cav_h+1.7, cav_r+1.0, cover_t+1.0, cav_cx, Zc, body_d-1.0);
            outer(cover_t, body_d);
            // ---- module retention: full ribs top and bottom, two short
            //      segments on +X so the cell can use the middle of that edge
            for(i=[0,1])
                translate([pad_x[i], mod_back+rib_gap, pad_z[i]])
                    xzext(cov_in-mod_back-rib_gap)
                        square([pad_w[i], bare_panel ? pad_h : 22.0],center=true);

            // ---- solid puck the stand pocket is bored into
            cylY(pk_d+2*lug_out+6, depth-cov_in_pk, 0, hub_z, cov_in_pk);
            // ---- driver carrier: four standoff pads at its corners.  The
            // driver itself is not held by the case at all - it plugs into
            // female headers on the carrier and the carrier is what is held.
            if (carrier_fit)
                for(sx=[-1,1],sz=[-1,1])
                    translate([carrier_cx+sx*carrier_hx/2, cov_in,
                               carrier_cz+sz*carrier_hz/2]) rotate([90,0,0]) {
                        // the pad the board sits on...
                        cylinder(d=carrier_pad+2.0, h=cov_in-carrier_back);
                        // ...and the peg through its own hole, which locates it.
                        // Kept under 2*carrier_pin across so it cannot foul the
                        // first header pin row.
                        cylinder(d=min(carrier_hole-carrier_peg, 2*carrier_pin),
                                 h=cov_in-carrier_back+carrier_t+1.2); }
            else {
                translate([drv_cx + drv_w/2+drv_clr+drv_rail/2-1.0, drv_back-2.6, drv_cz])
                    xzext(cov_in-drv_back+2.6) square([drv_rail, drv_h-1.0],center=true);
                translate([drv_cx - (drv_w/2+drv_clr+drv_rail/2-1.0), drv_back-2.6, drv_cz])
                    xzext(cov_in-drv_back+2.6) square([drv_rail, drv_h-1.0],center=true);
                translate([drv_cx, drv_back-2.6, drv_z0-1.4])
                    xzext(cov_in-drv_back+2.6) square([drv_w-2, 2.0],center=true);
            }
            // ---- perfboard: four standoff pads in the band above the driver
            if (bare_panel && perf_fit)
                for(sx=[-1,1],sz=[-1,1])
                    translate([perf_cx+sx*(perf_w/2-2.5), cov_in, perf_cz+sz*(perf_h/2-2.5)])
                        rotate([90,0,0]) cylinder(d=4.0, h=cov_in-perf_back);
            // ---- charger breakout: four standoff pads, foam tape or a strap
            //      holds it.  No screw posts: the board's hole spacing is not
            //      one of the numbers this model has measured.
            for(sx=[-1,1],sz=[-1,1])
                translate([chg_x_c+sx*(chg_w/2-3.5), cov_in, chg_z+sz*(chg_h/2-3.5)])
                    rotate([90,0,0]) cylinder(d=6.0, h=cov_in-chg_back);
            // ---- battery fence (cell is held by foam tape inside it)
            // flat platform so the cell doesn't straddle the puck's step
            translate([bat_cx, cov_in_pk, bat_cz])
                xzext(cov_in-cov_in_pk+0.01)
                    square([bat_w+2*bat_clr+2*bat_fence,
                            bat_h+2*bat_clr],center=true);
            for(sx=[-1,1])
                translate([bat_cx+sx*(bat_w/2+bat_clr+bat_fence/2), cov_in_pk-bat_t, bat_cz])
                    xzext(bat_t) square([bat_fence, bat_h-14],center=true);
            // ---- guide rails for a bare USB-C breakout board.  Not needed for
            // a pigtail that snaps into the skin on its own - that just wants a
            // clean opening and clear air behind it.
            if (!port_snap)
                for(sz=[-1,1], sx=[-1,1])
                    translate([ucb_x + sx*(ucb_w/2-0.5), cov_in-ucb_l,
                               ucb_z + sz*(ucb_t/2+0.15+1.0)])
                        xzext(ucb_l) square([2.0, 2.0],center=true);
            // ---- cover tongues that hook under the -X wall
            for(sz=[-1,1]) translate([cav_x0-1.4, body_d-2.4, Zc+sz*32-4.5])
                cube([1.4,1.6,9]);   // 1.3 left them 0.1 short of the lip, floating
        }
        // board slot + a lip on each rail - rail mounting only
        if (!carrier_fit)
            translate([drv_cx, drv_back-drv_t-0.15, (drv_z0+cav_z1+6)/2])
                xzext(drv_t+0.3) square([drv_w+2*drv_clr, cav_z1+6-drv_z0],center=true);

        pocket_cut();
        rear_port_cut();
        // clear space for the pigtail body itself: anything printed in the cover
        // that strays into it - platform, ribs - gets relieved automatically
        if (port_snap)
            translate([ucb_x, cov_in-snap_d, ucb_z]) xzext(snap_d+0.2)
                square([snap_w+1.5, snap_h+1.5], center=true);
        rear_chamfer();
        for(sp=scr_pos){
            translate([sp[0], body_d-0.1, sp[1]]) rotate([-90,0,0])
                cylinder(d=scr_free, h=cover_t+1.2);
            if (insert_fit)      // 90 deg countersink, opening at the back face
                translate([sp[0], depth-scr_csk, sp[1]]) rotate([-90,0,0])
                    cylinder(d1=scr_free, d2=scr_head, h=scr_csk+0.01);
            else
                translate([sp[0], depth-scr_cb, sp[1]]) rotate([-90,0,0])
                    cylinder(d=scr_head, h=scr_cb+1); }
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

// The clamp land: material LEFT IN the slot on the near wall, at the pivot, so
// the slot is line-to-line with the leg there instead of 0.4 loose.  45 deg
// lead-ins at both ends along Z, so the leg presses in rather than jamming on a
// square step.  Full disc thickness, because the leg's side face is what it
// bears on and that face turns with the leg.
module clamp_pad(){
    // x0 reaches 0.01 INTO the wall, not onto its face.  Flush with the slot's
    // own cut plane the two are coplanar, and CGAL leaves degenerate edges
    // behind - it cost 17 non-manifold edges in disc.stl once.
    x0 = -slot_w/2 - 0.01;   x1 = -slot_w/2 + clamp_pr;
    z0 = -pivot_r - clamp_len/2;   z1 = -pivot_r + clamp_len/2;
    translate([0, -0.02, 0]) xzext(disc_t + 0.04)
        polygon([[x0, z0-clamp_pr], [x1, z0], [x1, z1], [x0, z1+clamp_pr]]);
}

// The tooth, and the stem carrying it back through the stop wall to the bridge.
// ONE definition: the disc ADDS this solid and the leg SUBTRACTS the very same
// solid transformed into leg-local coordinates, so the pocket cannot be
// misaligned with the tooth - the alignment is construction, not arithmetic.
// z layout behind the slot, front to back:
//   det_zw1  the wall's front face - what the leg's stop lands on
//   det_zw0  the wall's back face      (det_wall thick, SOLID across the slot)
//   det_zb1  the bridge's front face   (det_gapf of air in front of it)
//   det_zb0  the bridge's back face    (det_tt thick)
//   det_zr0  the rear relief           (det_gap of air behind it)
module det_solid(grow=0){
    translate([-(det_w/2+grow), det_y0-grow, det_zb1-grow])
        cube([det_w+2*grow, (det_y1-det_y0)+2*grow,
              (det_zw1 + det_tooth - det_zb1)+2*grow]);
}
// The spring: a bridge across the disc's rear bulk, flexing along the long axis.
module det_bridge(){
    translate([-det_span/2, disc_t - det_h, det_zb0])   // top-aligned, so it
        cube([det_span, det_h, det_tt]);                //   meets the tooth
}
// ...and the clearance it needs: a window through the stop wall for the stem,
// and a relief behind the bridge so it has somewhere to flex into.
module det_free(){
    // window through the stop wall, only as wide as the stem needs
    translate([-(det_w/2+det_clr), det_y0-det_clr, det_zb1])
        cube([det_w+2*det_clr, (det_y1-det_y0)+2*det_clr, det_zw1-det_zb1]);
    // air in FRONT of the bridge, across its whole span - this is what was
    // missing, and it is why the bridge was only free over the window's width
    translate([-det_span/2-0.01, disc_t - det_h, det_zb1])
        cube([det_span+0.02, det_h, det_zw0-det_zb1]);
    // ...and behind it
    translate([-det_span/2-0.01, disc_t - det_h, det_zr0])
        cube([det_span+0.02, det_h, det_gap]);
}

module disc(){
    slot_z0 = -(pivot_r + stop_wall);
    slot_z1 = leg_len - pivot_r + 3.5;
    // where the foot sits when the leg is folded, and where the catch lip goes
    foot_z = leg_len - pivot_r;
    union(){
    if (catch_snap)    // catch lip: the foot snaps under it when the leg closes
        translate([0, disc_t - catch_t, foot_z - catch_p/2 + 0.01])
            rotate([0,90,0]) rotate([0,0,45])
                cylinder(d=catch_p*2*sqrt(2), h=slot_w+3.0, center=true, $fn=4);
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
        difference(){                       // the slot, less the clamp land
            translate([-slot_w/2, -0.01, slot_z0])
                cube([slot_w, disc_t+0.02, slot_z1-slot_z0]);
            if (clamp_land) clamp_pad();
        }
        if (snap_det) det_free();       // window through the wall, relief behind
        if (clamp_land && clamp_flex)   // relief slot behind the clamp land
            prism(flex_gap, flex_len+1.0, flex_gap/2, disc_t+0.02,
                  -(slot_w/2 + flex_t + flex_gap/2),
                  -pivot_r + (flex_z1 - flex_z0 - 1.0)/2, -0.01);
        if (pivot_screw) {
            // clearance the whole way through the near wall and the leg
            translate([-disc_d, disc_t/2, -pivot_r]) rotate([0,90,0])
                cylinder(d=scr_free, h=disc_d);
            // access channel in from the rim, flat-bottomed on the screw's axis
            // at seat_x: that flat is what the head and its washer sit on.
            // Only cut if it fits in disc_t - otherwise it is a trough, open on
            // both faces, that fouls the pocket floor.  clamp_ok is the test.
            if (clamp_ok)
                translate([-disc_d, disc_t/2, -pivot_r]) rotate([0,90,0])
                    cylinder(d=scr_head+0.8, h=disc_d + seat_x);
            // insert bore in the far wall
            translate([slot_w/2 - 0.01, disc_t/2, -pivot_r]) rotate([0,90,0])
                cylinder(d=ins_d, h=ins_l+ins_relief);
        } else
            translate([-disc_d, disc_t/2, -pivot_r]) rotate([0,90,0])
                cylinder(d=pin_d+pin_fit, h=2*disc_d);
        // soften the outer edge
        translate([0, disc_t-0.6, 0]) rotate([-90,0,0])
            difference(){ cylinder(d=disc_d+2,h=0.7);
                          cylinder(d1=disc_d-1.2,d2=disc_d+0.1,h=0.65); }
    }
    if (snap_det) { det_bridge(); det_solid(); }
    } }

// =================================================================== leg
// leg-local: pin at the origin, leg along +Z, thickness in Y centred on 0
module leg_shape(){
    difference(){
        rotate([90,0,0]) translate([0,0,-leg_t/2]) linear_extrude(leg_t)
            hull(){ circle(d=leg_w); translate([0,leg_len-foot_r]) circle(r=foot_r); }
        // heel flat: the pocket floor, seen from the leg at the deployed angle
        rotate([theta_dep,0,0]) translate([-50,-60-disc_t/2,-200]) cube([100,60,400]);
        // sweep relief: the rear of the hub, back to hub_r, over the sector that
        // passes straight down during the stroke.  Without this the heel flat's
        // far corner orbits 1.8 into the pocket floor and the leg jams.
        if (hub_sweep) hub_sweep_cut();
        // the detent pocket: the disc's own tooth, inverted into leg-local
        // coordinates and grown by det_fit - small, so the tooth has to deflect.
        // leg_placed does translate-then-rotate, so undoing it is
        // rotate(+theta) after translate(-T) - in that order.
        if (snap_det)
            rotate([theta_dep,0,0]) translate([0, -disc_t/2, pivot_r])
                det_solid(det_fit);
        // axle.  A bearing fit on the screw shank: the clamp is what holds it,
        // not the hole.
        translate([-leg_w,0,0]) rotate([0,90,0])
            cylinder(d=pivot_screw ? scr_free + 0.2 : pin_d+pin_fit, h=2*leg_w);
        // nail chamfer on the tip
        translate([0,leg_t/2,leg_len]) rotate([0,90,0])
            translate([0,0,-leg_w]) cylinder(r=2.2,h=2*leg_w,$fn=4);
    } }

// Everything beyond hub_r, in the leg-local angular sector that swings through
// 'straight down' somewhere in the stroke.  Local angle is measured from the
// leg's own +Z axis; the sector runs from sweep_a (= 270 - theta_dep, which is
// exactly where the heel flat touches the floor at the deployed angle) round to
// 270.  Drawn in the swing plane and extruded along the pivot axis.
module hub_sweep_cut(){
    translate([-leg_w,0,0]) rotate([0,90,0]) linear_extrude(2*leg_w)
        difference(){
            pie(leg_len, -90, theta_dep - 90);   // 2D angle = 180 - local angle
            circle(r=hub_r);
        }
}

// The adapter is TAPED TO THE BACK OF THE GLASS, not mounted to the case.  That
// is what makes it fit: at the glass's back face, in the band above the driver
// board, there is 14.8 mm of clear depth against the 5 it needs.  The footprint
// still overlaps the carrier in plan view, but they are 9.8 mm apart in DEPTH,
// so it was never a real conflict - reading a plan-view overlap as a clash is
// what made this look homeless for so long.
//
// It also lands on the right side of the split: taped to the glass, the adapter
// stays with the FRAME, so the panel's short stiff tail never crosses the joint
// and only the long FPC does.  That is exactly the service loop.
module mock_adapter(){
    if (adapt_fit)
        color("#3f7f3f") translate([adapt_cx, mod_back, adapt_cz])
            xzext(adapt_env) square([adapt_w, adapt_h], center=true);
}

module leg_placed(theta){
    translate([0, disc_t/2, -pivot_r]) rotate([-theta,0,0]) leg_shape(); }

module leg(){ rotate([90,0,0]) leg_shape(); }

// ============================================================== hardware
module mod_conn(){
    if (mod_header)
        translate([conn_x, conn_y0, conn_z]) xzext(conn_h)
            square([conn_w, conn_l], center=true); }
module mock_module(){
    // SHARP corners, as measured - this is what the relief has to swallow.
    // The PCB only exists on the module version of the panel.
    if (!bare_panel)
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
    // charger breakout: on its own standoffs when the panel is bare (no
    // Perma-Proto), riding on the proto otherwise
    if (!bare_panel)
        color("#1b5e20") translate([proto_cx, proto_face, proto_cz])
            xzext(proto_t) square([proto_w, proto_h],center=true);
    color("#155799") translate([bare_panel ? chg_x_c : proto_x0+chg_w/2+1,
                                bare_panel ? chg_back-chg_t : proto_face-chg_t+proto_t,
                                chg_z])
        xzext(bare_panel ? chg_t : chg_t-proto_t) square([chg_w, chg_h],center=true);
    // driver carrier
    if (carrier_fit)
        color("#8a6a3a") translate([carrier_cx, carrier_face, carrier_cz])
            xzext(carrier_t) square([carrier_w, carrier_h],center=true);
    // divider / wiring perfboard
    if (bare_panel && perf_fit)
        color("#8a6a3a") translate([perf_cx, perf_back-perf_t, perf_cz])
            xzext(perf_t) square([perf_w, perf_h],center=true);
    // rear USB-C: a snap-in pigtail body, or a breakout board in rails
    if (port_snap)
        color("#2b2b2b") translate([ucb_x, cov_in-snap_d, ucb_z])
            xzext(snap_d) square([snap_w, snap_h], center=true);
    else {
        color("#155799") translate([ucb_x, cov_in-ucb_l/2, ucb_z])
            translate([-ucb_w/2,-ucb_l/2,-ucb_t/2]) cube([ucb_w,ucb_l,ucb_t]);
        color("#c9ccd1") translate([ucb_x, cov_in-4.0, ucb_z])
            xzext(3.9) rrect(port_w-0.4, port_h-0.4, 1.0);
    }
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
    if (!bare_panel)
        translate([proto_cx, proto_face, proto_cz]) xzext(proto_t) square([proto_w,proto_h],center=true);
    translate([bare_panel ? chg_x_c : proto_x0+chg_w/2+1,
               bare_panel ? chg_back-chg_t : proto_face-chg_t+proto_t, chg_z])
        xzext(bare_panel ? chg_t : chg_t-proto_t) square([chg_w,chg_h],center=true); }

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
if (part=="bezel_test") translate([0,H,0]) rotate([90,0,0]) bezel_test();
else if (part=="frame")   translate([0,H,0]) rotate([90,0,0]) frame();
else if (part=="cover")   translate([0,0,depth]) rotate([-90,0,0]) cover();
else if (part=="disc")    rotate([-90,0,0]) disc();
else if (part=="leg")     leg();
else if (part=="standing_p") standing(false);
else if (part=="standing_l") standing(true);
else if (part=="exploded"){
    frame(); translate([0,14,0]) cover();
    translate([0,30,Zc]) rotate([-90,0,0]) disc(); }
else if (part=="plate"){
    translate([-60,H,0]) rotate([90,0,0]) frame();
    translate([60,0,depth]) rotate([-90,0,0]) cover();
    translate([60,-70,0]) rotate([-90,0,0]) disc();
    translate([0,-70,0]) leg(); }
else if (part=="assembly") device(0, theta_dep);
else if (part=="folded") device(0, 0);
else if (part=="folded_l") device(-90, 0);
else if (part=="guts"){ color("#5a5e67") cover(); mock_board(); mock_adapter(); }

echo(str("OUTER: short axis ",W," | long axis ",H," | depth ",depth));
echo(str("BEZEL: short-axis sides ",W/2-win_w/2,"  long-axis ends ",H/2-win_h/2,
         " | white shown: short ",white_show_short," long ",white_show_long));
echo(str("walls: +X ",W/2-cav_x1,"  -X ",W/2+cav_x0,
         " | end walls ",cav_z0," / ",H-cav_z1));
echo(str("interior behind PCB ",cov_in-mod_back,"  over stand pocket ",cov_in_pk-mod_back));
echo(str("DRIVER BOARD outline ",drv_w," x ",drv_h," x ",drv_env," on its own",
         " | but the number that decides fit is drv_stack ",drv_stack,
         " - see DEPTH BUDGET below | off the puck ",cov_in-mod_back," available"));
echo(str("CLEARANCE in front of: cell ",cov_in_pk-bat_t-mod_back,
         " | proto pcb ",proto_face-mod_back," | driver pcb ",drv_back-drv_t-mod_back));
echo(str("module 8-pin header: ", mod_header
         ? str("allowance assumed ",conn_h," mm")
         : "NOT FITTED - there is no module PCB, just bare glass and a tail"));
// Does the tail reach the driver board direct?  The ribbon's own S puts leg 3 at
// rib_end_z, rib_run above the exit, and a board whose socket sits fpc_off from
// one end then has drv_h of board to put somewhere.  WHICH end matters, and it
// is the whole question of whether the adapter is needed:
drv_dir_lo_z0 = rib_end_z - fpc_off;              // socket fpc_off from the BOTTOM end
drv_dir_lo_z1 = drv_dir_lo_z0 + drv_h;
drv_dir_hi_z1 = rib_end_z + fpc_off;              // socket fpc_off from the TOP end
drv_dir_hi_z0 = drv_dir_hi_z1 - drv_h;
drv_dir_lo_ok = drv_dir_lo_z0 >= cav_z0 && drv_dir_lo_z1 <= cav_z1;
drv_dir_hi_ok = drv_dir_hi_z0 >= cav_z0 && drv_dir_hi_z1 <= cav_z1;
echo(str("DIRECT PLUG-IN? leg 3 is at z ",rib_end_z,", so a board with its socket",
         " ",fpc_off," from the BOTTOM end spans z ",drv_dir_lo_z0," to ",
         drv_dir_lo_z1," -> ", drv_dir_lo_ok ? "fits"
           : str("OVERRUNS the interior top by ",drv_dir_lo_z1-cav_z1),
         "  ||  the SAME board turned end-for-end, socket ",fpc_off," from the TOP",
         " end, spans z ",drv_dir_hi_z0," to ",drv_dir_hi_z1," -> ",
         drv_dir_hi_ok ? "FITS" : str("overruns by ",drv_dir_hi_z1-cav_z1)));
echo(str("CROSSING THE SPLIT: the glass is on the FRAME, the driver on the COVER,",
         " so whatever joins them has to survive the cover lifting off.  The tail",
         " is ",rib_tail," long with no slack; its 180 deg fold gives back about ",
         tail_give," when it straightens, against the ",serv_lift,
         " a ZIF lever needs -> ", tail_crosses_split ? "it can cross"
           : str("IT CANNOT.  Short by ",serv_lift-tail_give,
                 ".  That, not reach, is why the adapter is fitted: it is a",
                 " service loop, and the long FPC is what crosses the split")));
echo(str("ADAPTER DEPTH COST: driver stack ",drv_stack," + adapter ",adapt_env,
         " = ",drv_stack+adapt_env," in front of each other, against ",
         cov_in_pk-mod_back," available -> ",
         (drv_stack+adapt_env <= cov_in_pk-mod_back) ? "fits"
           : str("SHORT by ",drv_stack+adapt_env-(cov_in_pk-mod_back),
                 ".  depth ",depth," -> ",depth+(drv_stack+adapt_env-(cov_in_pk-mod_back)),
                 " would cover it, or low-profile headers (hdr_h ",hdr_h,
                 " -> 5.5) buy back 3.0 of it")));
echo(str("FPC ADAPTER: ", adapt_fit
         ? str(adapt_w," x ",adapt_h," x ",adapt_env,", TAPED to the",
               " back of the glass at x ",adapt_x0," to ",adapt_x1,", z ",adapt_z0,
               " to ",adapt_z1," | depth there: glass back ",mod_back," to the",
               " carrier's face ",carrier_face," = ",carrier_face-mod_back,
               ", so it clears by ",adapt_clear,
               " | it overlaps the carrier by ",adapt_foul,
               " in PLAN, which is not a clash - they are ",adapt_clear,
               " apart in depth | sits ",adapt_gap," above the driver's parts",
               " | leg 3 turns at z ",rib_end_z," and runs ",rib_leg3,
               " inboard, ending between x ",
               (pan_px - pan_w/2 - rib_clr_out) + rib_leg3," and ",
               (pan_px - pan_w/2 - rib_clr_out + rib_band) + rib_leg3," -> ",
               ((pan_px - pan_w/2 - rib_clr_out + rib_band + rib_leg3) >= adapt_x0
                && (pan_px - pan_w/2 - rib_clr_out + rib_leg3) <= adapt_x1
                && rib_end_z >= adapt_z0 && rib_end_z <= adapt_z1)
                 ? "LANDS ON THE ADAPTER" : "MISSES THE ADAPTER",
               " | taped to the glass it stays with the FRAME, so only the long",
               " FPC crosses the split")
         : "not fitted"));
echo(str("DEPTH BUDGET over the puck: stack ",drv_stack," measured (driver + female",
         " sockets + carrier), room ",cov_in_pk-mod_back," -> ",
         (drv_stack <= cov_in_pk-mod_back)
           ? str("fits by ",cov_in_pk-mod_back-drv_stack)
           : str("SHORT by ",drv_stack-(cov_in_pk-mod_back)),
         " | every extra mm of disc_t comes straight off this: disc_t ",disc_t,
         " -> ",disc_t+2," would leave ",cov_in_pk-mod_back-2,
         ", which is ", ((cov_in_pk-mod_back-2) >= drv_stack) ? "still enough" : "NOT enough"));
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
echo(str("RIBBON ROUTE (rear face, portrait): tail leaves the CENTRE of the RIGHT",
         " side, ",rib_exit," off the glass centre | leg 1 out ",rib_out,
         " | leg 2 turns to the TOP, ",rib_band," wide x ",rib_run," long",
         " | leg 3 turns inboard, away from RIGHT, at z ",rib_end_z,", and runs ",
         rib_leg3," - it only has to LAND on the adapter, the tail folds over onto it"));
echo(str("RIBBON OUTBOARD: leg 1 needs ",rib_out," out from the GLASS edge; the",
         " relief gives ",rib_clr+pan_clr_w," (rib_clr ",rib_clr," from the pocket",
         " edge plus ",pan_clr_w," of pocket clearance) -> ",
         (rib_clr+pan_clr_w >= rib_out)
           ? str("clear by ",rib_clr+pan_clr_w-rib_out)
           : str("SHORT by ",rib_out-(rib_clr+pan_clr_w),
                 ".  rib_clr ",rib_out-pan_clr_w," would fix it and grows W by ",
                 2*(rib_out-pan_clr_w-rib_clr))));
echo(str("RIBBON LENGTH - CHECK THIS: the route needs at least ",rib_out+rib_run,
         " of developed tail before leg 3 even starts (",rib_out," + ",rib_run,
         "), against rib_tail ",rib_tail," measured flat.  Those two do not agree",
         " - one of them is wrong, and it decides whether leg 2 can really run ",
         rib_run));
echo(str("RIBBON HOLLOW HEADROOM: the corner screw bores at z ",cav_z0+scr_cz,
         " and ",cav_z1-scr_cz," reach x ",-scr_cx+ins_d/2," , which overlaps the",
         " hollow's x ",-(abs(pan_px)+pan_w/2+pan_clr_w+rib_clr)," to ",
         -(abs(pan_px)+pan_w/2+pan_clr_w)," - so THEY are what caps its length, not",
         " the route | hollow ends at z ",(Zc+pan_off_z)-pan_h/2+rib_off+rib_w,
         ", bore starts at z ",cav_z1-scr_cz-ins_d/2,
         " -> ",(cav_z1-scr_cz-ins_d/2)-((Zc+pan_off_z)-pan_h/2+rib_off+rib_w),
         " of headroom.  The other cost of length is the ",wall_rib,
         " outer wall outboard of it, which is now ",rib_w," long"));
echo(str("RIBBON RELIEF along the long axis: ",rib_w," long | ",rib_off,
         " from the -Z glass edge, ",rib_far," from the +Z edge | they sum to ",
         rib_off+rib_w+rib_far," against a ",pan_h," glass"));
echo(str("TAPE PADS: ", tape_pad
         ? str("2 (both long-axis ends), ",tape_len," along the short axis x ",
               tape_r," into the ledge x ",tape_dep," deep | ledge is ",ledge_end,
               " (", bare_panel ? "solid frame behind the ends of the glass"
                                : "PCB seat", "), ",ledge_end-tape_r,
               " of it left | pad face at depth ",
               pcb_face_y-tape_dep," vs glass back ",front_t+pan_t)
         : "none"));
echo(str("FLASH PORT: ", (drv_z1 + 1.2 < cav_z1)
         ? str("no wall to cut - the driver's USB-C sits inside the interior, ",
               "jack end at z ", drv_z1, ". Flash before assembly")
         : flash_port ? "OPEN through the long-axis +Z wall"
         : str("CLOSED - blind pocket to z ",H-flash_wall,", ",flash_wall,
               " skin left; jack reaches ",drv_z1+1.2)));
echo(str("RELIEFS: pocket relief R",pan_rel," | cavity relief R",cav_rel,
         " (cav_r ",cav_r,", limit 1.707 for a sharp PCB corner)",
         " | wall left at a cavity corner ",wall-cav_rel));
echo(str("HINGE: ", pivot_screw
         ? str(insert_size," clamp screw in through the disc rim, into an insert",
               " in the far slot wall | head seats ",head_seat," in from the slot",
               " wall, ",disc_rim_x-head_seat-slot_w/2," down a dia ",scr_head+0.8,
               " access channel | screw ",scr_reach," long, so ",insert_size," x ",
               floor(scr_reach/5)*5," with a wave washer under the head, ",
               floor(scr_reach/5)*5 - wash_t - (scr_reach-ins_l)," into the insert")
         : str("plain dia ",pin_d," pin, ",pin_fit," fit - see below")));
echo(str("HINGE SCREW FITS: ", clamp_ok ? "yes" : "NO",
         " | head ",scr_head," across needs disc_t, which is ",disc_t,
         " -> ",head_wall," a side | insert bore ",ins_d," -> ",ins_wall," a side",
         clamp_ok ? "" : str(" | BOTH ends of the screw are bounded by disc_t, so",
               " the adjustable clamp needs disc_t >= ",ceil(scr_head+0.8),
               ".  Running the plain dia ",pin_d," pin instead")));
echo(str("CLAMP TONGUE: ", (clamp_land && clamp_flex)
         ? str(flex_t," thick x ",disc_t," x ",flex_len," long, fixed both ends,",
               " loaded ",flex_z0," from one root -> ",flex_k," N/mm | at ",
               clamp_pr-2*leg_slot_c," of interference that is ",
               flex_k*(clamp_pr-2*leg_slot_c)," N, about ",
               2*0.35*flex_k*(clamp_pr-2*leg_slot_c)*2," N.mm of hinge torque",
               " vs ",0.35," N.mm of gravity on the leg | ",
               flex_k*(clamp_pr-2*leg_slot_c)*2*0.35*2/leg_len," N at the foot")
         : "none - the land bears on the bulk of the disc, so the fit is a lottery"));
echo(str("HINGE FRICTION: ", clamp_land
         ? str("clamp land - the slot is ",slot_w," but ",slot_w-clamp_pr,
               " over ",clamp_len," at the pivot, against a ",leg_w," leg, so ",
               clamp_pr-2*leg_slot_c," of interference and no free play. ",
               pivot_screw ? "The screw sets the rest."
                           : "PRINT-TUNE clamp_pr the way catch_p is tuned: it is the one number a drawing cannot give you.")
         : "NONE - the leg swings on whatever the print gave it"));
echo(str("SNAP DETENT: ", snap_det
         ? str("tooth on the DISC, pocket in the LEG - the inversion is what makes",
               " it possible while the leg still folds flush | engages at leg-local",
               " z ",det_at,", which is disc y ",det_fy," z ",det_fz,
               " - right at the stop wall | rides clear until 118.3 deg, so it only",
               " meets the leg in the last 3.7 | bridge ",det_span," x ",det_tt,
               " x ",det_h," -> ",det_k," N/mm | ",det_F," N at ",det_lift,
               " of lift, arm ",det_arm," -> ",det_T," N.mm of detent (",
               det_T/leg_len," N at the foot), ",det_sig," MPa at mid-span",
               " | with the clamp's ",2*0.35*flex_k*(clamp_pr-2*leg_slot_c)*2,
               " that is ",det_T + 2*0.35*flex_k*(clamp_pr-2*leg_slot_c)*2,
               " N.mm holding it open")
         : "not fitted - the leg holds on clamp friction alone"));
echo(str("DEPLOYED STOP: rear wall ",stop_wall," behind the pivot | the leg reaches",
         " that only at ",theta_dep," deg of swing (it is at 2.48 by 110), and past it",
         " the interference grows about 0.07 mm/deg | the heel flat's own stop is a",
         " tangency that saturates at 0.138, so this wall is what defines the lean"));
echo(str("LEG SWEEP: pivot axis ",piv_h," above the pocket floor, so nothing on the",
         " leg may orbit past that | hub rear cut back to ",hub_r,
         " (clearance ",sweep_clr,") over local ",sweep_a," to 270 deg",
         " | heel flat keeps its short side, ",
         hub_sweep ? "which is the hard stop at " : "UNCUT - the leg jams at ",
         hub_sweep ? stop_ang : 64, hub_sweep ? " deg" : " deg, 1.8 into the floor"));
echo(str("FASTENERS: ", insert_fit
         ? str(insert_size," heat-set inserts, bore dia ",ins_d," x ",ins_l+ins_relief,
               " deep into a ",scr_wall," mm end wall | ",insert_size,
               " countersunk screws, head ",scr_head,", cone ",scr_csk,
               " deep in a ",cover_t," cover")
         : str("self-tapping into a ",scr_pilot," pilot, ",scr_depth," deep")));
echo(str("REAR PORT: ", port_snap
         ? str("snap-in pigtail, opening ",snap_w+2*snap_c," x ",snap_h+2*snap_c,
               " (part ",snap_w," x ",snap_h,", clearance ",snap_c," a side), centred x ",
               ucb_x," z ",ucb_z," | needs ",snap_d," clear behind, has ",
               cov_in - (ucb_z < cav_z0 + 30 ? 0 : 0) - mod_back)
         : str("breakout board in rails, opening ",port_w," x ",port_h)));
echo(str("CARRIER MOUNT: four dia ",carrier_hole," holes at ",carrier_hx," x ",carrier_hz,
         " centres (",carrier_hx-carrier_hole," x ",carrier_hz-carrier_hole,
         " edge to edge), ",(carrier_w-carrier_hx)/2," in from each edge of the ",
         carrier_w," x ",carrier_h," board | pegs dia ",
         min(carrier_hole-carrier_peg, 2*carrier_pin)," on pads dia ",carrier_pad+2,
         " | first header pin is ",carrier_pin," from the hole, so nothing on the peg",
         " may exceed ",2*carrier_pin," across"));
echo(str("DRIVER MOUNT: ", carrier_fit
         ? str("carrier ",carrier_w," x ",carrier_h," on four pads, driver plugs into ",
               hdr_h," female headers | driver face to glass plane ",
               drv_back - drv_t - mod_back, " for parts standing ",drv_env-drv_t," proud")
         : "printed side rails"));
echo(str("CORNER POSTS: ",post_s," x ",post_s," from y ",post_y0," back to ",body_d,
         " | screws at x +/-",scr_cx,", z ",cav_z0+scr_cz," and ",cav_z1-scr_cz));
echo(str("GLASS GOES IN: interior x ",cav_x0," to ",cav_x1,", z ",cav_z0," to ",cav_z1,
         " | glass x ",glass_x0," to ",glass_x1,", z ",Zc-pan_h/2," to ",Zc+pan_h/2,
         " -> ", (cav_x0 <= glass_x0 && cav_x1 >= glass_x1 &&
                  cav_z0 <= Zc-pan_h/2 && cav_z1 >= Zc+pan_h/2)
                 ? "clears on every side, drops straight in" : "BLOCKED"));
echo(str("PERFBOARD: ", (bare_panel && perf_fit)
         ? str(perf_w," x ",perf_h," (",round(perf_w/2.54)," x ",round(perf_h/2.54),
               " holes at 2.54), centred x ",perf_cx,
               " z ",perf_cz," | band above the driver is ",cav_z1-drv_z1," tall")
         : "not fitted"));
echo(str("GLASS POCKET ",pan_w+2*pan_clr_w," x ",pan_h+2*pan_clr_h,
         "  (margin ",2*pan_clr_w," on the short axis, ",2*pan_clr_h,
         " on the long axis) | pocket relief R",pan_rel));
echo(str("charger ",chg_part," ",chg_w," x ",chg_h," x ",chg_t,
         " | fits proto: ", (chg_w <= proto_w-2 && chg_h <= proto_h-2) ? "yes" : "NO",
         " | clear in front: ", proto_face - chg_t + proto_t - mod_back));
if (mod_header) {
  echo(str("HEADER vs CELL: needs ",conn_h,", has ",cov_in_pk-bat_t-mod_back,
           " -> ", (conn_h > cov_in_pk-bat_t-mod_back)
                   ? str("CLASH by ",conn_h-(cov_in_pk-bat_t-mod_back)," mm")
                   : "clear"));
  echo(str("depth needed for a ",conn_h," mm header over the cell: ",
           conn_h + bat_t + mod_back + 5.95 + 0.5));
}

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
// Measured state of all 19, by volume:
//   10 genuinely empty | frame_cover + cover_board zero-volume touches (by design)
//   NO unintended interference.  The two that used to be real were both consequences
//   of hardware this build does not have: conn_cell (154 mm3) was a mated 8-pin
//   header, drv_module (1050 mm3) was that header's cable inflating drv_env to 15.
//   FOUR report geometry deliberately, and reading them as clashes wastes a day:
//     disc_legf  catch lip over the folded foot - the snap interference
//     disc_legd  clamp land against the deployed leg - the land is AT the pivot,
//                so it bears at every angle, this one included.  At theta_dep it
//                ALSO shows the leg on the slot's rear wall: that is the hard
//                stop bearing, not a clash.
//     disc_legs  the same land, at whatever angle chk_th asks for.  Reads 0.4
//                rather than the designed 0.2 because the check draws the leg
//                centred in its slot, while the land pushes it 0.2 onto the far
//                wall.  Read it as clamp_pr less one side of leg_slot_c.
//     frame_cover / cover_board  the zero-volume touches above
//     adapt_board  the FPC adapter on the carrier - 18 x 32 landing on it for
//                  31.25 of its length.  This one is a REAL conflict, not a
//                  by-design touch: the adapter has no home yet.  See TODO.
//     adapt_cover  zero-thickness - the adapter's back face is coplanar with
//                  the pocket face, which is where it wants to sit.
//   cover_legs is the one that must be empty, and empty at EVERY chk_th, not just
//   at 0 and theta_dep.  Both ends were clear while the middle was 1.8 mm inside
//   the cover; that is what the swept check exists to catch.
chk = "";
chk_th = theta_dep;
chk_d  = 3.2;                     // wall depth for the wall_leg probe               // sweep angle for the *_legs checks
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
// mid-travel sweep.  The two poses above are the ends of the stroke; chk_th lets
// the whole swing be walked, which is where a hub corner orbiting an axis only
// disc_t/2 off the pocket floor gets you into trouble.
// the detent tooth against the leg: empty early, ramp interference near the end,
// and empty again at theta_dep because the pocket has swallowed it
if(chk=="det_leg")      intersection(){ union(){ det_solid(); det_bridge(); }
                                        leg_placed(chk_th); }
if(chk=="adapt_board")  intersection(){ mock_adapter(); mock_board(); }
if(chk=="adapt_cover")  intersection(){ mock_adapter(); cover(); }
if(chk=="cover_legs")   intersection(){ cover(); leg_f(0,chk_th); }
if(chk=="disc_legs")    intersection(){ disc(); leg_placed(chk_th); }
// How far behind the pivot does the leg reach, while still inside the disc's
// thickness?  That is what decides whether the slot's rear wall can be a stop.
// chk_d = wall depth behind the pivot; non-empty means the leg touches it.
if(chk=="wall_leg")     intersection(){
    translate([-slot_w/2, 0, -200 - pivot_r - chk_d])
        cube([slot_w, disc_t, 200]);
    leg_placed(chk_th); }

// ------------------------------------------------- parameter dump for docs
if (part=="params") {
  vals = [
   ["W",W],["H",H],["depth",depth],["body_d",body_d],["front_t",front_t],
   ["cover_t",cover_t],["wall",wall],["corner_r",corner_r],["cav_r",cav_r],["cav_rel",cav_rel],["bt_h",bt_h],
   ["front_chf",front_chf],["rear_chf",rear_chf],["win_chf",win_chf],
   ["pcb_w",pcb_w],["pcb_h",pcb_h],["pcb_t",pcb_t],["pan_w",pan_w],["pan_h",pan_h],
   ["pan_t",pan_t],["pan_clr_w",pan_clr_w],["pan_clr_h",pan_clr_h],["rib_off",rib_off],["rib_cz",rib_cz],["rib_far",rib_far],["pan_r",pan_r],["pan_rel",pan_rel],
   ["mod_header",mod_header?1:0],["fpc_w",fpc_w],["fpc_off",fpc_off],["rib_w",rib_w],["rib_clr",rib_clr],["rib_dep",rib_dep],["wall_rib",wall_rib],
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
   ["slot_w",slot_w],["piv_h",piv_h],["hub_r",hub_r],["sweep_a",sweep_a],
   ["snap_det",snap_det?1:0],["det_at",det_at],["det_lift",det_lift],["det_span",det_span],
   ["det_tt",det_tt],["det_h",det_h],["det_w",det_w],["det_tooth",det_tooth],
   ["det_wall",det_wall],["det_gapf",det_gapf],
   ["det_zw1",det_zw1],["det_zw0",det_zw0],["det_zb1",det_zb1],["det_zb0",det_zb0],
   ["det_y0",det_y0],["det_y1",det_y1],["det_clr",det_clr],["det_fit",det_fit],
   ["det_k",det_k],["det_F",det_F],["det_T",det_T],["det_sig",det_sig],
   ["hub_sweep",hub_sweep?1:0],["sweep_clr",sweep_clr],["stop_wall",stop_wall],
   ["clamp_land",clamp_land?1:0],["clamp_pr",clamp_pr],["clamp_len",clamp_len],
   ["head_seat",head_seat],["wash_t",wash_t],["seat_x",seat_x],
   ["disc_rim_x",disc_rim_x],["scr_reach",scr_reach],
   ["clamp_flex",clamp_flex?1:0],["flex_t",flex_t],["flex_gap",flex_gap],
   ["flex_z0",flex_z0],["flex_z1",flex_z1],["flex_len",flex_len],["flex_k",flex_k],
   ["head_wall",head_wall],["ins_wall",ins_wall],["clamp_ok",clamp_ok?1:0],
   ["bat_w",bat_w],["bat_h",bat_h],["bat_t",bat_t],["bat_x0",bat_x0],
   ["bat_cx",bat_cx],["bat_cz",bat_cz],["bat_clr",bat_clr],["bat_fence",bat_fence],["pad_w0",pad_w[0]],["pad_w1",pad_w[1]],["pad_h",pad_h],
   ["pad_x0",pad_x[0]],["pad_x1",pad_x[1]],["pad_z0",pad_z[0]],["pad_z1",pad_z[1]],
   ["proto_w",proto_w],["proto_h",proto_h],["proto_t",proto_t],["proto_x0",proto_x0],
   ["proto_x1",proto_x1],["proto_cx",proto_cx],["proto_cz",proto_cz],
   ["proto_z0",proto_z0],["proto_z1",proto_z1],["proto_back",proto_back],["proto_face",proto_face],
   ["proto_hole_sp",proto_hole_sp],
   ["drv_env",drv_env],["drv_stack",drv_stack],
   ["rib_tail",rib_tail],["rib_leg3",rib_leg3],["rib_reach",rib_reach],
   ["adapt_fit",adapt_fit?1:0],["adapt_w",adapt_w],["adapt_h",adapt_h],
   ["adapt_t",adapt_t],["adapt_env",adapt_env],["adapt_hole",adapt_hole],
   ["adapt_inset",adapt_inset],["adapt_cx",adapt_cx],["adapt_cz",adapt_cz],
   ["adapt_x0",adapt_x0],["adapt_x1",adapt_x1],["adapt_z0",adapt_z0],["adapt_z1",adapt_z1],
   ["adapt_gap",adapt_gap],["adapt_foul",adapt_foul],["adapt_clear",adapt_clear],["drv_w",drv_w],["drv_h",drv_h],["drv_t",drv_t],["drv_x0",drv_x0],["drv_x1",drv_x1],
   ["drv_cx",drv_cx],["drv_cz",drv_cz],["drv_z0",drv_z0],["drv_z1",drv_z1],
   ["drv_back",drv_back],["drv_clr",drv_clr],["drv_rail",drv_rail],
   ["ucb_x",ucb_x],["ucb_z",ucb_z],["ucb_w",ucb_w],["ucb_l",ucb_l],["ucb_t",ucb_t],
   ["port_w",port_w],["port_h",port_h],
   ["chg_part",chg_part],["chg_w",chg_w],["chg_h",chg_h],["chg_t",chg_t],["chg_z",chg_z],["chg_x",proto_x0+chg_w/2+1],
["flash_port",flash_port?1:0],["flash_wall",flash_wall],["flash_x",flash_x],["flash_y0",flash_y0],["flash_y1",flash_y1],["usb_w",usb_w],
   ["bare_panel",bare_panel?1:0],["perf_fit",perf_fit?1:0],["perf_w",perf_w],["perf_h",perf_h],
   ["perf_cx",perf_cx],["perf_cz",perf_cz],["perf_t",perf_t],
   ["carrier_fit",carrier_fit?1:0],["carrier_w",carrier_w],["carrier_h",carrier_h],
   ["carrier_hole",carrier_hole],["carrier_hx",carrier_hx],["carrier_hz",carrier_hz],
   ["carrier_peg",carrier_peg],["carrier_pin",carrier_pin],
   ["carrier_cx",carrier_cx],["carrier_cz",carrier_cz],["carrier_z0",carrier_z0],["carrier_z1",carrier_z1],
   ["catch_p",catch_p],["pin_fit",pin_fit],["snap_c",snap_c],
   ["pivot_screw",pivot_screw?1:0],["leg_slot_c",leg_slot_c],["scr_wall",scr_wall],["carrier_t",carrier_t],["hdr_h",hdr_h],
   ["port_snap",port_snap?1:0],["snap_w",snap_w],["snap_h",snap_h],["snap_d",snap_d],
   ["post_s",post_s],["post_y0",post_y0],
   ["insert_fit",insert_fit?1:0],["ins_d",ins_d],["ins_l",ins_l],["scr_csk",scr_csk],["cav_cx",cav_cx],["scr_cx",scr_cx],["scr_cz",scr_cz],
   ["chg_x_c",chg_x_c],["chg_back",chg_back],["fpc_z",fpc_z],["ledge_end",ledge_end],
   ["tape_r",tape_r],["tape_at",tape_at],["lgt_w",lgt_w],["lgt_y0",lgt_y0],
   ["elec_clr",elec_clr],["col_gap",col_gap],["end_wall",end_wall],["side_wall",side_wall],
   ["scr_x",scr_x],["scr_z0",scr_z[0]],["scr_z1",scr_z[1]],["scr_z2",scr_z[2]],
   ["scr_pilot",scr_pilot],["scr_free",scr_free],["scr_head",scr_head],
   ["rib_t",rib_t],["rib_inset",rib_inset],["rib_pad",rib_pad],["rib_gap",rib_gap],
   ["conn_h",conn_h],["conn_w",conn_w],["conn_l",conn_l],["conn_x",conn_x],["conn_z",conn_z],["btn_n",btn_n],["btn_d",btn_d],["btn_sp",btn_sp]
  ];
  for (v = vals) echo(str("P|", v[0], "|", v[1]));
}
