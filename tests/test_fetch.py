import importlib.machinery, importlib.util, json, os, sys, tempfile, urllib.error, io
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

HERE = os.path.dirname(os.path.abspath(__file__))
PATH = os.path.join(HERE, "..", "plugins", "alpeMeteoSwiss", "fetch")
ZH = ZoneInfo("Europe/Zurich")

def load():
    loader = importlib.machinery.SourceFileLoader("fetch_mod", PATH)
    spec = importlib.util.spec_from_loader("fetch_mod", loader)
    mod = importlib.util.module_from_spec(spec); loader.exec_module(mod)
    return mod

TODAY = datetime.now(ZH).date()
DAYS = [(TODAY + timedelta(days=i)).isoformat() for i in range(9)]
HOURS = [f"{d}T{h:02d}:00" for d in DAYS for h in range(24)]

def om(model):
    n_icon = 5 * 24
    def col(base, upto=None):
        return [round(base + i * 0.1, 1) if (upto is None or i < upto) else None for i in range(len(HOURS))]
    limit = n_icon if model else None
    shift = 0 if model else 100          # best match ist klar unterscheidbar
    data = {"latitude": 47.0, "longitude": 8.6, "timezone": "Europe/Zurich", "utc_offset_seconds": 3600,
            "current": {"time": HOURS[10], "interval": 900, "temperature_2m": 5.5 + shift, "apparent_temperature": 3.0 + shift,
                        "relative_humidity_2m": 80, "is_day": 1, "weather_code": 3, "surface_pressure": 955.0,
                        "wind_speed_10m": 7.0, "wind_direction_10m": 200},
            "hourly": {"time": HOURS, "temperature_2m": col(1 + shift, limit), "weather_code": [3 if (limit is None or i < limit) else None for i in range(len(HOURS))],
                       "precipitation_probability": col(10 + shift, limit), "wind_speed_10m": col(5 + shift, limit),
                       "apparent_temperature": col(0 + shift, limit), "relative_humidity_2m": col(70, limit),
                       "surface_pressure": col(950, limit), "dew_point_2m": col(-1, limit), "is_day": [1] * len(HOURS)},
            "daily": {"time": DAYS, "temperature_2m_max": [10 + shift if (model is None or i < 5) else None for i in range(9)],
                      "temperature_2m_min": [1 + shift if (model is None or i < 5) else None for i in range(9)],
                      "weather_code": [61 if (model is None or i < 5) else None for i in range(9)],
                      "precipitation_probability_max": [40 if (model is None or i < 5) else None for i in range(9)]}}
    if not model:
        data["hourly"]["visibility"] = [20000.0] * len(HOURS)
        data["hourly"]["uv_index"] = [1.5] * len(HOURS)
        data["daily"]["sunrise"] = [d + "T07:30" for d in DAYS]
        data["daily"]["sunset"] = [d + "T16:50" for d in DAYS]
        data["daily"]["moonrise"] = [d + "T10:00" for d in DAYS[:-1]] + [None]
        data["daily"]["moonset"] = [d + "T20:00" for d in DAYS]
    return data

POINTS = ("point_id;point_type_id;station_abbr;postal_code;point_name;point_type_en;point_height_masl;"
          "point_coordinates_lv95_east;point_coordinates_lv95_north;point_coordinates_wgs84_lat;point_coordinates_wgs84_lon\n"
          "644000;2;;6440;Brunnen;Postal code;435.0;2688000;1205000;46.9936;8.6050\n"
          "644000;3;;;Fronalpstock;Mountain;1921.0;2690000;1203000;46.9930;8.6060\n"
          "77;1;ALT;;Altdorf;Station;438.0;2690000;1193000;46.887;8.622\n"
          "800100;2;;8001;Z\xfcrich;Postal code;408.0;2683000;1247000;47.3717;8.5423\n").encode("latin-1")

def stamp(day):   # lokaler Tagesbeginn als UTC, wie in den Dateien
    at = datetime.fromisoformat(day).replace(tzinfo=ZH).astimezone(timezone.utc)
    return at.strftime("%Y%m%d%H%M")

def param_csv(param, values, wrong):
    rows = ['"point_id";"point_type_id";"Date";"%s"' % param]
    for i, d in enumerate(DAYS):
        rows.append("644000;3;%s;%s" % (stamp(d), wrong))          # gleiche id, anderer Typ
        rows.append("800100;2;%s;%s" % (stamp(d), wrong))
        rows.append("644000.0;2;%s;%s" % (stamp(d), values[i]))
    rows.append("644000;2;kaputt;1")
    rows.append("")
    return "\n".join(rows).encode("latin-1")

