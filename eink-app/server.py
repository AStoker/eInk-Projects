"""eInk Daily Dash — image server.

Turns whatever is in two watched directories into panel-ready blobs and serves
them to the panel over HTTP. See ../IMAGE-PIPELINE.md for the blob format and
the contract this implements.

Two routes matter:

    GET /revision          a short string, changes only when /next would differ
    GET /next?mode=Photos  the blob itself, application/octet-stream

The panel wakes every 15 minutes and a full refresh costs ~17 seconds of
e-paper, so it asks for the revision first and only downloads when that string
has moved. Everything here exists to make that string honest: it must change
when the picture changes and at no other time.
"""

from __future__ import annotations

import hashlib
import json
import logging
import os
import threading
import time
from dataclasses import dataclass
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

from panelise import W, H, fit, panelise, pack
from PIL import Image

LOG = logging.getLogger("eink")

# --- configuration ---------------------------------------------------------
# Home Assistant writes the add-on's options here. Reading the file directly is
# what bashio does; doing it in Python keeps the image free of the Home
# Assistant base layer. Absent (running outside Supervisor), every value falls
# back to an environment variable and then to a default, which is what makes
# the server runnable from a terminal for testing.
def _options() -> dict:
    try:
        with open("/data/options.json", encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return {}


_OPT = _options()


def _opt(key: str, env: str, default):
    if key in _OPT:
        return _OPT[key]
    return type(default)(os.environ.get(env, default))


# Watched separately and never recursively. /media/runpod is the RunPod app's
# own gallery plus a pile of loose renders; only the eink/ subdirectory is ours.
PHOTO_DIR = Path(os.environ.get("EINK_PHOTO_DIR", "/media/eink/photos"))
AI_DIR = Path(os.environ.get("EINK_AI_DIR", "/media/runpod/eink"))
OUT_DIR = Path(os.environ.get("EINK_OUT_DIR", "/media/eink/out"))
PORT = int(os.environ.get("EINK_PORT", "8100"))
# Reported by /health so a deploy can be confirmed by asking the running
# container what it is, rather than by trusting that the update applied.
VERSION = os.environ.get("EINK_VERSION", "dev")
SCAN_SECONDS = int(_opt("scan_seconds", "EINK_SCAN_SECONDS", 60))
# How long one photo stays on the panel. Rotation is on a clock rather than on
# /next so that the revision can be computed without a request having happened —
# otherwise "has the picture changed" could only be answered by changing it.
PHOTO_ROTATE_SECONDS = int(_OPT["photo_rotate_minutes"]) * 60 if "photo_rotate_minutes" in _OPT \
    else int(os.environ.get("EINK_PHOTO_ROTATE_SECONDS", "900"))

# The three AI slots and the local hour each begins. Night wraps midnight.
SLOTS = (("morning", 5), ("day", 11), ("night", 18))
AI_NAMES = {"morning", "day", "night"}

SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif", ".tif", ".tiff"}


@dataclass(frozen=True)
class Blob:
    """One converted image, ready to serve."""

    ident: str  # content hash of the source; also the revision
    path: Path  # the .bin on disk
    source: Path


def current_slot(now: time.struct_time | None = None) -> str:
    """Which AI image belongs on the panel right now."""
    hour = (now or time.localtime()).tm_hour
    chosen = SLOTS[-1][0]  # night, since the day starts inside it
    for name, start in SLOTS:
        if hour >= start:
            chosen = name
    return chosen


def source_ident(path: Path) -> str:
    """Content hash, not mtime.

    An atomic replace gives a new mtime every night even when the RunPod job
    produced a byte-identical file, and the panel should not spend a refresh on
    a picture it is already showing.
    """
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()[:16]


class Library:
    """The converted set, rebuilt in the background as sources change."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._photos: list[Blob] = []
        self._ai: dict[str, Blob] = {}
        OUT_DIR.mkdir(parents=True, exist_ok=True)

    # -- conversion ---------------------------------------------------------
    def _convert(self, src: Path, dither: bool) -> Blob | None:
        # The dither mode is part of the identity, not just the content. The
        # same bytes in the photo directory and the AI directory convert to
        # different blobs -- one error-diffused, one hard-thresholded -- and a
        # cache keyed on content alone serves whichever was converted first.
        ident = source_ident(src) + ("d" if dither else "n")
        out = OUT_DIR / f"{ident}.bin"
        if not out.exists():
            try:
                img = fit(Image.open(src))
            except Exception as exc:  # a half-copied or non-image file
                LOG.warning("skipping %s: %s", src.name, exc)
                return None
            blob = pack(*panelise(img, dither=dither)[1:])
            tmp = out.with_suffix(".bin.tmp")
            tmp.write_bytes(blob)
            os.replace(tmp, out)  # never serve a half-written blob
            LOG.info("converted %s -> %s (%d bytes)", src.name, out.name, len(blob))
        return Blob(ident=ident, path=out, source=src)

    def rescan(self) -> None:
        photos, ai = [], {}

        for src in sorted(p for p in _images(PHOTO_DIR)):
            # Photographs need the error diffusion; see IMAGE-PIPELINE.md.
            blob = self._convert(src, dither=True)
            if blob:
                photos.append(blob)

        for src in _images(AI_DIR):
            # Only the three names we asked for. A stray file in this directory
            # is someone else's, not a slot.
            if src.stem not in AI_NAMES:
                continue
            blob = self._convert(src, dither=False)
            if blob:
                ai[src.stem] = blob

        with self._lock:
            self._photos, self._ai = photos, ai
        self._prune({b.path.name for b in photos} | {b.path.name for b in ai.values()})

    def _prune(self, keep: set[str]) -> None:
        for stale in OUT_DIR.glob("*.bin"):
            if stale.name not in keep:
                stale.unlink(missing_ok=True)
                LOG.info("pruned %s", stale.name)

    # -- selection ----------------------------------------------------------
    def current(self, mode: str) -> Blob | None:
        with self._lock:
            photos, ai = list(self._photos), dict(self._ai)

        if mode.lower().startswith("photo"):
            if not photos:
                return None
            # Deterministic from the clock, so /revision and /next agree without
            # either of them holding a cursor.
            idx = int(time.time() // PHOTO_ROTATE_SECONDS) % len(photos)
            return photos[idx]

        slot = current_slot()
        return ai.get(slot) or next(iter(ai.values()), None)


def _images(directory: Path):
    if not directory.is_dir():
        return
    for entry in directory.iterdir():
        if entry.is_file() and entry.suffix.lower() in SUFFIXES:
            yield entry


class Handler(BaseHTTPRequestHandler):
    library: Library

    def do_GET(self) -> None:  # noqa: N802
        route = urlparse(self.path)
        query = parse_qs(route.query)
        mode = (query.get("mode") or ["AI"])[0]

        if route.path == "/health":
            with self.library._lock:  # noqa: SLF001
                counts = (len(self.library._photos), len(self.library._ai))
            return self._json(200, {
                "ok": True,
                "version": VERSION,
                "photos": counts[0],
                "ai": counts[1],
                "slot": current_slot(),
            })

        if route.path == "/revision":
            blob = self.library.current(mode)
            # An empty revision means "nothing to show". The firmware reads that
            # as unknown and leaves the panel alone rather than refreshing.
            return self._text(200, blob.ident if blob else "")

        if route.path == "/next":
            blob = self.library.current(mode)
            if blob is None:
                return self._json(404, {"ok": False, "error": f"nothing for mode {mode}"})
            data = blob.path.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("X-Eink-Revision", blob.ident)
            self.end_headers()
            self.wfile.write(data)
            return

        if route.path == "/index":
            with self.library._lock:  # noqa: SLF001 — diagnostics only
                return self._json(200, {
                    "photos": [b.source.name for b in self.library._photos],
                    "ai": {k: v.source.name for k, v in self.library._ai.items()},
                    "slot": current_slot(),
                })

        self._json(404, {"ok": False, "error": "no such route"})

    def _json(self, code: int, body: dict) -> None:
        self._raw(code, "application/json", json.dumps(body).encode())

    def _text(self, code: int, body: str) -> None:
        self._raw(code, "text/plain; charset=utf-8", body.encode())

    def _raw(self, code: int, ctype: str, data: bytes) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt: str, *args) -> None:
        LOG.debug("%s - %s", self.address_string(), fmt % args)


def main() -> None:
    logging.basicConfig(
        level=_opt("log_level", "EINK_LOG_LEVEL", "INFO"),
        format="%(asctime)s %(levelname)s %(message)s",
    )
    library = Library()
    library.rescan()
    Handler.library = library

    def scanner() -> None:
        while True:
            time.sleep(SCAN_SECONDS)
            try:
                library.rescan()
            except Exception:
                LOG.exception("rescan failed")

    threading.Thread(target=scanner, daemon=True).start()

    LOG.info("serving on :%d  photos=%s  ai=%s", PORT, PHOTO_DIR, AI_DIR)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main()
