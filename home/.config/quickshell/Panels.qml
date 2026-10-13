// Which click-to-open panel is showing, as "<panel>:<screen>", or "" for none.
// Only one at a time: opening a panel closes whichever was open.
pragma Singleton

import Quickshell
import QtQuick

Singleton {
	property string current: ""

	function toggle(key: string): void {
		current = current === key ? "" : key;
	}

	function close(key: string): void {
		if (current === key)
			current = "";
	}
}
