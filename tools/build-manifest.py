#!/usr/bin/env python3
"""Generate XML/site.xml from the chronology spreadsheet.

    python3 tools/build-manifest.py inbox/chronology.xlsx

Every year row of the year-based tabs becomes a <year>, with its Chinese label, the
Western year, and the concurrent regnal years of the other states. Every tab that has
content for that year becomes a <document>. Whether a document is actually built is
decided later by build.py (it looks for XML/<dir>/source.xml), so this manifest can list
the whole corpus while pages fill in one bracket at a time.
"""
import re
import sys
from pathlib import Path
from xml.sax.saxutils import escape
import openpyxl

ROOT = Path(__file__).resolve().parents[1]

# year-based tabs: tab name in the workbook -> (folder slug, label on the site)
TABS = {
    "史记": ("shiji",   "Shiji 史记"),
    "简牍": ("jiandu",  "Excavated texts 简牍"),
}
# (the year-based 文化区 tab holds only essay titles per year; it is not listed on the site)
# the regional culture sheets: not year-based; listed in the sidebar as sources of their own
ERA_TABS = {
    "文化区（青藏）": ("qingzang", "青藏"),
    "文化区（西域）": ("xiyu",     "西域"),
    "文化区（东北）": ("dongbei",  "东北"),
    "文化区（内蒙）": ("neimeng",  "内蒙"),
}
SITE_NAME = "Regnum Sinense"

