import QtQuick
import qs.Common
import qs.Services
import qs.Modules.ControlCenter.Widgets
import qs.Modules.ControlCenter.Details
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property bool vpnActivating: BackendNetworkService.vpnIsBusy || BackendNetworkService.activeState === "activating"
    readonly property bool vpnActivated: BackendNetworkService.connected && BackendNetworkService.activeState === "activated"

    ccWidgetIcon: "vpn_key"
    ccWidgetPrimaryText: I18n.tr("VPN", "virtual private network, widget and page title")
    ccWidgetSecondaryText: {
        if (vpnActivating)
            return I18n.tr("Connecting...");
        if (!vpnActivated)
            return I18n.tr("Disconnected");
        const names = BackendNetworkService.activeNames || [];
        if (names.length <= 1)
            return names[0] || I18n.tr("Connected");
        return names[0] + " +" + (names.length - 1);
    }
    ccWidgetIsActive: vpnActivated

    onCcWidgetToggled: BackendNetworkService.toggleVpn()

    ccDetailContent: Component {
        VpnDetailContent {}
    }
    ccExpandedContent: Component {
        CcTileActions {
            actions: BackendNetworkService.profiles.map(profile => ({
                        text: profile.name,
                        icon: "vpn_key",
                        toggle: true,
                        active: BackendNetworkService.vpnStateForUuid(profile.uuid) === "activated",
                        enabled: !BackendNetworkService.isVpnConnectingUuid(profile.uuid),
                        trigger: () => BackendNetworkService.toggle(profile.uuid)
                    }))
        }
    }
}
