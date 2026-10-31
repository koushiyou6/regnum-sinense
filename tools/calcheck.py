#!/usr/bin/env python3
"""Convert a sexagenary (ganzhi) day to its day of the lunar month, checked against two sources.

    python3 tools/calcheck.py 995 2 丙午          # year CE, lunar month, ganzhi day
    python3 tools/calcheck.py 995 2 丙午 --leap   # the intercalary (閏) month of that number
    python3 tools/calcheck.py 995 2               # list the whole month

Source A: the sxtwl library (astronomical reconstruction of the traditional calendar).
Source B: month-start table extracted from Yuk Tung Liu's Chinese Calendar project
          (https://ytliu0.github.io/ChineseCalendar/, GPL-3), tools/liu-calendar-900-1300.json.
Both are computations; where they disagree, or a ganzhi is not found in the month, the
source's month may be wrong or the historical calendar may have differed by a day: check
the ctext.org / 二十史朔閏表 tables for that month before trusting either.
Dates are Julian (the calendar in use before 1582).
"""
import json, sys
from pathlib import Path

TG = "甲乙丙丁戊己庚辛壬癸"; DZ = "子丑寅卯辰巳午未申酉戌亥"
MONTHS = ["January","February","March","April","May","June","July","August","September","October","November","December"]
HERE = Path(__file__).resolve().parent

def ganzhi_of_jdn(j):            # (JDN + 49) mod 60, 0 = 甲子
    i = (j + 49) % 60
    return TG[i % 10] + DZ[i % 12]

def jdn_julian(y, m, d):
    a = (14 - m) // 12; yy = y + 4800 - a; mm = m + 12 * a - 3
    return d + (153 * mm + 2) // 5 + 365 * yy + yy // 4 - 32083

def julian_from_doy(y, doy):     # day-of-year, Jan 1 = 1, Julian leap rule
    ml = [31, 29 if y % 4 == 0 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    m = 1
    while doy > ml[m - 1]:
        doy -= ml[m - 1]; m += 1
    return m, doy

def month_liu(y, month, leap=False):
    """(list of (day_no, ganzhi, (m, d))) for the month, from Liu's table."""
    data = json.load(open(HERE / "liu-calendar-900-1300.json", encoding="utf-8"))["rows"]
    row = data.get(str(y))
    if not row:
        return None
    starts, leap_start, leap_after, length = row[:12], row[12], row[13], row[14]
    # rebuild the ordered sequence of month starts, inserting the leap month
    seq = []
    for i, s in enumerate(starts, start=1):
        seq.append((i, False, s))
        if leap_after == i and leap_start:
            seq.append((i, True, leap_start))
    seq.append((13, False, starts[0] + length))     # next year's first month, as the end marker
    for k, (mi, is_leap, s) in enumerate(seq[:-1]):
        if mi == month and is_leap == leap:
            end = seq[k + 1][2]
            days = []
            for n, doy in enumerate(range(s, end), start=1):
                m, d = julian_from_doy(y, doy)
                days.append((n, ganzhi_of_jdn(jdn_julian(y, m, d)), (m, d)))
            return days
    return None

def month_sxtwl(y, month, leap=False):
    try:
        import sxtwl
    except ImportError:
        return None
    days = []
    ml = [31, 29 if y % 4 == 0 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    for m in range(1, 13):
        for d in range(1, ml[m - 1] + 1):
            try:
                day = sxtwl.fromSolar(y, m, d)
            except Exception:
                continue
            if day.getLunarYear() == y and day.getLunarMonth() == month and bool(day.isLunarLeap()) == leap:
                gz = day.getDayGZ()
                days.append((day.getLunarDay(), TG[gz.tg] + DZ[gz.dz], (m, d)))
    # a lunar month can straddle Dec/Jan of the Western year; good enough for the 1st-12th months
    return days or None

def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    leap = "--leap" in sys.argv
    if len(args) < 2:
        print(__doc__); sys.exit(1)
    y, month = int(args[0]), int(args[1])
    target = args[2] if len(args) > 2 else None
    a = month_sxtwl(y, month, leap); b = month_liu(y, month, leap)
    label = f"{y} CE, {'intercalary ' if leap else ''}month {month}"
    for name, days in (("sxtwl", a), ("Liu", b)):
        if not days:
            print(f"{name}: no data for {label}"); continue
        if target:
            hits = [x for x in days if x[1] == target]
            if hits:
                n, gz, (m, d) = hits[0]
                print(f"{name}: {gz} = day {n} of month {month}  →  'the {n}{'st' if n in (1,21,31) else 'nd' if n in (2,22) else 'rd' if n in (3,23) else 'th'} of {MONTHS[month-1]}'  ({y}-{m:02d}-{d:02d} Julian)")
            else:
                print(f"{name}: {target} does not occur in {label} (month runs {days[0][1]}–{days[-1][1]}, {len(days)} days)")
        else:
            print(f"{name}: {label}: {len(days)} days, {days[0][1]} to {days[-1][1]}, starts {y}-{days[0][2][0]:02d}-{days[0][2][1]:02d} Julian")
            print("   " + "  ".join(f"{n}:{gz}" for n, gz, _ in days))
    if a and b:
        same = [x[1] for x in a] == [x[1] for x in b]
        print("agreement:", "yes — both sources give the same month" if same else "NO — the two sources differ; check the historical tables")

if __name__ == "__main__":
    main()
