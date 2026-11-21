#!/usr/bin/env python3
"""Ladeprüfung der ganzen Shell: shell/shell.qml mit dem Dienst aus core/ in einem verschachtelten
Compositor starten, Popouts und alle Einstellungsseiten öffnen, Warnungen und Fehler sammeln und mit
einer Grundlinie vergleichen.

    python3 entwicklung/ladepruefung/ladepruefung.py kwin               vergleichen mit grundlinie-kwin.txt
    python3 entwicklung/ladepruefung/ladepruefung.py hyprland           dasselbe unter Hyprland
    python3 entwicklung/ladepruefung/ladepruefung.py kwin --grundlinie  Grundlinie neu schreiben (3 Läufe vereint)
    Optionen: --laeufe N  --dienst PFAD (statt neu bauen)  --behalten (Temp-Ordner nicht löschen)

Jeder Lauf läuft in einem eigenen systemd-Scope (alpe-ladepruefung-<zeit>-<n>.scope). Aufgeräumt wird
nur über diesen Scope (systemctl --user stop …), nie über Prozessnamen: Die echte Shell läuft unter
denselben Namen. Nach einer harten Obergrenze stoppt die Prüfung ihren Scope und meldet einen Hänger.

Die Testumgebung gilt erst im Scope: eigenes HOME, eigene XDG-Ordner und XDG_RUNTIME_DIR, eigener
Session-Bus (dbus-run-session), ein leerer Ersatz für den Systembus (kein logind, NetworkManager,
polkit, BlueZ), Attrappen für systemctl, loginctl, pkexec, sudo. Als Erstes prüft der Lauf, dass er
den echten systemd-Benutzerdienst nicht erreicht (sonst Abbruch). Der Compositor läuft virtuell
(kwin_wayland --virtual); Hyprland läuft verschachtelt darin, weil es keinen eigenständigen
Headless-Betrieb mehr kennt. Vorher wird das ausgelieferte Design (design/kde) mit den Alpe-Plugins
ins Temp-HOME gespielt.

Ergebnis: 0 = keine neuen Warnungen/Fehler gegenüber der Grundlinie, 1 = neue, 2 = Lauf gescheitert.
Unix-Sockets dürfen höchstens ~107 Zeichen lang sein (Hyprlands Socket liegt unter
$XDG_RUNTIME_DIR/hypr/<63 Zeichen>/); das Laufzeitverzeichnis ist darum der kurze Ordner lp-r direkt
unter $ALPE_LP_TMP bzw. $TMPDIR bzw. /tmp.
"""
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
SHELL = os.path.join(REPO, "shell")
CORE = os.path.join(REPO, "core")
UNIT_PREFIX = "alpe-ladepruefung-"
DAUER_START = 6       # Sekunden Ruhe nach dem Laden der Oberfläche, bevor die IPC-Aufrufe beginnen
DAUER_ENDE = 8        # Sekunden Ruhe nach dem letzten Aufruf
POPOUTS = [("spotlight", "toggle"), ("clipboard", "toggle"), ("processlist", "toggle"),
           ("notifications", "toggle"), ("control-center", "toggle"), ("dash", "toggle", ""),
           ("powermenu", "toggle"), ("notepad", "toggle")]

STUB = '#!/bin/sh\necho "{name} $*" >> "{log}"\nexit 1\n'
SYSTEMBUS = """<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <type>system</type>
  <listen>unix:path={sock}</listen>
  <auth>EXTERNAL</auth>
  <policy context="default"><allow send_destination="*"/><allow own="*"/></policy>
</busconfig>
"""


def say(text):
    print(text, flush=True)


def q(value):
    return shlex.quote(str(value))


def settings_tabs():
    text = open(os.path.join(SHELL, "Common", "SettingsTabs.qml"), encoding="utf-8").read()
    seen = []
    for tab in re.findall(r'"id":\s*"([a-z0-9_]+)"', text):
        if tab not in seen:
            seen.append(tab)
    return seen


