#!/usr/bin/env python3
"""Alpe – Helfer für die KWin-Seiten der Einstellungen.

    alpe-kwin.py state                       Regeln, Effekte, Platzierung, Animation als JSON
    alpe-kwin.py rule-set JSON               Fensterregel anlegen/ändern (id leer: neu)
    alpe-kwin.py rule-delete ID              Fensterregel löschen
    alpe-kwin.py migrate                     kwinrulesrc ins Format von KWin 6.8 bringen (Order statt rules)
    alpe-kwin.py apply JSON                  [[datei, gruppe, schlüssel, wert], …] schreiben
                                             (wert null: löschen), danach KWin neu einlesen lassen
    alpe-kwin.py effect ID on|off            Effekt laden/entladen und dauerhaft (de)aktivieren
    alpe-kwin.py shortcuts                   alle globalen Tastenkürzel als JSON
    alpe-kwin.py shortcut-set JSON           {"component","action","componentName","actionName","keys":[int…]}
    alpe-kwin.py shortcut-new JSON           {"kind":"app","id":"kitty.desktop","name"} oder {"kind":"command","name","command"}, "keys":[int…]
    alpe-kwin.py shortcut-remove JSON        {"component","action"}: Kürzel weg; eigener Befehl samt Datei
    alpe-kwin.py apps                        startbare Programme (Desktop-Dateien) als JSON
    alpe-kwin.py block on|off                globale Kürzel anhalten (während eine Taste aufgenommen wird)
    alpe-kwin.py pick                        Fenster anklicken lassen (Fadenkreuz), Angaben als JSON
    alpe-kwin.py services                    systemd-Benutzerdienste als JSON
    alpe-kwin.py service AKTION UNIT         start|stop|restart|enable|disable (nur --user)

Gelesen wird direkt aus den Dateien in ~/.config, geschrieben nur über kwriteconfig6 (mit
--notify), damit KDE dieselbe Schreibweise und Sperre verwendet wie seine eigenen Dialoge. Die
Tastenkürzel laufen über kglobalaccel (D-Bus, busctl), das sie selbst speichert und KWin meldet.
"""
import json
import os
import re
import subprocess
import sys
import uuid

CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(os.path.expanduser("~"), ".config")
KWRITE = os.environ.get("ALPE_KWRITECONFIG", "kwriteconfig6")
BUSCTL = os.environ.get("ALPE_BUSCTL", "busctl")
SYSTEMCTL = os.environ.get("ALPE_SYSTEMCTL", "systemctl")

BLUR = "Effect-better-blur-dx"
CORNERS = "Round-Corners"
EFFECT_IDS = {"blur": "better_blur_dx", "corners": "kwin4_effect_shapecorners", "kwinblur": "blur"}

# KWin-Regeln: Werte der *rule-Schlüssel (Rules::Type)
UNUSED, DONT_AFFECT, FORCE, APPLY, REMEMBER = 0, 1, 2, 3, 4


# ---------------------------------------------------------------- KConfig lesen

def unescape(value):
    out, i = [], 0
    while i < len(value):
        c = value[i]
        if c == "\\" and i + 1 < len(value):
            n = value[i + 1]
            out.append({"s": " ", "n": "\n", "t": "\t", "r": "\r", "\\": "\\", ";": ";", ",": ","}.get(n, "\\" + n))
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def read_kconfig(name):
    """{"Gruppe" bzw. "A/B" für [A][B]: {schlüssel: wert}} in Dateireihenfolge."""
    groups = {}
    current = None
    path = os.path.join(CONFIG, name)
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            lines = handle.read().splitlines()
    except FileNotFoundError:
        return groups
    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("["):
            names = re.findall(r"\[([^\]]*)\]", line)
            # [$Version] und ähnliche Markierungen sind keine Gruppen
            names = [n for n in names if not n.startswith("$")]
            current = "/".join(names) if names else None
            if current is not None:
                groups.setdefault(current, {})
            continue
        if current is None or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = re.sub(r"\[\$[a-z]+\]$", "", key.strip())
        groups[current][key] = unescape(value.strip())
    return groups


