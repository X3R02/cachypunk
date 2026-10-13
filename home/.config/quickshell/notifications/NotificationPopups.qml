// Stack of notification cards at the top-right of the focused screen, under
// the bar, newest on top. The window is only as big as the cards, so the rest
// of the screen keeps its clicks.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs
import qs.services

PanelWindow {
	id: popups

	// More than this and the oldest wait off-screen until one closes
	readonly property int maxVisible: 4

	screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
	visible: Notifs.list.length > 0
	color: "transparent"
	implicitWidth: 380
	implicitHeight: stack.implicitHeight

	// Where mako put them: 20px in from the right edge and below the bar (the
	// window respects the bar's exclusive zone, so the margin starts under it)
	anchors.top: true
	anchors.right: true
	margins.top: 20
	margins.right: 20
	exclusionMode: ExclusionMode.Normal

	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.namespace: "quickshell-notifications"
	WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

	Column {
		id: stack

		width: parent.width
		spacing: 8

		Repeater {
			model: ScriptModel {
				values: Notifs.list.slice().reverse().slice(0, popups.maxVisible)
			}

			NotificationCard {}
		}
	}
}
