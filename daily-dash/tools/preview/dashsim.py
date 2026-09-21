"""
A stand-in for ESPHome's display API, drawing to a PNG instead of the panel.

The point is fidelity to what the glass will actually show, not a pretty
mockup: the canvas is 300 x 400, there are exactly three inks, and text is
rendered with antialiasing OFF because ESPHome bakes fonts to 1 bit per pixel.
A layout that fits here fits on the panel.

Coordinates and call signatures mirror the lambda's, so a layout written
against this file translates to C++ line for line.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

W, H = 300, 400

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (200, 30, 30)  # the panel's ink is a dull brick, not a pure #f00

FONT_DIR = Path(__file__).resolve().parents[2] / ".esphome" / "font"


def font(family: str, weight: int, size: int) -> ImageFont.FreeTypeFont:
    """One of the TTFs ESPHome already downloaded for this project."""
    return ImageFont.truetype(str(FONT_DIR / f"{family}@{weight}@False@v1.ttf"), size)


_GLYPHS: dict = {}


def _has_glyph(f: ImageFont.FreeTypeFont, ch: str) -> bool:
    """Whether the face carries this codepoint.

    FreeType answers with the .notdef box for anything it lacks, so the
    character is compared against a noncharacter that is guaranteed absent:
    matching bitmaps mean the same (missing) glyph. Keyed on the face's file
    and size, because the layouts build a fresh font object per call.
    """
    def mask(c):
        m = f.getmask(c, mode="1")
        return m.size, bytes(m)

    face = (f.path, f.size)
    if face not in _GLYPHS:
        _GLYPHS[face] = {None: mask("\ufffe")}
    seen = _GLYPHS[face]
    if ch not in seen:
        seen[ch] = mask(ch) != seen[None]
    return seen[ch]


def drawable(f: ImageFont.FreeTypeFont, s: str) -> str:
    """The text the panel would actually show.

    The firmware builds its fonts with `ignore_missing_glyphs: true`, so a
    codepoint outside the glyphset is skipped at render time -- an emoji in an
    event title costs its space and nothing more. Dropping it here too keeps
    the preview honest, where PIL would otherwise draw a .notdef box that the
    glass never shows.
    """
    return "".join(c for c in (s or "") if _has_glyph(f, c))


class Canvas:
    """The `it` object a display lambda is handed."""

    def __init__(self, w: int = W, h: int = H):
        self.img = Image.new("RGB", (w, h), WHITE)
        self.d = ImageDraw.Draw(self.img)
        self.d.fontmode = "1"  # 1-bit glyphs, as ESPHome renders them
        self.w, self.h = w, h

    # --- ESPHome primitives ------------------------------------------------

    def fill(self, color=WHITE):
        self.d.rectangle([0, 0, self.w, self.h], fill=color)

    def line(self, x1, y1, x2, y2, color=BLACK):
        self.d.line([x1, y1, x2, y2], fill=color, width=1)

    def rectangle(self, x, y, w, h, color=BLACK):
        self.d.rectangle([x, y, x + w - 1, y + h - 1], outline=color, width=1)

    def filled_rectangle(self, x, y, w, h, color=BLACK):
        self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=color)

    def circle(self, cx, cy, r, color=BLACK):
        self.d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color, width=1)

    def filled_circle(self, cx, cy, r, color=BLACK):
        self.d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)

    def print(self, x, y, f, color, align, text):
        """align is one of TOP_LEFT, TOP_CENTER, TOP_RIGHT, BOTTOM_LEFT,
        BOTTOM_RIGHT, CENTER -- the subset the lambda uses."""
        anchor = {
            "TOP_LEFT": "la",
            "TOP_CENTER": "ma",
            "TOP_RIGHT": "ra",
            "BOTTOM_LEFT": "ls",
            "BOTTOM_RIGHT": "rs",
            "CENTER": "mm",
        }[align]
        self.d.text((x, y), drawable(f, text), font=f, fill=color, anchor=anchor)

    # --- measurement, matching the lambda's text_w / wrap_lines -------------

    @staticmethod
    def text_w(f, s: str) -> int:
        return int(f.getlength(drawable(f, s)))

    @staticmethod
    def font_h(f) -> int:
        a, d = f.getmetrics()
        return a + d

    def wrap(self, f, text: str, maxw: int, max_lines: int) -> list[str]:
        lines, cur = [], ""
        for word in (text or "").split():
            cand = word if not cur else cur + " " + word
            if self.text_w(f, cand) > maxw and cur:
                lines.append(cur)
                cur = word
            else:
                cur = cand
        if cur:
            lines.append(cur)
        if not lines:
            lines = [""]
        if len(lines) > max_lines:
            last = lines[max_lines - 1]
            while last and self.text_w(f, last + "...") > maxw:
                last = last[:-1]
            lines = lines[:max_lines]
            lines[-1] = last + "..."
        return lines

    # --- output ------------------------------------------------------------

    def save(self, path, scale: int = 2, bezel: int = 10):
        """Nearest-neighbour upscale so every panel pixel stays one square,
        inside a grey bezel that shows where the glass ends."""
        img = self.img.resize((self.w * scale, self.h * scale), Image.NEAREST)
        out = Image.new("RGB", (img.width + bezel * 2, img.height + bezel * 2), (70, 70, 72))
        out.paste(img, (bezel, bezel))
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        out.save(path)
        return path


def contact_sheet(paths, out, cols=3, gap=14, labels=None):
    """Several renders side by side, for comparing options or times of day."""
    imgs = [Image.open(p) for p in paths]
    cw, ch = imgs[0].width, imgs[0].height
    label_h = 22 if labels else 0
    rows = (len(imgs) + cols - 1) // cols
    sheet = Image.new(
        "RGB",
        (cols * cw + (cols + 1) * gap, rows * (ch + label_h) + (rows + 1) * gap),
        (245, 245, 247),
    )
    d = ImageDraw.Draw(sheet)
    lf = font("Roboto", 700, 15)
    for i, im in enumerate(imgs):
        r, c = divmod(i, cols)
        x = gap + c * (cw + gap)
        y = gap + r * (ch + label_h + gap)
        if labels:
            d.text((x + 2, y), labels[i], font=lf, fill=(30, 30, 34))
        sheet.paste(im, (x, y + label_h))
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    return out
