// Privacy: shown only while something is using the microphone, the camera or
// the screen, and gone the rest of the time, so it costs the bar no room.
// One icon per device in use, in the alert colour; the tooltip names the apps.
// Microphone and camera come from scripts/privacy.sh (every 3 s), the screen
// from Hyprland's screencast event, which every portal capture (OBS, a call
// sharing its screen) goes through.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs

Module {
	id: mod

	// Apps using each device, "" when none
	property string micApps: ""
	property string camApps: ""
	// Hyprland reports each screencast starting and stopping
	property bool screen: false

	readonly property var parts: [
		{ on: micApps !== "", icon: "󰍬", text: "Microphone: " + micApps },
		{ on: camApps !== "", icon: "󰄀", text: "Camera: " + camApps },
		{ on: screen, icon: "󰹑", text: "Screen shared" }
	].filter(p => p.on)

	visible: parts.length > 0
	icon: parts.map(p => p.icon).join(" ")
	iconColor: Colors.alert
	tooltip: parts.map(p => p.text).join("\n")

	Process {
		id: probe

		command: [Quickshell.shellDir + "/scripts/privacy.sh"]
		stdout: StdioCollector {
			onStreamFinished: {
				let mic = "", cam = "";
				for (const line of text.split("\n")) {
					if (line.startsWith("mic="))
						mic = line.slice(4);
					else if (line.startsWith("cam="))
						cam = line.slice(4);
				}
				mod.micApps = mic;
				mod.camApps = cam;
			}
		}
	}

	Timer {
		interval: 3000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: probe.running = true
	}

	// screencast>>STATE,OWNER: state 1 when a capture starts, 0 when it stops
	Connections {
		target: Hyprland

		function onRawEvent(event) {
			if (event.name === "screencast")
				mod.screen = event.data.split(",")[0] === "1";
		}
	}
}
