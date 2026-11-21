#!/usr/bin/env python3
"""Fenster ohne Titelleiste – als dauerhafte KWin-Regel für alle Fenster.

    titelleisten.py [status|aus|an]

  status  zeigt, welche Regeln in ~/.config/kwinrulesrc die Titelleiste betreffen, und ob eine
          davon für alle Fenster gilt
  aus     legt die Regel «Alpe: ohne Titelleiste» an (falls keine andere für alle Fenster da ist):
          alle Fenster ohne Titelleiste und Rahmen; gezogen wird an der Griffleiste von Alpe.
          Wirkt sofort, auch auf offene Fenster
  an      entfernt diese Regel wieder (die Titelleisten von KWin kommen zurück)

Das Häkchen «Ohne Titelleiste und Rahmen» im Fenstermenü gilt nur für das eine Fenster, bis es
geschlossen wird. Die Regel nutzt «Erzwingen» – so schaltet kein Programm die Leiste wieder ein.
Programme mit eigener Titelleiste (Nautilus, Electron-Programme wie WordCraft) betrifft sie nicht.
"""
import importlib.util
import os
import sys

SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "shell")
RULE_NAME = "Alpe: ohne Titelleiste"
MATCHES = ("wmclassmatch", "titlematch", "windowrolematch", "clientmachinematch")


def kwin():
    path = os.path.join(SHELL, "scripts", "alpe-kwin.py")
    spec = importlib.util.spec_from_file_location("alpe_kwin", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def border_rules(k):
    rc = k.read_kconfig("kwinrulesrc")
    order = k.rule_order(rc)
    found = []
    for rid in order:
        group = rc.get(rid) or {}
        # Alpe: KWin 6.8 speichert decorationpolicy(rule) statt noborder(rule)
        hide, policy = k.border_of(group)
        if policy in ("", "0", "1"):
            continue
        everyone = all(group.get(m, "0") in ("", "0") for m in MATCHES)
        found.append({"id": rid, "name": group.get("Description", rid), "hide": hide,
                      "policy": policy, "all": everyone, "class": group.get("wmclass", "")})
    # Gruppen mit Titelleisten-Einstellung, die KWin nicht liest (fehlen in General/rules; ab KWin 6.8
    # liest KWin jede Gruppe, dann gibt es keine verwaisten)
    orphans = [{"id": g, "name": v.get("Description", g), "hide": k.border_of(v)[0],
                "all": all(v.get(m, "0") in ("", "0") for m in MATCHES)}
               for g, v in rc.items() if g not in order and g != "General"
               and ("noborderrule" in v or "decorationpolicyrule" in v)]
    return found, orphans, order


POLICY = {"2": "erzwingen", "3": "anfangs", "4": "merken", "5": "sofort", "6": "vorübergehend erzwingen"}


def main(mode):
    k = kwin()
    if mode != "status" and k.migrate():
        print("kwinrulesrc ins Format von KWin 6.8 gebracht (Order statt rules).")
    rules, orphans, order = border_rules(k)
    if mode == "status":
        if not rules:
            print("Keine KWin-Regel zur Titelleiste: Fenster bekommen die Titelleiste von KWin.")
        for r in rules:
            print("%s  %s  (%s)%s" % ("ohne Titelleiste" if r["hide"] else "mit Titelleiste", r["name"],
                                      POLICY.get(r["policy"], r["policy"]),
                                      "  – für alle Fenster" if r["all"] else "  – nur " + (r["class"] or "bestimmte Fenster")))
        for g in orphans:
            print("verwaist: «%s» [%s] steht in kwinrulesrc, fehlt aber in der Liste [General] rules –"
                  " KWin liest sie nicht. «alpe titelleisten aus» hängt sie wieder ein." % (g["name"], g["id"]))
        return 0
    ours = [r for r in rules if r["name"] == RULE_NAME]
    if mode == "an":
        for r in ours:
            k.rule_delete(r["id"])
        print("Regel «%s» entfernt." % RULE_NAME if ours else "Keine Regel von Alpe vorhanden.")
        return 0
    if any(r["all"] and r["hide"] for r in rules):
        print("Schon eingerichtet: %s" % next(r["name"] for r in rules if r["all"] and r["hide"]))
        return 0
    lost = next((g for g in orphans if g["hide"] and g["all"]), None)
    if lost:
        # Die eigene alte Regel wieder einhängen statt eine neue anzulegen
        order = order + [lost["id"]]
        k.write_order(k.read_kconfig("kwinrulesrc"), order)
        k.reconfigure()
        print("Regel «%s» wieder eingehängt (war verwaist): alle Fenster ohne Titelleiste." % lost["name"])
        return 0
    k.rule_set({"id": ours[0]["id"] if ours else None, "values": {
        "Description": RULE_NAME, "noborder": True, "noborderrule": 2, "types": 33}})   # normale Fenster und Dialoge
    print("Regel «%s» angelegt: alle Fenster ohne Titelleiste und Rahmen (sofort wirksam)." % RULE_NAME)
    return 0


if __name__ == "__main__":
    choice = (sys.argv[1] if len(sys.argv) > 1 else "status").lower()
    if choice not in ("status", "aus", "an"):
        print(__doc__.strip())
        sys.exit(2)
    sys.exit(main(choice))
