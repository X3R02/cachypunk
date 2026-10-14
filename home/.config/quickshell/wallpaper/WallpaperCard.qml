// One wallpaper in the picker: the image cropped to the desktop's card shape
// (tab on the top edge, bottom-right corner cut), its name under it, and an
// "Active" chip on the one in use. Off focus it sinks under a dark veil and
// shrinks, as the theme cards do.
import QtQuick
import QtQuick.Effects
import qs

Item {
	id: card

	// { path, name } of the image
	required property var wallpaper
	property bool focused: false
	property bool active: false

	signal picked

	implicitWidth: 320
	implicitHeight: 232
	scale: focused ? 1 : 0.92

	Behavior on scale {
		NumberAnimation {
			duration: 120
		}
	}

	Item {
		id: frame

		width: parent.width
		height: 200

		// The image, masked by the card's own shape
		Image {
			id: image

			anchors.fill: parent
			source: card.wallpaper.path ? "file://" + card.wallpaper.path : ""
			// Decoded small: these are previews, the originals can be 4K
			sourceSize: Qt.size(480, 300)
			fillMode: Image.PreserveAspectCrop
			asynchronous: true
			smooth: true
			visible: false
			layer.enabled: true
		}

		NotchRect {
			id: shape

			anchors.fill: parent
			notch: Theme.notch
			tabStep: Theme.cardTab
			fillColor: "white"
			strokeColor: "transparent"
			visible: false
			layer.enabled: true
		}

		MultiEffect {
			anchors.fill: parent
			source: image
			maskEnabled: true
			maskSource: shape
			maskThresholdMin: 0.5
			maskSpreadAtMin: 1
			autoPaddingEnabled: false
		}

		// Not decoded yet (or missing): the card stays a card
		NotchRect {
			visible: image.status !== Image.Ready
			anchors.fill: parent
			notch: Theme.notch
			tabStep: Theme.cardTab
			fillColor: Colors.bg
			strokeColor: "transparent"
		}

		NotchRect {
			anchors.fill: parent
			notch: Theme.notch
			tabStep: Theme.cardTab
			fillColor: "transparent"
			strokeColor: Colors.structure
			// Heavier frame on the focused card: 2 physical px at the 1.5x scale
			strokeWidth: card.focused ? 4 / 3 : Theme.borderWidth
		}

		// Off focus: a dark veil, not transparency
		NotchRect {
			anchors.fill: parent
			notch: Theme.notch
			tabStep: Theme.cardTab
			fillColor: Qt.rgba(0, 0, 0, 0.55)
			strokeColor: "transparent"
			opacity: card.focused ? 0 : 1

			Behavior on opacity {
				NumberAnimation {
					duration: 120
				}
			}
		}
	}

	Item {
		anchors.top: frame.bottom
		anchors.topMargin: 10
		width: parent.width
		height: name.implicitHeight

		BarText {
			id: name

			width: parent.width - 80
			elide: Text.ElideRight
			text: card.wallpaper.name
			color: card.focused ? Colors.structure : Colors.fgDim
		}

		Chip {
			anchors.right: parent.right
			anchors.verticalCenter: name.verticalCenter
			text: card.active ? "Active" : ""
			tone: Colors.accent
		}
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: card.picked()
	}
}
