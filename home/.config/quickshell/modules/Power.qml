// Session menu at the end of the bar; also opened by SUPER + CTRL + P through
// `qs ipc call panel toggle power`. Actions that end the session ask first in
// the game's confirmation dialog (confirm/ConfirmDialog.qml).
import Quickshell
import QtQuick
import qs
import qs.services

Module {
	id: mod

	required property var barWindow
	required property string screenName

	readonly property string key: "power:" + screenName
	panelKey: key

	icon: "󰐥"
	iconColor: panel.open ? Colors.accent : Colors.structure
	marked: panel.open
	onClicked: Panels.toggle(key)

	Panel {
		id: panel

		target: mod
		barWindow: mod.barWindow
		key: mod.key

		Repeater {
			model: [
				{ icon: "󰌾", label: "Lock", cmd: ["loginctl", "lock-session"] },
				{ icon: "󰤄", label: "Suspend", cmd: ["systemctl", "suspend"] },
				// Same command as SUPER + CTRL + Escape
				{ icon: "󰍃", label: "Log out", question: "Log out of this session? Open apps will close.", cmd: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"] },
				{ icon: "󰜉", label: "Restart", question: "Restart the system? Unsaved work in open apps will be lost.", cmd: ["systemctl", "reboot"] },
				{ icon: "󰐥", label: "Shut down", question: "Shut down the system? Unsaved work in open apps will be lost.", cmd: ["systemctl", "poweroff"] }
			]

			PanelButton {
				required property var modelData

				width: Theme.panelWidth
				icon: modelData.icon
				label: modelData.label
				onClicked: {
					Panels.close(mod.key);
					if (modelData.question)
						Confirm.ask(modelData.question, modelData.label, modelData.cmd);
					else
						Quickshell.execDetached(modelData.cmd);
				}
			}
		}
	}
}
