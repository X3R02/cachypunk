// Named BluetoothStatus so it doesn't shadow the Quickshell.Bluetooth singleton.
// Click opens the bluetooth panel: the adapter's power, then devices -
// connected first, then paired, then whatever a scan finds while the panel is
// open. A click connects a paired device, pairs a new one or disconnects a
// connected one; a right-click (Delete) forgets a paired device after a second
// one. Anything else is bluetui's job, behind "Advanced".
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import qs

Module {
	id: mod

	required property var barWindow
	required property string screenName

	readonly property string key: "bluetooth:" + screenName
	panelKey: key
	readonly property var adapter: Bluetooth.defaultAdapter
	readonly property bool enabled: adapter?.enabled ?? false
	readonly property var connectedDevices: enabled ? Bluetooth.devices.values.filter(d => d.connected) : []

	// Unnamed devices found by a scan are just MAC addresses: not worth a row
	readonly property var devices: {
		if (!enabled)
			return [];
		return Bluetooth.devices.values.filter(d => d.paired || d.connected || d.deviceName !== "").sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name)).slice(0, 10);
	}

	// Address of the paired device waiting for the confirming right-click
	property string armedForget: ""

	function deviceIcon(icon: string): string {
		if (/headset|headphone|audio-head/.test(icon))
			return "󰋋";
		if (/audio|speaker/.test(icon))
			return "󰓃";
		if (/mouse/.test(icon))
			return "󰍽";
		if (/keyboard/.test(icon))
			return "󰌌";
		if (/phone/.test(icon))
			return "󰏲";
		if (/gaming|joystick/.test(icon))
			return "󰊴";
		if (/computer/.test(icon))
			return "󰌢";
		return "󰂯";
	}

	function status(d): string {
		if (armedForget === d.address)
			return "Again to forget";
		if (d.pairing)
			return "Pairing";
		if (d.state === BluetoothDeviceState.Connecting)
			return "Connecting";
		if (d.state === BluetoothDeviceState.Disconnecting)
			return "Disconnecting";
		// A connected device with a battery shows the level instead (detail)
		if (d.connected)
			return d.batteryAvailable ? "" : "Connected";
		return d.paired ? "" : "Pair";
	}

	function activate(d): void {
		armedForget = "";
		if (d.connected) {
			d.disconnect();
		} else if (d.paired) {
			d.connect();
		} else {
			// Trusted, so it can reconnect by itself next time
			d.trusted = true;
			d.pair();
		}
	}

	function forget(d): void {
		if (!d.paired)
			return;
		if (armedForget !== d.address) {
			armedForget = d.address;
			return;
		}
		armedForget = "";
		d.forget();
	}

	icon: connectedDevices.length > 0 ? "󰂱" : enabled ? "󰂯" : "󰂲"
	// Lit only while something is actually connected
	iconColor: panel.open || connectedDevices.length > 0 ? Colors.accent : enabled ? Colors.structure : Colors.muted
	tooltip: panel.open ? "" : !adapter ? "No controller" : connectedDevices.length > 0 ? connectedDevices.map(d => d.name).join("\n") : enabled ? "On" : "Off"
	marked: panel.open
	onClicked: Panels.toggle(key)

	Panel {
		id: panel

		target: mod
		barWindow: mod.barWindow
		key: mod.key
		onOpenChanged: mod.armedForget = ""

		// Scan only while someone is looking at the list
		Binding {
			target: mod.adapter
			property: "discovering"
			value: panel.open
			// Only on a powered adapter: BlueZ refuses discovery otherwise
			when: mod.adapter !== null && mod.enabled
		}

		PanelButton {
			width: Theme.panelWidth
			icon: mod.enabled ? "󰂯" : "󰂲"
			label: !mod.adapter ? "No controller" : mod.enabled ? "Bluetooth on" : "Bluetooth off"
			color: mod.enabled ? Colors.accent : Colors.muted
			enabled: mod.adapter !== null && mod.adapter.state !== BluetoothAdapterState.Blocked
			onClicked: mod.adapter.enabled = !mod.adapter.enabled
		}

		PanelDivider {
			visible: mod.enabled
		}

		BarText {
			visible: mod.enabled && mod.devices.length === 0
			width: Theme.panelWidth
			height: Theme.rowHeight
			leftPadding: Theme.modulePadding
			text: "Scanning"
			color: Colors.muted
		}

		Repeater {
			// ScriptModel keeps rows alive while a scan reorders the list, so
			// the keyboard cursor stays on its device
			model: ScriptModel {
				values: mod.devices
			}

			PanelRow {
				id: row

				required property var modelData
				readonly property var device: modelData
				readonly property bool busy: device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting

				icon: mod.deviceIcon(device.icon)
				label: device.name
				active: device.connected
				chip: mod.status(device)
				chipColor: mod.armedForget === device.address ? Colors.alert : busy ? Colors.warn : device.connected ? Colors.accent : Colors.fgDim
				detail: device.connected && device.batteryAvailable ? Math.round(device.battery * 100) + "%" : ""
				onClicked: mod.activate(device)
				onSecondaryClicked: mod.forget(device)
				onHoveredChanged: if (!hovered && mod.armedForget === device.address)
					mod.armedForget = ""
			}
		}

		PanelDivider {}

		PanelButton {
			width: Theme.panelWidth
			icon: "󰒓"
			label: "Advanced"
			onClicked: {
				Panels.close(mod.key);
				Quickshell.execDetached(["ghostty", "--class=com.floatterm", "-e", "bluetui"]);
			}
		}
	}
}
