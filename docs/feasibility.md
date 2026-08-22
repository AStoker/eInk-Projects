# eInk Skylight-style Calendar Dashboard — Feasibility & Build Plan

Goal: a wall-mounted 13.3" color e-paper family calendar in a **wooden frame**, with **front-facing buttons**, driven by Home Assistant (HAOS on an Intel NUC).

Verdict up front: **the DIY path is feasible and is the right call — but not because it's cheaper. It saves roughly $70–90, and the only version that gets you a wooden frame with front buttons is the DIY one.** The prebuilt reTerminal E1004 is a sealed plastic photo-frame body you cannot reasonably re-case.

---

## 1. Option comparison

| | **Prebuilt — reTerminal E1004** | **DIY — XIAO EE02 + 13.3" panel** |
|---|---|---|
| Price | **$279.90** | **$163.90** (board $14.90 + panel $149.00 bundled) |
| Panel | 13.3" E Ink Spectra 6, 1200×1600, 6 colors | Same panel (Spectra 6, T133A01 controller) |
| MCU | ESP32-S3 | XIAO ESP32-S3 Plus (on-board, PSRAM required and present) |
| Battery | 5000 mAh built in, months of runtime | Not included — add LiPo w/ JST 2.0 (~$15–20) or run USB-C |
| Buttons | Touch buttons on front bezel + physical on back | 3 user buttons + reset **on the driver board** (GPIO 2/3/5) — must be relocated to the front yourself |
| Extras | Temp/humidity sensors | None |
| Enclosure | 376 × 311 × 40 mm plastic photo-frame body, not user-servicable | You build it — wood frame + 3D-printed bezel/back |
| ESPHome | **Upstream support**: `epaper_spi`, `model: Seeed-reTerminal-E1004` | Upstream generic `model: T133A01` (needs `cs_pin` + `cs1_pin` + dims), or two community components purpose-built for EE02 |
| Effort | ~1 evening | ~2–3 weekends including frame iterations |

Also worth knowing: buying the raw 13.3" Spectra 6 panel from **Waveshare is $249.99** — Seeed's $149–161 is by far the cheapest source for this panel, so buy it as part of the EE02 kit.

### Cost roll-up, DIY
- EE02 board + 13.3" Spectra 6 panel (bundle): **$163.90**
- 3.7V LiPo, 3000–5000 mAh, JST 2.0: **$15–20** (skip if you run USB-C to the wall)
- FFC extension cable (nice-to-have; kit includes one FFC + antenna): **$5**
- Wooden frame: **$10–25** IKEA, or ~$15 in hardwood if you cut your own
- Filament, magnets, heat-set inserts, tactile switches, wire: **~$10**
- **Total: ~$195–225 vs. $279.90 prebuilt**

The savings are real but modest. Decide on form factor, not price.

---

## 2. The constraints that actually matter (identical on both paths)

These are properties of the Spectra 6 panel, not of the hardware you pick:

- **Full refresh is slow.** Waveshare spec sheet says 19 s; in practice with the ESPHome EE02 components people measure **25–35 s**, with audible buzzing during init. There is **no partial refresh** on Spectra 6.
- **Six colors only**: black, white, red, green, blue, yellow. Anything photographic must be dithered to that palette first.
- **Framebuffer is ~960 KB** — PSRAM mandatory (octal @ 80 MHz on the XIAO ESP32-S3 Plus).
- **SPI clock is limited to ~2 MHz** on the EE02 community driver; higher was unreliable.
- **Dual chip-select.** The T133A01 drives the panel as two halves. Any driver that assumes a single CS will not work.

Practical consequence: this is a **once-or-a-few-times-per-hour** display. Design the calendar as a static daily/weekly page, not a live dashboard. That's exactly the Skylight use case, so it fits.

---

## 3. Software plan (Home Assistant)

Two approaches, and I'd pick the second for a Skylight-like calendar:

**A. Native ESPHome drawing** — `epaper_spi` display + `homeassistant` sensor imports + a `lambda:` that draws text/shapes. Fine for a weather-and-sensors panel. Painful for a real calendar grid with variable-length event titles.

**B. Render-to-image (recommended)** — Generate the calendar as a PNG on the NUC, have the device fetch it with ESPHome's `online_image` and blit it. This gives you full HTML/CSS layout control and makes iteration a browser refresh instead of a firmware flash.

