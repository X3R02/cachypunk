// Workspaces on this bar's monitor, only the ones that exist, as small cards
// in the game's list colours: selected fill with an accent number = focused,
// card with a coral number = has windows, outline only = empty, alert fill =
// urgent. Fixed-width cells so the row doesn't shift.
import Quickshell.Hyprland
import QtQuick
import qs

Row {
	id: root

	required property string screenName

	height: parent.height
	spacing: 5

	Repeater {
		// Special workspaces (scratchpad) have negative ids and stay hidden
		model: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor?.name === root.screenName).sort((a, b) => a.id - b.id)

		Item {
			id: pip

			required property var modelData
			readonly property bool focused: modelData.active
			readonly property bool occupied: modelData.toplevels.values.length > 0
			readonly property bool urgent: modelData.urgent

			// Wider on the right, text shifted left: see Module.qml
			width: 24
			height: root.height

			NotchRect {
				anchors.fill: parent
				anchors.topMargin: Theme.frameInset + 2
				anchors.bottomMargin: Theme.frameInset + 2
				notch: Theme.notchTiny
				fillColor: pip.urgent ? Colors.alert : pip.focused ? Colors.selected : mouse.containsMouse ? Qt.rgba(Colors.selected.r, Colors.selected.g, Colors.selected.b, 0.45) : pip.occupied ? Colors.bg : "transparent"
				strokeColor: pip.urgent ? Colors.alert : pip.focused ? Colors.structure : Colors.line
			}

			BarText {
				anchors.centerIn: parent
				anchors.horizontalCenterOffset: -1
				text: pip.modelData.name
				font.weight: Font.DemiBold
				font.letterSpacing: 0
				color: pip.urgent ? Colors.bg : pip.focused ? Colors.accent : pip.occupied ? Colors.structure : Colors.muted
			}

			MouseArea {
				id: mouse

				anchors.fill: parent
				hoverEnabled: true
				// A press on the bar closes any open panel, as on every segment
				onPressed: Panels.current = ""
				onClicked: pip.modelData.activate()
			}
		}
	}
}
