// A list entry inside a Panel: an icon, a label, an optional badge glyph after
// it, and at the right either a state chip ("CONNECTED", "DEFAULT") or a
// detail (a number such as signal strength). States come from
// EntryFrame; `active` marks the item in use (the connected network, the
// default output). As in the game, the label is cyan because the entry can
// be acted on, and turns light on the active fill. Enter or a click runs
// `clicked`; Delete or a right-click runs `secondaryClicked`.
import Quickshell
import QtQuick

Item {
	id: row

	property string icon: ""
	property string label: ""
	// Free text (device and network names) reads badly in caps
	property bool caps: false
	property string badge: ""
	property string detail: ""
	property color detailColor: Colors.fg
	// A state, labelled in a chip; shown instead of the detail when set
	property string chip: ""
	property color chipColor: Colors.accent
	property bool active: false
	property bool enabled: true

	readonly property bool navigable: true
	readonly property var panelWindow: QsWindow.window
	readonly property bool hovered: panelWindow?.keyboardNav ? panelWindow.cursor === row : mouse.containsMouse

	signal clicked
	signal secondaryClicked

	function activate(): void {
		states.flash();
		clicked();
	}

	function secondary(): void {
		secondaryClicked();
	}

	implicitWidth: Theme.panelWidth
	implicitHeight: Theme.rowHeight

	EntryFrame {
		id: states

		focused: row.hovered
		active: row.active
		enabled: row.enabled
	}

	Row {
		anchors.left: parent.left
		anchors.leftMargin: Theme.modulePadding
		anchors.verticalCenter: parent.verticalCenter
		spacing: 10

		BarIcon {
			anchors.verticalCenter: parent.verticalCenter
			visible: row.icon !== ""
			text: row.icon
			color: !row.enabled ? Colors.muted : Colors.accent
		}

		BarText {
			anchors.verticalCenter: parent.verticalCenter
			// Whatever the icon, badge and detail leave free
			width: Math.min(implicitWidth, row.width - Theme.modulePadding * 2 - Theme.notchSmall / 2 - (row.icon !== "" ? 28 : 0) - (row.badge !== "" ? 28 : 0) - (row.chip !== "" ? stateChip.implicitWidth + 12 : row.detail !== "" ? detailText.implicitWidth + 12 : 0))
			elide: Text.ElideRight
			caps: row.caps
			text: row.label
			color: !row.enabled ? Colors.muted : row.active ? Colors.fg : Colors.accent
		}

		BarIcon {
			anchors.verticalCenter: parent.verticalCenter
			visible: row.badge !== ""
			text: row.badge
			color: Colors.muted
		}
	}

	BarText {
		id: detailText

		anchors.right: parent.right
		anchors.rightMargin: Theme.modulePadding + Theme.notchSmall / 2
		anchors.verticalCenter: parent.verticalCenter
		visible: row.chip === ""
		text: row.detail
		color: row.detailColor
	}

	Chip {
		id: stateChip

		anchors.right: parent.right
		anchors.rightMargin: Theme.modulePadding + Theme.notchSmall / 2
		anchors.verticalCenter: parent.verticalCenter
		text: row.chip
		tone: row.chipColor
	}

	MouseArea {
		id: mouse

		anchors.fill: parent
		hoverEnabled: true
		enabled: row.enabled
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		onEntered: row.panelWindow?.takeCursor?.(row)
		onClicked: m => m.button === Qt.RightButton ? row.secondary() : row.activate()
	}
}
