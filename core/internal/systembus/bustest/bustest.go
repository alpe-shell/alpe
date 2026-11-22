// Package bustest stellt Tests einen eigenen Systembus im Temp-Ordner: einen echten dbus-daemon
// oder einen, der nie antwortet. Der echte Systembus des Rechners wird nie berührt; die Adresse
// kommt über DBUS_SYSTEM_BUS_ADDRESS aus dem Test.
package bustest

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"
)

// KurzerOrdner: Unix-Sockets dürfen höchstens 107 Zeichen lang sein; t.TempDir() ist oft länger.
func KurzerOrdner(t *testing.T) string {
	t.Helper()
	dir, err := os.MkdirTemp("", "sb")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { os.RemoveAll(dir) })
	return dir
}

// Stumm nimmt Verbindungen an. anmelden=false: der Bus sendet nie etwas. anmelden=true: er
// beantwortet die Anmeldung (AUTH) und schweigt danach auf Hello – der Fall der Ladeprüfung.
func Stumm(t *testing.T, anmelden bool) {
	t.Helper()
	sock := filepath.Join(KurzerOrdner(t), "sb")
	l, err := net.Listen("unix", sock)
	if err != nil {
		t.Fatal(err)
	}
	var mu sync.Mutex
	var verbindungen []net.Conn
	var offen sync.WaitGroup
	t.Cleanup(func() {
		l.Close()
		mu.Lock()
		for _, c := range verbindungen {
			c.Close()
		}
		mu.Unlock()
		offen.Wait()
	})
	go func() {
		for {
			c, err := l.Accept()
			if err != nil {
				return
			}
			mu.Lock()
			verbindungen = append(verbindungen, c)
			mu.Unlock()
			offen.Add(1)
			go func() {
				defer offen.Done()
				defer c.Close()
				r := bufio.NewReader(c)
				for {
					zeile, err := r.ReadString('\n')
					if err != nil {
						return
					}
					if !anmelden {
						continue
					}
					zeile = strings.TrimSpace(strings.TrimLeft(zeile, "\x00"))
					switch {
					case zeile == "AUTH":
						fmt.Fprint(c, "REJECTED EXTERNAL\r\n")
					case strings.HasPrefix(zeile, "AUTH EXTERNAL"):
						fmt.Fprint(c, "OK 0123456789abcdef0123456789abcdef\r\n")
					case zeile == "NEGOTIATE_UNIX_FD":
						fmt.Fprint(c, "ERROR\r\n")
					}
					// Nach BEGIN kommt Hello als Nachricht; darauf antwortet dieser Bus nie.
				}
			}()
		}
	}()
	t.Setenv("DBUS_SYSTEM_BUS_ADDRESS", "unix:path="+sock)
}

const richtlinie = `<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <type>system</type>
  <listen>unix:path=%s</listen>
  <auth>EXTERNAL</auth>
  <policy context="default">
    <allow user="*"/>
    <allow own="*"/>
    <allow send_destination="*"/>
    <allow send_type="signal"/>
    <allow send_requested_reply="true" send_type="method_return"/>
    <allow send_requested_reply="true" send_type="error"/>
    <allow receive_type="method_call"/>
    <allow receive_type="method_return"/>
    <allow receive_type="error"/>
    <allow receive_type="signal"/>
  </policy>
</busconfig>
`

// Echt startet einen eigenen dbus-daemon im Temp-Ordner (leer: kein logind, kein NetworkManager).
// Er beendet sich über timeout selbst; beendet wird sonst nur dieser eine Prozess. Fehlt
// dbus-daemon, wird der Test übersprungen.
func Echt(t *testing.T) {
	t.Helper()
	for _, programm := range []string{"dbus-daemon", "timeout"} {
		if _, err := exec.LookPath(programm); err != nil {
			t.Skipf("%s fehlt", programm)
		}
	}
	dir := KurzerOrdner(t)
	sock := filepath.Join(dir, "sb")
	conf := filepath.Join(dir, "systembus.conf")
	if err := os.WriteFile(conf, fmt.Appendf(nil, richtlinie, sock), 0o600); err != nil {
		t.Fatal(err)
	}
	cmd := exec.Command("timeout", "60", "dbus-daemon", "--config-file="+conf, "--nofork")
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		cmd.Process.Signal(os.Interrupt)
		cmd.Wait()
	})
	for range 50 {
		if _, err := os.Stat(sock); err == nil {
			break
		}
		time.Sleep(100 * time.Millisecond)
	}
	t.Setenv("DBUS_SYSTEM_BUS_ADDRESS", "unix:path="+sock)
}
