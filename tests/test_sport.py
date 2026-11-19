"""Tests fuer plugins/alpeSport/sport. Ohne Netz: die Antworten der Quellen sind nachgebaut,
gekuerzt nach echten Antworten von data.sihf.ch und site.api.espn.com (November 2026)."""
import importlib.machinery, importlib.util, json, os, tempfile, urllib.error
from datetime import date, datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
PNG = b"\x89PNG\r\n\x1a\n" + b"\0" * 16


def load():
    loader = importlib.machinery.SourceFileLoader("sport_mod", os.path.join(HERE, "..", "plugins", "alpeSport", "sport"))
    spec = importlib.util.spec_from_loader("sport_mod", loader)
    mod = importlib.util.module_from_spec(spec); loader.exec_module(mod)
    os.environ["XDG_CACHE_HOME"] = tempfile.mkdtemp()
    os.environ["ALPE_SPORT_TODAY"] = "2026-11-18"
    os.environ["TZ"] = "Europe/Zurich"
    import time; time.tzset()
    return mod


def team(tid, name, acr):
    return {"id": tid, "name": name, "acronym": acr, "signed": False, "type": "team", "clubId": tid}


HEADER = [{"alias": a} for a in ("day", "date", "time", "homeTeam", "awayTeam", "score", "scorePerPeriod",
                                   "decision", "status", "details", "broadcasts")]

SIHF_RESULTS = {"header": HEADER, "data": [
    ["So", "15.11.2026", "15:45", team(101149, "EHC Kloten", "EHCK"), team(103140, "Genève-Servette HC", "GSHC"),
     {"homeTeam": "3", "awayTeam": "5", "type": "result"},
     {"homeTeam": ["1", "0", "2"], "awayTeam": ["1", "4", "0"], "type": "periods"}, "",
     {"id": 12, "startDateTime": "2026-11-15T15:45:00+01:00", "percent": 100, "name": "Ende", "canceled": False},
     {"gameId": "20271105000137", "type": "linkToGameDetail"}, {"entries": ["MYSPORTS"], "type": "broadcasts"}],
    ["Mi", "18.11.2026", "19:45", team(101144, "EV Zug", "EVZ"), team(103144, "HC Ajoie", "HCA"),
     {"homeTeam": "-", "awayTeam": "-", "type": "result"},
     {"homeTeam": ["-", "-", "-"], "awayTeam": ["-", "-", "-"], "type": "periods"}, "",
     {"id": 0, "startDateTime": "2026-11-18T19:45:00+01:00", "percent": 0, "name": "Wie geplant", "canceled": False},
     {"gameId": "20271105000098", "type": "linkToGameDetail"}, {"entries": ["MYSPORTS"], "type": "broadcasts"}],
    ["Mi", "18.11.2026", "19:45", team(101151, "HC Davos", "HCD"), team(102126, "SC Bern", "SCB"),
     {"homeTeam": "2", "awayTeam": "1", "type": "result"},
     {"homeTeam": ["1", "1", "-"], "awayTeam": ["0", "1", "-"], "type": "periods"}, "",
     {"id": 5, "startDateTime": "2026-11-18T19:45:00+01:00", "percent": 50, "name": "2. Drittel", "canceled": False},
     {"gameId": "20271105000099", "type": "linkToGameDetail"}, {"entries": [], "type": "broadcasts"}],
    ["Mi", "19.11.2026", "20:00", team(103141, "Lausanne HC", "LHC"), team(101139, "ZSC Lions", "ZSC"),
     {"homeTeam": "4", "awayTeam": "3", "type": "result"},
     {"homeTeam": ["1", "1", "1", "1"], "awayTeam": ["1", "1", "1", "0"], "type": "periods"}, "OT",
     {"id": 12, "startDateTime": "2026-11-19T20:00:00+01:00", "percent": 100, "name": "Ende", "canceled": False},
     {"gameId": "20271105000151", "type": "linkToGameDetail"}, {"entries": [], "type": "broadcasts"}],
]}

STANDING_HEADER = [{"alias": a} for a in ("rank", "team", "gamesPlayed", "points", "pointsQuotient", "gamesWonInTime",
                                          "gamesWonExtraTime", "gamesWonPenalty", "gamesLostPenalty",
                                          "gamesLostExtraTime", "gamesLostInTime", "goalsFor", "goalsAgainst",
                                          "goalsDifference", "streak")]
SIHF_STANDING = {"header": STANDING_HEADER, "data": [
    ["2", team(103140, "Genève-Servette HC", "GSHC"), "19", "36", "1.89", "10", "2", "0", "1", "1", "5", "60", "45", "15", "W+W+"],
    ["1", team(101144, "EV Zug", "EVZ"), "19", "40", "2.1", "12", "1", "0", "0", "1", "5", "66", "40", "26", "W+"],
    ["7", team(101149, "EHC Kloten", "EHCK"), "19", "28", "1.4", "8", "0", "1", "1", "0", "9", "50", "55", "-5", "L-"],
    ["", {"name": "Durchschnitt"}, "19", "28", "", "", "", "", "", "", "", "", "", "", ""],
]}

