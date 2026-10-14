// AI agent usage limits. Records come from ~/.local/bin/agent-usage, which runs
// one collector per agent (agent-usage-<agent>; Claude's vendored from
// Omarchy) and prints, as JSON, only the agents in use: a collector reports
// `ready: false` for an agent that is missing, signed out or unused. The only
// per-agent knowledge here is each one's tab glyph (`icons`, the robot for
// any other). The bar shows the limit closest to running out across all of
// them; click opens the panel with one folder tab per agent on the card's
// top edge (PanelTabs: click or Enter on a tab, Left/Right on it, or Q / E
// anywhere), showing that agent's limits and when each one resets.
import Quickshell
import Quickshell.Io
import QtQuick
import qs

Module {
	id: mod

	required property var barWindow
	required property string screenName

	readonly property string key: "agents:" + screenName
	panelKey: key
	property var records: []
	// The tab shown, kept by agent id so it survives records being reordered
	// or an agent appearing; falls back to the first tab
	property string currentId: ""
	// Tab glyphs from Symbols Nerd Font: codicons' Claude mark; Antigravity
	// has no glyph of its own, so it takes Gemini's four-point star
	readonly property var icons: ({
			"claude": "\uec82",
			"agy": "\u{f0ae2}"
		})
	readonly property int currentIndex: Math.max(0, records.findIndex(r => r.id === currentId))
	readonly property var current: records[currentIndex] ?? null
	readonly property var tightest: {
		let best = null;
		for (const r of records)
			for (const l of r.limits ?? [])
				if (!best || l.percent > best.percent)
					best = Object.assign({ agent: r.name }, l);
		return best;
	}

	function levelColor(percent: real): color {
		return percent >= 0.95 ? Colors.alert : percent >= 0.8 ? Colors.warn : Colors.accent;
	}

	function refresh(args: list<string>): void {
		if (collector.running)
			return;
		collector.command = [Quickshell.env("HOME") + "/.local/bin/agent-usage"].concat(args);
		collector.running = true;
	}

	function untilReset(iso: string): string {
		if (!iso)
			return "";
		const minutes = Math.max(0, Math.round((new Date(iso) - clock.date) / 60000));
		const d = Math.floor(minutes / 1440), h = Math.floor(minutes % 1440 / 60), m = minutes % 60;
		return "Resets in " + (d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "m" : m + "m");
	}

	function compact(n: real): string {
		return n >= 1e6 ? (n / 1e6).toFixed(1) + "M" : n >= 1e3 ? Math.round(n / 1e3) + "k" : String(n);
	}

	visible: records.length > 0
	icon: "󰚩"
	iconColor: tightest && tightest.percent >= 0.8 ? levelColor(tightest.percent) : Colors.structure
	// Icon only, to keep the bar short: its colour turns at 80%, the figure
	// is in the tooltip and the panel
	tooltip: panel.open || !tightest ? "" : tightest.agent + " " + Math.round(tightest.percent * 100) + "%"
	marked: panel.open
	onClicked: Panels.toggle(key)

	SystemClock {
		id: clock

		precision: SystemClock.Minutes
	}

	Process {
		id: collector

		stdout: StdioCollector {
			onStreamFinished: {
				try {
					mod.records = JSON.parse(text);
				} catch (e) {
					// Keep the last good records; the runner already logged why
				}
			}
		}
	}

	// The usage endpoint rate-limits readily, so the regular check is slow;
	// opening the panel asks for fresh limits (the collector still reuses a
	// probe younger than 15s).
	Timer {
		running: true
		interval: 10 * 60 * 1000
		repeat: true
		triggeredOnStart: true
		onTriggered: mod.refresh([])
	}

	Panel {
		id: panel

		target: mod
		barWindow: mod.barWindow
		key: mod.key
		onOpenChanged: if (open)
			mod.refresh(["--limits-only"])

		tabIcons: mod.records.map(r => mod.icons[r.id] ?? "󰚩")
		tabIndex: mod.currentIndex
		onTabIndexChanged: mod.currentId = mod.records[tabIndex]?.id ?? ""

		// The current tab's agent; only one is ever drawn
		Column {
			id: agent

			readonly property var modelData: mod.current ?? ({})
			readonly property real inner: width - leftPadding - rightPadding

			visible: mod.current !== null
			width: Theme.panelWidth
			leftPadding: Theme.modulePadding
			rightPadding: Theme.modulePadding
			topPadding: 6
			bottomPadding: 6
			spacing: 6

			// The tabs show only glyphs, so the agent is named here
			Row {
				spacing: 8

				BarText {
					text: agent.modelData.name ?? ""
					color: Colors.accent
				}
				BarText {
					text: agent.modelData.tierLabel ?? ""
					color: Colors.muted
				}
			}

			// Sign-in or endpoint trouble, in the collector's own words
			BarText {
				width: agent.inner
				visible: text !== ""
				text: agent.modelData.authHelpText || agent.modelData.usageStatusText || ""
				caps: false
				wrapMode: Text.WordWrap
				color: Colors.alert
			}

			Repeater {
				model: agent.modelData.limits ?? []

				Column {
					id: limit

					required property var modelData

					width: agent.inner
					spacing: 4
					// Numbers kept past a failed check are shown, but dimmed
					opacity: agent.modelData.limitsStale ? 0.5 : 1

					Item {
						width: parent.width
						height: label.implicitHeight

						BarText {
							id: label

							text: limit.modelData.label
							color: Colors.structure
						}
						BarText {
							anchors.right: parent.right
							text: Math.round(limit.modelData.percent * 100) + "%"
							color: mod.levelColor(limit.modelData.percent)
						}
					}

					SegmentBar {
						width: parent.width
						height: 5
						value: limit.modelData.percent
						fillColor: limit.modelData.percent >= 0.8 ? mod.levelColor(limit.modelData.percent) : Colors.accent
					}

					BarText {
						visible: text !== ""
						text: mod.untilReset(limit.modelData.resetsAt ?? "")
						color: Colors.muted
					}
				}
			}

			// Agents that report no token counts (agy) show prompts only
			BarText {
				visible: (agent.modelData.todayPrompts ?? 0) > 0
				text: "Today  " + ((agent.modelData.todayTotalTokens ?? 0) > 0 ? mod.compact(agent.modelData.todayTotalTokens) + " tokens  ·  " : "") + agent.modelData.todayPrompts + " prompts"
				color: Colors.fgDim
			}
		}

		PanelDivider {}

		PanelButton {
			width: Theme.panelWidth
			icon: "󰑐"
			label: collector.running ? "Checking…" : "Refresh"
			enabled: !collector.running
			onClicked: mod.refresh([])
		}
	}
}
