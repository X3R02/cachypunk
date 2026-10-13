# Desktop design system

How this desktop applies the game's UI: which surface and component to use
for a job, what may sit inside what, and the rules every theme must keep.
`STYLEGUIDE.md` (next to this file) describes the original game; this file is
the desktop's own contract. When building anything visual, pick from here
first; add a new component only when nothing here fits, and document it here
the same day.

## 1. Tokens

Colours come only from the active theme (`themes/<name>.json`, rendered by
matugen). Never write a hex value into a component.

| Token | Role | Never use it for |
|---|---|---|
| `structure` | frames, labels, headings, prose in menus | data, values |
| `accent` | data, values, things you can act on, the active item's state | frames, decoration |
| `selected` | the active fill plane | hover |
| `line` | resting frames, dividers | text |
| `fg` / `fg_dim` | free text (names, bodies) / secondary text | labels |
| `muted` | disabled, placeholders | anything you must read |
| `yellow` (`warn`) | transient states (connecting, pairing), warnings | hover, decoration |
| `green` (`ok`) | success, installed, done | decoration |
| `accent2` (`alert`) | errors, critical, destructive actions | anything not dangerous |
| `bg` / `bg_deep` | card backing / dimmed screen behind modals | — |

Geometry and type come from `quickshell/Theme.qml`: Rajdhani DemiBold, one
size per surface (14 px text, 15 px icons), 1 px strokes (4/3 px for a
deliberately heavier frame), notches 10 / 6 / 4 px, sizes on whole pixels.

### Prominence

A surface's frame says how much it matters right now. Three tiers, and the
top one belongs to a single thing:

| Tier | Who | Frame stroke | Colour |
|---|---|---|---|
| **High** | the focused window, only | 2 px | `structure` at 100% |
| **Medium** | walker (the launcher: summoned, large, short-lived) | 4/3 px | `structure` at 65%, mixed over opaque `bg` |
| **Low** | popups: panels, tooltips, OSD, toasts | 1 px | `line` |

- Nothing but the focused window reaches High: no surface gets a 2 px or
  full-`structure` frame to stand out.
- A translucent stroke is always mixed over opaque `bg`, never over what is
  behind the surface (the gapper rule, below, applies to strokes too).
- Modals keep the game's dialog card (solid `structure` bracket, 1 px
  `structure` frame): the dimmed screen behind them already sets them apart.
- These are surface frames only. Entry states (section 4) light up the same
  way at every tier.

### Every theme must

- Fill every key that `nightcity.json` has, with the same meaning.
- Keep one lead colour (`structure`) and push the others down; `accent` and
  `green` are the second rank.
- Keep `line` and `selected` as the lead colour mixed over `bg` (Night City
  30% / 40%, the official values; a soft theme may go lower, Militech 22 / 28).
- Provide a wallpaper that reads well under its colours.

## 2. Surfaces

A surface is the window-level container. Every visible thing lives in one.

| Surface | Use it for | Shape | Background | Keyboard |
|---|---|---|---|---|
| **Bar** | always-visible status and launch points | strip, bottom edge line | `backdrop` | none |
| **Panel** | quick controls of one bar segment | popup card: bracket, gapper, tab, cut corner | screen untouched | exclusive while open |
| **Modal** | anything that must be answered before going on: confirmations, passwords, choosing a theme | dialog card (`ModalCard`): solid bracket, gapper, cell; or full-width carousel | `bg_deep` at 65%, never coloured | exclusive |
| **Toast** | something happened, no answer needed | notification: square box, heavier frame | none | none |
| **OSD** | the level you just changed | plain card, cut corner | none | none, clicks pass through |
| **Full screen** | lock and login | layout on the wallpaper, edge lines, dim micro-text | blurred wallpaper | exclusive |
| **Terminal panel** | sudo's fingerprint and password prompts (`~/.config/auth-prompts/`) | 46-column text panel redrawn in place, cut corner glyph | NetTech's fixed palette, not the theme | the terminal's |

Rules:

- **One modal at a time.** A modal never opens a panel; a panel closes before
  a modal opens.
- **Panels hang from their bar segment** and close on Escape or any press
  outside them, including the rest of the bar.
- **Toasts never ask.** If the user must decide, it is a modal; if the
  decision can wait, the toast carries action buttons and stays dismissible.
- **No red (or any colour) wash** behind modals: dim only.
- **The gapper is opaque `bg`** (Frame, ModalCard, walker), never
  transparent: as in the game, it stops the background leaking between
  bracket and cell. A transparent gapper was tried and reverted (2026-10-13).
- **The bracket is square at both ends** (Frame, ModalCard, walker): the
  guide's small notch at its foot read as a spike.
- Full-screen surfaces are the only place for decorative device micro-text
  and edge lines.

## 3. Components