SIHF_DETAIL = {
    "summary": {"periods": [
        {"name": "1. Drittel",
         "fouls": [{"playerLicenceNr": 151851, "time": "16:13", "timeInSeconds": 973, "minutes": 2, "teamId": 103140, "name": "Halten"}],
         "goals": [{"scorerLicenceNr": 348821, "assist1LicenceNr": 302468, "assist2LicenceNr": 343288, "time": "12:59",
                    "teamId": 103140, "timeInSeconds": 779, "result": {"home": 0, "away": 1},
                    "situation": {"code": "EQ"}, "isEmptyNet": False, "isPenaltyShot": False}]},
        {"name": "2. Drittel", "fouls": [],
         "goals": [{"scorerLicenceNr": 351019, "assist1LicenceNr": 0, "assist2LicenceNr": 0, "time": "21:06",
                    "teamId": 101149, "timeInSeconds": 1266, "result": {"home": 1, "away": 1},
                    "situation": {"code": "PP1"}, "isEmptyNet": False, "isPenaltyShot": False}]},
        {"name": "3. Drittel", "fouls": [], "goals": []}], "shootout": {"name": "Shootout"}},
    "lineUps": {"homeTeam": {"goalkeepers": [325067], "defenders": {"left": [347697], "right": [324968]},
                             "forwarders": {"left": [347696], "right": [342154], "center": [340147]},
                             "coach": {"fullName": "Michael Liniger"}},
                "awayTeam": {"goalkeepers": [310640], "defenders": {"left": [302468], "right": [340128]},
                             "forwarders": {"left": [348821], "right": [347707], "center": [343288]},
                             "coach": {"fullName": "Sam Hallam"}}},
    "players": [
        {"teamId": 103140, "id": 348821, "fullName": "Vesey Jimmy", "jerseyNumber": 16},
        {"teamId": 103140, "id": 302468, "fullName": "Le Coultre Simon", "jerseyNumber": 90},
        {"teamId": 103140, "id": 343288, "fullName": "Manninen Sakari", "jerseyNumber": 65},
        {"teamId": 103140, "id": 151851, "fullName": "Sutter Dave", "jerseyNumber": 77},
        {"teamId": 101149, "id": 351019, "fullName": "Johansson Simon", "jerseyNumber": 23},
        {"teamId": 101149, "id": 325067, "fullName": "Fadani Davide", "jerseyNumber": 35},
    ],
    "stats": [
        {"alias": "gameTeamStats", "header": [{"alias": "Statistic"}, {"alias": "EHC Kloten"}, {"alias": "GSHC"}],
         "data": [["SOG Total", "27", "18"], ["FO%", "47.62", "52.38"], ["PIM Total", "0", "4"], ["PP%", "0.00", "0.00"]]},
        {"alias": "gameGoalieStatsAway", "header": [{"alias": a} for a in ("playerNumber", "player", "goalsAgainst", "saves", "shotsAgainst", "savesPercentage", "secondsPlayed")],
         "data": [["38", "Charlin Stéphane", "3", "24", "27", "88.89", "60:00"], ["39", "van Pottelberghe Joren", "0", "0", "0", "-", "00:00"]]},
        {"alias": "gamePlayerStatsAway", "header": [{"alias": a} for a in ("playerNumber", "player", "playerPosition", "goals", "assists", "assists1", "assists2", "points")],
         "data": [["16", "Vesey Jimmy", "Stürmer", "2", "2", "1", "1", "4"], ["3", "Boqvist Adam", "Verteidiger", "1", "0", "0", "0", "1"]]},
    ],
    "gameId": "20271105000137",
    "result": {"homeTeam": "3", "awayTeam": "5", "scores": [
        {"homeTeam": "1", "awayTeam": "1", "indicator": "1"}, {"homeTeam": "0", "awayTeam": "4", "indicator": "2"},
        {"homeTeam": "2", "awayTeam": "0", "indicator": "3"}]},
    "details": {"venue": {"name": "SWISS Arena", "spectators": "5337", "city": "Kloten ZH"},
                "referees": [{"fullName": "Mark Lemelin"}, {"fullName": "Julien Staudenmann"}],
                "homeTeam": team(101149, "EHC Kloten", "EHCK"), "awayTeam": team(103140, "Genève-Servette HC", "GSHC")},
    "status": {"id": 12, "startDateTime": "2026-11-15T15:45:00+01:00", "percent": 100, "name": "Ende", "canceled": False},
    "broadcasts": {"entries": ["MYSPORTS"]},
}


def espn_competitor(side, tid, name, abbr, score, winner=False, logo=True, **extra):
    t = {"id": tid, "displayName": name, "shortDisplayName": name.split()[-1], "abbreviation": abbr, "color": "dc052d"}
    if logo:
        t["logo"] = "https://a.espncdn.com/i/teamlogos/soccer/500/%s.png" % tid
    return dict({"homeAway": side, "team": t, "score": score, "winner": winner}, **extra)


def espn_event(eid, when, state, name, home, away, clock="", period=0, short=""):
    return {"id": eid, "date": when, "status": {"displayClock": clock, "period": period,
            "type": {"name": name, "state": state, "shortDetail": short}},
            "competitions": [{"competitors": [home, away], "venue": {"fullName": "Allianz Arena"}}]}


GER_SCOREBOARD = {"leagues": [{"logos": [{"href": "https://a.espncdn.com/i/leaguelogos/soccer/500/10.png"}]}], "events": [
    espn_event("1", "2026-11-18T19:30Z", "in", "STATUS_SECOND_HALF", espn_competitor("home", "132", "Bayern Munich", "BAY", "2"),
               espn_competitor("away", "124", "Borussia Dortmund", "DOR", "1"), clock="67'", period=2),
    espn_event("2", "2026-11-18T23:30Z", "pre", "STATUS_SCHEDULED", espn_competitor("home", "131", "RB Leipzig", "RBL", "0"),
               espn_competitor("away", "2950", "Mainz", "M05", "0", logo=False)),      # 00:30 Ortszeit: naechster Tag
    espn_event("3", "2026-11-17T14:30Z", "post", "STATUS_FULL_TIME", espn_competitor("home", "125", "Freiburg", "SCF", "1", True),
               espn_competitor("away", "134", "Hoffenheim", "TSG", "0")),
]}

GER_STANDINGS = {"children": [{"name": "2026-27 German Bundesliga", "standings": {"entries": [
    {"team": {"id": "124", "displayName": "Borussia Dortmund", "abbreviation": "DOR", "logos": [{"href": "https://a.espncdn.com/i/teamlogos/soccer/500/124.png"}]},
     "note": {"color": "#81D6AC", "description": "Champions League", "rank": 2},
     "stats": [{"name": "gamesPlayed", "displayValue": "11"}, {"name": "wins", "displayValue": "7"}, {"name": "ties", "displayValue": "2"},
               {"name": "losses", "displayValue": "2"}, {"name": "pointsFor", "displayValue": "25"}, {"name": "pointsAgainst", "displayValue": "12"},
               {"name": "pointDifferential", "displayValue": "+13"}, {"name": "points", "displayValue": "23"}, {"name": "rank", "displayValue": "2"}]},
    {"team": {"id": "132", "displayName": "Bayern Munich", "abbreviation": "BAY", "logos": [{"href": "https://a.espncdn.com/i/teamlogos/soccer/500/132.png"}]},
     "note": {"color": "#81D6AC", "description": "Champions League", "rank": 1},
     "stats": [{"name": "gamesPlayed", "displayValue": "11"}, {"name": "wins", "displayValue": "9"}, {"name": "ties", "displayValue": "1"},
               {"name": "losses", "displayValue": "1"}, {"name": "pointsFor", "displayValue": "33"}, {"name": "pointsAgainst", "displayValue": "9"},
               {"name": "pointDifferential", "displayValue": "+24"}, {"name": "points", "displayValue": "28"}, {"name": "rank", "displayValue": "1"}]},
    {"team": {"id": "2950", "displayName": "Mainz", "abbreviation": "M05", "logos": []},
     "note": {"color": "#FF7F84", "description": "Relegation", "rank": 18},
     "stats": [{"name": "rank", "displayValue": "18"}, {"name": "points", "displayValue": "4"}]},
]}}]}

NBA_STANDINGS = {"children": [
    {"name": "Eastern Conference", "standings": {"entries": [
        {"team": {"id": "15", "displayName": "Milwaukee Bucks", "abbreviation": "MIL", "logos": [{"href": "https://a.espncdn.com/i/teamlogos/nba/500/mil.png"}]},
         "stats": [{"name": "playoffSeed", "type": "playoffseed", "displayValue": "15"}, {"name": "wins", "displayValue": "1"},
                   {"name": "losses", "displayValue": "13"}, {"name": "winPercent", "displayValue": ".071"},
                   {"name": "gamesBehind", "displayValue": "10.5"}, {"name": "streak", "displayValue": "L10"},
                   {"name": "Last Ten Games", "type": "lasttengames", "displayValue": "0-10"}]},
        {"team": {"id": "2", "displayName": "Boston Celtics", "abbreviation": "BOS", "logos": []},
         "stats": [{"name": "playoffSeed", "type": "playoffseed", "displayValue": "1"}, {"name": "wins", "displayValue": "12"},
                   {"name": "losses", "displayValue": "2"}]}]}},
    {"name": "Western Conference", "standings": {"entries": [
        {"team": {"id": "25", "displayName": "Oklahoma City Thunder", "abbreviation": "OKC"},
         "stats": [{"name": "playoffSeed", "displayValue": "8"}, {"name": "wins", "displayValue": "8"}, {"name": "losses", "displayValue": "6"}]}]}},
]}

