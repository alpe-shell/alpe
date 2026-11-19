#!/usr/bin/env python3
"""Alpe – hyprlock.conf und Alpe-Layout ineinander umsetzen.

    alpe-hyprlock.py DATEI [-o layout.js] [--ref 2560x1664] [--quiet]
    alpe-hyprlock.py DATEI --json       nur das Layout als JSON (für die Einstellungen)
    alpe-hyprlock.py write DATEI JSON [--locale de_CH] [--wallpaper BILD]
                                        Layout als hyprlock.conf schreiben (Alpe, Mac)
    alpe-hyprlock.py wallpaper DATEI BILD
                                        Hintergrund nachführen, wenn er dem Desktop folgt

Liest eine hyprlock-Konfiguration (Schreibweise hyprlang: Blöcke, $Variablen, source = …) und
schreibt `layout.js`, das der Alpe-Sperrbildschirm (Stil «hyprlock») lädt. Umgesetzt werden
background, label, image, shape und input-field mit Lage, Grösse, Farben, Schrift, Schatten und
Rundung. Uhrzeit und Datum aus `cmd[…] date +…` und `echo "$(date +…)"` rechnet der
Sperrbildschirm selbst aus (er darf keine Befehle starten); andere Befehle werden gemeldet
und weggelassen.

Die Werte bleiben in Pixeln des Bildschirms, für den die Datei geschrieben ist (--ref). Der
Sperrbildschirm skaliert sie auf seinen Bildschirm.
"""
import argparse
import datetime
import json
import os
import re
import sys

WIDGETS = ("label", "image", "shape", "input-field")
WEIGHTS = {
    "thin": 100, "hairline": 100, "extralight": 200, "ultralight": 200, "light": 300,
    "regular": 400, "normal": 400, "book": 400, "medium": 500, "semibold": 600,
    "demibold": 600, "bold": 700, "extrabold": 800, "ultrabold": 800, "black": 900, "heavy": 900,
}
RUNTIME_VARS = {"USER", "TIME", "TIME12", "FAIL", "ATTEMPTS", "LAYOUT", "PROMPT", "DESC"}


def warn(messages, text):
    messages.append(text)


# ---------------------------------------------------------------- Einlesen

def strip_comment(line):
    # hyprlang: «##» ist ein wörtliches #, sonst beginnt mit # ein Kommentar.
    keep = line.replace("##", "\0")
    if "#" in keep:
        keep = keep[: keep.index("#")]
    return keep.replace("\0", "#")


def expand(value, variables):
    def repl(match):
        name = match.group(1)
        return variables.get(name, match.group(0))
    # Der Name reicht so weit wie möglich: $wall greift nicht in $wallpaper. Unbekannte Namen
    # ($USER, $TIME …) bleiben stehen; sie setzt hyprlock erst zur Laufzeit ein.
    return re.sub(r"\$([A-Za-z_][A-Za-z0-9_]*)", repl, value)


def parse(path, variables=None, depth=0, messages=None):
    variables = {} if variables is None else variables
    messages = [] if messages is None else messages
    blocks = []
    stack = []
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    for number, raw in enumerate(lines, 1):
        if stack and raw.strip().lower().startswith("# alpe: hintergrund = desktop"):
            stack[-1]["_alpe_desktop"] = True
        line = strip_comment(raw).strip()
        if not line:
            continue
        if line.endswith("{"):
            name = line[:-1].strip().lower()
            block = {"_type": name, "_line": number}
            if stack:
                stack[-1].setdefault("_children", []).append(block)
            else:
                blocks.append(block)
            stack.append(block)
            continue
        if line == "}":
            if stack:
                stack.pop()
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if key.startswith("$") and not stack:
            variables[key[1:]] = expand(value, variables)
            continue
        value = expand(value, variables)
        if key == "source" and not stack:
            target = os.path.expanduser(value)
            if not os.path.isabs(target):
                target = os.path.join(os.path.dirname(path), target)
            if depth < 8 and os.path.exists(target):
                sub, _ = parse(target, variables, depth + 1, messages)
                blocks.extend(sub)
            else:
                warn(messages, f"source nicht gefunden: {value}")
            continue
        if stack:
            stack[-1][key] = value
    return blocks, messages


