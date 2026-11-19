#!/usr/bin/env python3
"""Baut die Kartengrundlage des Radar-Tabs aus Natural Earth (gemeinfrei).

Nur zur Bauzeit noetig (pyproj, Pillow). Ergebnis: zwei Alphamasken im Ausschnitt EXTENT,
die der Tab mit Theme-Farben einfaerbt:
  plugins/alpeRadar/map-lines.png   Landes- und Kantonsgrenzen, Fluesse
  plugins/alpeRadar/map-water.png   Seen

Aufruf: build-basemap.py <Ordner mit den Natural-Earth-GeoJSON-Dateien>
"""
import json, os, sys
from PIL import Image, ImageDraw
from pyproj import Transformer

EXTENT = (2400000, 1000000, 2920000, 1370000)   # LV95: West, Sued, Ost, Nord - wie im Hilfsprogramm radar
PX_PER_KM = 3
SS = 3                                           # Ueberabtastung fuer glatte Linien
PROJ = ("+proj=somerc +lat_0=46.95240555555556 +lon_0=7.439583333333333 +k_0=1 +x_0=2600000 "
        "+y_0=1200000 +ellps=bessel +towgs84=674.374,15.056,405.346,0,0,0,0 +units=m +no_defs")
to_lv95 = Transformer.from_crs("EPSG:4326", PROJ, always_xy=True)

W = int((EXTENT[2] - EXTENT[0]) / 1000 * PX_PER_KM)
H = int((EXTENT[3] - EXTENT[1]) / 1000 * PX_PER_KM)
LONLAT_BOX = (2.0, 43.0, 13.5, 50.0)


def near(coords):
    return any(LONLAT_BOX[0] <= x <= LONLAT_BOX[2] and LONLAT_BOX[1] <= y <= LONLAT_BOX[3] for x, y in coords)


def pixels(coords):
    xs, ys = to_lv95.transform([c[0] for c in coords], [c[1] for c in coords])
    scale = PX_PER_KM * SS / 1000
    return [((x - EXTENT[0]) * scale, (EXTENT[3] - y) * scale) for x, y in zip(xs, ys)]


def lines_of(geometry):
    kind, coords = geometry["type"], geometry["coordinates"]
    if kind == "LineString":
        return [coords]
    if kind == "MultiLineString":
        return coords
    if kind == "Polygon":
        return coords
    if kind == "MultiPolygon":
        return [ring for polygon in coords for ring in polygon]
    return []


def features(folder, name):
    with open(os.path.join(folder, name + ".geojson"), encoding="utf-8") as handle:
        return json.load(handle)["features"]


def main(folder, target):
    lines = Image.new("L", (W * SS, H * SS), 0)
    water = Image.new("L", (W * SS, H * SS), 0)
    draw_lines, draw_water = ImageDraw.Draw(lines), ImageDraw.Draw(water)

    for name in ("ne_10m_rivers_lake_centerlines", "ne_10m_rivers_europe"):
        for feature in features(folder, name):
            if not feature["geometry"]:
                continue
            for line in lines_of(feature["geometry"]):
                if near(line):
                    draw_lines.line(pixels(line), fill=70, width=SS)
    for feature in features(folder, "ne_10m_admin_1_states_provinces_lines"):
        if feature["properties"].get("adm0_a3") != "CHE" and feature["properties"].get("ADM0_A3") != "CHE":
            continue
        for line in lines_of(feature["geometry"]):
            draw_lines.line(pixels(line), fill=95, width=SS)
    for feature in features(folder, "ne_10m_admin_0_countries"):
        for ring in lines_of(feature["geometry"]):
            if near(ring):
                draw_lines.line(pixels(ring), fill=255, width=int(SS * 1.6))
    for name in ("ne_10m_lakes", "ne_10m_lakes_europe"):
        for feature in features(folder, name):
            geometry = feature["geometry"]
            if not geometry:
                continue
            polygons = [geometry["coordinates"]] if geometry["type"] == "Polygon" else geometry["coordinates"]
            for polygon in polygons:
                if not near(polygon[0]):
                    continue
                draw_water.polygon(pixels(polygon[0]), fill=255)
                for hole in polygon[1:]:
                    draw_water.polygon(pixels(hole), fill=0)

    for image, name in ((lines, "map-lines.png"), (water, "map-water.png")):
        alpha = image.resize((W, H), Image.LANCZOS)
        out = Image.new("RGBA", (W, H), (255, 255, 255, 0))
        out.putalpha(alpha)
        out.save(os.path.join(target, name), optimize=True)
        print(name, out.size, os.path.getsize(os.path.join(target, name)), "Bytes")


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    main(sys.argv[1], os.path.join(here, "..", "plugins", "alpeRadar"))
