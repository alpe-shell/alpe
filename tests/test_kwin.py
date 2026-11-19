#!/usr/bin/env python3
"""Prüft scripts/alpe-kwin.py mit Attrappen für kwriteconfig6 und busctl.

    python3 tests/test_kwin.py          nimmt ~/dux-shell (oder ALPE_SHELL_DIR)
"""
import json
import os
import subprocess
import sys
import tempfile
import textwrap

SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.expanduser("~"), "dux-shell")
SCRIPT = os.path.join(SHELL, "quickshell", "scripts", "alpe-kwin.py")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    if not cond:
        failures += 1


tmp = tempfile.mkdtemp()
cfg = os.path.join(tmp, "config")
os.makedirs(cfg)
log = os.path.join(tmp, "calls.log")

# kwriteconfig6-Attrappe: schreibt einfache KConfig-Dateien (Gruppen, Escapes \n) wie KDE.
kw = os.path.join(tmp, "kwriteconfig6")
with open(kw, "w") as f:
    f.write(textwrap.dedent(f'''\
        #!/usr/bin/env python3
        import sys, os
        a = sys.argv[1:]
        open({log!r}, "a").write("kwrite " + repr(a) + "\\n")
        file = groups = key = None; groups = []; value = None; delete = False
        i = 0
        while i < len(a):
            if a[i] == "--file": file = a[i+1]; i += 2
            elif a[i] == "--group": groups.append(a[i+1]); i += 2
            elif a[i] == "--key": key = a[i+1]; i += 2
            elif a[i] == "--delete": delete = True; i += 1
            elif a[i] == "--notify": i += 1
            else: value = a[i]; i += 1
        path = os.path.join({cfg!r}, file)
        head = "".join("[" + g + "]" for g in groups)
        lines = open(path).read().splitlines() if os.path.exists(path) else []
        out, cur, done = [], None, False
        def esc(v): return v.replace("\\\\", "\\\\\\\\").replace("\\n", "\\\\n")
        for ln in lines:
            if ln.startswith("["):
                if cur == head and not done and not delete:
                    out.append(key + "=" + esc(value)); done = True
                cur = ln.strip()
                out.append(ln); continue
            if cur == head and ln.split("=", 1)[0] == key:
                if not delete:
                    out.append(key + "=" + esc(value))
                done = True; continue
            out.append(ln)
        if not done and not delete:
            if cur != head:
                if head not in [l.strip() for l in out]:
                    out += ["", head]
                    out.append(key + "=" + esc(value))
                else:
                    idx = [l.strip() for l in out].index(head)
                    out.insert(idx + 1, key + "=" + esc(value))
            else:
                out.append(key + "=" + esc(value))
        open(path, "w").write("\\n".join(out) + "\\n")
        '''))
os.chmod(kw, 0o755)

# busctl-Attrappe: kglobalaccel mit zwei Komponenten, KWin-Effekte.
bc = os.path.join(tmp, "busctl")
with open(bc, "w") as f:
    f.write(textwrap.dedent(f'''\
        #!/usr/bin/env python3
        import sys, json
        a = sys.argv[1:]
        open({log!r}, "a").write("busctl " + repr(a) + "\\n")
        j = "--json=short" in a
        m = a[a.index("call") + 4] if "call" in a else ""
        if m == "allMainComponents":
            print(json.dumps({{"type": "aas", "data": [[["kwin", "KWin", "", ""], ["org.kde.konsole.desktop", "Konsole", "", ""], ["net.local.terminal.desktop", "Terminal", "", ""], ["dms", "Alpe", "", ""], ["kwin", "KWin", "", ""]]]}}))
        elif m == "getComponent":
            print(json.dumps({{"type": "o", "data": ["/component/" + a[-1]]}}))
        elif m == "allShortcutInfos":
            comp = a[a.index("call") + 2].split("/")[-1]
            rows = {{
                "kwin": [["Window Close", "Fenster schliessen", "kwin", "KWin", "default", "", [134217812 | 0], [134217812]],
                         ["Overview", "Übersicht", "kwin", "KWin", "default", "", [], [268435543]]],
                "dms": [["dms-launcher", "Alpe: Starter", "dms", "Alpe", "default", "", [[[268435488, 0, 0, 0]]], []]],
                "org.kde.konsole.desktop": [["NewWindow", "Neues Fenster", "org.kde.konsole.desktop", "Konsole", "default", "", [], []],
                                            ["_launch", "Konsole", "org.kde.konsole.desktop", "Konsole", "default", "", [201326676], [201326676]]],
                "net.local.terminal.desktop": [["_launch", "Starten", "net.local.terminal.desktop", "net.local.terminal", "default", "", [268435460], []]],
            }}[comp]
            print(json.dumps({{"type": "a(ssssssaiai)", "data": [rows]}}))
        elif m == "queryWindowInfo":
            print(json.dumps({{"type": "a{{sv}}", "data": [{{"resourceClass": {{"type": "s", "data": "org.gnome.Nautilus"}}, "caption": {{"type": "s", "data": "Downloads"}}, "x": {{"type": "d", "data": 1.0}}}}]}}))
        elif m == "isEffectLoaded":
            print(json.dumps({{"type": "b", "data": [a[-1] == "better_blur_dx"]}}))
        '''))
