"""Tests fuer plugins/alpeRadar/radar. Braucht h5py. Musterdatei: MeteoSchweiz Open Data (Quelle: MeteoSchweiz)."""
import importlib.machinery, importlib.util, json, os, struct, tempfile, urllib.error, zlib
from datetime import datetime, timedelta, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
SAMPLE = os.path.join(HERE, "data", "rzc263201930vl.001.h5")

def load():
    loader = importlib.machinery.SourceFileLoader("radar_mod", os.path.join(HERE, "..", "plugins", "alpeRadar", "radar"))
    spec = importlib.util.spec_from_loader("radar_mod", loader)
    mod = importlib.util.module_from_spec(spec); loader.exec_module(mod)
    os.environ["XDG_CACHE_HOME"] = tempfile.mkdtemp()
    return mod

def read_png(path):
    raw = open(path, "rb").read(); assert raw[:8] == b"\x89PNG\r\n\x1a\n"
    at, chunks = 8, {}
    while at < len(raw):
        size, kind = struct.unpack(">I4s", raw[at:at + 8]); body = raw[at + 8:at + 8 + size]
        assert struct.unpack(">I", raw[at + 8 + size:at + 12 + size])[0] == zlib.crc32(kind + body) & 0xFFFFFFFF
        chunks[kind] = chunks.get(kind, b"") + body; at += 12 + size
    width, height, depth, colour = struct.unpack(">IIBB", chunks[b"IHDR"][:10])
    rows = zlib.decompress(chunks[b"IDAT"]); assert len(rows) == height * (width * 4 + 1)
    return width, height, depth, colour, rows

def key(at):
    return "rzc%s%svl.001.h5" % (at.strftime("%y%j"), at.strftime("%H%M"))

def t_render():
    mod = load(); out = os.path.join(mod.cache_dir(), "x.png")
    wet = mod.render(SAMPLE, out); assert 0.25 < wet < 0.35, wet
    width, height, depth, colour, rows = read_png(out)
    assert (width, height, depth, colour) == (520, 370, 8, 6)
    stride = width * 4 + 1
    def pixel(x, y): return tuple(rows[y * stride + 1 + x * 4: y * stride + 5 + x * 4])
    assert pixel(288, 165) == (0, 0, 0, 0)                 # Brunnen war um 19:30 UTC trocken
    assert pixel(100, 100)[3] > 0                          # Jura: Niederschlag
    colours = {c[1] for c in mod.SCALE}
    assert {pixel(x, y) for x in range(0, 520, 7) for y in range(0, 370, 7)} <= colours | {(0, 0, 0, 0)}

def t_times():
    mod = load()
    assert mod.frame_time("rzc263201930vl.001.h5") == datetime(2026, 11, 16, 19, 30, tzinfo=timezone.utc)
    assert mod.frame_time("RZC243662355VL.801.h5") == datetime(2024, 12, 31, 23, 55, tzinfo=timezone.utc)
    for bad in ("cpc263201930_00060.001.h5", "rzc26320.h5", "rzc263992500vl.001.h5", "rzc263201930vl.001.txt", "tzc263201930vl.001.h5"):
        assert mod.frame_time(bad) is None, bad

def t_update():
    mod = load(); now = datetime.now(timezone.utc).replace(second=0, microsecond=0)
    now -= timedelta(minutes=now.minute % 5)
    times = [now - timedelta(minutes=5 * i) for i in range(30)]
    calls = []
    def get(url):
        calls.append(url)
        if "/items/" in url:
            day = url.rsplit("/", 1)[1][:8]
            assets = {key(t): {"href": "https://data/" + key(t)} for t in times if t.strftime("%Y%m%d") == day}
            assets["cpc%s_00060.001.h5" % now.strftime("%y%j%H%M")] = {"href": "https://data/cpc"}
            assets[key(now).replace("vl.001", "vl.801")] = {"href": "https://data/DOPPELT"}     # zweite Datei, gleiche Zeit
            if not any(t.strftime("%Y%m%d") == day for t in times): raise urllib.error.HTTPError(url, 404, "nf", None, None)
            return json.dumps({"assets": assets}).encode()
        if url.endswith("kaputt"): raise urllib.error.URLError("down")
        return open(SAMPLE, "rb").read()
    mod.http_get = get
    out = mod.update(12)
    assert len(out["frames"]) == 12 and out["extent"] == [2400000, 1000000, 2920000, 1370000] and len(out["legend"]) == 10
    assert not any(f["forecast"] for f in out["frames"])
    stamps = [f["time"] for f in out["frames"]]; assert stamps == sorted(stamps) and stamps[-1] == now.strftime("%Y-%m-%dT%H:%M:00Z")
    assert all(os.path.exists(f["path"]) for f in out["frames"]) and "https://data/DOPPELT" in calls and not out["errors"]
    assert not [n for n in os.listdir(mod.cache_dir()) if not n.endswith(".png")], os.listdir(mod.cache_dir())
    calls.clear(); out = mod.update(12)
    assert all("/items/" in u for u in calls), calls                # nichts doppelt geladen
    calls.clear(); out = mod.update(24); assert len(out["frames"]) == 24 and sum("/items/" not in u for u in calls) == 12
    for i in range(60):                                                # Aufraeumen: hoechstens KEEP Bilder
        open(os.path.join(mod.cache_dir(), "2020010100%02d.png" % i), "wb").close()
    mod.update(12); assert len([n for n in os.listdir(mod.cache_dir()) if n.endswith(".png")]) == mod.KEEP

