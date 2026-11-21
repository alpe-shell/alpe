package main

import (
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/alpe-shell/alpe/core/internal/brand"
	"github.com/alpe-shell/alpe/core/internal/log"
)

const dmsSessionRestartExitCode = 75 // EX_TEMPFAIL

// Plan 6.8: alpe-dienst startet, stoppt oder startet nie eine systemd-Unit neu. Den bewussten
// Neustart von alpe.service übernimmt allein die CLI «alpe restart».

// runningInstances liefert die PIDs laufender Dienst-Instanzen ausser der eigenen. Zugewiesen in
// init, weil shellApp seinerseits auf refuseUnitRestart verweist.
var runningInstances func() []int

func init() {
	runningInstances = func() []int {
		var pids []int
		for _, pid := range shellApp.PIDs() {
			if pid != os.Getpid() {
				pids = append(pids, pid)
			}
		}
		return pids
	}
}

// readCgroup liefert den Inhalt von /proc/<pid>/cgroup (0 = eigener Prozess).
var readCgroup = func(pid int) string {
	path := "/proc/self/cgroup"
	if pid != 0 {
		path = fmt.Sprintf("/proc/%d/cgroup", pid)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return ""
	}
	return string(data)
}

var restartNotice io.Writer = os.Stderr

// inUnit sagt, ob ein Prozess in der Cgroup von alpe.service läuft. Umgebungsvariablen wie
// INVOCATION_ID taugen dafür nicht: Ein Terminal, das selbst als systemd-Dienst läuft, gibt sie an
// einen von Hand gestarteten Dienst weiter.
func inUnit(cgroup string) bool {
	for line := range strings.SplitSeq(strings.TrimSpace(cgroup), "\n") {
		if strings.HasSuffix(line, "/"+brand.Unit) {
			return true
		}
	}
	return false
}

// refuseUnitRestart ist der Haken für «alpe-dienst restart». Läuft eine Instanz als
// alpe.service, ändert der Befehl nichts und verweist auf «alpe restart»; sonst übernimmt der
// gewöhnliche Weg (SIGUSR1 an die eigene Instanz bzw. Start ohne systemd).
func refuseUnitRestart() (bool, error) {
	for _, pid := range runningInstances() {
		if inUnit(readCgroup(pid)) {
			fmt.Fprintf(restartNotice, "%s läuft als %s (PID %d); neu starten mit «alpe restart». Nichts geändert.\n", brand.Binary, brand.Unit, pid)
			return true, nil
		}
	}
	return false, nil
}

// noteUnmanaged meldet beim Start einmal, dass diese Instanz nicht als alpe.service läuft.
func noteUnmanaged() {
	if !inUnit(readCgroup(0)) {
		log.Infof("%s läuft nicht als %s; «alpe restart» betrifft diese Instanz nicht", brand.Binary, brand.Unit)
	}
}
