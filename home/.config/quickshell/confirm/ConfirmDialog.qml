// The game's confirmation card: the screen behind dims and a dialog card in
// the middle asks the question in red caps, with BACK and the action as two
// buttons joined by a short line. BACK has the focus, so Enter on a stray
// confirmation does nothing harmful; Left/Right/Tab move between the two,
// Escape goes back.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs
import qs.services

PanelWindow {
	id: dialog

	// The keyboard cursor, as in a Panel: entries read `cursor` to draw focus
	readonly property bool keyboardNav: true
	property Item cursor: back

	function takeCursor(item: Item): void {
		cursor = item;
	}

	screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
	visible: Confirm.open
	color: "transparent"
	anchors {
		top: true
		bottom: true
		left: true
		right: true
	}
	exclusionMode: ExclusionMode.Ignore

	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.namespace: "quickshell-confirm"
	WlrLayershell.keyboardFocus: Confirm.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

	onVisibleChanged: if (visible) {
		cursor = back;
		keys.forceActiveFocus();
	}

	// Everything behind the dialog dims; no red wash (the user's choice)
	Rectangle {
		anchors.fill: parent
		color: Qt.rgba(Colors.bgDeep.r, Colors.bgDeep.g, Colors.bgDeep.b, 0.65)
	}

	Item {
		id: keys

		anchors.fill: parent
		focus: true

		Keys.onPressed: event => {
			switch (event.key) {
			case Qt.Key_Left:
			case Qt.Key_Right:
			case Qt.Key_Tab:
			case Qt.Key_Backtab:
			case Qt.Key_H:
			case Qt.Key_L:
				dialog.cursor = dialog.cursor === back ? go : back;
				break;
			case Qt.Key_Return:
			case Qt.Key_Enter:
			case Qt.Key_Space:
				dialog.cursor.activate();
				break;
			case Qt.Key_Escape:
				Confirm.cancel();
				break;
			default:
				return;
			}
			event.accepted = true;
		}

		Column {
			anchors.centerIn: parent
			spacing: 14

			ModalCard {
				contentWidth: 400

				Column {
					width: 400
					spacing: 12

					BarText {
						width: parent.width
						wrapMode: Text.Wrap
						text: Confirm.question
						color: Colors.structure
						font.pixelSize: 18
					}

					// Device fiction, as on every dialog in the game
					BarText {
						text: "Only CC35 certified and DHSF 5th class officers are allowed to manipulate, access or disable this device."
						width: parent.width
						wrapMode: Text.Wrap
						color: Qt.rgba(Colors.structure.r, Colors.structure.g, Colors.structure.b, 0.6)
						font.pixelSize: 8
					}
				}
			}

			Row {
				anchors.right: parent.right
				spacing: 0

				PanelButton {
					id: back

					width: 150
					label: "Back"
					cut: "left"
					onClicked: Confirm.cancel()
				}

				// The short line joining the two buttons
				Rectangle {
					anchors.verticalCenter: parent.verticalCenter
					width: 18
					height: Theme.borderWidth
					color: Colors.structure
				}

				PanelButton {
					id: go

					width: 150
					label: Confirm.action
					color: Colors.alert
					onClicked: Confirm.accept()
				}
			}
		}
	}
}