SOCCER_SUMMARY = {
    "header": {"id": "401884740", "competitions": [{"date": "2026-11-07T14:30Z",
        "status": {"displayClock": "90'+5'", "period": 2, "type": {"name": "STATUS_FULL_TIME", "state": "post", "shortDetail": "FT"}},
        "competitors": [
            {"homeAway": "home", "score": "1", "team": {"id": "2950", "displayName": "Mainz", "abbreviation": "M05", "logos": [{"href": "https://a.espncdn.com/i/teamlogos/soccer/500/2950.png"}]},
             "linescores": [{"displayValue": "0"}, {"displayValue": "1"}]},
            {"homeAway": "away", "score": "2", "winner": True, "team": {"id": "132", "displayName": "Bayern Munich", "abbreviation": "BAY", "logos": [{"href": "https://a.espncdn.com/i/teamlogos/soccer/500/132.png"}]},
             "linescores": [{"displayValue": "1"}, {"displayValue": "1"}]}]}]},
    "gameInfo": {"venue": {"fullName": "MEWA ARENA"}, "attendance": 33305, "officials": [{"displayName": "Felix Zwayer"}]},
    "keyEvents": [
        {"type": {"type": "kickoff", "text": "Kickoff"}, "clock": {"displayValue": "0'"}},
        {"type": {"type": "goal", "text": "Goal"}, "clock": {"displayValue": "23'"}, "team": {"id": "132"}, "scoringPlay": True,
         "participants": [{"athlete": {"displayName": "Harry Kane"}}, {"athlete": {"displayName": "Michael Olise"}}],
         "text": "Goal! Mainz 0, Bayern Munich 1. Harry Kane (Bayern Munich) header."},
        {"type": {"type": "yellow-card", "text": "Yellow Card"}, "clock": {"displayValue": "38'"}, "team": {"id": "2950"},
         "participants": [{"athlete": {"displayName": "Dominik Kohr"}}]},
        {"type": {"type": "halftime", "text": "Halftime"}, "clock": {"displayValue": "45'+2'"}},
        {"type": {"type": "own-goal", "text": "Own Goal"}, "clock": {"displayValue": "52'"}, "team": {"id": "132"}, "scoringPlay": True,
         "participants": [{"athlete": {"displayName": "Dayot Upamecano"}}],
         "text": "Own Goal by Dayot Upamecano, Bayern Munich.  Mainz 1, Bayern Munich 1."},
        {"type": {"type": "substitution", "text": "Substitution"}, "clock": {"displayValue": "60'"}, "team": {"id": "132"},
         "participants": [{"athlete": {"displayName": "Lennart Karl"}}, {"athlete": {"displayName": "Serge Gnabry"}}],
         "text": "Substitution, Bayern Munich. Lennart Karl replaces Serge Gnabry."},
        {"type": {"type": "goal", "text": "Goal"}, "clock": {"displayValue": "90'+3'"}, "team": {"id": "132"}, "scoringPlay": True,
         "participants": [{"athlete": {"displayName": "Lennart Karl"}}], "text": "Goal! Mainz 1, Bayern Munich 2. Lennart Karl (Bayern Munich) right footed shot."},
    ],
    "boxscore": {"teams": [
        {"team": {"id": "2950"}, "statistics": [{"name": "possessionPct", "displayValue": "31.2"}, {"name": "totalShots", "displayValue": "11"},
                                               {"name": "passPct", "displayValue": "0.7"}, {"name": "yellowCards", "displayValue": "1"}]},
        {"team": {"id": "132"}, "statistics": [{"name": "possessionPct", "displayValue": "68.8"}, {"name": "totalShots", "displayValue": "19"},
                                              {"name": "passPct", "displayValue": "0.9"}, {"name": "yellowCards", "displayValue": "0"}]}]},
    "rosters": [
        {"homeAway": "away", "team": {"id": "132"}, "formation": "4-2-3-1", "roster": [
            {"starter": True, "jersey": "1", "athlete": {"displayName": "Manuel Neuer", "shortName": "M. Neuer"}, "position": {"abbreviation": "G"}, "formationPlace": "1"},
            {"starter": True, "jersey": "27", "athlete": {"displayName": "Konrad Laimer"}, "position": {"abbreviation": "RB"}, "formationPlace": "2"},
            {"starter": True, "jersey": "2", "athlete": {"displayName": "Dayot Upamecano"}, "position": {"abbreviation": "CD-R"}, "formationPlace": "5"},
            {"starter": True, "jersey": "4", "athlete": {"displayName": "Jonathan Tah"}, "position": {"abbreviation": "CD-L"}, "formationPlace": "6"},
            {"starter": True, "jersey": "44", "athlete": {"displayName": "Josip Stanisic"}, "position": {"abbreviation": "LB"}, "formationPlace": "3"},
            {"starter": True, "jersey": "6", "athlete": {"displayName": "Joshua Kimmich"}, "position": {"abbreviation": "DM-R"}, "formationPlace": "4"},
            {"starter": True, "jersey": "45", "athlete": {"displayName": "Aleksandar Pavlovic"}, "position": {"abbreviation": "DM-L"}, "formationPlace": "8"},
            {"starter": True, "jersey": "17", "athlete": {"displayName": "Michael Olise"}, "position": {"abbreviation": "RM"}, "formationPlace": "7"},
            {"starter": True, "jersey": "10", "athlete": {"displayName": "Jamal Musiala"}, "position": {"abbreviation": "AM"}, "formationPlace": "10"},
            {"starter": True, "jersey": "7", "athlete": {"displayName": "Serge Gnabry"}, "position": {"abbreviation": "LM"}, "formationPlace": "11", "subbedOut": True},
            {"starter": True, "jersey": "9", "athlete": {"displayName": "Harry Kane"}, "position": {"abbreviation": "F"}, "formationPlace": "9",
             "plays": [{"didScore": True}]},
            {"starter": False, "jersey": "42", "athlete": {"displayName": "Lennart Karl"}, "position": {"abbreviation": "SUB"}, "subbedIn": True},
        ]},
        {"homeAway": "home", "team": {"id": "2950"}, "roster": [
            {"starter": True, "jersey": "27", "athlete": {"displayName": "Robin Zentner"}, "position": {"abbreviation": "G"}, "formationPlace": "1"}]},
    ],
}