# ---------------------------------------------------------------- Werte

def number(value, fallback=0.0):
    try:
        return float(str(value).strip())
    except (TypeError, ValueError):
        return fallback


def pair(value, fallback=(0.0, 0.0)):
    if value is None:
        return fallback
    # Als Text: «50%» (Anteil am Bildschirm) löst erst der Sperrbildschirm auf.
    parts = [p for p in re.split(r"[,\s]+", str(value).strip()) if p]
    return (parts[0], parts[1]) if len(parts) >= 2 else fallback


def boolean(value, fallback=False):
    if value is None:
        return fallback
    return str(value).strip().lower() in ("1", "true", "yes", "on")


def color(value, fallback="#ffffffff"):
    """hyprlang-Farbe → #AARRGGBB. Verläufe («a b 45deg») ergeben die erste Farbe."""
    if value is None:
        return fallback
    text = str(value).strip()
    match = re.match(r"rgba?\(([^)]*)\)", text)
    if match:
        inner = match.group(1).strip()
        if re.fullmatch(r"[0-9a-fA-F]{6}([0-9a-fA-F]{2})?", inner):
            rgb = inner[:6]
            alpha = inner[6:8] if len(inner) == 8 else "ff"
            return f"#{alpha}{rgb}".lower()
        parts = [p.strip() for p in inner.split(",")]
        try:
            r, g, b = (max(0, min(255, int(round(float(p))))) for p in parts[:3])
            a = float(parts[3]) if len(parts) > 3 else 1.0
            a = a / 255.0 if a > 1.0 else a
        except (ValueError, IndexError):
            return fallback
        return "#%02x%02x%02x%02x" % (int(round(max(0.0, min(1.0, a)) * 255)), r, g, b)
    match = re.match(r"0x([0-9a-fA-F]{8})", text)
    if match:
        return "#" + match.group(1).lower()
    match = re.match(r"#?([0-9a-fA-F]{6})$", text)
    if match:
        return "#ff" + match.group(1).lower()
    return fallback


def font(value):
    """«JetBrains Mono Nerd Font Mono ExtraBold» → Familie, Gewicht, kursiv."""
    words = str(value or "Sans").split()
    weight = 400
    italic = False
    while len(words) > 1:
        last = words[-1].lower()
        if last in WEIGHTS:
            weight = WEIGHTS[last]
            words.pop()
        elif last in ("italic", "oblique"):
            italic = True
            words.pop()
        else:
            break
    return {"family": " ".join(words), "weight": weight, "italic": italic}


# ---------------------------------------------------------------- Text

def markup(text):
    """Pango-Markup → Qt StyledText (b, i, u, s, span foreground/size, sup/sub, big/small)."""
    def span(match):
        attrs = dict(re.findall(r'(\w+)\s*=\s*["\']([^"\']*)["\']', match.group(1)))
        out = []
        colour = attrs.get("foreground") or attrs.get("color") or attrs.get("fgcolor")
        if colour:
            out.append(f'<font color="{colour}">')
        else:
            out.append("<font>")
        return "".join(out)
    text = re.sub(r"<span\b([^>]*)>", span, text)
    text = text.replace("</span>", "</font>")
    text = re.sub(r"</?(big|small|tt|sup|sub)>", "", text)
    return text


# Umgebungsvariablen vor date (etwa LC_TIME=de_CH.UTF-8, so schreibt Alpe die Sprache) sind erlaubt.
ENV = r"(?:[A-Z_]+=\S+\s+)*"
DATE_INLINE = re.compile(r"""\$\(\s*""" + ENV + r"""date\s+\+\s*(?:"([^"]*)"|'([^']*)'|(\S+))\s*\)""")


