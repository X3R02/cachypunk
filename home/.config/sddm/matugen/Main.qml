// SDDM login screen, styled after Cyberpunk 2077's menus like the rest of the
// desktop and mirroring hyprlock (~/.config/hypr/hyprlock.conf): darkened
// wallpaper, the date as a label over the time as data, and the login as the
// desktop's dialog card (the same one as the polkit prompt, quickshell's
// ModalCard): solid bracket, gapper, and the cell with its tab and cut
// corner, holding the heading, the prompt and the password field. The bottom row works like the game's main menu: coral caps at
// rest, an accent-outlined card on hover.
//
// Colors come from theme.conf.user, which theme-set rewrites on every theme
// switch; background.jpg is the theme wallpaper, pre-blurred by theme-set
// because blurring at greeter start would delay the first frame. Rajdhani is
// installed system-wide by install.sh, since SDDM can't read ~/.local/share.
import QtQuick
import QtQuick.Shapes

Rectangle {
	id: root

	readonly property string textFont: "Rajdhani"
	readonly property int textSize: 16

	// Single-user machine: the last user, or the first one SDDM knows about
	property string userName: userModel.lastUser
	property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
	property bool failed: false
	property date now: new Date()

	width: 1920
	height: 1200
	color: config.bg

	Timer {
		interval: 1000
		running: true
		repeat: true
		onTriggered: root.now = new Date()
	}

	Repeater {
		model: userModel
		Item {
			required property int index
			required property string name
			Component.onCompleted: if (index === 0 && root.userName === "")
				root.userName = name
		}
	}

	// Session names, indexed like sessionModel, for the cycling selector
	property var sessionNames: []
	Repeater {
		model: sessionModel
		Item {
			required property int index
			required property string name
			Component.onCompleted: {
				const names = root.sessionNames.slice();
				names[index] = name;
				root.sessionNames = names;
			}
		}
	}

	Connections {
		target: sddm
		function onLoginFailed() {
			root.failed = true;
			password.text = "";
			password.forceActiveFocus();
		}
	}

	// The game's card: square corners, bottom-right cut at 45 degrees
	component Card: Shape {
		id: card

		property color fill: config.bg
		property color stroke: config.structure
		property real notch: 10

		preferredRendererType: Shape.CurveRenderer
		antialiasing: true

		ShapePath {
			fillColor: card.fill
			strokeColor: card.stroke
			strokeWidth: 1
			joinStyle: ShapePath.MiterJoin
			startX: 0.5
			startY: 0.5
			PathLine { x: card.width - 0.5; y: 0.5 }
			PathLine { x: card.width - 0.5; y: card.height - 0.5 - card.notch }
			PathLine { x: card.width - 0.5 - card.notch; y: card.height - 0.5 }
			PathLine { x: 0.5; y: card.height - 0.5 }
			PathLine { x: 0.5; y: 0.5 }
		}
	}

	// The dialog card, as quickshell's ModalCard draws it: a solid bracket
	// down the left, a dark gapper, then the cell - tab on the top edge,
	// bottom-right corner cut. Content goes in `body`.
	component DialogCard: Item {
		id: dialog

		default property alias content: body.data
		property real padding: 18
		property real contentWidth: 400
		readonly property real bracketWidth: 12
		readonly property real gapper: 3
		readonly property real tab: 3
		readonly property real notch: 10

		implicitWidth: bracketWidth + gapper + contentWidth + padding * 2
		implicitHeight: body.childrenRect.height + padding * 2 + tab

		Rectangle {
			anchors.fill: parent
			color: config.bg
			opacity: 0.95
		}

		Rectangle {
			width: dialog.bracketWidth
			height: parent.height
			color: config.structure
		}

		Shape {
			x: dialog.bracketWidth + dialog.gapper
			width: parent.width - x
			height: parent.height
			preferredRendererType: Shape.CurveRenderer
			antialiasing: true

			ShapePath {
				id: cell

				readonly property real w: dialog.width - dialog.bracketWidth - dialog.gapper
				readonly property real h: dialog.height
				readonly property real tabEnd: Math.min(w * 0.28, 120)

				fillColor: config.bg
				strokeColor: config.structure
				strokeWidth: 1
				joinStyle: ShapePath.MiterJoin
				startX: 0.5
				startY: 0.5
				PathLine { x: cell.tabEnd; y: 0.5 }
				PathLine { x: cell.tabEnd + dialog.tab; y: dialog.tab + 0.5 }
				PathLine { x: cell.w - 0.5; y: dialog.tab + 0.5 }
				PathLine { x: cell.w - 0.5; y: cell.h - 0.5 - dialog.notch }
				PathLine { x: cell.w - 0.5 - dialog.notch; y: cell.h - 0.5 }
				PathLine { x: 0.5; y: cell.h - 0.5 }
				PathLine { x: 0.5; y: 0.5 }
			}
		}

		Item {
			id: body

			x: dialog.bracketWidth + dialog.gapper + dialog.padding
			y: dialog.padding + dialog.tab
			width: dialog.contentWidth
			height: childrenRect.height
		}
	}

	component Caps: Text {
		font.family: root.textFont
		font.pixelSize: root.textSize
		font.weight: Font.DemiBold
		font.capitalization: Font.AllUppercase
		font.letterSpacing: 1
	}

	Image {
		anchors.fill: parent
		source: config.background
		fillMode: Image.PreserveAspectCrop
		asynchronous: false
	}

	Column {
		anchors.centerIn: parent
		spacing: 12

		Caps {
			anchors.horizontalCenter: parent.horizontalCenter
			color: config.structure
			font.pixelSize: 20
			text: Qt.formatDate(root.now, "dddd d MMMM")
		}

		Caps {
			anchors.horizontalCenter: parent.horizontalCenter
			color: config.accent
			font.pixelSize: 88
			font.letterSpacing: 2
			text: Qt.formatTime(root.now, "hh:mm")
		}

		Item {
			width: 1
			height: 16
		}

		DialogCard {
			anchors.horizontalCenter: parent.horizontalCenter

			Column {
				width: 400
				spacing: 10

				Caps {
					text: "Authentication required"
					color: config.structure
					font.pixelSize: 20
				}

				// Prose in the dialog's red, sentence case, as the game writes it
				Text {
					width: parent.width
					wrapMode: Text.Wrap
					font.family: root.textFont
					font.pixelSize: root.textSize
					font.weight: Font.DemiBold
					color: config.structure
					text: "Log in as " + root.userName + "."
				}

				Item {
					width: 1
					height: 4
				}

				Card {
					width: parent.width
					height: 40
					notch: 4
					stroke: root.failed ? config.alert : password.activeFocus ? config.accent : config.line

					TextInput {
						id: password

						anchors.fill: parent
						anchors.leftMargin: 12
						anchors.rightMargin: 12
						verticalAlignment: TextInput.AlignVCenter
						echoMode: TextInput.Password
						passwordCharacter: "•"
						color: config.accent
						selectionColor: config.selected
						font.family: root.textFont
						font.pixelSize: root.textSize
						font.weight: Font.DemiBold
						focus: true
						clip: true

						onTextEdited: root.failed = false
						onAccepted: sddm.login(root.userName, text, root.sessionIndex)
						Keys.onEscapePressed: text = ""
					}

					Text {
						anchors.left: parent.left
						anchors.leftMargin: 12
						anchors.verticalCenter: parent.verticalCenter
						visible: password.text === ""
						font.family: root.textFont
						font.pixelSize: root.textSize
						font.weight: Font.DemiBold
						color: config.muted
						text: "Password"
					}
				}

				Text {
					visible: root.failed
					font.family: root.textFont
					font.pixelSize: root.textSize
					font.weight: Font.DemiBold
					color: config.alert
					text: "Wrong password"
				}

				// Device fiction, as on every dialog in the game
				Caps {
					width: parent.width
					topPadding: 4
					wrapMode: Text.Wrap
					font.pixelSize: 9
					font.letterSpacing: 0.6
					color: config.structure
					opacity: 0.6
					text: "Only CC35 certified and DHSF 5th class officers are allowed to manipulate, access or disable this device."
				}
			}
		}
	}

	// Bottom row: the game's main menu - coral caps, an accent card on hover
	component Action: Item {
		id: action

		property string text
		signal triggered

		implicitWidth: label.implicitWidth + 30
		implicitHeight: 36

		Card {
			anchors.fill: parent
			visible: hover.containsMouse
			fill: config.bg
			stroke: config.accent
			notch: 8
		}

		Caps {
			id: label

			anchors.centerIn: parent
			anchors.horizontalCenterOffset: -2
			color: hover.containsMouse ? config.accent : config.structure
			text: action.text
		}

		MouseArea {
			id: hover

			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: action.triggered()
		}
	}

	// The game's full-screen frame: thin lines near both edges and dim device
	// micro-text in the top corners (STYLEGUIDE.md section 7) - decoration only
	Repeater {
		model: 2

		Rectangle {
			required property int index

			x: index === 0 ? 28 : root.width - 29
			anchors.verticalCenter: parent.verticalCenter
			width: 1
			height: root.height * 0.6
			color: config.line
		}
	}

	component Micro: Caps {
		font.pixelSize: 9
		font.letterSpacing: 0.6
		lineHeight: 1.2
		// config values arrive as strings, so dim with opacity rather than
		// building an rgba from the colour's channels (those are undefined)
		color: config.structure
		opacity: 0.6
	}

	Micro {
		anchors.left: parent.left
		anchors.top: parent.top
		anchors.leftMargin: 44
		anchors.topMargin: 32
		text: "Access terminal\nSecure login protocol v2.077"
	}

	Micro {
		anchors.right: parent.right
		anchors.top: parent.top
		anchors.rightMargin: 44
		anchors.topMargin: 32
		horizontalAlignment: Text.AlignRight
		text: "Model line 12.12AA\nImage type: ARM Linux kernel image"
	}

	Action {
		anchors.left: parent.left
		anchors.bottom: parent.bottom
		anchors.margins: 20
		visible: root.sessionNames.length > 0
		text: root.sessionNames[root.sessionIndex] ?? ""
		onTriggered: root.sessionIndex = (root.sessionIndex + 1) % root.sessionNames.length
	}

	Row {
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.margins: 20
		spacing: 8

		Action {
			visible: sddm.canSuspend
			text: "Suspend"
			onTriggered: sddm.suspend()
		}
		Action {
			visible: sddm.canReboot
			text: "Restart"
			onTriggered: sddm.reboot()
		}
		Action {
			visible: sddm.canPowerOff
			text: "Shut down"
			onTriggered: sddm.powerOff()
		}
	}
}
