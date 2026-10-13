// Fixed geometry and type of the bar. Colors live in Colors.qml, rendered by
// matugen from the current theme (theme-set).
//
// The visual language follows BW77 (github.com/TheYopi/bw77-sh):
// and Cyberpunk 2077's own menus (gameuidatabase.com, game id 439):
//   - One text face (Rajdhani) at one size; capitals for the bar,
//     headings and buttons, normal case for free text. Hierarchy comes from
//     color and weight, never from mixing sizes.
//   - Icons come from the Symbols Nerd Font only.
//   - Surfaces are cards: square corners except the bottom-right, cut at 45
//     degrees. Popup cards add the game's tab on the top edge and the
//     bracket and gapper on the left. Borders are 1px in Colors.line.
//   - Colour carries meaning: labels and icons in the structure colour
//     (coral), data and values in the accent (cyan), selection as a muted red
//     fill (Colors.selected). The structure colour runs under the bar.
//   - Panel entries follow the game's states (EntryFrame): a 30% frame at
//     rest; focus = full frame and a 10% fill; active = 40% fill; a click
//     flashes 70%. Actionable labels are cyan, static labels red.
pragma Singleton

import Quickshell
import QtQuick

Singleton {
	readonly property string textFont: "Rajdhani"
	readonly property string iconFont: "Symbols Nerd Font"
	readonly property int textSize: 14
	readonly property int iconSize: 15
	readonly property real tracking: 0.8

	readonly property int barHeight: 32
	readonly property int borderWidth: 1
	// Height available to modules: everything above the bottom edge line
	readonly property int contentHeight: barHeight - borderWidth
	readonly property int edgeMargin: 12
	readonly property int modulePadding: 8
	readonly property int moduleSpacing: 4
	// Hover/active frames stop this far short of the bar's top and bottom
	readonly property int frameInset: 4

	// Chamfer lengths: panels, module frames, workspace pips
	readonly property int notch: 10
	readonly property int notchSmall: 6
	readonly property int notchTiny: 4
	// Popup cards: height of the tab step
	readonly property int cardTab: 3
	// Popup cards: the bracket strip down the left and the gapper after it
	readonly property int bracketWidth: 5
	readonly property int gapperWidth: 2
	readonly property int panelPadding: 12
	// Width of a panel's content and the height of one entry in it
	readonly property int panelWidth: 280
	readonly property int rowHeight: 30
	// Gap between stacked entries, so each one's frame reads as its own card
	readonly property int entrySpacing: 4

	// Entry states, from CDPR's internal UI guide (STYLEGUIDE.md section 4):
	// the red stroke and the red fill plane are the only things that change
	readonly property real idleStroke: 0.3
	readonly property real hoverFill: 0.1
	readonly property real activeFill: 0.4
	readonly property real flashFill: 0.7
	// Gap between the bar's edge line and a popup card, so the card's tab
	// reads as its own edge rather than merging with the line
	readonly property int popupGap: 4

	readonly property int scanlineSpacing: 3
	readonly property real scanlineOpacity: 0.05
}