def label_text(raw, messages, where):
    """Gibt (Vorlage, Takt in ms) zurück. In der Vorlage steht {date:FORMAT} für das Datum und
    {USER}, {FAIL}, {ATTEMPTS}, {LAYOUT} für Laufzeitwerte. None: nicht umsetzbar."""
    text = str(raw or "").strip()
    update = 0
    match = re.match(r"cmd\[([^\]]*)\]\s*(.*)$", text, re.S)
    if match:
        options = match.group(1)
        command = match.group(2).strip()
        found = re.search(r"update\s*:\s*(\d+)", options)
        update = int(found.group(1)) if found else 0
        found = re.fullmatch(ENV + r"""date\s+\+\s*(?:"([^"]*)"|'([^']*)'|(\S+))""", command)
        if found:
            return "{date:" + next(g for g in found.groups() if g is not None) + "}", update or 1000
        found = re.fullmatch(r"""echo\s+(?:-e\s+)?(?:"(.*)"|'(.*)'|(.*))""", command, re.S)
        if found:
            body = next((g for g in found.groups() if g is not None), "")
            if "$(" in DATE_INLINE.sub("", body):
                warn(messages, f"{where}: Befehl im Text wird nicht ausgeführt: {command}")
                return None, 0
            body = DATE_INLINE.sub(lambda m: "{date:" + next(g for g in m.groups() if g is not None) + "}", body)
            return runtime(body), update or 1000
        warn(messages, f"{where}: Befehl wird nicht ausgeführt, Text weggelassen: {command}")
        return None, 0
    if "$TIME" in text:
        update = 1000
    return runtime(text), update


def runtime(text):
    text = text.replace("$TIME12", "{date:%I:%M %p}").replace("$TIME", "{date:%H:%M}")
    for name in ("USER", "FAIL", "ATTEMPTS", "LAYOUT", "PROMPT", "DESC"):
        text = text.replace("$" + name, "{" + name + "}")
    return markup(text)


# ---------------------------------------------------------------- Umsetzen

def common(block):
    position = pair(block.get("position"), ("0", "0"))
    return {
        "position": [str(position[0]), str(position[1])],
        "monitor": str(block.get("monitor", "")),
        "halign": str(block.get("halign", "center")).lower(),
        "valign": str(block.get("valign", "center")).lower(),
        "zindex": int(number(block.get("zindex"), 0)),
        "rotate": number(block.get("rotate"), 0),
        "opacity": number(block.get("opacity"), 1.0),
    }


def shadow(block):
    return {
        "size": number(block.get("shadow_size"), 0),
        "passes": int(number(block.get("shadow_passes"), 0)),
        "color": color(block.get("shadow_color"), "#ff000000"),
        "boost": number(block.get("shadow_boost"), 1.2),
    }