Pipeline for B:
1. A small add-on / container on HAOS pulls events from your HA calendar entities (`calendar.get_events`) and renders an HTML page.
2. Headless Chromium screenshots it at **1600×1200** (landscape) or 1200×1600 (portrait).
3. Quantize + dither to the 6-color Spectra palette (this step is not optional — undithered images come out muddy or all-black).
4. Serve the PNG on the LAN; ESPHome `online_image` with `update_interval: 15min` or triggered by an HA automation on calendar change.
5. Buttons trigger `homeassistant.event` / a service call → HA swaps which page the renderer produces → device re-fetches.

The `acegallagher/esphome-bigink` project already does exactly this on EE02 hardware (online_image + PNG + dithering + battery SOC + button-driven state), so there's a working reference. `rkaramandi/esphome-seeed-ee02` is the cleaner DisplayBuffer-API implementation if you'd rather draw natively.

Both are described by their authors as young/experimental. That is the single biggest risk in the DIY plan — budget time for driver debugging.

---

## 4. Frame plan

**Panel dimensions: 208.8 × 284.7 × 0.85 mm outline; 202.8 × 270.4 mm active area.**

- **21×30 cm / 8¼×11¾" frame** (IKEA FISKBO, RIBBA, RÖDALM): the panel fits the 210×300 opening with ~0.6 mm per side to spare. This has been done — a reviewer put this exact panel in an IKEA FISKBO 21×30. Two caveats they hit: the panel is narrower than the frame so the sides need masking, and **the back cover would not close properly with the driver board behind the panel.**
- **11×14" frame (recommended)**: 279×356 mm gives you room for a 3D-printed mat/bezel that hides the panel edge cleanly, space in the bottom bezel for front buttons, and depth for the electronics. Looks more like a Skylight, less like a screen wedged in a photo frame.
- **Depth is the real constraint.** You need ≥12–15 mm behind the glass: panel (0.85 mm) + FFC fold + EE02 board (80×40 mm, several mm tall with connectors) + battery. Standard IKEA frame rabbets are shallower than that. Plan on 3D-printing a **spacer ring + custom back panel** rather than reusing the frame's cardboard back. Route the USB-C cable out the bottom edge.
- **Use the FFC extension cable** to move the EE02 board off the panel's centerline and down toward the bottom bezel — that's what makes the button relocation and the back cover both work.
- **Wood note**: IKEA's RÖDALM "oak effect" / "birch effect" and HOVSTA are veneer or foil, not solid wood. If you want real wood, a hardwood frame is easy to cut yourself, and you're 3D-printing the internals anyway.

**Front buttons**: the EE02's three user buttons are on GPIO **2, 3, 5**. Two ways to get them to the front — (a) 3D-printed plungers through the bezel pressing the on-board switches, which forces awkward board placement, or (b) **solder panel-mount tactile switches in parallel with the on-board button pads** and mount them in the bottom bezel. (b) is cleaner and lets you space them like the EE02's front row.

---

## 5. Recommended sequence (de-risk before spending $164)

1. **Prototype the software first on cheap hardware.** A 7.5" mono XIAO ePaper panel (~$59) or reTerminal E1001 ($69–79) has first-class ESPHome support and no driver risk. Build the whole HA → HTML → PNG → device pipeline on it. If you hate the 30 s refresh or the calendar layout, you've learned that for $60.
2. Order the EE02 + 13.3" panel. Get it lighting up on a desk with one of the two community ESPHome components before designing any enclosure.
3. Measure the assembled stack-up (panel + FFC fold + board + battery), then model the bezel/spacer/back.
4. Print in PLA, test-fit in a cheap IKEA frame, iterate, then commit to the good wood frame.
5. Wire the front buttons last.

---

---

## 6. Sourcing the panel, and which drivers actually apply

**The panel is E Ink EL133UF1** — 1200×1600, six colors, **208.8 × 284.7 × 0.85 mm** outline, **202.8 × 270.4 mm** active area, **60-pin 0.5 mm-pitch FPC**. Everyone sells the same glass; only the price and what's bolted to it differ.

My "not Waveshare" note was **about price only**, not quality — waveshare.com wants $249.99 for the raw panel.

Ranked sources:

| Source | Price | Notes |
|---|---|---|
| **Seeed — XIAO ePaper DIY Kit EE02** | **$15.99–$176.98** depending on variant (board alone $14.90; panel alone $160.99, $145.99 @10+) | **Buy this one.** Connector guaranteed, and the kit bundles the 60-pin adapter, FFC extension cable, and 2.4 GHz antenna |
| Amazon — raw 13.3" Spectra 6 (Waveshare / XYGStudy) | varies | Convenient. Make sure it's the **raw display**, not the HAT+ version |
| OpenELAB | €199.95 (full kit) | EU (Munich) / US (Arlington) warehouses — pricier, but faster than Shenzhen |
| waveshare.com | $249.99 raw / $259.99 with HAT | Same glass, worst price |
| E Ink shopkits (ED2208-NCA) | $449.00 | Also needs their Scarlet driver board |
| ThinkRobotics | ₹35,249.99 | Ships from India |
| **Avoid:** Good Display GDEP133C02 | — | That's a **QSPI module**, a different interface. It will not drop onto the EE02 |

