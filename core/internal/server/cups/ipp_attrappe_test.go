package cups

import (
	"bytes"
	"encoding/binary"
	"net"
	"net/http"
	"net/http/httptest"
	"strconv"
	"sync"
	"testing"

	"github.com/alpe-shell/alpe/core/pkg/ipp"
	"github.com/stretchr/testify/require"
)

// IPP-Attrappe: ein HTTP-Server, der die Abonnement-Operationen von cupsd nachbildet
// (Get-Subscriptions, Cancel-Subscription, Create-Printer-Subscriptions). Wie cupsd lässt sie
// nur den Besitzer kündigen und meldet «nicht gefunden», wenn es kein Abonnement gibt. Die
// Tests sprechen über den echten Client und das echte Drahtformat mit ihr.
type fakeSubscription struct {
	id        int
	owner     string
	events    []string
	pull      string
	recipient string
}

type fakeCUPS struct {
	t      *testing.T
	server *httptest.Server

	mu        sync.Mutex
	subs      []fakeSubscription
	nextID    int
	requests  []int16  // Operationen in der Reihenfolge des Eingangs
	cancelBy  []string // requesting-user-name jeder Kündigung
	denyAll   bool     // jede Kündigung ablehnen
	cancelled []int
}

func newFakeCUPS(t *testing.T, subs ...fakeSubscription) *fakeCUPS {
	f := &fakeCUPS{t: t, subs: subs, nextID: 100}
	f.server = httptest.NewServer(http.HandlerFunc(f.handle))
	t.Cleanup(f.server.Close)
	return f
}

func (f *fakeCUPS) baseURL() string { return f.server.URL }

func (f *fakeCUPS) client() CUPSClientInterface {
	host, portStr, err := net.SplitHostPort(f.server.Listener.Addr().String())
	require.NoError(f.t, err)
	port, err := strconv.Atoi(portStr)
	require.NoError(f.t, err)
	return ipp.NewCUPSClient(host, port, "", "", false)
}

func (f *fakeCUPS) remaining() []int {
	f.mu.Lock()
	defer f.mu.Unlock()
	ids := make([]int, 0, len(f.subs))
	for _, s := range f.subs {
		ids = append(ids, s.id)
	}
	return ids
}

func (f *fakeCUPS) requestCount() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return len(f.requests)
}

func (f *fakeCUPS) handle(w http.ResponseWriter, r *http.Request) {
	if r.Header.Get("Content-Type") != ipp.ContentTypeIPP {
		http.Error(w, "kein IPP", http.StatusBadRequest)
		return
	}
	req, err := ipp.NewRequestDecoder(r.Body).Decode(nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	f.mu.Lock()
	defer f.mu.Unlock()
	f.requests = append(f.requests, req.Operation)
	user, _ := req.OperationAttributes[ipp.AttributeRequestingUserName].(string)

	status := ipp.StatusOk
	var groups []fakeSubscription
	switch req.Operation {
	case ipp.OperationGetSubscriptions:
		if len(f.subs) == 0 {
			status = ipp.StatusErrorNotFound
		}
		groups = append(groups, f.subs...)
	case ipp.OperationCancelSubscription:
		id, _ := req.OperationAttributes["notify-subscription-id"].(int)
		f.cancelBy = append(f.cancelBy, user)
		status = ipp.StatusErrorNotFound
		for i, s := range f.subs {
			if s.id != id {
				continue
			}
			if f.denyAll || s.owner != user {
				status = ipp.StatusErrorNotAuthorized
				break
			}
			f.subs = append(f.subs[:i:i], f.subs[i+1:]...)
			f.cancelled = append(f.cancelled, id)
			status = ipp.StatusOk
			break
		}
	case ipp.OperationCreatePrinterSubscriptions:
		f.nextID++
		sub := fakeSubscription{id: f.nextID, owner: user}
		sub.pull, _ = req.SubscriptionAttributes["notify-pull-method"].(string)
		sub.recipient, _ = req.SubscriptionAttributes["notify-recipient-uri"].(string)
		f.subs = append(f.subs, sub)
		groups = []fakeSubscription{{id: sub.id}}
	default:
		status = ipp.StatusErrorBadRequest
	}

	w.Header().Set("Content-Type", ipp.ContentTypeIPP)
	_, _ = w.Write(encodeFakeResponse(f.t, status, req.RequestId, groups))
}

// encodeFakeResponse schreibt eine IPP-Antwort mit einer Abonnement-Gruppe je Eintrag.
func encodeFakeResponse(t *testing.T, status int16, reqID int32, groups []fakeSubscription) []byte {
	buf := new(bytes.Buffer)
	enc := ipp.NewAttributeEncoder(buf)
	write := func(v any) {
		if err := binary.Write(buf, binary.BigEndian, v); err != nil {
			t.Errorf("Antwort kodieren: %v", err)
		}
	}
	attr := func(name string, value any) {
		if err := enc.Encode(name, value); err != nil {
			t.Errorf("Attribut %s kodieren: %v", name, err)
		}
	}

	write(ipp.ProtocolVersionMajor)
	write(ipp.ProtocolVersionMinor)
	write(status)
	write(reqID)
	write(ipp.TagOperation)
	attr(ipp.AttributeCharset, ipp.Charset)
	attr(ipp.AttributeNaturalLanguage, ipp.CharsetLanguage)
	for _, g := range groups {
		write(ipp.TagSubscription)
		attr("notify-subscription-id", g.id)
		if g.owner != "" {
			attr("notify-subscriber-user-name", g.owner)
		}
		if len(g.events) > 0 {
			attr("notify-events", g.events)
		}
		if g.pull != "" {
			attr("notify-pull-method", g.pull)
		}
		if g.recipient != "" {
			attr("notify-recipient-uri", g.recipient)
		}
	}
	write(ipp.TagEnd)
	return buf.Bytes()
}