def convert(blocks, messages):
    result = {"general": {}, "background": None, "widgets": []}
    for index, block in enumerate(blocks):
        kind = block["_type"]
        where = f"{kind} (Zeile {block['_line']})"
        if kind == "general":
            result["general"] = {
                "ignoreEmptyInput": boolean(block.get("ignore_empty_input"), False),
                "hideCursor": boolean(block.get("hide_cursor"), False),
            }
        elif kind == "background":
            if result["background"] is not None:
                continue
            path = os.path.expanduser(str(block.get("path", "")))
            result["background"] = {
                "path": "" if path in ("", "screenshot") else path,
                # Alpe schreibt eine Marke, wenn der Hintergrund dem Desktop folgt.
                "source": "desktop" if block.get("_alpe_desktop") else ("image" if path not in ("", "screenshot") else "desktop"),
                "image": "" if path in ("", "screenshot") or block.get("_alpe_desktop") else path,
                "color": color(block.get("color"), "#ff111111"),
                "blurPasses": int(number(block.get("blur_passes"), 0)),
                "blurSize": number(block.get("blur_size"), 7),
                "noise": number(block.get("noise"), 0.0117),
                "contrast": number(block.get("contrast"), 0.8917),
                "brightness": number(block.get("brightness"), 0.8172),
                "vibrancy": number(block.get("vibrancy"), 0.1696),
                "vibrancyDarkness": number(block.get("vibrancy_darkness"), 0.0),
            }
        elif kind == "label":
            template, update = label_text(block.get("text", ""), messages, where)
            if template is None:
                continue
            item = common(block)
            item.update({
                "type": "label",
                "text": template,
                "update": update,
                "color": color(block.get("color"), "#fffefefe"),
                "fontSize": number(block.get("font_size"), 16),
                "font": font(block.get("font_family", "Sans")),
                "align": str(block.get("text_align", "center")).lower(),
                "shadow": shadow(block),
            })
            result["widgets"].append(item)
        elif kind == "image":
            path = os.path.expanduser(str(block.get("path", "")))
            if not path:
                continue
            item = common(block)
            item.update({
                "type": "image",
                "path": path,
                "exists": os.path.isfile(path),
                "size": number(block.get("size"), 150),
                "rounding": number(block.get("rounding"), -1),
                "borderSize": number(block.get("border_size"), 4),
                "borderColor": color(block.get("border_color"), "#ffdddddd"),
                "shadow": shadow(block),
            })
            if not item["exists"]:
                warn(messages, f"{where}: Bild fehlt: {path}")
            result["widgets"].append(item)
        elif kind == "shape":
            size = pair(block.get("size"), ("100", "100"))
            item = common(block)
            item.update({
                "type": "shape",
                "size": [str(size[0]), str(size[1])],
                "color": color(block.get("color"), "#ff111111"),
                "rounding": number(block.get("rounding"), -1),
                "borderSize": number(block.get("border_size"), 0),
                "borderColor": color(block.get("border_color"), "#00000000"),
                "xray": boolean(block.get("xray"), False),
                "shadow": shadow(block),
            })
            result["widgets"].append(item)
        elif kind == "input-field":
            size = pair(block.get("size"), ("400", "90"))
            item = common(block)
            item.update({
                "type": "input",
                "size": [str(size[0]), str(size[1])],
                "outline": number(block.get("outline_thickness"), 4),
                "outerColor": color(block.get("outer_color"), "#ff111111"),
                "innerColor": color(block.get("inner_color"), "#ffdddddd"),
                "fontColor": color(block.get("font_color"), "#ff111111"),
                "fontFamily": font(block.get("font_family", "Sans"))["family"],
                "checkColor": color(block.get("check_color"), "#ffcc8822"),
                "failColor": color(block.get("fail_color"), "#ffcc2222"),
                "capslockColor": color(block.get("capslock_color"), "") if block.get("capslock_color") not in (None, "-1") else "",
                "dotsSize": max(0.05, min(0.8, number(block.get("dots_size"), 0.33))),
                "dotsSpacing": max(0.0, number(block.get("dots_spacing"), 0.15)),
                "dotsCenter": boolean(block.get("dots_center"), True),
                "dotsRounding": number(block.get("dots_rounding"), -1),
                "hideInput": boolean(block.get("hide_input"), False),
                "fadeOnEmpty": boolean(block.get("fade_on_empty"), True),
                "rounding": number(block.get("rounding"), -1),
                "placeholder": runtime(str(block.get("placeholder_text", "<i>Input Password...</i>"))),
                "failText": runtime(str(block.get("fail_text", "<i>$FAIL <b>($ATTEMPTS)</b></i>"))),
                "failTimeout": int(number(block.get("fail_timeout"), 2000)),
            })
            result["widgets"].append(item)
        elif kind not in ("auth", "animations", "animation", "bezier"):
            warn(messages, f"{where}: wird nicht umgesetzt")
    # Gleiche zindex-Werte behalten die Reihenfolge der Datei.
    for order, item in enumerate(result["widgets"]):
        item["order"] = order
    if not any(w["type"] == "input" for w in result["widgets"]):
        warn(messages, "kein input-field: Alpe ergänzt eines in der Mitte")
    return result


