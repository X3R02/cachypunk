// The polkit authentication agent, in place of hyprpolkitagent: when an app
// asks for privileges (pkexec, a settings change), the game's dialog asks for
// the password - the screen dims, a dialog card (ModalCard: bracket,
// gapper, cell) holds the request, and BACK / AUTHENTICATE sit under it
// joined by a short line, as in the game's confirmations. Enter
// authenticates, Escape cancels. The password is checked by polkit's own
// helper, never here: this only passes the typed text to the AuthFlow.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import Quickshell.Wayland
import QtQuick
import qs

PanelWindow {
	id: dialog

	readonly property var flow: agent.flow
	// PAM tries the fingerprint first and only then asks for the password;
	// the field shows up at that point, not before
	readonly property bool wantsPassword: flow?.isResponseRequired ?? false
	// PAM's note as one plain line. The fprintd catalog in ~/.config/auth-prompts/
	// draws its prompts as a terminal panel; keep only the "//" line, without
	// colour and cursor codes or the corner glyph
	readonly property string note: {
		const lines = (flow?.supplementaryMessage ?? "").replace(/\x1b\[[0-9;]*[A-Za-z]/g, "").replace(/◤/g, "").split("\n");
		const line = lines.find(l => l.includes("//")) ?? lines.find(l => l.trim() !== "") ?? "";
		return line.trim().replace(/\s+/g, " ");
	}
	// Buttons read these to draw the mouse hover (no keyboard cursor here:
	// the password field has the keyboard)
	readonly property bool keyboardNav: false
	readonly property bool shown: agent.isActive && flow !== null && !flow.isCompleted

	function submit(): void {
		if (!flow || !flow.isResponseRequired)
			return;
		flow.submit(input.text);
		input.text = "";
	}

	function cancel(): void {
		flow?.cancelAuthenticationRequest();
		input.text = "";
	}

	screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
	visible: shown
	color: "transparent"
	anchors {
		top: true
		bottom: true
		left: true
		right: true
	}
	exclusionMode: ExclusionMode.Ignore

	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.namespace: "quickshell-polkit"
	WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

	onShownChanged: if (shown)
		keys.forceActiveFocus()

	PolkitAgent {
		id: agent
	}

	// Everything behind the dialog dims; no red wash (the user's choice)
	Rectangle {
		anchors.fill: parent
		color: Qt.rgba(Colors.bgDeep.r, Colors.bgDeep.g, Colors.bgDeep.b, 0.65)
	}

	// Holds the keyboard while the field is disabled (polkit is waiting on
	// the fingerprint reader first), so Escape always cancels
	Item {
		id: keys

		anchors.fill: parent
		focus: true
		Keys.onEscapePressed: dialog.cancel()
	}

	Column {
		anchors.centerIn: parent
		spacing: 14

	ModalCard {
		id: frame

		contentWidth: 400

		Column {
			width: 400
			spacing: 8

			BarText {
				text: "Authentication required"
				color: Colors.structure
				font.pixelSize: 18
			}

			// Prose in the dialog's red, sentence case, as the game writes it
			BarText {
				width: parent.width
				caps: false
				wrapMode: Text.Wrap
				text: dialog.flow?.message ?? ""
				color: Colors.structure
			}

			// Who is authenticating, when polkit offers a choice of admins
			BarText {
				visible: (dialog.flow?.identities.length ?? 0) > 1
				caps: false
				text: "As " + (dialog.flow?.selectedIdentity?.displayName ?? "")
				color: Colors.fgDim
			}

			Item {
				width: parent.width
				height: 8
			}

			// Fingerprint stage: what polkit says ("Place your right index
			// finger…"), with nothing to type yet
			Row {
				visible: !dialog.wantsPassword
				width: parent.width
				spacing: 12

				BarIcon {
					anchors.verticalCenter: parent.verticalCenter
					text: "󰈷"
					font.pixelSize: 26
					color: dialog.flow?.supplementaryIsError ? Colors.alert : Colors.accent
				}

				BarText {
					anchors.verticalCenter: parent.verticalCenter
					width: parent.width - 40
					caps: false
					wrapMode: Text.Wrap
					text: dialog.note || "Waiting for the fingerprint reader"
					color: dialog.flow?.supplementaryIsError ? Colors.alert : Colors.fg
				}
			}

			NotchRect {
				visible: dialog.wantsPassword
				width: parent.width
				height: 34
				notch: Theme.notchTiny
				fillColor: Colors.bg
				strokeColor: input.activeFocus ? Colors.accent : Colors.line

				TextInput {
					id: input

					anchors.fill: parent
					anchors.leftMargin: 10
					anchors.rightMargin: 10
					verticalAlignment: TextInput.AlignVCenter
					enabled: dialog.wantsPassword
					echoMode: dialog.flow?.responseVisible ? TextInput.Normal : TextInput.Password
					passwordCharacter: "•"
					color: Colors.accent
					selectionColor: Colors.selected
					font.family: Theme.textFont
					font.pixelSize: Theme.textSize
					font.weight: Font.DemiBold
					font.hintingPreference: Font.PreferNoHinting
					renderType: Text.NativeRendering
					clip: true
					// Takes the keyboard as soon as polkit wants a response
					onEnabledChanged: if (enabled)
						forceActiveFocus()
					onAccepted: dialog.submit()
					Keys.onEscapePressed: dialog.cancel()

					BarText {
						anchors.verticalCenter: parent.verticalCenter
						visible: input.text === ""
						caps: false
						// polkit's own prompt ("Password: ") without the colon
						text: (dialog.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
						color: Colors.muted
					}
				}
			}

			// Wrong password and other notes from polkit, once it asks for one
			BarText {
				width: parent.width
				visible: dialog.wantsPassword && text !== ""
				caps: false
				wrapMode: Text.Wrap
				text: dialog.note
				color: dialog.flow?.supplementaryIsError ? Colors.alert : Colors.fgDim
			}

			// Device fiction, as on every dialog in the game
			BarText {
				width: parent.width
				topPadding: 4
				wrapMode: Text.Wrap
				text: "Only CC35 certified and DHSF 5th class officers are allowed to manipulate, access or disable this device."
				color: Qt.rgba(Colors.structure.r, Colors.structure.g, Colors.structure.b, 0.6)
				font.pixelSize: 8
			}
		}
	}

		Row {
			anchors.right: parent.right
			spacing: 0

			PanelButton {
				width: 150
				label: "Back"
				// Alone while the reader waits; first of a pair once the
				// password field shows
				cut: dialog.wantsPassword ? "left" : "right"
				onClicked: dialog.cancel()
			}

			// The short line joining the two buttons
			Rectangle {
				visible: dialog.wantsPassword
				anchors.verticalCenter: parent.verticalCenter
				width: 18
				height: Theme.borderWidth
				color: Colors.structure
			}

			PanelButton {
				width: 150
				label: "Authenticate"
				visible: dialog.wantsPassword
				onClicked: dialog.submit()
			}
		}
	}
}
