---
name: cachypunk
description: >
  REQUIRED for any change to this machine's desktop (Cachypunk: CachyOS +
  Hyprland + Quickshell, styled after Cyberpunk 2077). Use when reading or
  editing anything in ~/.config/hypr, ~/.config/quickshell, ~/.config/matugen,
  ~/.config/walker, ~/.config/elephant, ~/.config/ghostty, ~/.config/sddm,
  ~/.config/auth-prompts, ~/.config/cachypunk, or ~/Projects/cachypunk.
  Triggers: Hyprland, keybindings, window rules, monitors, animations, bar,
  panels, widgets, OSD, notifications, launcher, themes, colors, wallpaper,
  fonts, GTK/Qt look, lock screen, login screen, sudo/polkit prompts, idle,
  night light, and "make it look like the game".
---

# Cachypunk

The desktop on this machine. Its whole config is the git repo
`~/Projects/cachypunk`, symlinked into `$HOME`: editing `~/.config/hypr` edits
the repo. The repo is public.

## Before you start

1. Read `~/Projects/cachypunk/AGENTS.md`: map, rules (keybinding tiers
   included), how we design and verify, known traps. It is the source of
   truth; this skill only routes you there.
2. Visual work: also read `home/.config/matugen/STYLEGUIDE.md` (the game's UI,
   the target) and `home/.config/matugen/DESIGN-SYSTEM.md` (how the desktop
   applies it).
3. Machine facts (monitors, layout, hardware): read them live (`hyprctl
   monitors`, `hyprctl devices`, `/sys`), or from your global instructions if
   they provide them. Never assume them, never hardcode them.

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

## When you learn something

Add one line to the right section of `AGENTS.md` (look-and-feel rules go to
`DESIGN-SYSTEM.md`). That is the memory every agent shares; an agent's private
memory may only keep a pointer.
