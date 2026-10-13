// Theme switcher (SUPER + CTRL + T, `qs ipc call themes toggle`): the screen
// dims and the themes line up as a carousel of long cards, each drawn in its
// own colours, the focused one centred. Left/Right (h/l) move, Enter or a
// click applies through theme-set, Escape closes.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs
import qs.services

PanelWindow {
	id: switcher

	property bool open: false

	function toggle(): void {
		open = !open;
	}

	function applyFocused(): void {
		const theme = Themes.list[carousel.currentIndex];
		if (!theme)
			return;
		Themes.apply(theme.name);
		open = false;
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
	WlrLayershell.namespace: "quickshell-themes"
	WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

	onOpenChanged: if (open) {
		Themes.reload();
		carousel.currentIndex = Math.max(0, Themes.list.findIndex(t => t.name === Themes.current));
		keys.forceActiveFocus();
	}

	// Everything behind dims, as behind every modal
	Rectangle {
		anchors.fill: parent
		color: Qt.rgba(Colors.bgDeep.r, Colors.bgDeep.g, Colors.bgDeep.b, 0.65)

		MouseArea {
			anchors.fill: parent
			onClicked: switcher.open = false
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
				switcher.applyFocused();
				break;
			case Qt.Key_Escape:
				switcher.open = false;
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
				text: "Theme"
				color: Colors.structure
				font.pixelSize: 18
			}

			ListView {
				id: carousel

				width: parent.width
				height: 126
				orientation: ListView.Horizontal
				spacing: 18
				model: Themes.list
				// Keep the focused card in the middle of the screen
				highlightRangeMode: ListView.StrictlyEnforceRange
				preferredHighlightBegin: width / 2 - 230
				preferredHighlightEnd: width / 2 + 230
				highlightMoveDuration: 160
				boundsBehavior: Flickable.StopAtBounds
				interactive: true

				delegate: ThemeCard {
					required property var modelData
					required property int index

					anchors.verticalCenter: parent?.verticalCenter
					theme: modelData
					focused: ListView.isCurrentItem
					active: modelData.name === Themes.current
					onPicked: {
						carousel.currentIndex = index;
						switcher.applyFocused();
					}
				}
			}

			BarText {
				anchors.horizontalCenter: parent.horizontalCenter
				text: Themes.applying ? "Applying" : "← →  Select    ⏎  Apply    Esc  Close"
				color: Colors.fgDim
			}
		}
	}
}
