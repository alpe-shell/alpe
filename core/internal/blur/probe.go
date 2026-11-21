package blur

import (
	wlhelpers "github.com/alpe-shell/alpe/core/internal/wayland/client"
	client "github.com/duxlabs-dev/dux-go/wayland/client"
)

const extBackgroundEffectInterface = "ext_background_effect_manager_v1"

func ProbeSupport() (bool, error) {
	display, err := client.Connect("")
	if err != nil {
		return false, err
	}
	defer display.Context().Close()

	registry, err := display.GetRegistry()
	if err != nil {
		return false, err
	}

	found := false
	registry.SetGlobalHandler(func(e client.RegistryGlobalEvent) {
		switch e.Interface {
		case extBackgroundEffectInterface:
			found = true
		}
	})

	if err := wlhelpers.Roundtrip(display, display.Context()); err != nil {
		return false, err
	}

	return found, nil
}
