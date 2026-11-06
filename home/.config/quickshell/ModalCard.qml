// The game's dialog card, assembled as CDPR's guide describes it
// (STYLEGUIDE.md section 5): a solid red bracket down the left, a dark gapper
// that keeps the background from leaking through, and the cell - the body,
// with the tab on its top edge and the bottom-right corner cut. Used by
// modal dialogs (confirmations, the polkit prompt).
import QtQuick

Item {
	id: card

	default property alias content: body.data
	property real padding: 18
	property real contentWidth: 380

	readonly property real bracketWidth: 12
	readonly property real gapper: 3

	implicitWidth: Math.ceil(bracketWidth + gapper + contentWidth + padding * 2)
	implicitHeight: Math.ceil(body.childrenRect.height + padding * 2 + Theme.cardTab)

	// Opaque backing plane behind all three parts: nothing behind a modal
	// shows through it, gapper included
	Rectangle {
		anchors.fill: parent
		color: Colors.bg
	}

	NotchRect {
		id: bracket

		width: card.bracketWidth
		height: parent.height
		// Square at both ends: the guide's small notch read as a spike
		notch: 0
		fillColor: Colors.structure
		strokeColor: Colors.structure
	}

	NotchRect {
		id: cell

		x: card.bracketWidth + card.gapper
		width: parent.width - x
		height: parent.height
		notch: Theme.notch
		tabStep: Theme.cardTab
		fillColor: Qt.rgba(Colors.structure.r, Colors.structure.g, Colors.structure.b, 0.08)
		strokeColor: Colors.structure
	}

	Item {
		id: body

		x: cell.x + card.padding
		y: card.padding + Theme.cardTab
		width: card.contentWidth
		height: childrenRect.height
	}
}
