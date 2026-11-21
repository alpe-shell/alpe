.pragma library

// One shell-wide blur reach in logical px, per-compositor
var HYPRLAND_DEFAULT = 48;

function defaultReach(compositor) {
    switch (compositor) {
    case "hyprland":
        return HYPRLAND_DEFAULT;
    default:
        return 0;
    }
}

function clamp(value, min, max) {
    return Math.min(max, Math.max(min, value));
}

// Dual kawase reach is 2 * size * (2^passes - 1); passes step up so size stays small enough to avoid banding
function hyprlandBlur(reach) {
    const passes = reach <= 20 ? 1 : reach <= 60 ? 2 : reach <= 140 ? 3 : 4;
    const size = clamp(Math.round(reach / (2 * ((1 << passes) - 1))), 1, 20);
    return {
        size,
        passes
    };
}

