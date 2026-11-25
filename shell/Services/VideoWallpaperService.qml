pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import "../Common/WallpaperFormats.js" as WallpaperFormats
import "../Common/VideoPoster.js" as VideoPoster

// matugen, thumbnails and every blurred or lock surface need a still image,
// so each video wallpaper gets one cached frame, extracted once per file change.
// Videos des eingespielten Designs bringen ihr Standbild als gleichnamiges .jpg mit (Plan 0.8 Nr. 106); es wird
// vor ffmpeg genommen, und nur für Videos im Ordner des Designs, nie für eigene Videos der Nutzer.
Singleton {
    id: root

    readonly property var log: Log.scoped("VideoWallpaperService")
    readonly property string posterDir: Paths.strip(Paths.cache) + "/video-wallpaper"
    readonly property string designDir: VideoPoster.designDir(Paths.strip(Paths.data))

    // video path -> frame path, holds only frames that exist on disk
    property var posters: ({})
    property bool ffmpegMissing: false
    property var _queue: []
    property var _queued: ({})
    property var _failed: ({})
    property bool _busy: false

    function isVideo(path) {
        return WallpaperFormats.isVideo(path);
    }

    function posterPath(video) {
        return `${posterDir}/${Qt.md5(video)}.jpg`;
    }

    // Mitgeliefertes Standbild neben einem Video des eingespielten Designs, sonst "".
    function bundledPoster(video) {
        return VideoPoster.bundledPoster(video, designDir);
    }

    // Image consumers bind to this: the path itself, or a video's frame once it exists.
    function imageFor(path) {
        if (!path || !WallpaperFormats.isVideo(path))
            return path || "";
        const poster = posters[path];
        if (poster)
            return poster;
        request(path);
        return "";
    }

    // True while a frame for this video may still arrive.
    function framePending(path) {
        return VideoPoster.pending(WallpaperFormats.isVideo(path), bundledPoster(path), {
            "poster": posters[path],
            "ffmpegMissing": ffmpegMissing,
            "failed": _failed[path]
        });
    }

    function request(video) {
        if (!VideoPoster.mayRequest(bundledPoster(video), {
            "ffmpegMissing": ffmpegMissing,
            "queued": _queued[video],
            "failed": _failed[video],
            "poster": posters[video]
        }))
            return;
        _queued[video] = true;
        _queue.push(video);
        Qt.callLater(_next);
    }

    function _next() {
        if (_busy || _queue.length === 0)
            return;
        _busy = true;
        const video = _queue.shift();
        const poster = posterPath(video);
        const bundled = bundledPoster(video);
        // Das Skript (VideoPoster.js) nimmt zuerst das mitgelieferte Standbild; sonst behält -nt ein Bild, das neuer
        // ist als sein Video, und der Filter thumbnail überspringt schwarze Bilder am Anfang.
        Proc.runCommand("videoWallpaperPoster", ["sh", "-c", VideoPoster.script(), "sh", poster, video, bundled], (output, exitCode) => {
            delete _queued[video];
            _busy = false;
            const result = VideoPoster.outcome(exitCode, bundled);
            if (result === "bundled") {
                posters = Object.assign({}, posters, {
                    [video]: bundled
                });
                _next();
                return;
            }
            if (result === "missing") {
                // Dieses Video bekommt kein Standbild (auch ein Video des Designs ohne .jpg): als gescheitert
                // eintragen, damit framePending() nicht ewig wartet und request() es nicht erneut einstellt.
                _failed = Object.assign({}, _failed, {
                    [video]: true
                });
                ffmpegMissing = true;
                // Videos des Designs bekommen ihr mitgeliefertes Standbild trotzdem
                _queue = _queue.filter(v => bundledPoster(v) !== "");
                const kept = {};
                for (const v of _queue)
                    kept[v] = true;
                _queued = kept;
                log.warn("ffmpeg not found, video wallpapers play without a theme or thumbnail frame");
                _next();
                return;
            }
            if (result === "failed") {
                // reassigned, not mutated, so framePending() bindings see the failure
                _failed = Object.assign({}, _failed, {
                    [video]: true
                });
                log.warn("could not extract a frame from", video + ":", output.trim());
            } else {
                posters = Object.assign({}, posters, {
                    [video]: poster
                });
            }
            _next();
        }, 0, 60000);
    }
}
