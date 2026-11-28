.pragma library

// Icons for programs without a desktop entry, one row per program family, names in lower case.
// Every program in a row shows the first of its icons the theme has, then the row's logo from assets/, then the row's
// glyph from the bundled symbol font (no file; such a process does not take a parent app's icon either).
// Icon names differ between themes, so list each spelling, best first.
const PROGRAM_ICONS = [
    {
        programs: ["alpe-dienst", "dsearch"],
        passesIcon: true,
        logo: "alpe-zeichen.svg"
    },
    {
        // Neutral glyph instead of the Hyprland mark (Plan 0.8 Nr. 143)
        programs: ["hyprland", "start-hyprland"],
        glyph: "team_dashboard"
    },
    {
        programs: ["docker", "dockerd", "docker-proxy", "docker-init", "docker-compose"],
        icons: ["docker", "docker-desktop"]
    },
    {
        programs: ["node", "npm", "npx"],
        icons: ["nodejs"]
    },
    {
        programs: ["jetbrainsd"],
        icons: ["jetbrains-toolbox"]
    }
];