# ---------------------------------------------------------------- Schreiben

WIDGET_BLOCKS = ("background", "label", "image", "shape", "input-field")
WEIGHT_NAMES = {100: "Thin", 200: "ExtraLight", 300: "Light", 500: "Medium", 600: "SemiBold",
                700: "Bold", 800: "ExtraBold", 900: "Black"}
DESKTOP_MARK = "# alpe: hintergrund = desktop"
HEADER = ("# Gestaltet in Alpe: Einstellungen → Sicherheit → Sperrbildschirm gestalten.",
          "# Alpe schreibt background, label, image, shape und input-field neu; andere Blöcke",
          "# (general, auth, animations …) bleiben. Frühere Stände: ~/.local/state/alpe/hyprlock/")
STRFTIME = re.compile(r"%[-_0]?[A-Za-z%]")


def rgba(value, fallback="#ffffffff"):
    text = str(value or fallback).lstrip("#")
    if len(text) == 6:
        text = "ff" + text
    try:
        a, r, g, b = (int(text[i:i + 2], 16) for i in (0, 2, 4, 6))
    except ValueError:
        return rgba(fallback)
    alpha = ("%.3f" % (a / 255)).rstrip("0").rstrip(".")
    return f"rgba({r}, {g}, {b}, {alpha or '0'})"


def fmt_num(value):
    n = float(value)
    return str(int(round(n))) if abs(n - round(n)) < 1e-6 else ("%.4f" % n).rstrip("0").rstrip(".")


def font_out(spec):
    spec = spec or {}
    name = str(spec.get("family") or "Sans")
    weight = int(spec.get("weight", 400) or 400)
    if weight != 400:
        best = min(WEIGHT_NAMES, key=lambda w: abs(w - weight))
        name += " " + WEIGHT_NAMES[best]
    if spec.get("italic"):
        name += " Italic"
    return name


def quote(text):
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("`", "\\`")


def runtime_out(text):
    return (str(text or "").replace("{USER}", "$USER").replace("{FAIL}", "$FAIL")
            .replace("{ATTEMPTS}", "$ATTEMPTS").replace("{LAYOUT}", "$LAYOUT"))


def label_out(item, locale):
    """Text eines Labels für hyprlock: Uhrzeit und Datum über date, sonst fester Text."""
    lc = f"LC_TIME={locale}.UTF-8 " if locale else ""
    if "format" in item:
        fmt = str(item["format"])
        if not STRFTIME.search(fmt):
            return fmt
        return f'cmd[update:1000] {lc}date +"{quote(fmt)}"'
    text = runtime_out(item.get("text", ""))
    whole = re.fullmatch(r"\{date:([^}]*)\}", text)
    if whole:
        return f'cmd[update:1000] {lc}date +"{quote(whole.group(1))}"'
    if "{date:" in text:
        body = re.sub(r"\{date:([^}]*)\}", lambda m: "$(" + lc + "date +'" + m.group(1).replace("'", "") + "')", text)
        return f'cmd[update:1000] echo "{body}"'
    return text


def place(item):
    pos = item.get("position") or ["0", "0"]
    out = [f"    position = {pos[0]}, {pos[1]}",
           f"    halign = {item.get('halign', 'center')}",
           f"    valign = {item.get('valign', 'center')}"]
    if item.get("zindex"):
        out.append(f"    zindex = {int(item['zindex'])}")
    if item.get("rotate"):
        out.append(f"    rotate = {fmt_num(item['rotate'])}")
    return out


