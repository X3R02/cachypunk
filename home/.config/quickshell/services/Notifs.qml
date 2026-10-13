// The notification daemon (org.freedesktop.Notifications), in place of mako.
// Every notification that arrives is tracked and shown as a card by
// notifications/NotificationPopups.qml until it times out or is dismissed,
// and recorded in `history` (newest first, the last 50) for the bar's
// notifications panel. Do not disturb skips the card but still records it;
// critical notifications always show.
pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
	id: root

	// Default lifetime when the sender leaves it to the server (mako's 5s)
	readonly property int defaultTimeout: 5000
	// Apps whose notifications are dropped: Spotify announces every track
	readonly property var hiddenApps: ["Spotify"]

	readonly property var list: server.trackedNotifications.values
	readonly property int historyLimit: 50

	// Survive a config reload: the history and the switch are what the panel
	// shows, and a reload must not clear them or turn DND off
	readonly property var history: persist.history ?? []
	readonly property int unread: persist.unread ?? 0
	readonly property bool dnd: persist.dnd ?? false

	PersistentProperties {
		id: persist

		reloadableId: "notifs"
		property var history: []
		property int unread: 0
		property bool dnd: false
	}

	function setDnd(on: bool): void {
		persist.dnd = on;
	}

	function markRead(): void {
		persist.unread = 0;
	}

	function clearHistory(): void {
		persist.history = [];
		persist.unread = 0;
	}

	// Bodies may carry markup; the history keeps plain text
	function plain(text: string): string {
		return text.replace(/<[^>]*>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").trim();
	}

	function record(n): void {
		const entry = {
			app: n.appName || "Notification",
			summary: plain(n.summary),
			body: plain(n.body),
			time: Date.now(),
			critical: n.urgency === NotificationUrgency.Critical
		};
		persist.history = [entry].concat(persist.history).slice(0, historyLimit);
		persist.unread += 1;
	}

	function timeout(n): int {
		if (n.urgency === NotificationUrgency.Critical)
			return 0;
		return n.expireTimeout > 0 ? n.expireTimeout : defaultTimeout;
	}

	// The action a click on the card runs: the sender's "default" if it has one
	function defaultAction(n) {
		return n.actions.find(a => a.identifier === "default") ?? null;
	}

	function click(n): void {
		const action = defaultAction(n);
		if (action)
			action.invoke();
		else
			n.dismiss();
	}

	function dismissAll(): void {
		for (const n of list.slice())
			n.dismiss();
	}

	NotificationServer {
		id: server

		// Cards survive a config reload instead of vanishing mid-read
		keepOnReload: true
		bodySupported: true
		bodyMarkupSupported: true
		bodyHyperlinksSupported: false
		actionsSupported: true
		imageSupported: true
		persistenceSupported: true

		onNotification: n => {
			if (root.hiddenApps.includes(n.appName))
				return;
			root.record(n);
			// Do not disturb: recorded but no card, unless it is critical
			if (root.dnd && n.urgency !== NotificationUrgency.Critical)
				return;
			n.tracked = true;
		}
	}
}
