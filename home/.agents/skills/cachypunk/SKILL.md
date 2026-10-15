---
name: cachypunk
description: >
  REQUIRED for any change to this machine's desktop (Cachypunk: CachyOS +
  Hyprland + Quickshell, styled after Cyberpunk 2077). Use when reading or
  editing anything in ~/.config/hypr, ~/.config/quickshell, ~/.config/matugen,
  ~/.config/walker, ~/.config/elephant, ~/.config/ghostty, ~/.config/sddm,
  ~/.config/auth-prompts, ~/.config/cachypunk, or the cachypunk repo.
  Triggers: Hyprland, keybindings, window rules, monitors, animations, bar,
  panels, widgets, OSD, notifications, launcher, themes, colors, wallpaper,
  fonts, GTK/Qt look, lock screen, login screen, sudo/polkit prompts, idle,
  night light, and "make it look like the game".
---

# Cachypunk

The desktop on this machine. Its whole config is a git repo linked into
`$HOME` by `cachypunk link`: editing `~/.config/hypr` edits the repo. Find the
repo with `readlink -f ~/.config/hypr` (it ends in `<repo>/home/.config/hypr`).
The repo is public.

## Before you start

1. Read `<repo>/AGENTS.md`: map, rules (keybinding tiers included), how we
   design and verify, known traps. It is the source of truth; this skill only
   routes you there.
2. Visual work: also read `home/.config/matugen/STYLEGUIDE.md` (the game's UI,
   the target) and `home/.config/matugen/DESIGN-SYSTEM.md` (how the desktop
   applies it).
3. Machine facts (host, hardware, monitors, keyboard and Hyprland layout): run
   `machine-context`, unless your session already received its output. Never
   assume them, never hardcode them into the repo.
4. Verify against the running system (`hyprctl`, `qs`, `/sys`, the actual
   file) instead of asserting from memory; say plainly what you could not
   verify.

## Where a change goes

| Change | Place |
|---|---|
| Shared desktop behaviour or look | the repo, under `home/` |
| A new file to link into `$HOME` | `home/<path>` plus a line in `links.txt`, then `cachypunk link` |
| A package it needs | `packages/*.txt` |
| Per-machine values (layout, apps, autostart) | `~/.config/cachypunk/user.lua`, see `examples/user.lua` |
| Wallpapers | `wallpaper-set`, stored in `~/.config/cachypunk/wallpapers/` |
| Colours | a palette in `matugen/themes/` or a matugen template, never hard-coded |
| Keybinds | `hypr/lua/binds.lua` through the `lua/keys.lua` helpers |
| Shell UI (bar, panels, OSD) | Quickshell, `home/.config/quickshell/` |

## Commands

```bash
cachypunk status              # links, packages, repo state
cachypunk link                # recreate symlinks after adding to links.txt
theme-set [name]              # apply a palette (no name = re-apply current)
wallpaper-set --list          # wallpapers the picker offers
qs ipc show                   # what the shell exposes (panel, osd, themes...)
qs ipc call panel toggle <n>  # the only way outside code reaches the shell
hyprctl reload && hyprctl configerrors   # after any Hyprland edit
```

## Safety

- Ask before opening or killing windows in the live session.
- Back up a config before rewriting it.
- English in everything written to disk.
- Nothing personal in the repo; public captures follow the rules in AGENTS.md.
- Commit or push only when the user asks.

## Setting up an agent on this machine

The repo ships what every agent shares: this skill and `machine-context`. What
is specific to one agent on one machine is written by that agent, as plain
files in its own global config, never symlinked by hand and never committed:

- **Global instructions** (`~/.claude/CLAUDE.md`, `~/.gemini/config/AGENTS.md`
  for Antigravity CLI, `~/.codex/AGENTS.md`...): if missing, add a line
  saying desktop work goes through the `cachypunk` skill. The user's personal
  preferences stay there.
- **Machine facts at session start** (optional; without it, run
  `machine-context` yourself): a SessionStart hook running
  `machine-context --claude-hook` (Claude Code, `~/.claude/settings.json`) or
  `machine-context --agy-hook` (Antigravity CLI, `~/.gemini/config/hooks.json`).
  Plain `machine-context` prints text for any other agent.
- **Per-machine desktop values** (layout, apps, wallpapers) go in
  `~/.config/cachypunk/`, as AGENTS.md says, never in the repo.

## When you learn something

Add one line to the right section of `AGENTS.md` (look-and-feel rules go to
`DESIGN-SYSTEM.md`). That is the memory every agent shares; an agent's private
memory may only keep a pointer.
