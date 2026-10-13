// The date as a label, then the time as data, like the game's HUD clock.
// Hover shows the month.
import Quickshell
import QtQuick
import qs

Module {
	id: mod

	tooltipContent: Calendar {
		date: clock.date
	}

	SystemClock {
		id: clock

		precision: SystemClock.Minutes
	}

	BarText {
		anchors.verticalCenter: parent.verticalCenter
		rightPadding: 4
		text: Qt.formatDateTime(clock.date, "ddd d MMM")
		color: Colors.structure
	}

	BarText {
		anchors.verticalCenter: parent.verticalCenter
		text: Qt.formatDateTime(clock.date, "h:mm AP")
		color: Colors.accent
		font.weight: Font.DemiBold
	}
}
