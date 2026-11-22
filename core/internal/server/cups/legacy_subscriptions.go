package cups

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"time"

	"github.com/alpe-shell/alpe/core/internal/brand"
	"github.com/alpe-shell/alpe/core/internal/log"
	"github.com/alpe-shell/alpe/core/internal/utils"
	"github.com/alpe-shell/alpe/core/pkg/ipp"
)

// Abonnements aus Alpe 1.0 (Plan 2.3.3, 0.8 Nr. 22 und 30). Bis 1.0 gehörten die Abonnements des
// Dienstes bei cupsd dem Besitzer «dms», teils ohne Ablauf. Der Dienst kündigt sie genau einmal:
// nur Abonnements dieses Besitzers, deren Ereignisliste und Zustellweg denen des Dienstes
// entsprechen. Danach liegt eine Marke im Zustandsordner, und cupsd wird dazu nicht mehr gefragt.
// Fällt weg, sobald der Umzug von 1.0 nicht mehr unterstützt wird.
const (
	legacyRequestingUserName  = "dms"
	legacySubscriptionsMarker = "cups-abos-1.0-gekuendigt"
)

func legacySubscriptionsMarkerPath() string {
	return filepath.Join(utils.XDGStateHome(), brand.DirName, legacySubscriptionsMarker)
}

type legacySubscription struct {
	id        int
	owner     string
	events    []string
	pull      string
	recipient string
}

// isOurs: Besitzer «dms», genau unsere Ereignisse, Zustellung über ippget oder D-Bus.
func (s legacySubscription) isOurs() bool {
	if s.owner != legacyRequestingUserName || s.id == 0 {
		return false
	}
	if s.pull != "ippget" && !strings.HasPrefix(s.recipient, "dbus:") {
		return false
	}
	got := slices.Clone(s.events)
	want := notifyEvents()
	slices.Sort(got)
	slices.Sort(want)
	return slices.Equal(slices.Compact(got), want)
}

func attributeStrings(attrs ipp.Attributes, name string) []string {
	var out []string
	for _, attr := range attrs[name] {
		if s, ok := attr.Value.(string); ok {
			out = append(out, s)
		}
	}
	return out
}

func firstString(values []string) string {
	if len(values) == 0 {
		return ""
	}
	return values[0]
}

func listSubscriptions(client CUPSClientInterface, baseURL string) ([]legacySubscription, error) {
	req := ipp.NewRequest(ipp.OperationGetSubscriptions, 1)
	req.OperationAttributes[ipp.AttributePrinterURI] = fmt.Sprintf("%s/", baseURL)
	req.OperationAttributes[ipp.AttributeRequestingUserName] = requestingUserName()
	req.OperationAttributes[ipp.AttributeRequestedAttributes] = []string{
		"notify-subscription-id",
		"notify-subscriber-user-name",
		"notify-events",
		"notify-pull-method",
		"notify-recipient-uri",
	}

	resp, err := client.SendRequest(fmt.Sprintf("%s/", baseURL), req, nil)
	if err == nil {
		err = resp.CheckForErrors()
	}
	if err != nil {
		// cupsd meldet «nicht gefunden», wenn es kein Abonnement gibt.
		var ippErr ipp.IPPError
		if errors.As(err, &ippErr) && ippErr.Status == ipp.StatusErrorNotFound {
			return nil, nil
		}
		return nil, err
	}

	var subs []legacySubscription
	for _, attrs := range resp.SubscriptionAttributes {
		sub := legacySubscription{
			owner:     firstString(attributeStrings(attrs, "notify-subscriber-user-name")),
			events:    attributeStrings(attrs, "notify-events"),
			pull:      firstString(attributeStrings(attrs, "notify-pull-method")),
			recipient: firstString(attributeStrings(attrs, "notify-recipient-uri")),
		}
		if ids := attrs["notify-subscription-id"]; len(ids) > 0 {
			if id, ok := ids[0].Value.(int); ok {
				sub.id = id
			}
		}
		subs = append(subs, sub)
	}
	return subs, nil
}

// cancelLegacySubscriptions gibt zurück, wie viele Abonnements gekündigt wurden. Ohne Fehler
// liegt danach die Marke; bei einem Fehler (cupsd nicht erreichbar, Kündigung abgelehnt) bleibt
// sie weg, und der nächste Start versucht es wieder.
func cancelLegacySubscriptions(client CUPSClientInterface, baseURL, markerPath string) (int, error) {
	if markerPath == "" {
		return 0, nil
	}
	if _, err := os.Stat(markerPath); err == nil {
		return 0, nil
	}

	subs, err := listSubscriptions(client, baseURL)
	if err != nil {
		return 0, fmt.Errorf("Abonnements abfragen: %w", err)
	}

	cancelled := 0
	var failed error
	for _, sub := range subs {
		if !sub.isOurs() {
			continue
		}
		req := ipp.NewRequest(ipp.OperationCancelSubscription, 1)
		req.OperationAttributes[ipp.AttributePrinterURI] = fmt.Sprintf("%s/", baseURL)
		// cupsd lässt nur den Besitzer kündigen, darum hier – und nur hier – der alte Name.
		req.OperationAttributes[ipp.AttributeRequestingUserName] = legacyRequestingUserName
		req.OperationAttributes["notify-subscription-id"] = sub.id

		resp, err := client.SendRequest(fmt.Sprintf("%s/", baseURL), req, nil)
		if err == nil {
			err = resp.CheckForErrors()
		}
		if err != nil {
			failed = errors.Join(failed, fmt.Errorf("Abonnement %d kündigen: %w", sub.id, err))
			continue
		}
		cancelled++
	}
	if failed != nil {
		return cancelled, failed
	}

	if err := os.MkdirAll(filepath.Dir(markerPath), 0o755); err != nil {
		return cancelled, err
	}
	note := fmt.Sprintf("%s: %d Abonnement(e) des Besitzers %q gekündigt\n", time.Now().Format(time.RFC3339), cancelled, legacyRequestingUserName)
	if err := os.WriteFile(markerPath, []byte(note), 0o644); err != nil {
		return cancelled, err
	}
	return cancelled, nil
}

func (m *Manager) cancelLegacySubscriptionsOnce() {
	m.legacyOnce.Do(func() {
		if m.legacyMarker == "" {
			return
		}
		n, err := cancelLegacySubscriptions(m.client, m.baseURL, m.legacyMarker)
		switch {
		case err != nil:
			log.Warnf("[CUPS] Abonnements aus 1.0: %v", err)
		case n > 0:
			log.Infof("[CUPS] %d Abonnement(e) aus 1.0 gekündigt", n)
		}
	})
}
