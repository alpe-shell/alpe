#!/usr/bin/env python3
"""Baut einen Baum, in dem qmllint die qs.*-Module des Shell-Codes auflösen kann."""
import os, shutil, sys, re
src = sys.argv[1]; dst = "/tmp/lint"
shutil.rmtree(dst, ignore_errors=True)
shutil.copytree(src, dst + "/qs", symlinks=False, ignore=shutil.ignore_patterns("translations", "tests", "assets", "*.wav", "*.png"))
for root, dirs, files in os.walk(dst + "/qs"):
    qml = sorted(f for f in files if f.endswith(".qml"))
    if not qml: continue
    rel = os.path.relpath(root, dst).replace(os.sep, ".")
    lines = ["module " + rel]
    for f in qml:
        head = open(os.path.join(root, f), encoding="utf-8", errors="replace").read(400)
        lines.append(("singleton " if re.search(r"^pragma Singleton", head, re.M) else "") + f[:-4] + " 1.0 " + f)
    open(os.path.join(root, "qmldir"), "w").write("\n".join(lines) + "\n")
# Quickshell-Attrappen
stubs = {
 "Quickshell": {"Singleton": "QtObject { default property list<QtObject> data }", "Scope": "QtObject { default property list<QtObject> data }",
                "ScriptModel": "QtObject { property var values }", "Ref": "QtObject { property var service; property var modules }",
                "Quickshell": None},
 "Quickshell.Io": {"Process": "QtObject { property var command; property bool running; property var stdout; property var stderr; property var environment; property string workingDirectory; signal exited(int exitCode, int exitStatus); signal started(); function signal(n) {} function write(s) {} }",
                   "StdioCollector": "QtObject { property string text; property bool waitForEnd; signal streamFinished() }",
                   "SplitParser": "QtObject { property string splitMarker; signal read(string data) }",
                   "FileView": "QtObject { property string path; property bool blockLoading; property bool blockWrites; property bool atomicWrites; property bool watchChanges; property bool printErrors; property bool preload; property bool loaded; signal fileChanged(); signal loadFailed(int error); function text() { return \"\" } function reload() {} function setText(t) {} function waitForJob() {} }"},
 "Quickshell.Services.UPower": {}, "Quickshell.Wayland": {}, "Quickshell.Widgets": {},
}
for mod, types in stubs.items():
    d = os.path.join(dst, *mod.split(".")); os.makedirs(d, exist_ok=True)
    lines = ["module " + mod]
    for name, body in types.items():
        if body is None:
            open(os.path.join(d, name + ".qml"), "w").write("pragma Singleton\nimport QtQuick\nQtObject { property string shellDir; property int processId; function env(n) { return \"\" } function execDetached(c) {} function iconPath(n, f) { return \"\" } }\n")
            lines.append("singleton %s 1.0 %s.qml" % (name, name))
        else:
            open(os.path.join(d, name + ".qml"), "w").write("import QtQuick\n" + body + "\n")
            lines.append("%s 1.0 %s.qml" % (name, name))
    open(os.path.join(d, "qmldir"), "w").write("\n".join(lines) + "\n")
print("ok")
