"""
Candidate dash layouts, drawn against the Canvas shim so each one previews as
a PNG before it becomes a lambda.

All three share one rule the current firmware does not have: a finished event
is GONE, not struck through. The panel is for what is still ahead. All-day
events are the exception -- they pin to the top all day, because "trash night"
stops being useful only at bedtime.
"""

from dashsim import BLACK, RED, WHITE, H, W, font

F = lambda w, s: font("Roboto", w, s)


# ---------------------------------------------------------------------------
# shared pieces
# ---------------------------------------------------------------------------

DOW = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
MON = ["January", "February", "March", "April", "May", "June", "July",
       "August", "September", "October", "November", "December"]


def split(events, now_min):
    """Upcoming events, all-day events, and how many the day has finished."""
    timed = [e for e in events if not e["a"]]
    allday = [e for e in events if e["a"]]
    upcoming = [e for e in timed if e["n"] > now_min]
    done = len(timed) - len(upcoming)
    return upcoming, allday, done


def live(e, now_min):
    return e["m"] <= now_min < e["n"]


def clock(now):
    return now.strftime("%-I:%M %p").lower()


def header_banner(it, now, remaining):
    """Reverse-video date bar. Costs 56 px and reads from across the room --
    the black field is what makes the white weekday legible at 26 px without
    a heavier face."""
    it.filled_rectangle(0, 0, W, 56, BLACK)
    it.print(12, 8, F(700, 30), WHITE, "TOP_LEFT", DOW[now.weekday_sun()][:3])
    it.print(78, 4, F(300, 40), WHITE, "TOP_LEFT", str(now.day))
    it.print(W - 12, 10, F(400, 14), WHITE, "TOP_RIGHT", MON[now.month - 1].upper())
    it.print(W - 12, 30, F(700, 16), RED, "TOP_RIGHT",
             f"{remaining} LEFT" if remaining else "CLEAR")


def header_split(it, now, remaining):
    """The current header's proportions, with the type pushed up a size."""
    it.print(12, -4, F(300, 58), RED, "TOP_LEFT", str(now.day))
    it.print(86, 6, F(700, 25), BLACK, "TOP_LEFT", DOW[now.weekday_sun()])
    it.print(86, 36, F(400, 16), RED, "TOP_LEFT", f"{MON[now.month - 1]} {now.year}")
    it.line(12, 62, W - 12, 62, BLACK)


def footer(it, now, left, note=""):
    it.line(12, 380, W - 12, 380, BLACK)
    it.print(12, H - 4, F(400, 13), BLACK, "BOTTOM_LEFT", note)
    it.print(W - 12, H - 4, F(700, 13), BLACK, "BOTTOM_RIGHT", clock(now))


def allday_chips(it, it_allday, y):
    """All-day items as a red-ruled strip, not as list rows -- they have no
    place on a time axis and stealing a row each would push real events off."""
    if not it_allday:
        return y
    for e in it_allday:
        it.filled_rectangle(12, y + 3, 6, 6, RED)
        lines = it.wrap(F(700, 17), e["s"], W - 40, 1)
        it.print(26, y - 3, F(700, 17), BLACK, "TOP_LEFT", lines[0])
        y += 22
    return y + 4


def empty_day(it, y, done):
    it.print(W // 2, y + 60, F(300, 30), BLACK, "TOP_CENTER",
             "All done" if done else "Nothing on")
    it.print(W // 2, y + 98, F(400, 16), RED, "TOP_CENTER",
             "for today" if done else "today")


# ===========================================================================
# OPTION A -- NOW & NEXT
# ===========================================================================
# One thing is huge and the rest is a list. Reading the panel at a glance
# answers "what am I supposed to be doing" without reading anything at all;
# the list underneath answers "and then what".
#
# The hero is whatever is happening now, or, if nothing is, the next thing up
# with a countdown. Past events are simply absent.
# ===========================================================================

