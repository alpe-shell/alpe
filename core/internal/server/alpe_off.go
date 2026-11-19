package server

// Alpe: Teile des Dienstes abschalten, die ein Rechner nicht braucht. Was in
// $XDG_CONFIG_HOME/alpe/aus steht (ein Name je Zeile, # leitet Kommentare ein),
// startet gar nicht erst: kein Speicher, keine D-Bus-Beobachter, keine Abfragen.
// Die Oberfläche behandelt einen fehlenden Teil wie fehlende Hardware.
//
// Namen: bluetooth, wellbeing, clipboard, location, trayrecovery, evdev, notifyactions

import (
	"bufio"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/duxlabs-dev/dux-shell/core/internal/log"
)

var (
	alpeOffOnce sync.Once
	alpeOffSet  map[string]bool
)

func alpeOffPath() string {
	base := os.Getenv("XDG_CONFIG_HOME")
	if base == "" {
		home, _ := os.UserHomeDir()
		base = filepath.Join(home, ".config")
	}
	return filepath.Join(base, "alpe", "aus")
}

func readAlpeOff(path string) map[string]bool {
	set := map[string]bool{}
	file, err := os.Open(path)
	if err != nil {
		return set
	}
	defer file.Close()
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if i := strings.Index(line, "#"); i >= 0 {
			line = line[:i]
		}
		if name := strings.ToLower(strings.TrimSpace(line)); name != "" {
			set[name] = true
		}
	}
	return set
}

// alpeOff meldet, ob der genannte Teil abgeschaltet ist. Gelesen wird einmal beim Start.
func alpeOff(name string) bool {
	alpeOffOnce.Do(func() {
		alpeOffSet = readAlpeOff(alpeOffPath())
		if len(alpeOffSet) > 0 {
			names := make([]string, 0, len(alpeOffSet))
			for n := range alpeOffSet {
				names = append(names, n)
			}
			log.Infof("Alpe: abgeschaltet: %s", strings.Join(names, ", "))
		}
	})
	return alpeOffSet[name]
}
