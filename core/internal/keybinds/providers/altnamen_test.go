package providers

import "testing"

// Kürzel aus Alpe 1.0 rufen «dms ipc …» auf; bis zum Umzug stehen sie bei den eigenen Kürzeln.
func TestLegacyShellBindsSortWithOwnBinds(t *testing.T) {
	h := &HyprlandProvider{}
	for _, action := range []string{"exec alpe-dienst ipc call notepad toggle", "exec dms ipc call notepad toggle"} {
		if got := h.getBindSortPriority(action); got != 0 {
			t.Errorf("%q: Rang %d, erwartet 0", action, got)
		}
	}
	if got := h.getBindSortPriority("exec firefox"); got == 0 {
		t.Error("fremde Befehle gehören nicht zu den eigenen Kürzeln")
	}
}