NBA_SUMMARY = {
    "header": {"id": "401810001", "competitions": [{"date": "2026-11-19T00:30Z",
        "status": {"displayClock": "4:12", "period": 3, "type": {"name": "STATUS_IN_PROGRESS", "state": "in", "shortDetail": "4:12 - 3rd"}},
        "competitors": [
            {"homeAway": "home", "score": "88", "team": {"id": "2", "displayName": "Boston Celtics", "abbreviation": "BOS", "logos": [{"href": "https://a.espncdn.com/i/teamlogos/nba/500/bos.png"}]},
             "linescores": [{"displayValue": "30"}, {"displayValue": "28"}, {"displayValue": "30"}], "records": [{"summary": "12-2"}]},
            {"homeAway": "away", "score": "80", "team": {"id": "15", "displayName": "Milwaukee Bucks", "abbreviation": "MIL"},
             "linescores": [{"displayValue": "25"}, {"displayValue": "30"}, {"displayValue": "25"}]}]}]},
    "boxscore": {
        "teams": [{"team": {"id": "15"}, "statistics": [{"name": "fieldGoalsMade-fieldGoalsAttempted", "displayValue": "30-70"}, {"name": "fieldGoalPct", "displayValue": "42.9"}]},
                  {"team": {"id": "2"}, "statistics": [{"name": "fieldGoalsMade-fieldGoalsAttempted", "displayValue": "33-66"}, {"name": "fieldGoalPct", "displayValue": "50"}]}],
        "players": [{"team": {"id": "2"}, "statistics": [{"labels": ["MIN", "FG", "3PT", "FT", "OREB", "DREB", "REB", "AST", "STL", "BLK", "TO", "PF", "+/-", "PTS"],
            "athletes": [{"starter": True, "athlete": {"id": "4065648", "shortName": "J. Tatum", "position": {"abbreviation": "F"}},
                          "stats": ["28", "9-17", "3-7", "4-4", "1", "7", "8", "5", "1", "0", "2", "1", "+9", "25"]},
                         {"didNotPlay": True, "athlete": {"shortName": "X. Bench"}, "stats": []}]}]}]},
    "leaders": [{"team": {"id": "2"}, "leaders": [{"name": "points", "leaders": [{"displayValue": "25", "athlete": {"displayName": "Jayson Tatum"}}]}]}],
}


def router(table, calls):
    def get(url):
        calls.append(url)
        if "combiner" in url or "teamlogos" in url or "leaguelogos" in url:
            return PNG
        for needle, payload in table:
            if needle in url:
                if isinstance(payload, Exception):
                    raise payload
                return json.dumps(payload).encode()
        raise urllib.error.URLError("kein Netz: " + url)
    return get


def t_hockey_day():
    mod = load(); calls = []
    mod.http_get = router([("alias=results", SIHF_RESULTS)], calls)
    out = mod.command_day(date(2026, 11, 18), ["nl"])
    assert "filterQuery=2027%2F17.11.2026-19.11.2026" in calls[0], calls[0]
    nl = out["leagues"][0]
    assert [m["id"] for m in nl["matches"]] == ["20271105000098", "20271105000099"], nl["matches"]
    zug, davos = nl["matches"]
    assert zug["status"] == "pre" and zug["start"] == "2026-11-18T18:45:00Z" and zug["home"]["abbr"] == "EVZ"
    assert zug["home"]["color"] and zug["home"]["score"] == "" and zug["tv"] == ["MYSPORTS"]
    assert davos["status"] == "live" and davos["label"] == "2. Drittel" and davos["home"]["score"] == "2"
    assert out["live"] == 1


def t_hockey_end_states():
    mod = load()
    columns = [h["alias"] for h in HEADER]
    kloten = mod.hockey_match(mod.sihf_row(columns, SIHF_RESULTS["data"][0]))
    assert kloten["status"] == "post" and kloten["label"] == "Ende" and kloten["away"]["winner"] and not kloten["home"]["winner"]
    lhc = mod.hockey_match(mod.sihf_row(columns, SIHF_RESULTS["data"][3]))
    assert lhc["label"] == "Ende n.V." and len(lhc["periods"]) == 4
    assert mod.season_for(date(2026, 11, 18)) == 2027 and mod.season_for(date(2027, 3, 1)) == 2027
    assert mod.hockey_status({"canceled": True})[0] == "canceled"


def t_hockey_league():
    mod = load(); calls = []
    mod.http_get = router([("alias=standing", SIHF_STANDING), ("alias=results", SIHF_RESULTS)], calls)
    out = mod.command_league("nl")
    rows = out["table"]["groups"][0]["rows"]
    assert [r["team"]["abbr"] for r in rows] == ["EVZ", "GSHC", "EHCK"]           # Durchschnitt faellt weg
    zug = rows[0]
    assert zug["cells"] == {"gp": "19", "w": "12", "otw": "1", "otl": "1", "l": "5", "goals": "66:40", "gd": "+26", "pts": "40"}
    assert zug["zone"]["kind"] == "up" and rows[2]["zone"]["kind"] == "playin"
    assert [f["r"] for f in rows[1]["form"]] == ["S"]                              # Sieg in Kloten
    assert [f["r"] for f in rows[2]["form"]] == ["N"]


def t_hockey_detail():
    mod = load(); calls = []
    mod.http_get = router([("gameoverview", SIHF_DETAIL)], calls)
    out = mod.command_match("nl", "20271105000137")
    m = out["match"]
    assert m["home"]["abbr"] == "EHCK" and m["away"]["score"] == "5" and m["status"] == "post"
    goals = [e for e in out["events"] if e["type"] == "goal"]
    assert goals[0]["player"] == "Vesey" and goals[0]["side"] == "away" and goals[0]["score"] == "0:1"
    assert goals[0]["detail"] == "Assists: Le Coultre, Manninen"
    assert goals[1]["detail"] == "Überzahl" and goals[1]["side"] == "home"
    pen = [e for e in out["events"] if e["type"] == "penaltymin"][0]
    assert pen["player"] == "Sutter" and pen["detail"] == "2 Min. · Halten"
    halves = [e for e in out["events"] if e["type"] == "half"]
    assert [h["score"] for h in halves] == ["1:1", "1:5", "3:5"]
    assert out["events"].index(halves[0]) > out["events"].index(pen)
    assert [p["name"] for p in out["periods"]] == ["1. Drittel", "2. Drittel", "3. Drittel"]
    sog = out["stats"][0]
    assert sog["label"] == "Schüsse aufs Tor" and sog["hv"] == 27 and sog["av"] == 18
    assert out["stats"][1]["home"] == "47.62 %"
    assert out["venue"] == "SWISS Arena, Kloten ZH" and out["attendance"] == 5337
    assert out["referee"] == "Mark Lemelin / Julien Staudenmann"
    goalie = [l for l in out["leaders"] if l["title"] == "Torhüter"]
    assert len(goalie) == 1 and goalie[0]["name"] == "Charlin"
    assert [l["name"] for l in out["leaders"] if l["title"] == "Skorer"] == ["Vesey", "Boqvist"]
    home = out["lineups"]["home"]
    assert home["goalies"][0]["num"] == "35" and len(home["blocks"]) == 1
    assert len(home["blocks"][0]["forwards"]) == 3 and len(home["blocks"][0]["defense"]) == 2
    assert out["lineups"]["away"]["blocks"][0]["forwards"][0]["short"] == "Vesey"
    assert out["lineups"]["home"]["coach"] == "Michael Liniger"


