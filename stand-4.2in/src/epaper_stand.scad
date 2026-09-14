// =====================================================================
//  4.2" e-Paper desk frame  -  "minimal bezel + snap-out kickstand"
//  Waveshare 4.2inch e-Paper Module (B) + e-Paper ESP32 Driver Board
//
//  Frame  : bezel = the panel's own dead border + ~2 mm plastic
//  Cover  : full back, carries the driver board + the stand recess
//  Leg    : the ONLY moving part.  Folds flush into the recess, swings out
//           dep_ang onto a flat on its heel.  Portrait only.
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
//  FRAME front shell | COVER back | LEG kickstand |
//  BEZEL TEST TILE  the front-face-only print for checking fit before the frame
// =====================================================================

/* [What to build] */
// frame | cover | leg | bezel_test | plate | standing | folded | assembly | exploded | guts
part = "standing";

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
// ---- the charger's four standoffs.  They are SCREW POSTS: an M2 heat-set
// insert goes into each, so the post's height is DERIVED from the insert it has
// to swallow plus the skin left behind it - see chg_stand.  The pads they
// replaced stood 0.5 proud of the register face, which is nothing to melt into.
chg_ins_d   = 2.9;    // bore for a 3.2 x 4.0 M2 insert: under the OD, so the
                      //   knurl has wall to bite.  MEASURE YOURS
chg_ins_l   = 4.0;    // ... its length
chg_ins_rel = 1.0;    // extra bore past it, for the plastic the insert displaces
chg_skin    = 1.2;    // back-face skin left behind the bore.  The bore is blind:
                      //   the back face carries no opening for the charger
chg_boss_d  = 6.5;    // post diameter -> 1.8 of wall around the bore
// ASSUMED, like adapt_hole: 3.5 in from each edge of the board.  MEASURE THE
// ACTUAL BREAKOUT - inserts are unforgiving about hole spacing in a way that
// foam tape was not.
chg_hx = chg_w - 7.0;   // insert centres, across the short axis
chg_hz = chg_h - 7.0;   // ... and along the long axis
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
// A glass rib low enough to cross the stand pocket is drawn as TWO segments,
// outboard of it.  Run straight through, the pocket cuts its ROOT away and
// leaves a 20 x 3.5 x 20.7 wall cantilevered off one end - and it is the wall
// that holds the glass down.  chk="rib_recess" is the guard.
rib_pocket_c = 1.0;   // material left between the pocket wall and a segment
rib_seg      = 15.0;  // segment length, each side

/* [Kickstand] */
// THE STAND IS A LEVER, and that is the whole design.  What came before was a leg
// The leg swings dep_ang, and past the pin it carries a HEEL whose flat
// face is coplanar with the recess floor at exactly that angle.  Deployed, the
// display's weight pushes the leg further open, the heel's flat lands on the floor,
// and the load runs leg -> heel -> cover in COMPRESSION.  That is what holds the
// display up; it is not friction and it is not a spring.  (Prior art for the same
// stop: US4515338A, "flat stop faces ... at an obtuse angle equal to the desired
// open angle plus 90 deg".)
//
// dep_ang IS UNDER 90 DEG ON PURPOSE.  The heel lands ON the floor plane only while
// the swing stays inside a right angle; past 90 it would rotate through the plane
// instead, and the deepest point of its arc would be inside the cover.
//
// THE LEG SWINGS FREE between the two poses.  There is no detent: the stop is what
// makes the deployed pose, gravity and the display's weight are what hold the leg
// in it, and the pocket floor is left flat and unbroken - one seat, one arc track
// and two nubs less to print and tune.
//
// PORTRAIT ONLY, which is what lets the leg run straight down the centreline - and
// that is what clears the corner screws by 32.4 and misses the driver carrier.
dep_ang  = 35.0;    // swing from folded.  The stance knob.
leg_len  = 55.0;    // pivot to foot tip
foot_z   = 3.0;     // where the folded foot tip stops.  MUST clear rear_chf (2.0)
                    //   or the leg hangs over the bottom edge of the frame.
leg_t    = 4.0;     // thickness at the pivot.  Sets piv_y: the pin sits leg_t/2
                    //   below the back face so the folded leg is FLUSH.
leg_tf   = 1.0;     // thickness at the tip.  The taper is ONE-SIDED - the back face
                    //   stays flush and the front face rises - so the thin end fits
                    //   the shallow recess without standing proud.
foot_r   = 4.0;     // foot corner radius, in plan
heel_z   = 4.0;     // how far the heel reaches past the pin.  Longer = more flat to
                    //   bear on, but it must stay inside rec_top through the sweep.
pin_d    = 2.0;     // pin, snapped into sockets on ears inside the pocket
pin_fit  = 0.10;    // ... and its clearance: a running fit, on the leg's bore and
                    //   on the sockets alike
rec_dep  = 4.5;     // recess depth below the back face
rec_shl  = 1.4;     // ... where solid frame is behind it (below cav_z0), where a
                    //   deep recess would leave no floor at all
// rec_w IS THE PIN LENGTH.  The pin spans the pocket exactly: it passes through
// both ears and its ends finish flush with the pocket's side walls, so the walls
// themselves cap it and nothing else has to retain it axially.  20 also happens to
// be half of a stock 40 mm rod.
rec_w    = 18.0;
rec_clr  = 0.5;     // clearance between the leg and each EAR
rec_wall = 1.5;     // wall left outboard of the pocket in the boss below.  Bounded
                    //   by the driver carrier at x -11.45: the boss reaches +/-10.5,
                    //   clearing it by 0.95.
rec_floor= 1.8;     // THE POCKET'S FLOOR, and it has to be built: see recess_boss().
                    //   The cover's own register is only cover_t+reg_step thick, and
                    //   the pocket is rec_dep deep, so the cut goes clean through it.
                    //   What used to stop that was the battery platform happening to
                    //   sit behind part of the pocket - and between the shallow step
                    //   and the platform's start there was a 7.75 mm band of pure
                    //   hole.  Sets rec_back, and so the depth the boards get across
                    //   the pocket band.
// FINGER ACCESS comes free now.  The ears are only ear_len long, so away from the
// pivot the leg sits in the full rec_w with (rec_w - leg_w)/2 open either side of
// it, the whole length, at the full pocket depth.  There is no separate notch band
// - and it was that band, sharing z 9.5..17.5 with the bottom glass rib and with
// the old port position, that undercut the rib and crowded the port.
// THE SOCKETS LIVE ON EARS INSIDE THE POCKET, not bored through its side walls.
// Bored outward they had to be reached from outside, which broke the back face into
// two more openings; on ears the C-mouth opens into the pocket, and the pocket is
// blind, so the back face stays unbroken.
ear_w    = 2.0;     // ear thickness, inboard from each pocket wall.  With rec_w and
                    //   rec_clr this sets leg_w: rec_w - 2*(ear_w + rec_clr).
