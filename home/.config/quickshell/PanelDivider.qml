// Rule between a Panel's sections, in the frame colour
import QtQuick

Item {
	width: Theme.panelWidth
	height: 9

	Rectangle {
		anchors.verticalCenter: parent.verticalCenter
		width: parent.width
		height: Theme.borderWidth
		color: Colors.line
	}
}
