import assert from "node:assert/strict";
import test from "node:test";
import { loadScript } from "./qml-script.mjs";

const Actions = loadScript(new URL("../Common/KeybindActions.js", import.meta.url));

// Kürzel aus DMS/Alpe 1.0 rufen «dms …»; sie sollen als die gleiche Alpe-Aktion gelten.
test("legacy dms shell actions read as alpe-dienst actions", () => {
    for (const [legacy, current] of [
        ["spawn dms ipc call spotlight toggle", "spawn alpe-dienst ipc call spotlight toggle"],
        ["spawn dms screenshot", "spawn alpe-dienst screenshot"],
        ["spawn dms screenshot window", "spawn alpe-dienst screenshot window"]
    ]) {
        const normalized = Actions.normalizeLegacyAction(legacy);
        assert.equal(normalized, current);
        assert.ok(Actions.isShellAction(normalized), normalized);
        assert.equal(Actions.getActionLabel(normalized, "hyprland"), Actions.getActionLabel(current, "hyprland"));
    }
});

test("other actions stay untouched", () => {
    for (const action of ["spawn dmsfoo", "spawn dms keybinds show", "spawn kitty", "workspace 1", "", undefined])
        assert.equal(Actions.normalizeLegacyAction(action), action);
});

test("every shell action uses alpe-dienst", () => {
    for (const action of Actions.getShellActions(true))
        assert.ok(!/^spawn dms /.test(action.id), action.id);
});
