#!/bin/sh
# Regenerate renders/ from the EXPORTED STLs.
#
# Every solid in these images is imported from stl/*.stl by tools/mkrenders.scad,
# so a render can only show what the slicer will get.  Re-export the STLs first
# if the model has changed:
#
#   for p in frame cover disc leg bezel_test; do
#     openscad -o stl/$p.stl -D "part=\"$p\"" src/epaper_stand.scad
#   done
#
# then run this from the stand-4.2in directory:  sh tools/mkrenders.sh
set -e
cd "$(dirname "$0")/.."
mkdir -p renders

SCAD=tools/mkrenders.scad

# shot <file> <view> <rx,ry,rz> <p|o> <w,h>
# frames the part automatically (--viewall --autocenter)
shot() {
  echo "  $1"
  openscad -o "renders/$1" \
    -D 'part="none"' -D 'chk=""' -D "view=\"$2\"" \
    --camera=0,0,0,"$3",0 --viewall --autocenter \
    --projection="$4" --imgsize="$5" --colorscheme=Tomorrow \
    "$SCAD" >/dev/null 2>&1
}

# shotfixed <file> <view> <tx,ty,tz,rx,ry,rz,dist> <p|o> <w,h>
# explicit camera, for layouts where auto-framing leaves too much air
shotfixed() {
  echo "  $1"
  openscad -o "renders/$1" \
    -D 'part="none"' -D 'chk=""' -D "view=\"$2\"" \
    --camera="$3" --projection="$4" --imgsize="$5" --colorscheme=Tomorrow \
    "$SCAD" >/dev/null 2>&1
}

echo "rendering from stl/ ..."
shot      01-iso-portrait.png    iso_p      70,0,25   p 1400,1400
shot      02-iso-landscape.png   iso_l      70,0,25   p 1400,1400
shot      03-front.png           front      90,0,0    o 1000,1300
shot      04-side.png            side       90,0,90   o 1200,1100
shot      05-back-deployed.png   back_dep   68,0,205  p 1400,1400
shot      06-back-folded.png     back_fold  68,0,205  p 1400,1400
shot      07-cover-inside.png    cover_in   62,0,18   p 1200,1400
shot      08-internal-layout.png guts       62,0,18   p 1200,1400
shot      09-disc.png            disc       58,0,205  p 1000,1000
shot      10-leg.png             leg        58,0,205  p 1000,700
shotfixed 11-print-plate.png     plate      0,22,10,50,0,0,430 o 1400,700
echo "done"
