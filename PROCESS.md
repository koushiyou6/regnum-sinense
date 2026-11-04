# Regnum Sinense — working procedure

The rules below govern every bracket. They are the standing instructions of the editor, Kou Shiyou, and are re-read before each bracket is begun. Where a rule and the glossary differ, the glossary and the editor's later rulings win.

## 1. Unit of work

- One bracket (one cell of the chronology: one source column, one year) at a time, in column order within the year, years in chronological order.
- Each bracket is published for the editor's check and is not pushed to GitHub, and the next bracket is not begun, until the editor approves it ("good", "next", "push").
- A year ends with a full stop: after the last bracket of a year is approved and pushed, work pauses. The next year is begun only when the editor says so in as many words; "push" on a year's last bracket means push, not continue.
- Questions are asked in chat, never written onto the page. No "[draft]" or "(provisional)" markers on the page.

## 2. Before translating

1. Read the bracket's cell verbatim; keep the compiler's paragraph breaks.
2. Re-read the Glossary doc (check for changes since the last read) and look up every term the passage contains that it rules on: units, offices, titles, date forms, naming rules. Read it carefully and in full, not by a keyword search: its naming conventions apply to every place-name (everything before an administrative unit is romanised in full, so 三川郡 is Sanchuan Commandery, not Three Rivers; 山 fuses into names; 河/水/川 are "X River" with no "the"; measures 里/斤/石/两 are romanised; 等 is "and others"; the glossary's 台 Plateau is for natural features, a built 台 such as 琅琊台 is a Terrace), and a rendering that breaks one of them is wrong even if it reads well.
3. Search the approved pages for the same passage. A passage already translated is copied verbatim from the approved page; only what differs in the new cell is retranslated, and the difference is said in chat.
4. Search the authority files for every person, place and term in the passage. An existing entry is reused (the tag points at it); a new name under which an existing person or place appears is added to that entry as an alternative name, never as a second entry.

## 3. Renderings

- Pinyin throughout; 卫 is Wey (to keep it apart from Wei 魏); other homophones take the character in parentheses only where two meet in one passage.
- Rulers: King X of Y, Duke X of Y, Lord X (君), Marquis X (侯), Prince (公子), Heir Apparent (太子), Queen (后), Queen Dowager (太后).
- Glossary units and offices: 城 Fortress as a noun (a walled place, or the suffix of a place-name count: "thirty-seven Fortresses"); as a verb, "fortified" (城故吴墟, "fortified the old ruins of Wu") or "made X a Fortress", whichever reads better; not an ironclad rule, 县 County, 郡 Commandery, 关 Pass, 守 Magistrate, 假 Acting, 令 Sheriff, 相 Chancellor, 相国 Chancellor of State, 令尹 Chief Minister, 弃市 executed in the marketplace, 诸侯 the Lords, 从/纵 the Vertical Alliance, 连横/衡 the Horizontal Alliance.
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
- An entry holds only what stays true from that page onward. Anything that is true of one page alone — which name the passage uses here, what this Biography is about, that "the Table calls him" so-and-so — goes in that bracket's notes (notes.xml), never in the entry, because a dated entry note carries forward to every later page until another replaces it. (Rule in force from 249 BC §5; earlier entries are left as they are.)
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
- Search understands years: "248", "248 BC", "248bc", "前248" or any reign-year name (秦庄襄王二年, 魏安釐王二十九年, "King Xiaocheng") lists the year page first; a year beside other words ("248 蒙骜", "Lian Po 251 BC") searches that year alone. English year names match by whole word whatever the tick. Only the main chronology's years are known to it: the Catalogue's sources by era, and the Library and Gazetteer chronologies when they are built (Han years from 206 BC, the 半岛 and 东瀛 tables), will need their years added to `search-index.json` (`years` in `build.py`) and a way to tell a Han "year 2" from a Qin one before they can be searched the same way.
- Search is client-side: the navbar box on every page goes to `search.html`, which searches `search-index.json` (every translated bracket, Chinese and English, and every person, place and term entry) in the browser. The index is rebuilt by `build.py`, so a page is searchable as soon as it is built and pushed.
- The `docs/google*.html` verification file and `.nojekyll` stay.
- Cultural-region essays and the 戰國縱橫家書 are sources by era, listed on `sources.html` (reached from the single "Catalogue" link in the Home sidebar) beside the videos; they are added when the editor says. Videos go in `XML/videos.xml` (title, url, from/to year numbers, optional note) and the page lists each with links to the years it covers.

## 11. Newspaper items (Catalogue → By newspaper)

- Source: `XML/newspapers.xml`, one `<newspaper>` per item (paper, date, era, topic, image in `assets/newspapers/`, Commons source), with `<intro>`, then `<article>`s each holding `<ja>` (head, subhead, paragraphs) and `<en>` (the same), then `<notes>`. The build writes `site/newspapers/<id>.html`.
- The page follows the bracket pages exactly: h1 (paper), era-lines (paper, place, date; Newspaper · Catalogue · era · topic), rule, the clipping full width (click enlarges in an overlay; click again or Esc closes; never a link to the raw image), rule, Introduction, rule, Text and Translation, then the same three-column grid (`Text: Japanese source` / `Text: English Translation` / `Annotations`): one row per headline, one row per paragraph, so the two texts stay level; the annotation panel is the bracket pages' (Terms / Persons / Places / Notes, latest entry note shown).
- Transcription: the paper's own characters (奮鬪, 爲, 脚, 說 …) and its own furigana, in the historical kana of the print; corrections to the editor's transcription are made against the print and reported in chat. Furigana as `<ruby>漢字<rt>かな</rt></ruby>`; a tag (`persName`, `placeName`, `term`) wraps the ruby, and a tagged word gets its own ruby apart from its neighbours (兩 + 旅, 天津 + 驛). Datelines as `<dateline>` with the place of sending tagged.
- A Japanese item renders Chinese names in their Japanese readings (Hōten, Kinshū, Go Haifu …), in the translation, the headlines and the entries' display names; the pinyin goes in the entry note ("Fengtian in pinyin, Hōten in Japanese reading; …"). The entry keeps the pinyin name as its main form (`<persName>`/`<placeName>` without `xml:lang`) and adds `<persName xml:lang="ja">` / `<placeName xml:lang="ja">`; a term that embeds a place name gets `<form type="ja-reading">` in its English entry. Bracket pages ignore the `ja` forms; the newspaper page prefers them; both are searchable. The Introduction and catalogue labels are in the site's own voice (pinyin).
- Consistency check as for a bracket (ids equal between `ja` and `en`; every id has an entry; every `corresp` a note), and the page is looked at on a desktop width and a phone width (390px) before publishing.

## 12. Catalogue, Gazetteer, Library

- The Home sidebar's "Sources by era / video" holds three entries: **Catalogue** (`sources.html`: by era — the 戰國縱橫家書 under 战国 — by newspaper, by video), **Gazetteer** (`gazetteer.html`: the cultural regions, "By region" 青藏 · 西域 · 东北 · 内蒙 · 岭南 and "By region (foreign)" 三韩 · 鄂尔多斯-蒙古 · 半岛-东瀛) and **Library** (`library.html`: the works of the scholars 大儒书籍, by period, Han first). All three pages share the Catalogue's form; what is not yet on the site is grey.
- Their sources are companion spreadsheets kept beside the chronology spreadsheet in `inbox/` (not in the repository): 大儒書籍 (two tabs, a Han year table 206 BC–AD 220 with a column per book, and 資治通鑒 宋版/四庫版) → Library, Han; 半岛-东瀛 (半岛 古籍 year table, 三国史记; 半岛 文化区; 东瀛 古籍, 古事記·日本書紀·風土記; 东瀛 文化区; with a .docx reading list) → 半岛-东瀛; the 朝鲜半岛初期铁器文化 essays → 三韩; the 广东分册 / 广西通史 / 东山文化 essays → 岭南; 补充年表_匈奴 and the 蒙古 slab-grave essays → 鄂尔多斯-蒙古. The main spreadsheet's 文化区 tabs remain the source of 青藏 · 西域 · 东北 · 内蒙.
- A source that has its own year table (Han in the Library; 半岛 and 东瀛 in the Gazetteer) opens a contents page of its own: a chronology directory in the Home page's form, the years listed by reign, each year's page holding one bracket per book-column, built and approved bracket by bracket. An essay source (三韩, 岭南, 鄂尔多斯-蒙古, the four 文化区 tabs) opens an essay page. Nothing is built from them until the editor says.