ear_mouth= 0.72;    // socket mouth, as a fraction of the bore.  Under 1.0 so the
                    //   pin snaps past it and is then retained.
ear_len  = 8.0;     // ear length along the long axis, centred on the pin
pk_floor_t_legacy = 1.8;   // (retired: the old pocket floor)

/* [Driver carrier] */
// The Waveshare board has no mounting holes, but it does have its two 19-pin
// male headers soldered on.  So it plugs into female headers on a carrier
// perfboard, and the carrier is what gets held down.  Any double-sided 0.1"
// prototype board does; this is sized for a 30 x 70 cut, which leaves ~14 mm of
// spare board below the driver for the battery divider.
carrier_fit = true;
carrier_w = 30.0; carrier_h = 70.0; carrier_t = 1.6;
hdr_h = 8.5;        // female header body: driver's underside to the carrier face
// THE BOARD STANDS OFF THE COVER.  The female headers are soldered from the far
// side, so clipped pin tails and their solder fillets stand proud of the face
// that lands on the cover.  carrier_lift is the air left under the board for
// them; the pad carries the board and the peg carries on through its hole.
// It is spent out of the driver column's depth budget - see DEPTH BUDGET.
carrier_lift = 2.5; // air under the board, for the solder joints
carrier_pad = 4.0;  // standoff pad diameter under each carrier corner.  Bounded
                    //   by the same keep-out as the peg: 2*carrier_pin
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
cov_in    = depth - cover_t;
// rec_y0 is the recess floor; elec_back is the rearmost plane the boards may reach.
rec_y0    = depth - rec_dep;           // recess floor
rec_shl_y = depth - rec_shl;           // ... where solid frame is behind it
// The recess only runs down the CENTRELINE (x +/-rec_w/2), and the carrier sits at
// x -41.45..-11.45, so the carrier misses it entirely and datums to elec_back.
// Only things that actually cross the recess band see rec_back, and the cell is
// the one that does - which is why it keeps its platform.
rec_back  = rec_y0 - rec_floor;        // the boss plane, where the recess runs
// cov_in is the SKIN datum, not the cover's inner face.  cover() lays a register
// prism cover_t+reg_step thick starting at body_d-reg_step across the whole cavity
// footprint, so the face anything inside actually lands on is reg_step further
// forward.  Datuming the boards to cov_in buried the carrier 2106 mm3 deep in it.
reg_step  = 1.0;
elec_back = cov_in - reg_step;         // ... everywhere else: the register face
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
carrier_back = elec_back - carrier_lift;          // on its four pads
carrier_face = carrier_back - carrier_t;
// THE ROOM THE DRIVER COLUMN HAS: from the glass plane back to the face the
// carrier lands on.  carrier_lift is spent out of it, so it is this and not
// elec_back - mod_back that drv_stack has to fit inside.
drv_room = (carrier_fit ? carrier_back : elec_back) - mod_back;
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
drv_back = carrier_fit ? carrier_face - hdr_h : elec_back - 0.5;
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
perf_back = elec_back - 0.5;
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
// The post height is not chosen, it is what is left once the insert bore and the
// skin behind it have been taken out of the depth: bore from the board's seat
// toward the back face, stop chg_skin short of it, and chg_back is wherever that
// puts the seat.
chg_bore  = chg_ins_l + chg_ins_rel;          // blind bore depth
chg_back  = depth - chg_skin - chg_bore;      // the face the charger lands on
chg_stand = elec_back - chg_back;             // ... how far that is off the register
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
// The charge port sits at the TOP of the interior, immediately left of the charger.
// Two reasons, and the structural one is the important one:
//
//   OPENINGS IN THE BACK FACE MUST NOT CROWD EACH OTHER.  Low down it shared a band
//   with the stand recess and the finger-notch band that used to widen it, leaving
//   barely 4 mm of rib between two openings in the same 8 mm strip.  Up here the
//   nearest opening is 27 mm away.
//
//   And the charger is right there, so the two wires no longer cross the whole
//   interior - it lands in the one large region nothing else was using.
//
// PORT CLEARANCES is echoed on every run: it measures the distance from this
// opening to every other opening in the back face, so crowding shows up as a
// number rather than being noticed on a print.
ucb_x = bare_panel ?  -5.0 : -34.4;               // port centre on the back
ucb_z = bare_panel ?  92.0 : 11.0;
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
// ---- the stand.  Everything here is DERIVED: piv_y from leg_t (flushness),
// piv_z from leg_len and foot_z, the heel's flat from dep_ang, the lean from all of
// them.  A parameter in this file has already drifted from what it was meant to
// equal (rib_off), so nothing about the stand is typed twice.
piv_z    = leg_len + foot_z;           // pin, up from the bottom edge
piv_y    = depth - leg_t/2;            // ... and its depth: FLUSH folded leg
piv_h    = piv_y - rec_y0;             // pin above the recess floor (= rec_dep-leg_t/2)
// THE BOSS HAS TO OVERRUN THE DEEP POCKET AT BOTH ENDS.  An end wall needs
// material behind it exactly as a floor does, and the pocket's two end walls are
// the ones easy to forget: they face along z, not along y, so a check that probes
// "behind the floor" never sees them.
//
// boss_z0 is as low as the boss may go - below it the frame's solid end wall is
// behind the cover and a boss would drive into it.  So the DEEP section starts
// rec_floor above that, and the boss runs rec_floor past rec_top at the other end.
// Start them on the same plane, as they were, and the deep pocket's lower end wall
// is a rec_w x (elec_back - rec_y0) hole straight into the electronics bay.
boss_z0  = cav_z0 + 0.5;               // the boss starts where the interior does
shl_z0   = boss_z0 + rec_floor;        // where the recess steps to rec_shl
tap_z    = shl_z0 + 7.5;                // ... so the taper must be FINISHED by
                                        //   shl_z0, not merely started: the leg
                                        //   was 2.04 into the shallow floor when
                                        //   the taper ran all the way to the tip.
// The heel's flat stop.  In leg-local coords it is the plane a distance piv_h from
// the pin whose normal has been rotated by dep_ang - i.e. the recess floor, pulled
// back through the deployed rotation.  Nothing else needs to be said about it: the
// cut in leg_shape() is that sentence in geometry.
rec_top  = piv_z + heel_z + 1.5;       // recess, top end: clears the heel's sweep
boss_z1  = rec_top + rec_floor;        // ... and the boss overruns it by a floor
rec_z0   = foot_z - rec_clr;           // ... and its bottom end: the folded foot
                                       //   tip stops at foot_z, so this is rec_clr
                                       //   below it and no lower.  Every mm further
                                       //   down is a mm nearer the rear chamfer -
                                       //   see reg_ext_z0.
