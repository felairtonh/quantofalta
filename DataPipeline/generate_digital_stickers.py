#!/usr/bin/env python3
"""
Generates the bundled catalog for the FIFA Panini Collection DIGITAL album
(the Panini x Coca-Cola app, where the user makes swap requests).

Structure per the checklist published by cartophilic-info-exch.blogspot.com
("Panini - FIFA World Cup 2026 Digital Collection", May 2026), reconciled with
the user's app where the sets are regional:
  - Intro: "00" Panini logo + FWC1-8 (Emblem x2, Mascots, Slogan, Ball,
    Canada / Mexico / USA "We Are 26" emblems) — mirrors the physical
    album's opening                                                  -> 9 brilliant
  - 48 teams x 12: slot 0 = team emblem FOIL, slots 1-11 = players   -> 576
  - "#AllTheFeels": Coca-Cola set — the user's app shows the
    14-sticker Brazilian lineup (the blog documents a 12 US set)     -> 14
  - Host City Posters: 16, in the checklist's printed order          -> 16
  - Update Edition: 2 new players per team (Neymar Jr is the only
    player absent from the physical collection)                      -> 96
  - Fan Stickers: one per team, unnamed even in the checklist        -> 48
  - McDonald's: user's app shows 8 (blog documents 6 — regional)     -> 8
  - Trophy Tour: Coca-Cola + 30 tour countries                       -> 31
  Total = 798 (57 brilliant).

Player names come from `digital_player_names.json` (528 players + 96 update),
best-effort transcription — editable in-app.

Output: AlbumTracker/Resources/BundledData/fifa-panini-collection/stickers.json
Run:    python3 DataPipeline/generate_digital_stickers.py
"""

import json
import os

# Reuse the physical album's team order (FIFA group draw) and metadata.
from generate_stickers import TEAM_INFO, GROUPS, COCA_COLA

INTRO = [
    ("00",   "Panini Logo", None),
    ("FWC1", "Official Emblem", None),
    ("FWC2", "Official Emblem", None),
    ("FWC3", "Official Mascots", None),
    ("FWC4", "Official Slogan", None),
    ("FWC5", "Official Ball", None),
    ("FWC6", "We Are 26 — Canada", "🇨🇦"),
    ("FWC7", "We Are 26 — Mexico", "🇲🇽"),
    ("FWC8", "We Are 26 — USA", "🇺🇸"),
]

# In the checklist's printed order.
HOST_CITIES = [
    ("Philadelphia", "🇺🇸"), ("Houston", "🇺🇸"), ("Atlanta", "🇺🇸"),
    ("Mexico City", "🇲🇽"), ("Los Angeles", "🇺🇸"), ("Kansas City", "🇺🇸"),
    ("Dallas", "🇺🇸"), ("Boston", "🇺🇸"), ("Miami", "🇺🇸"),
    ("Monterrey", "🇲🇽"), ("Vancouver", "🇨🇦"), ("Seattle", "🇺🇸"),
    ("Toronto", "🇨🇦"), ("New York New Jersey", "🇺🇸"),
    ("San Francisco Bay Area", "🇺🇸"), ("Guadalajara", "🇲🇽"),
]

# Coca-Cola sticker first, then the 30 tour countries.
TROPHY_TOUR = [
    ("Coca-Cola", None),
    ("Algeria", "🇩🇿"), ("Argentina", "🇦🇷"), ("Austria", "🇦🇹"),
    ("Bangladesh", "🇧🇩"), ("Brazil", "🇧🇷"), ("Canada", "🇨🇦"),
    ("Colombia", "🇨🇴"), ("Ecuador", "🇪🇨"), ("Egypt", "🇪🇬"),
    ("France", "🇫🇷"), ("Guatemala", "🇬🇹"), ("Honduras", "🇭🇳"),
    ("India", "🇮🇳"), ("Indonesia", "🇮🇩"), ("Ivory Coast", "🇨🇮"),
    ("Japan", "🇯🇵"), ("Kazakhstan", "🇰🇿"), ("Malaysia", "🇲🇾"),
    ("Mexico", "🇲🇽"), ("Morocco", "🇲🇦"), ("Portugal", "🇵🇹"),
    ("Saudi Arabia", "🇸🇦"), ("South Africa", "🇿🇦"), ("South Korea", "🇰🇷"),
    ("Spain", "🇪🇸"), ("Thailand", "🇹🇭"), ("Turkey", "🇹🇷"),
    ("Uruguay", "🇺🇾"), ("USA", "🇺🇸"), ("Uzbekistan", "🇺🇿"),
]

