#!/usr/bin/env python3
"""
Generates the bundled sticker catalog for the Panini FIFA World Cup 2026 album.

Structure (deterministic, documented publicly):
  - "00" Panini Logo (foil) + FWC1-FWC8 opening foils            -> 9 brilliant
  - FWC9-FWC19 FIFA Museum (past winners) foils                  -> 11 brilliant
  - 48 teams x 20 (pos 1 = team logo FOIL, pos 13 = team photo,
    the other 18 = players)                                      -> 960
  - CC1-CC14 Coca-Cola promo set (Brazilian edition)             -> 14
  Total = 994 (68 brilliant/foil).

Teams are emitted in the album's default order — the FIFA World Cup 2026 group
draw (Group A..L) — and tagged with their group. The app can re-sort alphabetically.

Player names are loaded from `player_names.json` (compiled from public checklists:
checklistinsider.com + diamondcardsonline.com, cross-checked). Slots without a
known name stay null and are editable in-app.

Output: AlbumTracker/Resources/BundledData/world-cup-2026/stickers.json
Run:    python3 DataPipeline/generate_stickers.py
"""

import json
import os

# name -> (FIFA code, flag)
TEAM_INFO = {
    "Algeria": ("ALG", "🇩🇿"), "Argentina": ("ARG", "🇦🇷"), "Australia": ("AUS", "🇦🇺"),
    "Austria": ("AUT", "🇦🇹"), "Belgium": ("BEL", "🇧🇪"), "Bosnia and Herzegovina": ("BIH", "🇧🇦"),
    "Brazil": ("BRA", "🇧🇷"), "Canada": ("CAN", "🇨🇦"), "Cape Verde": ("CPV", "🇨🇻"),
    "Colombia": ("COL", "🇨🇴"), "Côte d'Ivoire": ("CIV", "🇨🇮"), "Croatia": ("CRO", "🇭🇷"),
    "Curaçao": ("CUW", "🇨🇼"), "Czechia": ("CZE", "🇨🇿"), "DR Congo": ("COD", "🇨🇩"),
    "Ecuador": ("ECU", "🇪🇨"), "Egypt": ("EGY", "🇪🇬"), "England": ("ENG", "🏴󠁧󠁢󠁥󠁮󠁧󠁿"),
    "France": ("FRA", "🇫🇷"), "Germany": ("GER", "🇩🇪"), "Ghana": ("GHA", "🇬🇭"),
    "Haiti": ("HAI", "🇭🇹"), "Iran": ("IRN", "🇮🇷"), "Iraq": ("IRQ", "🇮🇶"),
    "Japan": ("JPN", "🇯🇵"), "Jordan": ("JOR", "🇯🇴"), "Korea Republic": ("KOR", "🇰🇷"),
    "Mexico": ("MEX", "🇲🇽"), "Morocco": ("MAR", "🇲🇦"), "Netherlands": ("NED", "🇳🇱"),
    "New Zealand": ("NZL", "🇳🇿"), "Norway": ("NOR", "🇳🇴"), "Panama": ("PAN", "🇵🇦"),
    "Paraguay": ("PAR", "🇵🇾"), "Portugal": ("POR", "🇵🇹"), "Qatar": ("QAT", "🇶🇦"),
    "Saudi Arabia": ("KSA", "🇸🇦"), "Scotland": ("SCO", "🏴󠁧󠁢󠁳󠁣󠁴󠁿"), "Senegal": ("SEN", "🇸🇳"),
    "South Africa": ("RSA", "🇿🇦"), "Spain": ("ESP", "🇪🇸"), "Sweden": ("SWE", "🇸🇪"),
    "Switzerland": ("SUI", "🇨🇭"), "Tunisia": ("TUN", "🇹🇳"), "Türkiye": ("TUR", "🇹🇷"),
    "United States": ("USA", "🇺🇸"), "Uruguay": ("URU", "🇺🇾"), "Uzbekistan": ("UZB", "🇺🇿"),
}

# Album default order = FIFA World Cup 2026 group draw.
GROUPS = {
    "A": ["Mexico", "South Africa", "Korea Republic", "Czechia"],
    "B": ["Canada", "Bosnia and Herzegovina", "Qatar", "Switzerland"],
    "C": ["Brazil", "Morocco", "Haiti", "Scotland"],
    "D": ["United States", "Paraguay", "Australia", "Türkiye"],
    "E": ["Germany", "Curaçao", "Côte d'Ivoire", "Ecuador"],
    "F": ["Netherlands", "Japan", "Sweden", "Tunisia"],
    "G": ["Belgium", "Egypt", "Iran", "New Zealand"],
    "H": ["Spain", "Cape Verde", "Saudi Arabia", "Uruguay"],
    "I": ["France", "Senegal", "Iraq", "Norway"],
    "J": ["Argentina", "Algeria", "Austria", "Jordan"],
    "K": ["Portugal", "DR Congo", "Uzbekistan", "Colombia"],
    "L": ["England", "Croatia", "Ghana", "Panama"],
}

