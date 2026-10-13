import QtQuick

Text {
	color: Colors.fg
	font.family: Theme.iconFont
	font.pixelSize: Theme.iconSize
	verticalAlignment: Text.AlignVCenter
	horizontalAlignment: Text.AlignHCenter
	renderType: Text.NativeRendering
	// Unhinted like BarText, so glyph curves aren't stair-stepped at 1.5x
	font.hintingPreference: Font.PreferNoHinting
}
