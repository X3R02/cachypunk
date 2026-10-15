# Working on Cachypunk

Shared notes for any agent (or person) changing this desktop: where things
live, the rules, how we design and verify, and the traps already found. It is
the project's memory, so it does not depend on any one assistant's private
notes.

**Keep it useful, not exhaustive.** When you learn something that would have
saved you a mistake, add one line in the right section (with the date if it
is a decision). Desktop matters only; no personal data (this repo is public).
Look-and-feel rules belong in `DESIGN-SYSTEM.md`, not here.

## Map

- The repo *is* the config: every path in `links.txt` is a symlink from
  `$HOME` into `home/`, so editing `~/.config/quickshell` edits the repo.
  A new file goes under `home/` plus a line in `links.txt` (and `packages/`
  if it needs a package). See README for install/update/link/status.
- Nothing personal in the repo: per-machine values go in
  `~/.config/cachypunk/user.lua` (documented in `examples/user.lua`) and
  `~/.config/cachypunk/wallpapers/`.
- Design documents, read before anything visual:
  - `home/.config/matugen/STYLEGUIDE.md`: Cyberpunk 2077's own UI, the target.
  - `home/.config/matugen/DESIGN-SYSTEM.md`: how this desktop applies it;
    surfaces, components, states. Update it when adding a component.
- Quickshell (`home/.config/quickshell/`) is the whole shell: bar, panels,
  OSD, notifications, wallpaper, polkit. Its layout is at the top of
  `shell.qml`. Build new shell pieces there, not as another daemon.
- Theming: fixed palettes in `matugen/themes/<name>.json`, rendered by
  `theme-set`. Anything derived from the theme is a matugen template (or a
  step in `theme-set`), never hard-coded colours.
- Hyprland config is Lua (`home/.config/hypr/lua/`): `binds.lua` is a pure
  keymap, programs in `programs.lua`, per-machine values in `user.lua`.
- The `cachypunk` agent skill (`home/.agents/skills/cachypunk/`, Omarchy's
  pattern) brings agents here from any directory; it is linked into
  `~/.agents`, `~/.claude` and `~/.gemini/config` skills. It only routes to
  this file, so rules live here, not there.

## Rules

