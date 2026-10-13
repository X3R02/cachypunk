// The notification daemon (org.freedesktop.Notifications), in place of mako.
// Every notification that arrives is recorded in `history` (newest first,
// the last 50) for the bar's notifications panel, and shown as a card by
// notifications/NotificationPopups.qml (`list`) until it times out or is
// dismissed. Do not disturb skips the card but still records it; critical
// notifications always show.
//
// A card that times out is only hidden, not closed: the notification stays
// alive for its app, so its action (open the chat, go to the tab) still works
// from the history. Only the history's 50 stay alive; older ones are closed.
// When one has no action left, activating it focuses its app's window.
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

	// Notifications still open for their app
	readonly property var live: server.trackedNotifications.values
	// The ones showing as cards: alive and not hidden
	readonly property var list: live.filter(n => !hidden[n.id])
	readonly property int historyLimit: 50

	// Survive a config reload: the history and the switch are what the panel
	// shows, and a reload must not clear them or turn DND off. Kept as JSON
	// text: a JS object can't move to the reloaded engine
	readonly property var history: JSON.parse(persist.history || "[]")
	readonly property int unread: persist.unread ?? 0
	readonly property bool dnd: persist.dnd ?? false
	// Ids of live notifications whose card is gone (timed out or cleared)
	readonly property var hidden: JSON.parse(persist.hidden || "{}")

	PersistentProperties {
		id: persist

		reloadableId: "notifs"
		property string history: "[]"
		property int unread: 0
		property bool dnd: false
		property string hidden: "{}"
	}

	function setDnd(on: bool): void {
		persist.dnd = on;
	}

	function markRead(): void {
		persist.unread = 0;
	}

	function clearHistory(): void {
		for (const n of live.slice())
			n.dismiss();
		persist.history = "[]";
		persist.unread = 0;
		persist.hidden = "{}";
	}

	function find(id: int) {
		return live.find(n => n.id === id) ?? null;
	}

	// Take the card away but keep the notification open for its app
	function hide(n): void {
		const next = {};
		for (const other of live)
			if (hidden[other.id])
				next[other.id] = true;
		next[n.id] = true;
		persist.hidden = JSON.stringify(next);
	}

	// The window of the app an entry came from
	function focusApp(entry): void {
		Quickshell.execDetached([Quickshell.shellDir + "/scripts/focus-app.sh", entry.desktop ?? "", entry.app ?? ""]);
	}

	// From the history: the notification's own action while it is alive,
	// else its app's window
	function activate(entry): void {
		const n = find(entry.id);
		const action = n ? defaultAction(n) : null;
		if (action) {
			action.invoke();
			hide(n);
		} else {
			focusApp(entry);
		}
	}

	function remove(entry): void {
		const n = find(entry.id);
		if (n)
			n.dismiss();
		persist.history = JSON.stringify(history.filter(e => !(e.id === entry.id && e.time === entry.time)));
	}

	// Bodies may carry markup; the history keeps plain text
	function plain(text: string): string {
		return text.replace(/<[^>]*>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").trim();
	}

	function record(n): void {
		const now = Date.now();
		const entry = {
			// Stable identity for the panel's list, so the cursor survives
			key: n.id + ":" + now,
			id: n.id,
			desktop: n.desktopEntry,
			app: n.appName || "Notification",
			summary: plain(n.summary),
			body: plain(n.body),
			time: now,
			critical: n.urgency === NotificationUrgency.Critical
		};
		const all = [entry].concat(history);
		// What falls out of the history is closed for good
		for (const old of all.slice(historyLimit)) {
			const stale = find(old.id);
			if (stale)
				stale.dismiss();
		}
		persist.history = JSON.stringify(all.slice(0, historyLimit));
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

	// A click on a card: the default action, else the app's window
	function click(n): void {
		const action = defaultAction(n);
		if (action)
			action.invoke();
		else
			focusApp({ desktop: n.desktopEntry, app: n.appName });
		hide(n);
	}

	// Clears the cards; the notifications stay in the history, still usable
	function dismissAll(): void {
		for (const n of list.slice())
			hide(n);
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
			// Tracked either way, so its action stays usable from the history
			n.tracked = true;
			// Do not disturb: no card, unless it is critical
			if (root.dnd && n.urgency !== NotificationUrgency.Critical)
				root.hide(n);
		}
	}
}