os.chmod(bc, 0o755)

with open(os.path.join(cfg, "kwinrulesrc"), "w") as f:
    f.write(textwrap.dedent('''\
        [$Version]
        update_info=kwinrules.upd:replace-placement-string-to-enum

        [3f1c]
        Description=Keine Titelleiste
        noborder=true
        noborderrule=2
        types=1
        wmclassmatch=0

        [7aa0]
        Description=kitty Lage
        position=812,240
        positionrule=4
        wmclass=kitty
        wmclassmatch=1

        [General]
        count=2
        rules=3f1c,7aa0
        '''))
with open(os.path.join(cfg, "kwinrc"), "w") as f:
    f.write(textwrap.dedent('''\
        [Effect-better-blur-dx]
        BlurStrength=12
        WindowClasses=app.zen_browser.zen\\norg.gnome.Nautilus

        [Plugins]
        better_blur_dxEnabled=true
        blurEnabled=false

        [Round-Corners]
        Size=14

        [Windows]
        Placement=Smart
        '''))

# systemctl-Attrappe
sc_ = os.path.join(tmp, "systemctl")
with open(sc_, "w") as f:
    f.write(textwrap.dedent(f'''\
        #!/usr/bin/env python3
        import sys
        a = sys.argv[1:]
        open({log!r}, "a").write("systemctl " + repr(a) + "\\n")
        if "list-units" in a:
            print("dms.service loaded active running Alpe"); print("pipewire.service loaded active running PipeWire")
        elif "list-unit-files" in a:
            print("dms.service enabled enabled"); print("alpe-sync.service disabled enabled"); print("foo@.service static -")
        elif "show" in a:
            for n in a[a.index("show") + 3:]:
                own = n in ("alpe-sync.service",)
                print(f"Id={{n}}\\nDescription=D {{n}}\\nActiveState={{'active' if n != 'alpe-sync.service' else 'inactive'}}\\nSubState=running\\nUnitFileState=enabled\\nFragmentPath={{'/home/x/.config/systemd/user/' + n if own else '/usr/lib/systemd/user/' + n}}\\nDropInPaths={{'/home/x/.config/systemd/user/dms.service.d/kwin.conf' if n == 'dms.service' else ''}}\\nActiveEnterTimestamp=Tue\\nMainPID=1\\n")
        '''))
os.chmod(sc_, 0o755)

data_home = os.path.join(tmp, "data")
data_sys = os.path.join(tmp, "sys")
for d in (os.path.join(data_home, "applications"), os.path.join(data_sys, "applications", "kde")):
    os.makedirs(d)
def desktop(path, body):
    with open(path, "w") as f:
        f.write("[Desktop Entry]\n" + body + "\n[Desktop Action x]\nName=Falsch\n")
