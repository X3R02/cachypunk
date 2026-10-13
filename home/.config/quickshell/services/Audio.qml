// PipeWire state and actions shared by the bar's volume module, its panel and
// the OSD. Every volume change lands on the 5% grid, so the 20-block meters
// always end on a whole block.
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
	id: root

	readonly property var sink: Pipewire.defaultAudioSink
	readonly property var source: Pipewire.defaultAudioSource

	// Node names whose active port reports nothing plugged in (the headset
	// jack's mic with no headset), read from pactl: PwNode doesn't carry
	// port availability
	property var unplugged: []

	function listed(n): bool {
		return !unplugged.includes(n.name) || n === sink || n === source;
	}

	// Hardware endpoints only, minus unplugged ones (the default always
	// stays, so you can see what is selected); app streams are wiremix's
	// business ("Advanced")
	readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream && listed(n))
	readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream && listed(n))

	function volume(node): real {
		return node?.audio?.volume ?? 0;
	}

	function muted(node): bool {
		return node?.audio?.muted ?? false;
	}

	function setVolume(node, value: real): void {
		if (!node?.audio)
			return;
		node.audio.volume = Math.max(0, Math.min(1, Math.round(value * 20) / 20));
	}

	// One block up or down from wherever the level is now, snapping a level
	// that is off the grid (set by another app) to the next block
	function step(node, dir: int): void {
		const cur = Math.round(volume(node) * 100);
		const next = dir > 0 ? Math.floor(cur / 5) * 5 + 5 : Math.ceil(cur / 5) * 5 - 5;
		setVolume(node, next / 100);
	}

	function toggleMute(node): void {
		if (node?.audio)
			node.audio.muted = !node.audio.muted;
	}

	function setDefault(node): void {
		if (node.isSink)
			Pipewire.preferredDefaultAudioSink = node;
		else
			Pipewire.preferredDefaultAudioSource = node;
	}

	// Leading words a node's description shares with the other endpoints of
	// the same card ("Ryzen HD Audio Controller" on "... Speaker" and
	// "... Digital Microphone"), which say nothing in a list of them. Nodes are
	// grouped by their first word, so a headset named on its own keeps its name.
	function sharedPrefix(node): string {
		const words = (node?.description || "").split(" ");
		const group = sinks.concat(sources).map(n => (n.description || "").split(" ")).filter(w => w[0] === words[0]);
		if (group.length < 2)
			return "";
		let shared = words.length;
		for (const other of group) {
			let i = 0;
			while (i < shared && other[i] === words[i])
				i++;
			shared = i;
		}
		return shared > 0 ? words.slice(0, shared).join(" ") + " " : "";
	}

	function name(node): string {
		return node?.description || node?.nickname || node?.name || "";
	}

	// The name without the card's shared prefix, for lists of endpoints
	function shortName(node): string {
		const full = name(node);
		const prefix = sharedPrefix(node);
		return prefix !== "" && full.startsWith(prefix) && full.length > prefix.length ? full.slice(prefix.length) : full;
	}

	function headphones(node): bool {
		// Bluetooth audio nodes carry no form factor; on a laptop they are
		// headphones or a headset in practice
		if ((node?.name ?? "").startsWith("bluez_"))
			return true;
		const p = node?.properties ?? {};
		const ff = p["device.form-factor"] ?? "";
		return ff === "headphone" || ff === "headset" || /headphone/i.test(p["device.profile.description"] ?? "");
	}

	function sinkIcon(node): string {
		if (muted(node))
			return "󰝟";
		if (headphones(node))
			return "󰋋";
		return ["󰕿", "󰖀", "󰕾"][Math.min(2, Math.floor(volume(node) * 100 / 34))];
	}

	function sourceIcon(node): string {
		return muted(node) ? "󰍭" : "󰍬";
	}

	// Binds the defaults so their audio properties are live
	PwObjectTracker {
		objects: [root.sink, root.source]
	}

	// Port availability, refreshed whenever pactl reports a card, sink or
	// source change (plugging a headset in, a profile switch)
	Process {
		id: ports

		running: true
		command: ["sh", "-c", "printf '['; pactl -f json list sinks; printf ','; pactl -f json list sources; printf ']'"]
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					const lists = JSON.parse(text);
					// (no Array.flat in QML's JS engine)
					root.unplugged = [].concat(...lists).filter(n => (n.ports ?? []).some(p => p.name === n.active_port && p.availability === "not available")).map(n => n.name);
				} catch (e) {
					// Keep the last good list
				}
			}
		}
	}

	Process {
		running: true
		command: ["pactl", "subscribe"]
		stdout: SplitParser {
			onRead: line => {
				if (/ on (card|sink|source) /.test(line))
					refresh.restart();
			}
		}
	}

	// Changes come in bursts; read once they settle
	Timer {
		id: refresh

		interval: 300
		onTriggered: ports.running = true
	}
}
