// The card shape from Cyberpunk 2077's menus: square corners except the
// bottom-right, which is cut at 45 degrees. `cut` moves the cut to the
// bottom-left or drops it, for buttons sharing a row (DESIGN-SYSTEM.md: the
// first cuts left, middle ones are square, the last cuts right). A card can
// also carry the game's
// two marks on its left side: a tab, where the first stretch of the top edge
// sits `tabStep` px higher than the rest and steps down at 45 degrees, and a
// bar, a second vertical line just inside the left edge.
import QtQuick
import QtQuick.Shapes

Item {
	id: root

	property color fillColor: Colors.bg
	property color strokeColor: Colors.line
	property real strokeWidth: Theme.borderWidth
	property real notch: Theme.notch
	// Which bottom corner is cut: "right", "left" or "none"
	property string cut: "right"

	// 0 = flat top edge
	property real tabStep: 0
	property real tabLength: Math.min(width * 0.28, 120)
	// How far right the tab's step runs while dropping tabStep: equal is the
	// usual 45 degrees, less is steeper (a panel's folder tabs)
	property real tabRun: tabStep
	property bool leftBar: false
	property color barColor: strokeColor

	Shape {
		anchors.fill: parent
		preferredRendererType: Shape.CurveRenderer
		antialiasing: true

		ShapePath {
			id: path

			fillColor: root.fillColor
			strokeColor: root.strokeColor
			strokeWidth: root.strokeWidth
			joinStyle: ShapePath.MiterJoin
			capStyle: ShapePath.FlatCap

			// Inset by half the stroke so the border is not clipped at the edge
			readonly property real l: root.strokeWidth / 2
			readonly property real t: root.strokeWidth / 2
			readonly property real r: root.width - root.strokeWidth / 2
			readonly property real b: root.height - root.strokeWidth / 2
			readonly property real n: root.notch
			readonly property real s: root.tabStep

			readonly property real nr: root.cut === "right" ? n : 0
			readonly property real nl: root.cut === "left" ? n : 0

			// Clockwise from the top-left; a zero cut or tab collapses its
			// points onto the corner
			PathPolyline {
				path: [
					Qt.point(path.l, path.t),
					Qt.point(path.l + (path.s > 0 ? root.tabLength : 0), path.t),
					Qt.point(path.l + (path.s > 0 ? root.tabLength + root.tabRun : 0), path.t + path.s),
					Qt.point(path.r, path.t + path.s),
					Qt.point(path.r, path.b - path.nr),
					Qt.point(path.r - path.nr, path.b),
					Qt.point(path.l + path.nl, path.b),
					Qt.point(path.l, path.b - path.nl),
					Qt.point(path.l, path.t)
				]
			}
		}
	}

	Rectangle {
		visible: root.leftBar
		x: 4
		y: 4
		width: 1
		height: root.height - 8
		color: root.barColor
		antialiasing: false
	}
}
