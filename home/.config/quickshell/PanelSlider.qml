// A level inside a Panel - volume, microphone, brightness: an icon, a
// segmented meter and the value. Steps are 5%, one block of the 20-block
// meter. Left/Right (or the wheel) step it, a click or drag on the meter sets
// it, and Enter or a click on the icon runs `toggled` (mute). States come
// from EntryFrame.
import Quickshell
import QtQuick

Item {
	id: slider

	property string icon: ""
	property real value: 0 // 0..1
	// Drawn dim, like a muted channel
	property bool off: false
	property bool enabled: true

	readonly property bool navigable: true
	readonly property var panelWindow: QsWindow.window
	readonly property bool hovered: panelWindow?.keyboardNav ? panelWindow.cursor === slider : mouse.containsMouse

	// Snapped to the 5% grid
	signal moved(real value)
	signal toggled

	function activate(): void {
		states.flash();
		toggled();
	}

	function adjust(step: int): void {
		const blocks = Math.round(value * 20) + step;
		moved(Math.max(0, Math.min(20, blocks)) / 20);
	}

	function setFrom(x: real): void {
		moved(Math.round(Math.max(0, Math.min(1, x / meter.width)) * 20) / 20);
	}

	implicitWidth: Theme.panelWidth
	implicitHeight: Theme.rowHeight

	EntryFrame {
		id: states

		focused: slider.hovered
		enabled: slider.enabled
	}

	MouseArea {
		id: mouse

		anchors.fill: parent
		hoverEnabled: true
		enabled: slider.enabled
		onEntered: slider.panelWindow?.takeCursor?.(slider)
		onWheel: w => slider.adjust(w.angleDelta.y > 0 ? 1 : -1)
	}

	BarIcon {
		id: glyph

		x: Theme.modulePadding
		anchors.verticalCenter: parent.verticalCenter
		width: 18
		text: slider.icon
		color: !slider.enabled || slider.off ? Colors.muted : Colors.accent

		MouseArea {
			anchors.fill: parent
			anchors.margins: -4
			enabled: slider.enabled
			cursorShape: Qt.PointingHandCursor
			onClicked: slider.toggled()
		}
	}

	SegmentBar {
		id: meter

		anchors.left: glyph.right
		anchors.leftMargin: 10
		anchors.right: readout.left
		anchors.rightMargin: 10
		anchors.verticalCenter: parent.verticalCenter
		height: 5
		segments: 20
		value: slider.value
		fillColor: slider.off ? Colors.muted : Colors.accent

		MouseArea {
			anchors.fill: parent
			anchors.margins: -8
			enabled: slider.enabled
			cursorShape: Qt.PointingHandCursor
			onPressed: m => slider.setFrom(m.x - 8)
			onPositionChanged: m => {
				if (pressed)
					slider.setFrom(m.x - 8);
			}
		}
	}

	BarText {
		id: readout

		anchors.right: parent.right
		anchors.rightMargin: Theme.modulePadding + Theme.notchSmall / 2
		anchors.verticalCenter: parent.verticalCenter
		// Fixed width, so the meter doesn't shift as the number changes
		width: 36
		horizontalAlignment: Text.AlignRight
		text: slider.off ? "Mute" : Math.round(slider.value * 100) + "%"
		color: slider.off ? Colors.muted : Colors.accent
	}
}
