// Section label inside a Panel ("Output", "Input"): a static label, so red as
// the game's field labels are; not an entry
import QtQuick

BarText {
	width: Theme.panelWidth
	height: 24
	leftPadding: Theme.modulePadding
	verticalAlignment: Text.AlignBottom
	bottomPadding: 3
	color: Colors.structure
}
