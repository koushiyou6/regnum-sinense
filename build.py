#!/usr/bin/env python3
"""Build the site.

    python3 build.py

Requires:  pip install saxonche   (Saxon-HE for Python; XSLT 3.0)

Reads XML/site.xml (generated from the spreadsheet by tools/build-manifest.py). For every
<document dir="…"> whose XML/<dir>/source.xml exists, transforms it with
XSLT/text-trans-notes.xsl into site/<dir>.html. Builds a year page for every year that has
at least one built document, and the Home page. Every page is self-contained (CSS inlined).
"""
from pathlib import Path
import xml.etree.ElementTree as ET
from saxonche import PySaxonProcessor

ROOT = Path(__file__).resolve().parent
XML = ROOT / "XML"
SITE = ROOT / "docs"
SITE_URL = "https://regnumsinense.com/"   # public address, for sitemap.xml and robots.txt
MANIFEST = XML / "site.xml"


def build():
    import subprocess, sys
    subprocess.run([sys.executable, "-I", str(ROOT / "tools" / "build-font.py")], check=True)   # subset CJK font for the current texts
    manifest = ET.parse(MANIFEST).getroot()
    with PySaxonProcessor(license=False) as proc:
        page_xslt = proc.new_xslt30_processor()
        page = page_xslt.compile_stylesheet(stylesheet_file=str(ROOT / "XSLT" / "text-trans-notes.xsl"))
        if page is None:
            raise SystemExit(page_xslt.error_message)
        index_xslt = proc.new_xslt30_processor()
        index = index_xslt.compile_stylesheet(stylesheet_file=str(ROOT / "XSLT" / "index.xsl"))
        if index is None:
            raise SystemExit(index_xslt.error_message)

        built_years = []
        for year in manifest.findall("year"):
            any_built = False
            for doc in year.findall("document"):
                d = doc.get("dir")
                source = XML / d / "source.xml"
                if not source.exists():
                    continue
                any_built = True
                # one page per translated bracket: site/<dir>/<n>.html
                eng = XML / d / "english.xml"
                eng_root = ET.parse(eng).getroot() if eng.exists() else None
                TEI = "{http://www.tei-c.org/ns/1.0}"
                translated = set()
                if eng_root is not None:
                    for div in eng_root.iter(f"{TEI}div"):
                        if div.get("n") and any(div.find(f"{TEI}{t}") is not None for t in ("p", "ab", "head")):
                            translated.add(div.get("n"))
                for i, _bracket in enumerate(doc.findall("bracket"), start=1):
                    if str(i) not in translated:
                        continue
                    out = SITE / d / f"{i}.html"
                    out.parent.mkdir(parents=True, exist_ok=True)
                    depth = len(Path(d).parts)
                    page.set_parameter("root", proc.make_string_value("../" * depth))
                    page.set_parameter("year", proc.make_string_value(year.get("era", "")))
                    page.set_parameter("dir", proc.make_string_value(d))
                    page.set_parameter("bracket", proc.make_string_value(str(i)))
                    page.transform_to_file(source_file=str(source), output_file=str(out))
                    print(f"wrote {out.relative_to(ROOT)}")
                old = SITE / f"{d}.html"
                if old.exists():
                    old.unlink()
            if any_built:
                built_years.append(year)

        # year pages, only for years with something to show
        for year in built_years:
            year_dir = year.find("document").get("dir").split("/")[0]
            out = SITE / year_dir / "index.html"
            out.parent.mkdir(parents=True, exist_ok=True)
            index.set_parameter("year", proc.make_string_value(year.get("n")))
            index.transform_to_file(source_file=str(MANIFEST), output_file=str(out))
            print(f"wrote {out.relative_to(ROOT)}")

        # Home
        out = SITE / "index.html"
        index.set_parameter("year", proc.make_string_value(""))
        index.transform_to_file(source_file=str(MANIFEST), output_file=str(out))
        print(f"wrote {out.relative_to(ROOT)}")

        # About (content in XML/about.xml)
        out = SITE / "about.html"
        index.set_parameter("page", proc.make_string_value("about"))
        index.transform_to_file(source_file=str(MANIFEST), output_file=str(out))
        print(f"wrote {out.relative_to(ROOT)}")

        # Search (client-side, over search-index.json)
        out = SITE / "search.html"
        index.set_parameter("page", proc.make_string_value("search"))
        index.transform_to_file(source_file=str(MANIFEST), output_file=str(out))
        print(f"wrote {out.relative_to(ROOT)}")

        # Sources by era / video (XML/site.xml side-groups and XML/videos.xml)
        out = SITE / "sources.html"
        index.set_parameter("page", proc.make_string_value("sources"))
        index.transform_to_file(source_file=str(MANIFEST), output_file=str(out))
        index.set_parameter("page", proc.make_string_value(""))
        print(f"wrote {out.relative_to(ROOT)}")

    write_search_index(manifest)

    # sitemap.xml and robots.txt for search engines
    pages = sorted(p for p in SITE.rglob("*.html"))
    urls = []
    for p in pages:
        rel = p.relative_to(SITE).as_posix()
        urls.append(SITE_URL + ("" if rel == "index.html" else rel[:-len("index.html")] if rel.endswith("/index.html") else rel))
    (SITE / "sitemap.xml").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        + "".join(f"  <url><loc>{u}</loc></url>\n" for u in urls) + "</urlset>\n", encoding="utf-8")
    (SITE / "robots.txt").write_text(f"User-agent: *\nAllow: /\nSitemap: {SITE_URL}sitemap.xml\n", encoding="utf-8")
    print(f"wrote sitemap.xml ({len(urls)} pages) and robots.txt")