def kwrite(file, group, key, value):
    cmd = [KWRITE, "--notify", "--file", file]
    for part in str(group).split("/"):
        cmd += ["--group", part]
    cmd += ["--key", key]
    if value is None:
        cmd.append("--delete")
    else:
        if isinstance(value, bool):
            value = "true" if value else "false"
        cmd.append(str(value))
    try:
        subprocess.run(cmd, check=False)
    except FileNotFoundError:
        sys.exit("%s fehlt – KDE-Einstellungen lassen sich nicht schreiben." % KWRITE)


def busctl(*args, json_out=False):
    cmd = [BUSCTL, "--user"] + (["--json=short"] if json_out else []) + list(args)
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if json_out:
        try:
            return json.loads(result.stdout)
        except ValueError:
            return None
    return result.returncode == 0


def reconfigure():
    busctl("call", "org.kde.KWin", "/KWin", "org.kde.KWin", "reconfigure")
    for effect in (EFFECT_IDS["blur"], EFFECT_IDS["corners"]):
        busctl("call", "org.kde.KWin", "/Effects", "org.kde.kwin.Effects", "reconfigureEffect", "s", effect)


def effect_loaded(effect):
    data = busctl("call", "org.kde.KWin", "/Effects", "org.kde.kwin.Effects", "isEffectLoaded", "s", effect, json_out=True)
    try:
        return bool(data["data"][0])
    except (TypeError, KeyError, IndexError):
        return None


def effect_present(effect):
    for base in ("/usr/lib/qt6/plugins/kwin/effects/plugins", "/usr/lib64/qt6/plugins/kwin/effects/plugins",
                 "/usr/lib/x86_64-linux-gnu/qt6/plugins/kwin/effects/plugins"):
        if os.path.exists(os.path.join(base, effect + ".so")):
            return True
    return False


# ---------------------------------------------------------------- Fensterregeln

RULE_FIELDS = ("Description", "wmclass", "wmclassmatch", "wmclasscomplete", "title", "titlematch", "types",
               "opacityactive", "opacityactiverule", "opacityinactive", "opacityinactiverule",
               "noborder", "noborderrule", "position", "positionrule", "size", "sizerule",
               "above", "aboverule", "placement", "placementrule", "decorationpolicy", "decorationpolicyrule")

# Alpe: KWin 6.8 (ab 6.7.90) hat das Format der kwinrulesrc geändert (Commits «Add support for
# cascaded window rules» und «Replace no border window rule with a tristate window rule»):
# - Jede Gruppe ist eine Regel; die Reihenfolge steht in [General] Order. «rules» und «count» sind
#   veraltet. Steht beim Einlesen noch eine Liste «rules» da, LÖSCHT KWin jede Gruppe, die nicht
#   darin steht. Alpe schrieb früher bei jeder neuen Regel «rules=<nur diese>» – so verschwanden
#   alle anderen Regeln (ohne Titelleiste, Deckkraft von Zed …), spätestens beim Neustart.
# - «Ohne Titelleiste» heisst jetzt decorationpolicy=none|server|client-preference|shadow mit
#   decorationpolicyrule; noborder/noborderrule migriert KWin beim Lesen und entfernt sie.
NEW_FORMAT = (6, 7, 90)
_kwin_version = False


def kwin_version():
    """(6, 8, 3) aus «kwin_wayland --version»; ALPE_KWIN_VERSION überschreibt (Tests), leer = unbekannt."""
    global _kwin_version
    if _kwin_version is not False:
        return _kwin_version
    text = os.environ.get("ALPE_KWIN_VERSION")
    if text is None:
        text = ""
        for exe in ("kwin_wayland", "kwin_x11"):
            try:
                out = subprocess.run([exe, "--version"], capture_output=True, text=True, timeout=5, check=False)
                text = out.stdout + out.stderr
                if text.strip():
                    break
            except (OSError, subprocess.SubprocessError):
                continue
    match = re.search(r"(\d+)\.(\d+)\.(\d+)", text)
    _kwin_version = tuple(int(x) for x in match.groups()) if match else None
    return _kwin_version


def new_format(rc):
    general = rc.get("General", {})
    if "Order" in general:
        return True
    version = kwin_version()
    if version is not None:
        return version >= NEW_FORMAT
    # Unbekannte Version: ohne alte Liste das neue Format (ein «Order» übersieht ein altes KWin nur,
    # eine Liste «rules» kostet ein neues KWin alle übrigen Regeln).
    return "rules" not in general and "count" not in general


