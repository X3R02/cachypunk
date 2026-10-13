import QtQuick

Text {
	// Capitals with wide tracking everywhere; set false for free text that
	// reads badly in caps
	property bool caps: true

	color: Colors.fg
	font.family: Theme.textFont
	font.pixelSize: Theme.textSize
	font.weight: Font.DemiBold
	font.capitalization: caps ? Font.AllUppercase : Font.MixedCase
	font.letterSpacing: caps ? Theme.tracking : 0
	// Tabular figures: digits all share one width
	font.features: { "tnum": 1 }
	verticalAlignment: Text.AlignVCenter
	renderType: Text.NativeRendering
	// No hinting: at the 1.5x scale, snapping glyph edges to the pixel grid
	// bent curves and diagonals into stair steps (visible on 2, 3 and 5); left
	// unhinted, the antialiasing spreads evenly and the curves stay smooth
	font.hintingPreference: Font.PreferNoHinting
}