def write_search_index(manifest):
    """site/search-index.json: every translated bracket (Chinese and English text) and every
    authority entry (persons, places, terms), with the pages each entry is tagged on."""
    import json, re
    TEI = "{http://www.tei-c.org/ns/1.0}"
    def text(el):
        return re.sub(r"\s+", " ", "".join(el.itertext())).strip()
    passages, where = [], {}
    for year in manifest.findall("year"):
        era = year.get("era", "")
        for doc in year.findall("document"):
            d = doc.get("dir")
            src, eng = XML / d / "source.xml", XML / d / "english.xml"
            if not (src.exists() and eng.exists()):
                continue
            src_divs = {dv.get("n"): dv for dv in ET.parse(src).getroot().iter(f"{TEI}div") if dv.get("n")}
            eng_divs = {dv.get("n"): dv for dv in ET.parse(eng).getroot().iter(f"{TEI}div") if dv.get("n")}
            for i, bracket in enumerate(doc.findall("bracket"), start=1):
                n = str(i)
                if n not in eng_divs or not any(eng_divs[n].find(f"{TEI}{t}") is not None for t in ("p", "ab", "head")):
                    continue
                url = f"{d}/{n}.html"
                label = f"{era} · {bracket.get('en') or bracket.text or n}"
                zh = text(src_divs[n]) if n in src_divs else ""
                en = text(eng_divs[n])
                passages.append({"url": url, "era": era, "title": bracket.get("en") or bracket.text or n, "zh": zh, "en": en})
                for dv in (src_divs.get(n), eng_divs.get(n)):
                    if dv is None:
                        continue
                    for tag, kind in (("persName", "person"), ("placeName", "place"), ("term", "term")):
                        for el in dv.iter(f"{TEI}{tag}"):
                            if el.get("n"):
                                where.setdefault((kind, el.get("n")), {})[url] = label
    entries = []
    auth = XML / "auth-files"
    def notes(el):
        """(latest note, earlier versions joined): the latest is shown, the rest only matched."""
        ns = [text(nt) for nt in el.findall(f"{TEI}note") if text(nt)]
        return (ns[-1] if ns else "", " ".join(ns[:-1]))
    for p in ET.parse(auth / "persons.xml").getroot().iter(f"{TEI}person"):
        pn = p.find(f"{TEI}persName")
        name = text(pn.find(f"{TEI}name")) if pn is not None and pn.find(f"{TEI}name") is not None else ""
        alt = " ".join(text(x) for x in (pn.findall(f"{TEI}addName") + pn.findall(f"{TEI}roleName")) if text(x)) if pn is not None else ""
        entries.append(("person", p.get("n"), name, alt, *notes(p)))
    for pl in ET.parse(auth / "locations.xml").getroot().iter(f"{TEI}place"):
        pn = pl.find(f"{TEI}placeName")
        name = text(pn) if pn is not None else ""
        entries.append(("place", pl.get("n"), name, "", *notes(pl)))
    for se in ET.parse(auth / "lexicon.xml").getroot().iter(f"{TEI}superEntry"):
        zh = en = defn = ""
        for e in se.findall(f"{TEI}entry"):
            orth = e.find(f"{TEI}form/{TEI}orth")
            if e.get("{http://www.w3.org/XML/1998/namespace}lang") == "zho":
                zh = text(orth) if orth is not None else ""
            else:
                en = text(orth) if orth is not None else ""
                defn = " ".join(text(df) for df in e.iter(f"{TEI}def") if text(df))
        entries.append(("term", se.get("n"), f"{zh} {en}".strip(), "", defn, ""))
    # traditional/simplified: a per-character map (built with OpenCC, one graph to one graph) so a search in
    # either script finds the other; the page's JS converts the query and the texts with the same map.
    chars = set()
    for ps in passages:
        chars.update(ps["zh"]); chars.update(ps["title"])
    for k, n, nm, alt, note, more in entries:
        chars.update(nm); chars.update(alt); chars.update(note); chars.update(more)
    t2s = {}
    try:
        from opencc import OpenCC
        cc = OpenCC("t2s")
        for ch in chars:
            if ord(ch) < 0x2E80:
                continue
            sc = cc.convert(ch)
            if len(sc) == 1 and sc != ch:
                t2s[ch] = sc
    except ImportError:
        print("opencc not installed: traditional/simplified matching left out of the search index")
    out = {"t2s": t2s, "passages": passages, "entries": [
        {"kind": k, "name": nm, "alt": alt, "note": note, "more": more,
         "pages": [{"url": u, "label": l} for u, l in where.get((k, n), {}).items()]}   # manifest order = chronological
        for k, n, nm, alt, note, more in entries if nm]}
    (SITE / "search-index.json").write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"wrote search-index.json ({len(passages)} passages, {len(out['entries'])} entries, {len(t2s)} t2s chars)")


if __name__ == "__main__":
    build()
