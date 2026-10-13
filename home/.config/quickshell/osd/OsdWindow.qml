// The on-screen display: the game's plain card - a coral frame with only the
// bottom-right corner cut - low on the focused screen, with an icon and either
// a 20-block meter or a message. Clicks pass straight through it.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs
import qs.services

PanelWindow {
	id: osd

	// What to draw for the current kind; a value below 0 means no meter
	readonly property string icon: Osd.kind === "volume" ? Audio.sinkIcon(Audio.sink) : Osd.kind === "mic" ? Audio.sourceIcon(Audio.source) : Osd.kind === "brightness" ? "󰃠" : Osd.icon
	readonly property real value: Osd.kind === "volume" ? Audio.volume(Audio.sink) : Osd.kind === "brightness" ? Brightness.percent / 100 : -1
	readonly property bool off: Osd.kind === "volume" ? Audio.muted(Audio.sink) : Osd.kind === "mic" ? Audio.muted(Audio.source) : false
	readonly property string label: Osd.kind === "mic" ? (off ? "Microphone off" : "Microphone on") : Osd.label

	screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
	visible: Osd.visible
	color: "transparent"
	// One spare pixel past the card on each side: at the 1.5x scale the window
	// edge is rounded, and it used to clip the card's right border
	implicitWidth: card.width + 2
	implicitHeight: card.height + 2

	anchors.bottom: true
	// Where swayosd sat: its centre 85% of the way down
	margins.bottom: Math.round((screen?.height ?? 800) * 0.15 - implicitHeight / 2)
	exclusionMode: ExclusionMode.Ignore
	mask: Region {}

	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.namespace: "quickshell-osd"
	WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

	NotchRect {
		id: card

		x: 1
		y: 1
		// Whole pixels, or the border lands on a half pixel and can vanish
		width: Math.ceil(content.implicitWidth + Theme.panelPadding * 2 + Theme.notch / 2)
		height: 44
		fillColor: Colors.bg
		strokeColor: Colors.structure
		notch: Theme.notch

		Row {
			id: content

			x: Theme.panelPadding
			anchors.verticalCenter: parent.verticalCenter
			spacing: 12

			BarIcon {
				anchors.verticalCenter: parent.verticalCenter
				text: osd.icon
				font.pixelSize: 18
				color: osd.off ? Colors.muted : Colors.structure
			}

			SegmentBar {
				anchors.verticalCenter: parent.verticalCenter
				visible: osd.value >= 0
				// 20 blocks of 10px, so each 5% step is one whole block
				width: 200
				height: 6
				segments: 20
				value: Math.max(0, osd.value)
				fillColor: osd.off ? Colors.muted : Colors.accent
			}

			BarText {
				anchors.verticalCenter: parent.verticalCenter
				// The number after a meter, the text of a message
				width: osd.value >= 0 ? 36 : implicitWidth
				horizontalAlignment: osd.value >= 0 ? Text.AlignRight : Text.AlignLeft
				text: osd.value >= 0 ? (osd.off ? "Mute" : Math.round(osd.value * 100) + "%") : osd.label
				color: osd.off ? Colors.muted : Colors.accent
			}
		}
	}
}
