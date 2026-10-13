// StatusNotifier tray. Quickshell registers the watcher itself, so apps that
// wait for org.kde.StatusNotifierWatcher (KeePassXC in autostart) still work.
// Icons are drawn as flat silhouettes (the icon's alpha masks a solid fill),
// so a dark source icon isn't drawn dim. Their colour follows the bar's logic:
// coral at rest, accent when the app reports an "on" state through its icon
// name (NordVPN connected, KeePassXC unlocked), like a connected Bluetooth.
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs

Row {
	id: tray

	required property var barWindow

	// Icon names that mean the app is in its "on" state: NordVPN switches to
	// its blue icon when connected; KeePassXC adds "-locked" only when locked
	function isOn(icon: string): bool {
		return /nordvpn-tray-blue/.test(icon) || (/keepassxc/.test(icon) && !/locked/.test(icon));
	}

	visible: SystemTray.items.values.length > 0
	height: parent.height
	spacing: 0

	Repeater {
		model: SystemTray.items

		Module {
			id: mod

			required property SystemTrayItem modelData

			tooltip: modelData.tooltipTitle || modelData.title
			onClicked: mouse => {
				if (mouse.button === Qt.MiddleButton)
					modelData.secondaryActivate();
				else if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
					if (modelData.hasMenu) {
						const pos = mod.mapToItem(tray.barWindow.contentItem, 0, mod.height);
						modelData.display(tray.barWindow, pos.x, pos.y);
					}
				} else
					modelData.activate();
			}
			onScrolled: wheel => modelData.scroll(wheel.angleDelta.y, false)

			// Icon and its fill in one box: content sits in Module's Row, where
			// children can't use fill anchors
			Item {
				anchors.verticalCenter: parent.verticalCenter
				width: 14
				height: 14

				// The mask samples this layer as a texture. Left at the item's
				// 14 logical px it was upscaled on the 1.5x display and the
				// icons came out jagged, so the icon is requested and layered at
				// 3x and filtered down.
				Image {
					id: icon

					anchors.fill: parent
					source: mod.modelData.icon
					sourceSize: Qt.size(42, 42)
					smooth: true
					mipmap: true
					visible: false
					layer.enabled: true
					layer.textureSize: Qt.size(42, 42)
					layer.smooth: true
					layer.mipmap: true
				}

				Rectangle {
					id: fill

					anchors.fill: parent
					color: mod.marked || tray.isOn(mod.modelData.icon) ? Colors.accent : Colors.structure
					visible: false
					layer.enabled: true
				}

				MultiEffect {
					anchors.fill: parent
					source: fill
					maskEnabled: true
					maskSource: icon
					// Keep pixels by the icon's alpha: the threshold must sit
					// above 0 or fully transparent pixels pass and the icon
					// becomes a solid square; the spread keeps antialiased edges
					maskThresholdMin: 0.5
					maskSpreadAtMin: 1
					autoPaddingEnabled: false
				}
			}
		}
	}
}
