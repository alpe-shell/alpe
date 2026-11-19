#!/usr/bin/env python3
"""Kopfleiste (GTK-Headerbar) von Proton VPN schlank machen oder verstecken.

    kopfleiste.py [schlank|weg|aus|status]

Proton VPN (proton-vpn-gtk-app, GTK 4) zeichnet seine eigene Kopfleiste: 48 px hoch, mit Titel,
Menü (⋮) und Fensterknöpfen. Unter Alpe fasst man Fenster ohnehin an der Griffleiste an.
Die eigene CSS-Datei alpe-apps.css (in ~/.config/gtk-4.0 und gtk-3.0) gilt nur für Proton VPN
(Klasse «proton-app» bzw. Fenstername «main-window», die das Programm selbst setzt) und wird
oben in gtk.css eingebunden; die
Benutzer-CSS hat bei GTK Vorrang vor der des Programms. Andere GTK-Programme bleiben, wie sie sind.

  schlank  Leiste ohne Titel, ohne eigene Farbe, knapp 30 px; Menü und × bleiben (Vorgabe)
  weg      Leiste fällt praktisch ganz weg (wenige Pixel); das Menü ist dann nicht erreichbar
           (Einstellungen von Proton VPN über das Symbol im Systembereich)
  aus      wieder wie vom Programm vorgesehen
Wirkt beim nächsten Start von Proton VPN.
"""
import os
import sys

CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(os.path.expanduser("~"), ".config")
# Neuere Fassungen sind GTK 4, ältere GTK 3: beide Ordner bekommen dieselben Regeln.
FOLDERS = [os.path.join(CONFIG, "gtk-4.0"), os.path.join(CONFIG, "gtk-3.0")]
IMPORT = '@import url("alpe-apps.css"); /* Alpe: alpe kopfleiste */'

SLIM = """/* Alpe: Proton VPN mit schlanker Kopfleiste (alpe kopfleiste schlank) */
.proton-app headerbar,
window#main-window > headerbar {
    min-height: 0;
    padding: 0 2px;
    border: none;
    box-shadow: none;
    background: none;
}
.proton-app headerbar .title,
window#main-window > headerbar .title {
    color: transparent;
    font-size: 1px;
}
.proton-app headerbar menubutton,
.proton-app headerbar windowcontrols,
window#main-window > headerbar menubutton,
window#main-window > headerbar windowcontrols {
    min-height: 0;
    margin: 0;
    padding: 0;
}
.proton-app headerbar menubutton > button,
window#main-window > headerbar menubutton > button {
    min-width: 16px;
    min-height: 16px;
    padding: 4px;
    margin: 2px;
}
.proton-app headerbar windowcontrols button,
window#main-window > headerbar windowcontrols button,
window#main-window > headerbar button.titlebutton {
    min-width: 20px;
    min-height: 20px;
    padding: 2px;
    margin: 2px;
}
.proton-app headerbar button,
window#main-window > headerbar button {
    min-height: 20px;
    padding-top: 2px;
    padding-bottom: 2px;
}
.proton-app headerbar windowhandle,
.proton-app headerbar windowhandle > box,
window#main-window > headerbar windowhandle,
window#main-window > headerbar windowhandle > box {
    min-height: 0;
    padding: 0;
}
"""

# Nur das Hauptfenster: Dialoge behalten ihr × (sonst liessen sie sich nur mit Esc schliessen)
GONE = """/* Alpe: Proton VPN ohne Kopfleiste (alpe kopfleiste weg) */
window#main-window > headerbar,
window#main-window > headerbar * {
    min-height: 0;
    min-width: 0;
    padding: 0;
    margin: 0;
    border: none;
    box-shadow: none;
    background: none;
    color: transparent;
    font-size: 1px;
    opacity: 0;
}
"""
GTK4_ONLY = """window#main-window > headerbar image {
    -gtk-icon-size: 1px;
}
"""


def read(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except OSError:
        return ""


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".alpe.tmp"
    with open(tmp, "w", encoding="utf-8") as handle:
        handle.write(text)
    os.replace(tmp, path)


def css_for(mode, folder):
    if mode == "schlank":
        return SLIM
    return GONE + (GTK4_ONLY if folder.endswith("gtk-4.0") else "")


def status():
    folder = FOLDERS[0]
    own = read(os.path.join(folder, "alpe-apps.css"))
    mode = "weg" if "kopfleiste weg" in own else "schlank" if "kopfleiste schlank" in own else "aus"
    linked = IMPORT.split(";")[0] in read(os.path.join(folder, "gtk.css"))
    return mode if linked or mode == "aus" else mode + " (Datei da, aber nicht in gtk.css eingebunden)"


def main(mode):
    if mode == "status":
        print("Proton VPN Kopfleiste: " + status())
        return 0
    for folder in FOLDERS:
        gtk_css, own = os.path.join(folder, "gtk.css"), os.path.join(folder, "alpe-apps.css")
        if os.path.islink(gtk_css):
            print("%s ist ein Verweis (selbst verwaltet). Füge selbst oben ein: %s" % (gtk_css, IMPORT))
            continue
        lines = [l for l in read(gtk_css).splitlines() if "alpe-apps.css" not in l]
        if mode == "aus":
            if os.path.exists(own):
                os.remove(own)
            if os.path.exists(gtk_css):
                write(gtk_css, "\n".join(lines) + ("\n" if lines else ""))
            continue
        write(own, css_for(mode, folder))
        # @import muss vor allen Regeln stehen: an den Anfang
        write(gtk_css, "\n".join([IMPORT] + lines) + "\n")
    if mode == "aus":
        print("Proton VPN: Kopfleiste wie vom Programm vorgesehen (beim nächsten Start).")
    else:
        print("Proton VPN: Kopfleiste %s – wirkt beim nächsten Start von Proton VPN." % ("schlank" if mode == "schlank" else "ausgeblendet"))
    return 0


if __name__ == "__main__":
    choice = (sys.argv[1] if len(sys.argv) > 1 else "schlank").lower()
    if choice not in ("schlank", "weg", "aus", "status"):
        print(__doc__.strip())
        sys.exit(2)
    sys.exit(main(choice))
