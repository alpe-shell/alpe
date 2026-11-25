.pragma library

// Standbild eines Video-Hintergrunds (Plan 0.8 Nr. 106).
//
// Matugen, Vorschaubilder und jede unscharfe oder gesperrte Fläche brauchen ein Standbild. Die Shell erzeugt es
// mit ffmpeg einmal je Video im Cache. Videos des eingespielten Designs bringen ihr Standbild als gleichnamiges .jpg
// mit (design.py apply legt beides unter <XDG_DATA_HOME>/alpe/design/bilder/ ab); dann braucht es kein ffmpeg.
// Nur für Videos in diesem Ordner – für eigene Videos der Nutzer wird ein .jpg daneben nicht genommen.
//
// FILTER und QUALITY sind der Aufruf, mit dem auch tools/standbild.py das mitgelieferte Bild erzeugt
// (tests/test_standbild.py vergleicht beide).

var FILTER = "thumbnail=60,scale='min(3840,iw)':-2";
var QUALITY = "2";
var BUNDLED_EXIT = 10;      // Rückgabewert des Skripts: das mitgelieferte Standbild liegt vor

// Ordner des eingespielten Designs, mit Schrägstrich am Ende.
function designDir(dataDir) {
    return (dataDir || "").replace(/\/+$/, "") + "/design/";
}

// Pfad des mitgelieferten Standbilds zu einem Video des Designs, sonst "".
function bundledPoster(video, dir) {
    let path = video || "";
    if (path.startsWith("file://"))
        path = path.substring(7);
    if (!dir || dir === "/design/" || !path.startsWith(dir))
        return "";
    if (path.split("/").indexOf("..") >= 0)
        return "";
    const slash = path.lastIndexOf("/");
    const dot = path.lastIndexOf(".");
    if (dot <= slash + 1)
        return "";
    return path.substring(0, dot) + ".jpg";
}

// Was der Dienst mit dem Rückgabewert des Skripts macht (rein, damit es sich mit Node prüfen lässt):
//   "bundled"   – mitgeliefertes Standbild nehmen (nur, wenn es eins gibt)
//   "missing"   – ffmpeg fehlt: dieses Video gilt als gescheitert (sonst wartete framePending() ewig auf ein Bild,
//                 das nie kommt – auch für ein Video des Designs ohne .jpg), ffmpegMissing setzen
//   "generated" – Standbild im Cache liegt vor
//   "failed"    – sonst
function outcome(exitCode, bundled) {
    if (exitCode === BUNDLED_EXIT && bundled)
        return "bundled";
    if (exitCode === 127)
        return "missing";
    if (exitCode === 0)
        return "generated";
    return "failed";
}

// Kann für dieses Video noch ein Standbild kommen? (framePending des Dienstes; state: ffmpegMissing, failed, poster)
function pending(isVideo, bundled, state) {
    return isVideo && !state.poster && (!state.ffmpegMissing || !!bundled) && !state.failed;
}

// Darf das Video eingestellt werden? (request des Dienstes; state zusätzlich: queued)
function mayRequest(bundled, state) {
    return !(state.ffmpegMissing && !bundled) && !state.queued && !state.failed && !state.poster;
}

// sh-Skript: $1 Standbild im Cache, $2 Video, $3 mitgeliefertes Standbild oder leer.
// Liegt $3 vor: Rückgabewert BUNDLED_EXIT, ohne ffmpeg. Fehlt ffmpeg: 127. -nt behält ein Bild, das neuer ist als
// sein Video; der Filter thumbnail überspringt schwarze Bilder am Anfang.
function script() {
    return '[ -n "$3" ] && [ -f "$3" ] && exit ' + BUNDLED_EXIT + '; '
        + 'command -v ffmpeg >/dev/null || exit 127; [ "$1" -nt "$2" ] && exit 0; '
        + 'mkdir -p "${1%/*}" && ffmpeg -nostdin -v error -i "$2" -vf "' + FILTER + '" -frames:v 1 -q:v ' + QUALITY
        + ' -y "$1.part.jpg" 2>&1 && mv -f "$1.part.jpg" "$1"';
}
