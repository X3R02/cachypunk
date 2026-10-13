#!/usr/bin/env python3
"""Write fprintd.po and sudoers.po: the auth prompts as one live NetTech panel.

Both are en_US gettext catalogs. pam_fprintd hands sudo one message per
fingerprint state and sudoers supplies the password prompt and the retry
note; sudo prints each verbatim followed by a newline. Instead of stacking,
the messages share one fixed panel and move the cursor over it, so the panel
updates in place:

    1  header strip        drawn by prompts
    2  status line         drawn by notes only, prompts skip it
    3  request band        drawn by prompts
    4  hint / input line   drawn by prompts; the password is typed here
    5  (cursor rests here after a prompt, so command output starts clean)

A prompt is drawn from line 1 down. A note (a failed scan, a wrong password)
climbs from line 5 to the status line and redraws only that; a "final" note
is followed by a new prompt, so it leaves the cursor above line 1 for that
prompt to redraw the panel, while a "retry" note returns to line 5 because
the reader keeps scanning without a new prompt.

The palette is NetTech's own, sampled from the game (STYLEGUIDE.md 2.4), not
the desktop theme. Only real information is shown: no decorative device
branding or version strings. The Quickshell polkit card gets the same text and keeps only the
line holding "//" (see polkit/PolkitDialog.qml), so every message needs one.
sudo logs in the C locale (sudoers_locale), so the journal never sees these.

A "verdict" redraws the header and the status line once auth is over: the
granted one is printed by pam_exec from /etc/pam.d/sudo (pam-sudo here, with
the `granted` script this writes), the locked-out one replaces sudo's
"N incorrect password attempts". The password prompt leaves the colour on
cyan over navy so pwfeedback's asterisks (sudoers-pwfeedback) land inside
the panel; every later message starts with a reset.
"""
import os
import re

W = 46  # panel width in cells, cut corner included
STATUS = 2  # status line, counted from the panel's first line
BELOW = 5  # where the cursor rests after a prompt

LIME = (203, 231, 87)
NAVY = (13, 16, 23)
BAND = (21, 53, 90)
CYAN = (87, 208, 215)
RED = (255, 59, 69)
GREEN = (28, 217, 123)

ESC = "\\033"
NL = "\\n"
CR = "\\r"


def fg(c):
    return f"{ESC}[38;2;{c[0]};{c[1]};{c[2]}m"


def bg(c):
    return f"{ESC}[48;2;{c[0]};{c[1]};{c[2]}m"


def up(n):
    return f"{ESC}[{n}A"


def down(n):
    return f"{ESC}[{n}B"


BOLD = f"{ESC}[1m"
RESET = f"{ESC}[0m"
# Erase to the end of the line, so nothing from an earlier draw survives
CLEAR = f"{ESC}[K"
# Hide what the user types: while the reader waits the terminal still echoes
CONCEAL = f"{ESC}[8m"


def row(fill, parts, cut=False):
    """One panel line: parts are (colour, text) on a fill, padded to W."""
    width = W - 1 if cut else W
    body = "".join(fg(c) + t for c, t in parts)
    # %u is sudo's attempt count, one digit wide
    pad = width - sum(len(re.sub(r"\\033\[[0-9;]*m", "", t).replace("%u", "0"))
                      for _, t in parts)
    line = bg(fill) + body + " " * pad + RESET
    if cut:
        # The cut bottom-right corner: a triangle in the fill colour
        line += fg(fill) + "◤" + RESET
    return line + CLEAR


def header(title, fill=LIME):
    return row(fill, [(NAVY, BOLD + " " + title)])


def prompt(title, request, value, hint, conceal=False):
    """Lines 1-4, skipping the status line so a note on it survives. With
    conceal, keys typed while it waits are drawn invisible on line 5."""
    return (RESET + header(title) + NL + NL
            + row(BAND, [(LIME, f" //{request}  "), (CYAN, "▣ " + value)])
            + NL + row(NAVY, [(LIME, "   > "), (CYAN, hint)], cut=True)
            + (CONCEAL if conceal else ""))


def note(colour, request, value, final):
    """Redraw the status line from line 5 and park the cursor (see above).
    Line 5 is wiped first: it may hold concealed keystrokes."""
    climb = BELOW - STATUS
    line = row(NAVY, [(colour, f" ✕ //{request}  "), (CYAN, value)])
    # sudo's newline after the message then lands on line 1 or line 5
    # A retry keeps the reader waiting, so it conceals again
    after = up(STATUS) if final else down(climb - 1) + CONCEAL
    return RESET + CR + CLEAR + up(climb) + CR + line + after


def verdict(title, colour, mark, request, value):
    """From line 5, after auth: recolour the header, set the status line and
    erase everything below it, so only the verdict stays and what follows
    starts on line 3. Wipes line 5 first: sudo prefixes its own notes with
    "sudo: "."""
    status = row(NAVY, [(colour, f" {mark} //{request}  "), (CYAN, value)])
    return (RESET + CR + CLEAR + up(BELOW - 1) + header(title, colour)
            + CR + down(STATUS - 1) + status
            + CR + down(1) + f"{ESC}[J" + up(1))


