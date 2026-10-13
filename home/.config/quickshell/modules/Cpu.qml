// CPU usage, sampled from /proc/stat every 5s
import Quickshell
import Quickshell.Io
import QtQuick
import qs

Module {
	id: mod

	// -1 until two samples exist; usage needs a delta between readings
	property int usage: -1
	property var last: null

	icon: "󰻠"
	iconColor: usage >= 85 ? Colors.alert : usage >= 60 ? Colors.warn : Colors.structure
	value: usage < 0 ? "" : usage + "%"
	tooltip: usage < 0 ? "CPU" : "CPU " + usage + "%"
	onClicked: Quickshell.execDetached(["ghostty", "--class=com.floatterm", "-e", "btop"])

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

	Timer {
		interval: 5000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: stat.running = true
	}
}
