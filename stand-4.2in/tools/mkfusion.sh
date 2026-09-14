#!/bin/sh
# Regenerate everything in fusion/ from src/epaper_stand.scad.
#
#   sh tools/mkfusion.sh
#
# Meshes and DXF sketches come out in the MODEL's coordinate system, not print
# orientation, so they land on the same origin as fusion/parameters.csv and the
# keep-out bodies.  Nothing in fusion/ is hand-written except README.md and
# vendor/ - re-run this after any parameter change.
set -e
cd "$(dirname "$0")/.."
mkdir -p fusion/mesh fusion/dxf fusion/scripts

SCAD=tools/mkfusion.scad
NONE='-D part="none"'

echo "== parameter dump"
openscad -o /tmp/p.stl -D 'part="params"' src/epaper_stand.scad 2>&1 \
  | sed -n 's/^ECHO: "P|\(.*\)"$/\1/p' | tr '|' '=' > /tmp/params.txt

echo "== meshes (model orientation)"
# Both formats on purpose.  STL is on Fusion's Personal-licence format list and
# 3MF is not, so STL is the one that always opens; 3MF is smaller and keeps the
# keep-outs as eight separate volumes, so it is the better one where it works.
for t in frame cover leg keepouts; do
  openscad -o "fusion/mesh/$t.stl" --export-format binstl $NONE \
           -D "target=\"$t\"" $SCAD 2>/dev/null
  openscad -o "fusion/mesh/$t.3mf" $NONE -D "target=\"$t\"" $SCAD 2>/dev/null
  echo "   fusion/mesh/$t.stl, .3mf"
done

echo "== DXF sketch profiles"
# front      outer profile and the window, seen from the front
# pocket     section through the glass pocket: reliefs and the ribbon hollow
# cavity     section inside the PCB cavity: walls, corner bores, ribbon notch
# cover_in   section just inside the cover: register, rails, carrier pegs
# cover_back the cover's outline and the stand pocket, seen from the back
# side       centreline section through frame and cover together
# leg_side   the leg's side profile, folded
# layout     every component envelope in plan, on the front view
for t in front pocket cavity cover_in cover_back side leg_side layout; do
  openscad -o "fusion/dxf/$t.dxf" $NONE -D "target=\"$t\"" $SCAD 2>/dev/null
  echo "   fusion/dxf/$t.dxf"
done

echo "== CSVs and the Fusion script"
python3 tools/mkfusion.py /tmp/params.txt