desktop(os.path.join(data_sys, "applications", "kitty.desktop"), "Type=Application\nName=kitty\nName[de]=Kitty-Terminal\nExec=kitty")
desktop(os.path.join(data_sys, "applications", "hidden.desktop"), "Type=Application\nName=Versteckt\nExec=x\nNoDisplay=true")
desktop(os.path.join(data_sys, "applications", "kde", "dolphin.desktop"), "Type=Application\nName=Dolphin\nExec=dolphin")
desktop(os.path.join(data_sys, "applications", "zed.desktop"), "Type=Application\nName=Zed (System)\nExec=zed")
desktop(os.path.join(data_home, "applications", "zed.desktop"), "Type=Application\nName=Zed\nExec=zed --eigen")
desktop(os.path.join(data_home, "applications", "net.local.terminal.desktop"), "Type=Application\nName=Terminal\nExec=kitty --single-instance\nNoDisplay=true")
env = dict(os.environ, XDG_CONFIG_HOME=cfg, ALPE_KWRITECONFIG=kw, ALPE_BUSCTL=bc, ALPE_SYSTEMCTL=sc_, HOME="/home/x", ALPE_KWIN_VERSION="6.7.5",
           XDG_DATA_HOME=data_home, XDG_DATA_DIRS=data_sys, LANG="de_CH.UTF-8", LC_MESSAGES="")


def run(*args):
    out = subprocess.run([sys.executable, "-I", SCRIPT] + list(args), env=env, capture_output=True, text=True)
    if out.returncode != 0:
        print(out.stderr)
    return json.loads(out.stdout or "{}")


s = run("state")
check([r["id"] for r in s["rules"]] == ["3f1c", "7aa0"], "Regeln in der Reihenfolge von [General] rules, [$Version] übersprungen")
check(s["rules"][1]["wmclass"] == "kitty" and s["rules"][1]["positionrule"] == "4", "Felder der kitty-Regel gelesen")
check(s["blurClasses"] == ["app.zen_browser.zen", "org.gnome.Nautilus"], "Better-Blur-Liste: zeilenweise, \\n entschlüsselt")
check(s["corners"]["Size"] == "14" and s["placement"] == "Smart" and s["animation"] == "1", "Ecken, Platzierung, Animation (Vorgabe 1)")
check(s["effects"]["blur"]["enabled"] is True and s["effects"]["blur"]["loaded"] is True and s["effects"]["corners"]["loaded"] is False, "Effekte: aktiviert/geladen")

r = run("rule-set", json.dumps({"id": "", "values": {"Description": "Zed", "wmclass": "dev.zed.Zed", "wmclassmatch": 1, "opacityactive": 86, "opacityactiverule": 2}, "blur": True}))
s = run("state")
new = [x for x in s["rules"] if x["id"] == r["id"]]
check(len(s["rules"]) == 3 and new and new[0]["opacityactive"] == "86", "neue Regel angehängt, Deckkraft 86")
check("dev.zed.Zed" in s["blurClasses"] and len(s["blurClasses"]) == 3, "Weichzeichnen: Klasse in Better-Blur-Liste")
rc = open(os.path.join(cfg, "kwinrulesrc")).read()
check("count=3" in rc and ("rules=3f1c,7aa0," + r["id"]) in rc, "[General] count und rules nachgeführt")

run("rule-set", json.dumps({"id": r["id"], "values": {"wmclass": "dev.zed.Zed2"}, "blur": True}))
s = run("state")
check("dev.zed.Zed2" in s["blurClasses"] and "dev.zed.Zed" not in s["blurClasses"], "Klasse umbenannt: Liste folgt")
run("rule-set", json.dumps({"id": r["id"], "values": {}, "blur": False}))
check("dev.zed.Zed2" not in run("state")["blurClasses"], "Weichzeichnen aus: Klasse entfernt, andere bleiben")

t = run("rule-set", json.dumps({"id": "", "values": {"Description": "kitty (fish)", "wmclass": "kitty", "wmclassmatch": 1, "title": "fish ~", "titlematch": 1}}))
tr = [x for x in run("state")["rules"] if x["id"] == t["id"]][0]
check(tr.get("title") == "fish ~" and tr.get("titlematch") == "1" and "title" not in tr["other"], "Fenster anklicken: Titel als Kriterium gespeichert und gelesen")
run("rule-set", json.dumps({"id": t["id"], "values": {"title": None, "titlematch": None}}))
tr = [x for x in run("state")["rules"] if x["id"] == t["id"]][0]
check("title" not in tr and "titlematch" not in tr, "Titel egal: Schlüssel gelöscht")
run("rule-delete", t["id"])

