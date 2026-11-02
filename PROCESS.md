# Regnum Sinense — working procedure

The rules below govern every bracket. They are the standing instructions of the editor, Kou Shiyou, and are re-read before each bracket is begun. Where a rule and the glossary differ, the glossary and the editor's later rulings win.

## 1. Unit of work

- One bracket (one cell of the chronology: one source column, one year) at a time, in column order within the year, years in chronological order.
- Each bracket is published for the editor's check and is not pushed to GitHub, and the next bracket is not begun, until the editor approves it ("good", "next", "push").
- A year ends with a full stop: after the last bracket of a year is approved and pushed, work pauses. The next year is begun only when the editor says so in as many words; "push" on a year's last bracket means push, not continue.
- Questions are asked in chat, never written onto the page. No "[draft]" or "(provisional)" markers on the page.

## 2. Before translating

1. Read the bracket's cell verbatim; keep the compiler's paragraph breaks.
2. Re-read the Glossary doc (check for changes since the last read) and look up every term the passage contains that it rules on: units, offices, titles, date forms, naming rules.
3. Search the approved pages for the same passage. A passage already translated is copied verbatim from the approved page; only what differs in the new cell is retranslated, and the difference is said in chat.
4. Search the authority files for every person, place and term in the passage. An existing entry is reused (the tag points at it); a new name under which an existing person or place appears is added to that entry as an alternative name, never as a second entry.

## 3. Renderings

- Pinyin throughout; 卫 is Wey (to keep it apart from Wei 魏); other homophones take the character in parentheses only where two meet in one passage.
- Rulers: King X of Y, Duke X of Y, Lord X (君), Marquis X (侯), Prince (公子), Heir Apparent (太子), Queen (后), Queen Dowager (太后).
- Glossary units and offices: 城 Fortress (always, verb included: "made X a Fortress"), 县 County, 郡 Commandery, 关 Pass, 守 Magistrate, 假 Acting, 令 Sheriff, 相 Chancellor, 相国 Chancellor of State, 令尹 Chief Minister, 弃市 executed in the marketplace, 诸侯 the Lords, 从/纵 the Vertical Alliance, 连横/衡 the Horizontal Alliance.
- Dates: BC/AD; regnal years as the text gives them, with the BC equivalent in a note; months by Western names (五月 → May). Sexagenary days: before Emperor Wu of Han they are kept in sexagenary form, romanised and capitalised (己亥 → Jihai, 辛丑 → Xinchou), since the calendars of the period are not fixed to the day; from Emperor Wu on they are converted to day numbers, computed and checked by two independent tables.
- Elliptical sources (the Tables, the Chronicle) stay elliptical: no subject is supplied; a note says who it is.
- Ivar's labels: 辨析 → "Analysis:", 無骨注 → "Ivar's note:", 原文附 → "original text appended", 待考 → "Pending investigation".
- Chapter and book titles in italics (`<title>`); quoted classics as "The Odes say", "The Changes say".

## 4. Text