def option_a(it, events, now):
    now_min = now.hour * 60 + now.minute
    upcoming, ad, done = split(events, now_min)

    header_banner(it, now, len(upcoming))
    y = 66
    y = allday_chips(it, ad, y)

    if not upcoming:
        empty_day(it, y, done)
        footer(it, now, 0)
        return

    hero, rest = upcoming[0], upcoming[1:]
    is_live = live(hero, now_min)
    mins = hero["m"] - now_min

    # --- the hero block ---------------------------------------------------
    it.filled_rectangle(12, y, W - 24, 3, RED)
    y += 12

    tag = "NOW" if is_live else (f"IN {mins} MIN" if mins < 60
                                 else f"IN {mins // 60}H {mins % 60:02d}M")
    it.print(12, y, F(700, 15), RED, "TOP_LEFT", tag)
    it.print(W - 12, y - 4, F(700, 24), BLACK, "TOP_RIGHT", hero["t"])
    y += 24

    for ln in it.wrap(F(400, 30), hero["s"], W - 24, 2):
        it.print(12, y, F(400, 30), BLACK, "TOP_LEFT", ln)
        y += 34
    y += 6
    it.line(12, y, W - 12, y, BLACK)
    y += 10

    # --- everything after it ----------------------------------------------
    if rest:
        it.print(12, y, F(700, 13), RED, "TOP_LEFT", "THEN")
        y += 20

    shown = 0
    for e in rest:
        lines = it.wrap(F(400, 21), e["s"], W - 92, 2)
        h = len(lines) * 23 + 8
        if y + h > 372:
            break
        it.print(12, y + 2, F(700, 15), BLACK, "TOP_LEFT", e["t"].replace(" ", ""))
        for k, ln in enumerate(lines):
            it.print(84, y + k * 23, F(400, 21), BLACK, "TOP_LEFT", ln)
        y += h
        shown += 1

    hidden = len(rest) - shown
    footer(it, now, len(upcoming), f"+{hidden} more later" if hidden else "")


# ===========================================================================
# OPTION B -- THE HOUR RULER
# ===========================================================================
# The literal reading of the ask: a day column that scrolls down on the hour.
# The top band is always the hour it is now, so the panel's top edge IS the
# present moment and everything below it is future.
#
# Empty hours are kept but thin, so the SHAPE of the day survives -- a two
# hour gap looks like a gap. Runs of three or more empty hours collapse to a
# single break marker when the day would otherwise overflow, which is what
# lets a 7am render still reach 9pm.
# ===========================================================================

def short_time(e):
    """Compact enough for the list: 5p, 7:30a, 12p."""
    h, m = e["m"] // 60, e["m"] % 60
    hh = h % 12 or 12
    mer = "a" if h < 12 else "p"
    return f"{hh}:{m:02d}{mer}" if m else f"{hh}{mer}"