def shadow_out(item):
    sh = item.get("shadow") or {}
    if int(sh.get("passes", 0) or 0) <= 0:
        return []
    return [f"    shadow_passes = {int(sh['passes'])}", f"    shadow_size = {fmt_num(sh.get('size', 3))}",
            f"    shadow_color = {rgba(sh.get('color', '#ff000000'))}", f"    shadow_boost = {fmt_num(sh.get('boost', 1.2))}"]


def blur_out(bg):
    """blurRadius (Alpe) -> blur_passes/blur_size; unveränderte Werte bleiben wie gelesen."""
    radius = bg.get("blurRadius")
    passes, size = int(bg.get("blurPasses", 0) or 0), float(bg.get("blurSize", 7) or 7)
    if radius is None:
        return passes, size
    if passes > 0 and abs(size * 2 ** passes * 3 - float(radius)) < 1:
        return passes, size
    if float(radius) <= 0:
        return 0, size
    return 3, max(1, round(float(radius) / 24))


def widget_lines(item, locale):
    kind = item.get("type")
    monitor = f"    monitor = {item.get('monitor', '')}".rstrip()
    flag = lambda v: "true" if v else "false"
    if kind == "label":
        lines = ["label {", monitor, f"    text = {label_out(item, locale)}",
                 f"    color = {rgba(item.get('color'))}",
                 f"    font_size = {int(round(float(item.get('fontSize', 16))))}",
                 f"    font_family = {font_out(item.get('font'))}"]
        if item.get("align") and item["align"] != "center":
            lines.append(f"    text_align = {item['align']}")
        return lines + shadow_out(item) + place(item) + ["}"]
    if kind == "image":
        lines = ["image {", monitor, f"    path = {item.get('path', '')}",
                 f"    size = {int(round(float(item.get('size', 150))))}",
                 f"    rounding = {int(item.get('rounding', -1))}",
                 f"    border_size = {int(item.get('borderSize', 0))}"]
        if int(item.get("borderSize", 0)) > 0:
            lines.append(f"    border_color = {rgba(item.get('borderColor'))}")
        return lines + shadow_out(item) + place(item) + ["}"]
    if kind == "shape":
        size = item.get("size") or ["100", "100"]
        lines = ["shape {", monitor, f"    size = {size[0]}, {size[1]}", f"    color = {rgba(item.get('color'))}",
                 f"    rounding = {int(item.get('rounding', -1))}", f"    border_size = {int(item.get('borderSize', 0))}"]
        if int(item.get("borderSize", 0)) > 0:
            lines.append(f"    border_color = {rgba(item.get('borderColor'))}")
        if item.get("xray"):
            lines.append("    xray = true")
        return lines + shadow_out(item) + place(item) + ["}"]
    if kind == "input":
        size = item.get("size") or ["400", "90"]
        lines = ["input-field {", monitor, f"    size = {size[0]}, {size[1]}",
                 f"    outline_thickness = {fmt_num(item.get('outline', 4))}",
                 f"    dots_size = {fmt_num(item.get('dotsSize', 0.33))}",
                 f"    dots_spacing = {fmt_num(item.get('dotsSpacing', 0.15))}",
                 f"    dots_center = {flag(item.get('dotsCenter', True))}",
                 f"    dots_rounding = {int(item.get('dotsRounding', -1))}",
                 f"    outer_color = {rgba(item.get('outerColor'))}", f"    inner_color = {rgba(item.get('innerColor'))}",
                 f"    font_color = {rgba(item.get('fontColor'))}", f"    font_family = {item.get('fontFamily') or 'Sans'}",
                 f"    fade_on_empty = {flag(item.get('fadeOnEmpty', False))}",
                 f"    placeholder_text = {runtime_out(item.get('placeholder'))}",
                 f"    hide_input = {flag(item.get('hideInput', False))}",
                 f"    rounding = {int(item.get('rounding', -1))}",
                 f"    check_color = {rgba(item.get('checkColor', '#ffcc8822'))}",
                 f"    fail_color = {rgba(item.get('failColor', '#ffcc2222'))}",
                 f"    fail_text = {runtime_out(item.get('failText', '<i>$FAIL <b>($ATTEMPTS)</b></i>'))}",
                 f"    fail_timeout = {int(item.get('failTimeout', 2000))}"]
        if item.get("capslockColor"):
            lines.append(f"    capslock_color = {rgba(item['capslockColor'])}")
        return lines + place(item) + ["}"]
    return []


