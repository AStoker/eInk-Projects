"""
Sample agendas, in the exact JSON shape packages/agenda.yaml documents:

    {"s": summary, "t": display time, "a": all-day, "m": start min, "n": end min}

`m`/`n` are minutes past local midnight, which is what the layouts sort and
compare against, so a preview at 2:30 PM is `now_min = 870`.
"""


def ev(h, m, dur, summary):
    start = h * 60 + m
    ampm = "AM" if h < 12 else "PM"
    hh = h % 12 or 12
    return {
        "s": summary,
        "t": f"{hh}:{m:02d} {ampm}",
        "a": False,
        "m": start,
        "n": start + dur,
    }


def allday(summary):
    return {"s": summary, "t": "", "a": True, "m": 0, "n": -1}


# A busy-but-real Tuesday: an all-day marker, back-to-back mornings, a gap
# over lunch, and two evening things. Enough rows that every layout has to
# make a decision about what to drop.
BUSY = [
    allday("Trash night"),
    ev(7, 30, 30, "School drop-off"),
    ev(9, 0, 60, "Standup + sprint planning"),
    ev(10, 30, 45, "1:1 with Dana"),
    ev(11, 30, 60, "Design review: panel firmware"),
    ev(13, 0, 30, "Lunch with Sam"),
    ev(14, 30, 90, "Customer call - Whitfield"),
    ev(17, 0, 45, "Soccer practice pickup"),
    ev(19, 0, 60, "Dinner at Mom's"),
]

# The usual case: a handful of things, plenty of white space.
LIGHT = [
    ev(9, 0, 30, "Standup"),
    ev(12, 0, 60, "Lunch with Sam"),
    ev(15, 30, 60, "Dentist"),
    ev(18, 30, 90, "Soccer practice"),
]

# Long titles, to prove the wrap and the truncation.
WORDY = [
    allday("Andrew is out of office"),
    ev(8, 0, 90, "Quarterly planning workshop with the platform team"),
    ev(11, 0, 30, "Coffee"),
    ev(13, 30, 120, "Whitfield onboarding walkthrough and Q&A session"),
    ev(16, 0, 30, "Pick up prescription at the pharmacy on Devine"),
]

EMPTY = []

# A day strewn from 6am to 9:30pm, built to hit every case that bends the
# ruler rather than to look plausible:
#   6:15/7:45/2:35   odd-minute starts, so the :MM marks appear
#   10:00 + 10:45    two events inside one hour band
#   1pm - 3pm        three consecutive empty hours, which is what triggers
#                    the collapse marker
#   9:30 PM          a late item, so early renders have to use the tail
#   the design review is long enough to wrap to two lines
WEDNESDAY = [
    allday("Recycling out"),
    ev(6, 15, 45, "Gym"),
    ev(7, 45, 25, "School drop-off"),
    ev(8, 30, 30, "Standup"),
    ev(9, 10, 60, "Andrew 3D Print Club"),
    ev(10, 0, 30, "1:1 with Dana"),
    ev(10, 45, 45, "Design review: panel firmware and enclosure"),
    ev(11, 30, 30, "Zorro touchpoint"),
    ev(12, 30, 60, "Lunch with Sam"),
    ev(16, 35, 90, "Customer call - Whitfield"),
    ev(18, 0, 45, "Soccer practice pickup"),
    ev(19, 30, 60, "Dinner at Mom's"),
    ev(21, 30, 30, "Take the trash out"),
]

# Deliberately past what the panel can show in hour form: 17 timed events.
# The point is that the layout degrades to a complete list rather than to a
# count, so nothing upcoming is ever hidden behind a "+N more".
PACKED = [allday("Recycling out")] + [
    ev(h, m, 30, t) for h, m, t in [
        (7, 0, "Gym"), (7, 45, "School drop-off"), (8, 30, "Standup"),
        (9, 0, "3D Print Club"), (9, 45, "1:1 with Dana"),
        (10, 30, "Design review: panel firmware"), (11, 0, "Zorro touchpoint"),
        (11, 45, "Vendor sync"), (12, 30, "Lunch with Sam"),
        (13, 30, "Roadmap review"), (14, 30, "Customer call - Whitfield"),
        (15, 30, "Interview: platform eng"), (16, 30, "Retro"),
        (17, 30, "Soccer pickup"), (18, 30, "Dinner at Moms"),
        (20, 0, "Book club"), (21, 30, "Take the trash out")]]

SETS = {"busy": BUSY, "light": LIGHT, "wordy": WORDY, "empty": EMPTY,
        "wednesday": WEDNESDAY, "packed": PACKED}
