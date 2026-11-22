package version

import "testing"

func TestCompareVersions(t *testing.T) {
	tests := []struct {
		v1       string
		v2       string
		expected int
	}{
		{"v0.1.0", "v0.1.0", 0},
		{"v0.1.0", "v0.1.1", -1},
		{"v0.1.1", "v0.1.0", 1},
		{"v0.1.10", "v0.1.2", 1},
		{"1.0.0", "v1.0.0", 0},
		{"", "", 0},
		{"v1.0", "v1", 0},
		{"v1.0.1", "v1.0", 1},
	}

	for _, tt := range tests {
		result := CompareVersions(tt.v1, tt.v2)
		if result != tt.expected {
			t.Errorf("CompareVersions(%q, %q) = %d; want %d", tt.v1, tt.v2, result, tt.expected)
		}
	}
}
