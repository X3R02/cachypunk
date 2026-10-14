// Wallpaper picker (SUPER + CTRL + D, `qs ipc call wallpapers toggle`): the
// same carousel as the theme switcher, with the images the current theme can
// wear. The first card is "Palette", the wallpaper theme-set draws from the
// theme's colours; the rest are the images in <pictures>/wallpapers. Left/Right
// (h/l) move, Enter or a click applies through wallpaper-set (which re-applies
// the theme, so the lock screen and SDDM follow), Escape closes.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs
import qs.services

PanelWindow {
	id: picker

	property bool open: false
	property bool applying: false
	// { path, name, palette? } per card, Palette first
	property var list: []

	readonly property string theme: Themes.current
	readonly property string paletteFile: Quickshell.env("HOME") + "/.local/share/cachypunk/wallpapers/" + theme + ".png"

	function toggle(): void {
		open = !open;
	}

	function applyFocused(): void {
		const w = list[carousel.currentIndex];
		if (!w || applying)
			return;
		if (w.path === Wallpaper.path) {
			open = false;
			return;
		}
		applying = true;
		// Detached for the same reason as the theme switcher: theme-set
		// reloads this shell halfway through
		Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/wallpaper-set", w.palette ? "--palette" : w.path]);
		open = false;
	}

	function name(path: string): string {
		return path.split("/").pop().replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ");
	}

	screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
	visible: open
	color: "transparent"
	anchors {
		top: true
		bottom: true
		left: true
		right: true
	}
	exclusionMode: ExclusionMode.Ignore

	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.namespace: "quickshell-wallpapers"
	WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

	onOpenChanged: if (open) {
		applying = false;
		Wallpaper.reload();
		lister.running = true;
		keys.forceActiveFocus();
	}

	Process {
		id: lister

		command: [Quickshell.env("HOME") + "/.local/bin/wallpaper-set", "--list"]
		stdout: StdioCollector {
			onStreamFinished: {
				const files = text.split("\n").filter(l => l !== "");
				picker.list = [{ path: picker.paletteFile, name: "Palette", palette: true }].concat(files.map(f => ({ path: f, name: picker.name(f) })));
				// Start on the one in use
				carousel.currentIndex = Math.max(0, picker.list.findIndex(w => w.path === Wallpaper.path));
			}
		}
	}

	// Everything behind dims, as behind every modal
	Rectangle {
		anchors.fill: parent
		color: Qt.rgba(Colors.bgDeep.r, Colors.bgDeep.g, Colors.bgDeep.b, 0.65)

		MouseArea {
			anchors.fill: parent
			onClicked: picker.open = false
		}
	}

	Item {
		id: keys

		anchors.fill: parent
		focus: true

		Keys.onPressed: event => {
			switch (event.key) {
			case Qt.Key_Left:
			case Qt.Key_H:
			case Qt.Key_Backtab:
				carousel.decrementCurrentIndex();
				break;
			case Qt.Key_Right:
			case Qt.Key_L:
			case Qt.Key_Tab:
				carousel.incrementCurrentIndex();
				break;
			case Qt.Key_Return:
			case Qt.Key_Enter:
			case Qt.Key_Space:
				picker.applyFocused();
				break;
			case Qt.Key_Escape:
				picker.open = false;
				break;
			default:
				return;
			}
			event.accepted = true;
		}

		Column {
			anchors.centerIn: parent
			width: parent.width
			spacing: 18

			BarText {
				anchors.horizontalCenter: parent.horizontalCenter
				text: "Wallpaper  ·  " + picker.theme
				color: Colors.structure
				font.pixelSize: 18
			}

			ListView {
				id: carousel

				width: parent.width
				height: 250
				orientation: ListView.Horizontal
				spacing: 18
				model: picker.list
				// Keep the focused card in the middle of the screen
				highlightRangeMode: ListView.StrictlyEnforceRange
				preferredHighlightBegin: width / 2 - 160
				preferredHighlightEnd: width / 2 + 160
				highlightMoveDuration: 160
				boundsBehavior: Flickable.StopAtBounds
				interactive: true

				delegate: WallpaperCard {
					required property var modelData
					required property int index

					anchors.verticalCenter: parent?.verticalCenter
					wallpaper: modelData
					focused: ListView.isCurrentItem
					active: modelData.path === Wallpaper.path
					onPicked: {
						carousel.currentIndex = index;
						picker.applyFocused();
					}
				}
			}

			BarText {
				anchors.horizontalCenter: parent.horizontalCenter
				text: "← →  Select    ⏎  Apply    Esc  Close"
				color: Colors.fgDim
			}
		}
	}
}
