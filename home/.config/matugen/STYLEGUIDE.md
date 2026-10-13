# Cyberpunk 2077 UI style guide

How Cyberpunk 2077's own interface looks and behaves, as the reference for
anything built on this desktop. This describes the original game UI only —
not this desktop's adaptation of it. When something here and the desktop
disagree, this file is the target.

## Sources

1. **Vladimír Vilimovský (CD Projekt Red), "Cyberpunk 2077 — User Interface
   (Part 2)"**, Behance gallery 133185623. Contains pages of CDPR's internal
   UI guide (cell and button state breakdowns with exact colours and
   opacities, the cell assembly manual, rarity tiers, tooltip and grid rules)
   and final in-game screens: character creation, main menu hub, inventory,
   backpack, map, character/perks, stats, journal, codex, tarot, HUD,
   dialogue, phone, vehicle and radio pickers, quickhacking, breach protocol,
   braindance, photo mode.
2. **gameuidatabase.com, game id 439**: in-game screen captures.

Every value below is marked **official** (printed in CDPR's guide pages) or
**sampled** (measured from final screens). Early concept slides in the
gallery (grey and pale-yellow explorations) are not used.

## 1. Principles

- **Neomilitary.** CDPR's own term for the aesthetic. The UI is equipment: it
  reads like a device's firmware, with model numbers, compliance text,
  registration marks and labelled data. Nothing is rounded, soft or glossy.
- **Layered planes.** Every surface is a stack — a near-black backing plane,
  a red fill plane, a red stroke — and states change only the opacity of
  those planes, never their colour (section 4).
- **Colour is meaning.** Red is the interface itself (frames, labels, body
  text). Cyan marks what you act on or read as data. Every other hue is
  reserved for a specific meaning (section 2).
- **A grid under everything.** "There are shared rules throughout all the
  fullscreen panels. Rules are defined on a grid to help cognitive navigation
  of the user not to get lost or confused" (CDPR).
- **Diegetic and subtle.** The HUD is "projected upon the eyeball's lens";
  the curvature this implies was kept "a rather subtle detail" (CDPR). Effects
  support the fiction; they never compete with information.

## 2. Colour

### 2.1 Base

| Role | Value | |
|---|---|---|
| Interface red: strokes, fills, labels | `#FF3B45` | official |
| Backing plane | `#0E0E17` | official |
| Red as rendered for text on screen | `#F24F4A` | sampled |
| Cyan: data, interactive labels, HUD selection | `#54DEE8` – `#5CEAF1` | sampled |
| Yellow: special / quest-critical / "NEW" | `#E3C33D` – `#DDA735` | sampled |

Menu backgrounds are a dark red-to-navy gradient (red-black at the top,
blue-black at the bottom) with a faint dot/scanline texture over it.

### 2.2 What each colour means

- **Red** — the frame of the world: card strokes, section and field labels,
  values in selectors, and body text in menus (journal entries, descriptions
  and confirmations are red, sentence case).
- **Cyan** — something to act on or a piece of data: menu entry labels (hub
  tiles, quest titles, section headers like "NEARBY QUESTS"), button labels,
  arrows, controller glyphs, numbers such as LEVEL, and the selected row in
  HUD lists. Dialogue choice text is cyan.
- **Yellow** — special status: the current objective, the quest-critical
  dialogue choice, "NEW" tags, money (€$), and the legendary tier.
- **Green** — positive data: street cred, "EASY" difficulty, the uncommon
  tier, completed steps in breach protocol.
- **Difficulty / threat scale** (journal): LOW in dim red, EASY green,
  MODERATE cyan, DANGEROUS bright red.
- **Rarity tiers** (official), drawn as a solid vertical bar down the left
  edge of an item cell, never as a fill:

  | Tier | Colour (sampled) |
  |---|---|
  | Legendary | `#C49331` |
  | Epic | `#8527CC` |
  | Rare | `#245FB1` |
  | Uncommon | `#1DC46F` |
  | Common | `#565656` |

### 2.3 Mode palettes

A whole mode is recoloured instead of decorated: menus are red on dark;
netrunning is green, lime and cyan (2.4); braindance changes the image per
layer (visual, thermal, sound). A picker opened over gameplay (phone contacts,
vehicles, radio) washes the whole world behind it in red, and a confirmation
in character creation does the same over the menu. The switch of palette *is*
the signal that you are in a different system.

### 2.4 Netrunning palettes (shipped)

**NetTech breach protocol** ("NET═TECH · CYBERSPACE HACKING CONSOLE ·
VER 23.2000 · REV 894 V012" — the console brands itself like a device). All
sampled:

| Role | Colour |
|---|---|
| Panel header strip (filled), logo, footer labels | lime `#CBE757` |
| Code glyphs in the matrix, buffer slots | lime `#D0E25A` |
| Panel body | near-black navy `#0D1017` |
| Active row band | navy blue `#15355A` |
| Active column band | slate `#1A2733` |
| Cursor cell (outlined square) | cyan `#57D0D7` |
| Installed / success fill, "UPLOAD SUCCESSFUL!" | green `#1CD97B` |
| Text on the green fill | near-black navy |

Behaviour worth keeping: the header strip is a solid lime bar with the panel
title in dark caps; panels have the cut bottom-right corner; when a step
succeeds its row fills solid green and gets an outlined "INSTALLED" chip, and
when everything succeeds a whole panel turns green with a terminal log
("//ACCESS_REQUEST_SUCCESS … COMPLETE"). The countdown sits in an outlined box
at the right of its row, with a lime progress line under it. The world behind
is tinted green.

**Quickhack list** (scanning overlay). Each row's state has its own colour
pair (text on row fill), sampled:

| State | Text | Row fill |
|---|---|---|
| Installed / active | green `#20F18A` | dark green `#154331` |
| Ready | cyan `#51D2D4` | near-black |
| Focused | cyan | teal `#214347` with full stroke |
| Unavailable ("NOT ENOUGH MEMORY", "NETWORK IS NOT BREACHED") | red `#B1403A` | dark red `#512322` |

The resource meter (CYBERDECK RAM) is segmented: available blocks cyan
`#48B9B9`, the cost of the focused hack red `#C6534A`. System notices are a
blue bar (`#3286F1` text on `#142F4E`): "NETWORK HACKED COST LOWERED BY 3".
The hack's tooltip names its rarity in the tier colour (epic purple
`#9B2BE7`) and its key figures in cyan.

### 2.5 Device palette (concept, not shipped)

Vilimovský's gallery also shows an alternate direction for in-world device
UIs, not used in the final game: **pale lime `#D3EEB5`** solid header and
footer bars with dark text, line drawings in the same lime on a warm
near-black `#171213` (or a navy `#38476C` gradient over a perspective grid),
and loud tier stripes — **yellow `#F5E308`** and **purple `#A848F8`** —
under item names. It uses the same vocabulary (cut corners, compliance
micro-text, QR/barcode marks, crossed-out empty slots, hint footer) with a
light-on-dark, print-like feel. Treat it as an alternate skin for a
self-contained tool, not as the main menu look.

## 3. Typography

- **A condensed, geometric sans in capitals** for every label, heading,
  button, tab and status, with generous tracking.
- **Sentence case** for prose: descriptions, journal text, dialogue choices,
  messages. Prose keeps the context colour (red in menus, cyan in dialogue,
  yellow for a job brief).
- **Hierarchy by colour and position, little by size.** Titles are only
  slightly larger than labels; a screen uses two or three sizes at most.
- **Numbers are first-class:** large figures next to small caps units
  ("130 LEVEL", "119 CRED", "10/50"); thousands separated by a space
  ("15 251", "€$ 10 000"); distances in brackets ("[3 590 M]").
- **Micro-text:** tiny dim lines as device fiction — "ONLY CC35 CERTIFIED AND
  DHSF 5TH CLASS OFFICERS ARE ALLOWED TO MANIPULATE, ACCESS OR DISABLE THIS
  DEVICE.", "CERTIFIED TO ACCESS OR DISABLE THIS ITEM.", "MODEL LINE 12.12AA",
  "IMAGE NAME / IMAGE TYPE / LOAD ADDRESS", hex code columns. Under headers,
  inside tiles, beside dialogue choices, in footers. Never legible at a
  glance, never essential.

## 4. Interaction states (official)

From CDPR's breakdown of item cells and buttons. Each state is a set of planes
over the backing plane (`#0E0E17` at 95% for cells, 80% for buttons):

| State | Stroke `#FF3B45` | Fill plane `#FF3B45` |
|---|---|---|
| Idle | 30% | — |
| Hover | 100% | 10% |
| Activated | 100% | 40% |
| Clicked | 100% (with a short glow) | 70% — a flash, then back to activated |

In an item cell the other layers (side panel, accent) stay at 30% in every
state; only the cell stroke and the fill plane move.

On final screens:

- **The focused entry** gets the hover treatment. The small square of two
  corner brackets (⌜ ⌟) seen over entries in screenshots is the game's mouse
  cursor, not part of the entry.
- **The chosen entry** in a list (the tracked quest, the active tab) holds a
  stronger red fill than hover, so focus and selection never look the same.
- **HUD lists** (dialogue choices, vehicle, radio and contact pickers) use a
  louder pattern: the selected row is a **solid cyan bar with dark text**; a
  quest-critical option is a **solid yellow bar**; other rows are plain cyan
  text.
- **Disabled / unavailable** entries drop to dim red text and frame.

## 5. Shapes

- **Square corners, one exception: the bottom-right corner is cut at 45°.**
  This holds for cards, buttons, rows, tiles, tooltips and dialogs.
- **The tab.** Most cards and buttons have a step in the top edge: the first
  stretch near the left sits higher and steps down at 45° to the rest.
- **Cell assembly** (official), left to right:
  - **Bracket** — a thin vertical strip with a small notch, the element's
    spine. In dialogs it is filled solid red.
  - **Gapper** — a dark gap between bracket and cell "which prevents the
    background leaking. This texture is most important for tooltips, popups,
    notifications etc. The UI parts which are appearing on top of everything
    else."
  - **Cell** — the body, with the cut corner.
- **Strokes are hairlines** (1 px at 1080p). Weight comes from fill opacity,
  not thicker lines.
- **Straight lines only.** Diagonals are always 45°. The only round shapes
  are controller glyphs and icon-internal details.
- **Hexagons** for the attribute/perk tree; **diamonds** for menu and quest
  icons.

## 6. Components

**Header bar (full-screen menus).** Left: LEVEL and CRED as big coloured
numbers (cyan, green) with a small caps unit and a thin segmented progress
line under each. Centre: the tab strip — current tab name in cyan caps with
its icon, neighbouring tabs dimmed red, controller bumper glyphs at both ends.
Right: inventory weight (icon + "10/50") and money ("€$ 15 251") in red and
yellow. Micro compliance text under each block.

**Hint footer.** Bottom right: pairs of a cyan controller glyph in a circle
and a red caps label ("NAVIGATION · OPEN MENU · EQUIP · RETURN"). Bottom left:
decorative columns of tiny red digits.

**Hub tile.** A wide card: cyan diamond icon + cyan caps label, micro-text
under the label, tab top-left, cut corner bottom-right. Sub-entries open
directly below the focused tile (CHARACTER → STATS). Small "LEVEL UP 3"
notices sit above a tile: cyan caps with the number in a filled cyan chip.

**List row (journal, codex).** Stacked cards: a diamond icon at the left,
title in cyan caps, a coloured status word beneath (difficulty), a bracketed
figure at the right. Rows are grouped under section header cards (cyan caps,
a collapse triangle at the right). A thick red scrollbar thumb runs beside
the list.

**State chip.** A small outlined box with tiny caps inside — "READY",
"INSTALLED", "NOT ENOUGH MEMORY", "COVERT HACK", "EQUIPPED" — under or beside
an entry's name, in the entry's state colour. Status is labelled, not only
coloured.

**Tabs.** Side-by-side cards; the active one filled red. A "NEW" chip (yellow
outline, yellow caps) marks unseen content.

**Selector (character creation, settings).** A card with the label at the left
and the current value at the right, both red caps; below it a row of button
cards with outlined cyan triangles ◁ ▷ (and a grid button between them when
there is a gallery). Optional thumbnail at the right of the label card.

**Attribute stepper.** Icon, name and a large value, with − and + buttons at
the ends; a red-filled tag marks a recommended attribute.

**Objective list.** The current objective is a filled row in yellow with a
yellow "!" badge; other objectives are red text beside empty square checkboxes.

**Tooltip / item card.** Item name in caps coloured by rarity, type and level
small beneath, a big stat ("950 DPS"), a list of effects with small icons and
bullet boxes, flavour text in sentence case, price and weight at the bottom.
Cut corner, bracket and gapper; "EQUIPPED" comparison cards sit beside it
with a filled cyan header strip.

**Confirmation dialog.** The background dims and washes red; a centred card
with a solid red bracket on its left, the question in large red caps, micro
compliance text, then two button cards — BACK and NEXT — joined by a short
line; the focused one is filled.

**Loading bar.** A thin red line filling left to right with the percentage at
its right end, under a small logo and caption.

**Meters.** Segmented bars (blocks with gaps) for progress, RAM, health and
skill advancement; a row of small level markers with the reached ones lit.

**HUD.** Minimal and edge-anchored: health as a short segmented bar with its
number top-left; quest title and objective top-right in red; ammo and weapon
bottom-right; quickhacks and the RAM bar appear only while scanning.
Interaction prompts are a red caps label + glyph + a short cyan option list.

## 7. Layout

- Wide outer margins with the frame of the screen marked by thin vertical
  lines, small registration marks and numeric ticks along the edges.
- Content in columns on the shared grid; related lists are stacked cards with
  small, even gaps.
- The 3D subject (character, item, map) owns the centre; panels hold the
  sides.
- Filler micro-text and code blocks fill dead space in corners — always dim.

## 8. Motion

- Click is a flash: the fill jumps to 70% and settles at 40%.
- Panels and sub-entries appear in place; selection moves without sliding.
- Loading and progress fill block by block.
- Glitch, chromatic split and scan artefacts appear on transitions,
  boot/loading screens, hacking and errors — not on a resting screen.

## 9. Checklist

- [ ] Square corners, bottom-right 45° cut, tab on the top edge where it fits.
- [ ] Red frame and labels, cyan for actionable/data, yellow and green only
      for their meanings.
- [ ] Capitals for labels, sentence case for prose, numbers large with small
      units.
- [ ] States: stroke 30 → 100%, fill 0 → 10 → 40 → 70%.
- [ ] Focus and selection visibly different.
- [ ] Hairline strokes, 45° diagonals only.
- [ ] Micro-text and marks only as dim filler, never information.
