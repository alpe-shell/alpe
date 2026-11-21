import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const source = readFileSync(new URL("../Services/SettingsSearchService.qml", import.meta.url), "utf8");

function service() {
    const context = vm.createContext({ Object, registeredCards: {}, targetSection: "" });
    context.root = context;
    for (const match of source.matchAll(/^    function (registerCard|unregisterCard)\([^\n]*\) \{\n[\s\S]*?^    \}/gm))
        vm.runInContext(match[0], context);
    return context;
}

test("unregister with the registered card removes it", () => {
    const s = service();
    const card = { name: "a" };
    s.registerCard("key", card, null, null);
    s.unregisterCard("key", card);
    assert.equal(s.registeredCards.key, undefined);
});

test("unregister from a stale card keeps the newer card", () => {
    const s = service();
    s.registerCard("key", { name: "new" }, null, null);
    s.unregisterCard("key", { name: "old" });
    assert.equal(s.registeredCards.key.item.name, "new");
});

// Qt has already nulled `target` when a card is torn down.
test("unregister without item keeps a live card of the same key", () => {
    const s = service();
    s.registerCard("key", { name: "new" }, null, null);
    s.unregisterCard("key", null);
    assert.equal(s.registeredCards.key.item.name, "new");
});

test("unregister without item removes an entry whose card is gone", () => {
    const s = service();
    s.registerCard("key", null, null, null);
    s.unregisterCard("key", null);
    assert.equal(s.registeredCards.key, undefined);
});
