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
from datetime import datetime, timedelta
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

import agenda
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
# Saved AI art to cycle through instead of the nightly renders -- a themed set
# kept from earlier generations. Recursive, like photos, so a set can live in a
# subfolder of its own. Converted as art (clamped, red kept), not as a photo.
LIBRARY_DIR = Path(os.environ.get("EINK_LIBRARY_DIR", "/media/eink/ai-library"))
PORT = int(os.environ.get("EINK_PORT", "8100"))
# Reported by /health so a deploy can be confirmed by asking the running
# container what it is, rather than by trusting that the update applied.
VERSION = os.environ.get("EINK_VERSION", "dev")
# Bumped whenever panelise() would turn the same source into different pixels.
# It rides along in every blob's name, so an old blob is never mistaken for
# what the current converter would produce. One character, because it also
# rides along in the revision string the panel stores in 32 bytes.
PIPELINE_REV = "2"
SCAN_SECONDS = int(_opt("scan_seconds", "EINK_SCAN_SECONDS", 20))
# How long one photo stays on the panel. Rotation is on a clock rather than on
# /next so that the revision can be computed without a request having happened —
# otherwise "has the picture changed" could only be answered by changing it.
PHOTO_ROTATE_SECONDS = int(_OPT["photo_rotate_minutes"]) * 60 if "photo_rotate_minutes" in _OPT \
    else int(os.environ.get("EINK_PHOTO_ROTATE_SECONDS", "900"))

# The three AI slots and the local hour each begins. Night wraps midnight.
SLOTS = (("morning", 5), ("day", 11), ("night", 18))

# Which AI source is live. On (or missing) means the nightly job generates and
# AI mode shows morning/day/night; off means the job stands down and AI mode
# cycles LIBRARY_DIR instead. The same helper gates the automation, so one
# switch moves both halves and there is nothing else to undo to go back.
GENERATE_SWITCH = "input_boolean.eink_daily_dash_generate_ai"
# How long one library picture stays up. 0 steps at each AI slot boundary --
# three pictures a day, the same refresh budget the generated set spends.
LIBRARY_ROTATE_SECONDS = int(_opt("library_rotate_minutes", "EINK_LIBRARY_ROTATE_MINUTES", 0)) * 60
AI_NAMES = {"morning", "day", "night"}

SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif", ".tif", ".tiff"}

# Today's agenda, assembled here and pushed to Core for the panel to subscribe
# to. Calendars are opt-in and listed explicitly; an empty list switches the
# feature off, which is what running outside Supervisor gets you.
AGENDA_CALENDARS = _OPT.get("agenda_calendars") or []
AGENDA_ENTITY = _opt("agenda_entity", "EINK_AGENDA_ENTITY", "sensor.esp_day_agenda")
AGENDA_SECONDS = int(_opt("agenda_refresh_minutes", "EINK_AGENDA_REFRESH_MINUTES", 5)) * 60


@dataclass(frozen=True)
class Blob:
    """One converted image, ready to serve."""

    ident: str  # content hash of the source; also the revision
    path: Path  # the .bin on disk
    source: Path


def current_slot(hour: int | None = None) -> str:
    """Which AI image belongs on the panel right now.

    The hour comes from Home Assistant's timezone rather than the container's.
    Nothing sets TZ in here -- Supervisor does not pass one and the base is
    plain Alpine -- so the container clock is UTC, and picking slots on it puts
    the morning image up at 1am. `agenda.timezone()` caches after its first
    answer, so this costs one call, not one per request.
    """
    if hour is None:
        hour = datetime.now(agenda.timezone()).hour
    chosen = SLOTS[-1][0]  # night, since the day starts inside it
    for name, start in SLOTS:
        if hour >= start:
            chosen = name
    return chosen


