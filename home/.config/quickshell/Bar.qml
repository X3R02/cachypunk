import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.modules

PanelWindow {
	id: bar

	required property var modelData

	screen: modelData
	anchors {
		top: true
		left: true
		right: true
	}
	implicitHeight: Theme.barHeight
	color: Colors.backdrop
	WlrLayershell.namespace: "quickshell-bar"

	Scanlines {}

	// Structure line along the bottom edge, outside the content area so
	// nothing paints over it
	EdgeLine {
		anchors.bottom: parent.bottom
		width: parent.width
	}

	// A click on the bar's empty space closes whichever panel is open (the
	// panel's own click-catcher leaves the bar's strip to the bar)
	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.AllButtons
		onPressed: Panels.current = ""
	}

	Item {
		id: content

		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		height: Theme.contentHeight

		Row {
			anchors.left: parent.left
			anchors.leftMargin: Theme.edgeMargin
			height: parent.height
			spacing: Theme.moduleSpacing

			Workspaces {
				screenName: bar.modelData.name
			}
			Media {
				barWindow: bar
				screenName: bar.modelData.name
			}
		}

		Clock {
			anchors.horizontalCenter: parent.horizontalCenter
		}

		Row {
			anchors.right: parent.right
			anchors.rightMargin: Theme.edgeMargin
			height: parent.height
			spacing: Theme.moduleSpacing

			Privacy {}
			Tray {
				barWindow: bar
			}
			Agents {
				barWindow: bar
				screenName: bar.modelData.name
			}
			Cpu {
				barWindow: bar
				screenName: bar.modelData.name
			}
			Network {
				barWindow: bar
				screenName: bar.modelData.name
			}
			BluetoothStatus {
				barWindow: bar
				screenName: bar.modelData.name
			}
			Volume {
				barWindow: bar
				screenName: bar.modelData.name
			}
			Battery {
				barWindow: bar
				screenName: bar.modelData.name
			}
			Notifications {
				barWindow: bar
				screenName: bar.modelData.name
			}
			Power {
				barWindow: bar
				screenName: bar.modelData.name
			}
		}
	}
}
