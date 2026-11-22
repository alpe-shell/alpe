// Package systembus baut die eine Verbindung des Dienstes zum Systembus auf – mit Zeitgrenze.
//
// godbus kennt für den Aufbau keine Zeitgrenze: dbus.SystemBus() hält eine paketweite Sperre über
// Auth und Hello hinweg, und Hello wartet ohne Ende auf die Antwort. Ein Systembus, der nicht
// antwortet, blockierte so jeden weiteren Aufrufer im Prozess (docs/plan/dienst-systembus.md).
// Darum ruft im Dienst nichts mehr dbus.SystemBus() auf; die Verbindung kommt von hier.
//
// Grundsatz: Keine Sperre wird über einen Bus- oder Netzaufruf hinweg gehalten.
package systembus

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"sync/atomic"
	"time"

	"github.com/alpe-shell/alpe/core/internal/log"
	"github.com/godbus/dbus/v5"
)

const (
	// AufbauGrenze ist die Zeitgrenze für Verbinden, Anmelden und Hello.
	AufbauGrenze = 3 * time.Second
	// Erneute Versuche: erster Abstand, danach verdoppelt bis zum Höchstabstand, ohne Ende.
	ErsterAbstand  = 2 * time.Second
	HoechstAbstand = 60 * time.Second
)

// ErrNichtVerfuegbar meldet, dass der Systembus nicht erreichbar ist oder nicht antwortet.
var ErrNichtVerfuegbar = errors.New("system bus unavailable")

// Verbinden baut eine eigene Verbindung zum Systembus auf und gibt nach spätestens grenze auf.
//
// Der Context aus dbus.WithContext ist bei godbus die Lebensdauer der Verbindung, nicht nur die
// Frist für den Aufbau: Ein context.WithTimeout schlösse sie auch nach Erfolg. Darum ein
// abbrechbarer Context mit Timer, der nach erfolgreichem Aufbau gestoppt wird. Die Verbindung
// endet mit ctx oder mit Close().
func Verbinden(ctx context.Context, grenze time.Duration) (*dbus.Conn, error) {
	aufbau, abbrechen := context.WithCancel(ctx)
	var abgelaufen atomic.Bool
	timer := time.AfterFunc(grenze, func() {
		abgelaufen.Store(true)
		abbrechen()
	})

	conn, err := dbus.ConnectSystemBus(dbus.WithContext(aufbau))
	timer.Stop()
	if err == nil && abgelaufen.Load() {
		// Die Frist lief genau beim Erfolg ab; godbus schliesst die Verbindung gleich.
		_ = conn.Close()
		err = context.DeadlineExceeded
	}
	if err != nil {
		abbrechen()
		if abgelaufen.Load() {
			return nil, fmt.Errorf("%w: no answer within %s", ErrNichtVerfuegbar, grenze)
		}
		return nil, fmt.Errorf("%w: %v", ErrNichtVerfuegbar, err)
	}
	return conn, nil
}

// Halter hält die geteilte Verbindung des Dienstes. Sie gehört dem Halter: Wer sie bekommt,
// meldet nur eigene Signale und Match-Regeln ab und schliesst sie nie.
type Halter struct {
	Grenze         time.Duration
	ErsterAbstand  time.Duration
	HoechstAbstand time.Duration

	// Für Tests austauschbar.
	verbinden func(ctx context.Context, grenze time.Duration) (*dbus.Conn, error)
	warnen    func(format string, v ...any)
	melden    func(format string, v ...any)

	mu          sync.Mutex
	conn        *dbus.Conn
	bereit      chan struct{}
	entschieden chan struct{}
	starten     sync.Once
}

// Neu legt einen Halter mit den Fristen des Dienstes an. Er verbindet erst mit Starten.
func Neu() *Halter {
	return &Halter{
		Grenze:         AufbauGrenze,
		ErsterAbstand:  ErsterAbstand,
		HoechstAbstand: HoechstAbstand,
		verbinden:      Verbinden,
		warnen:         log.Warnf,
		melden:         log.Infof,
		bereit:         make(chan struct{}),
		entschieden:    make(chan struct{}),
	}
}

// Starten baut die Verbindung im Hintergrund auf und kehrt sofort zurück. Scheitert der Aufbau,
// gibt es genau eine Meldung und erneute Versuche mit wachsendem Abstand, bis ctx endet.
func (h *Halter) Starten(ctx context.Context) {
	h.starten.Do(func() { go h.lauf(ctx) })
}

func (h *Halter) lauf(ctx context.Context) {
	abstand := h.ErsterAbstand
	gemeldet := false
	var erster sync.Once
	defer erster.Do(func() { close(h.entschieden) })
	for {
		conn, err := h.verbinden(ctx, h.Grenze)
		if err != nil {
			erster.Do(func() { close(h.entschieden) })
		}
		if err == nil {
			h.mu.Lock()
			h.conn = conn
			h.mu.Unlock()
			if gemeldet {
				h.melden("System bus connected")
			}
			close(h.bereit)
			erster.Do(func() { close(h.entschieden) })
			return
		}
		if ctx.Err() != nil {
			return
		}
		if !gemeldet {
			gemeldet = true
			h.warnen("System bus unavailable (%v); dependent managers disabled, retrying in background", err)
		} else {
			log.Debugf("System bus still unavailable: %v", err)
		}

		select {
		case <-ctx.Done():
			return
		case <-time.After(abstand):
		}
		abstand = min(abstand*2, h.HoechstAbstand)
	}
}

// Bereit wird geschlossen, sobald die Verbindung zum ersten Mal steht.
func (h *Halter) Bereit() <-chan struct{} { return h.bereit }

// Erstversuch wartet das Ergebnis des ersten Versuchs ab (höchstens die Aufbau-Grenze) und gibt
// die Verbindung oder nil zurück. Für Manager, die auch ohne Systembus etwas leisten: Sie starten
// im Normalfall mit Verbindung und bei einem stummen Bus ohne.
func (h *Halter) Erstversuch(ctx context.Context) *dbus.Conn {
	select {
	case <-h.entschieden:
	case <-ctx.Done():
	}
	conn, _ := h.Conn()
	return conn
}

// Conn gibt die Verbindung heraus, wenn sie steht. Nach einem Abriss im Betrieb meldet Conn
// false; ein Neuaufbau der Manager gehört nicht hierher (offener Fall).
func (h *Halter) Conn() (*dbus.Conn, bool) {
	h.mu.Lock()
	conn := h.conn
	h.mu.Unlock()
	if conn == nil || !conn.Connected() {
		return nil, false
	}
	return conn, true
}

// Verlangen gibt die Verbindung heraus oder sofort ErrNichtVerfuegbar – für Aufrufe, die nicht
// warten dürfen (Anfragen der Oberfläche).
func (h *Halter) Verlangen() (*dbus.Conn, error) {
	if conn, ok := h.Conn(); ok {
		return conn, nil
	}
	return nil, ErrNichtVerfuegbar
}

// Warten blockiert, bis die Verbindung steht oder ctx endet.
func (h *Halter) Warten(ctx context.Context) (*dbus.Conn, error) {
	select {
	case <-h.bereit:
		return h.Verlangen()
	case <-ctx.Done():
		return nil, fmt.Errorf("%w: %v", ErrNichtVerfuegbar, ctx.Err())
	}
}
