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
// the 24-pin FPC socket sits on one long edge - the panel ribbon has to reach it
fpc_w = 16.0;                                 // socket body, along the board edge
fpc_off = 12.5;                               // socket centre, from the near end
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
pivot_screw = true;
pin_fit = 0.10;                  // plain-pin fallback when pivot_screw = false
leg_len = 35.4; leg_w = 12.0; leg_t = 3.4;
leg_slot_c = 0.2;                // close, so the clamp screw has something to do
foot_r = 5.0; stop_ang = 58;     // deployed leg angle from straight down
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

/* [Rear USB-C pigtail] */
// Panel-mount pigtail with its own snap-in catch, so the cover just needs a
// precise rectangular hole and clear space behind it - no printed rails.
// MEASURE THE ACTUAL PART: snap fits live or die on a tenth of a millimetre.
port_snap = true;
snap_w = 15.0; snap_h = 8.0;   // the opening
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
pad_x = bare_panel
  ? [pan_px, pan_px - 12.0]
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
drv_z0 = bare_panel ? rib_cz - fpc_off : cav_z1 - 1.0 - drv_h;
drv_z1 = drv_z0 + drv_h;
drv_cz = (drv_z0 + drv_z1)/2;
drv_back = carrier_fit ? carrier_face - hdr_h : cov_in_pk - 0.5;
fpc_z = drv_z0 + fpc_off;                         // socket centre, on the -X edge
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
    translate([cav_cx,y0,Zc]) xzext(d) relieved(cav_w,cav_h,cav_r,cav_rel); }
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
                    translate([carrier_cx+sx*(carrier_w/2-3.5), cov_in,
                               carrier_cz+sz*(carrier_h/2-3.5)])
                        rotate([90,0,0]) cylinder(d=carrier_pad+2.0, h=cov_in-carrier_back);
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
module disc(){
    slot_w = leg_w + 2*leg_slot_c;
    slot_z0 = -(pivot_r + leg_w/2 + 1.2);
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
        translate([-slot_w/2, -0.01, slot_z0])
            cube([slot_w, disc_t+0.02, slot_z1-slot_z0]);
        if (pivot_screw) {
            // clearance through the near wall, countersink on the outside
            translate([-disc_d, disc_t/2, -pivot_r]) rotate([0,90,0])
                cylinder(d=scr_free, h=disc_d);
            translate([-disc_d/2 - slot_w/2, disc_t/2, -pivot_r]) rotate([0,90,0])
                cylinder(d1=scr_head, d2=scr_free, h=scr_csk+0.01);
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
    } } }

// =================================================================== leg
// leg-local: pin at the origin, leg along +Z, thickness in Y centred on 0
module leg_shape(){
    difference(){
        rotate([90,0,0]) translate([0,0,-leg_t/2]) linear_extrude(leg_t)
            hull(){ circle(d=leg_w); translate([0,leg_len-foot_r]) circle(r=foot_r); }
        // heel flat: the pocket floor, seen from the leg at the deployed angle
        rotate([theta_dep,0,0]) translate([-50,-60-disc_t/2,-200]) cube([100,60,400]);
        // axle.  A bearing fit on the screw shank: the clamp is what holds it,
        // not the hole.
        translate([-leg_w,0,0]) rotate([0,90,0])
            cylinder(d=pivot_screw ? scr_free + 0.2 : pin_d+pin_fit, h=2*leg_w);
        // nail chamfer on the tip
        translate([0,leg_t/2,leg_len]) rotate([0,90,0])
            translate([0,0,-leg_w]) cylinder(r=2.2,h=2*leg_w,$fn=4);
    } }

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
echo(str("walls: +X ",W/2-cav_x1,"  -X ",W/2+cav_x0,
         " | end walls ",cav_z0," / ",H-cav_z1));
