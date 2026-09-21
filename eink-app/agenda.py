"""eInk Daily Dash — today's agenda, assembled for the panel.

Home Assistant holds the calendars; the panel holds 300x400 pixels and no
calendar arithmetic. This module is the bridge. It asks Core for today's events
across the configured calendars, flattens them into the compact JSON the
display lambda parses, and writes the result back to Core as a sensor the panel
subscribes to.

The count goes in the state and the events go in the `entries` attribute,
because Core caps entity states at 255 characters and a full day blows past
that. The JSON shape is documented in ../daily-dash/packages/agenda.yaml and
parsed in ../daily-dash/packages/display.yaml; those two files and this one
have to agree.

Living here rather than in a Jinja template means the agenda is Python in the
same repo as the firmware that consumes it, so the two change together, and a
payload can be replayed through daily-dash/tools/preview to see what the glass
will show before it goes near the glass.
"""

from __future__ import annotations

import json
import logging
import os
import urllib.error
import urllib.request
from datetime import date, datetime, timedelta

LOG = logging.getLogger("eink.agenda")

# Supervisor injects this for any app whose manifest sets `homeassistant_api`.
# Its absence is what tells us we are running from a terminal rather than under
# Supervisor, which is the same signal the rest of the server uses.
TOKEN = os.environ.get("SUPERVISOR_TOKEN", "")
CORE = os.environ.get("EINK_CORE_URL", "http://supervisor/core/api")

# Spelled out rather than taken from strftime: the image is Alpine, whose musl
# strftime has neither the `%-d` width flag nor a populated locale, so the
# obvious format strings would come back padded or empty.
MONTHS = ("January", "February", "March", "April", "May", "June", "July",
          "August", "September", "October", "November", "December")
DAYS = ("Monday", "Tuesday", "Wednesday", "Thursday",
        "Friday", "Saturday", "Sunday")

# Each configured calendar is gated by `input_boolean.<prefix><its slug>`, so
# calendar.tricias_routine answers to input_boolean.eink_dash_cal_tricias_routine.
SWITCH_PREFIX = "eink_dash_cal_"


