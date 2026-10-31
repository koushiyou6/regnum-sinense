#!/usr/bin/env python3
"""Build the site.

    python3 build.py

Requires:  pip install saxonche   (Saxon-HE for Python; XSLT 3.0)

Reads XML/site.xml (generated from the spreadsheet by tools/build-manifest.py). For every
<document dir="…"> whose XML/<dir>/source.xml exists, transforms it with
XSLT/text-trans-notes.xsl into docs/<dir>/<n>.html. Builds a year page for every year that has
at least one built document, and the Home page. Every page is self-contained (CSS inlined).
"""
from pathlib import Path
import xml.etree.ElementTree as ET
from saxonche import PySaxonProcessor

ROOT = Path(__file__).resolve().parent
XML = ROOT / "XML"
SITE = ROOT / "docs"
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
                # one page per translated bracket: docs/<dir>/<n>.html
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
        index.set_parameter("page", proc.make_string_value(""))
        print(f"wrote {out.relative_to(ROOT)}")


if __name__ == "__main__":
    build()
