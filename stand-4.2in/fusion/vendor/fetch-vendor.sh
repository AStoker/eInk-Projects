#!/bin/sh
# Pull the vendor drawings, datasheets and large optional models that are NOT
# checked in.  See SOURCES.md for what each one is and why.
#
#   sh fusion/vendor/fetch-vendor.sh
#
# Everything lands in fusion/vendor/downloaded/, which .gitignore keeps out of
# the repo - these are vendor documents, and the links in SOURCES.md are the
# durable record of them.
set -e
cd "$(dirname "$0")"
mkdir -p downloaded
cd downloaded

get() {  # get <file> <url>
  [ -f "$1" ] && { echo "   have $1"; return 0; }
  printf '   %s ... ' "$1"
  curl -fsSL -A "Mozilla/5.0" -o "$1" "$2" && echo ok || echo FAILED
}

echo "== panel"
get 4.2inch-e-paper-b-specification.pdf \
    https://files.waveshare.com/upload/7/7f/4.2inch-e-paper-b-specification.pdf
get 4.2inch-e-paper-b-v2-manual.pdf \
    "https://files.waveshare.com/wiki/4.2inch%20e-Paper%20Module%20(B)/4.2inch%20e-Paper%20(B)%20V2.pdf"
get 4.2inch-e-paper-module-schematic.pdf \
    https://files.waveshare.com/upload/9/97/4.2inch_e-Paper_Schematic.pdf

echo "== driver board"
get e-paper-esp32-driver-board-v3.pdf \
    https://files.waveshare.com/wiki/E-Paper-ESP32-Driver-Board/E-Paper_ESP32_Driver_Board_V3.pdf
get e-paper-esp32-driver-board-schematic.pdf \
    https://files.waveshare.com/upload/8/80/E-Paper_ESP32_Driver_Board_Schematic.pdf
get e-paper-esp32-driver-board-manual.pdf \
    https://files.waveshare.com/upload/4/4a/E-Paper_ESP32_Driver_Board_user_manual_en.pdf
get esp32-wroom-32e.step \
    https://raw.githubusercontent.com/espressif/kicad-libraries/main/3dmodels/espressif.3dshapes/ESP32-WROOM-32E.STEP

echo "== charger"
get bq25185-datasheet.pdf https://www.ti.com/lit/ds/symlink/bq25185.pdf
get adafruit-4755-bq24074.step \
    "https://raw.githubusercontent.com/adafruit/Adafruit_CAD_Parts/main/4755%20USB%20Solar%20Charger/4755%20USB%20Solar%20Charger.step"

echo
echo "The GrabCAD driver-board model needs an account and cannot be scripted:"
echo "  https://grabcad.com/library/e-paper-esp32-driver-board-1"
