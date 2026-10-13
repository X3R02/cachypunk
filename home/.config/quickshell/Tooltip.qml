// Hover popup under a module: a plain panel in the bar's own materials
import Quickshell
import QtQuick

PopupWindow {
	id: tip

	required property Item target
	property bool show: false
	property string text: ""
	property Component contentComponent: null

	// Small delay so sweeping the pointer across the bar doesn't flash popups
	property bool armed: false

	anchor.item: target
	anchor.edges: Edges.Bottom
	anchor.gravity: Edges.Bottom
	// Hang below the bar's edge line by popupGap: the anchor rect is stretched
	// down past the module (anchor margins only inset the rect, they can't
	// push the popup away from it)
	anchor.rect.width: target.width
	anchor.rect.height: target.height + Theme.borderWidth + Theme.popupGap
	visible: show && armed
	color: "transparent"
	implicitWidth: frame.implicitWidth
	implicitHeight: frame.implicitHeight

	onShowChanged: {
		if (show)
			delay.restart();
		else {
			delay.stop();
			armed = false;
		}
	}

	Timer {
		id: delay

		interval: 350
		onTriggered: tip.armed = true
	}

	Frame {
		id: frame

		Loader {
			id: body

			sourceComponent: tip.contentComponent ?? plain
		}

		Component {
			id: plain

			BarText {
				text: tip.text
			}
		}
	}
}
