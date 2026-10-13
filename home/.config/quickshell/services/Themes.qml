// The colour themes: every palette in ~/.config/matugen/themes/ and which one
// is active (~/.config/matugen/current, written by theme-set). apply() runs
// theme-set detached; it re-renders every template - including Colors.qml, so
// the shell itself reloads into the new theme.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
	id: root

	// The `theme` object of each palette file, as theme-set reads them
	property var list: []
	property string current: ""
	property bool applying: false

	function reload(): void {
		reader.running = true;
	}

	function apply(name: string): void {
		if (applying || name === current)
			return;
		applying = true;
		// Detached: theme-set rewrites Colors.qml, which reloads this shell,
		// and a Process child would be killed in that reload - halfway
		// through, before theme-set reloads the terminal, GTK and the icons.
		// The reload brings `current` back fresh.
		Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/theme-set", name]);
	}

	Process {
		id: reader

		running: true
		command: ["sh", "-c", "printf '{\"current\":\"%s\",\"themes\":' \"$(cat \"$HOME/.config/matugen/current\" 2>/dev/null)\"; jq -s '[.[].theme]' \"$HOME\"/.config/matugen/themes/*.json; printf '}'"]
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					const data = JSON.parse(text);
					root.list = data.themes;
					root.current = data.current || (data.themes[0]?.name ?? "");
				} catch (e) {
					// Keep the last good list
				}
			}
		}
	}

}