run("rule-delete", "7aa0")
s = run("state")
check([x["id"] for x in s["rules"]] == ["3f1c", r["id"]], "Regel gelöscht, Reihenfolge der übrigen bleibt")
check("kitty" not in open(os.path.join(cfg, "kwinrulesrc")).read().split("[General]")[0].split("[" + r["id"] + "]")[0].split("[3f1c]")[1], "Schlüssel der gelöschten Regel entfernt")

run("apply", json.dumps([["kwinrc", "Round-Corners", "Size", 18], ["kdeglobals", "KDE", "AnimationDurationFactor", 0.5], ["/etc/passwd", "x", "y", "z"]]))
s = run("state")
check(s["corners"]["Size"] == "18" and s["animation"] == "0.5", "apply schreibt kwinrc und kdeglobals")
calls = open(log).read()
check("passwd" not in calls, "apply schreibt nur in kwinrc, kdeglobals, kwinrulesrc")
check("reconfigureEffect" in calls and "'reconfigure'" in calls, "danach KWin und Effekte neu eingelesen")

sc = run("shortcuts")
names = [c["component"] for c in sc["components"]]
check(sc["available"] and names == ["kwin", "dms", "net.local.terminal.desktop", "org.kde.konsole.desktop"], "Kürzel: ohne Doppel; KWin, Alpe, eigene Befehle, Programme: " + str(names))
check(sc["components"][0]["actions"][0]["name"] == "Fenster schliessen" and sc["components"][0]["actions"][1]["defaults"] == [268435543], "Aktionen sortiert, Vorgaben dabei")
by = {c["component"]: c for c in sc["components"]}
check(by["dms"]["actions"][0]["keys"] == [268435488], "Tasten als (ai)-Struktur werden zur Zahl")
check(by["org.kde.konsole.desktop"].get("launch") and not by["org.kde.konsole.desktop"].get("custom") and by["org.kde.konsole.desktop"]["actions"][0]["action"] == "_launch", "Programm erkannt, «Starten» zuerst")
t = by["net.local.terminal.desktop"]
check(t.get("custom") and t["name"] == "Terminal" and t["command"] == "kitty --single-instance", "eigener Befehl mit Name und Befehl aus der Desktop-Datei")

ap = run("apps")["apps"]
check([a["id"] for a in ap] == ["kde-dolphin.desktop", "kitty.desktop", "zed.desktop"], "Programme: Unterordner mit «-», ohne versteckte und eigene Befehle: " + str([a["id"] for a in ap]))
check([a["name"] for a in ap] == ["Dolphin", "Kitty-Terminal", "Zed"], "Name in der Landessprache, eigene Datei vor der des Systems: " + str([a["name"] for a in ap]))