def rule_groups(rc):
    return [g for g in rc if g != "General" and not g.startswith("$")]


def rule_order(rc):
    """Kennungen der Regeln in KWins Reihenfolge.

    KWin 6.8: Order, Gruppen ohne Eintrag stellt KWin voran (jede Gruppe ist eine Regel).
    Ältere Dateien (von KDEs Einstellungsmodul vor Plasma 5.20) haben keine Liste «rules», nur
    «count» und Gruppen [1] … [n]; die liest KWin bis 6.7 weiterhin. Alpe: Bis dahin hätte
    eine neue Regel hier die Liste mit nur sich selbst angelegt."""
    general = rc.get("General", {})
    if new_format(rc):
        order = [r for r in general.get("Order", "").split(",") if r and r in rc]
        return [g for g in rule_groups(rc) if g not in order] + order
    if "rules" in general:
        return [r for r in general["rules"].split(",") if r]
    try:
        count = int(general.get("count", "0") or 0)
    except ValueError:
        count = 0
    return [str(i) for i in range(1, count + 1) if str(i) in rc]


def write_order(rc, order):
    if new_format(rc):
        kwrite("kwinrulesrc", "General", "Order", ",".join(order) if order else None)
    else:
        kwrite("kwinrulesrc", "General", "rules", ",".join(order) if order else None)
        kwrite("kwinrulesrc", "General", "count", len(order))


def migrate():
    """Alte Liste «rules»/«count» unter KWin 6.8 durch «Order» mit allen Regeln ersetzen, bevor KWin
    sie liest und die nicht aufgeführten Gruppen löscht. Zuerst «rules» auf alle Gruppen setzen
    (liest KWin dazwischen, geht so nichts verloren), dann Order schreiben, dann die alten Schlüssel
    entfernen. Gibt zurück, ob etwas zu tun war."""
    rc = read_kconfig("kwinrulesrc")
    general = rc.get("General", {})
    if not new_format(rc) or ("rules" not in general and "count" not in general):
        return False
    order = rule_order(rc)
    if order:
        kwrite("kwinrulesrc", "General", "rules", ",".join(order))
        kwrite("kwinrulesrc", "General", "Order", ",".join(order))
    kwrite("kwinrulesrc", "General", "rules", None)
    kwrite("kwinrulesrc", "General", "count", None)
    return True


def border_values(values):
    """noborder/noborderrule der Seiten in KWins neue Schlüssel übersetzen (KWin 6.8)."""
    out = dict(values)
    if "noborder" in out:
        flag = out.pop("noborder")
        out["decorationpolicy"] = None if flag is None else ("none" if flag in (True, "true", 1, "1") else "server")
        out["noborder"] = None
    if "noborderrule" in out:
        out["decorationpolicyrule"] = out.pop("noborderrule")
        out["noborderrule"] = None
    return out


def border_of(group):
    """(versteckt?, Regeltyp) aus altem oder neuem Schlüssel"""
    rule = group.get("decorationpolicyrule") or group.get("noborderrule") or "0"
    if group.get("decorationpolicyrule"):
        return group.get("decorationpolicy", "client-preference") == "none", rule
    return group.get("noborder") == "true", rule


def rule_list():
    rc = read_kconfig("kwinrulesrc")
    order = rule_order(rc)
    # Gruppen ohne Eintrag in der Liste liest KWin nicht; sie bleiben aussen vor.
    rules = []
    for rid in order:
        group = rc.get(rid)
        if group is None:
            continue
        rule = {"id": rid}
        for field in RULE_FIELDS:
            if field in group:
                rule[field] = group[field]
        # Die Seiten kennen «noborder»; KWin 6.8 speichert decorationpolicy.
        if group.get("decorationpolicyrule"):
            hidden, kind = border_of(group)
            rule["noborder"] = "true" if hidden else "false"
            rule["noborderrule"] = kind
        rule["other"] = sorted(k for k in group if k not in RULE_FIELDS)
        rules.append(rule)
    return rules


def blur_classes():
    value = read_kconfig("kwinrc").get(BLUR, {}).get("WindowClasses", "")
    return [c.strip() for c in value.split("\n") if c.strip()]