def build_dienst(target):
    env = dict(os.environ, CGO_ENABLED="0")
    env.pop("GOFLAGS", None)
    subprocess.run(["go", "build", "-o", target, "./cmd/alpe-dienst"], cwd=CORE, env=env, check=True)


# ---------------------------------------------------------------- systemd (echte Umgebung, nur eigene Scopes)

def active_scopes():
    out = subprocess.run(["systemctl", "--user", "list-units", "--plain", "--no-legend", "--state=active,activating,deactivating",
                          UNIT_PREFIX + "*"], capture_output=True, text=True)
    return [line.split()[0] for line in out.stdout.splitlines() if line.strip()]


def scope_active(unit):
    out = subprocess.run(["systemctl", "--user", "is-active", unit], capture_output=True, text=True)
    return out.stdout.strip() in ("active", "activating", "deactivating")


def stop_scope(unit):
    """Beendet alles, was der Lauf gestartet hat (die ganze cgroup des Scopes), und nichts sonst."""
    if scope_active(unit):
        subprocess.run(["systemctl", "--user", "stop", unit], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


# ---------------------------------------------------------------- Skripte für den Lauf (laufen im Scope)

def session_script(base, dienst):
    """Startet den Dienst mit der Oberfläche, öffnet Popouts und Einstellungsseiten, beendet den Dienst."""
    calls = []
    for target, func, *rest in POPOUTS:
        args = " ".join(q(a) for a in rest)
        calls.append("ipc %s %s %s; sleep 1.5; ipc %s %s %s; sleep 0.5" % (target, func, args, target, func, args))
    for tab in settings_tabs():
        calls.append("ipc settings openWith %s; sleep 1.2" % tab)
    calls.append("ipc settings close; sleep 1")
    return """#!/bin/sh
# timeout -k: ein IPC-Aufruf, der TERM nicht beachtet, wird nach 2 s hart beendet.
ipc() {{ timeout -k 2 8 {dienst} ipc call "$@" >> {base}/ipc.log 2>&1; }}
{dienst} -c {shell} run > {base}/shell.log 2>&1 &
pid=$!
# Warten, bis die Oberfläche geladen ist und ihre IPC antwortet (höchstens 90 s + 30 s).
i=0
until grep -q "Configuration Loaded" {base}/shell.log 2>/dev/null; do
    i=$((i + 1)); [ $i -gt 180 ] && break; sleep 0.5
done
sleep {start}
i=0
until timeout -k 2 8 {dienst} ipc call settings close 2>/dev/null | grep -q SETTINGS_CLOSE_SUCCESS; do
    i=$((i + 1)); [ $i -gt 30 ] && break; sleep 1
done
echo "--- bereit" >> {base}/ipc.log
{calls}
sleep {ende}
echo "--- Ende nach Plan" >> {base}/ipc.log
kill -TERM $pid 2>/dev/null
for i in 1 2 3 4 5 6 7 8 9 10; do kill -0 $pid 2>/dev/null || break; sleep 0.5; done
kill -KILL $pid 2>/dev/null
wait $pid
echo "exit $?" > {base}/dienst.exit
""".format(dienst=q(dienst), base=q(base), shell=q(SHELL), start=DAUER_START, ende=DAUER_ENDE, calls="\n".join(calls))


def runner_script(base, compositor, sock, session):
    """Alles im Scope: Selbstprüfung, Vorbereitung des Temp-HOME, Ersatz-Systembus, Compositor."""
    if compositor == "kwin":
        start = session
    else:
        # Hyprland läuft mit seinem Wayland-Backend als Fenster im virtuellen kwin_wayland.
        start = os.path.join(base, "hyprland-start.sh")
    return """#!/bin/sh
base={base}
# 1. Selbstprüfung: Der echte systemd-Benutzerdienst darf von hier aus nicht erreichbar sein.
if /usr/bin/systemctl --user show-environment >/dev/null 2>&1; then
    echo "echter systemd-Benutzerdienst erreichbar" > "$base/abbruch"; exit 3
fi
# 2. Design und Plugins wie bei einer frischen Installation, ohne Dienst und kglobalaccel.
mkdir -p "$XDG_CONFIG_HOME/dms/plugins" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
cp -r {repo}/plugins/. "$XDG_CONFIG_HOME/dms/plugins/"
{{
    python3 {repo}/tools/activate-plugins.py
    ALPE_DESIGN_NO_SERVICE=1 ALPE_SHELL_DIR={shell} python3 {repo}/tools/design.py apply --ja --variante kde --bilder nein </dev/null
}} > "$base/vorbereitung.log" 2>&1
# 3. Leerer Ersatz für den Systembus.
dbus-daemon --config-file="$base/systembus.conf" --nofork >/dev/null 2>&1 &
i=0; while [ ! -S {sock} ] && [ $i -lt 50 ]; do i=$((i + 1)); sleep 0.1; done
# 4. Compositor ohne Bildschirm; endet mit dem Sitzungsskript.
dbus-run-session -- kwin_wayland --virtual --width 1920 --height 1080 --socket lp --no-lockscreen \\
    --exit-with-session {start} > "$base/compositor.log" 2>&1
echo "$?" > "$base/compositor.exit"
""".format(base=q(base), repo=q(REPO), shell=q(SHELL), sock=q(sock), start=q(start))


def hyprland_files(base, session):
    conf = os.path.join(base, "hyprland.lua")
    with open(conf, "w") as handle:
        handle.write('hl.config({ misc = { disable_hyprland_logo = true, disable_splash_rendering = true } })\n'
                     'hl.on("hyprland.start", function()\n    hl.exec_cmd(%s)\nend)\n' % ('"%s"' % session))
    starter = os.path.join(base, "hyprland-start.sh")
    with open(starter, "w") as handle:
        handle.write("""#!/bin/sh
Hyprland --config {conf} > {base}/hyprland.log 2>&1 &
h=$!
while kill -0 $h 2>/dev/null && [ ! -e {base}/dienst.exit ]; do sleep 1; done
kill -TERM $h 2>/dev/null; sleep 3; kill -KILL $h 2>/dev/null
wait $h
""".format(conf=q(conf), base=q(base)))
    os.chmod(starter, 0o755)


def test_env(base, home, rundir, stubs, sock, compositor):
    env = {
        "PATH": stubs + ":/usr/local/bin:/usr/bin:/bin",
        "HOME": home, "USER": os.environ.get("USER", "alpe"), "LOGNAME": os.environ.get("USER", "alpe"),
        "XDG_CONFIG_HOME": os.path.join(home, ".config"), "XDG_STATE_HOME": os.path.join(home, ".local", "state"),
        "XDG_CACHE_HOME": os.path.join(home, ".cache"), "XDG_DATA_HOME": os.path.join(home, ".local", "share"),
        "XDG_RUNTIME_DIR": rundir, "XDG_SESSION_TYPE": "wayland",
        "LANG": "de_CH.UTF-8", "LC_ALL": "de_CH.UTF-8",
        "DBUS_SYSTEM_BUS_ADDRESS": "unix:path=" + sock,
        "QT_QPA_PLATFORM": "wayland", "QS_DISABLE_CRASH_HANDLER": "1", "NO_AT_BRIDGE": "1",
    }
    if compositor == "kwin":
        env.update({"XDG_CURRENT_DESKTOP": "KDE", "KDE_FULL_SESSION": "true", "KDE_SESSION_VERSION": "6", "DESKTOP_SESSION": "plasma"})
    else:
        env.update({"XDG_CURRENT_DESKTOP": "Hyprland", "DESKTOP_SESSION": "hyprland",
                    "HYPRLAND_NO_SD_NOTIFY": "1", "HYPRLAND_NO_SD_VARS": "1"})
    return env


def rundir_users(rundir):
    """PIDs dieses Benutzers, deren XDG_RUNTIME_DIR der Laufzeitordner ist (nur lesend)."""
    wanted = ("XDG_RUNTIME_DIR=" + rundir).encode()
    pids = []
    for entry in os.listdir("/proc"):
        if not entry.isdigit():
            continue
        try:
            if os.stat("/proc/" + entry).st_uid != os.getuid():
                continue
            with open("/proc/%s/environ" % entry, "rb") as handle:
                if wanted in handle.read().split(b"\0"):
                    pids.append(int(entry))
        except OSError:
            continue
    return pids


def release_rundir(rundir):
    for mount in ("doc", "gvfs"):
        path = os.path.join(rundir, mount)
        if os.path.ismount(path):
            subprocess.run(["fusermount3", "-u", "-z", path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    shutil.rmtree(rundir, ignore_errors=True)


def one_run(compositor, dienst, keep, unit):
    root = os.environ.get("ALPE_LP_TMP") or tempfile.gettempdir()
    base = tempfile.mkdtemp(prefix="alpe-lp-", dir=root)
    home, stubs = os.path.join(base, "h"), os.path.join(base, "s")
    os.makedirs(home)
    os.makedirs(stubs)
    rundir = os.path.join(root, "lp-r")
    users = rundir_users(rundir)
    if users:
        shutil.rmtree(base, ignore_errors=True)
        raise SystemExit("FEHLER: %s wird noch benutzt (PIDs %s) – nichts gestartet" % (rundir, " ".join(map(str, users))))
    release_rundir(rundir)            # kein Scope aktiv und kein Prozess darin (geprüft): ein Rest ist verwaist
    os.makedirs(rundir)
    os.chmod(rundir, 0o700)
    for name in ("systemctl", "loginctl", "pkexec", "sudo", "systemd-run", "shutdown", "reboot", "poweroff"):
        path = os.path.join(stubs, name)
        with open(path, "w") as handle:
            handle.write(STUB.format(name=name, log=os.path.join(base, "stubs.log")))
        os.chmod(path, 0o755)
    sock = os.path.join(rundir, "sb")
    with open(os.path.join(base, "systembus.conf"), "w") as handle:
        handle.write(SYSTEMBUS.format(sock=sock))
    session = os.path.join(base, "sitzung.sh")
    with open(session, "w") as handle:
        handle.write(session_script(base, dienst))
    os.chmod(session, 0o755)
    if compositor == "hyprland":
        hyprland_files(base, session)
    runner = os.path.join(base, "lauf.sh")
    with open(runner, "w") as handle:
        handle.write(runner_script(base, compositor, sock, session))
    os.chmod(runner, 0o755)

    env = test_env(base, home, rundir, stubs, sock, compositor)
    # Laden (bis 120 s), Popouts, alle Seiten; unter verschachteltem Hyprland deutlich langsamer.
    limit = 180 + DAUER_START + DAUER_ENDE + 6 * len(POPOUTS) + 3 * len(settings_tabs())
    cmd = ["systemd-run", "--user", "--scope", "--collect", "--quiet", "--unit=" + unit,
           "/usr/bin/env", "-i"] + ["%s=%s" % kv for kv in sorted(env.items())] + ["/bin/sh", runner]
    started = time.time()
    hung = False
    with open(os.path.join(base, "scope.log"), "w") as out:
        proc = subprocess.Popen(cmd, stdout=out, stderr=out, stdin=subprocess.DEVNULL)
        try:
            proc.wait(timeout=limit)
        except subprocess.TimeoutExpired:
            hung = True
            say("   Obergrenze %d s erreicht – Scope %s wird gestoppt" % (limit, unit))
        finally:
            stop_scope(unit)
            try:
                proc.wait(timeout=30)
            except subprocess.TimeoutExpired:
                say("   WARNUNG: systemd-run endet nicht – bitte prüfen: systemctl --user status %s" % unit)
    release_rundir(rundir)
    result = {"base": base, "seconds": round(time.time() - started), "hung": hung, "limit": limit}
    for name in ("shell.log", "ipc.log", "stubs.log", "dienst.exit", "compositor.exit", "abbruch", "scope.log"):
        path = os.path.join(base, name)
        result[name] = open(path, errors="replace").read() if os.path.exists(path) else ""
    if not keep:
        shutil.rmtree(base, ignore_errors=True)
    return result


# ---------------------------------------------------------------- Auswertung

ANSI = re.compile(r"\x1b\[[0-9;]*m")
LEVEL = re.compile(r"^\s*(WARN|ERROR|FATAL|CRITICAL|CRIT)\b")
QMLERR = re.compile(r"(TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|"
                    r"Binding loop|Cannot read property|is not defined|Type .* unavailable|failed to load component)")


def normalize(line, base):
    line = ANSI.sub("", line).rstrip()
    line = line.replace(base, "<TMP>").replace(REPO, "<REPO>")
    line = re.sub(r"/tmp/[^\s\"']*alpe-lp-[^/\s\"']+", "<TMP>", line)
    line = re.sub(r"/[^\s\"']*/lp-r\b", "<RUN>", line)
    line = re.sub(r"0x[0-9a-fA-F]+", "0x…", line)
    line = re.sub(r"\(qs:\d+\)", "(qs)", line)
    line = re.sub(r"\b\d{1,2}:\d{2}:\d{2}(\.\d+)?\b", "<ZEIT>", line)
    line = re.sub(r"(alpe|dms)-\d+\.sock", r"\1-<PID>.sock", line)
    line = re.sub(r"\b\d+(\.\d+)?\s?(ms|s|µs)\b", "<DAUER>", line)
    line = re.sub(r"by-id/[a-z0-9]+", "by-id/<ID>", line)
    line = re.sub(r"\[pid \d+\]|pid[ =:]\d+", "pid <PID>", line)
    line = re.sub(r"<Unknown File>:\d+", "<Unknown File>:<N>", line)
    # Hashes aus dem zufälligen Temp-Pfad (Bild-Cache, Standbild eines Video-Hintergrunds)
    line = re.sub(r"imagecache/[0-9a-f]{8}@", "imagecache/<HASH>@", line)
    line = re.sub(r"video-wallpaper/[0-9a-f]{32}\.", "video-wallpaper/<HASH>.", line)
    # Zeilennummern verschieben sich bei jeder Änderung am Code; verglichen wird der Wortlaut.
    line = re.sub(r"(\.(?:qml|js))\[-?\d+:-?\d+\]", r"\1[<Z>]", line)
    line = re.sub(r"\[([A-Za-z_]\w*):\d+\]", r"[\1:<Z>]", line)
    return line.strip()


def findings(result):
    found = set()
    for raw in result["shell.log"].splitlines():
        plain = ANSI.sub("", raw)
        if LEVEL.search(plain) or QMLERR.search(plain):
            found.add(normalize(raw, result["base"]))
    return found


def health(result):
    """Kam die Shell wirklich hoch und lief der Ablauf durch? Sonst ist der Vergleich wertlos."""
    log = ANSI.sub("", result["shell.log"])
    problems = []
    if result["abbruch"]:
        problems.append("ABBRUCH der Selbstprüfung: " + result["abbruch"].strip())
        return problems
    if result["hung"]:
        problems.append("Hänger: Obergrenze von %d s erreicht, Scope gestoppt" % result["limit"])
    if "Configuration Loaded" not in log:
        problems.append("Oberfläche nicht geladen («Configuration Loaded» fehlt)")
    if "backend ready" not in log:
        problems.append("Dienst nicht bereit")
    if "--- bereit" not in result["ipc.log"]:
        problems.append("Oberfläche hat nicht auf IPC geantwortet")
    if "Ende nach Plan" not in result["ipc.log"]:
        problems.append("Ablauf nicht zu Ende gekommen")
    if re.search(r"(Segmentation fault|SIGSEGV|core dumped|Aborted)", log):
        problems.append("Absturz im Log")
    return problems


def main(argv):
    args = argv[1:]
    if not args or args[0] not in ("kwin", "hyprland"):
        say(__doc__)
        return 2
    compositor = args[0]
    write = "--grundlinie" in args
    keep = "--behalten" in args
    runs = int(args[args.index("--laeufe") + 1]) if "--laeufe" in args else (3 if write else 1)
    for need in ("kwin_wayland", "systemd-run", "dbus-run-session") + (("Hyprland",) if compositor == "hyprland" else ()):
        if not shutil.which(need):
            say("übersprungen: %s nicht installiert" % need)
            return 0
    running = active_scopes()
    if running:
        say("FEHLER: Es läuft schon eine Ladeprüfung: %s" % ", ".join(running))
        return 2
    baseline_path = os.path.join(HERE, "grundlinie-%s.txt" % compositor)
    if "--dienst" in args:
        dienst = os.path.abspath(args[args.index("--dienst") + 1])
        tmpbin = None
    else:
        tmpbin = tempfile.mkdtemp(prefix="alpe-lp-bau-", dir=os.environ.get("ALPE_LP_TMP") or tempfile.gettempdir())
        dienst = os.path.join(tmpbin, "alpe-dienst")
        say("== Dienst bauen (core/)")
        build_dienst(dienst)
    union = set()
    stamp = time.strftime("%Y%m%d-%H%M%S")
    try:
        for n in range(runs):
            unit = "%s%s-%s-%d.scope" % (UNIT_PREFIX, stamp, compositor, n + 1)
            say("== Lauf %d/%d unter %s (%s)" % (n + 1, runs, compositor, unit))
            result = one_run(compositor, dienst, keep, unit)
            say("   %d s, Compositor-Exit %s, Dienst %s" % (result["seconds"], result["compositor.exit"].strip() or "?",
                                                         result["dienst.exit"].strip() or "?"))
            if keep:
                say("   behalten: %s" % result["base"])
            if result["stubs.log"]:
                calls = sorted(set(" ".join(l.split(" ")[:3]) for l in result["stubs.log"].splitlines()))
                say("   abgefangen: " + ", ".join(calls))
                if any(" restart" in l or " stop" in l or " start" in l for l in result["stubs.log"].splitlines()):
                    say("   HINWEIS: Der Lauf wollte einen Dienst starten/stoppen (abgefangen, siehe stubs.log)")
            problems = health(result)
            if problems:
                for p in problems:
                    say("   FEHLER: " + p)
                return 2
            got = findings(result)
            say("   %d verschiedene Warnungen/Fehler" % len(got))
            union |= got
    finally:
        if tmpbin:
            shutil.rmtree(tmpbin, ignore_errors=True)
    if write:
        with open(baseline_path, "w", encoding="utf-8") as handle:
            handle.write("# Grundlinie der Ladeprüfung (%s): Warnungen und Fehler eines Laufs mit dem ausgelieferten\n"
                         "# Design, vereint über %d Läufe. Neu schreiben: ladepruefung.py %s --grundlinie\n" % (compositor, runs, compositor))
            for line in sorted(union):
                handle.write(line + "\n")
        say("Grundlinie geschrieben: %s (%d Einträge)" % (os.path.relpath(baseline_path, REPO), len(union)))
        return 0
    if not os.path.exists(baseline_path):
        say("keine Grundlinie – zuerst: ladepruefung.py %s --grundlinie" % compositor)
        return 2
    baseline = {l.rstrip("\n") for l in open(baseline_path, encoding="utf-8") if l.strip() and not l.startswith("#")}
    new = sorted(union - baseline)
    gone = sorted(baseline - union)
    say("== Vergleich mit %s" % os.path.relpath(baseline_path, REPO))
    say("   gleich: %d   neu: %d   nicht mehr da: %d" % (len(union & baseline), len(new), len(gone)))
    for line in new:
        say("   NEU   " + line)
    for line in gone:
        say("   WEG   " + line)
    return 1 if new else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