FAN_COUNT = 48        # one per team, art still "coming soon" in the app
MCDONALDS_COUNT = 8   # user's regional app count (blog documents 6)

BRILLIANT, COMMON = "brilliant", "common"


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(here, "digital_player_names.json"), encoding="utf-8") as f:
        names = {k: v for k, v in json.load(f).items() if not k.startswith("_")}

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

    for i, (code, name, flag) in enumerate(INTRO):
        add(code, i, name, BRILLIANT, "opening", "Intro", None, flag, None)

    # Teams: slot 0 = emblem foil, slots 1-11 = players (no team photo).
    named = 0
    for group_letter, team_names in GROUPS.items():
        for team_name in team_names:
            tcode, flag = TEAM_INFO[team_name]
            roster = names.get(tcode, {}).get("players", [])
            add(f"{tcode}0", 0, None, BRILLIANT, "team_logo", team_name, tcode, flag, group_letter)
            for n in range(1, 12):
                player = roster[n - 1] if len(roster) >= n else None
                if player:
                    named += 1
                add(f"{tcode}{n}", n, player, COMMON, "player", team_name, tcode, flag, group_letter)

    # #AllTheFeels — the user's app shows the same 14 players as the physical
    # Brazilian Coca-Cola set.
    for i, (pname, flag) in enumerate(COCA_COLA, start=1):
        add(f"CC{i}", i, pname, COMMON, "special", "#AllTheFeels", None, flag, None)

    for i, (city, flag) in enumerate(HOST_CITIES, start=1):
        add(f"HC{i}", i, city, COMMON, "host_city", "Host City Posters", None, flag, None)

    # Update Edition: one page per group, 2 stickers per team in draw order.
    for group_letter, team_names in GROUPS.items():
        for team_name in team_names:
            tcode, flag = TEAM_INFO[team_name]
            update = names.get(tcode, {}).get("update", [])
            for n in (1, 2):
                player = update[n - 1] if len(update) >= n else None
                if player:
                    named += 1
                add(f"{tcode}U{n}", n, player, COMMON, "update",
                    "Update Edition", tcode, flag, group_letter)

    # Fan Stickers: one per team (earned by trading for that country's first
    # player), in team/draw order — named after the team.
    fan_i = 0
    for group_letter, team_names in GROUPS.items():
        for team_name in team_names:
            fan_i += 1
            tcode, flag = TEAM_INFO[team_name]
            add(f"FAN{fan_i}", fan_i, team_name, COMMON, "extra",
                "Fan Stickers", tcode, flag, group_letter)
    assert fan_i == FAN_COUNT

    for i in range(1, MCDONALDS_COUNT + 1):
        add(f"MCD{i}", i, None, COMMON, "extra", "McDonald's", None, None, None)

    for i, (name, flag) in enumerate(TROPHY_TOUR, start=1):
        add(f"TT{i}", i, name, COMMON, "extra", "Trophy Tour", None, flag or "🏆", None)

    # ---- sanity checks ----
    assert len(stickers) == 798, f"expected 798, got {len(stickers)}"
    assert sum(1 for s in stickers if s["kind"] == BRILLIANT) == 57
    assert len({s["code"] for s in stickers}) == 798, "duplicate codes!"
    assert sum(1 for s in stickers if s["category"] == "player") == 528
    assert sum(1 for s in stickers if s["category"] == "update") == 96
    assert named == 528 + 96, f"expected 624 names, got {named}"
    assert len(TROPHY_TOUR) == 31

    out_dir = os.path.join(os.path.dirname(here),
                           "AlbumTracker", "Resources", "BundledData", "fifa-panini-collection")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "stickers.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(stickers, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Wrote {len(stickers)} digital stickers ({named} names) -> {out_path}")


if __name__ == "__main__":
    main()
