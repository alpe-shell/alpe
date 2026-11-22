"""Tests fuer die Werkzeuge: fastfetch.py, kopfleiste.py, titelleisten.py, alpe version --short."""
import importlib.util, json, os, subprocess, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.join(HERE, "..", "tools")

VORHER = """{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    // Logo von früher
    "logo": { "source": "windows", "padding": { "top": 2, "left": 2 }, "color": { "1": "magenta", "2": "blue" } },
    "display": { "separator": " ➜  ", "color": { "keys": "magenta", "title": "blue" } },
    "modules": [
        "title",
        "separator",
        { "type": "custom", "key": "󰣇 OS     ", "format": "Alpe 0.9" },
        { "type": "kernel", "key": "󰒋 Kernel ", "format": "{1} {2}" },
        "colors",
    ]
}
"""


def load(name):
    spec = importlib.util.spec_from_file_location(name.replace(".", "_"), os.path.join(TOOLS, name))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def run_tool(name, args, config):
    env = dict(os.environ, XDG_CONFIG_HOME=config)
    return subprocess.run(["python3", os.path.join(TOOLS, name)] + args, env=env, capture_output=True, text=True)


def t_fastfetch():
    config = tempfile.mkdtemp()
    os.makedirs(os.path.join(config, "fastfetch"))
    path = os.path.join(config, "fastfetch", "config.jsonc")
    open(path, "w", encoding="utf-8").write(VORHER)
    out = run_tool("fastfetch.py", [], config)
    assert out.returncode == 0, out.stdout + out.stderr
    data = json.load(open(path, encoding="utf-8"))
    assert data["logo"]["type"] == "file" and data["logo"]["source"].endswith("fastfetch/alpe-logo.txt")
    assert data["logo"]["padding"] == {"top": 2, "left": 2}
    line = data["modules"][2]
    assert line == {"type": "command", "key": "󰣇 OS     ", "text": "alpe version --short"}, line
    assert data["display"]["separator"] == " ➜  " and len(data["modules"]) == 5
    assert open(path + ".vor-alpe", encoding="utf-8").read() == VORHER          # Sicherung mit Kommentar
    assert "$1" in open(os.path.join(config, "fastfetch", "alpe-logo.txt"), encoding="utf-8").read()
    again = run_tool("fastfetch.py", [], config)
    assert "schon eingerichtet" in again.stdout, again.stdout


def t_fastfetch_without_alpe_line():
    mod = load("fastfetch.py")
    out = mod.adapt({"modules": ["title", "separator", "kernel"]})
    assert out["modules"][2]["text"] == "alpe version --short"
    assert mod.strip_comments('{"a": "x//y", /* b */ "c": [1,],}') == '{"a": "x//y",  "c": [1]}'


def t_kopfleiste():
    config = tempfile.mkdtemp()
    os.makedirs(os.path.join(config, "gtk-4.0"))
    gtk = os.path.join(config, "gtk-4.0", "gtk.css")
    open(gtk, "w").write('@import "alpe-colors.css";\n')
    assert run_tool("kopfleiste.py", ["schlank"], config).returncode == 0
    lines = open(gtk).read().splitlines()
    assert lines[0].startswith('@import url("alpe-apps.css")') and lines[1] == '@import "alpe-colors.css";'
    for folder in ("gtk-4.0", "gtk-3.0"):
        assert "proton-app headerbar" in open(os.path.join(config, folder, "alpe-apps.css")).read()
    assert "schlank" in run_tool("kopfleiste.py", ["status"], config).stdout
    run_tool("kopfleiste.py", ["weg"], config)
    assert open(gtk).read().count("alpe-apps.css") == 1                             # nicht doppelt
    assert "-gtk-icon-size" in open(os.path.join(config, "gtk-4.0", "alpe-apps.css")).read()
    assert "-gtk-icon-size" not in open(os.path.join(config, "gtk-3.0", "alpe-apps.css")).read()
    run_tool("kopfleiste.py", ["aus"], config)
    assert open(gtk).read() == '@import "alpe-colors.css";\n'
    assert not os.path.exists(os.path.join(config, "gtk-4.0", "alpe-apps.css"))


