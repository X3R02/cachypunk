// One notification as a plain square box (no tab, inner bar or corner cut): app icon or image, the summary in accent
// caps, the body as plain text, a progress meter when the sender gives a
// value, and its actions. A click runs the default action (or dismisses), a
// right-click dismisses; hovering pauses the timeout. Critical notifications
// have an alert frame and stay until dismissed.
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs
import qs.services

Item {
	id: card

	required property var modelData
	readonly property var n: modelData
	readonly property bool critical: n.urgency === NotificationUrgency.Critical
	readonly property string iconSource: n.image !== "" ? n.image : n.appIcon !== "" ? Quickshell.iconPath(n.appIcon, true) : ""
	readonly property var progress: n.hints?.value

	width: 380
	height: frame.implicitHeight

	Timer {
		running: Notifs.timeout(card.n) > 0 && !mouse.containsMouse
		interval: Notifs.timeout(card.n)
		onTriggered: card.n.expire()
	}

	MouseArea {
		id: mouse

		anchors.fill: parent
		hoverEnabled: true
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		onClicked: m => m.button === Qt.RightButton ? card.n.dismiss() : Notifs.click(card.n)
	}

	Frame {
		id: frame

		width: parent.width
		simple: true
		// The coral frame mako had, a touch heavier than the panels' line:
		// 2 physical px at the 1.5x scale, so it stays crisp
		strokeColor: card.critical ? Colors.alert : Colors.structure
		strokeWidth: 4 / 3
		// Square: a plain box, no corner cut
		notch: 0

		Row {
			width: card.width - frame.padding * 2
			spacing: 12

			Image {
				id: icon

				visible: card.iconSource !== "" && status !== Image.Error
				width: visible ? 32 : 0
				height: 32
				source: card.iconSource
				sourceSize.width: 64
				sourceSize.height: 64
				fillMode: Image.PreserveAspectFit
				smooth: true
				mipmap: true
			}

			Column {
				width: parent.width - (icon.visible ? icon.width + parent.spacing : 0)
				spacing: 4

				Item {
					width: parent.width
					height: summary.implicitHeight

					BarText {
						id: summary

						width: parent.width - app.implicitWidth - 8
						elide: Text.ElideRight
						text: card.n.summary
						color: card.critical ? Colors.alert : Colors.accent
					}
					BarText {
						id: app

						anchors.right: parent.right
						text: card.n.appName
						color: Colors.muted
					}
				}

				BarText {
					width: parent.width
					visible: text !== ""
					caps: false
					text: card.n.body
					textFormat: Text.StyledText
					wrapMode: Text.Wrap
					maximumLineCount: 4
					elide: Text.ElideRight
					// Prose in red, sentence case, as the game writes it
					color: Colors.structure
				}

				SegmentBar {
					visible: card.progress !== undefined
					width: parent.width
					height: 5
					segments: 32
					value: (card.progress ?? 0) / 100
				}

				Flow {
					width: parent.width
					visible: card.n.actions.some(a => a.identifier !== "default")
					spacing: 4

					Repeater {
						model: card.n.actions.filter(a => a.identifier !== "default")

						PanelButton {
							required property var modelData

							label: modelData.text
							onClicked: modelData.invoke()
						}
					}
				}
			}
		}
	}
}
