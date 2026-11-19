pragma Singleton
import QtQuick
QtObject { property string shellDir: "/shell"; property int processId: 1; property var calls: []; property var screens: [{name: "DP-2", width: 3440, height: 1440}]
  // Umgebung für Seiten, die Pfade daraus bilden (ALPE_ENV als JSON überschreibt)
  property var environment: ({ "HOME": "/home/nutzer", "USER": "nutzer" })
  function env(n) { return environment[n] || "" } function execDetached(c) { calls = calls.concat([c]) } }
