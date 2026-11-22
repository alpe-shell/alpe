#!/usr/bin/env bash
# Alpe – Hyprland von hyprlock auf den Alpe-Sperrbildschirm der Shell umstellen. WAHLWEISE:
# Ab 1.8 bleibt hyprlock die Vorgabe und wird in den Einstellungen gestaltet; dieses Werkzeug
# ist nur für den Fall, dass die Shell selbst sperren soll.
#
#   bash maclock.sh            zeigen, was geändert würde (nichts wird geschrieben)
#   bash maclock.sh apply      umstellen; jede geänderte Datei bekommt eine Sicherung *.vor-alpe
#   bash maclock.sh undo       Sicherungen zurückspielen
#
# Was geändert wird:
#   - hypridle: lock_cmd = alpe-dienst ipc call lock lock
#   - Aufrufe von hyprlock (Tastenkürzel usw.), auch «pidof hyprlock || hyprlock»: alpe-dienst ipc call lock lock
#   - Sperren beim Start (exec-once … hyprlock): Zeile auskommentiert; stattdessen sperrt die Shell
#     selbst nach der Anmeldung (Einstellung lockAtStartup in ~/.config/alpe/settings.json)
# hyprlock.conf und das Paket hyprlock bleiben unberührt; «undo» stellt alles wieder her.
# Sicherungsordner (.alpe-backups, .dms-backups) werden nie angefasst (Plan 0.8 Nr. 57).
set -euo pipefail
HYPR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/alpe/settings.json"
MODE="${1:-check}"

[ -d "$HYPR" ] || { echo "kein $HYPR – läuft hier Hyprland?"; exit 1; }

if [ "$MODE" = undo ]; then
    found=0
    while IFS= read -r -d '' backup; do
        mv -f "$backup" "${backup%.vor-alpe}"; echo "   zurück: ${backup%.vor-alpe}"; found=1
    done < <(find "$HYPR" -name '*.vor-alpe' -print0)
    [ "$found" = 1 ] || echo "   keine Sicherungen gefunden"
    echo "   lockAtStartup bleibt, wie es ist (Einstellungen → Sicherheit)."
    exit 0
fi

python3 -I - "$HYPR" "$SETTINGS" "$MODE" <<'PY'
import json, os, re, sys

hypr, settings, mode = sys.argv[1:4]
LOCK = "alpe-dienst ipc call lock lock"
# Sicherungen bleiben, wie sie sind: Ordner des Dienstes (auch der aus 1.0) werden übersprungen.
BACKUP_DIRS = {".alpe-backups", ".dms-backups"}
# hyprlock als Befehl, nicht hyprlock.conf, hyprlock-Pfade oder -Optionen anderer Programme
TOKEN = re.compile(r"(?<![\w./-])hyprlock(?:\s+--immediate(?:-render)?)?(?![\w.-])")
PIDOF = re.compile(r"pidof\s+hyprlock\s*\|\|\s*")
changes, boot = [], False

for base, dirs, files in os.walk(hypr):
    dirs[:] = [d for d in dirs if d not in BACKUP_DIRS]
    for name in sorted(files):
        if not name.endswith((".conf", ".lua")) or name == "hyprlock.conf":
            continue
        path = os.path.join(base, name)
        text = open(path, encoding="utf-8", errors="replace").read()
        lua = name.endswith(".lua")
        out, touched = [], False
        for line in text.splitlines(keepends=True):
            stripped = line.lstrip()
            comment = stripped.startswith("--") if lua else stripped.startswith("#")
            if comment or "hyprlock" not in line or not TOKEN.search(line):
                out.append(line)
                continue
            if re.search(r"exec[-_]once", line):
                prefix = "-- " if lua else "# "
                new = line[: len(line) - len(stripped)] + prefix + "Alpe: sperrt jetzt die Shell selbst (lockAtStartup) – " + stripped
                boot = True
            elif re.match(r"\s*lock_cmd\s*=", line):
                new = re.sub(r"=.*", "= " + LOCK, line.rstrip("\n")) + "\n"
            else:
                new = TOKEN.sub(LOCK, PIDOF.sub("", line))
            if new != line:
                changes.append((path, line.rstrip(), new.rstrip()))
                touched = True
            out.append(new)
        if touched and mode == "apply":
            backup = path + ".vor-alpe"
            if not os.path.exists(backup):
                open(backup, "w", encoding="utf-8").write(text)
            open(path, "w", encoding="utf-8").write("".join(out))

if not changes:
    print("   nichts zu tun: kein hyprlock-Aufruf in " + hypr)
for path, old, new in changes:
    print("   " + os.path.relpath(path, hypr))
    print("     - " + old.strip())
    print("     + " + new.strip())

if boot:
    if mode == "apply":
        try:
            data = json.load(open(settings, encoding="utf-8"))
        except (OSError, ValueError):
            data = {}
        data["lockAtStartup"] = True
        os.makedirs(os.path.dirname(settings), exist_ok=True)
        json.dump(data, open(settings, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
        print("   lockAtStartup eingeschaltet: Die Shell sperrt nach der Anmeldung.")
    else:
        print("   + lockAtStartup in " + settings + " (die Shell sperrt nach der Anmeldung)")

if changes and mode != "apply":
    print("\n   Umstellen mit:  bash ~/alpe/tools/maclock.sh apply")
elif changes:
    print("\n   Fertig. Wirkt nach «hyprctl reload» bzw. für hypridle nach einem Neustart:  systemctl --user restart hypridle  (oder ab- und anmelden)")
PY