RUN_OLD, RUN_NEW = TODAY.strftime("%Y%m%d") + "0300", TODAY.strftime("%Y%m%d") + "0900"
PICTO = [1, 3, 17, 22, 5, 14, 27, 112, 2]
FILES = {"jp2000d0": param_csv("jp2000d0", PICTO, 99), "tre200pn": param_csv("tre200pn", [-2.5 + i for i in range(9)], 55),
         "tre200px": param_csv("tre200px", [4.5 + i for i in range(9)], 55),
         "rreq10p0": param_csv("rreq10p0", [0.0, 0.2, 2.2, 10.5, 0.0, 1.0, 0.0, 3.0, 0.0], 77),
         "rreq90p0": param_csv("rreq90p0", [0.0, 1.4, 8.4, 31.0, 0.3, 4.0, 0.0, 9.5, 0.1], 77)}

class Net:
    def __init__(self, mod, fail=()):
        self.fail, self.calls, self.mod = set(fail), [], mod
    def __call__(self, url, timeout=7.0):
        self.calls.append(url)
        if "open-meteo" in url:
            which = "icon" if "models=" in url else "best"
            if which in self.fail: raise urllib.error.URLError("down")
            assert "timezone=auto" in url and "forecast_days=9" in url and "latitude=4" in url, url
            return json.dumps(om("x" if which == "icon" else None)).encode()
        if url.endswith("meta_point.csv"):
            if "points" in self.fail: raise urllib.error.URLError("down")
            return POINTS
        if "/items/" in url:
            if "stac" in self.fail: raise urllib.error.HTTPError(url, 404, "nf", None, None)
            item = url.rsplit("/", 1)[1]
            if "today404" in self.fail and item.startswith(TODAY.strftime("%Y%m%d")):
                raise urllib.error.HTTPError(url, 404, "nf", None, None)
            assets = {}
            for run in (RUN_OLD, RUN_NEW):
                for p in list(FILES) + ["tre200h0"]:
                    assets["vnut12.lssw.%s.%s.csv" % (run, p)] = {"href": "https://data/%s/%s.csv" % (run, p)}
            return json.dumps({"id": item, "assets": assets}).encode()
        if url.startswith("https://data/"):
            run, name = url.split("/")[-2:]
            assert run == RUN_NEW, "alter Lauf geladen: " + url
            if "csv" in self.fail: raise urllib.error.URLError("down")
            return FILES[name[:-4]]
        raise AssertionError("unerwartete URL " + url)

def fresh(fail=()):
    mod = load()
    os.environ["XDG_CACHE_HOME"] = tempfile.mkdtemp()
    mod.http_get = Net(mod, fail)
    return mod

def shape(f):
    assert set(f) >= {"latitude", "longitude", "current", "hourly", "daily"}
    n = len(f["hourly"]["time"]); assert n == 216, n
    for k, v in f["hourly"].items(): assert len(v) == n, k
    m = len(f["daily"]["time"]); assert m == 9
    for k, v in f["daily"].items(): assert len(v) == m, k
    for k in ("sunrise", "sunset", "moonrise", "moonset"):
        assert all(isinstance(x, str) for x in f["daily"].get(k, [])), k
    json.dumps(f, allow_nan=False)
    allowed_c = {"time","temperature_2m","apparent_temperature","relative_humidity_2m","is_day","weather_code","surface_pressure","wind_speed_10m","wind_direction_10m"}
    assert set(f["current"]) == allowed_c, set(f["current"]) ^ allowed_c

def t_full():
    mod = fresh(); f, info = mod.build(46.99, 8.60); shape(f)
    assert info["point"]["name"] == "Brunnen" and info["point"]["point_type_id"] == "2", info["point"]
    assert info["run"] == RUN_NEW and info["official_days"] == 9, info
    d = f["daily"]
    assert d["weather_code"] == [0, 2, 63, 75, 3, 61, 3, 95, 1], d["weather_code"]
    assert d["temperature_2m_min"] == [-2.5 + i for i in range(9)] and d["temperature_2m_max"][0] == 4.5
    assert d["precipitation_probability_max"] == [40]*5 + [None]*4
    assert d["moonrise"][-1] == "" and d["sunrise"][0].endswith("T07:30")
    h = f["hourly"]
    assert h["temperature_2m"][0] == 1.0 and h["temperature_2m"][119] < 50 and h["temperature_2m"][120] > 100   # ICON, dann best match
    assert h["visibility"][0] == 20000.0 and h["uv_index"][200] == 1.5
    assert f["current"]["temperature_2m"] == 5.5 and f["timezone"] == "Europe/Zurich" and f["utc_offset_seconds"] == 3600
    assert not mod.notes, mod.notes
    extras = json.load(open(os.path.join(os.path.dirname(mod.cache_dir()), "weather-extras.json"), encoding="utf-8"))
    assert extras["provider"] == "alpeMeteoSwiss" and extras["name"] == "MeteoSchweiz" and extras["point"]["name"] == "Brunnen"
    assert abs(extras["updated"] - __import__("time").time()) < 60 and extras["run"] == RUN_NEW and len(extras["days"]) == 9
    assert extras["days"][DAYS[2]] == {"precip_min": 2.2, "precip_max": 8.4, "text": "stark bewölkt, zeitweise Regen", "pictogram": 17}
    assert extras["days"][DAYS[7]]["text"] == "Aufhellungen, leicht gewitterhaft" and extras["days"][DAYS[0]]["precip_max"] == 0.0