def raw_blocks(text):
    """Oberste Blöcke mit Originaltext: [(name oder None für Zeilen ausserhalb, text)]."""
    out, depth, current, name = [], 0, [], None
    for line in text.splitlines(keepends=True):
        code = strip_comment(line).strip()
        if depth == 0 and code.endswith("{"):
            name, current, depth = code[:-1].strip().lower(), [line], 1
            continue
        if depth > 0:
            current.append(line)
            depth += code.count("{") - code.count("}")
            if depth <= 0:
                out.append((name, "".join(current)))
                depth, current = 0, []
            continue
        out.append((None, line))
    return out


def write_conf(path, layout, locale="", wallpaper="", keep=10):
    old = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
    if old:
        first = path + ".vor-alpe"
        if not os.path.exists(first):
            with open(first, "w", encoding="utf-8") as handle:
                handle.write(old)
        state = os.environ.get("XDG_STATE_HOME") or os.path.join(os.path.expanduser("~"), ".local", "state")
        backups = os.path.join(state, "alpe", "hyprlock")
        os.makedirs(backups, exist_ok=True)
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
        with open(os.path.join(backups, f"hyprlock-{stamp}.conf"), "w", encoding="utf-8") as handle:
            handle.write(old)
        for stale in sorted(os.listdir(backups))[:-keep]:
            os.remove(os.path.join(backups, stale))
    blocks = raw_blocks(old)
    kept = []
    for name, text in blocks:
        stripped = text.strip()
        if name is None:
            if stripped.startswith("$") or stripped.startswith("source"):
                kept.append(stripped)
        elif name not in WIDGET_BLOCKS:
            kept.append(text.rstrip("\n"))
    out = list(HEADER) + [""]
    if kept:
        out += kept + [""]
    if not any(name == "general" for name, _ in blocks):
        out += ["general {", "    ignore_empty_input = true", "}", ""]
    bg = layout.get("background") or {}
    desktop = bg.get("source", "desktop") != "image"
    image = wallpaper if desktop else bg.get("image", "")
    passes, size = blur_out(bg)
    out += ["background {", "    monitor ="]
    if desktop:
        out.append("    " + DESKTOP_MARK)
    out += [f"    path = {image or 'screenshot'}", f"    color = {rgba(bg.get('color', '#ff111111'))}",
            f"    blur_passes = {passes}", f"    blur_size = {fmt_num(size)}",
            f"    noise = {fmt_num(bg.get('noise', 0.0117))}", f"    contrast = {fmt_num(bg.get('contrast', 0.8917))}",
            f"    brightness = {fmt_num(bg.get('brightness', 0.8172))}", f"    vibrancy = {fmt_num(bg.get('vibrancy', 0.1696))}",
            f"    vibrancy_darkness = {fmt_num(bg.get('vibrancyDarkness', 0))}", "}", ""]
    for item in layout.get("widgets", []):
        lines = widget_lines(item, locale)
        if lines:
            out += lines + [""]
    tmp = path + ".neu"
    with open(tmp, "w", encoding="utf-8") as handle:
        handle.write("\n".join(out))
    os.replace(tmp, path)


