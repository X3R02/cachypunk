// One theme in the switcher, drawn in that theme's own colours: a long card
// (cut corner, tab) on the theme's backing colour, its name in the theme's
// structure colour and a strip of swatches - the colours that change with it.
import QtQuick
import qs

Item {
	id: card

	required property var theme
	property bool focused: false
	property bool active: false

	signal picked

	readonly property var swatches: [
		{ key: "bg", label: "Base" },
		{ key: "surface", label: "Surface" },
		{ key: "structure", label: "Frame" },
		{ key: "accent", label: "Data" },
		{ key: "green", label: "Ok" },
		{ key: "yellow", label: "Warn" },
		{ key: "accent2", label: "Alert" }
	]

	implicitWidth: 460
	implicitHeight: 108
	scale: focused ? 1 : 0.92

	Behavior on scale {
		NumberAnimation {
			duration: 120
		}
	}

	NotchRect {
		anchors.fill: parent
		notch: Theme.notch
		tabStep: Theme.cardTab
		fillColor: card.theme.bg
		strokeColor: card.theme.structure
		// Heavier frame on the focused card: 2 physical px at the 1.5x scale
		strokeWidth: card.focused ? 4 / 3 : Theme.borderWidth
	}

	Column {
		x: 18
		y: 16
		width: parent.width - 36
		spacing: 12

		Item {
			width: parent.width
			height: title.implicitHeight

			BarText {
				id: title

				text: card.theme.name
				color: card.theme.structure
				font.pixelSize: 20
			}

			// The theme in use, labelled as the game labels states
			Chip {
				anchors.right: parent.right
				anchors.verticalCenter: title.verticalCenter
				text: card.active ? "Active" : ""
				tone: card.theme.accent
			}
		}

		Row {
			spacing: 6

			Repeater {
				model: card.swatches

				Column {
					required property var modelData

					spacing: 4

					Rectangle {
						width: 54
						height: 26
						color: card.theme[modelData.key]
						border.width: Theme.borderWidth
						border.color: card.theme.line
						antialiasing: false
					}

					BarText {
						text: modelData.label
						color: card.theme.fg_dim
						font.pixelSize: 10
					}
				}
			}
		}
	}

	// Cards off focus sink back under a dark veil - not transparency, which
	// let whatever is behind the switcher show through them
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

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: card.picked()
	}
}