// THE POCKET'S FLOOR PLATE MUST DIE IN SOLID FRAME.  It is a plug: the cover
// carries it and the frame is relieved reg_fit larger to receive it, so there is a
// reg_fit gap all round it.  Run it down to the bottom edge and that gap comes out
// through the REAR CHAMFER, which has already taken chf_bite off both parts' back
// faces there - and the gap then leads straight into the frame's hollow end wall.
// So the plate stops chf_bite + margin short, and the frame closes its end.
chf_bite   = rear_chf - cover_t;       // what the chamfer takes off the frame's
                                       //   back face at the bottom edge
reg_fit    = 0.15;                     // the plate's clearance in its relief
reg_ext_z0 = rec_z0 - 0.6;             // the plate's bottom end
stand_reg_w = rec_w + 2*rec_wall;      // ... and its width: the pocket plus its walls
reg_seal   = (reg_ext_z0 - reg_fit) - chf_bite;   // frame left below the relief
leg_w    = rec_w - 2*(ear_w + rec_clr);   // the leg fits BETWEEN the ears
pin_len  = rec_w;                      // ... and the pin spans the whole pocket
ear_x0   = rec_w/2 - ear_w;            // ear inner face
finger_g = (rec_w - leg_w)/2;          // open either side of the leg, off the ears
// stance, by the same maths standing() uses: py is the contact edge
py_edge  = depth - rear_chf;
foot_zd  = piv_z - leg_len*cos(dep_ang);          // deployed foot, up from the edge
foot_yd  = piv_y + leg_len*sin(dep_ang);          // ... and its depth
lean     = atan2(foot_zd, foot_yd - py_edge);
footprint= (foot_yd - py_edge)*cos(lean) + foot_zd*sin(lean);
stand_ok = foot_z >= rear_chf + 0.5;   // nothing may overhang the bottom edge

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
        stand_register(reg_fit);   // ... and its local extension down the pocket
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
// ONLY THE TOP END IS HOLLOWED.  The bottom end wall is the one the stand pocket
// lies against, and the pocket's floor there is the cover's 1.0 mm register plate -
// an OUTSIDE surface.  That end stays solid, so the leg's pocket is a blind hollow
// in a solid block with nothing behind it to get into.  It costs lgt_gain of
// filament and it is worth every gram of it.
module lightening(){
    if (bare_panel) {
        z0 = cav_z1 + 2.0;
        z1 = H - 2.5;
        if (z1 - z0 > 3.0)
            translate([cav_cx, lgt_y0, (z0+z1)/2]) xzext(body_d - lgt_y0 + 0.1)
                rrect(lgt_w, z1 - z0, 1.5);
    } }
// what leaving the bottom end solid costs, for the record
lgt_gain = lgt_w * (cav_z0 - 2.0 - 2.5) * (body_d - lgt_y0) / 1000;   // cm3

// ================================================================= cover
// The cover's register plate stops at the cavity's footprint (z 8.15 up), but the
// stand pocket runs below that, and down there the cover is nothing but its
// cover_t skin - which a rec_shl-deep pocket removes entirely.  So the register is
// extended locally, over the pocket's footprint only, and the frame is relieved to
// match.  Called with extra>0 it grows, which is how the frame's relief is made
// slightly larger than the plate that has to enter it.
module stand_register(extra = 0){
    translate([-(stand_reg_w/2 + extra), body_d - reg_step - extra, reg_ext_z0 - extra])
        cube([stand_reg_w + 2*extra,
              reg_step + 2*extra,
              (boss_z0 + 0.05) - reg_ext_z0 + extra]);
}

// THE SOLID THE POCKET IS BORED INTO.  Without this the pocket is not a pocket:
// the cover's own skin plus register is 2.4 thick and the pocket is rec_dep = 4.5
// deep, so the cut passes straight through into the interior wherever nothing else
// happens to be behind it.
//
// It runs the whole DEEP length, so the floor is rec_floor everywhere rather than
// only where the battery platform happens to reach.  chk="rec_floor_gap" is the
// guard, and it tests each band at its own floor depth.
module recess_boss(){
    // Only where the INTERIOR is behind the cover.  Below shl_z0 there is solid
    // frame back there, so a boss would drive straight into it - and it is not
    // wanted anyway: the pocket steps to rec_shl there, which the register alone
    // already floors.
    translate([-(rec_w/2 + rec_wall), rec_back, boss_z0])
        cube([rec_w + 2*rec_wall, depth - rec_back, boss_z1 - boss_z0]);
}

// The ribs that press the glass forward onto the front lip.  Nothing else holds
// it back: the interior has to be open behind the glass or the glass could not get
// in.  So these are structural, and their ROOT is what makes them work.
//
// A rib low enough to cross the stand pocket is split into two segments outboard of
// it.  Drawn straight through, the pocket takes its root out over the pocket's full
// width and leaves the middle cantilevered off one end.
module glass_ribs(){
    for (i = [0,1])
        if (bare_panel && pad_z[i] < rec_top + pad_h)
            for (sx = [-1,1])
                translate([sx*(rec_w/2 + rib_pocket_c + rib_seg/2),
                           mod_back+rib_gap, pad_z[i]])
                    xzext(cov_in-mod_back-rib_gap)
                        square([rib_seg, pad_h], center=true);
        else
            translate([pad_x[i], mod_back+rib_gap, pad_z[i]])
                xzext(cov_in-mod_back-rib_gap)
                    square([pad_w[i], bare_panel ? pad_h : 22.0], center=true);
}

