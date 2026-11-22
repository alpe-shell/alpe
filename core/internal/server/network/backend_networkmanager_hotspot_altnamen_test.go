package network

import (
	"testing"

	"github.com/Wifx/gonetworkmanager/v2"
	mock_gonetworkmanager "github.com/alpe-shell/alpe/core/internal/mocks/github.com/Wifx/gonetworkmanager/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Hotspot-Verbindung aus Alpe 1.0 (Plan 2.3.2, 0.8 Nr. 16): «DankMaterialShell Hotspot» mit der
// Kennung «dms-hotspot» wird erkannt und weiter benutzt; neu angelegt wird nur «Alpe Hotspot».

func legacyHotspotSettings(ssid string) gonetworkmanager.ConnectionSettings {
	return gonetworkmanager.ConnectionSettings{
		"connection": {
			"id":          "DankMaterialShell Hotspot",
			"uuid":        "0c0ffee0-1111-2222-3333-444455556666",
			"type":        "802-11-wireless",
			"autoconnect": false,
			"stable-id":   "dms-hotspot",
		},
		"802-11-wireless": {
			"mode": "ap",
			"ssid": []byte(ssid),
		},
	}
}

func TestNewHotspotProfileCarriesAlpeName(t *testing.T) {
	settings := buildHotspotSettings(HotspotRequest{SSID: "Stube"}, nil)
	assert.Equal(t, "Alpe Hotspot", settings["connection"]["id"])
	assert.Equal(t, "alpe-hotspot", settings["connection"]["stable-id"])
	assert.True(t, isManagedHotspotConnection(settings))
	assert.False(t, isLegacyHotspotConnection(settings))
}

func TestLegacyHotspotProfileIsRecognised(t *testing.T) {
	settings := legacyHotspotSettings("Stube")
	assert.True(t, isManagedHotspotConnection(settings))
	assert.True(t, isLegacyHotspotConnection(settings))
}

func TestLegacyHotspotProfileKeepsItsNameOnUpdate(t *testing.T) {
	updated := buildHotspotSettings(HotspotRequest{SSID: "Neuer Name", Password: "hunter2-password"}, legacyHotspotSettings("Stube"))
	assert.Equal(t, "DankMaterialShell Hotspot", updated["connection"]["id"])
	assert.Equal(t, "dms-hotspot", updated["connection"]["stable-id"])
	assert.Equal(t, "0c0ffee0-1111-2222-3333-444455556666", updated["connection"]["uuid"])
	assert.Equal(t, []byte("Neuer Name"), updated["802-11-wireless"]["ssid"])
}

func TestConfigureHotspotReusesLegacyProfile(t *testing.T) {
	mockNM := mock_gonetworkmanager.NewMockNetworkManager(t)
	mockSettings := mock_gonetworkmanager.NewMockSettings(t)
	mockWiFi := mock_gonetworkmanager.NewMockDeviceWireless(t)
	legacyConn := mock_gonetworkmanager.NewMockConnection(t)

	backend, err := NewNetworkManagerBackend(mockNM)
	require.NoError(t, err)
	backend.settings = mockSettings
	backend.wifiDevices = map[string]*wifiDeviceInfo{
		"wlan0": {device: mockWiFi, wireless: mockWiFi, name: "wlan0"},
	}

	existing := legacyHotspotSettings("Stube")
	req := HotspotRequest{SSID: "Stube", Password: "hunter2-password", Device: "wlan0"}
	expected := buildHotspotSettings(req, existing)
	require.Equal(t, "dms-hotspot", expected["connection"]["stable-id"])

	mockWiFi.EXPECT().GetPropertyManaged().Return(true, nil).Twice()
	mockWiFi.EXPECT().GetPropertyWirelessCapabilities().Return(nmWiFiDeviceCapAP, nil).Twice()
	mockNM.EXPECT().GetPropertyActiveConnections().Return([]gonetworkmanager.ActiveConnection{}, nil)
	mockSettings.EXPECT().ListConnections().Return([]gonetworkmanager.Connection{legacyConn}, nil)
	legacyConn.EXPECT().GetSettings().Return(existing, nil)
	// Aktualisiert wird die bestehende Verbindung; AddConnection ist nicht erwartet und liesse
	// den Test scheitern – es entsteht also kein zweites Profil.
	legacyConn.EXPECT().Update(expected).Return(nil).Once()

	require.NoError(t, backend.ConfigureHotspot(req))

	backend.stateMutex.RLock()
	defer backend.stateMutex.RUnlock()
	assert.True(t, backend.state.HotspotConfigured)
	assert.Equal(t, "Stube", backend.state.HotspotSSID)
}

func TestFindManagedHotspotConnectionPrefersAlpeProfile(t *testing.T) {
	mockNM := mock_gonetworkmanager.NewMockNetworkManager(t)
	mockSettings := mock_gonetworkmanager.NewMockSettings(t)
	legacyConn := mock_gonetworkmanager.NewMockConnection(t)
	alpeConn := mock_gonetworkmanager.NewMockConnection(t)

	backend, err := NewNetworkManagerBackend(mockNM)
	require.NoError(t, err)
	backend.settings = mockSettings

	alpeSettings := buildHotspotSettings(HotspotRequest{SSID: "Stube"}, nil)
	mockSettings.EXPECT().ListConnections().Return([]gonetworkmanager.Connection{legacyConn, alpeConn}, nil).Once()
	legacyConn.EXPECT().GetSettings().Return(legacyHotspotSettings("Alt"), nil).Once()
	alpeConn.EXPECT().GetSettings().Return(alpeSettings, nil).Once()

	conn, settings, err := backend.findManagedHotspotConnection()
	require.NoError(t, err)
	assert.Same(t, alpeConn, conn)
	assert.Equal(t, "alpe-hotspot", settings["connection"]["stable-id"])
}
