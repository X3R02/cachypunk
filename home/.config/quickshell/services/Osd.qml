// What the on-screen display shows. The volume, mic and brightness keys call
// show("volume" | "mic" | "brightness") through `qs ipc call osd ...`, and the
// OSD window reads those levels live from Audio and Brightness - so a mute
// that PipeWire applies a moment later still lands on screen. Scripts send a
// one-off message with message().
pragma Singleton

import Quickshell
import QtQuick

Singleton {
	id: root

	property bool visible: false
	// "volume", "mic", "brightness" or "message"
	property string kind: ""
	// Only for messages
	property string icon: ""
	property string label: ""

	function show(kind: string): void {
		root.kind = kind;
		visible = true;
		hide.restart();
	}

	function message(icon: string, label: string): void {
		root.icon = icon;
		root.label = label;
		show("message");
	}

	Timer {
		id: hide

		interval: 1500
		onTriggered: root.visible = false
	}
}
