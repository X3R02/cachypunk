// The tabs of a Panel, drawn as the card's own top edge, like the tabs on a
// folder icon: the card's tab (the raised first stretch of the top edge,
// Frame/NotchRect) grows into a row of wide, low tabs, one per icon. Tabs
// share 45-degree dividers and the edge steps down after the last at the
// same 45 degrees (`run` = tabHeight). The strip is a carousel: the current
// tab is always the first slot and the others follow in order, wrapping, so
// changing tab rotates the icons while the tab shapes stay put and only the
// content moves. The current tab stands in front: its
// left side is straight, so the tab before it ends straight down and the
// others read as a layer behind. Panel places this over the Frame and gives
// the Frame the matching raised edge (`tabLength` = topX(count), `tab` =
// tabHeight, `tabRun` = run); this item only draws what lies inside that
// edge: the dividers, the line that closes each tab off from the body (left
// open under the current tab, like a folder), the flash plane and the icons.
//
// Every tab is a panel entry (navigable, activate, adjust). Unlike other
// entries, the current tab takes no fill: it keeps the card's dark backing
// and an open floor, so tab and content read as one surface, and it is told
// apart only by its glyph in `accent` while the others are `muted`. Focus
// (the cursor) touches neither fill nor edges, which stay the frame's 1 px
// `line` like the rest of the popup: it brightens another tab's glyph to
// `fg`; the current glyph stays `accent`. An
// activation still flashes 70%. Panel walks this strip
// before the body, so the tabs come first under Up/Down, and pages it with
// Q / E. Paging with the cursor on a tab carries the cursor along.
import Quickshell
import QtQuick
import QtQuick.Shapes

Item {
	id: strip

	property var icons: []
	property int currentIndex: 0
	property real tabHeight: 24
	// Width of the current tab (always the first slot), measured at mid
	// height, where the glyph sits; the tabs behind it are a little narrower
	property real tabWidth: 72
	property real backWidth: 60
	// How far a divider runs right while dropping the tab's height: 45
	// degrees, the card's own cut. A steeper 0.4 x tabHeight was tried; with
	// the front tab's straight side, 45 reads as the game's card tab
	property real run: tabHeight

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
		selected((index + count) % count);
		// The current tab is always slot 0, so that is where the cursor goes
		if (cursorOnTab)
			panelWindow.takeCursor(repeater.itemAt(0));
	}

	function step(n: int): void {
		select(currentIndex + n);
	}

	// Where divider i meets the top edge (0 is the card's left side). The
	// first tab loses half a run at its top, since its left side is
	// straight, so at mid height it measures tabWidth; each later tab adds
	// backWidth
	function topX(i: int): real {
		return i === 0 ? 0 : tabWidth + (i - 1) * backWidth - run / 2;
	}

	width: topX(count) + run
	height: tabHeight

	Repeater {
		id: repeater

		// One slot per tab; slot j shows the tab j places after the current
		model: strip.count

		Item {
			id: tab

			required property int index
			readonly property int item: (strip.currentIndex + index) % Math.max(1, strip.count)

			readonly property bool navigable: true
			readonly property bool current: index === 0
			readonly property bool last: index === strip.count - 1
			// The panel opens with its cursor on the current tab
			readonly property bool preferred: current
			readonly property bool hovered: strip.panelWindow?.keyboardNav ? strip.panelWindow.cursor === tab : mouse.containsMouse
			property bool flashing: false
			readonly property real fill: flashing ? Theme.flashFill : 0

			readonly property real h: strip.tabHeight
			// Top corners, and where the sides meet the floor: sides lean by
			// one run, except the first slot's straight left side, which is
			// the card's edge. The current tab always sits there, in front,
			// and the others lean behind it like the tabs of a folder
			readonly property real x0: strip.topX(index)
			readonly property real x1: strip.topX(index + 1)
			readonly property real b0: index === 0 ? x0 : x0 + strip.run
			readonly property real foot: x1 + strip.run

			function activate(): void {
				flashing = true;
				flashTimer.restart();
				strip.select(item);
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

			// The line closing the tab off from the body, open when current
			Rectangle {
				visible: !tab.current
				x: tab.b0
				y: tab.h
				width: tab.foot - tab.b0
				height: strip.lw
				color: Colors.line
				antialiasing: false
			}

			Shape {
				anchors.fill: parent
				preferredRendererType: Shape.CurveRenderer

				// The state plane
				ShapePath {
					strokeColor: "transparent"
					fillColor: Qt.rgba(Colors.structure.r, Colors.structure.g, Colors.structure.b, tab.fill)

					PathPolyline {
						path: [Qt.point(tab.x0, 0), Qt.point(tab.x1, 0), Qt.point(tab.foot, tab.h), Qt.point(tab.b0, tab.h), Qt.point(tab.x0, 0)]
					}
				}

				// The divider to the next tab, in the frame's colour; the
				// last tab's right side is the frame's own step
				ShapePath {
					strokeColor: tab.last ? "transparent" : Colors.line
					strokeWidth: strip.lw
					fillColor: "transparent"
					capStyle: ShapePath.FlatCap

					PathPolyline {
						path: [Qt.point(tab.x1, strip.edge), Qt.point(tab.foot, tab.h)]
					}
				}
			}

			BarIcon {
				// Centred at mid height, between the sides' midpoints
				x: Math.round(((tab.x0 + tab.b0) / 2 + (tab.x1 + tab.foot) / 2) / 2 - width / 2)
				y: Math.round((tab.h - height) / 2)
				text: strip.icons[tab.item] ?? ""
				color: tab.current ? Colors.accent : tab.hovered ? Colors.fg : Colors.muted
			}

			MouseArea {
				id: mouse

				// The stretch the tab owns at mid height
				x: (tab.x0 + tab.b0) / 2
				width: (tab.x1 + tab.foot) / 2 - x
				height: parent.height
				hoverEnabled: true
				onEntered: strip.panelWindow?.takeCursor(tab)
				onClicked: tab.activate()
			}
		}
	}
}
