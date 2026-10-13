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

	// Backing plane behind all three parts, so the gapper reads dark
	Rectangle {
		anchors.fill: parent
		color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
	}

	// The gapper itself is fully opaque: the backing above lets 5% through,
	// and nothing behind may show between bracket and cell. Like Frame's, it
	// runs under the bracket and into the cell so no half-pixel seam is left
	Rectangle {
		width: card.bracketWidth + card.gapper + 4
		height: parent.height
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
