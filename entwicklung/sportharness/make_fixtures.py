#!/usr/bin/env python3
"""Baut Musterdaten fuer die Vorschau des Sport-Tabs: rohe Antworten im Format von ESPN und SIHF,
durch das echte Hilfsprogramm geschickt (ohne Netz). Logos sind Platzhalter (Farbkreis mit
Initiale), damit die Vorschau Bilder hat.

    python3 make_fixtures.py   -> fixtures/*.json, fixtures/logos/*.png
"""
import importlib.machinery, importlib.util, json, os, re, sys
from datetime import date

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "fixtures")
os.makedirs(OUT, exist_ok=True)
os.environ["XDG_CACHE_HOME"] = os.path.join(OUT, "cache")
os.environ["ALPE_SPORT_TODAY"] = "2026-11-18"

loader = importlib.machinery.SourceFileLoader("sport", os.path.join(HERE, "..", "..", "plugins", "alpeSport", "sport"))
spec = importlib.util.spec_from_loader("sport", loader)
S = importlib.util.module_from_spec(spec); loader.exec_module(S)

from PIL import Image, ImageDraw, ImageFont

COLORS = {}


def crest_png(key):
    color = COLORS.get(key, "#555555")
    img = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((8, 8, 152, 152), fill=color, outline="white", width=8)
    try:
        font = ImageFont.truetype(os.path.expanduser("~/.fonts/InterVariable.ttf"), 64)
    except OSError:
        font = None
    letter = (key[:1] or "?").upper()
    d.text((80, 82), letter, fill="white", anchor="mm", font=font)
    from io import BytesIO
    buf = BytesIO(); img.save(buf, "PNG"); return buf.getvalue()


def team(tid, name, abbr, color, short=None):
    COLORS[str(tid)] = color
    return {"id": str(tid), "displayName": name, "shortDisplayName": short or name, "abbreviation": abbr,
            "color": color.lstrip("#"), "logo": "https://a.espncdn.com/i/teamlogos/soccer/500/%s.png" % tid}


def comp(side, t, score, winner=False, **extra):
    return dict({"homeAway": side, "team": t, "score": str(score), "winner": winner}, **extra)


def event(eid, when, name, state, home, away, clock="", period=0, short="", note=""):
    c = {"competitors": [home, away], "venue": {"fullName": ""}}
    if note:
        c["notes"] = [{"headline": note}]
    return {"id": str(eid), "date": when, "status": {"displayClock": clock, "period": period,
            "type": {"name": name, "state": state, "shortDetail": short}}, "competitions": [c]}


# --------------------------------------------------------------- Fussball: DFB-Pokal und Bundesliga
BAY = team(132, "Bayern Munich", "BAY", "#dc052d", "Bayern")
SCF = team(125, "SC Freiburg", "SCF", "#111111", "Freiburg")
DOR = team(124, "Borussia Dortmund", "BVB", "#fde100", "Dortmund")
B04 = team(131, "Bayer Leverkusen", "B04", "#e32221", "Leverkusen")
STU = team(134, "VfB Stuttgart", "VFB", "#e32219", "Stuttgart")
HSV = team(3600, "Hamburger SV", "HSV", "#0a3f86", "Hamburg")
MAI = team(2950, "Mainz", "M05", "#c3141e")
FCU = team(598, "1. FC Union Berlin", "FCU", "#d4011d", "Union Berlin")
INT = team(110, "Internazionale", "INT", "#0068a8", "Inter")
TOR = team(239, "Torino", "TOR", "#8a1e03")
RMA = team(86, "Real Madrid", "RMA", "#febe10", "Real Madrid")
CEL = team(85, "Celta Vigo", "CEL", "#8ac3ee", "Celta")

