package windowrules

import "strings"

type RuleStore interface {
	EnsureWritable() error
	LoadShellRules() ([]WindowRule, error)
	WriteShellRules([]WindowRule) error
}

const OpaqueRuleID = "alpe-window-opaque"

// legacyRuleIDs: IDs der eigenen Regeln bis Alpe 1.0. Sie stehen in windowrules.lua der Nutzer und
// werden beim Lesen auf die heutigen abgebildet (bis zum Umzug von 1.0, Plan 2.3.3).
var legacyRuleIDs = map[string]string{
	"dms-window-opaque":    OpaqueRuleID,
	"dms-floating-windows": "alpe-floating-windows",
}

// CurrentRuleID gibt zu einer ID aus einer Datei von 1.0 die heutige zurück, sonst die ID selbst.
func CurrentRuleID(id string) string {
	if current, ok := legacyRuleIDs[strings.TrimSpace(id)]; ok {
		return current
	}
	return id
}

// pinShellRules puts the opaque rule last, since compositors apply rules in
// order and the last match wins.
func pinShellRules(rules []WindowRule) []WindowRule {
	var rest, last []WindowRule
	for _, rule := range rules {
		if rule.ID == OpaqueRuleID {
			last = append(last, rule)
		} else {
			rest = append(rest, rule)
		}
	}
	return append(rest, last...)
}

func Set(store RuleStore, rule WindowRule) error {
	if err := store.EnsureWritable(); err != nil {
		return err
	}
	rules, err := store.LoadShellRules()
	if err != nil {
		rules = []WindowRule{}
	}

	for i, existing := range rules {
		if existing.ID != rule.ID {
			continue
		}
		rules[i] = rule
		return store.WriteShellRules(pinShellRules(rules))
	}

	return store.WriteShellRules(pinShellRules(append(rules, rule)))
}

func Remove(store RuleStore, id string) error {
	if err := store.EnsureWritable(); err != nil {
		return err
	}
	rules, err := store.LoadShellRules()
	if err != nil {
		return err
	}

	kept := make([]WindowRule, 0, len(rules))
	for _, rule := range rules {
		if rule.ID == id {
			continue
		}
		kept = append(kept, rule)
	}

	return store.WriteShellRules(pinShellRules(kept))
}

func Reorder(store RuleStore, ids []string) error {
	if err := store.EnsureWritable(); err != nil {
		return err
	}
	rules, err := store.LoadShellRules()
	if err != nil {
		return err
	}

	wanted := make(map[string]int, len(ids))
	for position, id := range ids {
		if _, seen := wanted[id]; seen {
			continue
		}
		wanted[id] = position
	}

	ordered := make([]WindowRule, len(ids))
	placed := make([]bool, len(ids))
	leftover := make([]WindowRule, 0, len(rules))
	for _, rule := range rules {
		position, ok := wanted[rule.ID]
		if !ok || placed[position] {
			leftover = append(leftover, rule)
			continue
		}
		ordered[position] = rule
		placed[position] = true
	}

	result := make([]WindowRule, 0, len(rules))
	for position, rule := range ordered {
		if !placed[position] {
			continue
		}
		result = append(result, rule)
	}

	return store.WriteShellRules(pinShellRules(append(result, leftover...)))
}