def t_version_short():
    shell = tempfile.mkdtemp()
    os.makedirs(os.path.join(shell, "Common"))
    open(os.path.join(shell, "Common", "Brand.qml"), "w").write(
        'QtObject {\n    readonly property string version: "1.0"\n    readonly property string codename: "Zugerberg"\n}\n')
    out = subprocess.run(["bash", os.path.join(TOOLS, "alpe"), "version", "--short"], env=dict(os.environ, ALPE_SHELL_DIR=shell),
                         capture_output=True, text=True)
    assert out.stdout.strip() == "Alpe 1.0 «Zugerberg»", out.stdout


def kwin_env(config):
    stub = os.path.join(HERE, "data", "kwinstub")
    shell = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "shell")
    return dict(os.environ, XDG_CONFIG_HOME=config, ALPE_KWRITECONFIG=os.path.join(stub, "kwriteconfig6"),
                ALPE_BUSCTL=os.path.join(stub, "busctl"), ALPE_SHELL_DIR=shell, ALPE_KWIN_VERSION=kwin_version)


kwin_version = "6.7.5"   # bisherige Prüfungen: Format vor KWin 6.8


def titles(config, *args):
    return subprocess.run(["python3", os.path.join(TOOLS, "titelleisten.py")] + list(args), env=kwin_env(config),
                          capture_output=True, text=True)


def t_titelleisten_orphan():
    """Eine Regel «ohne Titelleiste», die aus der Liste [General] rules gefallen ist, wird erkannt
    und wieder eingehängt statt doppelt angelegt."""
    config = tempfile.mkdtemp()
    open(os.path.join(config, "kwinrulesrc"), "w").write(
        "[General]\ncount=1\nrules=abc\n\n[abc]\nDescription=Zed\nwmclass=zed\nwmclassmatch=1\n\n"
        "[alt]\nDescription=Ohne Titelleiste\nnoborder=true\nnoborderrule=2\n")
    assert "verwaist" in titles(config, "status").stdout
    assert "wieder eingehängt" in titles(config, "aus").stdout
    out = titles(config, "status").stdout
    assert "für alle Fenster" in out and "verwaist" not in out, out


def t_titelleisten_new_rule():
    config = tempfile.mkdtemp()
    assert "angelegt" in titles(config, "aus").stdout
    text = open(os.path.join(config, "kwinrulesrc")).read()
    assert "Alpe: ohne Titelleiste" in text and "noborderrule=2" in text and "types=33" in text
    assert "Schon eingerichtet" in titles(config, "aus").stdout
    assert "entfernt" in titles(config, "an").stdout
    assert "Keine KWin-Regel" in titles(config, "status").stdout


def t_legacy_rules_stay():
    """Alte Datei ohne «rules», nur count und [1] …: eine neue Regel darf die alten nicht verdrängen."""
    config = tempfile.mkdtemp()
    open(os.path.join(config, "kwinrulesrc"), "w").write(
        "[General]\ncount=1\n\n[1]\nDescription=Ohne Titelleiste\nnoborder=true\nnoborderrule=2\n")
    env = kwin_env(config)
    script = os.path.join(env["ALPE_SHELL_DIR"], "scripts", "alpe-kwin.py")
    subprocess.run(["python3", script, "rule-set", json.dumps({"values": {"Description": "kitty", "wmclass": "kitty", "wmclassmatch": 1}})],
                   env=env, capture_output=True, text=True, check=True)
    assert "für alle Fenster" in titles(config, "status").stdout


# ---------------------------------------------------------------- KWin 6.8

def kwin68_read(config):
    """Was KWin 6.8 beim Einlesen mit kwinrulesrc tut (RuleBookSettings::usrRead): steht eine Liste
    «rules» da, werden alle Gruppen gelöscht, die nicht darin stehen. Gibt die Regeln zurück."""
    path = os.path.join(config, "kwinrulesrc")
    groups, cur = {}, None
    for line in open(path).read().splitlines():
        line = line.strip()
        if line.startswith("["):
            cur = line[1:-1]
            groups.setdefault(cur, {})
        elif "=" in line and cur:
            key, value = line.split("=", 1)
            groups[cur][key] = value
    legacy = [r for r in groups.get("General", {}).get("rules", "").split(",") if r]
    rules = {g: v for g, v in groups.items() if g != "General" and not g.startswith("$")}
    if legacy:
        rules = {g: v for g, v in rules.items() if g in legacy}
    return rules