def t_cache():
    mod = fresh(); mod.build(46.99, 8.60); first = len(mod.http_get.calls)
    mod.notes.clear(); mod.http_get.calls.clear(); f, info = mod.build(46.99, 8.60)
    assert all("open-meteo" in u for u in mod.http_get.calls), mod.http_get.calls     # nichts von geo.admin.ch
    assert info["official_days"] == 9 and first == 9, first

def t_stale_then_down():
    mod = fresh(); mod.build(46.99, 8.60)
    path = [p for p in os.listdir(mod.cache_dir()) if p.startswith("daily-")]; assert path == ["daily-2-644000.json"], path
    full = os.path.join(mod.cache_dir(), path[0]); c = json.load(open(full)); c["fetched"] -= 3600; json.dump(c, open(full, "w"))
    mod.http_get.fail = {"stac"}; mod.notes.clear(); f, info = mod.build(46.99, 8.60)
    assert info["official_days"] == 9 and any("nicht aktualisiert" in n for n in mod.notes), mod.notes
    c["fetched"] -= 13 * 3600; json.dump(c, open(full, "w")); mod.notes.clear(); f, info = mod.build(46.99, 8.60)
    assert info["official_days"] == 0 and f["daily"]["weather_code"][0] == 61; shape(f)

def t_no_icon():
    mod = fresh({"icon"}); f, info = mod.build(46.99, 8.60); shape(f)
    assert f["hourly"]["temperature_2m"][0] > 100 and info["official_days"] == 9 and f["current"]["temperature_2m"] == 105.5
    assert f["daily"]["precipitation_probability_max"] == [40]*9      # ohne ICON-CH bleibt das Standardmodell

def t_no_best():
    mod = fresh({"best"}); f, info = mod.build(46.99, 8.60); shape(f)
    assert f["hourly"]["temperature_2m"][130] is None and "visibility" not in f["hourly"] and "sunrise" not in f["daily"]
    assert f["daily"]["weather_code"][8] == 1 and f["daily"]["precipitation_probability_max"][8] is None

def t_no_ogd():
    for fail in ({"points"}, {"stac"}, {"csv"}):
        mod = fresh(fail); f, info = mod.build(46.99, 8.60); shape(f)
        assert info["official_days"] == 0 and f["daily"]["weather_code"][:5] == [61]*5 and mod.notes, (fail, mod.notes)

def t_yesterday_item():
    mod = fresh({"today404"}); f, info = mod.build(46.99, 8.60); assert info["official_days"] == 9

def t_abroad():
    mod = fresh(); f, info = mod.build(48.85, 2.35); shape(f)
    assert info["point"] is None and info["official_days"] == 0 and any("km" in n for n in mod.notes)
    assert not os.path.exists(os.path.join(os.path.dirname(mod.cache_dir()), "weather-extras.json"))

def t_old_cache_ignored():
    mod = fresh(); mod.build(46.99, 8.60)
    full = os.path.join(mod.cache_dir(), "daily-2-644000.json"); c = json.load(open(full)); del c["v"]; json.dump(c, open(full, "w"))
    mod.http_get.calls.clear(); mod.build(46.99, 8.60)
    assert any("/items/" in u for u in mod.http_get.calls) and json.load(open(full))["v"] == 2

def t_extras_removed():
    mod = fresh(); mod.build(46.99, 8.60)
    path = os.path.join(os.path.dirname(mod.cache_dir()), "weather-extras.json"); assert os.path.exists(path)
    cached = [p for p in os.listdir(mod.cache_dir()) if p.startswith("daily-")][0]
    os.unlink(os.path.join(mod.cache_dir(), cached)); mod.http_get.fail = {"stac"}; mod.build(46.99, 8.60)
    assert not os.path.exists(path)                 # ohne amtliche Daten keine alten Mengen

def t_all_down():
    mod = fresh({"icon", "best"})
    try: mod.build(46.99, 8.60); raise SystemExit("haette scheitern muessen")
    except RuntimeError as e: assert "Open-Meteo" in str(e)

def t_dates():
    mod = load()
    assert mod.local_date("202610062200") == "2026-10-07" and mod.local_date("202611152300") == "2026-11-16"
    assert mod.local_date("202611160000") == "2026-11-16" and mod.local_date("x") is None and mod.local_date('"202601010000"') == "2026-01-01"
    assert mod.integer_text(" 8840.0 ") == "8840" and mod.integer_text('"12"') == "12" and mod.integer_text("ab") == "ab"

for name, fn in sorted(globals().items()):
    if name.startswith("t_"):
        fn(); print("ok", name)