pokal = {"leagues": [{"logos": [{"href": "https://a.espncdn.com/i/leaguelogos/soccer/500/2061.png"}]}], "events": [
    event(1, "2026-11-18T17:00Z", "STATUS_FULL_TIME", "post", comp("home", HSV, 1), comp("away", STU, 3, True), note="Round of 16"),
    event(2, "2026-11-18T17:00Z", "STATUS_FINAL_PEN", "post", comp("home", FCU, 2, False, shootoutScore=3), comp("away", B04, 2, True, shootoutScore=4), note="Round of 16"),
    event(3, "2026-11-18T19:45Z", "STATUS_SECOND_HALF", "in", comp("home", BAY, 2), comp("away", SCF, 1), clock="67'", period=2, note="Round of 16"),
    event(4, "2026-11-18T19:45Z", "STATUS_HALFTIME", "in", comp("home", DOR, 0), comp("away", MAI, 0), clock="45'", period=1, note="Round of 16"),
]}
coppa = {"events": [
    event(11, "2026-11-18T20:00Z", "STATUS_SCHEDULED", "pre", comp("home", INT, 0), comp("away", TOR, 0), note="Round of 16"),
]}
copa = {"events": [
    event(21, "2026-11-18T20:30Z", "STATUS_SCHEDULED", "pre", comp("home", CEL, 0), comp("away", RMA, 0), note="Second Round"),
]}

# Bundesliga-Tabelle (18 Teams)
BL = [("Bayern Munich", "BAY", "#dc052d", 132), ("Borussia Dortmund", "BVB", "#fde100", 124), ("RB Leipzig", "RBL", "#dd0741", 11420),
      ("Bayer Leverkusen", "B04", "#e32221", 131), ("VfB Stuttgart", "VFB", "#e32219", 134), ("Eintracht Frankfurt", "SGE", "#e1000f", 125 + 1000),
      ("SC Freiburg", "SCF", "#111111", 125), ("1. FC Union Berlin", "FCU", "#d4011d", 598), ("Werder Bremen", "SVW", "#1d9053", 137),
      ("TSG Hoffenheim", "TSG", "#1961b5", 7911), ("Borussia Mönchengladbach", "BMG", "#000000", 268), ("VfL Wolfsburg", "WOB", "#65b32e", 138),
      ("FC Augsburg", "FCA", "#ba3733", 3841), ("Hamburger SV", "HSV", "#0a3f86", 3600), ("1. FC Köln", "KOE", "#ed1c24", 122),
      ("Mainz", "M05", "#c3141e", 2950), ("1. FC Heidenheim", "HDH", "#e2001a", 6418), ("FC St. Pauli", "STP", "#6d4c41", 270)]
notes = {1: "Champions League", 2: "Champions League", 3: "Champions League", 4: "Champions League", 5: "Europa League",
         6: "Conference League Qualifiers", 16: "Relegation Playoff", 17: "Relegation", 18: "Relegation"}
