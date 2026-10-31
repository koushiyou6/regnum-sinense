# Regnum Sinense

The sources behind [Atrium Concordiae](https://www.youtube.com/@AtriumConcordiae)'s historical atlases of China, year by year from 256 BC: Chinese text, English translation and notes, side by side.

The site is published from the `docs/` folder with GitHub Pages.

## Layout

| Path | What it is |
|---|---|
| `XML/<year>/<source>/source.xml` | the Chinese text of one source for one year, one `<div n="N">` per bracket |
| `XML/<year>/<source>/english.xml` | its translation, same structure |
| `XML/<year>/<source>/notes.xml` | explanatory notes, keyed to `<span corresp="…">` in the translation |
| `XML/<year>/<source>/intro.xml` | introductions, one `<div n="N">` per bracket |
| `XML/auth-files/` | the lexicon, personography and gazetteer (`term`, `persName`, `placeName` entries by number) |
| `XML/site.xml` | the chronology manifest: years, concurrent regnal years, sources and brackets (generated) |
| `XML/about.xml` | the About page |
| `XSLT/` | the stylesheets that turn the XML into pages |
| `css/style.css` | the stylesheet, adapted from the Parlamentos project |
| `tools/` | `build-manifest.py` (manifest from the chronology spreadsheet), `build-font.py` (CJK font subset), `calcheck.py` (calendar checks) |
| `docs/` | the built site; `docs/google*.html` is the Google Search Console verification file and must stay |

## Building

Needs Python 3 with `saxonche`, `fonttools` and `openpyxl`, and the Noto Serif CJK fonts installed (`fonts-noto-cjk` on Debian/Ubuntu).

    python3 build.py

rebuilds every page under `docs/`, subsetting the Chinese font first. To regenerate the manifest from the chronology spreadsheet:

    python3 tools/build-manifest.py path/to/chronology.xlsx

## Credits and licences

See [CREDITS.md](CREDITS.md).
