// One screen's background: the theme's wallpaper on the background layer,
// cropped to fill. Built per screen by shell.qml's Variants, so a monitor
// plugged in later gets it too (the hotplug case awww needed a script for).
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
import qs.services

PanelWindow {
	id: win

	required property var modelData

	screen: modelData
	color: Colors.bgDeep
	anchors {
		top: true
		bottom: true
		left: true
		right: true
	}
	exclusionMode: ExclusionMode.Ignore
	mask: Region {}

	WlrLayershell.layer: WlrLayer.Background
	WlrLayershell.namespace: "quickshell-wallpaper"
	WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

	Image {
		anchors.fill: parent
		source: Wallpaper.path !== "" ? "file://" + Wallpaper.path : ""
		fillMode: Image.PreserveAspectCrop
		// Decode at the screen's real pixel size, not the file's
		sourceSize.width: win.width * (win.screen?.devicePixelRatio ?? 1)
		sourceSize.height: win.height * (win.screen?.devicePixelRatio ?? 1)
		asynchronous: true
		smooth: true
		// The path stays the same file name only by coincidence; never serve a
		// stale decode after a theme switch
		cache: false
	}
}
