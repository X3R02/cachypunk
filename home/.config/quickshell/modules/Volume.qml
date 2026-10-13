// Default output's volume; scroll steps it by 5%. Click opens the audio panel:
// output and input levels, and which device each one uses. Per-app streams
// and device profiles are wiremix's job, behind "Advanced".
import Quickshell
import QtQuick
import qs
import qs.services

Module {
	id: mod

	required property var barWindow
	required property string screenName

	readonly property string key: "volume:" + screenName
	panelKey: key
	readonly property int volume: Math.round(Audio.volume(Audio.sink) * 100)
	readonly property bool muted: Audio.muted(Audio.sink)

	icon: Audio.sinkIcon(Audio.sink)
	iconColor: panel.open ? Colors.accent : muted ? Colors.muted : Colors.structure
	value: muted ? "" : volume + "%"
	tooltip: panel.open ? "" : (Audio.name(Audio.sink) || "No output") + "  " + volume + "%"
	marked: panel.open
	onClicked: Panels.toggle(key)
	onScrolled: wheel => Audio.step(Audio.sink, wheel.angleDelta.y > 0 ? 1 : -1)

	Panel {
		id: panel

		target: mod
		barWindow: mod.barWindow
		key: mod.key

		PanelHeading {
			text: "Output"
		}

		PanelSlider {
			icon: Audio.sinkIcon(Audio.sink)
			value: Audio.volume(Audio.sink)
			off: mod.muted
			enabled: Audio.sink !== null
			onMoved: v => Audio.setVolume(Audio.sink, v)
			onToggled: Audio.toggleMute(Audio.sink)
		}

		Repeater {
			model: ScriptModel {
				values: Audio.sinks
			}

			PanelRow {
				required property var modelData

				icon: Audio.headphones(modelData) ? "󰋋" : "󰓃"
				label: Audio.shortName(modelData)
				active: modelData === Audio.sink
				chip: active ? "Default" : ""
				onClicked: Audio.setDefault(modelData)
			}
		}

		PanelDivider {}

		PanelHeading {
			text: "Input"
		}

		PanelSlider {
			icon: Audio.sourceIcon(Audio.source)
			value: Audio.volume(Audio.source)
			off: Audio.muted(Audio.source)
			enabled: Audio.source !== null
			onMoved: v => Audio.setVolume(Audio.source, v)
			onToggled: Audio.toggleMute(Audio.source)
		}

		Repeater {
			model: ScriptModel {
				values: Audio.sources
			}

			PanelRow {
				required property var modelData

				icon: "󰍬"
				label: Audio.shortName(modelData)
				active: modelData === Audio.source
				chip: active ? "Default" : ""
				onClicked: Audio.setDefault(modelData)
			}
		}

		PanelDivider {}

		PanelButton {
			width: Theme.panelWidth
			icon: "󰒓"
			label: "Advanced"
			onClicked: {
				Panels.close(mod.key);
				Quickshell.execDetached(["ghostty", "--class=com.floatterm", "-e", "wiremix"]);
			}
		}
	}
}