def t_soccer_day():
    mod = load(); calls = []
    mod.http_get = router([("ger.1/scoreboard", GER_SCOREBOARD)], calls)
    out = mod.command_day(date(2026, 11, 18), ["ger.1"])
    assert sorted(c.split("dates=")[1] for c in calls if "scoreboard" in c) == ["20261117", "20261118"], calls
    assert not any("-" in c.split("dates=")[1] for c in calls if "scoreboard" in c)     # keine Spannen (HTTP 400)
    league = out["leagues"][0]
    assert [m["id"] for m in league["matches"]] == ["1"]                     # Spiel 2 um 00:30, Spiel 3 gestern
    bay = league["matches"][0]
    assert bay["status"] == "live" and bay["label"] == "67'" and bay["home"]["abbr"] == "BAY"
    assert bay["home"]["logo"].endswith(".png") and os.path.exists(bay["home"]["logo"])
    assert league["logo"] and os.path.exists(league["logo"])
    assert any(c == "https://a.espncdn.com/i/teamlogos/soccer/500/132.png" for c in calls)
    assert not any("combiner" in c for c in calls if "selftest" not in c)          # kein Bildverkleinerer mehr
    calls.clear()
    out = mod.command_day(date(2026, 11, 19), ["ger.1"])
    assert [m["id"] for m in out["leagues"][0]["matches"]] == ["2"]
    assert out["leagues"][0]["matches"][0]["away"]["logo"] == ""


def t_soccer_status():
    mod = load()
    s = lambda name, state, **kw: mod.espn_status({"type": dict(name=name, state=state, shortDetail=kw.get("short", "")),
                                                   "period": kw.get("period", 0), "displayClock": kw.get("clock", "")}, kw.get("sport", "soccer"))
    assert s("STATUS_FINAL_PEN", "post") == ("post", "n.P.")
    assert s("STATUS_FINAL_AET", "post") == ("post", "n.V.")
    assert s("STATUS_FULL_TIME", "post") == ("post", "Ende")
    assert s("STATUS_HALFTIME", "in") == ("live", "Pause")
    assert s("STATUS_POSTPONED", "post") == ("postponed", "Verschoben")
    assert s("STATUS_IN_PROGRESS", "in", period=3, clock="4:12", sport="basketball") == ("live", "Q3 4:12")
    assert s("STATUS_IN_PROGRESS", "in", period=5, clock="2:00", sport="basketball") == ("live", "OT 2:00")
    assert s("STATUS_END_PERIOD", "in", period=2, sport="basketball") == ("live", "Ende Q2")
    assert s("STATUS_FINAL", "post", period=5, short="Final/OT", sport="basketball") == ("post", "Ende n.V.")
    assert mod.german_round("Round of 16") == "Achtelfinal" and mod.german_round("Quarterfinals") == "Viertelfinal"
    assert mod.german_round("2nd Leg") == "2. Spiel"


def t_soccer_league():
    mod = load(); calls = []
    mod.http_get = router([("ger.1/standings", GER_STANDINGS), ("ger.1/scoreboard", GER_SCOREBOARD)], calls)
    out = mod.command_league("ger.1")
    rows = out["table"]["groups"][0]["rows"]
    assert out["table"]["groups"][0]["name"] == ""
    assert [r["team"]["abbr"] for r in rows] == ["BAY", "DOR", "M05"]
    assert rows[0]["cells"]["goals"] == "33:9" and rows[0]["cells"]["pts"] == "28" and rows[0]["cells"]["gd"] == "+24"
    assert rows[0]["zone"]["kind"] == "cl" and rows[2]["zone"]["kind"] == "rel" and rows[2]["zone"]["label"] == "Abstieg"
    assert rows[0]["form"] == []                                    # Spiel 1 laeuft noch, Spiel 3 betrifft andere
    assert [c["key"] for c in out["table"]["columns"]] == ["gp", "w", "d", "l", "goals", "gd", "pts"]
    months = sorted({c.split("dates=")[1] for c in calls if "ger.1/scoreboard" in c})
    assert months == ["202610", "202611", "202612"], months
    cup = mod.command_league("ger.dfb_pokal")
    assert cup["table"] is None


def t_nba_table():
    mod = load(); calls = []
    mod.http_get = router([("nba/standings", NBA_STANDINGS), ("nba/scoreboard", {"events": []})], calls)
    out = mod.command_league("nba")
    days = sorted(c.split("dates=")[1] for c in calls if "nba/scoreboard" in c)
    assert days[0] == "20261116" and days[-1] == "20261123" and len(days) == 8, days
    east, west = out["table"]["groups"]
    assert east["name"] == "Eastern Conference" and [r["team"]["abbr"] for r in east["rows"]] == ["BOS", "MIL"]
    assert east["rows"][1]["cells"]["l10"] == "0-10" and east["rows"][1]["cells"]["pct"] == ".071"
    assert east["rows"][0]["zone"]["kind"] == "up" and east["rows"][1]["zone"] is None
    assert west["rows"][0]["zone"]["kind"] == "playin"
    assert "form" not in east["rows"][0]


def t_soccer_detail():
    mod = load(); calls = []
    mod.http_get = router([("summary?event=401884740", SOCCER_SUMMARY)], calls)
    out = mod.command_match("ger.1", "401884740")
    assert out["match"]["home"]["name"] == "Mainz" and out["match"]["label"] == "Ende"
    assert out["venue"] == "MEWA ARENA" and out["attendance"] == 33305 and out["referee"] == "Felix Zwayer"
    assert [p["name"] for p in out["periods"]] == ["1. HZ", "2. HZ"] and out["periods"][1]["home"] == "1"
    ev = out["events"]
    kinds = [e["type"] for e in ev]
    assert kinds == ["goal", "yellow", "half", "owngoal", "sub", "goal"], kinds
    assert ev[0]["side"] == "away" and ev[0]["score"] == "0:1" and ev[0]["detail"] == "Assist: Michael Olise"
    assert ev[2]["score"] == "0:1"
    assert ev[3]["side"] == "home" and ev[3]["score"] == "1:1" and ev[3]["detail"] == "Eigentor"
    assert ev[4]["player"] == "Lennart Karl" and ev[4]["detail"] == "Serge Gnabry"
    assert ev[5]["score"] == "1:2" and ev[5]["minute"] == "90'+3'" and ev[5]["sort"] == 90 * 60 + 3
    poss = out["stats"][0]
    assert poss["label"] == "Ballbesitz" and poss["home"] == "31.2 %" and poss["av"] == 68.8
    pas = [s for s in out["stats"] if s["label"] == "Passquote"][0]
    assert pas["home"] == "70 %" and pas["av"] == 90
    away = out["lineups"]["away"]
    assert away["formation"] == "4-2-3-1"
    names = [[p["num"] for p in line] for line in away["lines"]]
    assert names == [["1"], ["44", "4", "2", "27"], ["45", "6"], ["7", "10", "17"], ["9"]], names
    assert away["lines"][-1][0]["marks"] == ["goal"]
    assert [p["name"] for p in away["bench"]] == ["Lennart Karl"] and away["bench"][0]["subIn"]
    assert out["lineups"]["home"]["formation"] == ""                  # nur der Torhueter bekannt