- **English** in everything written to disk: code, comments, commits, docs.
- **Keybinding tiers** have fixed meanings:

  | Tier | Meaning |
  |---|---|
  | `SUPER` | focus, navigate, launch |
  | `SUPER + SHIFT` | move the window, change its state |
  | `SUPER + CTRL` | hardware, display, session, **and every bar panel** |
  | `SUPER + ALT` | the alternative take on the same key |

  - Every panel hanging from the bar opens from `SUPER + CTRL + <key>`,
    whatever it shows (2026-10-14: media/notifications/AI on `SUPER` read as
    random). Never put a bind where it merely fits.
  - Binds go through the helpers in `lua/keys.lua` (`k.super`, `k.shift`,
    `k.ctrl`, `k.alt`, `k.plain`), each with a description: things you summon
    are named ("Terminal", "Audio settings"), actions take a verb ("Lock the
    screen"). The descriptions feed the `SUPER + K` cheatsheet.
  - Kept exceptions: `SUPER + Q` close and `SUPER + mouse` drag/resize; the
    `Print` family is keyed by capture target.
- **Panels**: quick controls inline, the full tool behind a last "Advanced"
  row; keyboard-driven (Up/Down/j/k, Enter, Left/Right, Delete, Escape; Q / E
  page a `PanelHeader`). Outside code reaches the shell only via `qs ipc call`.
- **Prefer maintained projects** over hand-rolled scripts and rules.
- Don't open or kill windows in the user's live session to test without
  asking. Back up a config before rewriting it.
- **Public captures**: no network or bluetooth panels (SSIDs and device names
  leak location and people), check app lists and window contents, strip
  metadata.

## How we design

- **Start from the game.** Find the component the game uses for the job
  (STYLEGUIDE section 6) before inventing one. Folder tabs for the agents
  panel took ~10 rejected rounds; the game's menu header strip was approved
  at once (2026-10-14). The card's top-edge "tab" is decoration, not
  navigation.
- **Agree on the shape first**: ask for a quick sketch or show two ASCII
  previews; words like "chip" or "folder" are ambiguous.
- **Show every step** with a capture. Things the user asks "to see" stay
  uncommitted until approved; then commit and record rejected variants in
  DESIGN-SYSTEM.md so they are not proposed again.
- **"Based on X" means all of X**: porting Omarchy's agent usage meant every
  collector and its detection rule, not only the one we had.
- Settled by the user, do not revisit: hyprlock's own look (no dialog card);
  modals dim, never a red wash; no corner-bracket reticle (it is the game's
  mouse pointer); no generated wallpapers unless asked; Qt stays Fusion +
  matugen palette (a Kvantum theme was built and reverted: KeePassXC
  self-themes and wins).

## Verify against the running system

- Quickshell: errors with `timeout 3 qs log`. Open a panel with
  `qs ipc call panel toggle <name>`, then **wait until `hyprctl layers -j`
  lists namespace `quickshell-panel`** before sending keys with
  `hyprctl eval 'hl.dispatch(hl.dsp.send_shortcut({mods="", key="Down"}))'`;
  otherwise the keys land in the focused window. Capture with
  `grim -g "x,y wxh"` in **logical** pixels (screen scale applies). After a
  config reload, data-driven panels are empty until their collectors rerun.
- Hyprland Lua: `hyprctl eval` / `hyprctl repl` show real argument shapes
  (the stubs only list names). **Invalid enum values fail silently**:
  `hl.dsp.*` returns nil and the bind is dead with no error. After editing
  binds: `hyprctl reload`, `hyprctl configerrors`, `hyprctl binds -j`.
- Qt palette: qtct fails silently on a bad scheme. Print
  `QGuiApplication::palette()` from a tiny app under
  `QT_QPA_PLATFORM=offscreen`, with and without `QT_QPA_PLATFORMTHEME=qtXct`.
- GTK (walker cards): render headlessly with `gtk4-broadwayd` and a script
  that snapshots the widget at 1.5x.
- SDDM: `QT_FORCE_STDERR_LOGGING=1 QT_QPA_PLATFORM=offscreen
  sddm-greeter-qt6 --test-mode --theme <dir>`.
- elephant providers: `elephant query "provider;text;max;false"`.
- Polkit dialog: `hyprctl eval 'hl.exec_cmd("pkexec true")'` (pkexec from an
  agent's own shell never reaches the agent).

## Known traps

- `graphical-session.target` never starts here: anything that must run with
  the session starts from `hypr/lua/autostart.lua`, or its user unit uses
  `WantedBy=default.target`.
- `sed -i` swaps the file's inode and Quickshell keeps watching the old one:
  edit QML in place (or `touch shell.qml` to force a reload).
- Anything that rewrites a file Quickshell watches (`theme-set` writing
  `Colors.qml`) must run via `Quickshell.execDetached`: the hot reload kills
  `Process` children mid-run.
- QML: Quickshell popups never get the keyboard, so panels are layer surfaces.
  Lists that rescan need `ScriptModel` or the cursor is lost. Services
  (Networking, Bluetooth...) initialise lazily. `top` is a FINAL property of
  `Item`, don't declare it. QML JS has no `Array.flat`.
- `pkill -f <pattern>` matches the agent's own shell command line: kill by
  pid or `-x` name.
- Long one-liners pasted into the user's terminal wrap and break: hand over a
  script file instead.
- GTK can't clip shapes: walker's cards are SVG 9-slice `border-image`s drawn
  at 3x; keep SVG comments inside the root element.
- elephant providers are Go plugins built against elephant: never mix `-bin`
  and source packages.
- GTK 3 runs `adw-gtk3-dark` so matugen's libadwaita `@define-color`
  overrides reach it too. Qt gets the palette only (qtct); running Qt apps
  reload when `theme-set` touches `qtXct.conf`.
- KeePassXC paints its own theme unless `ApplicationTheme=classic`, and even
  then its custom widgets assume its bundled look; it rewrites its ini on
  exit, so edit it only while the app is closed.
- qtct's `stylesheets` key does nothing; Qt's `-stylesheet <path>` argument
  works. QSS `background` on a combo/spin box drops its arrows.
- If a Kvantum theme is ever reconsidered: `interior=false` is the only way
  to near-black surfaces, but it also erases selection bands and progress
  fills (state is painted as the interior); recolour SVGs by hue, rank-map
  greys; set `inactive.highlight.text.color` too. Decide the KeePassXC
  trade-off first.
- `walker --dmenu` closed without a pick is the normal path, not a failure:
  guard the call.
- SDDM config colours are strings: dim with `opacity`, not `Qt.rgba(config.x)`.
- The wl-clip-persist and wl-x11-clip-bridge user services feed XWayland apps
  and walker's clipboard history; keep them.
- Agent usage (`~/.local/bin/agent-usage`): one `agent-usage-<agent>`
  collector per agent, vendored from Omarchy except `agy`. Which agents show
  follows Omarchy's `providerHasData` rule (usage, limits, balance or a
  signed-in plan), not the `ready` flag (Codex sets it when not installed).
  The agy collector only runs `agy -p /usage` and never reads its token.
