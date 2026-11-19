pragma Singleton
import QtQuick
QtObject { property var procs: []; function started(p) { procs = procs.concat([p]) }
  // beantwortet alle laufenden Prozesse, deren Befehl das Muster enthält
  function answer(pattern, text, code) { let n = 0; for (const p of procs) { if (!p || !p.running || JSON.stringify(p.command).indexOf(pattern) < 0) continue; n++; if (p.stdout) { p.stdout.text = text; p.stdout.streamFinished() } p.running = false; p.exited(code || 0) } return n } }