module cover(){
  difference(){
   union(){
    difference(){
        union(){
            prism(cav_w+1.7, cav_h+1.7, cav_r+1.0, cover_t+reg_step, cav_cx, Zc,
                  body_d-reg_step);
            outer(cover_t, body_d);
            recess_boss();
            stand_register();
            glass_ribs();

            // ---- driver carrier.  The
            // driver itself is not held by the case at all - it plugs into
            // female headers on the carrier and the carrier is what is held.
            // Each corner is a PAD carrying a PEG: the pad holds the board
            // carrier_lift off the register face, which is the air the header
            // solder joints on its underside need, and the peg carries on
            // through the hole to locate it.  Both are kept under 2*carrier_pin
            // across so neither can foul the first header pin row.
            if (carrier_fit)
                for(sx=[-1,1],sz=[-1,1])
                    translate([carrier_cx+sx*carrier_hx/2, elec_back,
                               carrier_cz+sz*carrier_hz/2]) rotate([90,0,0]) {
                        cylinder(d=min(carrier_pad, 2*carrier_pin), h=carrier_lift);
                        cylinder(d=min(carrier_hole-carrier_peg, 2*carrier_pin),
                                 h=carrier_lift+carrier_t+1.2); }
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
            // ---- charger breakout: four screw posts, each deep enough to
            //      swallow an M2 heat-set insert and still leave chg_skin of
            //      back face behind it.
            for(sx=[-1,1],sz=[-1,1])
                translate([chg_x_c+sx*chg_hx/2, cov_in, chg_z+sz*chg_hz/2])
                    rotate([90,0,0]) cylinder(d=chg_boss_d, h=cov_in-chg_back);
            // ---- battery platform + fence.  The cell spans x -7.65..36.35 and the
            // leg recess runs x -8..8, so the cell DOES cross the recess band and
            // would otherwise straddle its step.
            // So the platform stays, re-datumed to rec_back.
            translate([bat_cx, rec_back, bat_cz]) xzext(cov_in-rec_back+0.01)
                square([bat_w+2*bat_clr+2*bat_fence, bat_h+2*bat_clr],center=true);
            for(sx=[-1,1])
                translate([bat_cx+sx*(bat_w/2+bat_clr+bat_fence/2), rec_back-bat_t, bat_cz])
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

        // the insert bores, drilled from the seat toward the back face.  Blind:
        // chg_skin of skin is left, so the back face stays unbroken.
        for(sx=[-1,1],sz=[-1,1])
            translate([chg_x_c+sx*chg_hx/2, chg_back - 0.01, chg_z+sz*chg_hz/2])
                rotate([-90,0,0]) cylinder(d=chg_ins_d, h=chg_bore + 0.01);
        recess_cut();
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
    }
    // The ears live INSIDE the pocket, so they go back on after it is cut - the
    // same reason frame()'s corner posts are added after the cavity.
    piv_ears();
   }
   piv_sockets();
  } }

// ===================================================== the stand: recess + leg
// The recess is drawn in COVER/WORLD coords - x across, z up the long axis, y the
// depth with y = depth at the back face.  The leg is drawn leg-local with the pin
// at the origin, so leg_placed() is the whole transform: there is no second offset
// to get wrong, which is how the old leg_placed's translate went unnoticed.
//
// SIGN, because it was wrong once and every angle collided: the leg opens by
// rotate([+theta]).  A point at leg-local (0,0,-leg_len) - the foot - goes to
// y = +leg_len*sin(theta), i.e. OUT of the back face.  rotate([-theta]) swings it
// the other way, into the cover, which is a collision at every angle including
// the two end poses that a two-pose check would call clean.

// The recess the leg folds into: the pocket, the pin sockets, the detent track and
// seat, less the latch lip.  Deep where the interior is behind it; stepped SHALLOW
// below cav_z0, because there the cover is backed by solid frame and a deep pocket
// would leave no floor.  That step is the only reason the leg tapers.
// NOTHING BRIDGES ITS MOUTH and nothing is cut into its floor.  The pocket is a
// plain blind hollow: two steps in depth, two ears at the pivot, and that is all.
module recess_cut(){
    union(){
            // deep section - it starts rec_floor ABOVE the boss, so its lower
            // end wall has boss behind it
            translate([-rec_w/2, rec_y0, shl_z0])
                cube([rec_w, rec_dep + 0.02, rec_top - shl_z0]);
            // shallow section, over the frame's solid end wall
            translate([-rec_w/2, rec_shl_y, rec_z0])
                cube([rec_w, rec_shl + 0.02, shl_z0 - rec_z0]);
    }
}

// The pivot ears: two blocks standing INSIDE the pocket, inboard of its side
// walls, from the pocket floor up to the back face.  They carry the pin sockets.
//
// This is what keeps the back face unbroken.  Bored straight outward into the
// pocket's walls instead, a socket can only be reached from OUTSIDE the part, so
// its snap mouth has to break the back face - two more openings in a face that
// should have none.  On an ear the mouth opens into the pocket, and the pocket is
// a blind pocket, so the whole hinge is enclosed by the cover.
//
// They also set the leg's width, and the gap either side of it away from the pivot
// is the finger access.
module piv_ears(){
    for (sx = [-1, 1])
        translate([sx*ear_x0 - (sx < 0 ? ear_w : 0), rec_y0, piv_z - ear_len/2])
            cube([ear_w, rec_dep, ear_len]);
}

// ... and the C-socket through each of them.  Bore, plus a MOUTH narrower than the
// bore opening toward the back face: the pin presses past the lip and is retained.
// Cut AFTER the ears are unioned on, or the pocket cut would take the ears away
// and this would bore fresh air.
module piv_sockets(){
    bore = pin_d + pin_fit;
    for (sx = [-1, 1]) {
        translate([sx*(rec_w/2 + 0.1), piv_y, piv_z]) rotate([0, sx*-90, 0])
            cylinder(d=bore, h=ear_w + 0.2, $fn=48);
        translate([sx*ear_x0 - (sx < 0 ? ear_w : 0) - 0.05,
                   piv_y - bore*ear_mouth/2, piv_z - bore*ear_mouth/2])
            cube([ear_w + 0.1, depth - piv_y + bore, bore*ear_mouth]);
    }
}

// ---------------------------------------------------------------------- the leg
// leg-local: pin at the origin, body along -Z toward the foot, thickness in Y,
// width in X.  At theta = 0 this frame IS the world frame, so -Y is toward the
// recess floor and -Z is toward the bottom edge of the frame.
// The leg's plan outline: the body is drawn oversize in x and trimmed by this, so
// every side face on the leg is the same surface and the union merges cleanly
// instead of leaving three surfaces on one edge (invisible to every clash check).
module leg_plan(){
    translate([0, 50, 0]) rotate([90,0,0]) linear_extrude(100) hull(){
        translate([-leg_w/2, 0]) square([leg_w, heel_z + 1]);
        translate([-leg_w/2 + foot_r, -leg_len + foot_r]) circle(r=foot_r);
        translate([ leg_w/2 - foot_r, -leg_len + foot_r]) circle(r=foot_r);
    }
}

module leg_shape(){
    difference(){
        union(){
            difference(){
                intersection(){
                    union(){
                        // body: constant leg_t to tap_z, then a ONE-SIDED taper -
                        // back face flush, front face rising - to leg_tf at the tip.
                        // TWO hulls, not one: a single hull over four cross-sections
                        // takes the CONVEX shortcut straight past the third, and the
                        // front face then ran 2.04 into the shallow floor.
                        hull(){
                            translate([-leg_w/2, -leg_t/2, 0.01])
                                cube([leg_w, leg_t, 0.02]);
                            translate([-leg_w/2, -leg_t/2, -(piv_z - tap_z)])
                                cube([leg_w, leg_t, 0.02]);
                            translate([-leg_w/2, leg_t/2 - leg_tf, -(piv_z - shl_z0)])
                                cube([leg_w, leg_tf, 0.02]);
                        }
                        translate([-leg_w/2, leg_t/2 - leg_tf, -leg_len])
                            cube([leg_w, leg_tf, leg_len - (piv_z - shl_z0)]);
                        // the heel, past the pin
                        translate([-leg_w/2, -leg_t/2, 0])
                            cube([leg_w, leg_t, heel_z]);
                    }
                    leg_plan();
                }
                // THE STOP: the recess floor, pulled back through the deployed
                // rotation.  What is left of the heel is a flat that lands on that
                // floor at exactly dep_ang - a face, not a tangent corner.
                rotate([-dep_ang, 0, 0])
                    translate([-leg_w, -50 - piv_h, -50]) cube([2*leg_w, 50, 100]);
            }
        }
        // the pin bore
        translate([-leg_w, 0, 0]) rotate([0,90,0])
            cylinder(d=pin_d + pin_fit, h=2*leg_w);
        // (no relief is cut in the tip: at leg_tf it is too thin to take one.
        //  What starts the leg is the nail dish in the COVER - see recess_cut.)
    }
}

// theta = 0 folded, dep_ang deployed.  +theta swings the foot OUT - see the note
// at the top of this section.
module leg_placed(theta){
    translate([0, piv_y, piv_z]) rotate([theta, 0, 0]) leg_shape(); }

module leg(){ rotate([90,0,0]) leg_shape(); }

module mock_adapter(){
    if (adapt_fit)
        color("#3f7f3f") translate([adapt_cx, mod_back, adapt_cz])
            xzext(adapt_env) square([adapt_w, adapt_h], center=true);
}

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
    color("#3b3b46") translate([bat_cx, rec_back-bat_t, bat_cz])
        xzext(bat_t) rrect(bat_w, bat_h, 2); }
