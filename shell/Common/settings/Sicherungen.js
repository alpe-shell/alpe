.pragma library

// Alpe (Plan 0.8 Nr. 57): Sicherungen aus 1.0 werden nie umbenannt, gelöscht oder verändert.
// Gelesen wird der neue Name und, wenn es ihn nicht gibt, der alte; wo die Shell eine Sicherung
// verbraucht, arbeitet sie auf einer Kopie unter dem neuen Namen. Den alten Namen räumt erst
// das Ende des Umzugs von 1.0 ab. Die Skripte stehen hier, damit tests/test_sicherungen.mjs
// genau das ausführt, was die Shell ausführt.

var GTK_THEME = "gtk-theme.alpe-backup";
var GTK_THEME_1_0 = "gtk-theme.dms-backup";
var ICON_THEME = "icon-theme.alpe-backup";
var ICON_THEME_1_0 = "icon-theme.dms-backup";
// Marke im Zustandsordner: Die Sicherung aus 1.0 ist einmal übernommen worden.
var ICON_THEME_MARKER = "sicherung-1.0-icon-theme.uebernommen";

function quote(arg) {
    return "'" + String(arg).replace(/'/g, "'\\''") + "'";
}

// GTK-Thema: Die Sicherung wird nur geschrieben, die Shell liest sie nie zurück. Es genügt darum
// zu wissen, ob es eine gibt – unter dem neuen oder dem alten Namen. `cur` ist im Skript gesetzt.
function gtkThemeBackupStep(configDir) {
    const current = quote(`${configDir}/gtk-3.0/${GTK_THEME}`);
    const legacy = quote(`${configDir}/gtk-3.0/${GTK_THEME_1_0}`);
    return `{ [ -e ${current} ] || [ -e ${legacy} ]; } || printf '%s\\n' "$cur" > ${current}`;
}

// Symbolthema: Die Sicherung wird beim Zurückgeben verbraucht (gelesen und gelöscht). Die
// Sicherung aus 1.0 wird darum genau einmal unter den neuen Namen kopiert; die Marke verhindert,
// dass sie nach dem Verbrauch der Kopie ein zweites Mal gilt (auch wenn es den neuen Namen schon
// gab). Setzt `b` auf den neuen Namen.
function iconThemeAdopt(configDir, stateDir) {
    const current = quote(`${configDir}/gtk-3.0/${ICON_THEME}`);
    const legacy = quote(`${configDir}/gtk-3.0/${ICON_THEME_1_0}`);
    const marker = quote(`${stateDir}/${ICON_THEME_MARKER}`);
    return `b=${current}; if [ ! -e ${marker} ] && [ -e ${legacy} ]; then mkdir -p "$(dirname "$b")" "$(dirname ${marker})" && { [ -e "$b" ] || cp -p ${legacy} "$b"; } && : > ${marker}; fi; `;
}

// Gibt «restore:<Thema>» aus, wenn die Sicherung zurückkommt, sonst das aktuelle Thema.
function iconThemeRestoreScript(configDir, stateDir, currentCmd, lastApplied) {
    return `${iconThemeAdopt(configDir, stateDir)}cur=$(${currentCmd}); if saved=$(cat "$b" 2>/dev/null); then rm -f "$b"; [ "$cur" = ${quote(lastApplied)} ] && { printf 'restore:%s' "$saved"; exit 0; }; fi; printf '%s' "$cur"`;
}

// Sichert das aktuelle Thema, bevor Alpe ein eigenes setzt; eine bestehende Sicherung bleibt.
function iconThemeBackupScript(configDir, stateDir, currentCmd, resolved) {
    return `${iconThemeAdopt(configDir, stateDir)}[ -e "$b" ] && exit 0; cur=$(${currentCmd}); case "$cur" in ''|${quote(resolved)}) ;; *) mkdir -p "$(dirname "$b")" && printf '%s\\n' "$cur" > "$b" ;; esac`;
}
