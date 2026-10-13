// Month grid for the clock tooltip, weeks starting on Monday
import QtQuick
import qs

Column {
	id: cal

	required property date date

	readonly property int year: date.getFullYear()
	readonly property int month: date.getMonth()
	readonly property int today: date.getDate()
	// Monday-based weekday of the 1st, and how many days the month has
	readonly property int lead: (new Date(year, month, 1).getDay() + 6) % 7
	readonly property int days: new Date(year, month + 1, 0).getDate()
	readonly property int cell: 26

	spacing: 8

	BarText {
		text: Qt.formatDate(cal.date, "MMMM yyyy")
		color: Colors.structure
		font.weight: Font.DemiBold
	}

	Grid {
		columns: 7

		Repeater {
			model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

			BarText {
				required property string modelData

				width: cal.cell
				height: 20
				horizontalAlignment: Text.AlignHCenter
				text: modelData
				color: Colors.muted
			}
		}

		Repeater {
			model: cal.lead + cal.days

			NotchRect {
				id: cell

				required property int index
				readonly property int day: index - cal.lead + 1
				readonly property bool isToday: day === cal.today

				width: cal.cell
				height: 22
				notch: Theme.notchTiny
				fillColor: isToday ? Colors.selected : "transparent"
				strokeColor: isToday ? Colors.structure : "transparent"

				BarText {
					anchors.centerIn: parent
					text: cell.day > 0 ? cell.day : ""
					color: cell.isToday ? Colors.accent : Colors.fg
				}
			}
		}
	}
}