def alpe_kwin(config, *args):
    env = kwin_env(config)
    script = os.path.join(env["ALPE_SHELL_DIR"], "scripts", "alpe-kwin.py")
    out = subprocess.run(["python3", script] + list(args), env=env, capture_output=True, text=True, check=True)
    return json.loads(out.stdout) if out.stdout.strip() else None


def with_kwin(version, fn):
    global kwin_version
    old, kwin_version = kwin_version, version
    try:
        fn()
    finally:
        kwin_version = old


def t_kwin68_neue_regel_behaelt_alle():
    """Unter KWin 6.8 schrieb Alpe «rules=<nur die neue Regel>» – KWin löschte daraufhin alle anderen."""
    def body():
        config = tempfile.mkdtemp()
        open(os.path.join(config, "kwinrulesrc"), "w").write(
            "[General]\nOrder=zed,titel\n\n[zed]\nDescription=Zed\nwmclass=dev.zed.Zed\nwmclassmatch=1\n"
            "opacityactive=86\nopacityactiverule=2\n\n[titel]\nDescription=Alpe: ohne Titelleiste\n"
            "decorationpolicy=none\ndecorationpolicyrule=2\ntypes=33\n")
        rid = alpe_kwin(config, "rule-set", json.dumps({"values": {"Description": "Wingdrive", "wmclass": "wingdrive",
                                                                   "wmclassmatch": 1, "opacityactive": 90, "opacityactiverule": 2}}))["id"]
        text = open(os.path.join(config, "kwinrulesrc")).read()
        assert "rules=" not in text and "count=" not in text, text
        assert "Order=zed,titel," + rid in text, text
        assert set(kwin68_read(config)) == {"zed", "titel", rid}
        alpe_kwin(config, "rule-delete", "zed")
        assert set(kwin68_read(config)) == {"titel", rid} and "Order=titel," + rid in open(os.path.join(config, "kwinrulesrc")).read()
        st = alpe_kwin(config, "state")
        titel = [r for r in st["rules"] if r["id"] == "titel"][0]
        assert titel["noborder"] == "true" and titel["noborderrule"] == "2", titel   # für die Seite übersetzt
    with_kwin("6.8.3", body)


def t_kwin68_migrate_rettet_veraltete_liste():
    """Eine veraltete Liste «rules» (von KWin vor 6.8 oder älterem Alpe) wird zu Order mit allen Gruppen, bevor KWin liest."""
    def body():
        config = tempfile.mkdtemp()
        open(os.path.join(config, "kwinrulesrc"), "w").write(
            "[General]\ncount=1\nrules=neu\n\n[alt]\nDescription=Zed\nwmclass=zed\n\n[neu]\nDescription=Wingdrive\nwmclass=wingdrive\n")
        assert set(kwin68_read(config)) == {"neu"}            # so ginge «Zed» verloren
        assert alpe_kwin(config, "migrate")["migrated"] is True
        text = open(os.path.join(config, "kwinrulesrc")).read()
        assert "rules=" not in text and "count=" not in text and "Order=alt,neu" in text, text
        assert set(kwin68_read(config)) == {"alt", "neu"}
        assert alpe_kwin(config, "migrate")["migrated"] is False   # zweites Mal nichts zu tun
    with_kwin("6.8.3", body)


def t_kwin68_titelleisten():
    def body():
        config = tempfile.mkdtemp()
        assert "angelegt" in titles(config, "aus").stdout
        text = open(os.path.join(config, "kwinrulesrc")).read()
        assert "decorationpolicy=none" in text and "decorationpolicyrule=2" in text and "noborder" not in text, text
        assert "rules=" not in text and "Order=" in text, text
        out = titles(config, "status").stdout
        assert "ohne Titelleiste" in out and "für alle Fenster" in out, out
        assert "Schon eingerichtet" in titles(config, "aus").stdout
        assert "entfernt" in titles(config, "an").stdout
        assert "Keine KWin-Regel" in titles(config, "status").stdout
    with_kwin("6.8.3", body)


def t_kwin67_bleibt_beim_alten_format():
    def body():
        config = tempfile.mkdtemp()
        alpe_kwin(config, "rule-set", json.dumps({"values": {"Description": "x", "noborder": True, "noborderrule": 2}}))
        text = open(os.path.join(config, "kwinrulesrc")).read()
        assert "rules=" in text and "noborderrule=2" in text and "Order" not in text and "decorationpolicy" not in text, text
    with_kwin("6.7.5", body)


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
