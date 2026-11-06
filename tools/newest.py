#!/usr/bin/env python3
"""Record the newest page of the site, for the Home page's button.

    python3 tools/newest.py <dir> <n>      e.g.  python3 tools/newest.py 247bc/jiandu 2
                                                 python3 tools/newest.py videos/zhou/shang 1

Writes XML/newest.xml from the bracket's record in XML/site.xml (a year's document) or
XML/videos.xml (a video period's document). Run it for each bracket as it is published.
"""
import sys, xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
XML = ROOT / "XML"

def main(d, n):
    i = int(n)
    for year in ET.parse(XML / "site.xml").getroot().findall("year"):
        for doc in year.findall("document"):
            if doc.get("dir") == d:
                br = doc.findall("bracket")[i - 1]
                return write(d, i, year.get("era", ""), br.text or "", br.get("en", ""), doc.get("label", ""))
    vfile = XML / "videos.xml"
    if vfile.exists():
        for video in ET.parse(vfile).getroot().findall("video"):
            for section in video.findall("section"):
                doc = section.find("document")
                if doc is not None and doc.get("dir") == d:
                    br = doc.findall("bracket")[i - 1]
                    return write(d, i, section.get("en", ""), br.text or "", br.get("en", ""), video.get("title", ""))
    raise SystemExit(f"{d} is not a document of site.xml or videos.xml")

def write(d, i, era, label, en, source):
    el = ET.Element("newest", href=f"{d}/{i}.html", era=era, label=label.strip(), en=en, source=source)
    (XML / "newest.xml").write_text('<?xml version="1.0" encoding="UTF-8"?>\n<!-- the newest page, written by tools/newest.py; the Home page links to it -->\n'
                                    + ET.tostring(el, encoding="unicode") + "\n", encoding="utf-8")
    print(f"newest: {d}/{i}.html — {era} · {label.strip()} ({en})")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    main(sys.argv[1], sys.argv[2])
