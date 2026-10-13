// A clickable button inside a Panel: optional icon + optional label, with the
// game's entry states (EntryFrame). Button labels are cyan, as in the game's
// BACK / NEXT; `color` overrides it for a state (muted when off, alert while
// a destructive action waits for its confirming click). The hover and the
// keyboard share the panel's one cursor.
import Quickshell
import QtQuick

Item {
	id: btn

	property string icon: ""
	property string label: ""
	property color color: Colors.accent
	property bool enabled: true
	// Buttons in one row: "left" for the first, "none" between, "right" last
	property string cut: "right"
	// The panel opens with its cursor here instead of on the first entry
	property bool preferred: false

	readonly property bool navigable: true
	readonly property var panelWindow: QsWindow.window
	// Under the panel's cursor, whether the mouse or the keyboard put it there
	readonly property bool hovered: panelWindow?.keyboardNav ? panelWindow.cursor === btn : mouse.containsMouse

	signal clicked

	function activate(): void {
		states.flash();
		clicked();
	}

	implicitWidth: row.implicitWidth + Theme.modulePadding * 2
	implicitHeight: Theme.rowHeight

	EntryFrame {
		id: states

		focused: btn.hovered
		enabled: btn.enabled
		cut: btn.cut
	}

	Row {
		id: row

		anchors.left: parent.left
		anchors.leftMargin: Theme.modulePadding
		anchors.verticalCenter: parent.verticalCenter
		spacing: 10

		BarIcon {
			anchors.verticalCenter: parent.verticalCenter
			visible: btn.icon !== ""
			text: btn.icon
			color: !btn.enabled ? Colors.muted : btn.color
		}

		BarText {
			anchors.verticalCenter: parent.verticalCenter
			visible: btn.label !== ""
			text: btn.label
			color: !btn.enabled ? Colors.muted : btn.color
		}
	}

	MouseArea {
		id: mouse

		anchors.fill: parent
		hoverEnabled: true
		enabled: btn.enabled
		onEntered: btn.panelWindow?.takeCursor(btn)
		onClicked: btn.activate()
	}
}
