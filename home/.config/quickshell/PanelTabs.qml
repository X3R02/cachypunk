// The tabs of a Panel, drawn as the card's own top edge: the card's tab (the
// raised first stretch of the top edge, Frame/NotchRect) grows into a row of
// folder tabs, one per icon, split by 45-degree dividers and stepping down at
// 45 degrees after the last one, the way the game's cards carry their tab.
// Panel places this over the Frame and gives the Frame the matching raised
// edge (`tabLength` = topX(count), `tab` = tabHeight); this item only
// draws what lies inside that edge: the dividers, the line that closes each
// tab off from the body (left open under the current tab, like a folder),
// the state planes and the icons.
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
	// Clear space around each glyph. Measured from the tab's sides where
	// they come closest: a shared diagonal leans into the tab to its right
	// at the glyph's bottom, so every tab after the first starts further
	// left of its glyph than the first, and all glyphs keep the same room
	property real padding: 8
	readonly property real glyph: Theme.iconSize + 2
	// Where the glyph box starts and ends, measured down from the top
	readonly property real glyphTop: (tabHeight - glyph) / 2
	readonly property real glyphBottom: glyphTop + glyph

	readonly property var panelWindow: QsWindow.window
	readonly property int count: icons.length
	readonly property real lw: Theme.borderWidth
	// Half a stroke in from the top, where Frame's outline runs
	readonly property real edge: lw / 2

	signal selected(int index)

	function select(index: int): void {
		if (count === 0)
			return;
		const cursorOnTab = repeater.count > 0 && Array.from({ length: repeater.count }, (_, i) => repeater.itemAt(i)).indexOf(panelWindow?.cursor) >= 0;
		const next = (index + count) % count;
		selected(next);
		if (cursorOnTab)
			panelWindow.takeCursor(repeater.itemAt(next));
	}

	function step(n: int): void {
		select(currentIndex + n);
	}

	// Where tab i's top edge starts; its bottom edge starts tabHeight further
	// right (45 degrees), except the first, whose left side is the card's edge
	// Where divider i meets the top edge (0 is the card's left side). The
	// first tab only needs its glyph and padding before the diagonal reaches
	// the glyph's top; every later one also spans the diagonal it leans on
	function topX(i: int): real {
		if (i === 0)
			return 0;
		const first = 2 * padding + glyph - glyphTop;
		return first + (i - 1) * (2 * padding + glyph + (glyphBottom - glyphTop));
	}

	// Glyph's left edge in tab i: past its left side at the glyph's bottom
	function glyphX(i: int): real {
		return i === 0 ? padding : topX(i) + glyphBottom + padding;
	}

	function bottomX(i: int): real {
		return i === 0 ? 0 : topX(i) + tabHeight;
	}

	width: topX(count) + tabHeight
	height: tabHeight

	// The line closing the tabs off from the body, open under the current tab
	Repeater {
		model: strip.count

		Rectangle {
			required property int index

			visible: index !== strip.currentIndex
			x: strip.bottomX(index)
			y: strip.tabHeight
			width: strip.topX(index + 1) + strip.tabHeight - x
			height: strip.lw
			color: Colors.line
			antialiasing: false
		}
	}

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

			readonly property real x0: strip.topX(index)
			readonly property real x1: strip.topX(index + 1)
			readonly property real b0: strip.bottomX(index)
			readonly property real b1: x1 + strip.tabHeight

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

				// The state plane, the whole tab
				ShapePath {
					strokeColor: "transparent"
					fillColor: Qt.rgba(Colors.structure.r, Colors.structure.g, Colors.structure.b, tab.fill)

					PathPolyline {
						path: [Qt.point(tab.x0, 0), Qt.point(tab.x1, 0), Qt.point(tab.b1, strip.tabHeight), Qt.point(tab.b0, strip.tabHeight), Qt.point(tab.x0, 0)]
					}
				}

				// Its divider from the next tab, in the frame's colour
				ShapePath {
					strokeColor: tab.index < strip.count - 1 ? Colors.line : "transparent"
					strokeWidth: strip.lw
					fillColor: "transparent"
					capStyle: ShapePath.FlatCap

					PathPolyline {
						path: [Qt.point(tab.x1, strip.edge), Qt.point(tab.b1, strip.tabHeight)]
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
						path: tab.index === 0 ? [Qt.point(strip.edge, strip.tabHeight), Qt.point(strip.edge, strip.edge), Qt.point(tab.x1, strip.edge), Qt.point(tab.b1, strip.tabHeight)] : [Qt.point(tab.b0, strip.tabHeight), Qt.point(tab.x0, strip.edge), Qt.point(tab.x1, strip.edge), Qt.point(tab.b1, strip.tabHeight)]
					}
				}

			}

			BarIcon {
				// In its glyph box, the same padding from both sides in every tab
				x: Math.round(strip.glyphX(tab.index) + (strip.glyph - width) / 2)
				y: Math.round((strip.tabHeight - height) / 2)
				text: tab.modelData
				color: tab.current && !tab.hovered ? Colors.fg : Colors.accent
			}

			MouseArea {
				id: mouse

				// The tab's middle band: the slanted ends overlap the
				// neighbours' boxes, so each takes the stretch it owns at mid height
				x: (tab.x0 + tab.b0) / 2
				width: (tab.x1 + tab.b1) / 2 - x
				height: parent.height
				hoverEnabled: true
				onEntered: strip.panelWindow?.takeCursor(tab)
				onClicked: tab.activate()
			}
		}
	}
}
