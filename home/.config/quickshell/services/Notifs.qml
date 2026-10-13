// The notification daemon (org.freedesktop.Notifications), in place of mako.
// Every notification that arrives is tracked and shown as a card by
// notifications/NotificationPopups.qml until it times out or is dismissed.
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
			n.tracked = true;
		}
	}
}
