.pragma library

// Alpe-Zeichen (zwei Gipfel) – einzige Quelle der Pfaddaten.
// Aus diesen Vielecken entstehen: die Form «alpeLogo» der Materialformen (MaterialShapes.js,
// Material-Vorlage «Alpe»), der Logo-Modus "alpe" (Widgets/LauncherLogo.qml) und die Dateien
// assets/alpe-zeichen.svg und assets/alpe-zeichen-akzent.svg (tests/test_logoform.mjs prüft,
// dass sie genau svg() entsprechen; neu schreiben mit ALPE_LOGO_SCHREIBEN=1).

var viewBox = 512;

// Teile des Zeichens in Koordinaten des viewBox, je ein geschlossenes Vieleck.
var parts = [
    {
        name: "grosser Gipfel: Schneekappe",
        points: [[318, 62], [392, 196], [352, 172], [318, 214], [286, 170], [246, 198]]
    },
    {
        name: "grosser Gipfel: Fels",
        points: [[232, 226], [286, 198], [318, 246], [352, 202], [406, 232], [500, 446], [258, 446], [223, 318], [204, 277]]
    },
    {
        name: "kleiner Gipfel",
        points: [[150, 196], [196, 292], [172, 276], [150, 304], [128, 278], [104, 294]]
    },
    {
        name: "",
        points: [[92, 320], [128, 306], [150, 336], [172, 304], [204, 322], [238, 446], [12, 446]]
    }
];

// Dasselbe als Kubiken im Einheitsquadrat, wie MaterialShapes.js sie erwartet: Jede Kante ist
// eine gerade Kubik; ein Sprung zwischen zwei aufeinanderfolgenden Kubiken beginnt einen neuen Teilpfad.
var cubics = (function () {
    var out = [];
    var unit = function (value) {
        return value / viewBox;
    };
    for (var p = 0; p < parts.length; p++) {
        var points = parts[p].points;
        for (var i = 0; i < points.length; i++) {
            var a = points[i];
            var b = points[(i + 1) % points.length];
            out.push([unit(a[0]), unit(a[1]), unit(a[0] + (b[0] - a[0]) / 3), unit(a[1] + (b[1] - a[1]) / 3), unit(a[0] + (b[0] - a[0]) * 2 / 3), unit(a[1] + (b[1] - a[1]) * 2 / 3), unit(b[0]), unit(b[1])]);
        }
    }
    return out;
})();

// Pfaddaten eines Teils für SVG («M318 62 L392 196 … Z»).
function partPath(part) {
    return "M" + part.points.map(function (point) {
        return point[0] + " " + point[1];
    }).join(" L") + " Z";
}

// Das ganze Zeichen als SVG-Datei in der Füllfarbe fill.
function svg(fill) {
    var lines = ['<?xml version="1.0" encoding="UTF-8"?>', "<!-- Alpe: zwei Gipfel. Eigenes Zeichen. -->", '<svg xmlns="http://www.w3.org/2000/svg" width="' + viewBox + '" height="' + viewBox + '" viewBox="0 0 ' + viewBox + " " + viewBox + '">', '  <g fill="' + fill + '">'];
    for (var p = 0; p < parts.length; p++) {
        if (parts[p].name !== "")
            lines.push("    <!-- " + parts[p].name + " -->");
        lines.push('    <path d="' + partPath(parts[p]) + '"/>');
    }
    lines.push("  </g>", "</svg>", "");
    return lines.join("\n");
}
