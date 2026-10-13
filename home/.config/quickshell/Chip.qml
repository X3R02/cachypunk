// State chip, as the game labels a state instead of only colouring it
// ("READY", "INSTALLED", "COVERT HACK"): tiny tracked caps in a 1 px outlined
// box, both in the state's colour. Square corners - the chip is too small
// for the cut to read.
import QtQuick

Rectangle {
	id: chip

	property string text: ""
	property color tone: Colors.accent

	visible: text !== ""
	implicitWidth: label.implicitWidth + 8
	implicitHeight: 16
	color: "transparent"
	border.width: Theme.borderWidth
	border.color: tone
	antialiasing: false

	BarText {
		id: label

		anchors.centerIn: parent
		text: chip.text
		color: chip.tone
		font.pixelSize: 10
		font.letterSpacing: 0.6
	}
}
