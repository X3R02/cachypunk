// The tabs of a Panel, drawn as the card's own top edge: the card's tab (the
// raised first stretch of the top edge, Frame/NotchRect) grows into a row of
// folder tabs, one per icon, all the same width and split by straight
// dividers; only after the last does the edge step down at 45 degrees, the
// way the game's cards carry their tab. Panel places this over the Frame and
// gives the Frame the matching raised edge (`tabLength` = count x tabWidth,
// `tab` = tabHeight); this item only draws what lies inside that edge: the
// dividers, the line that closes each tab off from the body (left open under
// the current tab, like a folder), the state planes and the icons.
//
// Every tab is a panel entry (navigable, activate, adjust): its states are
// EntryFrame's - idle; focused (cursor) stroke 100% + 10% fill; current
// stroke 100% + 40% fill; 70% flash on activation. Panel walks this strip
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
	// Clear space either side of each glyph; every tab is the same width
	property real padding: 10
	readonly property real tabWidth: 2 * padding + Theme.iconSize + 2

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

	width: count * tabWidth + tabHeight
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
			readonly property bool last: index === strip.count - 1
			// The panel opens with its cursor on the current tab
			readonly property bool preferred: current
			readonly property bool hovered: strip.panelWindow?.keyboardNav ? strip.panelWindow.cursor === tab : mouse.containsMouse
			property bool flashing: false
			readonly property real fill: flashing ? Theme.flashFill : hovered ? Theme.hoverFill : current ? Theme.activeFill : 0
			readonly property bool lit: hovered || current || flashing

			readonly property real x0: index * strip.tabWidth
			readonly property real x1: x0 + strip.tabWidth
			// Where the right side meets the floor: straight down, or the
			// 45-degree step after the last tab
			readonly property real foot: last ? x1 + strip.tabHeight : x1
			readonly property real h: strip.tabHeight

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

			// The line closing the tab off from the body, open when current
			Rectangle {
				visible: !tab.current
				x: tab.x0
				y: tab.h
				width: tab.foot - tab.x0
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
						path: [Qt.point(tab.x0, 0), Qt.point(tab.x1, 0), Qt.point(tab.foot, tab.h), Qt.point(tab.x0, tab.h), Qt.point(tab.x0, 0)]
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
						path: [Qt.point(tab.x1, strip.edge), Qt.point(tab.x1, tab.h)]
					}
				}

				// Focused or current: the tab's own edges at full strength,
				// left open at the bottom where it joins the body
				ShapePath {
					strokeColor: tab.lit ? Colors.structure : "transparent"
					strokeWidth: strip.lw
					fillColor: "transparent"
					joinStyle: ShapePath.MiterJoin
					capStyle: ShapePath.FlatCap

					PathPolyline {
						path: [Qt.point(tab.x0 + strip.edge, tab.h), Qt.point(tab.x0 + strip.edge, strip.edge), Qt.point(tab.x1, strip.edge), Qt.point(tab.foot, tab.h)]
					}
				}
			}

			BarIcon {
				x: Math.round(tab.x0 + (strip.tabWidth - width) / 2)
				y: Math.round((tab.h - height) / 2)
				text: tab.modelData
				color: tab.current && !tab.hovered ? Colors.fg : Colors.accent
			}

			MouseArea {
				id: mouse

				x: tab.x0
				width: strip.tabWidth
				height: parent.height
				hoverEnabled: true
				onEntered: strip.panelWindow?.takeCursor(tab)
				onClicked: tab.activate()
			}
		}
	}
}
