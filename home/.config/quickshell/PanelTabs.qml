// The tabs of a Panel: folder tabs standing on the card's top edge, one per
// icon. Every tab has the same shape, | \ : a vertical left side, a flat top
// and a 45-degree right side down to the card, where the next tab's left
// side rises, so every icon sits the same distance from its tab's left edge
// (the game's card tab, repeated). Panel lowers
// the Frame's cell by `tabHeight` (Frame.headerHeight) and places this strip
// in that room; the cell's top edge is each tab's floor.
//
// Every tab is a panel entry (navigable, activate, adjust) with EntryFrame's
// states: idle (outline in the frame's `line`); focused (cursor) outline in
// `structure` + 10% fill; current outline in `structure` + 40% fill and its
// floor left open, joined to the body like a folder; 70% flash on
// activation. Panel walks this strip before the body, so the tabs come first
// under Up/Down, and pages it with Q / E. Paging with the cursor on a tab
// carries the cursor along.
import Quickshell
import QtQuick
import QtQuick.Shapes

Item {
	id: strip

	property var icons: []
	property int currentIndex: 0
	// Width of a tab's flat top; the slanted side adds tabHeight more
	property real tabWidth: 30
	property real tabHeight: 24

	readonly property var panelWindow: QsWindow.window
	readonly property int count: icons.length
	readonly property real lw: Theme.borderWidth
	// Half a stroke in, where a 1 px line drawn on an edge lands
	readonly property real edge: lw / 2

	signal selected(int index)

	function select(index: int): void {
		if (count === 0)
			return;
		let cursorOnTab = false;
		for (let i = 0; i < repeater.count; i++)
			if (repeater.itemAt(i) === panelWindow?.cursor)
				cursorOnTab = true;
		const next = (index + count) % count;
		selected(next);
		if (cursorOnTab)
			panelWindow.takeCursor(repeater.itemAt(next));
	}

	function step(n: int): void {
		select(currentIndex + n);
	}

	function leftX(i: int): real {
		return i * (tabWidth + tabHeight);
	}

	width: leftX(count)
	height: tabHeight

	Repeater {
		id: repeater

		model: strip.icons

		Item {
			id: tab

			required property string modelData
			required property int index

			readonly property bool navigable: true
			readonly property bool current: index === strip.currentIndex
			// The panel opens with its cursor on the current tab
			readonly property bool preferred: current
			readonly property bool hovered: strip.panelWindow?.keyboardNav ? strip.panelWindow.cursor === tab : mouse.containsMouse
			property bool flashing: false
			readonly property real fill: flashing ? Theme.flashFill : hovered ? Theme.hoverFill : current ? Theme.activeFill : 0
			readonly property bool lit: hovered || current || flashing

			// Left side and end of the flat top; the slant runs from there at
			// 45 degrees, so at height y it is at x1 + y
			readonly property real x0: strip.leftX(index) + strip.edge
			readonly property real x1: strip.leftX(index) + strip.tabWidth
			// The planes stop on the cell's top edge, or cover it under the
			// current tab, whose floor is open
			readonly property real floor: strip.tabHeight + (current ? strip.lw : 0)
			readonly property var plane: [Qt.point(x0, strip.edge), Qt.point(x1, strip.edge), Qt.point(x1 + floor, floor), Qt.point(x0, floor), Qt.point(x0, strip.edge)]

			function activate(): void {
				flashing = true;
				flashTimer.restart();
				strip.select(index);
			}

			function adjust(n: int): void {
				strip.step(n);
			}

			anchors.fill: parent

			Timer {
				id: flashTimer

				interval: 120
				onTriggered: tab.flashing = false
			}

			Shape {
				anchors.fill: parent
				preferredRendererType: Shape.CurveRenderer

				// The backing, opaque like the rest of the card
				ShapePath {
					strokeColor: "transparent"
					fillColor: Colors.bg

					PathPolyline {
						path: tab.plane
					}
				}

				// The state plane
				ShapePath {
					strokeColor: "transparent"
					fillColor: Qt.rgba(Colors.structure.r, Colors.structure.g, Colors.structure.b, tab.fill)

					PathPolyline {
						path: tab.plane
					}
				}

				// Its outline, | \ , down to the cell's top edge
				ShapePath {
					strokeColor: tab.lit ? Colors.structure : Colors.line
					strokeWidth: strip.lw
					fillColor: "transparent"
					joinStyle: ShapePath.MiterJoin
					capStyle: ShapePath.FlatCap

					PathPolyline {
						path: [Qt.point(tab.x0, strip.tabHeight + strip.lw), Qt.point(tab.x0, strip.edge), Qt.point(tab.x1, strip.edge), Qt.point(tab.x1 + strip.tabHeight + strip.lw, strip.tabHeight + strip.lw)]
					}
				}
			}

			BarIcon {
				// Centred at mid height, between the left side and the slant
				x: Math.round((tab.x0 + tab.x1 + strip.tabHeight / 2) / 2 - width / 2)
				y: Math.round((strip.tabHeight - height) / 2)
				text: tab.modelData
				color: tab.current && !tab.hovered ? Colors.fg : Colors.accent
			}

			MouseArea {
				id: mouse

				x: tab.x0
				width: tab.x1 + strip.tabHeight / 2 - x
				height: parent.height
				hoverEnabled: true
				onEntered: strip.panelWindow?.takeCursor(tab)
				onClicked: tab.activate()
			}
		}
	}
}
