// One bar segment: optional icon + optional value. Hover lights a card behind
// the segment in the game's selection colours; `marked` (meaning "active")
// holds it at full strength and turns the icon to the accent, as a selected
// row does in the game's menus. The card is inset from the bar's top and
// bottom, so the edge line is never covered.
import QtQuick

Item {
	id: mod

	default property alias content: row.data
	property string icon: ""
	property string value: ""
	property color iconColor: Colors.structure
	property color valueColor: Colors.accent
	property bool marked: false
	property color markColor: Colors.structure

	property string tooltip: ""
	property Component tooltipContent: null
	// Panels.current key of this segment's own panel, "" when it has none. A
	// press anywhere on the bar closes whichever panel is open, except this
	// segment's own: its click then toggles it, so clicking the same icon
	// closes it and clicking another switches straight to that panel.
	property string panelKey: ""

	readonly property bool hovered: mouse.containsMouse

	signal clicked(var mouse)
	signal scrolled(var wheel)

	implicitHeight: Theme.contentHeight
	// Extra room on the right for the cut corner: the cut takes area out of
	// the bottom-right, so text centred on the full width reads as off-centre
	implicitWidth: row.implicitWidth + Theme.modulePadding * 2 + Theme.notchSmall / 2

	NotchRect {
		anchors.fill: parent
		anchors.topMargin: Theme.frameInset
		anchors.bottomMargin: Theme.frameInset
		notch: Theme.notchSmall
		visible: opacity > 0
		opacity: mod.marked || mod.hovered ? 1 : 0
		fillColor: Qt.rgba(Colors.selected.r, Colors.selected.g, Colors.selected.b, mod.marked ? 1 : 0.45)
		strokeColor: Qt.rgba(mod.markColor.r, mod.markColor.g, mod.markColor.b, mod.marked ? 1 : 0.5)

		Behavior on opacity {
			NumberAnimation {
				duration: 100
			}
		}
	}

	MouseArea {
		id: mouse

		anchors.fill: parent
		hoverEnabled: true
		acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
		onPressed: if (Panels.current !== "" && Panels.current !== mod.panelKey)
			Panels.current = ""
		onClicked: m => mod.clicked(m)
		onWheel: w => mod.scrolled(w)
	}

	// After the MouseArea so children that handle their own input (tray icons)
	// sit on top of it
	Row {
		id: row

		anchors.centerIn: parent
		anchors.horizontalCenterOffset: -Theme.notchSmall / 4
		spacing: 6

		BarIcon {
			anchors.verticalCenter: parent.verticalCenter
			visible: mod.icon !== ""
			text: mod.icon
			color: mod.marked ? Colors.accent : mod.iconColor
		}

		BarText {
			anchors.verticalCenter: parent.verticalCenter
			visible: mod.value !== ""
			text: mod.value
			color: mod.valueColor
		}
	}

	Tooltip {
		target: mod
		show: mod.hovered && (mod.tooltip !== "" || mod.tooltipContent !== null)
		text: mod.tooltip
		contentComponent: mod.tooltipContent
	}
}