def library_index(count: int, offset: int = 0) -> int:
    """Which library picture is current, from the clock alone.

    Stateless for the same reason photo rotation is: /revision and /next must
    agree, and asking what is current must not change it. In slot mode the
    step counts slots since a fixed day, with the day starting at the morning
    slot so the small hours still belong to the previous night.
    """
    if LIBRARY_ROTATE_SECONDS:
        step = int(time.time() // LIBRARY_ROTATE_SECONDS)
    else:
        now = datetime.now(agenda.timezone())
        day = (now - timedelta(hours=SLOTS[0][1])).date().toordinal()
        names = [name for name, _ in SLOTS]
        step = day * len(SLOTS) + names.index(current_slot(now.hour))
    return (step + offset) % count


def generating(previous: bool) -> bool:
    """Whether the generate switch is on, keeping the last answer on a miss.

    A Core blip must not flip the panel between sources, so an unanswered
    lookup keeps what was known. No helper at all counts as on: that is how
    this ran before the library existed.
    """
    if not agenda.TOKEN:
        return previous
    got = agenda._call(f"states/{GENERATE_SWITCH}", quiet=True)  # noqa: SLF001
    if got is None:
        return previous
    if isinstance(got, dict) and got.get("state") == "off":
        return False
    return True


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
        self._library: list[Blob] = []
        self._generate = True
        OUT_DIR.mkdir(parents=True, exist_ok=True)

    # -- conversion ---------------------------------------------------------
    def _convert(self, src: Path, kind: str) -> Blob | None:
        # The conversion is part of the identity, not just the content. The
        # same bytes in the photo directory and the AI directory convert to
        # different blobs, and a cache keyed on content alone would serve
        # whichever happened to be converted first. PIPELINE_REV is in there
        # for the same reason across time: a converter change gives the same
        # source a new name, so the cache rebuilds and the panel is told the
        # picture moved -- without it, every photo already on disk would keep
        # serving the blob the old converter made.
        ident = source_ident(src) + kind[0] + PIPELINE_REV
        out = OUT_DIR / f"{ident}.bin"
        if not out.exists():
            try:
                img = fit(Image.open(src))
            except Exception as exc:  # a half-copied or non-image file
                LOG.warning("skipping %s: %s", src.name, exc)
                return None
            # Both are dithered. Generated art is clamped first: its "white"
            # paper sits around luminance 230 and its ink around 10, and
            # without pulling those two flats to the rails the error diffusion
            # treats the background as a tone to reproduce and speckles the
            # whole sky. Clamped, the flats come out clean and the diffusion is
            # spent where it earns something -- the mid-tones that give a storm
            # cloud its depth. A photograph wants its full tonal range, so it
            # is not clamped.
            #
            # Red is for generated art only. There it is one named object the
            # prompt asked for, so it lands as an accent. A photograph has red
            # scattered through it at whatever saturation the light gave it,
            # and the gate then catches some of it and not the rest -- a face
            # gets a red patch, a jacket goes half red and half dithered. Black
            # and white throughout is the honest rendering of a photograph.
            art = kind == "art"
            blob = pack(*panelise(img, dither=True, clamp=art, red=art)[1:])
            tmp = out.with_suffix(".bin.tmp")
            tmp.write_bytes(blob)
            os.replace(tmp, out)  # never serve a half-written blob
            LOG.info("converted %s -> %s (%d bytes)", src.name, out.name, len(blob))
        return Blob(ident=ident, path=out, source=src)

    def rescan(self) -> None:
        photos, ai = [], {}

        for src in sorted(_images(PHOTO_DIR, recursive=True)):
            if not _settled(src):
                LOG.info("still copying, will pick up next scan: %s", src.name)
                continue
            blob = self._convert(src, "photo")
            if blob:
                photos.append(blob)

        for src in _images(AI_DIR):
            # Only the three names we asked for. A stray file in this directory
            # is someone else's, not a slot.
            if src.stem not in AI_NAMES:
                continue
            blob = self._convert(src, "art")
            if blob:
                ai[src.stem] = blob

        library = []
        for src in sorted(_images(LIBRARY_DIR, recursive=True)):
            if not _settled(src):
                LOG.info("still copying, will pick up next scan: %s", src.name)
                continue
            blob = self._convert(src, "art")
            if blob:
                library.append(blob)

        generate = generating(self._generate)
        if generate != self._generate:
            LOG.info("AI source -> %s", "generated" if generate else "library")

        with self._lock:
            self._photos, self._ai = photos, ai
            self._library, self._generate = library, generate
        self._prune({b.path.name for b in photos}
                    | {b.path.name for b in ai.values()}
                    | {b.path.name for b in library})

    def _prune(self, keep: set[str]) -> None:
        for stale in OUT_DIR.glob("*.bin"):
            if stale.name not in keep:
                stale.unlink(missing_ok=True)
                LOG.info("pruned %s", stale.name)

    # -- selection ----------------------------------------------------------
    def current(self, mode: str, offset: int = 0) -> Blob | None:
        with self._lock:
            photos, ai = list(self._photos), dict(self._ai)
            library, generate = list(self._library), self._generate

        if mode.lower().startswith("photo"):
            if not photos:
                return None
            # Clock plus offset. The clock keeps it rotating on its own; the
            # offset is what Next/Previous moves, and because both come from
            # the caller rather than from state held here, /revision and /next
            # always agree -- asking what is current cannot change it.
            idx = (int(time.time() // PHOTO_ROTATE_SECONDS) + offset) % len(photos)
            return photos[idx]

        # Library when generation is switched off. An empty library falls back
        # to whatever was last generated rather than blanking the panel.
        if not generate and library:
            return library[library_index(len(library), offset)]

        slot = current_slot()
        return ai.get(slot) or next(iter(ai.values()), None)


def _images(directory: Path, recursive: bool = False):
    """Image files in a directory.

    Photos recurse, so albums in subfolders work without anyone having to
    flatten them. The AI directory does not: it holds exactly three known
    names beside the RunPod app's own output.
    """
    if not directory.is_dir():
        return
    walker = directory.rglob("*") if recursive else directory.iterdir()
    for entry in walker:
        if not entry.is_file() or entry.suffix.lower() not in SUFFIXES:
            continue
        # Skip the junk that turns up on a network share, and anything that
        # looks like a partial copy.
        if entry.name.startswith((".", "._")) or entry.suffix.lower() == ".tmp":
            continue
        yield entry


def _settled(path: Path) -> bool:
    """True once the file has stopped growing.

    Dropping a photo over Samba arrives as a series of writes, so a scan can
    catch it half-written. The RunPod side replaces atomically and never needs
    this, but a person dragging a folder in does.
    """
    try:
        first = path.stat().st_size
        time.sleep(0.4)
        return first > 0 and first == path.stat().st_size
    except OSError:
        return False


class Handler(BaseHTTPRequestHandler):
    library: Library
    agenda: dict | None = None

    def do_GET(self) -> None:  # noqa: N802
        route = urlparse(self.path)
        query = parse_qs(route.query)
        mode = (query.get("mode") or ["AI"])[0]
        try:
            offset = int((query.get("offset") or ["0"])[0])
        except ValueError:
            offset = 0

        if route.path == "/health":
            with self.library._lock:  # noqa: SLF001
                lib = self.library
                counts = (len(lib._photos), len(lib._ai), len(lib._library))
                generate = lib._generate
            return self._json(200, {
                "ok": True,
                "version": VERSION,
                "photos": counts[0],
                "ai": counts[1],
                "library": counts[2],
                "ai_source": "generated" if generate or not counts[2] else "library",
                "slot": current_slot(),
            })

        if route.path == "/revision":
            blob = self.library.current(mode, offset)
            # An empty revision means "nothing to show". The firmware reads that
            # as unknown and leaves the panel alone rather than refreshing.
            return self._text(200, blob.ident if blob else "")

        if route.path == "/next":
            blob = self.library.current(mode, offset)
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

        if route.path == "/agenda":
            # Diagnostics: what the last push contained and which calendars
            # were switched on when it was built.
            return self._json(200, self.agenda or {"enabled": False})

        if route.path == "/index":
            with self.library._lock:  # noqa: SLF001 — diagnostics only
                return self._json(200, {
                    "photos": [b.source.name for b in self.library._photos],
                    "ai": {k: v.source.name for k, v in self.library._ai.items()},
                    "library": [b.source.name for b in self.library._library],
                    "generate": self.library._generate,
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

    # The agenda is pushed rather than pulled, so it runs on its own clock. It
    # publishes once at startup because the entity is state-only and does not
    # survive a Core restart -- this is what puts it back.
    def agenda_loop() -> None:
        while True:
            try:
                Handler.agenda = agenda.refresh(AGENDA_CALENDARS, AGENDA_ENTITY)
            except Exception:
                LOG.exception("agenda refresh failed")
            time.sleep(AGENDA_SECONDS)

    if AGENDA_CALENDARS:
        threading.Thread(target=agenda_loop, daemon=True).start()
    else:
        LOG.info("agenda disabled: no calendars configured")

    LOG.info("serving on :%d  photos=%s  ai=%s  library=%s", PORT, PHOTO_DIR, AI_DIR, LIBRARY_DIR)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main()