def option_b(it, events, now):
    now_min = now.hour * 60 + now.minute
    upcoming, ad, done = split(events, now_min)

    header_split(it, now, len(upcoming))
    y0 = 70
    y0 = allday_chips(it, ad, y0)

    if not upcoming:
        empty_day(it, y0, done)
        footer(it, now, 0)
        return

    GUT      = 46     # hour-label gutter, shared by the ruler and the list
    Y_MAX    = 374
    EMPTY_H  = 17
    BREAK_H  = 15
    EV_LH    = 24     # one line of event title in the ruler
    LIST_HDR = 20     # the LATER TODAY label
    avail    = Y_MAX - y0

    def band_hour(e):
        h = e["m"] // 60
        return h if h > now.hour else now.hour

    def bucket(h):
        return [e for e in upcoming if band_hour(e) == h]

    def wrap_ev(e):
        return it.wrap(F(400, 22), e["s"], W - GUT - 16, 2)

    def band_h(h):
        evs = bucket(h)
        if not evs:
            return EMPTY_H
        total = 6
        for e in evs:
            total += len(wrap_ev(e)) * EV_LH + 8 + 12
        return total

    last_end = max(e["n"] for e in upcoming)
    end_h = max((last_end + 59) // 60, now.hour + 4)
    hours = list(range(now.hour, min(23, end_h) + 1))

    # --- the full ruler, with empty runs collapsed only if it overflows -----
    bands = [(h, band_h(h)) for h in hours]
    for run_min in (3, 2):
        if sum(b for _, b in bands) <= avail:
            break
        out, i = [], 0
        while i < len(bands):
            j = i
            while (j < len(bands) and bands[j][0] is not None
                   and bands[j][0] != now.hour and not bucket(bands[j][0])):
                j += 1
            if j - i >= run_min:
                out.append((None, BREAK_H))
            else:
                out.extend(bands[i:j])
            if j < len(bands):
                out.append(bands[j])
            i = j + 1
        if len(out) == len(bands):
            break
        bands = out

    def trimmed(prefix):
        """A prefix of bands with trailing blanks dropped -- a ruler that ends
        on three empty hours is spending height on nothing."""
        out = list(prefix)
        while out and (out[-1][0] is None or not bucket(out[-1][0])):
            out.pop()
        return out

    def drawn_by(prefix):
        seen = set()
        for h, _ in prefix:
            if h is not None:
                for e in bucket(h):
                    seen.add(id(e))
        return seen

    # --- how much ruler fits, given that the rest must still be listed ------
    # Preference order: readable list rows first, then as many hour bands as
    # will fit underneath that. The list is never truncated and never counts,
    # so a packed morning simply gets fewer hours and more rows.
    plan, rest, LH = None, None, 16
    for lh in (16, 13):
        for k in range(len(bands), -1, -1):
            cand = trimmed(bands[:k])
            left = [e for e in upcoming if id(e) not in drawn_by(cand)]
            need = sum(b for _, b in cand)
            if left:
                need += LIST_HDR + len(left) * lh
            if need <= avail:
                plan, rest, LH = cand, left, lh
                break
        if plan is not None:
            break

    if plan is None:
        # A day too full for even a 12 px row each. Shrink the rows to whatever
        # divides the space -- still every event, still no count.
        plan, rest = [], list(upcoming)
        LH = max(9, (avail - LIST_HDR) // max(len(rest), 1))  # crowds, but shows

    # The list is anchored to the footer, so any slack left after both are
    # placed opens as a hole between them. Give it to the ruler: to the empty
    # hours if there are any, otherwise to the last band, which just means the
    # ruler closes where the list begins.
    used = sum(b for _, b in plan)
    if rest:
        used += LIST_HDR + len(rest) * LH
    slack = avail - used
    if plan and slack > 0:
        gaps = [i for i, (h, _) in enumerate(plan) if h is None or not bucket(h)]
        if gaps:
            add = min(slack // len(gaps), 46)
            plan = [(h, b + add) if i in gaps else (h, b)
                    for i, (h, b) in enumerate(plan)]
            slack -= add * len(gaps)
        if slack > 0 and rest:
            plan[-1] = (plan[-1][0], plan[-1][1] + slack)

    # --- draw the ruler ----------------------------------------------------
    y = y0
    for h, bh in plan:
        if h is None:
            for k in range(3):
                it.filled_rectangle(GUT - 13, y + 2 + k * 5, 2, 2, BLACK)
            y += bh
            continue

        evs = bucket(h)
        hh = h % 12 or 12
        is_now = h == now.hour
        c_hour = RED if is_now else BLACK

        it.line(GUT, y, W - 12, y, c_hour)
        it.print(GUT - 10, y - 4 if evs else y - 2,
                 F(700, 20) if evs else F(400, 15), c_hour, "TOP_RIGHT", str(hh))
        if evs:
            it.print(GUT - 10, y + 17, F(400, 11), c_hour, "TOP_RIGHT",
                     "am" if h < 12 else "pm")

        if is_now:
            ny = y + int(bh * (now.minute / 60.0))
            for k in range(7):
                it.filled_rectangle(k, ny - (6 - k), 1, 2 * (6 - k) + 1, RED)

        ey = y + 4
        for e in evs:
            lines = wrap_ev(e)
            c = RED if live(e, now_min) else BLACK
            if live(e, now_min):
                it.filled_rectangle(GUT + 2, ey, 4, len(lines) * EV_LH, RED)
            for k, ln in enumerate(lines):
                it.print(GUT + 12, ey + k * EV_LH, F(400, 22), c, "TOP_LEFT", ln)
            ey += len(lines) * EV_LH
            eh, em = e["n"] // 60, e["n"] % 60
            it.print(GUT + 12, ey - 3, F(700, 12), c, "TOP_LEFT",
                     "%d:%02d - %d:%02d" % (e["m"] // 60 % 12 or 12, e["m"] % 60,
                                            eh % 12 or 12, em))
            ey += 12 + 6
        y += bh

    if plan:
        it.line(GUT, y, W - 12, y, BLACK)

    # --- everything the ruler could not hold, in full ----------------------
    if rest:
        # With no ruler above it the list is the whole screen, so it starts at
        # the top; under a ruler it hangs off the footer instead.
        ly = (y0 + LIST_HDR if not plan
              else Y_MAX - (LIST_HDR + len(rest) * LH) + LIST_HDR)
        it.print(12, ly - 17, F(700, 11), RED, "TOP_LEFT", "LATER TODAY")
        tsz = 13 if LH >= 16 else 11
        tf = F(400, tsz)
        mf = F(700, 12 if LH >= 16 else 11)
        for e in rest:
            it.print(GUT - 10, ly + (LH - tsz) // 2 - 1, mf,
                     BLACK, "TOP_RIGHT", short_time(e))
            title, maxw = e["s"], W - GUT - 24
            if it.text_w(tf, title) > maxw:
                while title and it.text_w(tf, title + "...") > maxw:
                    title = title[:-1]
                title += "..."
            it.print(GUT + 12, ly + (LH - tsz) // 2 - 1, tf, BLACK,
                     "TOP_LEFT", title)
            ly += LH

    footer(it, now, len(upcoming))


# ===========================================================================
# OPTION C -- BIG CARDS
# ===========================================================================
# No time axis at all: the next three or four things, each in a box, at the
# largest type the panel can hold. Anything that does not fit becomes one
# summary line at the bottom.
#
# This is the option that trades knowing the shape of the day for being
# readable from the kitchen doorway.
# ===========================================================================

def option_c(it, events, now):
    now_min = now.hour * 60 + now.minute
    upcoming, ad, done = split(events, now_min)

    header_banner(it, now, len(upcoming))
    y = 64
    y = allday_chips(it, ad, y)

    if not upcoming:
        empty_day(it, y, done)
        footer(it, now, 0)
        return

    Y_MAX = 374

    # Two passes: measure, then spread. Cards bunched at the top under 150 px
    # of nothing look like the panel gave up; even spacing looks composed.
    def card_h(idx, e):
        ts = 27 if idx == 0 else 21
        return 30 + len(it.wrap(F(400, ts), e["s"], W - 40, 2)) * (ts + 5) + 14

    fit, used = 0, 0
    for idx, e in enumerate(upcoming):
        h = card_h(idx, e)
        cap = Y_MAX - 22 if idx < len(upcoming) - 1 else Y_MAX
        if y + used + h > cap:
            break
        used += h
        fit += 1
    pad = min(((Y_MAX - y) - used) // max(fit, 1), 24) if fit else 0

    shown = 0
    for idx, e in enumerate(upcoming):
        first = idx == 0
        ts = 27 if first else 21
        tf = F(400, ts)
        lines = it.wrap(tf, e["s"], W - 40, 2)
        h = 30 + len(lines) * (ts + 5) + 14
        # Reserve the overflow line's own row, or it prints over the footer.
        if shown >= fit:
            break

        is_live = live(e, now_min)
        c = RED if is_live else BLACK

        if first:
            it.rectangle(8, y, W - 16, h - 8, c)
            pad = 12
        else:
            it.filled_rectangle(8, y + 2, 3, h - 14, BLACK)
            pad = 8

        mins = e["m"] - now_min
        badge = "NOW" if is_live else (f"{mins} min" if mins < 60
                                       else f"{mins // 60}h {mins % 60:02d}m")
        it.print(8 + pad, y + 8, F(700, 19 if first else 15), c, "TOP_LEFT", e["t"])
        it.print(W - 8 - pad, y + 10, F(700, 14 if first else 12), RED,
                 "TOP_RIGHT", badge)
        ty = y + (34 if first else 30)
        for k, ln in enumerate(lines):
            it.print(8 + pad, ty + k * (ts + 5), tf, BLACK, "TOP_LEFT", ln)
        y += h + pad
        shown += 1

    hidden = len(upcoming) - shown
    if hidden:
        it.print(12, min(y + 4, 356), F(400, 15), RED, "TOP_LEFT",
                 f"+ {hidden} more before bed")
    footer(it, now, len(upcoming))


LAYOUTS = {"a": option_a, "b": option_b, "c": option_c}
NAMES = {"a": "A - Now & Next", "b": "B - Hour ruler", "c": "C - Big cards"}
