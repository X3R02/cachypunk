// Click-to-open panel under a bar module: the tooltip's materials, but it takes
// input and closes on a click anywhere else. While open, the window covers the
// whole screen below the bar, transparent, and a click anywhere outside the
// card closes it. The bar's strip is left out of it, so a click on another
// module switches straight to that panel, the same module toggles it closed,
// and a click on the bar's empty space closes it (Bar.qml).
//
// It is a layer surface rather than a popup because popups never receive the
// keyboard: while open it holds keyboard focus, and Up/Down (or k/j, Tab)
// move through the entries, Enter/Space activates one, Left/Right (h/l)
// adjusts it, Delete runs its secondary action and Escape closes. An entry is
// any item in the content with `navigable: true` and an `activate()` function
// (optionally `adjust(step)` and `secondary()`); it reads
// `QsWindow.window.cursor === this` to draw itself selected and calls
// `takeCursor(this)` on hover, so mouse and keyboard share one cursor.
// PanelButton, PanelRow and PanelSlider are the stock entries. On open the
// cursor starts on the entry marked `preferred: true`, else on the first.
// A panel with tabs sets `tabIcons` (one glyph per tab) and follows
// `tabIndex`: the card's top edge then rises into folder tabs (PanelTabs),
// which come first under Up/Down and also page with Q / E, the game's
// bumpers; a cursor left on content the new tab hid goes back to the top.
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
	id: panel

	required property Item target
	required property var barWindow
	// Panels.current value that means "this panel is open"
	required property string key
	default property alias content: body.data

	readonly property bool open: Panels.current === key
	// Tells entries they live in a Panel and should follow `cursor`
	readonly property bool keyboardNav: true
	property Item cursor: null
	// One glyph per tab, empty for a panel without tabs; tabIndex is the
	// tab shown, set by the panel's owner and by the tabs themselves
	property var tabIcons: []
	property int tabIndex: 0

	// Where the module sits on the bar, taken when the panel opens
	property real targetX: 0

	function entries(): list<Item> {
		const found = [];
		const walk = item => {
			for (const child of item.children) {
				if (!child.visible)
					continue;
				if (child.navigable === true && child.enabled !== false)
					found.push(child);
				walk(child);
			}
		};
		if (tabStrip.visible)
			walk(tabStrip);
		walk(body);
		return found;
	}

	function move(step: int): void {
		const list = entries();
		if (list.length === 0)
			return;
		const at = list.indexOf(cursor);
		cursor = list[at < 0 ? (step > 0 ? 0 : list.length - 1) : (at + step + list.length) % list.length];
	}

	function takeCursor(item: Item): void {
		cursor = item;
	}

	// Gives the keyboard back to the panel after a text field had it
	function refocus(): void {
		keys.forceActiveFocus();
	}

	// Where the cursor starts: the entry marked `preferred: true` (media's
	// play/pause), else the first one from the top
	function placeCursor(): void {
		const list = entries();
		cursor = list.find(e => e.preferred === true) ?? list[0] ?? null;
	}

	onOpenChanged: {
		cursor = null;
		if (open) {
			targetX = target.mapToItem(null, 0, 0).x;
			keys.forceActiveFocus();
			// After this frame: entries bound to the panel's visibility exist then
			Qt.callLater(placeCursor);
		}
	}

	screen: barWindow.screen
	visible: open
	color: "transparent"

	anchors {
		top: true
		bottom: true
		left: true
		right: true
	}
	margins.top: Theme.barHeight
	exclusionMode: ExclusionMode.Ignore

	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.namespace: "quickshell-panel"
	WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

	Item {
		id: keys

		anchors.fill: parent
		focus: true

		// A click anywhere outside the card closes the panel
		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.AllButtons
			onPressed: Panels.close(panel.key)
		}

		Keys.onPressed: event => {
			switch (event.key) {
			case Qt.Key_Down:
			case Qt.Key_J:
			case Qt.Key_Tab:
				panel.move(1);
				break;
			case Qt.Key_Up:
			case Qt.Key_K:
			case Qt.Key_Backtab:
				panel.move(-1);
				break;
			case Qt.Key_Return:
			case Qt.Key_Enter:
			case Qt.Key_Space:
				if (panel.cursor)
					panel.cursor.activate();
				break;
			case Qt.Key_Left:
			case Qt.Key_H:
			case Qt.Key_Right:
			case Qt.Key_L:
				if (panel.cursor && typeof panel.cursor.adjust === "function")
					panel.cursor.adjust(event.key === Qt.Key_Left || event.key === Qt.Key_H ? -1 : 1);
				break;
			case Qt.Key_Q:
			case Qt.Key_E:
				if (!tabStrip.visible)
					return;
				tabStrip.step(event.key === Qt.Key_Q ? -1 : 1);
				// After this frame: the new tab's entries are visible then
				Qt.callLater(() => {
					if (panel.entries().indexOf(panel.cursor) < 0)
						panel.placeCursor();
				});
				break;
			case Qt.Key_Delete:
				if (panel.cursor && typeof panel.cursor.secondary === "function")
					panel.cursor.secondary();
				break;
			case Qt.Key_Escape:
				Panels.close(panel.key);
				break;
			default:
				return;
			}
			event.accepted = true;
		}

		// Swallows clicks on the card's own background, so only clicks
		// outside it reach the closer above
		MouseArea {
			x: frame.x
			y: frame.y
			width: frame.width
			height: frame.height
			acceptedButtons: Qt.AllButtons
		}

		Frame {
			id: frame

			// Centred under the module, kept on screen; hangs below the bar's
			// edge line by popupGap
			x: Math.round(Math.max(0, Math.min(panel.targetX + panel.target.width / 2 - width / 2, keys.width - width)))
			y: Theme.popupGap
			tabHeight: tabStrip.visible ? tabStrip.tabHeight : -1
			tabLength: tabStrip.visible ? tabStrip.count * tabStrip.tabWidth : -1

			Column {
				id: body

				// Each entry is its own framed card, as the game stacks them
				spacing: Theme.entrySpacing
			}
		}

		// Inside the frame's raised top edge, over the cell
		PanelTabs {
			id: tabStrip

			visible: count > 0
			x: frame.x + frame.cellX
			y: frame.y
			icons: panel.tabIcons
			currentIndex: panel.tabIndex
			onSelected: index => panel.tabIndex = index
		}
	}
}
