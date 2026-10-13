// Wired wins over wifi, like NetworkManager's own default route. Click opens
// the wifi panel (also SUPER + CTRL + W through `qs ipc call panel toggle network`):
// the networks in range, strongest first. A click connects to a saved or open
// network, asks for the password of a new one, or disconnects the current one;
// a right-click (Delete on the keyboard) forgets a saved network after a
// second one. "Advanced" opens NetworkManager's connection editor.
import Quickshell
import Quickshell.Networking
import QtQuick
import qs

Module {
	id: mod

	required property var barWindow
	required property string screenName

	readonly property string key: "network:" + screenName
	panelKey: key

	readonly property var devices: Networking.devices.values
	readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
	readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
	readonly property var wifi: wifiDevice && wifiDevice.connected ? wifiDevice : null
	readonly property var wifiNet: wifi ? wifi.networks.values.find(n => n.connected) ?? null : null
	readonly property int signal: wifiNet ? Math.round(wifiNet.signalStrength * 100) : 0

	readonly property var wifiIcons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

	// Connected first, then saved, then by signal; hidden networks (no name)
	// can't be picked from a list
	readonly property var networks: {
		if (!wifiDevice || !Networking.wifiEnabled)
			return [];
		return wifiDevice.networks.values.filter(n => n.name !== "").sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength)).slice(0, 10);
	}

	// Name of the network showing the password field, "" when none
	property string asking: ""
	// Name of the saved network waiting for the confirming right-click
	property string armedForget: ""
	// Last failure, shown under the network it belongs to
	property string failedName: ""
	property string failedText: ""

	function signalIcon(strength: real): string {
		return wifiIcons[Math.min(4, Math.floor(strength * 5))];
	}

	function secured(net): bool {
		return net.security !== WifiSecurityType.Open && net.security !== WifiSecurityType.Owe;
	}

	function failText(reason): string {
		switch (reason) {
		case ConnectionFailReason.NoSecrets:
		case ConnectionFailReason.WifiClientFailed:
			return "Wrong password";
		case ConnectionFailReason.WifiAuthTimeout:
			return "Timed out";
		case ConnectionFailReason.WifiNetworkLost:
			return "Network lost";
		default:
			return "Could not connect";
		}
	}

	function activate(net): void {
		armedForget = "";
		failedName = "";
		if (net.connected) {
			net.disconnect();
		} else if (net.known || !secured(net)) {
			asking = "";
			net.connect();
		} else {
			asking = asking === net.name ? "" : net.name;
		}
	}

	function forget(net): void {
		if (!net.known)
			return;
		if (armedForget !== net.name) {
			armedForget = net.name;
			return;
		}
		armedForget = "";
		net.forget();
	}

	icon: wired ? "󰀂" : wifiNet ? wifiIcons[Math.min(4, Math.floor(signal / 20))] : "󰖪"
	iconColor: panel.open ? Colors.accent : wired || wifiNet ? Colors.structure : Colors.alert
	tooltip: panel.open ? "" : wired ? "Wired" : wifiNet ? wifiNet.name + "  " + signal + "%" : "Disconnected"
	marked: panel.open
	onClicked: Panels.toggle(key)

	Panel {
		id: panel

		target: mod
		barWindow: mod.barWindow
		key: mod.key
		onOpenChanged: {
			mod.asking = "";
			mod.armedForget = "";
			mod.failedName = "";
		}

		// Scan only while someone is looking at the list
		Binding {
			target: mod.wifiDevice
			property: "scannerEnabled"
			value: panel.open
			when: mod.wifiDevice !== null
		}

		PanelButton {
			width: Theme.panelWidth
			icon: Networking.wifiEnabled ? "󰖩" : "󰖪"
			label: Networking.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
			color: Networking.wifiEnabled ? Colors.accent : Colors.muted
			enabled: Networking.wifiHardwareEnabled
			onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
		}

		PanelDivider {}

		BarText {
			visible: Networking.wifiEnabled && mod.networks.length === 0
			width: Theme.panelWidth
			leftPadding: Theme.modulePadding
			height: Theme.rowHeight
			text: "Scanning"
			color: Colors.muted
		}

		Repeater {
			// ScriptModel keeps each row alive while a rescan reorders the
			// list, so the keyboard cursor stays on its network
			model: ScriptModel {
				values: mod.networks
			}

			Column {
				id: entry

				required property var modelData
				readonly property var net: modelData
				// Direction comes from `state`: `connected` drops as soon as a
				// disconnect starts, which made it read as "Connecting"
				readonly property bool busy: net.stateChanging
				readonly property bool asking: mod.asking === net.name

				width: Theme.panelWidth

				Connections {
					target: entry.net

					function onConnectionFailed(reason): void {
						mod.failedName = entry.net.name;
						mod.failedText = mod.failText(reason);
						if (!entry.net.known && mod.secured(entry.net))
							mod.asking = entry.net.name;
					}

					function onConnectedChanged(): void {
						if (entry.net.connected && mod.asking === entry.net.name)
							mod.asking = "";
					}
				}

				PanelRow {
					id: row

					width: parent.width
					icon: mod.signalIcon(entry.net.signalStrength)
					label: entry.net.name
					badge: mod.secured(entry.net) ? (entry.net.known ? "󰌾" : "󰍁") : ""
					active: entry.net.connected
					// A state chip where there is a state, the signal otherwise
					chip: mod.armedForget === entry.net.name ? "Again to forget" : entry.busy ? (entry.net.state === ConnectionState.Disconnecting ? "Disconnecting" : "Connecting") : entry.net.connected ? "Connected" : ""
					chipColor: mod.armedForget === entry.net.name ? Colors.alert : entry.busy ? Colors.warn : Colors.accent
					detail: Math.round(entry.net.signalStrength * 100) + "%"
					detailColor: Colors.fgDim
					onClicked: mod.activate(entry.net)
					onSecondaryClicked: mod.forget(entry.net)
					onHoveredChanged: if (!hovered && mod.armedForget === entry.net.name)
						mod.armedForget = ""
				}

				BarText {
					visible: mod.failedName === entry.net.name
					leftPadding: Theme.modulePadding + 25
					height: 22
					text: mod.failedText
					color: Colors.alert
				}

				// Password for a network that isn't saved yet; Enter connects,
				// Escape closes the field
				Item {
					visible: entry.asking
					width: parent.width
					height: visible ? 36 : 0

					NotchRect {
						id: field

						anchors.fill: parent
						anchors.leftMargin: Theme.modulePadding + 25
						anchors.rightMargin: Theme.modulePadding
						anchors.topMargin: 3
						anchors.bottomMargin: 3
						notch: Theme.notchTiny
						fillColor: Colors.bg
						strokeColor: input.activeFocus ? Colors.accent : Colors.line

						TextInput {
							id: input

							anchors.fill: parent
							anchors.leftMargin: 8
							anchors.rightMargin: 8
							verticalAlignment: TextInput.AlignVCenter
							echoMode: TextInput.Password
							passwordCharacter: "•"
							color: Colors.accent
							selectionColor: Colors.selected
							font.family: Theme.textFont
							font.pixelSize: Theme.textSize
							font.weight: Font.DemiBold
							font.hintingPreference: Font.PreferNoHinting
							renderType: Text.NativeRendering
							clip: true

							onVisibleChanged: {
								text = "";
								if (visible)
									forceActiveFocus();
							}
							onAccepted: {
								if (text === "")
									return;
								mod.failedName = "";
								entry.net.connectWithPsk(text);
								text = "";
								panel.refocus();
							}
							Keys.onEscapePressed: {
								mod.asking = "";
								panel.refocus();
							}

							BarText {
								anchors.verticalCenter: parent.verticalCenter
								visible: input.text === ""
								caps: false
								text: "Password"
								color: Colors.muted
							}
						}
					}
				}
			}
		}

		PanelDivider {}

		// VPNs, static addresses, hidden networks: everything the list doesn't cover
		PanelButton {
			width: Theme.panelWidth
			icon: "󰒓"
			label: "Advanced"
			onClicked: {
				Panels.close(mod.key);
				Quickshell.execDetached(["nm-connection-editor"]);
			}
		}
	}
}