module mock_pcbs(){
    translate([drv_cx, drv_back-drv_t, drv_cz]) xzext(drv_t) square([drv_w,drv_h],center=true);
    if (!bare_panel)
        translate([proto_cx, proto_face, proto_cz]) xzext(proto_t) square([proto_w,proto_h],center=true);
    translate([bare_panel ? chg_x_c : proto_x0+chg_w/2+1,
               bare_panel ? chg_back-chg_t : proto_face-chg_t+proto_t, chg_z])
        xzext(bare_panel ? chg_t : chg_t-proto_t) square([chg_w,chg_h],center=true); }

// ============================================================== assembly
module stand(theta=0){ color("#2e3138") leg_placed(theta); }

module device(theta=0){
    color("#4c4f57") frame();
    color("#54575f") cover();
    mock_module(); mock_board();
    stand(theta); }

// The lean and footprint are DERIVED at the top level now, so this consumes them
// rather than re-deriving them.  tools/mkrenders.scad and mkdrawings.py used to
// carry their own copies of this arithmetic; they read the derived values instead.
module standing(){
    com = -(py_edge - 11.0)*cos(lean) + Zc*sin(lean);   // centre of mass estimate
    echo(str("STANCE: lean ",lean," deg | footprint ",footprint,
             " mm | CoM ",com," mm behind the contact edge | foot tip folded at z ",
             foot_z,", chamfer ends at ",rear_chf," -> ",
             stand_ok ? "nothing overhangs" : "OVERHANGS THE BOTTOM EDGE"));
    translate([0,0,py_edge*sin(lean)])
    rotate([-lean,0,0]) device(dep_ang);
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
else if (part=="leg")     leg();
else if (part=="standing") standing();
else if (part=="exploded"){
    frame(); translate([0,14,0]) cover(); translate([0,34,0]) leg(); }
else if (part=="plate"){
    translate([-60,H,0]) rotate([90,0,0]) frame();
    translate([60,0,depth]) rotate([-90,0,0]) cover();
    translate([0,-70,0]) leg(); }
else if (part=="assembly") device(dep_ang);
else if (part=="folded") device(0);
else if (part=="guts"){ color("#5a5e67") cover(); mock_board(); mock_adapter(); }

echo(str("OUTER: short axis ",W," | long axis ",H," | depth ",depth));
echo(str("BEZEL: short-axis sides ",W/2-win_w/2,"  long-axis ends ",H/2-win_h/2,
         " | white shown: short ",white_show_short," long ",white_show_long));
echo(str("walls: +X ",W/2-cav_x1,"  -X ",W/2+cav_x0,
         " | end walls ",cav_z0," / ",H-cav_z1));
echo(str("interior behind PCB ",cov_in-mod_back,"  over the leg recess ",elec_back-mod_back));
echo(str("DRIVER BOARD outline ",drv_w," x ",drv_h," x ",drv_env," on its own",
         " | but the number that decides fit is drv_stack ",drv_stack,
         " - see DEPTH BUDGET below | off the recess band ",elec_back-mod_back,
         " available"));
echo(str("CLEARANCE in front of: cell ",rec_back-bat_t-mod_back,
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
         drv_room," available -> ",
         (drv_stack+adapt_env <= drv_room) ? "fits"
           : str("SHORT by ",drv_stack+adapt_env-drv_room,
                 ".  depth ",depth," -> ",depth+(drv_stack+adapt_env-drv_room),
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
echo(str("DEPTH BUDGET in the driver column: stack ",drv_stack," measured (driver + female",
         " sockets + carrier), room ",drv_room," (the register face at ",elec_back,
         " less the ",carrier_lift," the pads lift the board for its solder joints",
         ", back to the glass plane at ",mod_back,") -> ",
         (drv_stack <= drv_room)
           ? str("fits by ",drv_room-drv_stack)
           : str("SHORT by ",drv_stack-drv_room),
         " | the carrier misses the recess band (x +/-",rec_w/2," vs the carrier at ",
         carrier_cx-carrier_w/2," to ",carrier_cx+carrier_w/2,
         "), so it datums to the register face at ",elec_back,
         " rather than to the recess floor's backing at ",rec_back,
         " - worth ",elec_back-rec_back));
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
echo(str("STAND: lever leg, swings ",dep_ang," deg | leg ",leg_len," long, ",
         leg_t," thick at the pivot tapering ONE-SIDED to ",leg_tf,
         " so the back face stays flush | pin dia ",pin_d,
         " snapped into sockets in the recess walls, mouth ",
         (pin_d+pin_fit)*ear_mouth," across a ",pin_d+pin_fit," bore, through ",
         ear_w," ears INSIDE the pocket -> a ",pin_d," x ",pin_len,
         " pin, which is exactly rec_w, so the pocket walls cap it",
         " | THE POCKET IS A PLAIN BLIND HOLLOW: no detent, no seat, no latch lip",
         " across its mouth.  The stop makes the deployed pose; folded, the leg just",
         " lies in the pocket and nothing holds it there"));
echo(str("STOP: the heel reaches ",heel_z," past the pin and is cut by the recess",
         " floor pulled back through ",dep_ang," deg, so at ",dep_ang,
         " a FLAT lands on the floor - a face, not a tangent corner |",
         " load path leg -> heel -> cover, in COMPRESSION, and the display's own",
         " weight pushes it INTO the stop | swing is ",dep_ang,
         " < 90, which is what puts the heel ON the floor plane rather than",
         " through it"));
echo(str("FINGER ACCESS: the ears are only ",ear_len," long, so away from the pivot",
         " the leg sits in the full ",rec_w," with ",finger_g,
         " open either side of it, the whole length, at the full ",rec_dep,
         " depth - no separate notch band | pocket reaches x +/-",rec_w/2,
         ", the driver carrier's near edge is ",carrier_cx+carrier_w/2,
         " -> clears by ",abs(carrier_cx+carrier_w/2)-rec_w/2));
echo(str("LEG WIDTH is DERIVED: rec_w ",rec_w," less two ears of ",ear_w,
         " and ",rec_clr," clearance each -> leg_w ",leg_w,
         " | the pin passes through both ears and its ends finish flush with the",
         " pocket walls, so nothing else retains it sideways"));
echo(str("STANCE: lean ",lean," deg | footprint ",footprint,
         " | folded foot tip at z ",foot_z," against a ",rear_chf," chamfer -> ",
         stand_ok ? "clear, nothing overhangs the bottom edge"
                  : "OVERHANGS THE BOTTOM EDGE - raise foot_z"));
echo(str("RECESS: ",rec_dep," deep down to z ",cav_z0,", then ",rec_shl,
         " below that because the cover is backed by SOLID FRAME there | floor",
         " leaves ",rec_floor," to rec_back ",rec_back," | anything CROSSING the",
         " band datums there; everything else datums to the register face ",
         elec_back," (= cov_in ",cov_in," less the ",reg_step," register step),",
         " so crossing the band costs ",elec_back-rec_back));
echo(str("FASTENERS: ", insert_fit
         ? str(insert_size," heat-set inserts, bore dia ",ins_d," x ",ins_l+ins_relief,
               " deep into a ",scr_wall," mm end wall | ",insert_size,
               " countersunk screws, head ",scr_head,", cone ",scr_csk,
               " deep in a ",cover_t," cover")
         : str("self-tapping into a ",scr_pilot," pilot, ",scr_depth," deep")));
// Gap between two axis-aligned rectangles in the back face, in plan (x, z).
// Positive = that much material between them; negative = they overlap.
function _sep(a0,a1,b0,b1) = max(a0-b1, b0-a1);
function gap2d(ax0,ax1,az0,az1, bx0,bx1,bz0,bz1) =
    let (sx = _sep(ax0,ax1,bx0,bx1), sz = _sep(az0,az1,bz0,bz1))
    (sx > 0 && sz > 0) ? sqrt(sx*sx + sz*sz) : max(sx, sz);

// THE STRUCTURAL CHECK ON THE BACK FACE.  Every opening in it, measured against
// the port.  Openings that share a narrow band leave a rib between them, and a rib
// is the thing that cracks - so this is echoed rather than left to be discovered.
pw = snap_w + 2*snap_c;  ph = snap_h + 2*snap_c;
px0 = ucb_x - pw/2;  px1 = ucb_x + pw/2;
pz0 = ucb_z - ph/2;  pz1 = ucb_z + ph/2;
g_rec  = gap2d(px0,px1,pz0,pz1, -rec_w/2, rec_w/2, rec_z0, rec_top);
g_rib  = min([ for (i = [0,1])
               gap2d(px0,px1,pz0,pz1, pad_x[i]-pad_w[i]/2, pad_x[i]+pad_w[i]/2,
                                      pad_z[i]-pad_h/2,    pad_z[i]+pad_h/2) ]);
g_scr  = min([ for (sp = scr_pos)
               gap2d(px0,px1,pz0,pz1, sp[0]-scr_head/2, sp[0]+scr_head/2,
                                      sp[1]-scr_head/2, sp[1]+scr_head/2) ]);
g_min  = min(g_rec, g_scr);
echo(str("POCKET END WALLS: the boss runs z ",boss_z0," to ",boss_z1," and the DEEP",
         " section of the pocket runs ",shl_z0," to ",rec_top,", so each end wall has ",
         shl_z0-boss_z0," / ",boss_z1-rec_top," of boss behind it -> ",
         (shl_z0-boss_z0 >= rec_floor - 1e-6 && boss_z1-rec_top >= rec_floor - 1e-6)
           ? "both closed"
           : "AN END WALL IS OPEN into the interior - see chk=rec_floor_gap",
         " | an end wall faces along z, so the floor probes never touch it: start the",
         " boss and the deep section on the SAME plane and the lower one is a ",
         rec_w," x ",rec_shl_y-rec_y0," hole into the electronics bay"));
echo(str("POCKET FLOOR: recess_boss() runs x +/-",rec_w/2+rec_wall," and z ",boss_z0,
         " to ",boss_z1," (it starts where the interior does - below that solid frame",
         " is behind the cover), front face at ",rec_back,", so the floor is ",rec_floor,
         " for the whole DEEP length | the cover's own skin+register is only ",
         cover_t+reg_step," against a ",rec_dep,
         " deep pocket, so without the boss the cut goes through | below the step",
         " stand_register() extends the register down to z ",reg_ext_z0,
         " so the shallow band keeps ",reg_step," behind it, and the frame is",
         " relieved to match (it stops at ",reg_ext_z0,", clear of the chamfer)",
         " | the floor is flat and unbroken at ",rec_floor,
         " the whole deep length - nothing is cut into it | boss reaches x ",
         -(rec_w/2+rec_wall),", carrier's near edge ",carrier_cx+carrier_w/2,
         " -> clears by ",abs(carrier_cx+carrier_w/2)-(rec_w/2+rec_wall)));
echo(str("POCKET FLOOR PLATE: the cover's register extension runs z ",reg_ext_z0,
         " to ",shl_z0+0.05," and the frame is relieved ",reg_fit,
         " larger to take it, so there is a ",reg_fit," gap all round the plug",
         " | the rear chamfer takes ",chf_bite," off the frame's back face at the",
         " bottom edge, so the plate has to STOP ABOVE THAT or the gap comes out",
         " through the chamfer and leads into the frame's end wall -> ",
         reg_seal >= 0.5
           ? str("ends in solid frame, ",reg_seal," of it below the relief")
           : str("OPEN - only ",reg_seal," left; raise reg_ext_z0 or rec_z0"),
         " | and the frame's bottom end wall is NOT hollowed - lightening() runs at",
         " the top end only - so the plate is backed by ",body_d-lgt_y0,
         " of solid frame rather than by a void.  That costs ",lgt_gain," cm3"));
echo(str("GLASS RIBS: ", bare_panel
         ? str("bottom rib SPLIT into two ",rib_seg," segments at x +/-",
               rec_w/2+rib_pocket_c," to +/-",rec_w/2+rib_pocket_c+rib_seg,
               " so the stand pocket cannot cut their root (it reaches x +/-",
               rec_w/2,", leaving ",rib_pocket_c," of material) | top rib one piece,",
               " x ",pad_x[1]-pad_w[1]/2," to ",pad_x[1]+pad_w[1]/2," at z ",pad_z[1],
               ", clear of the pocket which ends at z ",rec_top)
         : "module pads, not ribs", " | each stands ",cov_in-mod_back-rib_gap,
         " off the cover face"));
echo(str("PORT CLEARANCES in the back face: to the stand pocket ",g_rec,
         ", to the nearest corner screw ",g_scr," | worst ",g_min," -> ",
         g_min >= 8 ? "no two openings share a band"
                    : g_min >= 4 ? "TIGHT - a thin rib between two openings"
                                 : "TOO CLOSE - move the port"));
echo(str("PORT vs GLASS RIBS: nearest rib root is ",g_rib,
         " away -> ", g_rib >= 2 ? "the ribs keep their footing"
                                 : "IT IS UNDERCUTTING A RIB"));
echo(str("PORT WIRING: charger's near edge is x ",chg_x_c-chg_w/2," z ",
         chg_z-chg_h/2," to ",chg_z+chg_h/2,", so the two wires run about ",
         max(chg_x_c-chg_w/2-px1, 0)," mm"));
echo(str("REAR PORT: ", port_snap
         ? str("snap-in pigtail, opening ",snap_w+2*snap_c," x ",snap_h+2*snap_c,
               " (part ",snap_w," x ",snap_h,", clearance ",snap_c," a side), centred x ",
               ucb_x," z ",ucb_z," | needs ",snap_d," clear behind, has ",
               cov_in - (ucb_z < cav_z0 + 30 ? 0 : 0) - mod_back)
         : str("breakout board in rails, opening ",port_w," x ",port_h)));
echo(str("CARRIER MOUNT: four dia ",carrier_hole," holes at ",carrier_hx," x ",carrier_hz,
         " centres (",carrier_hx-carrier_hole," x ",carrier_hz-carrier_hole,
         " edge to edge), ",(carrier_w-carrier_hx)/2," in from each edge of the ",
         carrier_w," x ",carrier_h," board | a dia ",min(carrier_pad, 2*carrier_pin),
         " PAD ",carrier_lift," tall under each corner, carrying a dia ",
         min(carrier_hole-carrier_peg, 2*carrier_pin)," PEG that stands ",
         carrier_t+1.2," past the board face - so the board sits at ",carrier_back,
         " with ",carrier_lift," of air under it for the header solder joints",
         " | first header pin is ",carrier_pin," from the hole, so nothing on pad or",
         " peg may exceed ",2*carrier_pin," across"));
echo(str("DRIVER MOUNT: ", carrier_fit
         ? str("carrier ",carrier_w," x ",carrier_h," on four pegs, driver plugs into ",
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
echo(str("CHARGER POSTS: four dia ",chg_boss_d," posts at ",chg_hx," x ",chg_hz,
         " centres (ASSUMED - measure the breakout), standing ",chg_stand,
         " off the register face so the board lands at ",chg_back,
         " | each takes an M2 heat-set insert: bore dia ",chg_ins_d," x ",chg_bore,
         " (insert ",chg_ins_l," plus ",chg_ins_rel," relief), reaching depth ",
         chg_back+chg_bore," against a back face at ",depth," -> ",
         (depth - (chg_back+chg_bore) >= 1.0)
           ? str(depth-(chg_back+chg_bore)," of skin left, the bore stays blind")
           : "IT BREAKS THE BACK FACE - raise chg_skin",
         " | wall round the bore ",(chg_boss_d-chg_ins_d)/2,
         " | clear in front of the board: ",chg_back-chg_t-mod_back));
if (mod_header) {
  echo(str("HEADER vs CELL: needs ",conn_h,", has ",cov_in-bat_t-mod_back,
           " -> ", (conn_h > cov_in-bat_t-mod_back)
                   ? str("CLASH by ",conn_h-(cov_in-bat_t-mod_back)," mm")
                   : "clear"));
  echo(str("depth needed for a ",conn_h," mm header over the cell: ",
           conn_h + bat_t + mod_back + 5.95 + 0.5));
}

// ---------------------------------------------------------------- checks
// Render one of these and look for solid geometry.  READ THIS FIRST: the test is
// POSITIVE VOLUME, not "is the result empty", and two of these pairs report
// geometry BY DESIGN:
//   frame_cover  - the frame's rear face and the cover's front face are both at
//                  y = body_d, so the intersection is a zero-thickness sheet:
//                  real vertices, ZERO volume, no interference
//   cover_board  - 16.70 mm3, which is the four carrier pegs standing through the
//                  four holes they are there to fill.  mock_board() draws the
//                  carrier as a plain slab, so the holes are not in the model and
//                  the pegs read as solid.  Watch the NUMBER: 16.70 is the pegs,
//                  anything above it is something else touching the boards.
// Chasing either as a clash is a dead end (it cost a while once).
// SECOND TRAP: when an intersection is empty OpenSCAD writes NO FILE, so a script
// that reuses output paths silently re-reads the PREVIOUS check's result.  Delete
// the output before every run or you will chase a clash that is not there.
// State of the checks:
//   frame_cover and cover_board report by design - see above.  Everything else
//   must be genuinely EMPTY.
//
//   cover_legs is the one that matters, and it must be empty at EVERY chk_th, not
//   just at 0 and dep_ang.  Both ends were clear once while the middle was 1.80 mm
//   inside the cover; that is what the swept check exists to catch.  With no
//   detent it is empty at every angle but 0, where it reports 6.91 mm3 - the latch
//   lip's bite on the folded leg's tip, which is the interference the leg bows past.
//   heel_floor is the one that proves the STOP: empty up to dep_ang, then linear in
//   the over-travel, which is the signature of a FACE rotating into a plane.
//   rec_frame is new and is the guard on the recess being too deep: the volume
//   the recess needs must not reach into the frame.  frame_cover cannot
//   substitute, because its by-design zero-volume touch would hide it.
chk = "";
chk_th = dep_ang;                 // sweep angle for the swept checks
if(chk=="frame_cover")  intersection(){ frame(); cover(); }
if(chk=="frame_module") intersection(){ frame(); mock_module(); }
if(chk=="cover_module") intersection(){ cover(); mock_module(); }
if(chk=="cover_board")  intersection(){ cover(); mock_board(); }
if(chk=="frame_board")  intersection(){ frame(); mock_board(); }
if(chk=="drv_module")   intersection(){ mock_module(); drv_envelope(); }
if(chk=="conn_cell")    intersection(){ mod_conn(); mock_cell(); }
if(chk=="conn_board")   intersection(){ mod_conn(); mock_pcbs(); }
if(chk=="conn_cover")   intersection(){ mod_conn(); cover(); }
if(chk=="adapt_board")  intersection(){ mock_adapter(); mock_board(); }
if(chk=="adapt_cover")  intersection(){ mock_adapter(); cover(); }
// the leg through its whole stroke, against the cover.  MUST be empty at every
// chk_th - the ends alone are not sufficient and have hidden a jam before.
if(chk=="cover_legs")   intersection(){ cover(); leg_placed(chk_th); }
// is the heel's flat on the floor?  This is the one that proves the STOP is real:
// the intersection must be EMPTY below dep_ang and appear at dep_ang - a tangent
// heel would show a hair of geometry all the way through instead.
if(chk=="heel_floor")   intersection(){
    translate([-rec_w/2, rec_y0 - 20, piv_z - 20]) cube([rec_w, 20, 40]);
    leg_placed(chk_th); }
// IS THE POCKET ACTUALLY BLIND?  A slab just behind the floor, less the cover: if
// the cover does not fill it, the pocket is a hole into the interior.  This is the
// one that was missing - rec_frame only asks whether the pocket reaches the FRAME,
// which it did not, so nothing complained while 7.75 mm of it was open.
// Each band is tested at ITS OWN floor: the deep section against rec_floor, the
// shallow section against the register alone.  Anything the cover does not fill is
// a hole into the interior.
//
// AND IT TESTS THE TWO END WALLS, which is what it used to miss.  An end wall faces
// along z, not along y, so probing "behind the floor" never touches it - and the
// deep section's lower end wall had nothing behind it at all: an 18 x 2.1 slot out
// of the leg pocket into the electronics bay, with every other check passing.
if(chk=="rec_floor_gap") difference(){
    union(){
        // max(...,0.1) on purpose: a non-positive slab would build no geometry and
        // the check would read EMPTY, which is the same word as "passes".
        translate([-rec_w/2, rec_back + 0.05, shl_z0 + 0.05])
            cube([rec_w, max(rec_floor - 0.1, 0.1), rec_top - shl_z0 - 0.1]);
        translate([-rec_w/2, body_d - reg_step + 0.05, rec_z0 + 0.05])
            cube([rec_w, max(reg_step + cover_t - rec_shl - 0.1, 0.1),
                  shl_z0 - rec_z0 - 0.1]);
        // the deep section's two END WALLS: the material that has to stand beyond
        // each end of it, over the depth the deep pocket reaches past the shallow
        // floor.  Both must be solid boss.
        for (zz = [shl_z0 - rec_floor + 0.05, rec_top + 0.05])
            translate([-rec_w/2, rec_y0 + 0.05, zz])
                cube([rec_w, rec_shl_y - rec_y0 - 0.1, rec_floor - 0.1]);
    }
    cover();
}
// The glass ribs must keep their root: the pocket must not cut into them at all.
// This is the check that was missing when the pocket took 20 of a 26 mm root and
// left the rib cantilevered - nothing intersected, so no clash check saw it.
if(chk=="rib_recess")   intersection(){ glass_ribs();  recess_cut(); }
// the recess must not reach into the frame.  This is the depth guard.
if(chk=="rec_frame")    intersection(){ recess_cut();   frame(); }

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
   ["cav_z0",cav_z0],["cav_z1",cav_z1],["Zc",Zc],
   ["win_w",win_w],["win_h",win_h],
   ["white_show_short",white_show_short],["white_show_long",white_show_long],
   ["tape_pad",tape_pad?1:0],["tape_len",tape_len],["tape_reach",tape_reach],["tape_dep",tape_dep],
   ["pcb_face_y",pcb_face_y],["mod_back",mod_back],
   ["cov_in",cov_in],
   ["pin_d",pin_d],["leg_len",leg_len],["leg_w",leg_w],
   ["leg_t",leg_t],["foot_r",foot_r],
   ["dep_ang",dep_ang],["leg_len",leg_len],["foot_z",foot_z],["leg_w",leg_w],
   ["leg_t",leg_t],["leg_tf",leg_tf],["foot_r",foot_r],["pin_d",pin_d],
   ["heel_z",heel_z],["tap_z",tap_z],
   ["piv_h",piv_h],["piv_z",piv_z],["piv_y",piv_y],
   ["shl_z0",shl_z0],
   ["rec_dep",rec_dep],["rec_shl",rec_shl],["rec_w",rec_w],["rec_clr",rec_clr],
   ["rec_floor",rec_floor],["rec_wall",rec_wall],["rec_y0",rec_y0],["rec_top",rec_top],["rec_z0",rec_z0],
   ["rec_back",rec_back],["rec_shl_y",rec_shl_y],["py_edge",py_edge],
   ["reg_ext_z0",reg_ext_z0],["reg_fit",reg_fit],["chf_bite",chf_bite],
   ["reg_seal",reg_seal],["stand_reg_w",stand_reg_w],["lgt_gain",lgt_gain],
   ["boss_z0",boss_z0],["boss_z1",boss_z1],
   ["ear_w",ear_w],["ear_len",ear_len],["ear_x0",ear_x0],["ear_mouth",ear_mouth],
   ["pin_len",pin_len],["finger_g",finger_g],
   ["elec_back",elec_back],["reg_step",reg_step],
   ["lean",lean],["footprint",footprint],["stand_ok",stand_ok?1:0],
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
   ["chg_hx",chg_hx],["chg_hz",chg_hz],["chg_boss_d",chg_boss_d],["chg_ins_d",chg_ins_d],
   ["chg_ins_l",chg_ins_l],["chg_bore",chg_bore],["chg_back",chg_back],["chg_stand",chg_stand],
   ["chg_skin",chg_skin],
["flash_port",flash_port?1:0],["flash_wall",flash_wall],["flash_x",flash_x],["flash_y0",flash_y0],["flash_y1",flash_y1],["usb_w",usb_w],
   ["bare_panel",bare_panel?1:0],["perf_fit",perf_fit?1:0],["perf_w",perf_w],["perf_h",perf_h],
   ["perf_cx",perf_cx],["perf_cz",perf_cz],["perf_t",perf_t],
   ["carrier_fit",carrier_fit?1:0],["carrier_w",carrier_w],["carrier_h",carrier_h],
   ["carrier_hole",carrier_hole],["carrier_hx",carrier_hx],["carrier_hz",carrier_hz],
   ["carrier_peg",carrier_peg],["carrier_pin",carrier_pin],
   ["carrier_cx",carrier_cx],["carrier_cz",carrier_cz],["carrier_z0",carrier_z0],["carrier_z1",carrier_z1],
   ["carrier_back",carrier_back],["carrier_face",carrier_face],["carrier_pad",carrier_pad],
   ["carrier_lift",carrier_lift],["drv_room",drv_room],
   ["pin_fit",pin_fit],["snap_c",snap_c],
   ["scr_wall",scr_wall],["carrier_t",carrier_t],["hdr_h",hdr_h],
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
