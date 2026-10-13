// Panel backlight through brightnessctl (it goes through logind, so no udev
// rule or group is needed to write it). Steps land on the 5% grid like volume,
// and never go below 5%, so stepping down can't blank the panel.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
	id: root

	readonly property int floor: 5
	// -1 until brightnessctl has answered once (or when there is no backlight)
	property int percent: -1
	readonly property bool available: percent >= 0
	// A step asked for before the first reading: the singleton is created on
	// first use, so the first key press arrives before the level is known
	property int pending: 0

	function set(target: int): void {
		const next = Math.max(floor, Math.min(100, target));
		percent = next;
		writer.command = ["brightnessctl", "-m", "set", next + "%"];
		writer.running = true;
	}

	function step(dir: int): void {
		if (!available) {
			pending = dir;
			return;
		}
		const cur = percent;
		set(dir > 0 ? Math.floor(cur / 5) * 5 + 5 : Math.ceil(cur / 5) * 5 - 5);
	}

	// "amdgpu_bl1,backlight,cur,37%,max" -> 37
	function parse(text: string): void {
		const field = text.trim().split("\n")[0]?.split(",")[3] ?? "";
		const n = parseInt(field);
		if (isNaN(n))
			return;
		percent = n;
		if (pending !== 0) {
			const dir = pending;
			pending = 0;
			step(dir);
		}
	}

	Process {
		running: true
		command: ["brightnessctl", "-m", "-c", "backlight", "info"]
		stdout: StdioCollector {
			onStreamFinished: root.parse(text)
		}
	}

	Process {
		id: writer

		stdout: StdioCollector {
			onStreamFinished: root.parse(text)
		}
	}
}