def follow_wallpaper(path, image):
    """Folgt der Hintergrund dem Desktop (Marke), das Bild im background-Block tauschen."""
    if not os.path.exists(path):
        return False
    lines = open(path, encoding="utf-8").read().splitlines(keepends=True)
    inside = marked = changed = False
    for i, line in enumerate(lines):
        code = strip_comment(line).strip()
        if code.lower().replace(" ", "") == "background{":
            inside, marked = True, False
        elif inside and line.strip().lower().startswith(DESKTOP_MARK):
            marked = True
        elif inside and marked and code.startswith("path"):
            new = line[: len(line) - len(line.lstrip())] + f"path = {image}\n"
            if new != line:
                lines[i], changed = new, True
        elif inside and code == "}":
            inside = False
    if changed:
        tmp = path + ".neu"
        with open(tmp, "w", encoding="utf-8") as handle:
            handle.write("".join(lines))
        os.replace(tmp, path)
    return changed


def subcommand():
    """write / wallpaper; sonst None (dann gilt die alte Aufrufform)."""
    if len(sys.argv) >= 2 and sys.argv[1] == "write":
        rest = argparse.ArgumentParser()
        rest.add_argument("cmd")
        rest.add_argument("conf")
        rest.add_argument("layout")
        rest.add_argument("--locale", default="")
        rest.add_argument("--wallpaper", default="")
        a = rest.parse_args()
        write_conf(os.path.expanduser(a.conf), json.loads(a.layout), a.locale, a.wallpaper)
        print(json.dumps({"ok": True}))
        return 0
    if len(sys.argv) >= 4 and sys.argv[1] == "wallpaper":
        print(json.dumps({"changed": follow_wallpaper(os.path.expanduser(sys.argv[2]), sys.argv[3])}))
        return 0
    return None


def main():
    handled = subcommand()
    if handled is not None:
        return handled
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("conf")
    parser.add_argument("-o", "--output", default="-")
    parser.add_argument("--ref", default="2560x1664", help="Bildschirm, für den die Datei geschrieben ist")
    parser.add_argument("--quiet", action="store_true")
    parser.add_argument("--json", action="store_true", help="Layout als JSON in einer Zeile ausgeben")
    args = parser.parse_args()
    try:
        ref_w, ref_h = (int(v) for v in args.ref.lower().split("x"))
    except ValueError:
        sys.exit("--ref erwartet BREITExHÖHE, etwa 2560x1664")
    blocks, messages = parse(os.path.expanduser(args.conf))
    layout = convert(blocks, messages)
    layout["reference"] = {"width": ref_w, "height": ref_h}
    # «exists» dient nur den Meldungen; im Layout hätte es den Stand dieses Rechners festgehalten.
    for item in layout["widgets"]:
        item.pop("exists", None)
    layout["source"] = os.path.abspath(os.path.expanduser(args.conf))
    if args.json:
        layout.pop("source", None)
        for item in layout["widgets"]:
            item.pop("exists", None)
        sys.stdout.write(json.dumps(layout, ensure_ascii=False, separators=(",", ":")) + "\n")
        for message in messages:
            print(f"   HINWEIS: {message}", file=sys.stderr)
        return 0
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    body = (
        ".pragma library\n"
        f"// Erzeugt von tools/hyprlock2qml.py aus {layout['source']} am {stamp}.\n"
        "// Nicht von Hand ändern: Die Quelle ist die hyprlock.conf.\n"
        "var layout = " + json.dumps(layout, ensure_ascii=False, indent=1) + ";\n"
    )
    if args.output == "-":
        sys.stdout.write(body)
    else:
        tmp = args.output + ".neu"
        with open(tmp, "w", encoding="utf-8") as handle:
            handle.write(body)
        os.replace(tmp, args.output)
    if not args.quiet:
        counts = {}
        for item in layout["widgets"]:
            counts[item["type"]] = counts.get(item["type"], 0) + 1
        summary = ", ".join(f"{n} × {t}" for t, n in sorted(counts.items()))
        print(f"   hyprlock.conf umgesetzt: {summary or 'nichts'}", file=sys.stderr)
        for message in messages:
            print(f"   HINWEIS: {message}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
