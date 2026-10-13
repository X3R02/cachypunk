// Faint horizontal lines over a surface, every Theme.scanlineSpacing px.
// Ported from BW77's Common/Scanlines.qml, without the drift animation.
import QtQuick

Item {
	id: root

	anchors.fill: parent
	clip: true

	Column {
		width: parent.width
		spacing: Theme.scanlineSpacing - 1

		Repeater {
			model: root.height > 0 ? Math.ceil(root.height / Theme.scanlineSpacing) : 0

			Rectangle {
				width: root.width
				height: 1
				color: "#000000"
				opacity: Theme.scanlineOpacity
			}
		}
	}
}