entries = []
pts = 31
for i, (name, abbr, color, tid) in enumerate(BL, 1):
    t = team(tid, name, abbr, color); t["logos"] = [{"href": t.pop("logo")}]
    w = max(0, 10 - i // 2); d = (i * 3) % 5; l = 11 - w - d
    gf, ga = 30 - i, 8 + i
    stats = [{"name": "gamesPlayed", "displayValue": "11"}, {"name": "wins", "displayValue": str(w)}, {"name": "ties", "displayValue": str(d)},
             {"name": "losses", "displayValue": str(l)}, {"name": "pointsFor", "displayValue": str(gf)}, {"name": "pointsAgainst", "displayValue": str(ga)},
             {"name": "pointDifferential", "displayValue": "%+d" % (gf - ga)}, {"name": "points", "displayValue": str(w * 3 + d)},
             {"name": "rank", "displayValue": str(i)}]
    entries.append({"team": t, "stats": stats, "note": {"description": notes[i], "color": "#81D6AC"} if i in notes else None})
bl_standings = {"children": [{"name": "2026-27 German Bundesliga", "standings": {"entries": entries}}]}

# Bundesliga-Spiele fuer Form und Spielplan
bl_events = []
pairs = [(BL[0], BL[13]), (BL[1], BL[4]), (BL[2], BL[6]), (BL[3], BL[15]), (BL[5], BL[7]), (BL[8], BL[9]),
         (BL[10], BL[11]), (BL[12], BL[14]), (BL[16], BL[17])]
eid = 100
for week, day_ in enumerate(["2026-10-25", "2026-11-01", "2026-11-08", "2026-11-22", "2026-11-29"]):
    for k, ((hn, ha, hc, hi), (an, aa, ac, ai)) in enumerate(pairs):
        if week % 2:
            (hn, ha, hc, hi), (an, aa, ac, ai) = (an, aa, ac, ai), (hn, ha, hc, hi)
        eid += 1
        h = team(hi, hn, ha, hc); a = team(ai, an, aa, ac)
        if day_ < "2026-11-18":
            hs, as_ = (eid * 7) % 4, (eid * 3) % 3
            bl_events.append(event(eid, day_ + "T%02d:30Z" % (14 + k % 3 * 2), "STATUS_FULL_TIME", "post", comp("home", h, hs, hs > as_), comp("away", a, as_, as_ > hs)))
        else:
            bl_events.append(event(eid, day_ + "T%02d:30Z" % (14 + k % 3 * 2), "STATUS_SCHEDULED", "pre", comp("home", h, 0), comp("away", a, 0)))
bl_board = {"leagues": [{"logos": [{"href": "https://a.espncdn.com/i/leaguelogos/soccer/500/10.png"}]}], "events": bl_events}

# Spieldetail Bayern - Freiburg (laeuft)
roster = lambda rows: [{"starter": s, "jersey": j, "athlete": {"displayName": n, "id": "9%03d" % int(j)}, "position": {"abbreviation": p}, "formationPlace": f, **x}
                       for s, j, n, p, f, x in rows]
summary = {
    "header": {"id": "3", "competitions": [{"date": "2026-11-18T19:45Z", "notes": [{"headline": "Round of 16"}],
        "status": {"displayClock": "67'", "period": 2, "type": {"name": "STATUS_SECOND_HALF", "state": "in", "shortDetail": "67'"}},
        "competitors": [
            {"homeAway": "home", "score": "2", "team": dict(BAY, logos=[{"href": BAY["logo"]}]), "linescores": [{"displayValue": "1"}, {"displayValue": "1"}]},
            {"homeAway": "away", "score": "1", "team": dict(SCF, logos=[{"href": SCF["logo"]}]), "linescores": [{"displayValue": "1"}, {"displayValue": "0"}]}]}]},
    "gameInfo": {"venue": {"fullName": "Allianz Arena"}, "attendance": 75000, "officials": [{"displayName": "Deniz Aytekin"}]},
    "keyEvents": [
        {"type": {"type": "goal"}, "clock": {"displayValue": "12'"}, "team": {"id": "132"}, "scoringPlay": True,
         "participants": [{"athlete": {"displayName": "Harry Kane"}}, {"athlete": {"displayName": "Michael Olise"}}],
         "text": "Goal! Bayern Munich 1, SC Freiburg 0. Harry Kane header."},
        {"type": {"type": "yellow-card"}, "clock": {"displayValue": "29'"}, "team": {"id": "125"}, "participants": [{"athlete": {"displayName": "Maximilian Eggestein"}}]},
        {"type": {"type": "goal"}, "clock": {"displayValue": "41'"}, "team": {"id": "125"}, "scoringPlay": True,
         "participants": [{"athlete": {"displayName": "Vincenzo Grifo"}}], "text": "Goal! Bayern Munich 1, SC Freiburg 1. Vincenzo Grifo free kick."},
        {"type": {"type": "halftime"}, "clock": {"displayValue": "45'+2'"}},
        {"type": {"type": "substitution"}, "clock": {"displayValue": "58'"}, "team": {"id": "132"},
         "text": "Substitution, Bayern Munich. Lennart Karl replaces Serge Gnabry."},
        {"type": {"type": "penalty---scored"}, "clock": {"displayValue": "63'"}, "team": {"id": "132"}, "scoringPlay": True,
         "participants": [{"athlete": {"displayName": "Harry Kane"}}], "text": "Goal! Bayern Munich 2, SC Freiburg 1. Harry Kane penalty."},
        {"type": {"type": "yellow-card"}, "clock": {"displayValue": "65'"}, "team": {"id": "132"}, "participants": [{"athlete": {"displayName": "Joshua Kimmich"}}]},
    ],
    "boxscore": {"teams": [
        {"team": {"id": "132"}, "statistics": [{"name": n, "displayValue": v} for n, v in [("possessionPct", "64.3"), ("totalShots", "17"), ("shotsOnTarget", "7"), ("wonCorners", "6"), ("totalPasses", "512"), ("passPct", "0.89"), ("foulsCommitted", "8"), ("offsides", "2"), ("yellowCards", "1"), ("saves", "1")]]},
        {"team": {"id": "125"}, "statistics": [{"name": n, "displayValue": v} for n, v in [("possessionPct", "35.7"), ("totalShots", "6"), ("shotsOnTarget", "2"), ("wonCorners", "2"), ("totalPasses", "284"), ("passPct", "0.78"), ("foulsCommitted", "11"), ("offsides", "1"), ("yellowCards", "1"), ("saves", "5")]]}]},
    "rosters": [
        {"homeAway": "home", "team": {"id": "132"}, "formation": "4-2-3-1", "roster": roster([
            (True, "1", "Manuel Neuer", "G", "1", {}), (True, "27", "Konrad Laimer", "RB", "2", {}), (True, "2", "Dayot Upamecano", "CD-R", "5", {}),
            (True, "4", "Jonathan Tah", "CD-L", "6", {}), (True, "44", "Josip Stanisic", "LB", "3", {}), (True, "6", "Joshua Kimmich", "DM-R", "4", {"plays": [{"yellowCard": True}]}),
            (True, "45", "Aleksandar Pavlovic", "DM-L", "8", {}), (True, "17", "Michael Olise", "RM", "7", {}), (True, "10", "Jamal Musiala", "AM", "10", {}),
            (True, "7", "Serge Gnabry", "LM", "11", {"subbedOut": True}), (True, "9", "Harry Kane", "F", "9", {"plays": [{"didScore": True}, {"didScore": True}]}),
            (False, "42", "Lennart Karl", "SUB", "0", {"subbedIn": True}), (False, "26", "Sven Ulreich", "SUB", "0", {}), (False, "8", "Leon Goretzka", "SUB", "0", {})])},
        {"homeAway": "away", "team": {"id": "125"}, "formation": "4-4-2", "roster": roster([
            (True, "1", "Noah Atubolu", "G", "1", {}), (True, "29", "Philipp Lienhart", "CD-R", "5", {}), (True, "28", "Matthias Ginter", "CD-L", "6", {}),
            (True, "17", "Lukas Kübler", "RB", "2", {}), (True, "30", "Christian Günter", "LB", "3", {}), (True, "8", "Maximilian Eggestein", "CM-R", "4", {"plays": [{"yellowCard": True}]}),
            (True, "27", "Nicolas Höfler", "CM-L", "8", {}), (True, "42", "Ritsu Doan", "RM", "7", {}), (True, "32", "Vincenzo Grifo", "LM", "11", {"plays": [{"didScore": True}]}),
            (True, "9", "Lucas Höler", "CF-R", "9", {}), (True, "38", "Michael Gregoritsch", "CF-L", "10", {})])},
    ],
}

# --------------------------------------------------------------- NBA (frueh am Morgen, Ortszeit)
def nba(tid, name, abbr, color):
    t = team(tid, name, abbr, color); t["logo"] = "https://a.espncdn.com/i/teamlogos/nba/500/%s.png" % abbr.lower(); COLORS[str(tid)] = color
    return t
BOS, MIL, LAL, GSW, DEN, OKC = nba(2, "Boston Celtics", "BOS", "#007a33"), nba(15, "Milwaukee Bucks", "MIL", "#00471b"), nba(13, "Los Angeles Lakers", "LAL", "#552583"), \
    nba(9, "Golden State Warriors", "GSW", "#1d428a"), nba(7, "Denver Nuggets", "DEN", "#0e2240"), nba(25, "Oklahoma City Thunder", "OKC", "#007ac1")
nba_board = {"events": [
    event(31, "2026-11-18T00:30Z", "STATUS_FINAL", "post", comp("home", BOS, 118, True, records=[{"summary": "12-2"}]), comp("away", MIL, 104, records=[{"summary": "1-13"}]), period=4, short="Final"),
    event(32, "2026-11-18T03:00Z", "STATUS_FINAL", "post", comp("home", DEN, 121), comp("away", OKC, 125, True), period=5, short="Final/OT"),
    event(33, "2026-11-18T03:30Z", "STATUS_FINAL", "post", comp("home", LAL, 109, True), comp("away", GSW, 101), period=4, short="Final"),
]}

# --------------------------------------------------------------- National League
NL = [(101144, "EV Zug", "EVZ"), (103140, "Genève-Servette HC", "GSHC"), (101139, "ZSC Lions", "ZSC"), (103141, "Lausanne HC", "LHC"),
      (102126, "SC Bern", "SCB"), (101151, "HC Davos", "HCD"), (103138, "Fribourg-Gottéron", "FRI"), (101149, "EHC Kloten", "EHCK"),
      (101150, "HC Lugano", "HCL"), (101060, "SC Rapperswil-Jona Lakers", "SCRJ"), (102128, "EHC Biel-Bienne", "EHCB"),
      (101152, "HC Ambri-Piotta", "HCAP"), (102127, "SCL Tigers", "SCL"), (103144, "HC Ajoie", "HCA")]
nt = lambda i: {"id": NL[i][0], "name": NL[i][1], "acronym": NL[i][2], "signed": False, "type": "team", "clubId": NL[i][0]}
HEADER = [{"alias": a} for a in ("day", "date", "time", "homeTeam", "awayTeam", "score", "scorePerPeriod", "decision", "status", "details", "broadcasts")]
def nl_row(h, a, when, sid, name, hs, as_, ph, pa, gid, decision=""):
    return ["Mi", "", "", nt(h), nt(a), {"homeTeam": hs, "awayTeam": as_}, {"homeTeam": ph, "awayTeam": pa}, decision,
            {"id": sid, "startDateTime": when, "percent": 0 if sid == 0 else 100 if sid == 12 else 50, "name": name, "canceled": False},
            {"gameId": gid}, {"entries": ["MYSPORTS"]}]
nl_day = {"header": HEADER, "data": [
    nl_row(0, 13, "2026-11-18T19:45:00+01:00", 5, "2. Drittel", "3", "1", ["2", "1", "-"], ["0", "1", "-"], "20271105000098"),
    nl_row(4, 5, "2026-11-18T19:45:00+01:00", 5, "2. Drittel", "1", "1", ["1", "0", "-"], ["0", "1", "-"], "20271105000099"),
    nl_row(2, 8, "2026-11-18T19:45:00+01:00", 4, "Pause", "0", "2", ["0", "-", "-"], ["2", "-", "-"], "20271105000100"),
    nl_row(1, 7, "2026-11-18T19:45:00+01:00", 5, "2. Drittel", "2", "2", ["1", "1", "-"], ["1", "1", "-"], "20271105000101"),
    nl_row(3, 12, "2026-11-18T20:00:00+01:00", 5, "1. Drittel", "0", "0", ["0", "-", "-"], ["0", "-", "-"], "20271105000102"),
]}
SH = [{"alias": a} for a in ("rank", "team", "gamesPlayed", "points", "pointsQuotient", "gamesWonInTime", "gamesWonExtraTime", "gamesWonPenalty",
                              "gamesLostPenalty", "gamesLostExtraTime", "gamesLostInTime", "goalsFor", "goalsAgainst", "goalsDifference", "streak")]
nl_table = {"header": SH, "data": [[str(i + 1), nt(i), "19", str(42 - i * 2), "", str(13 - i // 2), "1", "1", "1", "0", str(2 + i // 2),
                                    str(70 - i * 2), str(40 + i * 2), "", ""] for i in range(14)]}

# --------------------------------------------------------------- Alpe: Bestenlisten, Spieler
def leader(aid, name, t, value, games):
    return {"displayValue": "Matches: %d, Goals: %d" % (games, value), "value": float(value),
            "athlete": {"id": aid, "displayName": name, "shortName": name,
                        "team": {"id": t["id"], "displayName": t["displayName"], "abbreviation": t["abbreviation"],
                                 "logos": [{"href": t["logo"]}]}}}
bl_stats = {"stats": [
    {"name": "goalsLeaders", "displayName": "Goals", "leaders": [
        leader("9009", "Harry Kane", BAY, 16, 11), leader("2", "Serhou Guirassy", DOR, 9, 11), leader("3", "Deniz Undav", STU, 8, 10),
        leader("4", "Patrik Schick", B04, 7, 11), leader("5", "Vincenzo Grifo", SCF, 6, 11)]},
    {"name": "assistsLeaders", "displayName": "Assists", "leaders": [
        leader("9017", "Michael Olise", BAY, 7, 11), leader("7", "Julian Brandt", DOR, 5, 11), leader("8", "Grischa Prömel", STU, 4, 9)]}]}
athlete = {"athlete": {"displayName": "Harry Kane", "position": {"name": "Forward"}, "age": 33, "jersey": "9", "citizenship": "England",
                       "displayHeight": "6' 2\"", "team": {"id": "132", "displayName": "Bayern Munich", "logos": [{"href": BAY["logo"]}]}}}
overview = {"statistics": {"labels": ["STRT", "G", "A", "SHOT", "SOG", "YC"], "names": ["starts", "totalGoals", "goalAssists", "totalShots", "shotsOnTarget", "yellowCards"],
                           "splits": [{"displayName": "2026-27 German Bundesliga", "stats": ["11", "16", "3", "48", "27", "1"]},
                                      {"displayName": "2026-27 UEFA Champions League", "stats": ["4", "5", "1", "17", "9", "0"]}]}}
PH = [{"name": n} for n in ("R", "Spieler", "Team", "Pos", "GP", "G", "A", "PTS", "P/GP", "PIM Total", "+/-")]
nl_players = {"header": PH, "data": [[str(i + 1), name, nt(team_i), "Stürmer", "20", str(g), str(a), str(g + a), "%.2f" % ((g + a) / 20), "6", "%+d" % pm]
                                       for i, (name, team_i, g, a, pm) in enumerate([
                                           ("Kovar Jan", 0, 9, 18, 12), ("Hofmann Grégory", 0, 12, 13, 9), ("Malgin Denis", 2, 6, 19, 10),
                                           ("Tanus Kristian", 13, 6, 22, -1), ("Järventie Roby", 11, 12, 15, 7), ("Ritzmann Marco", 1, 7, 14, 4)])]}
GH = [{"name": n} for n in ("R", "Spieler", "Team", "GP", "GPI", "GA", "GAA", "SA", "SVS", "SVS%", "MIP", "PIM", "G", "A")]
nl_goalies = {"header": GH, "data": [["1", "Genoni Leonardo", nt(0), "12", "12", "22", "1.84", "295", "273", "92.54", "718:03", "0", "0", "0"],
                                     ["2", "Wolf Simon", nt(4), "11", "10", "20", "1.95", "284", "264", "92.96", "615:33", "0", "0", "0"]]}

# --------------------------------------------------------------- durch das echte Programm
ROUTES = [("ger.dfb_pokal/scoreboard", pokal), ("ita.coppa_italia/scoreboard", coppa), ("esp.copa_del_rey/scoreboard", copa),
          ("nba/scoreboard", nba_board), ("ger.1/standings", bl_standings), ("ger.1/scoreboard", bl_board),
          ("summary?event=3", summary), ("alias=standing", nl_table), ("alias=results", nl_day),
          ("ger.1/statistics", bl_stats), ("/overview", overview), ("athletes/9009", athlete),
          ("alias=goalkeeper", nl_goalies), ("alias=player", nl_players)]


NATI_HTML = """<table><tr><th>Datum</th><th>Event</th><th>Ort</th><th>Heim</th><th>Gast</th><th>Resultat</th></tr>
<tr><td>13.12.2026</td><td>SWISS Ice Hockey Games</td><td>Zürich / SUI</td><td>Switzerland</td><td>Finland</td><td>0:0</td></tr>
<tr><td>12.12.2026</td><td>SWISS Ice Hockey Games</td><td>Zürich / SUI</td><td>Switzerland</td><td>Czechia</td><td>0:0</td></tr>
<tr><td>10.12.2026</td><td>SWISS Ice Hockey Games</td><td>Zürich / SUI</td><td>Sweden</td><td>Switzerland</td><td>0:0</td></tr>
<tr><td>08.11.2026</td><td>NOCCO Hockey Games, Finland</td><td>Helsinki / FIN</td><td>Czechia</td><td>Switzerland</td><td>4:2</td></tr>
<tr><td>07.11.2026</td><td>NOCCO Hockey Games, Finland</td><td>Helsinki / FIN</td><td>Sweden</td><td>Switzerland</td><td>4:2</td></tr>
<tr><td>05.11.2026</td><td>NOCCO Hockey Games, Finland</td><td>Helsinki / FIN</td><td>Switzerland</td><td>Finland</td><td>1:3</td></tr>
<tr><td>31.05.2026</td><td>2026 IIHF Ice Hockey World Championship / Gold Medal Game</td><td>Swiss Life Arena, Zurich</td><td>Switzerland</td><td>Finland</td><td>0:1 (OT)</td></tr>
</table>"""


def get(url):
    if "sihf.ch/de/nationalteams" in url:
        return NATI_HTML.encode()
    if "countries/500/" in url:
        code = url.split("countries/500/")[1].split(".")[0]
        return crest_png_initial(code.upper(), {"sui": "#d52b1e", "fin": "#003580", "swe": "#006aa7", "cze": "#11457e"}.get(code, "#555555"))
    m = re.search(r"img=/i/(?:teamlogos|leaguelogos)/\w+/500/([\w.]+)\.png", url)
    if m:
        key = m.group(1)
        for tid, color in COLORS.items():
            if tid == key:
                return crest_png_named(tid)
        for t in (BOS, MIL, LAL, GSW, DEN, OKC):
            if t["abbreviation"].lower() == key:
                return crest_png_named(t["id"])
        return crest_png_named(key)
    for needle, payload in ROUTES:
        if needle in url:
            return json.dumps(payload).encode()
    return json.dumps({"events": []}).encode()


NAMES = {}
for t in (BAY, SCF, DOR, B04, STU, HSV, MAI, FCU, INT, TOR, RMA, CEL, BOS, MIL, LAL, GSW, DEN, OKC):
    NAMES[t["id"]] = t["shortDisplayName"]
for name, abbr, color, tid in BL:
    NAMES.setdefault(str(tid), name); COLORS.setdefault(str(tid), color)


def crest_png_named(tid):
    return crest_png_initial(NAMES.get(str(tid), "Liga"), COLORS.get(str(tid), "#3a5a8c"))


def crest_png_initial(name, color):
    COLORS["_"] = color
    img = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((8, 8, 152, 152), fill=color, outline="white", width=8)
    font = ImageFont.truetype(os.path.expanduser("~/.fonts/InterVariable.ttf"), 70)
    letter = re.sub(r"^(1\. FC |FC |SC |VfB |VfL |TSG |Borussia |Bayer )", "", name)[:1].upper()
    d.text((80, 84), letter, fill="white" if color.lower() not in ("#fde100", "#febe10", "#8ac3ee") else "black", anchor="mm", font=font)
    from io import BytesIO
    buf = BytesIO(); img.save(buf, "PNG"); return buf.getvalue()


S.http_get = get
write = lambda name, data: json.dump(data, open(os.path.join(OUT, name), "w"), ensure_ascii=False, indent=1)
write("leagues.json", S.command_leagues())
write("day.json", S.command_day(date(2026, 11, 18), ["nl", "sui.hockey", "sui.nt", "nba", "ger.dfb_pokal", "ita.coppa_italia", "esp.copa_del_rey", "eng.1", "ger.1"]))
write("league-ger.1.json", S.command_league("ger.1"))
write("league-nl.json", S.command_league("nl"))
write("league-sui.hockey.json", S.command_league("sui.hockey"))
write("match-ger.dfb_pokal-3.json", S.command_match("ger.dfb_pokal", "3"))
write("stats-ger.1.json", S.command_stats("ger.1"))
write("stats-nl.json", S.command_stats("nl"))
write("player-ger.1.json", S.command_player("ger.1", "9009"))
write("player-ger.dfb_pokal.json", S.command_player("ger.dfb_pokal", "9009"))
write("player-nl.json", S.command_player("nl", "Genoni Leonardo"))
os.environ["ALPE_SPORT_NOTIFY_LOG"] = os.path.join(OUT, "cache", "notify.jsonl")
write("watch.json", S.command_watch(["hockey:101144", "soccer:132"], ["nl", "ger.dfb_pokal"], ["goal"]))
write("cache.json", {"bytes": 4321000, "files": 312, "path": "~/.cache/alpe/sport"})
print("Musterdaten in", OUT)