OPENING = [
    ("00", "Panini Logo", None), ("FWC1", "Official Emblem", None),
    ("FWC2", "Official Emblem", None), ("FWC3", "Official Mascots", None),
    ("FWC4", "Official Slogan", None), ("FWC5", "Official Ball", None),
    ("FWC6", "Canada — Host Cities", "🇨🇦"), ("FWC7", "Mexico — Host Cities", "🇲🇽"),
    ("FWC8", "USA — Host Cities", "🇺🇸"),
]
# FIFA Museum foils FWC9-FWC19 (selected past champions). Positioned AFTER the teams in the album.
MUSEUM = [
    ("FWC9", "Italy 1934"), ("FWC10", "Uruguay 1950"), ("FWC11", "West Germany 1954"),
    ("FWC12", "Brazil 1962"), ("FWC13", "West Germany 1974"), ("FWC14", "Argentina 1986"),
    ("FWC15", "Brazil 1994"), ("FWC16", "Brazil 2002"), ("FWC17", "Italy 2006"),
    ("FWC18", "Germany 2014"), ("FWC19", "Argentina 2022"),
]
# Brazilian-edition under-the-label promo set (album pages 112-113). Order per
# clubedacopa.com.br, players cross-checked against coca-cola.com/br. The US
# edition has a different 12-sticker lineup — this album is the Brazilian one.
COCA_COLA = [
    ("Lamine Yamal", "🇪🇸"), ("Joshua Kimmich", "🇩🇪"), ("Harry Kane", "🏴󠁧󠁢󠁥󠁮󠁧󠁿"),
    ("Santiago Giménez", "🇲🇽"), ("Joško Gvardiol", "🇭🇷"), ("Federico Valverde", "🇺🇾"),
    ("Jefferson Lerma", "🇨🇴"), ("Enner Valencia", "🇪🇨"), ("Gabriel Magalhães", "🇧🇷"),
    ("Virgil van Dijk", "🇳🇱"), ("Alphonso Davies", "🇨🇦"), ("Emiliano Martínez", "🇦🇷"),
    ("Raúl Jiménez", "🇲🇽"), ("Lautaro Martínez", "🇦🇷"),
]

BRILLIANT, COMMON = "brilliant", "common"


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(here, "player_names.json"), encoding="utf-8") as f:
        names = json.load(f)  # {teamCode: {numberStr: name}}

    stickers = []
    order = 0

    def add(code, number, name, kind, category, section, team_code, flag, group):
        nonlocal order
        stickers.append({
            "code": code, "number": number, "order": order, "name": name,
            "kind": kind, "category": category, "section": section,
            "team_code": team_code, "flag": flag, "group": group,
        })
        order += 1

    for i, (code, name, flag) in enumerate(OPENING):
        add(code, i, name, BRILLIANT, "opening", "Opening", None, flag, None)

    named_count = 0
    for group_letter, team_names in GROUPS.items():
        for team_name in team_names:
            tcode, flag = TEAM_INFO[team_name]
            team_names_map = names.get(tcode, {})
            for n in range(1, 21):
                code = f"{tcode}{n}"
                if n == 1:
                    add(code, n, None, BRILLIANT, "team_logo", team_name, tcode, flag, group_letter)
                elif n == 13:
                    add(code, n, None, COMMON, "team_photo", team_name, tcode, flag, group_letter)
                else:
                    player_name = team_names_map.get(str(n))
                    if player_name:
                        named_count += 1
                    add(code, n, player_name, COMMON, "player", team_name, tcode, flag, group_letter)

    # FIFA Museum comes after all the teams in the album.
    for code, museum_name in MUSEUM:
        num = int(code.replace("FWC", ""))
        add(code, num, museum_name, BRILLIANT, "museum", "FIFA Museum", None, "🏆", None)

    for i, (pname, flag) in enumerate(COCA_COLA, start=1):
        add(f"CC{i}", i, pname, COMMON, "special", "Coca-Cola", None, flag, None)

    # ---- sanity checks ----
    assert len(stickers) == 994, f"expected 994, got {len(stickers)}"
    assert sum(1 for s in stickers if s["kind"] == BRILLIANT) == 68
    assert len({s["code"] for s in stickers}) == 994, "duplicate codes!"
    assert len({s["group"] for s in stickers if s["group"]}) == 12, "expected 12 groups"
    assert len(TEAM_INFO) == 48 and sum(len(v) for v in GROUPS.values()) == 48

    out_dir = os.path.join(os.path.dirname(here),
                           "AlbumTracker", "Resources", "BundledData", "world-cup-2026")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "stickers.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(stickers, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Wrote {len(stickers)} stickers, {named_count}/864 player names filled -> {out_path}")


if __name__ == "__main__":
    main()
