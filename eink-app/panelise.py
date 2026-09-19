"""Source image -> the panel's three inks.

Red is gated on the pixel actually being red, not on nearest-colour distance:
a warm antialias pixel like (167,137,112) is closer to pure red than to black,
which is what fringes every silhouette edge when you let quantize() decide.
"""
from PIL import Image
import numpy as np

W, H = 300, 400
RED_SAT = 90    # max-min, below this a pixel is treated as neutral
RED_DOM = 60    # how far R must lead G and B
LUM_MID = 128   # black/white split for flat art

def fit(src, w=W, h=H):
    src = src.convert("RGB")
    sw, sh = src.size
    t = w / h
    if sw / sh > t:
        nw = int(sh * t); box = ((sw - nw) // 2, 0, (sw - nw) // 2 + nw, sh)
    else:
        nh = int(sw / t); box = (0, (sh - nh) // 2, sw, (sh - nh) // 2 + nh)
    return src.crop(box).resize((w, h), Image.LANCZOS)

# Near-black and near-white bounds for the clamp. A generated print puts its
# "white" paper around luminance 230 and its ink around 10 -- neither is at the
# rail. Left alone, Floyd-Steinberg treats a 230 background as a tone it must
# reproduce and scatters dots across the whole sky. Clamped, those two flats
# quantise with zero error and only the genuine mid-tones get diffused, which
# is where the depth actually lives.
CLAMP_LO, CLAMP_HI = 40, 205


def panelise(img, dither, clamp=False):
    x = np.asarray(img).astype(np.int16)
    r, g, b = x[:, :, 0], x[:, :, 1], x[:, :, 2]
    sat = x.max(2) - x.min(2)
    is_red = (sat >= RED_SAT) & (r >= np.maximum(g, b) + RED_DOM)

    lum = (x @ np.array([0.299, 0.587, 0.114])).astype(np.float32)
    if clamp:
        lum = np.where(lum >= CLAMP_HI, 255.0, lum)
        lum = np.where(lum <= CLAMP_LO, 0.0, lum)
    if dither:
        # Floyd-Steinberg the non-red pixels into black/white.
        L = lum.copy(); black = np.zeros(L.shape, bool)
        for y in range(H):
            for xx in range(W):
                if is_red[y, xx]:
                    continue
                old = L[y, xx]; new = 255.0 if old >= LUM_MID else 0.0
                black[y, xx] = new == 0.0
                e = old - new
                if xx + 1 < W:  L[y, xx + 1] += e * 7 / 16
                if y + 1 < H:
                    if xx:          L[y + 1, xx - 1] += e * 3 / 16
                    L[y + 1, xx] += e * 5 / 16
                    if xx + 1 < W:  L[y + 1, xx + 1] += e * 1 / 16
    else:
        black = (lum < LUM_MID) & ~is_red

    out = np.full((H, W, 3), 255, np.uint8)
    out[black] = (0, 0, 0)
    out[is_red] = (255, 0, 0)
    return Image.fromarray(out), black, is_red

HEADER_LEN = 13
STRIDE = 38          # ceil(300 / 8); the last 4 bits of each row are padding
MAGIC = b"EINK1"


def pack(black, red):
    """Two boolean masks -> the 30,413-byte blob the panel expects.

    Rows are interleaved, black then red, so the firmware can draw a complete
    row from 76 bytes and never holds an image buffer. A plane-major file would
    force it to buffer 15 KB before it could draw anything, which is most of the
    heap it has left once WiFi and the frame buffer are up.
    """
    out = bytearray(MAGIC)
    out += W.to_bytes(2, "little")
    out += H.to_bytes(2, "little")
    out += STRIDE.to_bytes(2, "little")
    out += bytes([2, 0])                       # planes, flags
    assert len(out) == HEADER_LEN, len(out)

    # np.packbits gives MSB-first bytes, which is the bit order the firmware
    # reads (mask = 0x80 >> (x & 7)), and pads the final partial byte with zeros
    # -- zero being "no ink", so the padding is white and invisible.
    for y in range(H):
        for plane in (black, red):
            out += np.packbits(plane[y]).tobytes().ljust(STRIDE, b"\x00")[:STRIDE]
    return bytes(out)


if __name__ == "__main__":
    im = fit(Image.open("day_src.png"))
    out, black, red = panelise(im, dither=False)
    out.save("day_panelised.png")
    t = W * H
    print("white %.1f%%  black %.1f%%  red %.1f%%" %
          (100*(~black & ~red).sum()/t, 100*black.sum()/t, 100*red.sum()/t))
    out.resize((600, 800), Image.NEAREST).save("day_panelised_2x.png")