Curiosity worth knowing about: Good Display sells a finished 13.3" Spectra 6 **in a wooden frame** (DMPH133E61) — but it's **$889**, cloud/app-managed on their own RTOS, with no Home Assistant or local API. Not a shortcut.

### "Can I use the Waveshare drivers?"

Three separate things get called "the Waveshare driver," and only one of them matters here:

1. **The Waveshare driver HAT** — a Raspberry Pi–oriented board. You don't need it. **The EE02 *is* your driver board.**
2. **Waveshare's C / Python sample code** — written for Pi, Arduino, and ESP-IDF. Not usable from ESPHome, but a useful reference for the panel init sequence if you end up debugging.
3. **ESPHome's `waveshare_epaper` component** — **does not support the 13.3" Spectra 6.** This is the one that trips people up. That panel is a **dual-CS T133A01** and lives in the newer **`epaper_spi`** component, configured with both `cs_pin` and `cs1_pin`. For a bare panel on EE02: `platform: epaper_spi`, `model: T133A01`, manual pins and dimensions — or use one of the two EE02 community components.

### ESPHome Designer

It generates **YAML**, not raw lambdas — widget-based layout, multi-page, with round-trip import of an existing config. Tested devices are reTerminal **E1001 / E1002**, TRMNL 7.5" OG, Waveshare PhotoPainter, and M5Paper / M5Core Ink. **The E1004 and the EE02 13.3" are not on that list** — the README says untested devices "may require troubleshooting." LVGL mode is flagged "Highly Experimental."

Practical path: hand-write the `display:` block yourself (`epaper_spi` / `T133A01` / 1200×1600 / dual CS / PSRAM), then let Designer generate the drawing YAML against that canvas size and paste it in. It runs as Docker or a standalone web app, not an HA add-on.

**This changes the software recommendation in §3.** If Designer works against your canvas, native ESPHome drawing becomes the primary path and you can skip the HTML→PNG pipeline entirely. Keep the render-to-image route as a fallback for a dense month-grid layout, where hand-placed widgets get tedious.

