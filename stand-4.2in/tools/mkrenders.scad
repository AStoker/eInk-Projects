// =====================================================================
//  Renders built from the EXPORTED STLs, not from the model's geometry.
//
//  Every solid in these pictures is imported from stl/*.stl, so what you see
//  is what the slicer gets.  The model is included only for its numbers - the
//  placement maths (lean angle, hub position, leg swing) and the mock
//  electronics, which have no STL because they are not printed.
//
//  Each STL is exported print-ready: mirrored in X (print_mirror = true) and
//  rotated flat-face-down.  The stl_* modules below undo exactly that, so the
//  parts come back into model space and assemble; as_printed() then flips the
//  finished assembly, so every picture shows the hand you will actually hold -
//  which is the OPPOSITE hand to the drawing sheets.  If print_mirror or a
//  part's export orientation ever changes in the model, change it here too.
//
//  Usage (see tools/mkrenders.sh):
//    openscad -o out.png -D 'part="none"' -D 'view="iso_p"' \
//             --imgsize=1400,1400 --camera=... tools/mkrenders.scad
// =====================================================================
include <../src/epaper_stand.scad>

view = "iso_p";

// ---------------------------------------------------------------- parts
// inverse of:  oriented() translate([0,H,0]) rotate([90,0,0]) frame()
module stl_frame(){
    rotate([-90,0,0]) translate([0,-H,0]) mirror([1,0,0]) import("../stl/frame.stl"); }

// inverse of:  oriented() translate([0,0,depth]) rotate([-90,0,0]) cover()
module stl_cover(){
    rotate([90,0,0]) translate([0,0,-depth]) mirror([1,0,0]) import("../stl/cover.stl"); }

// inverse of:  oriented() rotate([-90,0,0]) disc()
module stl_disc(){
    rotate([90,0,0]) mirror([1,0,0]) import("../stl/disc.stl"); }

// inverse of:  oriented() leg()  ->  leg_shape() in its own frame
module stl_leg_shape(){
    rotate([-90,0,0]) mirror([1,0,0]) import("../stl/leg.stl"); }

module stl_leg_placed(theta){
    translate([0, disc_t/2, -pivot_r]) rotate([-theta,0,0]) stl_leg_shape(); }

module stl_bezel_test(){
    rotate([-90,0,0]) translate([0,-H,0]) mirror([1,0,0]) import("../stl/bezel_test.stl"); }

// ------------------------------------------------------------ assemblies
// The parts come out of the exporter mirrored in X (print_mirror = true), so
// the object you actually hold is the mirror of the as-designed hand: relief,
// screw spine and both ports on the other side.  The stl_* modules above put
// each part back into design space so they assemble; as_printed() flips the
// finished assembly back, so these pictures show the thing that comes off the
// printer rather than the thing on the drawing sheets.
module as_printed(){ if (print_mirror) mirror([1,0,0]) children(); else children(); }

module stl_stand(rot=0, theta=0){
    translate([0, pk_y0, hub_z]) rotate([0,rot,0]) {
        color("#3a3d44") stl_disc();
        color("#2e3138") stl_leg_placed(theta); } }

module stl_device(rot=0, theta=0, guts=true){
    color("#4c4f57") stl_frame();
    color("#54575f") stl_cover();
    if (guts) { mock_module(); mock_board(); }
    stl_stand(rot, theta); }

// same lean maths as the model's standing(), on the STL parts
module stl_standing(land=false, theta=theta_dep){
    zp = hub_z - pivot_r;
    yp = pk_y0 + disc_t/2;
    py = depth - rear_chf;
    fy = yp + leg_len*sin(stop_ang);
    fz = zp - leg_len*cos(stop_ang);
    a  = (theta == 0) ? 0 : atan2(fz, fy - py);
    as_printed()
    translate([0,0,py*sin(a)])
    rotate([-a,0,0])
        if (land) translate([-H/2,0,W/2]) rotate([0,90,0]) stl_device(-90, theta);
        else stl_device(0, theta);
}

// ----------------------------------------------------------------- views
if      (view=="iso_p")      stl_standing(false);
else if (view=="iso_l")      stl_standing(true);
else if (view=="front")      stl_standing(false);
else if (view=="side")       stl_standing(false);
else if (view=="back_dep")   stl_standing(false);
else if (view=="back_fold")  as_printed() { color("#4c4f57") stl_frame();
                                            color("#54575f") stl_cover();
                                            stl_stand(0, 0); }
else if (view=="cover_in")   as_printed() color("#54575f") stl_cover();
else if (view=="disc")       as_printed() color("#3a3d44") stl_disc();
else if (view=="leg")        as_printed() color("#2e3138") stl_leg_shape();
else if (view=="bezel_test") as_printed() color("#4c4f57") stl_bezel_test();
// internal layout: the printed cover as exported, with the electronics that
// are NOT printed drawn from the model
else if (view=="guts")       as_printed() { color("#54575f") stl_cover(); mock_board(); }
// the four printed parts exactly as the exporter leaves them - mirrored in X
// and already flat-face-down, so nothing here rotates them.  This is the
// orientation that lands on the bed when you open the STL in the slicer.
else if (view=="plate")      {
    color("#4c4f57") translate([-50, 0, 0]) import("../stl/frame.stl");
    color("#54575f") translate([ 50, 0, 0]) import("../stl/cover.stl");
    color("#3a3d44") translate([  0,-40, 0]) import("../stl/disc.stl");
    color("#2e3138") translate([-45,-40, 0]) import("../stl/leg.stl"); }
