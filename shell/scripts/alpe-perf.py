#!/usr/bin/env python3
"""Alpe – Verbrauch der Shell messen und Teile des Dienstes abschalten.

    alpe-perf.py                 JSON: Prozesse (PSS, CPU %), abgeschaltete Teile, eigener Dienst?
    alpe-perf.py off NAME on|off Teil des Dienstes ab- (on) oder wieder einschalten (off)

Gemessen wird über /proc: PSS (anteiliger Speicher, ehrlicher als RSS bei geteilten
Bibliotheken) und CPU-Anteil über 0,5 s. Abgeschaltete Teile stehen in ~/.config/alpe/aus;
der eigene Dienst liest die Datei beim Start (core/internal/server/alpe_off.go).
"""
import json
import os
import sys
import time

CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(os.path.expanduser("~"), ".config")
OFF_FILE = os.path.join(CONFIG, "alpe", "aus")
PARTS = ["bluetooth", "wellbeing", "clipboard", "location", "trayrecovery", "evdev", "notifyactions"]
PROC = os.environ.get("ALPE_PROC", "/proc")


def read(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            return handle.read()
    except OSError:
        return ""


def shell_processes():
    uid = os.getuid()
    found = []
    for pid in os.listdir(PROC):
        if not pid.isdigit():
            continue
        status = read(f"{PROC}/{pid}/status")
        if not status or f"Uid:\t{uid}" not in status:
            continue
        cmdline = read(f"{PROC}/{pid}/cmdline").split("\0")
        exe = os.path.basename(cmdline[0]) if cmdline and cmdline[0] else ""
        try:
            target = os.readlink(f"{PROC}/{pid}/exe")
        except OSError:
            target = ""
        if exe in ("quickshell", "qs") or os.path.basename(target) in ("quickshell", "qs"):
            kind = "Oberfläche (Quickshell)"
        elif (exe in ("alpe-dienst", "dms", "alpe") or os.path.basename(target) in ("alpe-dienst", "dms", "alpe")) and "run" in cmdline[1:]:
            kind = "Dienst (" + ("eigener Bau" if "/.local/lib/alpe/" in target else "Paket") + ")"
        else:
            continue
        found.append({"pid": int(pid), "name": kind, "exe": target})
    return found


def pss_kb(pid):
    for line in read(f"{PROC}/{pid}/smaps_rollup").splitlines():
        if line.startswith("Pss:"):
            return int(line.split()[1])
    for line in read(f"{PROC}/{pid}/status").splitlines():
        if line.startswith("VmRSS:"):
            return int(line.split()[1])
    return 0


def memory_kb(pid):
    """RSS, PSS und privat (Private_Clean + Private_Dirty) aus smaps_rollup."""
    values = {"rss": 0, "pss": 0, "private": 0}
    for line in read(f"{PROC}/{pid}/smaps_rollup").splitlines():
        key, _, rest = line.partition(":")
        if not rest.strip():
            continue
        amount = int(rest.split()[0])
        if key == "Rss":
            values["rss"] = amount
        elif key == "Pss":
            values["pss"] = amount
        elif key in ("Private_Clean", "Private_Dirty"):
            values["private"] += amount
    return values


def arena_limited(pid):
    return any(e.startswith("MALLOC_ARENA_MAX=") for e in read(f"{PROC}/{pid}/environ").split("\0"))


def cpu_ticks(pid):
    stat = read(f"{PROC}/{pid}/stat")
    if not stat:
        return 0
    fields = stat.rsplit(")", 1)[-1].split()
    return int(fields[11]) + int(fields[12])


def threads(pid):
    for line in read(f"{PROC}/{pid}/status").splitlines():
        if line.startswith("Threads:"):
            return int(line.split()[1])
    return 0


def read_off():
    parts = set()
    for line in read(OFF_FILE).splitlines():
        name = line.split("#", 1)[0].strip().lower()
        if name:
            parts.add(name)
    return parts


def write_off(parts):
    os.makedirs(os.path.dirname(OFF_FILE), exist_ok=True)
    body = "# Alpe: Teile des Dienstes, die nicht starten (Einstellungen → Leistung)\n"
    body += "".join(p + "\n" for p in sorted(parts))
    tmp = OFF_FILE + ".neu"
    with open(tmp, "w", encoding="utf-8") as handle:
        handle.write(body)
    os.replace(tmp, OFF_FILE)


def measure():
    procs = shell_processes()
    ticks = os.sysconf("SC_CLK_TCK")
    before = {p["pid"]: cpu_ticks(p["pid"]) for p in procs}
    start = time.monotonic()
    time.sleep(0.5)
    elapsed = time.monotonic() - start
    total = 0
    for p in procs:
        p["pss"] = pss_kb(p["pid"])
        mem = memory_kb(p["pid"])
        p["rss"], p["private"] = mem["rss"], mem["private"]
        p["arenaLimited"] = arena_limited(p["pid"])
        p["threads"] = threads(p["pid"])
        p["cpu"] = round((cpu_ticks(p["pid"]) - before.get(p["pid"], 0)) / ticks / elapsed * 100, 1)
        total += p["pss"]
    procs.sort(key=lambda p: -p["pss"])
    meminfo = {}
    for line in read(f"{PROC}/meminfo").splitlines():
        key, _, value = line.partition(":")
        if value.strip():
            meminfo[key] = int(value.split()[0])
    return {
        "processes": procs,
        "totalPss": total,
        "memTotal": meminfo.get("MemTotal", 0),
        "memAvailable": meminfo.get("MemAvailable", 0),
        "off": sorted(read_off()),
        "parts": PARTS,
        "arenaLimited": any(p.get("arenaLimited") for p in procs if p["name"].startswith("Oberfläche")),
        "ownBackend": any("/.local/lib/alpe/" in p.get("exe", "") for p in procs),
    }


def main(argv):
    if len(argv) >= 4 and argv[1] == "off":
        name, state = argv[2].lower(), argv[3]
        if name not in PARTS:
            sys.exit("unbekannter Teil")
        parts = read_off()
        if state == "on":
            parts.add(name)
        else:
            parts.discard(name)
        write_off(parts)
        print(json.dumps({"off": sorted(parts)}))
        return
    print(json.dumps(measure(), ensure_ascii=False))


if __name__ == "__main__":
    main(sys.argv)
