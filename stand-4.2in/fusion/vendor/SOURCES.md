# Component CAD and datasheets

Every part in the build, what exists for it, and where it comes from. Where a
vendor publishes a solid model it is checked in beside this file; where one does
not exist, the measured envelope in [`../keepouts.csv`](../keepouts.csv) is the
substitute, and `fetch-vendor.sh` pulls the drawings and the large optional
models on demand.

Dimensions quoted here are the model's, from
[`../reference-dimensions.csv`](../reference-dimensions.csv).

STEP imports on Fusion's Personal licence, so the models below open directly.
Each one you upload takes one of Personal's ten active documents, so upload the
part you need rather than the folder, and deactivate a model when you are done
with it — read-only documents are unlimited.

---

## 1. Waveshare 4.2inch e-Paper (B) — raw panel, WFT0420CZ15

400 × 300, red/black/white, SPI, **no PCB**. Glass 76 × 90 × 1.05, sharp
corners, active area 63.6 (short) × 84.8 (long). Dead border 3.0 on three sides
and 9.4 on the ribbon side — all measured on the part in hand, which outranks
the datasheet.

| | |
|---|---|
| Product | https://www.waveshare.com/4.2inch-e-paper-b.htm |
| Wiki | https://www.waveshare.com/wiki/4.2inch_e-Paper_Module_(B)_Manual |
| Panel specification, with the mechanical drawing | https://files.waveshare.com/upload/7/7f/4.2inch-e-paper-b-specification.pdf |
| (B) V2 user manual | https://files.waveshare.com/wiki/4.2inch%20e-Paper%20Module%20(B)/4.2inch%20e-Paper%20(B)%20V2.pdf |
| Module schematic — the PCB version, which is not fitted | https://files.waveshare.com/upload/9/97/4.2inch_e-Paper_Schematic.pdf |

No solid model is published for the raw panel. `PANEL_GLASS` and `FPC_HOLLOW`
in the keep-outs cover it. The specification PDF is the one to read for the FPC
tail: it carries the tail's own width and length and where it leaves the glass,
which is the single geometry in this build that has no slack.

## 2. Waveshare e-Paper ESP32 Driver Board — Rev 3

Outline 29.46 × 48.25, off the vendor's mechanical drawing. The 24-pin FPC
socket sits on one long edge, 12.5 from the near end. Measured stack, back face
to tallest point, board + female sockets + carrier: **16.0**.

| | |
|---|---|
| Product | https://www.waveshare.com/e-paper-esp32-driver-board.htm |
| Wiki | https://www.waveshare.com/wiki/E-Paper_ESP32_Driver_Board |
| Rev 3 drawing and schematic | https://files.waveshare.com/wiki/E-Paper-ESP32-Driver-Board/E-Paper_ESP32_Driver_Board_V3.pdf |
| Earlier schematic | https://files.waveshare.com/upload/8/80/E-Paper_ESP32_Driver_Board_Schematic.pdf |
| User manual | https://files.waveshare.com/upload/4/4a/E-Paper_ESP32_Driver_Board_user_manual_en.pdf |
| Community solid model, GrabCAD account needed | https://grabcad.com/library/e-paper-esp32-driver-board-1 |
| ESP32-WROOM-32E STEP, official Espressif — the tallest part on the board | https://github.com/espressif/kicad-libraries/blob/main/3dmodels/espressif.3dshapes/ESP32-WROOM-32E.STEP |

Two revision facts that the older product pages get wrong: the serial chip has
been a **CH343** since July 2022, not the CP2102, and the 20241230 revision
moved the USB connector to Type-C.

`DRIVER_BOARD` in the keep-outs is the full `drv_env` 6.0 component envelope,
not the 1.6 bare board — the cover's rails overlap the PCB edge by 1.0 on
purpose to grip it, so a body drawn at the board's own thickness reads those
rails as a clash while they are doing their job.

## 3. Waveshare e-Paper FPC adapter

Ships in the box with the driver board, along with a 24-pin FFC extension
cable. Outline **18 × 32**, measured; 5.0 deep over the board and both FPC
connectors. It is fitted as a service loop: the panel's tail plugs into it on
the panel side and a longer FPC crosses the frame/cover split.

No product page, drawing or model of its own — it is listed only as an included
accessory on the driver board's product page. `FPC_ADAPTER` carries the measured
envelope. A community capture of a 24-pin FPC-to-SPI breakout, useful for pad positions
rather than for its outline, is on EasyEDA as *Waveshare E-Paper 24 pin FPC to
SPI board rev.A*. Both that page and the GrabCAD one above refuse a scripted
fetch, so open them in a browser.

## 4. Adafruit bq25185 USB / DC / Solar charger — PID 6091

32 × 26.3, and 7.2 deep over the board and its USB-C jack.

| | |
|---|---|
| Product | https://www.adafruit.com/product/6091 |
| Guide | https://learn.adafruit.com/adafruit-bq25185-usb-dc-solar-lithium-ion-polymer-charger |
| Downloads, including the CAD | https://learn.adafruit.com/adafruit-bq25185-usb-dc-solar-lithium-ion-polymer-charger/downloads |
| PCB source | https://github.com/adafruit/Adafruit-bq25185-Charger-Breakout-PCB |
| TI bq25185 datasheet | https://www.ti.com/lit/ds/symlink/bq25185.pdf |

**Checked in here:**

- `adafruit-6091-bq25185-charger.step` — solid model, components included
- `adafruit-6091-bq25185-charger.f3d` — the same part as a Fusion archive; use
  this one, it comes in as a proper component tree

Both from https://github.com/adafruit/Adafruit_CAD_Parts, which is where every
other Adafruit part in the catalogue lives too.

## 5. Adafruit bq24074 charger — PID 4755

The alternative the model can be switched to with `chg_part = "bq24074"`:
25.4 × 20.3. Not fitted.

- Product: https://www.adafruit.com/product/4755
- STEP: https://github.com/adafruit/Adafruit_CAD_Parts/tree/main/4755%20USB%20Solar%20Charger

## 6. Adafruit Perma-Proto quarter-size — PID 1608

43.2 × 50.8. Not fitted: the bare panel put the charger on its own standoffs.
Checked in as `adafruit-1608-perma-proto-quarter.step` because the driver
carrier is a cut of the same 0.1 inch double-sided stock, so it is the closest
thing to a model of that board.

- Product: https://www.adafruit.com/product/1608

## 7. 2000 mAh LiPo, 694449 pouch

44 × 49 × 6.9, measured, with roughly R2 corners in plan. No CAD exists for a
pouch cell. `CELL` in the keep-outs is squared off at the full 44 × 49, which is
the conservative way round.

The NTC is confirmed on this pack: 10 kΩ yellow-to-black at room temperature.

## 8. Fasteners

Four M2.5 countersunk screws through the cover into heat-set inserts in the
frame, one near each corner. The model assumes the common CNC Kitchen sizes:
insert OD 4.0 × 4.0 long, bore Ø3.6 × 5.0, head Ø5.0 at 90°.

- Insert sizing and boss design: https://www.cnckitchen.com/blog/tips-and-tricks-for-heat-set-inserts
- The M2.5 insert itself: https://cnckitchen.store/products/gewindeeinsatz-threaded-insert-m2-5-standard-100-stk-pcs
- Screws, with a STEP download per size: https://www.mcmaster.com/screws/socket-head-screws/flat-head-socket-cap-screws-8/thread-size~m2-5/
- Inserts: https://www.mcmaster.com/products/heat-set-inserts/thread-size~m2-5/

The kickstand pin is a Ø2 × 18 rod — half of a stock 40 mm length.
