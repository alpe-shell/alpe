package brand

import "testing"

// Plan 0.8 Nr. 67: Die Kennung trägt die echte Version, auf drei Stellen ergänzt.
func TestUserAgent(t *testing.T) {
	saved := Version
	t.Cleanup(func() { Version = saved })

	for version, want := range map[string]string{
		"1.1":    "Alpe/1.1.0 (+https://github.com/alpe-shell/alpe)",
		"1.0":    "Alpe/1.0.0 (+https://github.com/alpe-shell/alpe)",
		"2":      "Alpe/2.0.0 (+https://github.com/alpe-shell/alpe)",
		"1.2.3":  "Alpe/1.2.3 (+https://github.com/alpe-shell/alpe)",
		"v1.4":   "Alpe/1.4.0 (+https://github.com/alpe-shell/alpe)",
		"dev":    "Alpe/dev (+https://github.com/alpe-shell/alpe)",
		"":       "Alpe/dev (+https://github.com/alpe-shell/alpe)",
		"1.1-rc": "Alpe/1.1-rc (+https://github.com/alpe-shell/alpe)",
	} {
		Version = version
		if got := UserAgent(); got != want {
			t.Errorf("Version %q: UserAgent() = %q, erwartet %q", version, got, want)
		}
	}
}