def shifted_copy(folder, columns):
    """Die Musterdatei, um columns Zellen nach Osten verschoben."""
    import h5py, numpy, shutil
    path = os.path.join(folder, "shift%d.h5" % columns); shutil.copyfile(SAMPLE, path)   # copyfile: Muster ist schreibgeschützt
    with h5py.File(path, "r+") as handle:
        data = handle["dataset1/data1/data"]; grid = numpy.nan_to_num(data[()])
        moved = numpy.zeros_like(grid); moved[:, columns:] = grid[:, :grid.shape[1] - columns] if columns else grid
        data[...] = moved
    return open(path, "rb").read()

def t_ahead():
    import numpy
    mod = load(); now = datetime.now(timezone.utc).replace(second=0, microsecond=0)
    now -= timedelta(minutes=now.minute % 5)
    times = [now - timedelta(minutes=5 * i) for i in range(8)]
    work = tempfile.mkdtemp()
    bodies = {key(t): shifted_copy(work, 6 * (7 - i)) for i, t in enumerate(times)}     # 6 km je 5 Minuten nach Osten
    def get(url):
        if "/items/" in url:
            day = url.rsplit("/", 1)[1][:8]
            assets = {k: {"href": "https://data/" + k} for k in bodies if mod.frame_time(k).strftime("%Y%m%d") == day}
            if not assets: raise urllib.error.HTTPError(url, 404, "nf", None, None)
            return json.dumps({"assets": assets}).encode()
        return bodies[url.rsplit("/", 1)[1]]
    mod.http_get = get
    out = mod.update(6, 60)
    real = [f for f in out["frames"] if not f["forecast"]]; ahead = [f for f in out["frames"] if f["forecast"]]
    assert len(real) == 6 and len(ahead) == 12 and not out["errors"], out["errors"]
    assert ahead[0]["time"] == (now + timedelta(minutes=5)).strftime("%Y-%m-%dT%H:%M:00Z") and ahead[-1]["time"] == (now + timedelta(minutes=60)).strftime("%Y-%m-%dT%H:%M:00Z")
    names = sorted(os.listdir(mod.cache_dir()))
    assert len([n for n in names if n.startswith("raw-")]) == 4 and len([n for n in names if n.startswith("ahead-")]) == 12, names
    # Die Stroemung: 1.2 km pro Minute nach Osten, nichts nach Norden oder Sueden.
    last = mod.load_raw(os.path.join(mod.cache_dir(), "raw-%s.npz" % now.strftime("%Y%m%d%H%M")))
    before = mod.load_raw(os.path.join(mod.cache_dir(), "raw-%s.npz" % (now - timedelta(minutes=10)).strftime("%Y%m%d%H%M")))
    field = mod.motion_field(before, last, 10.0); wet = last > 0.1
    assert abs(float(numpy.median(field[1][wet])) - 1.2) < 0.06 and abs(float(numpy.median(field[0][wet]))) < 0.03
    future = mod.advect(last, field, 30); truth = numpy.zeros_like(last); truth[:, 36:] = last[:, :-36]
    hit = ((future > 0.1) & (truth > 0.1)).sum() / ((future > 0.1) | (truth > 0.1)).sum(); assert hit > 0.85, hit
    width, height, depth, colour, rows = read_png(ahead[5]["path"]); assert (width, height) == (520, 370)
    # Zweiter Aufruf rechnet nichts neu; ohne --ahead verschwinden Hochrechnung und Raster.
    stamp = os.path.getmtime(ahead[0]["path"]); mod.update(6, 60); assert os.path.getmtime(ahead[0]["path"]) == stamp
    out = mod.update(6, 30); assert len([f for f in out["frames"] if f["forecast"]]) == 6
    assert len([n for n in os.listdir(mod.cache_dir()) if n.startswith("ahead-")]) == 6
    out = mod.update(6); assert not any(f["forecast"] for f in out["frames"])
    assert not [n for n in os.listdir(mod.cache_dir()) if n.startswith(("ahead-", "raw-"))]

def t_ahead_dry():
    import numpy
    mod = load(); grid = numpy.zeros((640, 710), dtype="float32")
    assert mod.motion_field(grid, grid, 10.0) is None
    still = mod.advect(numpy.ones((640, 710), dtype="float32"), numpy.zeros((2, 640, 710), dtype="float32"), 30)
    assert float(still.min()) == 1.0

def t_failures():
    mod = load()
    def down(url): raise urllib.error.HTTPError(url, 404, "nf", None, None)
    mod.http_get = down
    try: mod.update(12); raise SystemExit("haette scheitern muessen")
    except RuntimeError as error: assert "keine Radarbilder" in str(error)
    now = datetime.now(timezone.utc).replace(second=0, microsecond=0)
    def broken(url):
        if "/items/" in url: return json.dumps({"assets": {key(now): {"href": "https://data/x"}}}).encode()
        return b"kein hdf5"
    mod.http_get = broken
    try: mod.update(12); raise SystemExit("haette scheitern muessen")
    except RuntimeError as error: assert "kein Bild umgerechnet" in str(error)
    assert os.listdir(mod.cache_dir()) == []

for name, fn in sorted(globals().items()):
    if name.startswith("t_"):
        fn(); print("ok", name)