def t_nba_detail():
    mod = load(); calls = []
    mod.http_get = router([("summary?event=401810001", NBA_SUMMARY)], calls)
    out = mod.command_match("nba", "401810001")
    m = out["match"]
    assert m["status"] == "live" and m["label"] == "Q3 4:12" and m["home"]["record"] == "12-2"
    assert [p["name"] for p in out["periods"]] == ["Q1", "Q2", "Q3"] and out["periods"][2]["away"] == "25"
    fg = out["stats"][0]
    assert fg["label"] == "Würfe" and fg["home"] == "33-66" and fg["hv"] == 33 and fg["av"] == 30
    box = out["players"]["home"]
    assert box["columns"] == ["MIN", "PTS", "REB", "AST", "FG", "3PT", "+/-"]
    assert box["rows"] == [{"id": "4065648", "name": "J. Tatum", "pos": "F", "starter": True, "cells": ["28", "25", "8", "5", "9-17", "3-7", "+9"]}]
    assert out["leaders"] == [{"side": "home", "title": "Punkte", "value": "25", "name": "Jayson Tatum", "id": ""}]


def t_stale_cache():
    mod = load(); calls = []
    mod.http_get = router([("alias=results", SIHF_RESULTS)], calls)
    first = mod.command_day(date(2026, 11, 18), ["nl"])
    path = os.path.join(mod.cache_dir("http"))
    for name in os.listdir(path):                                   # Zwischenspeicher altern lassen
        full = os.path.join(path, name); data = json.load(open(full)); data["t"] = 0; json.dump(data, open(full, "w"))
    mod.http_get = router([], calls)                                 # kein Netz
    second = mod.command_day(date(2026, 11, 18), ["nl"])
    assert second["stale"] and second["errors"] and len(second["leagues"][0]["matches"]) == len(first["leagues"][0]["matches"])


def t_pick_logo():
    mod = load()
    assert mod.pick_logo([{"href": "hell", "rel": ["full", "default"]}, {"href": "dunkel", "rel": ["full", "dark"]}]) == "dunkel"
    assert mod.pick_logo([]) == "" and mod.pick_logo([{"href": "x"}]) == "x"
    assert mod.logo_url("https://a.espncdn.com/i/teamlogos/soccer/500/132.png") == "https://a.espncdn.com/i/teamlogos/soccer/500/132.png"
    assert mod.surname("Le Coultre Simon") == "Le Coultre" and mod.surname("Vesey") == "Vesey"



NATI_HTML = """<html><body><table><thead><tr><th>Datum</th><th>Event</th><th>Ort</th><th>Heimteam</th><th>Auswärtsteam</th><th>Resultat</th></tr></thead>
<tbody>
<tr><td>13.12.2026</td><td>SWISS Ice Hockey Games</td><td>Zürich / SUI</td><td><span>Switzerland</span></td><td><span>Finland</span></td><td>0:0</td></tr>
<tr><td>18.11.2026</td><td>Testspiel</td><td>Biel / SUI</td><td><span>Switzerland</span></td><td><span>Germany</span></td><td>0:0</td></tr>
<tr><td>08.11.2026</td><td>NOCCO Hockey Games, Finland</td><td>Helsinki / FIN</td><td><span>Czechia</span></td><td><span>Switzerland</span></td><td>4:2</td></tr>
<tr><td>31.05.2026</td><td>2026 IIHF Ice Hockey World Championship / Gold Medal Game</td><td>Swiss Life Arena, Zurich</td><td>Switzerland</td><td>Finland</td><td>0:1 (OT)</td></tr>
</tbody></table></body></html>"""


def t_national_hockey():
    mod = load(); calls = []
    def get(url):
        calls.append(url)
        if "sihf.ch/de/nationalteams" in url:
            return NATI_HTML.encode()
        if "teamlogos/countries" in url:
            return PNG
        raise urllib.error.URLError("kein Netz")
    mod.http_get = get
    out = mod.command_league("sui.hockey")
    ms = out["matches"]
    assert [m["id"] for m in ms] == ["20260531-SUI-FIN", "20261108-CZE-SUI", "20261118-SUI-GER", "20261213-SUI-FIN"], [m["id"] for m in ms]
    wm, nocco, today_, swiss = ms
    assert wm["status"] == "post" and wm["label"] == "Ende n.V." and wm["away"]["winner"] and wm["home"]["name"] == "Schweiz"
    assert nocco["home"]["name"] == "Tschechien" and nocco["home"]["score"] == "4" and nocco["away"]["score"] == "2"
    assert today_["status"] == "pre" and today_["timeUnknown"] and today_["noDetail"]           # 0:0 am Spieltag: noch offen
    assert swiss["status"] == "pre" and swiss["home"]["score"] == "" and swiss["round"] == "SWISS Ice Hockey Games"
    assert swiss["home"]["logo"].endswith(".png") and any("countries/500/sui.png" in c for c in calls)
    assert out["table"] is None and out["league"]["logo"]
    day = mod.command_day(date(2026, 11, 18), ["sui.hockey"])
    assert [m["id"] for m in day["leagues"][0]["matches"]] == ["20261118-SUI-GER"]
    assert "Länderspiele" in mod.command_match("sui.hockey", "x")["error"]


NATI_SCHEDULE = {"events": [
    {"id": "401861156", "date": "2026-11-13T19:45Z", "league": {"slug": "uefa.nations", "name": "UEFA Nations League"},
     "season": {"year": 2027, "slug": "league-phase"},
     "competitions": [{"status": {"type": {"name": "STATUS_FULL_TIME", "state": "post"}}, "notes": [], "competitors": [
        {"homeAway": "home", "team": {"id": "472", "displayName": "Slovenia", "abbreviation": "SVN"}, "score": {"value": 0.0, "displayValue": "0"}},
        {"homeAway": "away", "team": {"id": "475", "displayName": "Switzerland", "abbreviation": "SUI"}, "score": {"value": 0.0, "displayValue": "0"}}]}]},
    {"id": "760513", "date": "2026-07-12T01:00Z", "league": {"slug": "fifa.world", "name": "FIFA World Cup"},
     "season": {"year": 2026, "slug": "quarterfinals"},
     "competitions": [{"status": {"type": {"name": "STATUS_FINAL_AET", "state": "post"}}, "competitors": [
        {"homeAway": "home", "team": {"id": "202", "displayName": "Argentina", "abbreviation": "ARG"}, "score": {"displayValue": "3"}, "winner": True},
        {"homeAway": "away", "team": {"id": "475", "displayName": "Switzerland", "abbreviation": "SUI"}, "score": {"displayValue": "1"}}]}]},
]}


def t_national_soccer():
    mod = load(); calls = []
    mod.http_get = router([("teams/475/schedule", NATI_SCHEDULE), ("uefa.nations/summary?event=401861156", SOCCER_SUMMARY)], calls)
    out = mod.command_league("sui.nt")
    assert [m["id"] for m in out["matches"]] == ["fifa.world~760513", "uefa.nations~401861156"]
    wc, nl = out["matches"]
    assert nl["round"] == "Nations League · Ligaphase" and nl["away"]["name"] == "Switzerland" and nl["home"]["score"] == "0"
    assert wc["round"] == "WM · Viertelfinal" and wc["label"] == "n.V."
    assert any("season=2027" in c for c in calls) and any("fixture=true" in c for c in calls)
    detail = mod.command_match("sui.nt", "uefa.nations~401861156")
    assert "error" not in detail and any("soccer/uefa.nations/summary?event=401861156" in c for c in calls)
    day = mod.command_day(date(2026, 11, 13), ["sui.nt"])
    assert [m["id"] for m in day["leagues"][0]["matches"]] == ["uefa.nations~401861156"]


