// Notifications: a bell with the count of unread ones, struck through while
// Do not disturb is on. Click (or SUPER + CTRL + N) opens the panel: the Do not
// disturb switch, the latest notifications as cards (the game's journal: app
// and age as the label, the title, the body under it) and "Clear all" as the
// last row. There is no "Advanced": the history lives here and nowhere else.
// Opening the panel marks everything read. Each card is an entry: Enter or a
// click runs its action while its app still listens (else focuses the app's
// window), Delete or a right-click twice removes it.
import Quickshell
import QtQuick
import qs
import qs.services

Module {
	id: mod

	required property var barWindow
	required property string screenName

	readonly property string key: "notifications:" + screenName
	panelKey: key
	// The cards the panel shows; the rest of the history waits behind them
	readonly property int shown: 6
	// Bumped every 30 s while the panel is open, so the ages stay current
	property int tick: 0
	// Key of the card whose first Delete is waiting for a second
	property string armedRemove: ""

	function age(time: real): string {
		void mod.tick;
		const s = Math.max(0, (Date.now() - time) / 1000);
		if (s < 60)
			return "now";
		if (s < 3600)
			return Math.floor(s / 60) + "m";
		if (s < 86400)
			return Math.floor(s / 3600) + "h";
		return Math.floor(s / 86400) + "d";
	}

	icon: Notifs.dnd ? "󰂛" : Notifs.unread > 0 ? "󰂞" : "󰂚"
	iconColor: panel.open ? Colors.accent : Notifs.dnd ? Colors.muted : Notifs.unread > 0 ? Colors.accent : Colors.structure
	value: Notifs.unread > 0 ? String(Notifs.unread) : ""
	tooltip: panel.open ? "" : Notifs.dnd ? "Do not disturb" : Notifs.unread > 0 ? Notifs.unread + " unread" : "Notifications"
	marked: panel.open
	onClicked: Panels.toggle(key)

	Timer {
		interval: 30000
		running: panel.open
		repeat: true
		onTriggered: mod.tick++
	}

	Panel {
		id: panel

		target: mod
		barWindow: mod.barWindow
		key: mod.key

		onOpenChanged: {
			mod.armedRemove = "";
			if (open) {
				mod.tick++;
				Notifs.markRead();
			}
		}

		PanelButton {
			width: Theme.panelWidth
			icon: Notifs.dnd ? "󰂛" : "󰂚"
			label: Notifs.dnd ? "Do not disturb on" : "Do not disturb off"
			color: Notifs.dnd ? Colors.accent : Colors.muted
			onClicked: Notifs.setDnd(!Notifs.dnd)
		}

		PanelDivider {}

		BarText {
			visible: Notifs.history.length === 0
			x: Theme.modulePadding
			height: Theme.rowHeight
			verticalAlignment: Text.AlignVCenter
			caps: false
			text: "Nothing yet"
			color: Colors.muted
		}

		// The journal: one card per notification, newest first
		Column {
			visible: Notifs.history.length > 0
			width: Theme.panelWidth
			spacing: 6

			Repeater {
				// Matched by key, so a new notification doesn't rebuild the
				// cards and the cursor stays where it was
				model: ScriptModel {
					values: Notifs.history.slice(0, mod.shown)
					objectProp: "key"
				}

				// A panel entry: Enter or a click runs the notification's
				// action (or focuses its app), Delete twice removes it
				Item {
					id: card

					required property var modelData

					readonly property bool navigable: true
					readonly property var panelWindow: QsWindow.window
					readonly property bool hovered: panelWindow?.keyboardNav ? panelWindow.cursor === card : mouse.containsMouse
					readonly property bool armed: mod.armedRemove !== "" && mod.armedRemove === (modelData?.key ?? "")

					function activate(): void {
						states.flash();
						Panels.close(mod.key);
						Notifs.activate(modelData);
					}

					function secondary(): void {
						if (!armed) {
							mod.armedRemove = modelData?.key ?? "";
							return;
						}
						mod.armedRemove = "";
						Notifs.remove(modelData);
					}

					width: Theme.panelWidth
					height: text.implicitHeight + 16

					EntryFrame {
						id: states

						focused: card.hovered
					}

					// A critical one keeps its alert frame at rest
					NotchRect {
						visible: (card.modelData?.critical ?? false) && !card.hovered
						anchors.fill: parent
						notch: Theme.notchSmall
						fillColor: "transparent"
						strokeColor: Colors.alert
					}

					MouseArea {
						id: mouse

						anchors.fill: parent
						hoverEnabled: true
						acceptedButtons: Qt.LeftButton | Qt.RightButton
						onEntered: card.panelWindow?.takeCursor(card)
						onClicked: m => m.button === Qt.RightButton ? card.secondary() : card.activate()
					}

					Column {
						id: text

						x: Theme.modulePadding
						y: 8
						width: parent.width - Theme.modulePadding * 2
						spacing: 2

						Item {
							width: parent.width
							height: appName.implicitHeight

							BarText {
								id: appName

								width: parent.width - 48
								elide: Text.ElideRight
								text: (card.modelData?.app ?? "")
								color: (card.modelData?.critical ?? false) ? Colors.alert : Colors.structure
							}
							BarText {
								visible: !card.armed
								anchors.right: parent.right
								caps: false
								text: mod.age(card.modelData?.time ?? Date.now())
								color: Colors.accent
							}
							Chip {
								visible: card.armed
								anchors.right: parent.right
								anchors.verticalCenter: parent.verticalCenter
								text: "Again to remove"
								tone: Colors.alert
							}
						}
						BarText {
							visible: text !== ""
							width: parent.width
							elide: Text.ElideRight
							caps: false
							text: (card.modelData?.summary ?? "")
							color: Colors.fg
						}
						BarText {
							visible: text !== ""
							width: parent.width
							wrapMode: Text.Wrap
							maximumLineCount: 2
							elide: Text.ElideRight
							caps: false
							text: (card.modelData?.body ?? "")
							color: Colors.fgDim
						}
					}
				}
			}
		}

		BarText {
			visible: Notifs.history.length > mod.shown
			x: Theme.modulePadding
			height: 24
			verticalAlignment: Text.AlignVCenter
			caps: false
			text: (Notifs.history.length - mod.shown) + " older"
			color: Colors.muted
		}

		PanelDivider {}

		PanelButton {
			width: Theme.panelWidth
			icon: "󰎟"
			label: "Clear all"
			enabled: Notifs.history.length > 0
			onClicked: Notifs.clearHistory()
		}
	}
}
