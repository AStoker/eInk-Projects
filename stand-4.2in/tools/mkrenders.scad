// =====================================================================
//  Renders built from the EXPORTED STLs, not from the model's geometry.
//
//  Every solid in these pictures is imported from stl/*.stl, so what you see
//  is what the slicer gets.  The model is included only for its numbers - the
//  placement maths and the mock electronics, which have no STL because they
//  are not printed.
//
//  Each STL is exported print-ready: rotated flat-face-down, in the hand it is
//  designed in - there is no mirroring.  The stl_* modules below undo exactly
//  that rotation, so the parts come back into model space and assemble.  If a
//  part's export orientation changes in the model, change it here too.
//
//  PORTRAIT ONLY: the leg runs down the centreline and the stand has one
//  orientation, so there is one standing view.
//
//  Usage (see tools/mkrenders.sh):
//    openscad -o out.png -D 'part="none"' -D 'view="iso_p"' \
//             --imgsize=1400,1400 --camera=... tools/mkrenders.scad
// =====================================================================
include <../src/epaper_stand.scad>

view = "iso_p";

// ---------------------------------------------------------------- parts
// inverse of:  translate([0,H,0]) rotate([90,0,0]) frame()
module stl_frame(){
    rotate([-90,0,0]) translate([0,-H,0]) import("../stl/frame.stl"); }

// inverse of:  translate([0,0,depth]) rotate([-90,0,0]) cover()
module stl_cover(){
    rotate([90,0,0]) translate([0,0,-depth]) import("../stl/cover.stl"); }

// inverse of:  leg()  ->  leg_shape() in its own frame
module stl_leg_shape(){
    rotate([-90,0,0]) import("../stl/leg.stl"); }

// the model's leg_placed(), on the STL.  Same +theta sign - the foot swings OUT.
module stl_leg_placed(theta){
    translate([0, piv_y, piv_z]) rotate([theta,0,0]) stl_leg_shape(); }

module stl_bezel_test(){
    rotate([-90,0,0]) translate([0,-H,0]) import("../stl/bezel_test.stl"); }

// ------------------------------------------------------------ assemblies
module stl_device(theta=0, guts=true){
    color("#4c4f57") stl_frame();
    color("#54575f") stl_cover();
    if (guts) { mock_module(); mock_board(); }
    color("#2e3138") stl_leg_placed(theta); }

// The lean is DERIVED at the top level of the model, so this consumes it rather
// than re-deriving it.  This file used to carry its own copy of that arithmetic
// and the two could drift.
module stl_standing(theta=dep_ang){
    a = (theta == 0) ? 0 : lean;
    translate([0,0,py_edge*sin(a)]) rotate([-a,0,0]) stl_device(theta);
}

// ----------------------------------------------------------------- views
if      (view=="iso_p")      stl_standing();
else if (view=="iso_fold")   stl_standing(0);
else if (view=="front")      stl_standing();
else if (view=="side")       stl_standing();
else if (view=="back_dep")   stl_standing();
else if (view=="back_fold")  stl_device(0, guts=false);
else if (view=="cover_in")   color("#54575f") stl_cover();
// the recess, the arc detent track and the pin sockets, from behind and close in
else if (view=="cover_rec")  intersection(){
                                 color("#54575f") stl_cover();
                                 translate([-(rec_w/2+rec_wall+4), rec_back-1,
                                            piv_z-18])
                                     cube([rec_w+2*rec_wall+8,
                                           depth-rec_back+2, 30]); }
else if (view=="leg")        color("#2e3138") stl_leg_shape();
else if (view=="bezel_test") color("#4c4f57") stl_bezel_test();
// internal layout: the printed cover as exported, with the electronics that
// are NOT printed drawn from the model
else if (view=="guts")       { color("#54575f") stl_cover(); mock_board(); mock_adapter(); }
// the three printed parts exactly as the exporter leaves them - already
// flat-face-down, so nothing here rotates them.  This is the orientation that
// lands on the bed when you open the STL in the slicer.
else if (view=="plate")      {
    color("#4c4f57") translate([-50, 0, 0]) import("../stl/frame.stl");
    color("#54575f") translate([ 50, 0, 0]) import("../stl/cover.stl");
    color("#2e3138") translate([  0,-40, 0]) import("../stl/leg.stl"); }
