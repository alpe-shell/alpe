.pragma library

// Hilfen fuer den Sport-Tab: Datum, Anzeige und Favoriten. Ohne Theme, damit die Datei rein bleibt.

const WEEKDAYS = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"];
const WEEKDAYS_LONG = ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"];
const MONTHS = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"];

function pad(n) {
    return n < 10 ? "0" + n : String(n);
}

function midnight(d) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function addDays(d, n) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);
}

function isoDate(d) {
    return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate());
}

function dayDiff(d, ref) {
    return Math.round((midnight(d).getTime() - midnight(ref).getTime()) / 86400000);
}

// "Heute", "Morgen", "Fr 21.11."
function dayLabel(d, ref) {
    const diff = dayDiff(d, ref || new Date());
    if (diff === 0)
        return "Heute";
    if (diff === -1)
        return "Gestern";
    if (diff === 1)
        return "Morgen";
    return WEEKDAYS[d.getDay()] + " " + pad(d.getDate()) + "." + pad(d.getMonth() + 1) + ".";
}

// "Mittwoch, 18. November"
function longDay(d, ref) {
    const diff = dayDiff(d, ref || new Date());
    const base = WEEKDAYS_LONG[d.getDay()] + ", " + d.getDate() + ". " + MONTHS[d.getMonth()];
    if (diff === 0)
        return "Heute · " + base;
    if (diff === 1)
        return "Morgen · " + base;
    if (diff === -1)
        return "Gestern · " + base;
    return base;
}

function clock(iso) {
    if (!iso)
        return "–";
    const d = new Date(iso);
    return pad(d.getHours()) + ":" + pad(d.getMinutes());
}

function startDay(match) {
    return match && match.start ? midnight(new Date(match.start)) : null;
}

function hasScore(match) {
    return match && (match.status === "live" || match.status === "post") && match.home.score !== "" && match.away.score !== "";
}

// Mittelteil einer Zeile: Spielstand oder Anstosszeit
function centerText(match) {
    if (hasScore(match))
        return match.home.score + " – " + match.away.score;
    if (match.status === "postponed")
        return "Versch.";
    if (match.status === "canceled")
        return "Abges.";
    if (match.timeUnknown)
        return "–:–";
    return clock(match.start);
}

// Kurztext links in der Zeile (FotMob: Minute, «HZ», «Ende»)
function statusText(match) {
    if (match.status === "live")
        return match.label || "Live";
    if (match.status === "post")
        return match.label || "Ende";
    if (match.status === "pre")
        return clock(match.start);
    return match.label || "";
}

// Kurzform fuer die schmale Statusspalte
function shortLabel(label) {
    return (label || "").replace(/(\d)\. Drittel/, "$1. Dr.").replace("Verlängerung", "Verl.").replace("Penaltyschiessen", "Pen.").replace("Unterbrochen", "Unterbr.");
}

function penaltiesText(match) {
    if (match.home && match.home.penalties !== undefined && match.away && match.away.penalties !== undefined)
        return "n.P. " + match.home.penalties + ":" + match.away.penalties;
    return "";
}

function favKey(match, side) {
    const team = match[side];
    return match.sport + ":" + team.id;
}

function teamKey(sport, team) {
    return sport + ":" + (team ? team.id : "");
}

function isFavoriteMatch(match, favorites) {
    if (!favorites || favorites.length === 0)
        return false;
    return favorites.indexOf(favKey(match, "home")) >= 0 || favorites.indexOf(favKey(match, "away")) >= 0;
}

function toggled(list, key) {
    const out = (list || []).slice();
    const at = out.indexOf(key);
    if (at >= 0)
        out.splice(at, 1);
    else
        out.push(key);
    return out;
}

// Spiele eines Wettbewerbs nach Tagen gruppieren: [{day: Date, matches: [...]}]
function groupByDay(matches) {
    const groups = [];
    let current = null;
    for (const m of matches || []) {
        const day = startDay(m);
        if (!day)
            continue;
        if (!current || current.day.getTime() !== day.getTime()) {
            current = {
                "day": day,
                "matches": []
            };
            groups.push(current);
        }
        current.matches.push(m);
    }
    return groups;
}

// Gruppe, an die die Liste beim Oeffnen springt: Live, sonst heute oder der naechste Spieltag
function focusGroup(groups, ref) {
    const today = midnight(ref || new Date()).getTime();
    for (let i = 0; i < groups.length; i++) {
        if (groups[i].matches.some(m => m.status === "live"))
            return i;
    }
    for (let i = 0; i < groups.length; i++) {
        if (groups[i].day.getTime() >= today)
            return i;
    }
    return Math.max(0, groups.length - 1);
}

function optionKey(leagueId) {
    return "liga_" + leagueId.replace(/\./g, "_");
}

function eventIcon(type, sport) {
    switch (type) {
    case "goal":
    case "penalty":
        return sport === "hockey" ? "sports_hockey" : sport === "basketball" ? "sports_basketball" : "sports_soccer";
    case "owngoal":
        return "sports_soccer";
    case "penmiss":
        return "block";
    case "sub":
        return "swap_vert";
    case "penaltymin":
        return "timer";
    case "var":
        return "videocam";
    }
    return "";
}

function formatAttendance(n) {
    if (!n)
        return "";
    return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, "’");
}

// Alpe: Reihenfolge der Wettbewerbe aus den Sport-Einstellungen (Liste von Kennungen).
// Unbekannte oder neue Wettbewerbe folgen in der Reihenfolge des Hilfsprogramms.
function ordered(leagues, order) {
    const list = (leagues || []).slice();
    if (!order || !order.length)
        return list;
    const rank = id => {
        const at = order.indexOf(id);
        return at < 0 ? 1000 + list.findIndex(l => l.id === id) : at;
    };
    return list.sort((a, b) => rank(a.id) - rank(b.id));
}

// Streaming-Link je Wettbewerb: nur http(s) gilt
function streamFor(streams, leagueId) {
    const s = (streams || {})[leagueId];
    return s && /^https?:\/\//.test(s.url || "") ? s : null;
}
