// The game's menu header strip as a Panel's tab bar (STYLEGUIDE.md
// section 6, "Header bar"): the current tab's glyph and name in `accent`
// caps, centred; the neighbouring tabs' glyphs dimmed in `structure` either
// side; the keys that page them (Q / E, the game's bumpers) boxed at both
// ends. It is a carousel - the current tab stays centred and the rest rotate
// through the sides - so only the content below moves. Not an entry: Q / E
// page it from anywhere (Panel), and a click on a neighbour or a key box
// pages too. With two tabs the one neighbour shows on the right only; with
// more, the previous and next tabs flank the current one and the rest are
// off-strip, as in the game.
//
// It replaced folder tabs drawn on the card's top edge (2026-10-14): the
// card's tab is decoration in the game, never navigation, and every shape
// tried for it looked borrowed. This is what the game itself pages with L1/R1.
import QtQuick

Item {
	id: strip

	property var icons: []
	property var labels: []
	property int currentIndex: 0

	readonly property int count: icons.length

	signal selected(int index)

	function select(index: int): void {
		if (count > 0)
			selected((index + count) % count);
	}

	function step(n: int): void {
		select(currentIndex + n);
	}

	width: Theme.panelWidth
	height: Theme.rowHeight

	component KeyBox: Item {
		id: box

		property string key: ""
		property int direction: 0

		width: 18
		height: 18

		Rectangle {
			anchors.fill: parent
			color: "transparent"
			border.width: Theme.borderWidth
			border.color: strip.count > 1 ? Colors.accent : Colors.muted
			antialiasing: false
		}

		BarText {
			anchors.centerIn: parent
			text: box.key
			color: strip.count > 1 ? Colors.accent : Colors.muted
			font.pixelSize: 11
		}

		MouseArea {
			anchors.fill: parent
			anchors.margins: -4
			onClicked: strip.step(box.direction)
		}
	}

	component Neighbour: BarIcon {
		id: n

		property int offset: 0

		visible: strip.count > (offset < 0 ? 2 : 1)
		text: strip.icons[(strip.currentIndex + offset + strip.count) % Math.max(1, strip.count)] ?? ""
		color: Colors.structure
		opacity: mouse.containsMouse ? 1 : 0.5

		MouseArea {
			id: mouse

			anchors.fill: parent
			anchors.margins: -6
			hoverEnabled: true
			onClicked: strip.step(n.offset)
		}
	}

	KeyBox {
		id: prevKey

		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
		key: "Q"
		direction: -1
	}

	Neighbour {
		anchors.left: prevKey.right
		anchors.leftMargin: 14
		anchors.verticalCenter: parent.verticalCenter
		offset: -1
	}

	Row {
		anchors.centerIn: parent
		spacing: 8

		BarIcon {
			anchors.verticalCenter: parent.verticalCenter
			text: strip.icons[strip.currentIndex] ?? ""
			color: Colors.accent
		}
		BarText {
			anchors.verticalCenter: parent.verticalCenter
			text: strip.labels[strip.currentIndex] ?? ""
			color: Colors.accent
		}
	}

	Neighbour {
		anchors.right: nextKey.left
		anchors.rightMargin: 14
		anchors.verticalCenter: parent.verticalCenter
		offset: 1
	}

	KeyBox {
		id: nextKey

		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		key: "E"
		direction: 1
	}
}
