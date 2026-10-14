//@ pragma UseQApplication
// The desktop shell: the bar (one per screen, rebuilt as monitors come and
// go) with its panels, the on-screen display, the notification daemon, the
// wallpaper and the polkit agent.
// Colors come from Colors.qml, which matugen renders on `theme-set`.
// The pragma on line 1 starts quickshell as a QApplication, which tray icons
// need to show their right-click (platform) menus; it applies on restart.
//
// Layout of this config:
//   *.qml            shared pieces: Theme, Colors, the card shapes, Module (a
//                    bar segment), Panel and its entries (PanelButton,
//                    PanelRow, PanelSlider, PanelHeading, PanelDivider)
//   modules/         one file per bar segment, each owning its panel
//   services/        singletons holding state and actions: Audio,
//                    Brightness, Osd, Notifs, Wallpaper, Confirm, Themes
//   osd/, notifications/, wallpaper/, polkit/, confirm/, themes/   the
//                    windows that draw the OSD, the popups, each screen's
//                    background, the password dialog, confirmations and the
//                    theme switcher
//
// Everything outside the shell reaches it through `qs ipc call <target> ...`
// (the handlers below), never by poking its files.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.services
import qs.osd
import qs.notifications
import qs.wallpaper
import qs.polkit
import qs.confirm
import qs.themes

ShellRoot {
	function focusedScreen(): string {
		return Hyprland.focusedMonitor?.name ?? "";
	}

	// `qs ipc call panel toggle <name>` opens a bar panel on the focused
	// monitor: power (SUPER + CTRL + P), network (SUPER + CTRL + W), volume,
	// bluetooth, battery
	IpcHandler {
		target: "panel"

		function toggle(name: string): void {
			Panels.toggle(name + ":" + focusedScreen());
		}
	}

	// The volume, microphone and brightness keys, and one-off messages from
	// scripts: `qs ipc call osd volume up|down|mute`, `osd mic`,
	// `osd brightness up|down`, `osd message <glyph> <text>`
	IpcHandler {
		target: "osd"

		function volume(action: string): void {
			const sink = Audio.sink;
			if (!sink)
				return;
			if (action === "mute")
				Audio.toggleMute(sink);
			else
				Audio.step(sink, action === "up" ? 1 : -1);
			Osd.show("volume");
		}

		function mic(): void {
			const source = Audio.source;
			if (!source)
				return;
			Audio.toggleMute(source);
			Osd.show("mic");
		}

		function brightness(action: string): void {
			Brightness.step(action === "up" ? 1 : -1);
			Osd.show("brightness");
		}

		function message(glyph: string, text: string): void {
			Osd.message(glyph, text);
		}
	}

	// `qs ipc call wallpaper reload` re-reads ~/.config/theme/wallpaper
	IpcHandler {
		target: "wallpaper"

		function reload(): void {
			Wallpaper.reload();
		}
	}

	// `qs ipc call themes toggle` (SUPER + CTRL + T): the theme switcher
	IpcHandler {
		target: "themes"

		function toggle(): void {
			themeSwitcher.toggle();
		}
	}

	// `qs ipc call wallpapers toggle` opens the wallpaper picker
	IpcHandler {
		target: "wallpapers"

		function toggle(): void {
			wallpaperPicker.toggle();
		}
	}

	// `qs ipc call notifications dismiss` clears every popup;
	// `qs ipc call notifications dnd` switches Do not disturb
	IpcHandler {
		target: "notifications"

		function dismiss(): void {
			Notifs.dismissAll();
		}

		function dnd(): void {
			Notifs.setDnd(!Notifs.dnd);
		}
	}

	Variants {
		model: Quickshell.screens

		Bar {}
	}

	Variants {
		model: Quickshell.screens

		WallpaperWindow {}
	}

	OsdWindow {}

	PolkitDialog {}

	ConfirmDialog {}

	ThemeSwitcher {
		id: themeSwitcher
	}

	WallpaperPicker {
		id: wallpaperPicker
	}

	// The "Config reloaded" toast is Quickshell's own, unthemed; a failed
	// reload still shows its popup, which carries the error
	Connections {
		target: Quickshell

		function onReloadCompleted(): void {
			Quickshell.inhibitReloadPopup();
		}
	}

	NotificationPopups {}
}