- The Chinese is kept as it stands in the compiler's text: character forms, punctuation, parenthesised editors' readings in excavated texts. Variants are flagged in a note, not normalised, and only when they matter to the reading (the glossary's rule).
- A character lost from the compiler's text is supplied in 〔 〕 from the three-commentary edition (史記三家注) and noted as "supplied from the three-commentary edition". The source of the text is never named as "the spreadsheet" on the page.
- 〓 marks a graph illegible in a manuscript, and is left as such.
- An obscure phrase is translated with the reading the commentaries give, and the note names the commentary (Jijie / Xu Guang, Suoyin, Zhengyi). If none gives one, the internet is searched (Wikisource 三家注 text, annotated editions) before the note says the reading is unsettled. 辛德勇 is not used.

## 5. Notes (notes.xml)

- Textual and dating matters only, inside the year: readings, variants, supplied characters, which regnal year equals which BC year, who an unexpressed subject is, that a chapter is excerpted.
- No narrative of other years, no cross-references to events outside the bracket beyond what a reading requires.
- Plain and short. No sentences about the editing process ("kept as they stand", "could not be reproduced"), nothing that reads as written by a machine.

## 6. Entries (auth-files)

- Persons: identification only — rank or office, state, reign dates for rulers, personal name, the names the texts call him by, and the commentary a disputed identification rests on.
- A ruler's entry follows his status: once he is on the throne in the bracket being read (or accedes within it), the entry from that bracket onward gives him as king, with his personal name but without his earlier status ("Heir Apparent", "Lord Anguo before his accession"); the earlier wording stays on the earlier pages through versioning. The earlier name is kept only where the bracket's own text uses it. The same holds for any change of status: the entry says what he is as of the bracket, not what he was. Places: the kind of place, the state, the commentary's placing, the modern location. Terms: a one-line definition.
- No events from other years in an entry. No "location not established": search the commentaries and the internet first; if nothing is found, say what the commentaries do and do not give ("the commentaries give no location") and, where the text allows, where it sits relative to a known place.
- Place headwords show the name only; the rest is in the expanded note.
- One entry per person or place, but its text is never changed retroactively. An entry's note is versioned by the bracket that introduces a change: a new `<note from="-255" seq="7">` (year, BC negative; seq = the bracket's place in that year's reading order, Shiji brackets first, then the excavated texts) is added and shows from that bracket onward, while earlier pages keep the earlier note. This applies to new names, new offices, moved seats and any fact learned from a later bracket; a dated note states the fact as of its bracket and does not recount what went before. Only an outright error is corrected in place, everywhere, and that is said in chat.

## 7. Encoding

- `XML/<year>/<source>/source.xml`: `<div n="N">` per bracket, `<head>` = column heading, one `<p>` per paragraph; tag the first occurrence in the bracket of each `persName`, `placeName`, `term` by entry number; `<title>` for chapter names.
- `english.xml`: same structure and the same tags; `<span corresp="key">` on the words a note attaches to.
- `notes.xml`: `<div n="N">` with `<interp corresp="key">` for every span.
- `intro.xml`: `<div n="N">` with one or two sentences on what the bracket holds, written for every bracket.
- A year's first bracket also needs the four files created with the year's title (`Shiji 史记 · <year label>`) and, for a new year, a check that `site.xml` carries it.

## 8. Build and check

1. `python3 build.py` (subsets the CJK font, rebuilds every page, regenerates `search.html` with `search-index.json`, `sitemap.xml` and `robots.txt`).
2. Consistency check: the set of tag ids in the Chinese equals the set in the English; every id has an entry; every `corresp` has a note.
3. Render the page and look at it (paragraph alignment, strip, headers).
4. Regenerate the artifact's Home (`preview/index.html`: title, style, body of `site/index.html`) and publish the artifact with the changed pages and fonts.
5. In chat: a short summary of the renderings and readings worth the editor's eye, and any questions.

## 9. After approval

1. Copy `XML/` into the repository clone, rebuild there (`docs/`), commit as Kou Shiyou with no co-author line, fetch, rebase, push to `main`. GitHub Pages redeploys itself.
2. Then the next bracket.

## 10. Site rules

- No credit to Claude anywhere: not on pages, not in TEI headers, not in commits.
- One page per bracket, linked from the year page and from every sibling bracket's strip; introductions on every bracket; no annotation box beside the introduction.
- Search is client-side: the navbar box on every page goes to `search.html`, which searches `search-index.json` (every translated bracket, Chinese and English, and every person, place and term entry) in the browser. The index is rebuilt by `build.py`, so a page is searchable as soon as it is built and pushed.
- The `docs/google*.html` verification file and `.nojekyll` stay.
- Cultural-region essays and the 戰國縱橫家書 are sidebar sources by era, to be added when the editor says.