def set_blur_class(name, wanted, old_name=""):
    classes = blur_classes()
    for drop in {name or "", old_name or ""} - {""}:
        classes = [c for c in classes if c.lower() != drop.lower()]
    if wanted and name:
        classes.append(name)
    kwrite("kwinrc", BLUR, "WindowClasses", "\n".join(classes) if classes else None)


def rule_set(data):
    migrate()
    rc = read_kconfig("kwinrulesrc")
    order = rule_order(rc)
    rid = data.get("id") or str(uuid.uuid4())
    old = rc.get(rid, {})
    values = data.get("values", {})
    written = border_values(values) if new_format(rc) else values
    for key, value in written.items():
        if key not in RULE_FIELDS:
            continue
        if value is None and key not in old:
            continue
        kwrite("kwinrulesrc", rid, key, value)
    if rid not in order:
        order.append(rid)
        write_order(rc, order)
    # Weichzeichnen gehört zu Better Blur DX, nicht zu KWins Regeln: Fensterklasse in die Liste.
    if "blur" in data:
        wmclass = values.get("wmclass", old.get("wmclass", "")) or ""
        set_blur_class(wmclass, bool(data["blur"]), old.get("wmclass", "") or "")
    reconfigure()
    return rid


def rule_delete(rid):
    migrate()
    rc = read_kconfig("kwinrulesrc")
    order = [r for r in rule_order(rc) if r != rid]
    for key in rc.get(rid, {}):
        kwrite("kwinrulesrc", rid, key, None)
    write_order(rc, order)
    reconfigure()


# ---------------------------------------------------------------- Zustand

def state():
    kwinrc = read_kconfig("kwinrc")
    plugins = kwinrc.get("Plugins", {})
    globals_ = read_kconfig("kdeglobals")
    effects = {}
    for name, effect in EFFECT_IDS.items():
        enabled = plugins.get(effect + "Enabled")
        effects[name] = {
            "id": effect,
            "installed": effect_present(effect) if name != "kwinblur" else True,
            "enabled": None if enabled is None else enabled == "true",
            "loaded": effect_loaded(effect),
        }
    return {
        "rules": rule_list(),
        "blurClasses": blur_classes(),
        "blur": kwinrc.get(BLUR, {}),
        "corners": kwinrc.get(CORNERS, {}),
        "effects": effects,
        "placement": kwinrc.get("Windows", {}).get("Placement", "Centered"),
        "animation": globals_.get("KDE", {}).get("AnimationDurationFactor", "1"),
        "focusPolicy": kwinrc.get("Windows", {}).get("FocusPolicy", "ClickToFocus"),
    }


def apply(entries):
    for file, group, key, value in entries:
        if file not in ("kwinrc", "kdeglobals", "kwinrulesrc"):
            continue
        kwrite(file, group, key, value)
    reconfigure()


def effect_toggle(effect, on):
    known = set(EFFECT_IDS.values())
    if effect not in known:
        sys.exit("unbekannter Effekt")
    kwrite("kwinrc", "Plugins", effect + "Enabled", bool(on))
    busctl("call", "org.kde.KWin", "/Effects", "org.kde.kwin.Effects", "loadEffect" if on else "unloadEffect", "s", effect)
    # KWins eigene Unschärfe und Better Blur DX schliessen einander aus.
    if on and effect == EFFECT_IDS["blur"]:
        kwrite("kwinrc", "Plugins", "blurEnabled", False)
        busctl("call", "org.kde.KWin", "/Effects", "org.kde.kwin.Effects", "unloadEffect", "s", "blur")


# ---------------------------------------------------------------- Tastenkürzel

APPLICATIONS = os.path.join(os.environ.get("XDG_DATA_HOME") or os.path.join(os.path.expanduser("~"), ".local", "share"), "applications")
CUSTOM_PREFIX = "net.local."


def combos(value):
    """Tastenkombinationen als Zahlen. kglobalaccel liefert QKeySequence als (ai) – je nach busctl
    als Zahl oder als verschachtelte Liste [[k1, k2, k3, k4]]; gezählt wird die erste Taste."""
    out = []
    for item in value or []:
        while isinstance(item, list) and len(item) == 1 and isinstance(item[0], list):
            item = item[0]
        if isinstance(item, list):
            item = item[0] if item else 0
        try:
            item = int(item)
        except (TypeError, ValueError):
            continue
        if item:
            out.append(item)
    return out


