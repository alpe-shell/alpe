#!/usr/bin/env python3
"""Alpe – hyprlock.conf und Alpe-Layout ineinander umsetzen.

Ab 1.8 liegt der Umsetzer im Shell-Code (shell/scripts/alpe-hyprlock.py), weil die
Einstellungen ihn dort brauchen (hyprlock am Mac). Dieses Skript reicht nur weiter; Aufruf
wie dort, etwa:  hyprlock2qml.py DATEI --json   oder   hyprlock2qml.py DATEI -o layout.js
"""
import os
import sys

shell = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "shell")
target = os.path.join(shell, "scripts", "alpe-hyprlock.py")
if not os.path.exists(target):
    sys.exit(f"{target} fehlt – zuerst den Shell-Code auf Alpe bringen (bash ~/alpe/install.sh)")
os.execv(sys.executable, [sys.executable, "-I", target] + sys.argv[1:])