def retry(request, value):
    return note(LIME, request, value, final=False)


def denied(request, value):
    return note(RED, request, value, final=True)


FINGERS = ["left thumb", "left index finger", "left middle finger",
           "left ring finger", "left little finger", "right thumb",
           "right index finger", "right middle finger", "right ring finger",
           "right little finger"]


def short(finger):
    return finger.replace(" finger", "").upper()


fprintd = []
for verb, prep, hint in (("Place", "on", "place finger on reader_"),
                         ("Swipe", "across", "swipe finger across reader_")):
    for tail in ("%s", "the fingerprint reader"):
        fprintd.append((f"{verb} your finger {prep} {tail}",
                        prompt("BIOMETRIC ACCESS", "ACCESS_REQUEST",
                               "ANY FINGER", hint, conceal=True)))
        for f in FINGERS:
            fprintd.append((f"{verb} your {f} {prep} {tail}",
                            prompt("BIOMETRIC ACCESS", "ACCESS_REQUEST",
                                   short(f), hint, conceal=True)))

fprintd += [
    # The reader keeps scanning after these
    ("Place your finger on the reader again", retry("RESCAN", "place again_")),
    ("Swipe your finger again", retry("RESCAN", "swipe again_")),
    ("Swipe was too short, try again", retry("SWIPE_TOO_SHORT", "again_")),
    ("Swipe was too fast, try again", retry("SWIPE_TOO_FAST", "again_")),
    ("Your finger was not centered, try swiping your finger again",
     retry("OFF_CENTER", "swipe again_")),
    ("Your finger was not centered, try touching the sensor again",
     retry("OFF_CENTER", "touch again_")),
    ("Remove your finger, and try swiping your finger again",
     retry("LIFT_FINGER", "swipe again_")),
    # A new prompt follows these: the next scan, or the password
    ("Failed to match fingerprint", denied("NO_MATCH", "access denied")),
    ("Verification timed out", denied("TIMEOUT", "scan window closed")),
    ("An unknown error occurred", denied("READER_FAULT", "falling back")),
]

# The password is typed on line 4: draw the line in full to wipe the
# fingerprint hint, then return to its start for the "> " the cursor sits on
password = prompt("PASSWORD OVERRIDE", "MANUAL_AUTH", "USER PASSWORD", "")
password += CR + bg(NAVY) + fg(LIME) + "   > " + fg(CYAN)

sudoers = [
    ("[sudo] password for %p: ", password),
    ("Sorry, try again.", denied("BAD_PASSWORD", "access denied")),
    (("%u incorrect password attempt", "%u incorrect password attempts"),
     [verdict("ACCESS DENIED", RED, "✕", "LOCKED_OUT", "%u failed attempt"),
      verdict("ACCESS DENIED", RED, "✕", "LOCKED_OUT", "%u failed attempts")]),
]

granted = {
    "fingerprint": verdict("ACCESS GRANTED", GREEN, "✓", "AUTHORIZED",
                           "fingerprint"),
    "password": verdict("ACCESS GRANTED", GREEN, "✓", "AUTHORIZED",
                        "password"),
}

HEADER = '''# Generated by ~/.config/auth-prompts/generate.py - edit that, not this.
msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\\n"
"Language: en_US\\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\\n"
'''

here = os.path.dirname(os.path.abspath(__file__))
for domain, entries in (("fprintd", fprintd), ("sudoers", sudoers)):
    with open(os.path.join(here, domain + ".po"), "w") as fh:
        fh.write(HEADER)
        for k, v in entries:
            if isinstance(k, tuple):
                fh.write(f'\nmsgid "{k[0]}"\nmsgid_plural "{k[1]}"\n')
                for i, form in enumerate(v):
                    fh.write(f'msgstr[{i}] "{form}"\n')
            else:
                fh.write(f'\nmsgid "{k}"\nmsgstr "{v}"\n')

# The msgids this overrides, one per line, for the pacman hook's check that
# a new fprintd or sudo still uses them
for domain, entries in (("fprintd", fprintd), ("sudoers", sudoers)):
    with open(os.path.join(here, "msgids-" + domain), "w") as fh:
        for k, _ in entries:
            for msgid in (k if isinstance(k, tuple) else (k,)):
                fh.write(msgid + "\n")

# Run as root by pam_exec, so install.sh copies it out of $HOME. No newline:
# pam_exec would split the output into separate messages
with open(os.path.join(here, "granted"), "w") as fh:
    fh.write("#!/bin/sh\n# Generated by ~/.config/auth-prompts/generate.py: "
             "the ACCESS GRANTED panel.\n# $1 is how the user got in: "
             "fingerprint or password.\n")
    fh.write('case "$1" in\n')
    for how, text in granted.items():
        fh.write(f"{how}) printf '{text}' ;;\n")
    fh.write("esac\nexit 0\n")