def desktop_entry(path):
    """Gruppe [Desktop Entry] einer Desktop-Datei; Name in der Landessprache, wenn vorhanden."""
    entry, inside = {}, False
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            for raw in handle:
                line = raw.strip()
                if line.startswith("["):
                    inside = line == "[Desktop Entry]"
                    continue
                if inside and "=" in line and not line.startswith("#"):
                    key, value = line.split("=", 1)
                    entry.setdefault(key.strip(), value.strip())
    except OSError:
        return {}
    lang = (os.environ.get("LC_MESSAGES") or os.environ.get("LANG") or "").split(".")[0]
    for key in ("Name[%s]" % lang, "Name[%s]" % lang.split("_")[0]):
        if lang and entry.get(key):
            entry["Name"] = entry[key]
            break
    return entry


def application_dirs():
    data = os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
    dirs = [APPLICATIONS] + [os.path.join(d, "applications") for d in data.split(":") if d]
    seen, out = set(), []
    for d in dirs:
        if d not in seen and os.path.isdir(d):
            seen.add(d)
            out.append(d)
    return out


def apps():
    """Startbare Programme: erste Desktop-Datei je ID gewinnt (eigene vor Systemdateien), ohne
    versteckte und ohne die eigenen Befehle (die stehen in der Kürzelliste)."""
    found = {}
    for base in application_dirs():
        for folder, _dirs, files in os.walk(base):
            for name in files:
                if not name.endswith(".desktop"):
                    continue
                path = os.path.join(folder, name)
                # Unterordner gehören nach der Spezifikation mit «-» zur ID (kde/foo.desktop → kde-foo.desktop)
                did = os.path.relpath(path, base).replace(os.sep, "-")
                if did in found:
                    continue
                entry = desktop_entry(path)
                found[did] = entry
    out = []
    for did, entry in found.items():
        if did.startswith(CUSTOM_PREFIX) or not entry.get("Name") or not entry.get("Exec"):
            continue
        if entry.get("Type", "Application") != "Application":
            continue
        if entry.get("NoDisplay") == "true" or entry.get("Hidden") == "true":
            continue
        out.append({"id": did, "name": entry["Name"]})
    # Gleiche Namen unterscheidbar machen (etwa zwei Firefox-Einträge)
    names = {}
    for app in out:
        names[app["name"]] = names.get(app["name"], 0) + 1
    for app in out:
        if names[app["name"]] > 1:
            app["name"] = "%s (%s)" % (app["name"], app["id"][:-8])
    out.sort(key=lambda a: a["name"].lower())
    return {"apps": out}


def custom_path(component):
    return os.path.join(APPLICATIONS, component)


def shortcuts():
    data = busctl("call", "org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel", "allMainComponents", json_out=True)
    components = []
    try:
        main = data["data"][0]
    except (TypeError, KeyError, IndexError):
        return {"available": False, "components": []}
    seen = set()
    for entry in main:
        unique = entry[0] if entry else ""
        if not unique or unique in seen:
            continue
        seen.add(unique)
        path = busctl("call", "org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel", "getComponent", "s", unique, json_out=True)
        try:
            opath = path["data"][0]
        except (TypeError, KeyError, IndexError):
            continue
        infos = busctl("call", "org.kde.kglobalaccel", opath, "org.kde.kglobalaccel.Component", "allShortcutInfos", json_out=True)
        try:
            rows = infos["data"][0]
        except (TypeError, KeyError, IndexError):
            continue
        actions = []
        friendly = unique
        for row in rows:
            # (uniqueName, friendlyName, componentUnique, componentFriendly, contextUnique, contextFriendly, keys, defaultKeys)
            friendly = row[3] or friendly
            actions.append({"action": row[0], "name": row[1] or row[0], "keys": combos(row[6]), "defaults": combos(row[7])})
        actions.sort(key=lambda a: (a["action"] != "_launch", a["name"].lower()))
        item = {"component": unique, "name": friendly, "actions": actions}
        # Alpe: Programme (Komponente = Desktop-Datei) und eigene Befehle kennzeichnen
        if unique.endswith(".desktop"):
            item["launch"] = True
            if unique.startswith(CUSTOM_PREFIX):
                item["custom"] = True
                entry = desktop_entry(custom_path(unique))
                item["name"] = entry.get("Name") or friendly
                item["command"] = entry.get("Exec", "")
        components.append(item)

    def order(c):
        rank = 0 if c["component"] == "kwin" else 1 if c["component"] == "dms" else 2 if c.get("custom") else 3 if c.get("launch") else 4
        return (rank, c["name"].lower())
    components.sort(key=order)
    return {"available": True, "components": components}


