// The states of a panel entry, as CDPR's internal UI guide specifies them
// (STYLEGUIDE.md section 4): only the red stroke and a red fill plane change.
//   idle      stroke 30%
//   focused   stroke 100%, fill 10%
//   active    stroke 100%, fill 40%   (the item in use)
//   clicked   fill flashes to 70%, then settles
// Focus wins over active: the active entry under the cursor drops to the
// focused look like any other, which is what shows the cursor is there.
// Shared by PanelRow, PanelButton and PanelSlider so every entry behaves the
// same. Fills its parent; call flash() on activation.
import QtQuick

Item {
	id: frame

	property bool focused: false
	property bool active: false
	property bool enabled: true
	// The cut corner, for entries sharing a row (see NotchRect)
	property string cut: "right"

	property bool flashing: false
	readonly property real fill: flashing ? Theme.flashFill : focused ? Theme.hoverFill : active ? Theme.activeFill : 0

	function flash(): void {
		flashing = true;
		flashTimer.restart();
	}

	anchors.fill: parent

	Timer {
		id: flashTimer

		interval: 120
		onTriggered: frame.flashing = false
	}

	// The backing plane every entry sits on (#0E0E17 at 80% for buttons in
	// the guide), so an entry stays readable wherever it is placed
	NotchRect {
		anchors.fill: parent
		notch: Theme.notchSmall
		cut: frame.cut
		fillColor: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.8)
		strokeColor: "transparent"
	}

	NotchRect {
		anchors.fill: parent
		notch: Theme.notchSmall
		cut: frame.cut
		opacity: frame.enabled ? 1 : 0.5
		fillColor: Qt.rgba(Colors.structure.r, Colors.structure.g, Colors.structure.b, frame.fill)
		strokeColor: Qt.rgba(Colors.structure.r, Colors.structure.g, Colors.structure.b, frame.focused || frame.active || frame.flashing ? 1 : Theme.idleStroke)

		Behavior on fillColor {
			ColorAnimation {
				duration: 100
			}
		}
	}
}
