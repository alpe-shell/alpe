package cups

import (
	"errors"
	"os"
	"path/filepath"
	"testing"

	"github.com/alpe-shell/alpe/core/pkg/ipp"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func setUserName(t *testing.T, name string, err error) {
	t.Helper()
	old := lookupUserName
	lookupUserName = func() (string, error) { return name, err }
	t.Cleanup(func() { lookupUserName = old })
}

func markerIn(t *testing.T) string {
	// wie im Betrieb: Der Ordner ~/.local/state/alpe muss noch nicht bestehen.
	return filepath.Join(t.TempDir(), "state", "alpe", legacySubscriptionsMarker)
}

func TestCancelLegacySubscriptionsOnlyOwnOnes(t *testing.T) {
	setUserName(t, "erika", nil)
	other := []string{"job-completed"}
	fake := newFakeCUPS(t,
		fakeSubscription{id: 1, owner: "dms", events: notifyEvents(), recipient: "dbus://"},
		fakeSubscription{id: 2, owner: "dms", events: notifyEvents(), pull: "ippget"},
		fakeSubscription{id: 3, owner: "dms", events: other, recipient: "dbus://"},             // andere Ereignisse
		fakeSubscription{id: 4, owner: "erika", events: notifyEvents(), recipient: "dbus://"},  // anderer Besitzer
		fakeSubscription{id: 5, owner: "dms", events: notifyEvents(), recipient: "mailto:x@y"}, // anderer Zustellweg
		fakeSubscription{id: 6, owner: "erika", events: other, recipient: "dbus://"},           // fremdes Abonnement
	)
	marker := markerIn(t)

	n, err := cancelLegacySubscriptions(fake.client(), fake.baseURL(), marker)
	require.NoError(t, err)
	assert.Equal(t, 2, n)
	assert.Equal(t, []int{1, 2}, fake.cancelled)
	assert.Equal(t, []int{3, 4, 5, 6}, fake.remaining())
	assert.Equal(t, []string{"dms", "dms"}, fake.cancelBy, "gekündigt wird als Besitzer der alten Abonnements")
	assert.FileExists(t, marker)

	// Zweiter Start: Die Marke liegt, cupsd wird nicht mehr gefragt.
	before := fake.requestCount()
	n, err = cancelLegacySubscriptions(fake.client(), fake.baseURL(), marker)
	require.NoError(t, err)
	assert.Zero(t, n)
	assert.Equal(t, before, fake.requestCount())
}

func TestCancelLegacySubscriptionsNoneAtAll(t *testing.T) {
	setUserName(t, "erika", nil)
	fake := newFakeCUPS(t) // cupsd meldet «nicht gefunden»
	marker := markerIn(t)

	n, err := cancelLegacySubscriptions(fake.client(), fake.baseURL(), marker)
	require.NoError(t, err)
	assert.Zero(t, n)
	assert.FileExists(t, marker)
	assert.Equal(t, []int16{ipp.OperationGetSubscriptions}, fake.requests)
}

func TestCancelLegacySubscriptionsRetriesAfterFailure(t *testing.T) {
	setUserName(t, "erika", nil)
	fake := newFakeCUPS(t, fakeSubscription{id: 1, owner: "dms", events: notifyEvents(), recipient: "dbus://"})
	fake.denyAll = true
	marker := markerIn(t)

	_, err := cancelLegacySubscriptions(fake.client(), fake.baseURL(), marker)
	require.Error(t, err)
	assert.NoFileExists(t, marker, "ohne Erfolg keine Marke")

	fake.mu.Lock()
	fake.denyAll = false
	fake.mu.Unlock()
	n, err := cancelLegacySubscriptions(fake.client(), fake.baseURL(), marker)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	assert.FileExists(t, marker)
}

func TestCancelLegacySubscriptionsServerUnreachable(t *testing.T) {
	setUserName(t, "erika", nil)
	fake := newFakeCUPS(t)
	client, url := fake.client(), fake.baseURL()
	fake.server.Close()
	marker := markerIn(t)

	_, err := cancelLegacySubscriptions(client, url, marker)
	require.Error(t, err)
	assert.NoFileExists(t, marker)
}

func TestNewSubscriptionsBelongToCurrentUser(t *testing.T) {
	setUserName(t, "erika", nil)
	fake := newFakeCUPS(t)

	id, err := NewSubscriptionManager(fake.client(), fake.baseURL()).createSubscription()
	require.NoError(t, err)
	assert.Equal(t, 101, id)
	dbusManager := &DBusSubscriptionManager{client: fake.client(), baseURL: fake.baseURL()}
	id, err = dbusManager.createDBusSubscription()
	require.NoError(t, err)
	assert.Equal(t, 102, id)

	require.Len(t, fake.subs, 2)
	assert.Equal(t, fakeSubscription{id: 101, owner: "erika", pull: "ippget"}, fake.subs[0])
	assert.Equal(t, fakeSubscription{id: 102, owner: "erika", recipient: "dbus:/"}, fake.subs[1])

	// Eigene Abonnements des laufenden Benutzers rührt die Kündigung nicht an.
	fake.subs[0].events, fake.subs[1].events = notifyEvents(), notifyEvents()
	n, err := cancelLegacySubscriptions(fake.client(), fake.baseURL(), markerIn(t))
	require.NoError(t, err)
	assert.Zero(t, n)
	assert.Equal(t, []int{101, 102}, fake.remaining())
}

func TestRequestingUserNameFallback(t *testing.T) {
	setUserName(t, "", errors.New("kein Eintrag"))
	assert.Equal(t, "alpe", requestingUserName())
	setUserName(t, "", nil)
	assert.Equal(t, "alpe", requestingUserName())
	setUserName(t, "erika", nil)
	assert.Equal(t, "erika", requestingUserName())
}

func TestManagerSkipsLegacyCheckWithoutMarkerPath(t *testing.T) {
	// NewTestManager setzt keine Marke: kein Zugriff auf cupsd, kein Zugriff aufs Dateisystem.
	m := NewTestManager(nil, nil)
	m.cancelLegacySubscriptionsOnce()
	assert.Empty(t, m.legacyMarker)
}

func TestLegacyMarkerLiesInStateDir(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", filepath.Join(os.TempDir(), "zustand"))
	assert.Equal(t, filepath.Join(os.TempDir(), "zustand", "alpe", "cups-abos-1.0-gekuendigt"), legacySubscriptionsMarkerPath())
}