### Additional sources
- [E Ink EL133UF1 product page](https://www.eink.com/product/detail/EL133UF1)
- [Seeed 13.3" Spectra 6 datasheet (PDF)](https://files.seeedstudio.com/Bazaar/product_pdf/100088646.pdf)
- [OpenELAB EE02 kit](https://openelab.io/products/seeed-studio-xiao-epaper-diy)
- [E Ink shopkits ED2208-NCA](https://shopkits.eink.com/en/product/detail/13.3''Spectra6ePaperDisplay)
- [Good Display DMPH133E61 wooden-frame unit](https://buy-lcd.com/products/dmph133e61)
- [SpicyLimes/ESPHome-Designer](https://github.com/SpicyLimes/ESPHome-Designer)


---

## 7. Decision: buy the E1004 — and how to get it into wood

Given ESPHome Designer covers the UI work and the DIY savings are only ~$70–90, the prebuilt E1004 is the sound pick. It also carries one advantage the EE02 does not: **an upstream ESPHome preset** (`platform: epaper_spi`, `model: Seeed-reTerminal-E1004`) instead of a young community driver. Plus the 5000 mAh battery and the temp/humidity sensor.

**Useful geometry:** body is **376 × 311 × 40 mm**; active area is 270.4 × 202.8 mm. That's a **~53 mm bezel on every side** — the E1004 is already mat-proportioned like a matted photo frame. The job is covering plastic with wood, not re-laying-out a frame.

**Known unknowns:** Seeed publishes **no CAD/STEP, no schematics, and no disassembly guide** for the E1004. Its spec table says "metal enclosure," but CNX's teardown of the E1001/E1002 found **plastic** despite similar marketing language — treat the material as unconfirmed until it's in hand.

### Option A — Wooden over-frame (recommended)

Don't open it. Build a wood frame with a rabbet that the whole body drops into from behind; the wood covers the plastic bezel and the opening is cut slightly larger than the active area. Reversible, warranty intact, nothing electrical to touch.

Two things to design around:

- **Front capacitive touch buttons** live on the lower front bezel. Either cut openings in the bottom rail over them, or thin the wood there to **~1–2 mm veneer** — capacitive sensing works through thin non-conductive material and ESP32 touch thresholds are tunable. Worth prototyping in scrap before cutting the good stock. Caveat: Seeed's ESPHome cookbook only documents the E1001/E1002 **rear GPIO buttons (GPIO 3/4/5)**; whether the E1004's front touch pads are exposed in ESPHome is unverified.
- **40 mm depth**, plus a metal stand on threaded inserts and a wall-mount hole on the back. The over-frame has to clear or replace that hardware.

### Option B — Full reframe (open it, transplant panel + mainboard)

Precedent is decent: the E1001/E1002 open via **four corner screws** (Seeed ships a screwdriver), with an **antenna cable running to the back cover** to watch out for. The E1004 is probably similar but unconfirmed.

Trade-offs: you'd likely want an FFC extension to reposition the mainboard; you lose the front touch buttons (bezel assembly) and would wire tactile switches to the rear button GPIOs or the **2×4 pin expansion header**; and if the front turns out to be bonded metal, difficulty jumps sharply.

### Option C — Fall back to the EE02 kit

If you end up building a frame, wiring front buttons, and printing internals regardless, the ~$115 saved buys a lot of filament. You give up the upstream ESPHome preset, the battery, and the sensors.

### Recommended order of operations

1. Order the E1004. Run it on the stock stand for a week driving a real calendar via ESPHome Designer.
2. Measure the actual body, bezel, and touch-pad locations — don't design from the spec sheet.
3. Build the over-frame (A). Test capacitive touch through veneer scrap first.
4. Only open the case if the over-frame can't get the look you want — by then you'll know exactly what you're cutting into.


## Sources

- [reTerminal E1004 product page](https://www.seeedstudio.com/reTerminal-E1004-p-6692.html)
- [Getting Started with reTerminal E1004 — Seeed Wiki](https://wiki.seeedstudio.com/getting_started_with_reterminal_e1004/)
- [Hackster: Seeed packs its 13.3" color ePaper into the reTerminal E1004](https://www.hackster.io/news/seeed-packs-its-13-3-color-epaper-display-an-espressif-esp32-and-battery-into-the-reterminal-e1004-dcc5ed526bfb)
- [XIAO ePaper DIY Kit EE02 product page](https://www.seeedstudio.com/XIAO-ePaper-DIY-Kit-EE02-for-13-3-Spectratm-6-E-Ink.html)
- [Getting Started with EE02 — Seeed Wiki](https://wiki.seeedstudio.com/getting_started_with_ee02/)
- [CNX Software: EE02 announcement](https://www.cnx-software.com/2026/01/10/xiao-epaper-diy-kit-ee02-an-esp32-s3-board-designed-for-13-3-inch-spectra-6-color-e-ink-display/)
- [CNX Software: EE02 hands-on review (IKEA FISKBO build)](https://www.cnx-software.com/2026/02/05/review-of-xiao-epaper-diy-kit-ee02-13-3-inch-color-e-ink-display-with-sensecraft-hmi-and-arduino/)
- [Seeed 13.3" Spectra 6 panel](https://www.seeedstudio.com/13-3inch-Six-Color-eInk-ePaper-Display-with-1200x1600-Pixels-p-6569.html)
- [Waveshare 13.3inch e-Paper HAT+ (E) — dimensions & refresh spec](https://www.waveshare.com/13.3inch-e-paper-hat-plus-e.htm)
- [ESPHome `epaper_spi` component docs](https://esphome.io/components/display/epaper_spi/)
- [rkaramandi/esphome-seeed-ee02](https://github.com/rkaramandi/esphome-seeed-ee02)
- [acegallagher/esphome-bigink](https://github.com/acegallagher/esphome-bigink)
- [Seeed: Which is your best e-ink display for your Home Assistant dashboard](https://www.seeedstudio.com/blog/2025/10/27/which-is-your-best-e-ink-display-for-your-home-assistant-dashboard/)
- [SmartHomeScene: E-Paper dashboards with Waveshare and ESPHome](https://smarthomescene.com/diy/e-paper-dashboards-with-waveshare-and-esphome/)
- [CNX Software: reTerminal E1001/E1002 review (teardown — four corner screws, plastic case)](https://www.cnx-software.com/2025/12/15/reterminal-e1001-e1002-review-bw-and-color-epaper-displays-tested-with-sensecraft-hmi-and-home-assistant/)
- [Seeed ESPHome Cookbook: buttons, battery, touch, low power](https://wiki.seeedstudio.com/reterminal_e10xx_with_esphome_advanced/)
- [reTerminal E Series overview (dimensions, enclosure)](https://wiki.seeedstudio.com/reterminal_e10xx_main_page/)