CL_BOARD = {"events": [dict(GER_SCOREBOARD["events"][0], season={"slug": "league-phase"})]}


def t_champions_league():
    mod = load(); calls = []
    mod.http_get = router([("uefa.champions/standings", GER_STANDINGS), ("uefa.champions/scoreboard", CL_BOARD)], calls)
    out = mod.command_league("uefa.champions")
    assert out["table"] and len(out["table"]["groups"][0]["rows"]) == 3          # Ligaphase hat eine Tabelle
    assert out["matches"][0]["round"] == "Ligaphase"
    assert all("-" not in c.split("dates=")[1] for c in calls if "dates=" in c)


def t_record_only_nba():
    mod = load()
    ev = {"id": "1", "date": "2026-11-18T19:00Z", "status": {"type": {"state": "pre", "name": "STATUS_SCHEDULED"}},
          "competitions": [{"competitors": [
              {"homeAway": "home", "team": {"id": "1", "displayName": "A"}, "records": [{"summary": "1-5-4"}]},
              {"homeAway": "away", "team": {"id": "2", "displayName": "B"}, "records": [{"summary": "3-4-3"}]}]}]}
    assert "record" not in mod.espn_match(ev, "eng.1")["home"]
    assert mod.espn_match(ev, "nba")["home"]["record"] == "1-5-4"


def t_slow_logos_do_not_block():
    """Ein haengender Logo-Server darf die Antwort nicht aufhalten."""
    mod = load(); calls = []
    import time as _t
    spawned = []
    def get(url):
        calls.append(url)
        if "teamlogos" in url or "leaguelogos" in url:
            _t.sleep(30)
            return PNG
        return json.dumps(GER_SCOREBOARD).encode()
    mod.http_get = get
    mod._spawn_logo_loader = lambda wanted: spawned.append(len(wanted))
    started = _t.time()
    out = mod.command_day(date(2026, 11, 18), ["ger.1"])
    assert _t.time() - started < 6, _t.time() - started
    assert out["leagues"][0]["matches"][0]["home"]["logo"] == "" and spawned and spawned[0] >= 2


def t_output_utf8():
    mod = load()
    import io, contextlib, sys as _s
    class Raw(io.StringIO):
        def __init__(self):
            super().__init__(); self.buffer = io.BytesIO()
    raw = Raw()
    with contextlib.redirect_stdout(raw):
        mod.main(["sport", "leagues"])
    assert "Schweiz" in raw.buffer.getvalue().decode("utf-8")


def t_hockey_logos_and_ipv4():
    mod = load()
    import socket
    zug = mod.hockey_team({"id": 101144, "name": "EV Zug", "acronym": "EVZ"})
    assert zug["logoUrl"] == "https://r2.thesportsdb.com/images/media/team/badge/sxn04y1647290534.png/small"
    assert mod.hockey_team({"id": 101060, "name": "SC Rapperswil-Jona Lakers"})["logoUrl"] == ""   # kein Logo: Abzeichen
    fake = [(socket.AF_INET6, 1, 6, "", ("::1", 443, 0, 0)), (socket.AF_INET, 1, 6, "", ("127.0.0.1", 443))]
    mod._getaddrinfo = lambda *a, **k: list(fake)
    assert mod._ipv4_first("x", 443)[0][0] == socket.AF_INET


def t_main_json():
    mod = load()
    import io, contextlib
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        assert mod.main(["sport", "match", "xx", "1"]) == 0
    assert "unbekannter Wettbewerb" in json.loads(buf.getvalue())["error"]
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        assert mod.main(["sport", "day", "2026-13-01"]) == 2
    assert "error" in json.loads(buf.getvalue())


# ---------------------------------------------------------------- Beobachter, Statistik, Spieler

def results_with(changes):
    """Kopie von SIHF_RESULTS mit geaenderten Zeilen: {index: (status, heim, gast)}."""
    import copy
    data = copy.deepcopy(SIHF_RESULTS)
    for index, (status_id, name, home, away) in changes.items():
        row = data["data"][index]
        row[5] = {"homeTeam": home, "awayTeam": away, "type": "result"}
        row[8] = dict(row[8], id=status_id, name=name, percent=50 if status_id not in (0, 12) else (0 if status_id == 0 else 100))
    return data


def t_watch_events():
    mod = load(); calls = []
    log = os.path.join(tempfile.mkdtemp(), "notify.jsonl")
    os.environ["ALPE_SPORT_NOTIFY_LOG"] = log
    mod.HOT_AGE = 0
    favorites, leagues = ["hockey:101144", "hockey:101151"], ["nl", "nba", "eng.1"]
    mod.http_get = router([("alias=results", SIHF_RESULTS)], calls)
    first = mod.command_watch(favorites, leagues, ["goal", "start", "end"])
    assert [m["id"] for m in first["matches"]] == ["20271105000099", "20271105000098"]   # live zuerst
    assert first["events"] == [] and first["hot"] is True
    assert not any("nba" in c or "eng.1" in c for c in calls), calls                   # nur Sportarten der Favoriten
    # Zug beginnt und trifft, Davos trifft
    mod.http_get = router([("alias=results", results_with({1: (2, "1. Drittel", "1", "0"), 2: (5, "2. Drittel", "3", "1")}))], calls)
    second = mod.command_watch(favorites, leagues, ["goal", "start", "end"])
    kinds = sorted((e["match"].split("/")[1], e["kind"], e["side"]) for e in second["events"])
    assert kinds == [("20271105000098", "goal", "home"), ("20271105000098", "start", ""),
                     ("20271105000099", "goal", "home")], kinds
    sent = [json.loads(line) for line in open(log, encoding="utf-8")]
    assert len(sent) == 3 and any(s["title"] == "Tor für EV Zug" and s["body"].startswith("EV Zug 1:0 HC Ajoie") for s in sent), sent
    # Davos fertig; nur Schluss melden lassen
    mod.http_get = router([("alias=results", results_with({1: (2, "1. Drittel", "1", "0"), 2: (12, "Ende", "3", "1")}))], calls)
    third = mod.command_watch(favorites, leagues, ["end"])
    assert [(e["kind"]) for e in third["events"]] == ["end"]
    sent = [json.loads(line) for line in open(log, encoding="utf-8")]
    assert len(sent) == 4 and sent[-1]["title"] == "Schluss · NL" and sent[-1]["body"] == "HC Davos 3:1 SC Bern", sent[-1]
    # ohne Favoriten: keine Abfrage
    calls.clear()
    assert mod.command_watch([], leagues, ["goal"])["matches"] == [] and calls == []
    del os.environ["ALPE_SPORT_NOTIFY_LOG"]


def t_watch_basketball_no_goals():
    mod = load()
    before = {"status": "live", "home": 50, "away": 48, "start": ""}
    match = {"sport": "basketball", "status": "live", "home": {"score": "55"}, "away": {"score": "48"}}
    assert mod.watch_events(before, match) == []
    match = dict(match, sport="soccer")
    assert mod.watch_events(dict(before, home=0, away=0), dict(match, home={"score": "2"}, away={"score": "0"})) == \
        [{"kind": "goal", "side": "home"}, {"kind": "goal", "side": "home"}]
    assert mod.watch_events(None, match) == []


