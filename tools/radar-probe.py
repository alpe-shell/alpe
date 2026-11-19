#!/usr/bin/env python3
"""Holt die juengste Niederschlagsradar-Datei (PRECIP/RZC) von MeteoSchweiz als Muster nach ~/."""
import json, urllib.request, datetime, os
base = "https://data.geo.admin.ch/api/stac/v1/collections/ch.meteoschweiz.ogd-radar-precip/items/"
now = datetime.datetime.now(datetime.timezone.utc)
for back in (0, 1):
    item = (now - datetime.timedelta(days=back)).strftime("%Y%m%d") + "-ch"
    try:
        assets = json.load(urllib.request.urlopen(base + item, timeout=20))["assets"]
    except Exception as error:
        print(item, "nicht lesbar:", error); continue
    keys = sorted(k for k in assets if k.upper().startswith("RZC"))
    print(item, len(assets), "Dateien, davon RZC:", len(keys), "| Beispiele:", sorted(assets)[:3])
    if keys:
        target = os.path.expanduser("~/radar-" + keys[-1])
        urllib.request.urlretrieve(assets[keys[-1]]["href"], target)
        print("gespeichert:", target, os.path.getsize(target), "Bytes"); break
