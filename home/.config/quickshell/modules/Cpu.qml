// CPU usage, sampled from /proc/stat. Click opens the system panel: usage as
// a meter, temperature, clock and load, memory, GPU, the processes using the
// most CPU, and btop behind the last "Advanced" row. The figures come from
// scripts/sysinfo.sh, which looks each sensor up by name and leaves out what
// the machine doesn't have; this panel hides those rows.
import Quickshell
import Quickshell.Io
import QtQuick
import qs

Module {
	id: mod

	required property var barWindow
	required property string screenName

	readonly property string key: "cpu:" + screenName
	panelKey: key

	// -1 until two samples exist; usage needs a delta between readings
	property int usage: -1
	property var last: null
	// The latest sysinfo.sh reading, as { key: value }; tops holds the processes
	property var info: ({})
	property var tops: []

	readonly property color usageColor: usage >= 85 ? Colors.alert : usage >= 60 ? Colors.warn : Colors.accent
	readonly property real tempC: info.temp ? info.temp / 1000 : -1
	readonly property real memFraction: info.memtotal ? info.memused / info.memtotal : 0

	function gib(kb: real): string {
		return (kb / 1048576).toFixed(1);
	}

	icon: "󰻠"
	iconColor: panel.open ? Colors.accent : usage >= 85 ? Colors.alert : usage >= 60 ? Colors.warn : Colors.structure
	value: usage < 0 ? "" : usage + "%"
	tooltip: panel.open || usage < 0 ? "" : "CPU " + usage + "%"
	marked: panel.open
	onClicked: Panels.toggle(key)

	Process {
		id: stat

		command: ["head", "-n1", "/proc/stat"]
		stdout: StdioCollector {
			onStreamFinished: {
				// cpu user nice system idle iowait irq softirq steal ...
				const f = text.trim().split(/\s+/).slice(1, 9).map(Number);
				const idle = f[3] + f[4];
				const total = f.reduce((a, b) => a + b, 0);
				if (mod.last) {
					const dt = total - mod.last.total;
					if (dt > 0)
						mod.usage = Math.round(100 * (1 - (idle - mod.last.idle) / dt));
				}
				mod.last = { idle, total };
			}
		}
	}

	Process {
		id: sysinfo

		command: [Quickshell.shellDir + "/scripts/sysinfo.sh"]
		stdout: StdioCollector {
			onStreamFinished: {
				const info = {}, tops = [];
				for (const line of text.split("\n")) {
					const eq = line.indexOf("=");
					if (eq < 0)
						continue;
					const k = line.slice(0, eq), v = line.slice(eq + 1);
					if (k === "top") {
						const [name, pct] = v.split(" ");
						tops.push({ name, pct: Number(pct) });
					} else {
						info[k] = Number(v);
					}
				}
				mod.info = info;
				mod.tops = tops;
			}
		}
	}

	// Every 5 s for the bar; every 1.5 s while the panel is open, with the
	// rest of the figures read alongside
	Timer {
		interval: panel.open ? 1500 : 5000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			stat.running = true;
			if (panel.open)
				sysinfo.running = true;
		}
	}

	Panel {
		id: panel

		target: mod
		barWindow: mod.barWindow
		key: mod.key

		onOpenChanged: if (open)
			sysinfo.running = true

		// Usage: the figure and a meter under it
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
					color: mod.usageColor
				}
				BarText {
					x: 28
					anchors.verticalCenter: parent.verticalCenter
					text: "Processor"
					color: Colors.structure
				}
				BarText {
					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter
					text: mod.usage < 0 ? "" : mod.usage + "%"
					color: mod.usageColor
				}
			}

			SegmentBar {
				width: parent.width - parent.leftPadding - parent.rightPadding
				height: 5
				segments: 20
				value: Math.max(0, mod.usage) / 100
				fillColor: mod.usageColor
			}
		}

		PanelDivider {}

		// Figures: label in the structure colour, value in the accent; a row
		// the machine has no sensor for is left out
		Repeater {
			model: [
				{ label: "Temperature", value: mod.tempC >= 0 ? Math.round(mod.tempC) + " °C" : "", hot: mod.tempC >= 85 },
				{ label: "Clock", value: mod.info.freq ? (mod.info.freq / 1000).toFixed(2) + " GHz" : "", hot: false },
				{ label: "Load", value: mod.info.load !== undefined ? mod.info.load.toFixed(2) + " / " + mod.info.cores : "", hot: false },
				{ label: "Memory", value: mod.info.memtotal ? mod.gib(mod.info.memused) + " / " + mod.gib(mod.info.memtotal) + " GiB" : "", hot: mod.memFraction >= 0.9 },
				{ label: "Graphics", value: mod.info.gpu !== undefined ? mod.info.gpu + "%" : "", hot: false }
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
					// Units keep their case: GHz, GiB
					caps: false
					text: parent.modelData.value
					color: parent.modelData.hot ? Colors.alert : Colors.accent
				}
			}
		}

		PanelDivider {
			visible: mod.tops.length > 0
		}

		PanelHeading {
			visible: mod.tops.length > 0
			text: "Top processes"
		}

		// Names are free text (sentence case, fg); the share is data
		Repeater {
			model: mod.tops

			Item {
				required property var modelData

				width: Theme.panelWidth
				height: 26

				BarText {
					x: Theme.modulePadding
					width: parent.width - 120
					elide: Text.ElideRight
					anchors.verticalCenter: parent.verticalCenter
					caps: false
					text: parent.modelData.name
					color: Colors.fg
				}
				BarText {
					anchors.right: parent.right
					anchors.rightMargin: Theme.modulePadding + Theme.notchSmall / 2
					anchors.verticalCenter: parent.verticalCenter
					text: parent.modelData.pct.toFixed(1) + "%"
					color: Colors.accent
				}
			}
		}

		PanelDivider {}

		// The full tool: btop in the floating terminal
		PanelButton {
			width: Theme.panelWidth
			icon: "󰒓"
			label: "Advanced"
			onClicked: {
				Panels.close(mod.key);
				Quickshell.execDetached(["ghostty", "--class=com.floatterm", "-e", "btop"]);
			}
		}
	}
}
