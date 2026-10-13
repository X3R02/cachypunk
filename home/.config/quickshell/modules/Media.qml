// Now playing, from any MPRIS player (Brave tabs and webapps included). Click
// opens the controls, middle click toggles playback. Hidden with no player.
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import qs

Module {
	id: mod

	required property var barWindow
	required property string screenName

	readonly property string key: "media:" + screenName
	panelKey: key
	readonly property var players: Mpris.players.values
	// The one playing wins; otherwise the first, so a paused track stays in reach
	readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players[0] ?? null
	readonly property bool playing: player?.isPlaying ?? false
	readonly property string title: player?.trackTitle || player?.identity || ""
	readonly property string artist: player?.trackArtist ?? ""

	function time(seconds: real): string {
		const s = Math.max(0, Math.floor(seconds));
		return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
	}

	visible: player !== null
	icon: playing ? "󰝚" : "󰏤"
	iconColor: playing ? Colors.structure : Colors.muted
	marked: panel.open
	onClicked: mouse => {
		if (mouse.button === Qt.MiddleButton) {
			if (player?.canTogglePlaying)
				player.togglePlaying();
		} else {
			Panels.toggle(key);
		}
	}

	BarText {
		anchors.verticalCenter: parent.verticalCenter
		width: Math.min(implicitWidth, 260)
		elide: Text.ElideRight
		text: mod.artist ? mod.title + "  ·  " + mod.artist : mod.title
		color: mod.playing ? Colors.accent : Colors.muted
		// BarText's semibold: Rajdhani's regular weight is so thin that at the
		// 1.5x scale its strokes round unevenly and the title looked jagged
	}

	Panel {
		id: panel

		target: mod
		barWindow: mod.barWindow
		key: mod.key

		// MPRIS doesn't push position updates; poll while it can be seen moving
		Timer {
			running: panel.open && mod.playing
			interval: 1000
			repeat: true
			triggeredOnStart: true
			onTriggered: mod.player?.positionChanged()
		}

		Column {
			width: Theme.panelWidth
			leftPadding: Theme.modulePadding
			rightPadding: Theme.modulePadding
			topPadding: 6
			bottomPadding: 10
			spacing: 4

			BarText {
				width: parent.width - parent.leftPadding - parent.rightPadding
				elide: Text.ElideRight
				text: mod.title
				color: Colors.accent
				font.weight: Font.DemiBold
			}

			BarText {
				width: parent.width - parent.leftPadding - parent.rightPadding
				elide: Text.ElideRight
				visible: text !== ""
				text: [mod.artist, mod.player?.trackAlbum ?? ""].filter(s => s).join("  ·  ")
				caps: false
				color: Colors.structure
			}

			BarText {
				text: mod.player?.identity ?? ""
				color: Colors.muted
			}
		}

		// Progress: a segmented meter, click to seek where the player allows it
		Item {
			id: progress

			readonly property bool known: (mod.player?.lengthSupported ?? false) && mod.player.length > 0

			visible: known
			width: Theme.panelWidth
			height: 26

			SegmentBar {
				id: track

				x: Theme.modulePadding
				y: 2
				width: parent.width - Theme.modulePadding * 2
				height: 5
				segments: 32
				value: progress.known ? mod.player.position / mod.player.length : 0

				MouseArea {
					anchors.fill: parent
					anchors.margins: -6
					enabled: mod.player?.canSeek ?? false
					cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
					onClicked: mouse => mod.player.position = mod.player.length * Math.max(0, Math.min(1, (mouse.x - 6) / track.width))
				}
			}

			BarText {
				x: Theme.modulePadding
				anchors.bottom: parent.bottom
				text: progress.known ? mod.time(mod.player.position) : ""
				color: Colors.muted
			}

			BarText {
				anchors.right: parent.right
				anchors.rightMargin: Theme.modulePadding
				anchors.bottom: parent.bottom
				text: progress.known ? mod.time(mod.player.length) : ""
				color: Colors.muted
			}
		}

		Row {
			anchors.horizontalCenter: parent.horizontalCenter
			topPadding: 4

			PanelButton {
				icon: "󰒮"
				cut: "left"
				enabled: mod.player?.canGoPrevious ?? false
				onClicked: mod.player.previous()
			}
			PanelButton {
				icon: mod.playing ? "󰏤" : "󰐊"
				cut: "none"
				enabled: mod.player?.canTogglePlaying ?? false
				onClicked: mod.player.togglePlaying()
			}
			PanelButton {
				icon: "󰒭"
				enabled: mod.player?.canGoNext ?? false
				onClicked: mod.player.next()
			}
		}
	}
}