SOCCER_LEADERS = {"stats": [
    {"name": "goalsLeaders", "displayName": "Goals", "leaders": [
        {"displayValue": "Matches: 10, Goals: 9", "value": 9.0,
         "athlete": {"id": "253989", "displayName": "Erling Haaland", "shortName": "E. Haaland",
                     "team": {"id": "382", "displayName": "Manchester City", "abbreviation": "MNC",
                              "logos": [{"href": "https://a.espncdn.com/i/teamlogos/soccer/500/382.png"}]}}}]},
    {"name": "assistsLeaders", "displayName": "Assists", "leaders": []}]}

NBA_BYATHLETE = {
    "categories": [{"name": "general", "names": ["gamesPlayed", "avgRebounds"]},
                   {"name": "offensive", "names": ["avgPoints", "avgAssists"]}],
    "athletes": [{"athlete": {"id": "3945274", "displayName": "Luka Doncic", "shortName": "L. Doncic", "teamShortName": "LAL"},
                  "categories": [{"name": "general", "values": [13.0, 8.4]}, {"name": "offensive", "values": [38.76923, 9.2]}]}]}

SIHF_PLAYERS = {"header": [{"name": n} for n in ("R", "Spieler", "Team", "Pos", "GP", "G", "A", "PTS", "P/GP", "PIM Total", "+/-")],
                "data": [["1", "Tanus Kristian", team(103144, "HC Ajoie", "HCA"), "Stürmer", "20", "6", "22", "28", "1.40", "6", "-1"],
                         ["2", "Järventie Roby", team(101152, "HC Ambri-Piotta", "HCAP"), "Stürmer", "20", "12", "15", "27", "1.35", "8", "7"]]}
SIHF_GOALIES = {"header": [{"name": n} for n in ("R", "Spieler", "Team", "GP", "GPI", "GA", "GAA", "SA", "SVS", "SVS%", "MIP", "PIM", "G", "A")],
                "data": [["1", "Genoni Leonardo", team(101144, "EV Zug", "EVZ"), "12", "12", "22", "1.84", "295", "273", "92.54", "718:03", "0", "0", "0"],
                         ["2", "Von Burg Christof", team(102126, "SC Bern", "SCB"), "11", "10", "20", "1.95", "284", "264", "92.96", "615:33", "0", "0", "0"],
                         ["3", "Ersatz Hans", team(102126, "SC Bern", "SCB"), "2", "1", "5", "5.00", "20", "15", "75.00", "60:00", "0", "0", "0"]]}

ATHLETE = {"athlete": {"displayName": "Erling Haaland", "position": {"name": "Forward"}, "age": 26, "jersey": "9",
                       "citizenship": "Norway", "displayHeight": "6' 5\"",
                       "team": {"id": "382", "displayName": "Manchester City", "logos": [{"href": "https://a.espncdn.com/i/teamlogos/soccer/500/382.png"}]}}}
OVERVIEW = {"statistics": {"labels": ["STRT", "G", "A"], "names": ["starts", "totalGoals", "goalAssists"],
                           "splits": [{"displayName": "2026-27 English Premier League", "stats": ["10", "9", "1"]}]}}


def t_stats_soccer_and_nba():
    mod = load(); calls = []
    mod.http_get = router([("eng.1/statistics", SOCCER_LEADERS)], calls)
    out = mod.command_stats("eng.1")
    assert [c["title"] for c in out["categories"]] == ["Tore"]                         # leere Kategorie faellt weg
    row = out["categories"][0]["rows"][0]
    assert row["player"]["id"] == "253989" and row["value"] == "9" and row["sub"] == "10 Spiele" and row["team"]["abbr"] == "MNC"
    mod.http_get = router([("byathlete", NBA_BYATHLETE)], calls)
    out = mod.command_stats("nba")
    assert [c["title"] for c in out["categories"]] == ["Punkte", "Rebounds", "Assists"]
    assert out["categories"][0]["rows"][0]["value"] == "38.8" and out["categories"][1]["rows"][0]["value"] == "8.4"
    assert any("sort=offensive.avgPoints%3Adesc" in c for c in calls), calls


def t_stats_hockey():
    mod = load(); calls = []
    mod.http_get = router([("alias=goalkeeper", SIHF_GOALIES), ("alias=player", SIHF_PLAYERS)], calls)
    out = mod.command_stats("nl")
    titles = [c["title"] for c in out["categories"]]
    assert titles == ["Skorer", "Tore", "Assists", "Plus/Minus", "Torhüter"], titles
    assert out["categories"][0]["rows"][0]["player"]["short"] == "Tanus" and out["categories"][0]["rows"][0]["sub"] == "6 T · 22 A"
    assert out["categories"][1]["rows"][0]["player"]["name"] == "Järventie Roby"
    goalies = out["categories"][4]["rows"]
    assert [g["player"]["name"] for g in goalies] == ["Von Burg Christof", "Genoni Leonardo"]   # Ersatz zu wenig Spiele
    player = mod.command_player("nl", "Leonardo Genoni")
    assert player["player"]["position"] == "Torhüter" and player["splits"][0]["title"] == "National League 2026/27"
    assert {c["label"]: c["value"] for c in player["splits"][0]["cells"]}["Fangquote"] == "92.54"
    assert "error" in mod.command_player("nl", "Niemand Hier")


def t_player_espn():
    mod = load(); calls = []
    mod.http_get = router([("/overview", OVERVIEW), ("athletes/253989", ATHLETE)], calls)
    out = mod.command_player("eng.1", "253989")
    assert out["player"]["position"] == "Sturm" and out["player"]["age"] == "26" and out["player"]["jersey"] == "9"
    split = out["splits"][0]
    assert split["title"] == "English Premier League 2026/27"
    assert [c["label"] for c in split["cells"]] == ["Startelf", "Tore", "Vorlagen"]
    assert any("soccer/eng.1/athletes/253989/overview" in c for c in calls)


def t_cache_command():
    mod = load()
    folder = mod.cache_dir("http")
    open(os.path.join(folder, "x.json"), "w").write("{}" * 100)
    assert mod.command_cache()["bytes"] >= 200
    assert mod.command_cache(clear=True)["files"] == 0 or not os.path.exists(os.path.join(folder, "x.json"))


def t_player_ids_in_detail():
    mod = load(); calls = []
    mod.http_get = router([("gameoverview", SIHF_DETAIL)], calls)
    out = mod.command_match("nl", "20271105000137")
    lineup = out["lineups"]["away"]
    assert lineup["blocks"][0]["forwards"][0]["id"] == lineup["blocks"][0]["forwards"][0]["name"] == "Vesey Jimmy"
    assert all(l.get("id") for l in out["leaders"])


if __name__ == "__main__":
    failed = 0
    for name, fn in sorted(globals().items()):
        if name.startswith("t_") and callable(fn):
            try:
                fn(); print("ok   ", name)
            except Exception as error:
                failed += 1
                import traceback; traceback.print_exc()
                print("FEHLER", name, error)
    raise SystemExit(1 if failed else 0)