def _call(path: str, payload: dict | None = None, params: str = "",
          quiet: bool = False) -> object:
    """One Core API call. Returns None rather than raising on failure.

    A calendar that is unavailable, a token that has expired, and Core still
    starting up all look the same from here: something to log and retry on the
    next tick, not something to take the image server down over. `quiet` is for
    the lookups where absence is an expected answer rather than a fault.
    """
    url = f"{CORE}/{path}{params}"
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(
        url,
        data=data,
        method="POST" if data is not None else "GET",
        headers={
            "Authorization": f"Bearer {TOKEN}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return json.loads(resp.read() or b"null")
    except (urllib.error.URLError, OSError, ValueError) as exc:
        if not quiet:
            LOG.warning("core call %s failed: %s", path, exc)
        return None


def _slug(entity: str) -> str:
    return entity.split(".", 1)[-1]


def switch_for(entity: str) -> str:
    """The helper that turns one calendar on and off."""
    return f"input_boolean.{SWITCH_PREFIX}{_slug(entity)}"


def enabled(calendars: list[str]) -> list[str]:
    """The configured calendars that are currently switched on.

    A calendar whose switch does not exist counts as on. The switches are an
    override rather than a registry, so adding a calendar to the app's options
    puts it on the panel straight away, and the helper only has to exist for
    the ones anyone actually wants to turn off.
    """
    live = []
    for entity in calendars:
        got = _call(f"states/{switch_for(entity)}", quiet=True)
        if isinstance(got, dict) and got.get("state") == "off":
            continue
        live.append(entity)
    return live


def _boundary(value: str) -> date | datetime:
    """A calendar boundary, which is a bare date for an all-day event.

    Timed boundaries come back with Core's own UTC offset; converting to local
    makes the minute arithmetic below independent of what the container thinks
    its timezone is.
    """
    if "T" not in value:
        return date.fromisoformat(value)
    return datetime.fromisoformat(value).astimezone()


def _is_all_day(value: date | datetime) -> bool:
    # datetime subclasses date, so the isinstance has to go the other way.
    return not isinstance(value, datetime)


def _clock(when: datetime) -> str:
    hour = when.hour % 12 or 12
    return f"{hour}:{when.minute:02d} {'AM' if when.hour < 12 else 'PM'}"


def fetch(calendars: list[str], day: date) -> tuple[list[dict], int]:
    """Every event touching `day`, and how many calendars answered.

    The count is what lets the caller tell a day with nothing on it from a day
    Core would not talk about; both produce no events.

    Asked for one calendar at a time on purpose. A combined call fails whole
    when any single calendar is unavailable, and an unavailable calendar is a
    normal state -- a Google integration reauthing takes out the whole agenda
    otherwise. One at a time, a broken calendar costs only its own events.
    """
    start = datetime.combine(day, datetime.min.time())
    window = {
        "start_date_time": start.strftime("%Y-%m-%d %H:%M:%S"),
        "end_date_time": (start + timedelta(days=1)).strftime("%Y-%m-%d %H:%M:%S"),
    }

    found: list[dict] = []
    answered = 0
    for entity in calendars:
        body = dict(window, entity_id=entity)
        got = _call("services/calendar/get_events", body, "?return_response")
        if not isinstance(got, dict):
            continue
        answered += 1
        # The REST shape is {"service_response": {"calendar.x": {"events": []}}}.
        response = got.get("service_response") or {}
        for per_entity in response.values():
            found.extend(per_entity.get("events") or [])
    return found, answered


def entries(events: list[dict], day: date) -> list[dict]:
    """The events as the panel wants them, in time order.

    Core answers a one-day window with anything it considers nearby, which
    includes multi-day events that have not started yet, so membership in the
    day is decided here rather than trusted from the query.
    """
    out: list[dict] = []
    midnight = datetime.combine(day, datetime.min.time()).astimezone()
    tomorrow = midnight + timedelta(days=1)

    for event in events:
        try:
            start = _boundary(event["start"])
            end = _boundary(event["end"])
        except (KeyError, TypeError, ValueError):
            LOG.warning("skipping unparseable event: %r", event)
            continue

        # A summary arrives however it was typed into the calendar, and a
        # trailing space survives into the list's truncation, where it shows up
        # as a gap before the ellipsis.
        summary = (event.get("summary") or "").strip() or "(no title)"

        if _is_all_day(start):
            # An all-day end is exclusive: a single day runs 21st to 22nd.
            if not (start <= day < end):
                continue
            out.append({"a": True, "m": -1, "n": -1, "s": summary, "t": ""})
            continue

        if end <= midnight or start >= tomorrow:
            continue

        # Clamped to the day, because the panel draws minutes past local
        # midnight on a 24-hour ruler and has nowhere to put an event that
        # began yesterday. The firmware carries anything still running into the
        # current hour band, so a clamped start lands where it belongs.
        m = max(0, int((start - midnight).total_seconds() // 60))
        n = min(1439, int((end - midnight).total_seconds() // 60))
        out.append({"a": False, "m": m, "n": max(m, n), "s": summary,
                    "t": _clock(start)})

    # All-day first, then by start time -- the order the panel draws them in.
    out.sort(key=lambda e: (not e["a"], e["m"]))
    return out


def publish(entity: str, payload: list[dict], day: date) -> bool:
    """Write the agenda back to Core as `entity`.

    POST /api/states creates a state-only entity, which means it does not
    survive a Core restart. That is why the refresh loop pushes on startup and
    then on a cadence rather than only when something changes: the entity
    reappears on the next tick without anyone intervening.
    """
    body = {
        "state": str(len(payload)),
        "attributes": {
            "entries": json.dumps(payload, ensure_ascii=False),
            "day_name": DAYS[day.weekday()],
            "date_line": f"{MONTHS[day.month - 1]} {day.day}, {day.year}",
            "icon": "mdi:calendar-today",
            "friendly_name": "ESP Day Agenda",
        },
    }
    return _call(f"states/{entity}", body) is not None


def refresh(calendars: list[str], entity: str) -> dict:
    """One full cycle: read the switches, ask Core, flatten, write back.

    The switches are read every cycle rather than cached, which is what makes
    turning a calendar off show up on the panel within one refresh instead of
    requiring the app to be restarted.
    """
    day = datetime.now().astimezone().date()
    live = enabled(calendars)
    events, answered = fetch(live, day)

    if live and not answered:
        # Every calendar failed. Publishing now would publish an empty day, and
        # an empty day is indistinguishable on the glass from a clear one --
        # leaving the last good agenda up is the honest failure.
        LOG.warning("agenda: no calendar answered; leaving the last agenda in place")
        return {"day": day.isoformat(), "published": False,
                "error": "no calendar answered"}

    payload = entries(events, day)
    published = publish(entity, payload, day)
    if published:
        LOG.info("agenda: %d events for %s from %d/%d calendars",
                 len(payload), day, len(live), len(calendars))
    return {
        "day": day.isoformat(),
        "published": published,
        "calendars": {c: (c in live) for c in calendars},
        "entries": payload,
    }