open(log, "w").close()
nw = run("shortcut-new", json.dumps({"kind": "command", "name": "Notizen öffnen", "command": "kitty -e nvim ~/notizen.md\nrm -rf ~", "keys": [268435534]}))
path = os.path.join(data_home, "applications", "net.local.notizen-oeffnen.desktop")
check(nw["ok"] and nw["component"] == "net.local.notizen-oeffnen.desktop" and os.path.exists(path), "neuer Befehl: Desktop-Datei net.local.<name>.desktop angelegt")
body = open(path).read()
check("Exec=kitty -e nvim ~/notizen.md rm -rf ~\n" in body and "X-KDE-GlobalAccel-CommandShortcut=true" in body and body.count("\n") == 7, "Befehl einzeilig (kein Zeilenumbruch schmuggelt Schlüssel ein)")
call = open(log).read()
check("'doRegister', 'as', '4', 'net.local.notizen-oeffnen.desktop', '_launch'" in call, "bei kglobalaccel angemeldet (doRegister)")
check("'setForeignShortcutKeys', 'asa(ai)', '4', 'net.local.notizen-oeffnen.desktop', '_launch', 'Notizen öffnen', 'Notizen öffnen', '1', '4', '268435534'" in call, "Taste für «_launch» gesetzt")
nw2 = run("shortcut-new", json.dumps({"kind": "command", "name": "Notizen öffnen", "command": "x", "keys": [1]}))
check(nw2["component"] == "net.local.notizen-oeffnen-2.desktop", "gleicher Name: eigene Datei mit Nummer")
open(log, "w").close()
na = run("shortcut-new", json.dumps({"kind": "app", "id": "kitty.desktop", "name": "Kitty-Terminal", "keys": [268435460]}))
check(na["ok"] and "'setForeignShortcutKeys', 'asa(ai)', '4', 'kitty.desktop', '_launch'" in open(log).read(), "Programm: Komponente ist die Desktop-Datei")
bad = run("shortcut-new", json.dumps({"kind": "app", "id": "../../etc/passwd", "keys": [1]}))
check(not bad["ok"], "Programm ohne gültige Desktop-ID abgewiesen")
open(log, "w").close()
rm = run("shortcut-remove", json.dumps({"component": "net.local.notizen-oeffnen.desktop", "action": "_launch"}))
call = open(log).read()
check(rm["removed"] and not os.path.exists(path) and "'unregister', 'ss', 'net.local.notizen-oeffnen.desktop', '_launch'" in call, "eigenen Befehl entfernen: Taste leer, abgemeldet, Datei weg")
rm2 = run("shortcut-remove", json.dumps({"component": "zed.desktop", "action": "_launch"}))
check(not rm2["removed"] and os.path.exists(os.path.join(data_home, "applications", "zed.desktop")), "Programm entfernen lässt seine Desktop-Datei stehen")

open(log, "w").close()
run("shortcut-set", json.dumps({"component": "kwin", "action": "Overview", "componentName": "KWin", "actionName": "Übersicht", "keys": [268435543, 0]}))
call = open(log).read()
check("'setForeignShortcutKeys', 'asa(ai)', '4', 'kwin', 'Overview', 'KWin', 'Übersicht', '1', '4', '268435543', '0', '0', '0'" in call, "Kürzel setzen: as + a(ai), Nullen weggelassen")
open(log, "w").close()
run("shortcut-set", json.dumps({"component": "kwin", "action": "Overview", "keys": []}))
check("'Overview', 'kwin', 'Overview', '0'" in open(log).read(), "Kürzel entfernen: leere Liste")

z = run("rule-set", json.dumps({"id": "", "values": {"Description": "x", "wmclass": "zz.App", "wmclassmatch": 1}, "blur": True}))["id"]
run("rule-set", json.dumps({"id": z, "values": {"wmclass": None, "wmclassmatch": 0}, "blur": False}))
s = run("state")
check("zz.App" not in s["blurClasses"] and not [x for x in s["rules"] if x["id"] == z][0].get("wmclass"), "auf «Alle Programme» umgestellt: Klasse gelöscht, aus der Blur-Liste")
run("effect", "kwin4_effect_shapecorners", "on")
s = run("state")
check(s["effects"]["corners"]["enabled"] is True, "Effekt eingeschaltet (Plugins …Enabled=true)")

pk = run("pick")
check(pk == {"resourceClass": "org.gnome.Nautilus", "caption": "Downloads"}, "Fenster anklicken: Klasse und Titel aus queryWindowInfo " + str(pk))
sv = run("services")
ids = [x["Id"] for x in sv["services"]]
check(ids == ["alpe-sync.service", "dms.service", "pipewire.service"], "Dienste: aus Units und Unit-Dateien, ohne Vorlagen: " + str(ids))
own = {x["Id"]: x["own"] for x in sv["services"]}
check(own["alpe-sync.service"] and not own["dms.service"], "eigene Dienste erkannt (~/.config/systemd/user)")
check([x for x in sv["services"] if x["Id"] == "dms.service"][0]["dropins"] == ["/home/x/.config/systemd/user/dms.service.d/kwin.conf"], "Drop-ins gelesen")
open(log, "w").close()
run("service", "enable", "alpe-sync.service")
check("'enable', '--now', 'alpe-sync.service'" in open(log).read(), "Autostart an: enable --now")
bad = subprocess.run([sys.executable, "-I", SCRIPT, "service", "start", "x; rm -rf ~"], env=env, capture_output=True, text=True)
check(bad.returncode != 0, "ungültiger Unit-Name abgewiesen")

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