# ---- English glosses, shown in small type under the Chinese ----
BRACKET_EN = {
    "史记（一：本纪）": "Shiji I: Basic Annals",
    "史记（二：表）": "Shiji II: Tables",
    "史记（三：世家）": "Shiji III: Hereditary Houses",
    "史记（四：列传）": "Shiji IV: Biographies",
    "史记（五：列传）": "Shiji V: Biographies",
    "无骨论点补充（以及辨析）一": "Ivar the Boneless' commentary and analysis I",
    "无骨论点补充（以及辨析）二": "Ivar the Boneless' commentary and analysis II",
    "年表辨析补充三": "Chronology analysis, supplement III",
    "其他古籍（史類）": "Other ancient works (histories)",
    "史記：補：八書": "Shiji, supplement: the Eight Treatises",
    "《秦简牍合集》（一）睡虎地竹简": "Collected Qin Slips I: the Shuihudi bamboo slips",
    "岳麓书院藏秦简": "Qin slips in the Yuelu Academy collection",
    "《里耶秦簡牘校釋》(一）（二）": "Liye Qin Slips, Collated and Annotated, I–II",
    "里耶秦簡（其他）": "Liye Qin slips (other)",
    "胡家草场西汉简牍《岁纪》": "Hujiacaochang Western Han slips: the Suiji (Annual Record)",
    "附：《戰國縱橫家書》原文": "Appendix: text of the Zhanguo zonghengjia shu",
}
RULER_EN = {
    "周赧王": "King Nan of Zhou",
    "秦昭襄王": "King Zhaoxiang of Qin", "秦孝文王": "King Xiaowen of Qin", "秦庄襄王": "King Zhuangxiang of Qin",
    "秦王政": "King Zheng of Qin", "秦始皇帝": "the First Emperor of Qin",
    "魏安釐王": "King Anxi of Wei", "魏景湣王": "King Jingmin of Wei", "魏王假": "King Jia of Wei",
    "韩桓惠王": "King Huanhui of Han", "韩王安": "King An of Han",
    "赵孝成王": "King Xiaocheng of Zhao", "赵悼襄王": "King Daoxiang of Zhao", "赵幽缪王": "King Youmiu of Zhao", "代王嘉": "King Jia of Dai",
    "楚考烈王": "King Kaolie of Chu", "楚幽王": "King You of Chu", "楚王負刍": "King Fuchu of Chu",
    "燕孝王": "King Xiao of Yan", "燕王喜": "King Xi of Yan",
    "齐王建": "King Jian of Qi",
    "鲁顷公": "Duke Qing of Lu",
    "卫怀君": "Lord Huai of Wey", "卫元君": "Lord Yuan of Wey", "卫君角": "Lord Jiao of Wey",
}
OTHER_EN = {
    "西周、东周世系不详": "Western and Eastern Zhou: succession unknown",
    "东周世系不详": "Eastern Zhou: succession unknown",
}
SIDE_EN = {
    "戰國縱橫家書": "Zhanguo zonghengjia shu (the Mawangdui letters of the Warring States persuaders)",
    "文化区": "Cultural regions",
    "青藏": "Qinghai–Tibet", "西域": "Western Regions", "东北": "Northeast", "内蒙": "Inner Mongolia",
}
CN_DIGITS = {"元": 1, "一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6, "七": 7, "八": 8, "九": 9}

def cn_number(t):                       # 五十九 → 59, 十 → 10, 元 → 1
    if t in CN_DIGITS: return CN_DIGITS[t]
    if "十" in t:
        tens, _, ones = t.partition("十")
        return (CN_DIGITS[tens] if tens else 1) * 10 + (CN_DIGITS[ones] if ones else 0)
    return None

def ordinal(n):
    suf = "th" if 10 <= n % 100 <= 20 else {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
    return f"{n}{suf}"

def gloss_regnal(label):                 # 秦昭襄王五十一年 → 51st year of King Zhaoxiang of Qin
    parts = []
    for part in label.split("/"):
        part = part.strip()
        if part in OTHER_EN:
            parts.append(OTHER_EN[part]); continue
        m = re.match(r"^(.*?)([元一二三四五六七八九十]+)年$", part)
        if m and m.group(1) in RULER_EN:
            parts.append(f"{ordinal(cn_number(m.group(2)))} year of {RULER_EN[m.group(1)]}")
        else:
            parts.append("")
    return " / ".join(parts).strip(" /")
import re
def reign(label):                       # 周赧王五十九年 → 周赧王 ; "秦王政二十六年 / 秦始皇帝元年" → 秦始皇帝
    last = label.split("/")[-1].strip()
    return re.sub(r"[元一二三四五六七八九十百]+年$", "", last)


def year_dir(western: int) -> str:
    return f"{-western}bc" if western < 0 else f"{western}ad"


def main(xlsx):
    wb = openpyxl.load_workbook(xlsx, read_only=True, data_only=True)
    years = {}                          # western year -> dict
    for tab, (slug, label) in TABS.items():
        if tab not in wb.sheetnames:
            continue
        rows = list(wb[tab].iter_rows(values_only=True))
        header = rows[0]
        for r in rows[1:]:
            try:
                w = int(r[2])
            except (TypeError, ValueError):
                continue                 # period headers and blank rows
            year_label = " / ".join(part.strip() for part in str(r[0]).splitlines() if part.strip())   # a year with two labels: 秦王政二十六年 / 秦始皇帝元年
            y = years.setdefault(w, {"label": year_label, "concurrent": str(r[1] or "").strip(), "docs": []})
            # brackets = non-empty cells from column 3 onward
            brackets = [(i, str(header[i]).strip()) for i, c in enumerate(r) if i >= 3 and c not in (None, "")]
            if brackets:
                y["docs"].append((slug, label, brackets))

    # the regional culture sheets, kept as named sources for the sidebar (content added later)
    era_sources = [(slug, label, tab) for tab, (slug, label) in ERA_TABS.items() if tab in wb.sheetnames]

    out = ['<?xml version="1.0" encoding="UTF-8"?>',
           '<!-- Generated by tools/build-manifest.py from the chronology spreadsheet. Edit the script, not this file. -->',
           '<site>', f'   <name>{escape(SITE_NAME)}</name>']
    for w in sorted(years):
        y = years[w]
        era = f"{-w} BC" if w < 0 else f"AD {w}"
        rg = reign(y["label"])
        out.append(f'   <year n="{w}" era="{escape(era)}" label="{escape(y["label"])}" en="{escape(gloss_regnal(y["label"]))}" reign-en="{escape(RULER_EN.get(rg, ""))}">')
        for line in [s for s in y["concurrent"].splitlines() if s.strip()]:
            out.append(f'      <concurrent en="{escape(gloss_regnal(line.strip()))}">{escape(line.strip())}</concurrent>')
        for slug, label, brackets in y["docs"]:
            out.append(f'      <document dir="{year_dir(w)}/{slug}" label="{escape(label)}">')
            for col, name in brackets:
                out.append(f'         <bracket col="{col}" en="{escape(BRACKET_EN.get(name, ""))}">{escape(name)}</bracket>')
            out.append('      </document>')
        out.append('   </year>')
    out.append('   <side-group label="战国" en="Warring States">')
    out.append(f'      <side-source id="zonghengjia" label="戰國縱橫家書" en="{escape(SIDE_EN["戰國縱橫家書"])}"/>')
    out.append('   </side-group>')
    out.append(f'   <side-group label="文化区" en="{escape(SIDE_EN["文化区"])}">')
    for slug, label, tab in era_sources:
        out.append(f'      <side-source id="{slug}" label="{escape(label)}" en="{escape(SIDE_EN.get(label, ""))}" sheet="{escape(tab)}"/>')
    out.append('      <side-source id="lingnan" label="岭南" en="Lingnan"/>')   # no sheets yet for these
    for slug, label, en in (("sanhan", "三韩", "Samhan, the Three Han"), ("ordos", "鄂尔多斯-蒙古", "Ordos–Mongolia"), ("bandao-dongying", "半岛-东瀛", "Korean Peninsula and Japan")):
        out.append(f'      <side-source id="{slug}" foreign="yes" label="{label}" en="{en}"/>')
    out.append('   </side-group>')
    missing = sorted({n for y in years.values() for _, _, b in y["docs"] for _, n in b if n not in BRACKET_EN})
    if missing: print("brackets without an English gloss:", missing)
    out.append('</site>')
    (ROOT / "XML" / "site.xml").write_text("\n".join(out) + "\n", encoding="utf-8")
    ndocs = sum(len(y["docs"]) for y in years.values())
    nbr = sum(len(b) for y in years.values() for _, _, b in y["docs"])
    print(f"site.xml: {len(years)} years, {ndocs} source pages, {nbr} brackets")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ROOT.parent / "inbox" / "chronology.xlsx")
