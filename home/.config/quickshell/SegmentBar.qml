// A meter drawn as discrete segments instead of a smooth bar. Ported from
// BW77's Common/SegmentBar.qml.
import QtQuick

Item {
	id: root

	property real value: 0 // 0..1
	property int segments: 24
	property real gap: 2
	property color fillColor: Colors.accent
	property color emptyColor: Colors.line

	readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * segments)

	implicitHeight: 6

	Row {
		anchors.fill: parent
		spacing: root.gap

		Repeater {
			model: root.segments

			Rectangle {
				required property int index

				width: (root.width - root.gap * (root.segments - 1)) / root.segments
				height: root.height
				color: index < root.lit ? root.fillColor : root.emptyColor
				antialiasing: false
			}
		}
	}
}
