// The wallpaper image, in place of awww. theme-set points
// ~/.config/theme/wallpaper at the theme's image; this resolves that link at
// start and again on `qs ipc call wallpaper reload` (hypr-wallpaper-apply,
// run by theme-set), so every screen's background follows the theme.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
	id: root

	// Resolved target of the link, "" until read (or when it is missing)
	property string path: ""

	function reload(): void {
		resolver.running = true;
	}

	Process {
		id: resolver

		running: true
		command: ["readlink", "-f", Quickshell.env("HOME") + "/.config/theme/wallpaper"]
		stdout: StdioCollector {
			onStreamFinished: root.path = text.trim()
		}
	}
}
