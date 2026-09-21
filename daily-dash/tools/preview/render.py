#!/usr/bin/env python3
"""
Render a dash layout to PNG.

    ./render.py                          # every layout, every sample time
    ./render.py -l b -s busy -t 14:30    # one frame
    ./render.py -l b --day               # one layout across the whole day

Output lands in tools/preview/out/. Nothing here touches the firmware; it is
a drawing board for the lambda.
"""

import argparse
import datetime as dt
from pathlib import Path

import dashsim
import layouts
import sample

OUT = Path(__file__).resolve().parent / "out"


def load_json(path):
    """An agenda dumped straight from the Home Assistant attribute, so a real
    day can be previewed without being committed as a sample."""
    import json
    events = json.loads(Path(path).read_text())
    sample.SETS["json"] = events
    return "json"


class Now(dt.datetime):
    """datetime plus the one field ESPTime has and datetime does not."""

    def weekday_sun(self):
        return (self.weekday() + 1) % 7

    @property
    def day_of_month(self):
        return self.day


def at(hhmm, date=dt.date(2026, 9, 22)):
    h, m = (int(x) for x in hhmm.split(":"))
    if isinstance(date, str):
        date = dt.date(*(int(x) for x in date.split("-")))
    return Now(date.year, date.month, date.day, h, m)


def render(key, evset, when, scale=2):
    it = dashsim.Canvas()
    it.fill(dashsim.WHITE)
    layouts.LAYOUTS[key](it, sample.SETS[evset], when)
    path = OUT / "frames" / f"{key}-{evset}-{when.strftime('%H%M')}.png"
    return it.save(path, scale=scale)


def sheets():
    """The curated set, numbered in the order they are worth looking at.

    Regenerating is the only supported way to fill out/ -- ad-hoc renders from
    several revisions of a layout sitting side by side is how the directory
    stops being reviewable.
    """
    for f in OUT.rglob("*.png"):
        f.unlink()

    # 1. The three directions, on the same busy afternoon.
    dashsim.contact_sheet(
        [render(k, "busy", at("14:50"), 1) for k in layouts.LAYOUTS],
        OUT / "1-three-options.png", cols=3,
        labels=[layouts.NAMES[k] for k in layouts.LAYOUTS])

    # 2. The chosen layout scrolling through a day.
    times = ["07:00", "09:20", "11:45", "14:50", "17:10", "19:30"]
    dashsim.contact_sheet(
        [render("b", "busy", at(t), 1) for t in times],
        OUT / "2-hour-ruler-across-the-day.png", cols=3, labels=times)

    # 3. The cases that break layouts: a quiet day, long titles, nothing left.
    cases = [("light", "16:05"), ("wordy", "06:30"), ("empty", "20:30")]
    dashsim.contact_sheet(
        [render("b", s, at(t), 1) for s, t in cases],
        OUT / "3-hour-ruler-edge-cases.png", cols=3,
        labels=[f"{s} day, {t}" for s, t in cases])

    # 4. A day strewn from dawn to bedtime -- the one that found the carried
    #    event, the collapsed current hour and the mis-indexed tail.
    times = ["06:00", "10:20", "13:15", "16:50", "20:00", "21:45"]
    dashsim.contact_sheet(
        [render("b", "wednesday", at(t, "2026-09-23"), 1) for t in times],
        OUT / "4-wednesday-strewn.png", cols=3, labels=times)

    # 5. More than the panel can hold in hour form, to prove the fallback.
    times = ["06:30", "09:00", "12:00", "15:00"]
    dashsim.contact_sheet(
        [render("b", "packed", at(t, "2026-09-23"), 1) for t in times],
        OUT / "5-overloaded-day.png", cols=4, labels=times)

    for f in sorted(OUT.glob("[0-9]-*.png")):
        print(f)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("-l", "--layout", default=None, choices=list(layouts.LAYOUTS))
    p.add_argument("-s", "--set", default="busy", choices=list(sample.SETS))
    p.add_argument("-t", "--time", default="08:15")
    p.add_argument("-d", "--date", default="2026-09-22", help="YYYY-MM-DD")
    p.add_argument("--from-json", default=None,
                   help="a file holding the agenda JSON array, used as the set")
    p.add_argument("--day", action="store_true", help="one layout across the day")
    p.add_argument("--sheets", action="store_true",
                   help="the three numbered review sheets, and nothing else")
    p.add_argument("--scale", type=int, default=2)
    a = p.parse_args()

    if a.sheets:
        sheets()
        return

    evset = load_json(a.from_json) if a.from_json else a.set
    keys = [a.layout] if a.layout else list(layouts.LAYOUTS)

    if a.day:
        times = ["07:00", "09:20", "11:45", "14:50", "17:10", "19:30"]
        for k in keys:
            paths = [render(k, evset, at(t, a.date), a.scale) for t in times]
            out = dashsim.contact_sheet(
                paths, OUT / f"day-{k}-{a.set}.png", cols=3, labels=times)
            print(out)
        return

    paths, labels = [], []
    for k in keys:
        paths.append(render(k, evset, at(a.time, a.date), a.scale))
        labels.append(layouts.NAMES[k])
    if len(paths) > 1:
        print(dashsim.contact_sheet(
            paths, OUT / f"compare-{evset}-{a.time.replace(':', '')}.png",
            cols=3, labels=labels))
    else:
        print(paths[0])


if __name__ == "__main__":
    main()