def set_keys(component, action, component_name, action_name, keys):
    ident = [component, action, component_name or component, action_name or action]
    keys = [int(k) for k in keys if int(k) != 0]
    args = ["call", "org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel", "setForeignShortcutKeys", "asa(ai)", "4"] + ident
    args.append(str(len(keys)))
    for key in keys:
        args += ["4", str(key), "0", "0", "0"]
    return busctl(*args)


def shortcut_set(data):
    return set_keys(data["component"], data["action"], data.get("componentName"), data.get("actionName"), data.get("keys", []))


def slug(name):
    text = name.lower()
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")):
        text = text.replace(a, b)
    text = re.sub(r"[^a-z0-9]+", "-", text).strip("-")
    return text or "befehl"


def write_command(name, command):
    """Desktop-Datei wie KDEs «Neuer Befehl»: net.local.<name>.desktop in ~/.local/share/applications,
    unsichtbar im Menü; kglobalaccel startet sie über die Aktion «_launch»."""
    os.makedirs(APPLICATIONS, exist_ok=True)
    base = CUSTOM_PREFIX + slug(name)
    component, n = base + ".desktop", 2
    while os.path.exists(custom_path(component)):
        component = "%s-%d.desktop" % (base, n)
        n += 1
    clean = lambda v: " ".join(str(v).split())
    with open(custom_path(component), "w", encoding="utf-8") as handle:
        handle.write("[Desktop Entry]\n")
        handle.write("Type=Application\n")
        handle.write("Name=%s\n" % clean(name))
        handle.write("Exec=%s\n" % clean(command))
        handle.write("NoDisplay=true\n")
        handle.write("StartupNotify=false\n")
        handle.write("X-KDE-GlobalAccel-CommandShortcut=true\n")
    return component


def shortcut_new(data):
    keys = data.get("keys", [])
    name = (data.get("name") or "").strip()
    if data.get("kind") == "command":
        command = (data.get("command") or "").strip()
        if not name or not command:
            return {"ok": False, "error": "Name und Befehl fehlen"}
        component = write_command(name, command)
    else:
        component = data.get("id") or ""
        if not component.endswith(".desktop") or "/" in component:
            return {"ok": False, "error": "unbekanntes Programm"}
    # doRegister legt für eine Desktop-Datei die Komponente an (liest Exec und Aktionen selbst),
    # setForeignShortcutKeys gibt «_launch» die Taste und meldet sie KWin.
    ident = [component, "_launch", name or component, name or component]
    busctl("call", "org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel", "doRegister", "as", "4", *ident)
    ok = set_keys(component, "_launch", ident[2], ident[3], keys)
    return {"ok": bool(ok), "component": component, "error": "" if ok else "kglobalaccel lehnt ab"}


def shortcut_remove(data):
    component, action = data.get("component", ""), data.get("action", "_launch")
    set_keys(component, action, component, action, [])
    if component.endswith(".desktop"):
        busctl("call", "org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel", "unregister", "ss", component, action)
    # Nur eigene Befehle (net.local.*) samt Datei löschen, nie Desktop-Dateien von Programmen.
    removed = False
    if component.startswith(CUSTOM_PREFIX) and component.endswith(".desktop") and "/" not in component:
        try:
            os.remove(custom_path(component))
            removed = True
        except FileNotFoundError:
            pass
    return {"ok": True, "removed": removed}


# ---------------------------------------------------------------- Fenster anklicken

