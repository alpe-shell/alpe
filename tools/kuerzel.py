#!/usr/bin/env python3
"""Alpe-Tastenkürzel unter KDE (kglobalaccel): die Vorgaben von Alpe setzen.

    kuerzel.py status      zeigt, wie die Vorgaben gerade belegt sind
    kuerzel.py vorgaben    setzt sie; wer die Taste bisher hatte, verliert nur diese Taste
    kuerzel.py zurueck     nimmt die Tasten der Vorgaben wieder weg (für «alpe entfernen»)

Vorgaben:
  Meta+Q   Fenster schliessen (KWin, zusätzlich zu Alt+F4)
  Meta+M   Alpe-Systemmonitor (Aktion «dms-processlist» des KWin-Skripts der Shell)

Das KWin-Skript meldet seine Aktionen erst an, wenn die Shell läuft. Fehlt eine Aktion noch,
wartet «vorgaben» bis zu --warten Sekunden (Vorgabe 15) und meldet sonst, was offen blieb.
"""
import importlib.util
import os
import sys
import time

SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.expanduser("~"), "dux-shell")

# (Komponente, Aktion, Tasten) – die Tasten kommen zu den vorhandenen dazu
VORGABEN = [
    ("kwin", "Window Close", ["Meta+Q"]),
    ("kwin", "dms-processlist", ["Meta+M"]),
]

MODS = {"meta": 0x10000000, "ctrl": 0x04000000, "alt": 0x08000000, "shift": 0x02000000}
NAMED = {"space": 0x20, "comma": 0x2C, ",": 0x2C, "return": 0x01000004, "enter": 0x01000005,
         "esc": 0x01000000, "escape": 0x01000000, "tab": 0x01000001, "print": 0x01000009}


def key_code(text):
    """«Meta+Q» → Qt-Tastencode (Modifikatoren | Taste)."""
    *mods, key = text.split("+") if text != "+" else ["+"]
    code = 0
    for mod in mods:
        code |= MODS[mod.strip().lower()]
    low = key.strip().lower()
    if low in NAMED:
        return code | NAMED[low]
    if len(low) > 1 and low[0] == "f" and low[1:].isdigit():
        return code | (0x01000030 + int(low[1:]) - 1)
    if len(key.strip()) == 1:
        return code | ord(key.strip().upper())
    raise ValueError("unbekannte Taste: %s" % text)


def key_text(code):
    parts = [name.capitalize() for name, bit in (("meta", MODS["meta"]), ("ctrl", MODS["ctrl"]),
                                                  ("alt", MODS["alt"]), ("shift", MODS["shift"])) if code & bit]
    key = code & 0x01FFFFFF
    if 0x01000030 <= key <= 0x01000052:
        name = "F%d" % (key - 0x01000030 + 1)
    else:
        name = next((n.capitalize() for n, c in NAMED.items() if c == key and len(n) > 1), None) or (chr(key) if key < 0x110000 else hex(key))
    return "+".join(parts + [name])


def kwin():
    path = os.path.join(SHELL, "quickshell", "scripts", "alpe-kwin.py")
    spec = importlib.util.spec_from_file_location("alpe_kwin", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def table(k):
    """{(Komponente, Aktion): {"keys": [...], "name": ..., "cname": ...}}"""
    data = k.shortcuts()
    out = {}
    for comp in data.get("components", []):
        for act in comp.get("actions", []):
            out[(comp["component"], act["action"])] = {"keys": act["keys"], "name": act["name"], "cname": comp["name"]}
    return out, bool(data.get("available"))


def status(k):
    rows, available = table(k)
    if not available:
        print("kglobalaccel nicht erreichbar (keine KDE-Sitzung?)")
        return 1
    for comp, action, keys in VORGABEN:
        row = rows.get((comp, action))
        if row is None:
            print("  ? %s – Aktion fehlt (läuft die Shell?)" % action)
            continue
        have = row["keys"]
        missing = [k_ for k_ in keys if key_code(k_) not in have]
        mark = "✓" if not missing else "!"
        print("  %s %-28s %s" % (mark, row["name"], ", ".join(key_text(c) for c in have) or "keine Taste"))
    return 0


def vorgaben(k, wait):
    deadline = time.time() + wait
    while True:
        rows, available = table(k)
        if not available:
            print("   Tastenkürzel: kglobalaccel nicht erreichbar – übersprungen")
            return 1
        if all((c, a) in rows for c, a, _ in VORGABEN) or time.time() >= deadline:
            break
        time.sleep(1)
    open_items = 0
    for comp, action, keys in VORGABEN:
        row = rows.get((comp, action))
        if row is None:
            print("   Tastenkürzel: «%s» noch nicht angemeldet – später: alpe kuerzel vorgaben" % action)
            open_items += 1
            continue
        wanted = [key_code(x) for x in keys]
        for code in wanted:
            if code in row["keys"]:
                continue
            # Wer die Taste schon hat, gibt nur sie ab
            for (oc, oa), other in rows.items():
                if (oc, oa) != (comp, action) and code in other["keys"]:
                    rest = [c for c in other["keys"] if c != code]
                    k.set_keys(oc, oa, other["cname"], other["name"], rest)
                    other["keys"] = rest
                    print("   %s: von «%s» (%s) übernommen" % (key_text(code), other["name"], other["cname"]))
        new = row["keys"] + [c for c in wanted if c not in row["keys"]]
        if new != row["keys"]:
            k.set_keys(comp, action, row["cname"], row["name"], new)
        print("   %s: %s" % (row["name"], ", ".join(key_text(c) for c in new)))
    return 1 if open_items else 0


def zurueck(k):
    rows, available = table(k)
    if not available:
        return 1
    for comp, action, keys in VORGABEN:
        row = rows.get((comp, action))
        if row is None:
            continue
        rest = [c for c in row["keys"] if c not in [key_code(x) for x in keys]]
        if rest != row["keys"]:
            k.set_keys(comp, action, row["cname"], row["name"], rest)
            print("   %s: %s" % (row["name"], ", ".join(key_text(c) for c in rest) or "keine Taste"))
    return 0


def main(argv):
    cmd = argv[0] if argv else "status"
    wait = 15
    if "--warten" in argv:
        wait = int(argv[argv.index("--warten") + 1])
    if cmd not in ("status", "vorgaben", "zurueck"):
        print(__doc__.strip())
        return 2
    k = kwin()
    return {"status": status, "zurueck": zurueck}.get(cmd, lambda m: vorgaben(m, wait))(k)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
