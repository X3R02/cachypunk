// Battery. Warning tints yellow at 20%, critical goes to the alert color at
// 10%; charging lights the accent. Click opens the battery panel: charge,
// time left, power draw, health and the charge limits TLP set, then the power
// profile (tlp-pd answers the power-profiles-daemon API that UPower's
// PowerProfiles talks to). There is no "Advanced": the only admin tool for
// this is TLP's config in /etc/tlp.d.
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import qs

Module {
	id: mod

	required property var barWindow
	required property string screenName

	readonly property string key: "battery:" + screenName
	panelKey: key
	readonly property var dev: UPower.displayDevice
	// The physical battery, for what the display device doesn't carry
	readonly property var battery: UPower.devices.values.find(d => d.isLaptopBattery) ?? null
	readonly property real fraction: dev.percentage
	readonly property int level: Math.round(fraction * 100)
	readonly property bool charging: dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged || dev.state === UPowerDeviceState.PendingCharge
	readonly property color stateColor: charging ? Colors.accent : level <= 10 ? Colors.alert : level <= 20 ? Colors.warn : Colors.structure
	readonly property string sysfs: "/sys/class/power_supply/" + (battery?.nativePath || "BAT0") + "/"

	readonly property var chargingIcons: ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
	readonly property var icons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

	readonly property var profiles: [
		{ profile: PowerProfile.PowerSaver, icon: "󰾆", label: "Power saver" },
		{ profile: PowerProfile.Balanced, icon: "󰾅", label: "Balanced" },
		{ profile: PowerProfile.Performance, icon: "󰓅", label: "Performance" }
	]

	function duration(seconds: real): string {
		const h = Math.floor(seconds / 3600), m = Math.round((seconds % 3600) / 60);
		return h + "h " + String(m).padStart(2, "0") + "m";
	}

	readonly property string stateText: {
		if (dev.state === UPowerDeviceState.FullyCharged)
			return "Full";
		if (dev.state === UPowerDeviceState.PendingCharge)
			return "Plugged in, not charging";
		const t = charging ? dev.timeToFull : dev.timeToEmpty;
		if (t <= 0)
			return charging ? "Charging" : "On battery";
		return (charging ? "Full in " : "Empty in ") + duration(t);
	}

	visible: dev.ready && dev.isLaptopBattery
	icon: (charging ? chargingIcons : icons)[Math.min(9, Math.floor(level / 10))]
	iconColor: panel.open ? Colors.accent : stateColor
	value: level + "%"
	valueColor: charging || level <= 20 ? stateColor : Colors.accent
	tooltip: panel.open ? "" : stateText
	marked: panel.open
	onClicked: Panels.toggle(key)

	// Charge limits TLP writes at boot (START/STOP_CHARGE_THRESH_BAT0)
	FileView {
		id: startThreshold

		path: mod.sysfs + "charge_control_start_threshold"
		watchChanges: true
		onFileChanged: reload()
	}

	FileView {
		id: endThreshold

		path: mod.sysfs + "charge_control_end_threshold"
		watchChanges: true
		onFileChanged: reload()
	}

	Panel {
		id: panel

		target: mod
		barWindow: mod.barWindow
		key: mod.key

		// Charge: the level as a meter, the state under it
		Column {
			width: Theme.panelWidth
			leftPadding: Theme.modulePadding
			rightPadding: Theme.modulePadding
			topPadding: 4
			bottomPadding: 6
			spacing: 6

			Item {
				width: parent.width - parent.leftPadding - parent.rightPadding
				height: Theme.rowHeight - 6

				BarIcon {
					anchors.verticalCenter: parent.verticalCenter
					text: mod.icon
					color: mod.stateColor
				}
				BarText {
					x: 28
					anchors.verticalCenter: parent.verticalCenter
					text: mod.stateText
					color: Colors.structure
				}
				BarText {
					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter
					text: mod.level + "%"
					color: mod.charging || mod.level <= 20 ? mod.stateColor : Colors.accent
				}
			}

			SegmentBar {
				width: parent.width - parent.leftPadding - parent.rightPadding
				height: 5
				segments: 20
				value: mod.fraction
				fillColor: mod.charging || mod.level <= 20 ? mod.stateColor : Colors.accent
			}
		}

		PanelDivider {}

		// Figures: label in the structure colour, value in the accent
		Repeater {
			model: [
				{ label: "Power draw", value: mod.battery && mod.battery.changeRate > 0 ? mod.battery.changeRate.toFixed(1) + " W" : "" },
				{ label: "Health", value: mod.battery?.healthSupported ? Math.round(mod.battery.healthPercentage) + "%" : "" },
				{ label: "Charge limit", value: startThreshold.loaded && endThreshold.loaded ? startThreshold.text().trim() + "–" + endThreshold.text().trim() + "%" : "" }
			].filter(f => f.value !== "")

			Item {
				required property var modelData

				width: Theme.panelWidth
				height: 26

				BarText {
					x: Theme.modulePadding
					anchors.verticalCenter: parent.verticalCenter
					text: parent.modelData.label
					color: Colors.structure
				}
				BarText {
					anchors.right: parent.right
					anchors.rightMargin: Theme.modulePadding + Theme.notchSmall / 2
					anchors.verticalCenter: parent.verticalCenter
					text: parent.modelData.value
					color: Colors.accent
				}
			}
		}

		PanelDivider {}

		PanelHeading {
			text: "Power profile"
		}

		Repeater {
			model: mod.profiles.filter(p => p.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

			PanelRow {
				required property var modelData

				icon: modelData.icon
				label: modelData.label
				caps: true
				active: PowerProfiles.profile === modelData.profile
				chip: active ? "Active" : ""
				onClicked: PowerProfiles.profile = modelData.profile
			}
		}
	}
}
