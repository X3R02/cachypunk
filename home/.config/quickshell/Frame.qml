// The surface of every popup (panels and tooltips), assembled as CDPR's guide
// describes the game's cells (STYLEGUIDE.md section 5): a thin bracket down
// the left, a dark gapper that stops the background leaking through, and the
// cell - tab on the top edge, bottom-right corner cut - over faint
// scanlines. `simple` drops bracket and tab, leaving the plain card: one
// frame, only the corner cut. `headerHeight` lowers the cell by that much
// and flattens its top edge, leaving room above for a Panel's PanelTabs,
// which then stand in for the card's tab.
// Sizes are rounded up to whole pixels: at fractional scales a fractional
// edge put the 1px border on a half pixel, where it could vanish.
import QtQuick

Item {
	id: frame

	default property alias content: body.data
	property real padding: Theme.panelPadding
	// Alert for urgent popups
	property color strokeColor: Colors.line
	property real strokeWidth: Theme.borderWidth
	// 0 = all four corners square
	property real notch: Theme.notch
	property bool simple: false
	// Room above the cell for PanelTabs; the cell's own tab is dropped then
	property real headerHeight: 0

	readonly property real tab: simple || headerHeight > 0 ? 0 : Theme.cardTab
	// Bracket width plus the gapper after it; the cell starts there
	readonly property real cellX: simple ? 0 : Theme.bracketWidth + Theme.gapperWidth

	implicitWidth: Math.ceil(body.childrenRect.width + padding * 2 + cellX)
	implicitHeight: Math.ceil(body.childrenRect.height + padding * 2 + tab + headerHeight)

	// The gapper: an opaque plane under the gap so nothing behind shows
	// through it. It starts under the bracket and runs a few px into the cell:
	// at fractional scales the gap's edges fall on half pixels, and a plane
	// cut exactly to the gap left a see-through seam beside the bracket
	Rectangle {
		visible: !frame.simple
		width: frame.cellX + 4
		height: parent.height
		color: Colors.bg
	}

	NotchRect {
		id: bracket

		visible: !frame.simple
		width: Theme.bracketWidth
		height: parent.height
		// Square at both ends: the guide's small notch read as a spike
		notch: 0
		fillColor: Colors.line
		strokeColor: frame.strokeColor
		strokeWidth: frame.strokeWidth
	}

	NotchRect {
		id: cell

		x: frame.cellX
		y: frame.headerHeight
		width: parent.width - x
		height: parent.height - y
		fillColor: Colors.bg
		strokeColor: frame.strokeColor
		strokeWidth: frame.strokeWidth
		notch: frame.notch
		tabStep: frame.tab
	}

	Scanlines {
		anchors.fill: cell
		anchors.topMargin: frame.tab + 1
		anchors.leftMargin: 1
		anchors.rightMargin: 1
		anchors.bottomMargin: 1
	}

	Item {
		id: body

		x: frame.cellX + frame.padding
		y: frame.padding + frame.tab + frame.headerHeight
		width: childrenRect.width
		height: childrenRect.height
	}
}