echo(str("interior behind PCB ",cov_in-mod_back,"  over stand pocket ",cov_in_pk-mod_back));
echo(str("DRIVER BOARD envelope ",drv_w," x ",drv_h," x ",drv_env,
         " | clear depth over the puck ",cov_in_pk-mod_back," -> ",
         (drv_env <= cov_in_pk-mod_back) ? "fits"
           : str("SHORT by ",drv_env-(cov_in_pk-mod_back)," mm"),
         " | off the puck ",cov_in-mod_back));
echo(str("CLEARANCE in front of: cell ",cov_in_pk-bat_t-mod_back,
         " | proto pcb ",proto_face-mod_back," | driver pcb ",drv_back-drv_t-mod_back));
echo(str("module 8-pin header: ", mod_header
         ? str("allowance assumed ",conn_h," mm")
         : "NOT FITTED - the panel's 24-pin FPC goes straight to the driver board"));
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
         ? str(insert_size," clamp screw through the disc into an insert in the far",
               " slot wall | leg ",leg_w," in a ",leg_w+2*leg_slot_c," slot, so each",
               " wall closes ",leg_slot_c," to clamp | tighten to set the friction")
         : str("plain dia ",pin_d," pin, ",pin_fit," fit")));
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
// Measured state of all 14, by volume:
//   12 genuinely empty | frame_cover + cover_board zero-volume touches (by design)
//   NO real interference.  The two that used to be real were both consequences of
//   hardware this build does not have: conn_cell (154 mm3) was a mated 8-pin
//   header, drv_module (1050 mm3) was that header's cable inflating drv_env to 15.
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
   ["bat_w",bat_w],["bat_h",bat_h],["bat_t",bat_t],["bat_x0",bat_x0],
   ["bat_cx",bat_cx],["bat_cz",bat_cz],["bat_clr",bat_clr],["bat_fence",bat_fence],["pad_w0",pad_w[0]],["pad_w1",pad_w[1]],["pad_h",pad_h],
   ["pad_x0",pad_x[0]],["pad_x1",pad_x[1]],["pad_z0",pad_z[0]],["pad_z1",pad_z[1]],
   ["proto_w",proto_w],["proto_h",proto_h],["proto_t",proto_t],["proto_x0",proto_x0],
   ["proto_x1",proto_x1],["proto_cx",proto_cx],["proto_cz",proto_cz],
   ["proto_z0",proto_z0],["proto_z1",proto_z1],["proto_back",proto_back],["proto_face",proto_face],
   ["proto_hole_sp",proto_hole_sp],
   ["drv_env",drv_env],["drv_w",drv_w],["drv_h",drv_h],["drv_t",drv_t],["drv_x0",drv_x0],["drv_x1",drv_x1],
   ["drv_cx",drv_cx],["drv_cz",drv_cz],["drv_z0",drv_z0],["drv_z1",drv_z1],
   ["drv_back",drv_back],["drv_clr",drv_clr],["drv_rail",drv_rail],
   ["ucb_x",ucb_x],["ucb_z",ucb_z],["ucb_w",ucb_w],["ucb_l",ucb_l],["ucb_t",ucb_t],
   ["port_w",port_w],["port_h",port_h],
   ["chg_part",chg_part],["chg_w",chg_w],["chg_h",chg_h],["chg_t",chg_t],["chg_z",chg_z],["chg_x",proto_x0+chg_w/2+1],
   ["print_mirror",print_mirror?1:0],["flash_port",flash_port?1:0],["flash_wall",flash_wall],["flash_x",flash_x],["flash_y0",flash_y0],["flash_y1",flash_y1],["usb_w",usb_w],
   ["bare_panel",bare_panel?1:0],["perf_fit",perf_fit?1:0],["perf_w",perf_w],["perf_h",perf_h],
   ["perf_cx",perf_cx],["perf_cz",perf_cz],["perf_t",perf_t],
   ["carrier_fit",carrier_fit?1:0],["carrier_w",carrier_w],["carrier_h",carrier_h],
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