def pick():
    """KWin zeigt ein Fadenkreuz; das angeklickte Fenster liefert Klasse, Titel usw."""
    data = busctl("--timeout=120", "call", "org.kde.KWin", "/KWin", "org.kde.KWin", "queryWindowInfo", json_out=True)
    try:
        info = data["data"][0]
    except (TypeError, KeyError, IndexError):
        return {}
    out = {}
    for key in ("resourceClass", "resourceName", "desktopFile", "caption", "role", "type"):
        value = info.get(key)
        if isinstance(value, dict):
            out[key] = value.get("data")
    return out


# ---------------------------------------------------------------- Dienste

SERVICE_PROPS = ["Id", "Description", "ActiveState", "SubState", "UnitFileState", "FragmentPath", "DropInPaths", "ActiveEnterTimestamp", "MainPID"]


def systemctl(*args):
    return subprocess.run([SYSTEMCTL, "--user", "--no-pager"] + list(args), capture_output=True, text=True, check=False)


def services():
    names = set()
    for line in systemctl("list-units", "--type=service", "--all", "--plain", "--no-legend").stdout.splitlines():
        if line.split():
            names.add(line.split()[0])
    for line in systemctl("list-unit-files", "--type=service", "--no-legend").stdout.splitlines():
        parts = line.split()
        # Vorlagen (name@.service) lassen sich so nicht starten
        if parts and "@." not in parts[0]:
            names.add(parts[0])
    names = sorted(n for n in names if n.endswith(".service") and "@." not in n)
    if not names:
        return {"available": False, "services": []}
    out = systemctl("show", "-p", ",".join(SERVICE_PROPS), *names).stdout
    home = os.path.expanduser("~")
    result = []
    for block in out.split("\n\n"):
        item = {}
        for line in block.splitlines():
            if "=" in line:
                key, value = line.split("=", 1)
                item[key] = value
        if not item.get("Id"):
            continue
        fragment = item.get("FragmentPath", "")
        item["own"] = fragment.startswith(os.path.join(home, ".config", "systemd", "user"))
        item["dropins"] = [p for p in item.get("DropInPaths", "").split() if p]
        result.append(item)
    return {"available": True, "services": result}


def service(action, unit):
    if action not in ("start", "stop", "restart", "enable", "disable") or not re.fullmatch(r"[\w@.:-]+\.service", unit):
        sys.exit("ungültig")
    args = [action, unit]
    if action in ("enable", "disable"):
        args.insert(1, "--now")
    result = systemctl(*args)
    return {"ok": result.returncode == 0, "error": result.stderr.strip()}


# ---------------------------------------------------------------- Aufruf

def main(argv):
    if len(argv) < 2:
        sys.exit(__doc__)
    cmd = argv[1]
    if cmd == "state":
        print(json.dumps(state(), ensure_ascii=False))
    elif cmd == "rule-set":
        print(json.dumps({"id": rule_set(json.loads(argv[2]))}))
    elif cmd == "migrate":
        changed = migrate()
        if changed:
            reconfigure()
        print(json.dumps({"migrated": changed, "kwin": ".".join(map(str, kwin_version() or ())) or None}))
    elif cmd == "rule-delete":
        rule_delete(argv[2])
        print("{}")
    elif cmd == "apply":
        apply(json.loads(argv[2]))
        print("{}")
    elif cmd == "effect":
        effect_toggle(argv[2], argv[3] == "on")
        print("{}")
    elif cmd == "shortcuts":
        print(json.dumps(shortcuts(), ensure_ascii=False))
    elif cmd == "shortcut-set":
        print(json.dumps({"ok": shortcut_set(json.loads(argv[2]))}))
    elif cmd == "shortcut-new":
        print(json.dumps(shortcut_new(json.loads(argv[2])), ensure_ascii=False))
    elif cmd == "shortcut-remove":
        print(json.dumps(shortcut_remove(json.loads(argv[2]))))
    elif cmd == "apps":
        print(json.dumps(apps(), ensure_ascii=False))
    elif cmd == "block":
        busctl("call", "org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel", "blockGlobalShortcuts", "b", "true" if argv[2] == "on" else "false")
        print("{}")
    elif cmd == "pick":
        print(json.dumps(pick(), ensure_ascii=False))
    elif cmd == "services":
        print(json.dumps(services(), ensure_ascii=False))
    elif cmd == "service":
        print(json.dumps(service(argv[2], argv[3]), ensure_ascii=False))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