| Component | File | Use | Contains |
|---|---|---|---|
| Module | `Module.qml` | one bar segment | icon, value |
| PanelHeading | `PanelHeading.qml` | names a group in a panel | text only |
| PanelRow | `PanelRow.qml` | one item of a list where one or more are *active* | icon, label, badge glyph, chip or detail |
| PanelButton | `PanelButton.qml` | an action (Lock, Advanced, Back) | icon, label |
| PanelSlider | `PanelSlider.qml` | a 0–100 level | icon, segmented meter, value |
| PanelDivider | `PanelDivider.qml` | separates groups | — |
| Chip | `Chip.qml` | a state ("CONNECTED", "DEFAULT", "ACTIVE") | text only |
| SegmentBar | `SegmentBar.qml` | any level or progress | — |
| ModalCard | `ModalCard.qml` | the body of a modal | heading, prose, fields, micro-text |
| Frame | `Frame.qml` | the body of a panel or tooltip | panel entries |

Nesting rules:

- A **Panel** contains, top to bottom: optional toggle (PanelButton) →
  headings with their rows and sliders → divider → `Advanced` (PanelButton,
  always last, opens the full tool). Nothing else.
- A **PanelRow** holds at most one Chip *or* one detail, never both. A state
  is a Chip; a number (signal %, battery %) is a detail.
- A **Chip** never contains an icon and is never a button.
- A **ModalCard** holds the question or heading, prose, at most one field,
  and micro-text. Its buttons sit *below* the card, BACK first, joined to
  the action by a short line.
- Buttons are never put inside rows, and rows never inside buttons.
- **Buttons sharing a row read as one control**: the first cuts its
  bottom-left corner, the middle ones are square, the last cuts its
  bottom-right (`PanelButton.cut`: "left", "none", "right"). A lone button
  keeps the usual bottom-right cut. Media prev / play / next and the dialogs'
  BACK — action pairs follow it; so must any new row of buttons.

**Icons (NightCity theme).** Folders and file types are drawn as cards, not
taken from an icon set: a folder is the card silhouette (tab, cut corner)
filled flat with `structure`, a special folder adds a caps label in `bg`
(DOC, DL, IMG...); a file is a portrait card in `structure` 12% over `bg`,
framed in `structure`, labelled with its type (TXT, PDF, VID...); a folder
taking a drop turns `accent`. No gradients, no pictograms: labels instead.
App icons stay Adwaita's.

## 4. States

One set of states for every entry (`EntryFrame.qml`), from CDPR's guide:

| State | Frame | Fill | Text |
|---|---|---|---|
| idle | `structure` 30% | — | `accent` (actionable) |
| focus (mouse or keyboard) | 100% | 10% | `accent` |
| active (in use) | 100% | 40% | `fg` |
| pressed | 100% | 70% flash | — |
| disabled | 50% opacity | — | `muted` |

- Focus wins over active: the active entry under the cursor shows the focus
  look, which is how the cursor stays visible on it.
- Mouse hover and keyboard focus are the same state and look the same,
  everywhere (panels, walker, dialogs).
- Never mark focus with an extra glyph or colour (no corner reticle: that is
  the game's mouse pointer; no yellow frame).
- Pending state goes in `yellow`, failure in `alert`, both as Chips.

## 5. Text

- Labels, headings, buttons, chips: capitals, tracked.
- Names (networks, devices, files) and prose: sentence case, never forced
  to capitals.
- Prose in menus and dialogs is `structure`; names and values are `fg` or
  `accent`.
- Numbers use tabular figures; levels step in 5% so meters end on a block.

## 6. Interaction

- **Keyboard first.** Every surface that takes input works without a mouse:
  Up/Down (j/k, Tab) move, Enter/Space activate, Left/Right (h/l) adjust or
  move sideways, Delete is the secondary action, Escape closes or goes back.
- **Destructive actions confirm** in a modal (log out, restart, shut down)
  with BACK focused by default. Reversible actions don't (lock, suspend).
- **Forgetting or removing an item** takes a second press of the secondary
  action, with its chip switching to "AGAIN TO …" in `alert`.
- **Show an input only when it can be used.** Waiting states (fingerprint,
  scanning) show what is happening, not a disabled field.
- **Advanced is the escape hatch**: every panel ends in one row that opens
  the full tool (nm-connection-editor, bluetui, wiremix). A TUI is never a
  panel's main path.
- Keybinds open surfaces through `progs.panel(name)` / `progs.themes()`;
  outside code talks to the shell only through `qs ipc call`.

## 7. Where things live

| What | Where |
|---|---|
| Shell surfaces and components | `~/.config/quickshell` |
| Palettes | `~/.config/matugen/themes/*.json` |
| Everything theme-derived | a matugen template, applied by `theme-set` |
| Lock / login | `hypr/hyprlock.conf`, `~/.config/sddm/matugen` |
| Launcher | walker theme from matugen |
| Folder and file icons | `~/.local/bin/theme-icons` (NightCity icon theme, rebuilt by `theme-set`) |

## 8. Checklist for anything new

- [ ] Picked a surface from section 2 and components from section 3.
- [ ] Colours by role from section 1; no hex in the component.
- [ ] States from section 4; mouse and keyboard look the same.
- [ ] Works from the keyboard; Escape closes.
- [ ] Destructive → modal confirmation.
- [ ] Looks right in every theme (switch with SUPER+CTRL+T and check).
- [ ] Documented here if it is a new component.
